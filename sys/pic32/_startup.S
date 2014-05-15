#
# Startup code for Microchip PIC32 microcontrollers.
# Based on the MIPS application note:
# "Boot-CPS: Example Boot Code for MIPS® Cores".
#
# Copyright (C) 2010-2014 Serge Vakulenko, <serge@vak.ru>
#
# Permission to use, copy, modify, and distribute this software
# and its documentation for any purpose and without fee is hereby
# granted, provided that the above copyright notice appear in all
# copies and that both that the copyright notice and this
# permission notice and warranty disclaimer appear in supporting
# documentation, and that the name of the author not be used in
# advertising or publicity pertaining to distribution of the
# software without specific, written prior permission.
#
# The author disclaim all warranties with regard to this
# software, including all implied warranties of merchantability
# and fitness.  In no event shall the author be liable for any
# special, indirect or consequential damages or any damages
# whatsoever resulting from loss of use, data or profits, whether
# in an action of contract, negligence or other tortious action,
# arising out of or in connection with the use or performance of
# this software.
#
#include "machine/io.h"

#define UBASE   0x7f008000      /* User space base address */

/*
 * MIPS Coprocessor 0 register numbers
 */
#define C0_INDEX        $0
#define C0_ENTRYLO0     $2
#define C0_ENTRYLO1     $3
#define C0_PAGEMASK     $5
#define C0_WIRED        $6
#define C0_COUNT        $9
#define C0_ENTRYHI      $10
#define C0_COMPARE      $11
#define C0_STATUS       $12
#define C0_SRSCTL       $12,2
#define C0_CAUSE        $13
#define C0_EPC          $14
#define C0_CONFIG       $16
#define C0_CONFIG1      $16,1
#define C0_CONFIG7      $16,7
#define C0_WATCHLO      $18
#define C0_WATCHHI      $19
#define C0_DEBUG        $23
#define C0_DEPC         $24
#define C0_ITAGLO       $28
#define C0_DTAGLO       $28,2
#define C0_ERRPC        $30

/*
 * MIPS Config1 register
 */
#define CFG1_MMUSSHIFT  25              // mmu size - 1
#define CFG1_ISSHIFT    22              // icache lines 64<<n
#define CFG1_ILSHIFT    19              // icache line size 2<<n
#define CFG1_IASHIFT    16              // icache ways - 1
#define CFG1_DSSHIFT    13              // dcache lines 64<<n
#define CFG1_DLSHIFT    10              // dcache line size 2<<n
#define CFG1_DASHIFT    7               // dcache ways - 1

                .set    noreorder
                .set    mips32r2
                .set    nomips16

                .extern u
                .extern u_end
                .extern u0
                .extern main
                .extern exception

#---------------------------------------
# Reset vector: main entry point
#
                .section .startup,"ax",@progbits
                .org    0
                .type   _reset_vector_, @function
_reset_vector_: .globl  _reset_vector_

                .set    noat
                mtc0    $0, C0_COUNT            # Clear cp0 Count (Used to measure boot time.)
#if 0
                //
                // Check for NMI exception.
                //
check_nmi:                                      # Check whether we are here due to a reset or NMI.
                mfc0    $s1, C0_STATUS          # Read Status
                ext     $s1, $s1, 19, 1         # extract NMI
                beqz    $s1, init_gpr           # Branch if this is NOT an NMI exception.
                nop

                # Call nmi_exception().
                la      $sp, _stack-16          # Set up stack base.
                la      $gp, _gp                # GP register value defined by linker script.
                la      $s1, nmi_exception      # Call user-defined NMI handler.
                jalr    $s1
                nop
#endif
                //
                // Set all GPRs of all register sets to predefined state.
                //
init_gpr:
                li      $1, 0xdeadbeef          # 0xdeadbeef stands out, kseg2 mapped, odd.

                # Determine how many shadow sets are implemented (in addition to the base register set.)
                # the first time thru the loop it will initialize using $1 set above.
                # At the bottom og the loop, 1 is  subtract from $30
                # and loop back to next_shadow_set to start the next loop and the next lowest set number.
                mfc0    $29, C0_SRSCTL          # read SRSCtl
                ext     $30, $29, 26, 4         # extract HSS

next_shadow_set:                        # set PSS to shadow set to be initialized
                ins     $29, $30, 6, 4          # insert PSS
                mtc0    $29, C0_SRSCTL          # write SRSCtl

                wrpgpr  $1, $1
                wrpgpr  $2, $1
                wrpgpr  $3, $1
                wrpgpr  $4, $1
                wrpgpr  $5, $1
                wrpgpr  $6, $1
                wrpgpr  $7, $1
                wrpgpr  $8, $1
                wrpgpr  $9, $1
                wrpgpr  $10, $1
                wrpgpr  $11, $1
                wrpgpr  $12, $1
                wrpgpr  $13, $1
                wrpgpr  $14, $1
                wrpgpr  $15, $1
                wrpgpr  $16, $1
                wrpgpr  $17, $1
                wrpgpr  $18, $1
                wrpgpr  $19, $1
                wrpgpr  $20, $1
                wrpgpr  $21, $1
                wrpgpr  $22, $1
                wrpgpr  $23, $1
                wrpgpr  $24, $1
                wrpgpr  $25, $1
                wrpgpr  $26, $1
                wrpgpr  $27, $1
                wrpgpr  $28, $1
                beqz    $30, init_cp0
                wrpgpr  $29, $1

                wrpgpr  $30, $1
                wrpgpr  $31, $1
                b       next_shadow_set
                add     $30, -1                 # Decrement to the next lower number

                //
                // Init CP0 Status, Count, Compare, Watch*, and Cause.
                //
init_cp0:
                # Initialize Status
                li      $v1, 0x00400404         # (M_StatusIM | M_StatusERL | M_StatusBEV)
                mtc0    $v1, C0_STATUS          # write Status

                # Initialize Watch registers if implemented.
                mfc0    $v0, C0_CONFIG1         # read Config1
                ext     $v1, $v0, 3, 1          # extract bit 3 WR (Watch registers implemented)
                beq     $v1, $zero, done_wr
                li      $v1, 0x7                # (M_WatchHiI | M_WatchHiR | M_WatchHiW)

                # Clear Watch Status bits and disable watch exceptions
                mtc0    $v1, C0_WATCHHI         # write WatchHi0
                mfc0    $v0, C0_WATCHHI         # read WatchHi0
                bgez    $v0, done_wr            # Check for bit 31 (sign bit) for more Watch registers
                mtc0    $zero, C0_WATCHLO       # clear WatchLo0

                mtc0    $v1, C0_WATCHHI, 1      # write WatchHi1
                mfc0    $v0, C0_WATCHHI, 1      # read WatchHi1
                bgez    $v0, done_wr            # Check for bit 31 (sign bit) for more Watch registers
                mtc0    $zero, C0_WATCHLO, 1    # clear WatchLo1

                mtc0    $v1, C0_WATCHHI, 2      # write WatchHi2
                mfc0    $v0, C0_WATCHHI, 2      # read WatchHi2
                bgez    $v0, done_wr            # Check for bit 31 (sign bit) for more Watch registers
                mtc0    $zero, C0_WATCHLO, 2    # clear WatchLo2

                mtc0    $v1, C0_WATCHHI, 3      # write WatchHi3
                mfc0    $v0, C0_WATCHHI, 3      # read WatchHi3
                bgez    $v0, done_wr            # Check for bit 31 (sign bit) for more Watch registers
                mtc0    $zero, C0_WATCHLO, 3    # clear WatchLo3

                mtc0    $v1, C0_WATCHHI, 4      # write WatchHi4
                mfc0    $v0, C0_WATCHHI, 4      # read WatchHi4
                bgez    $v0, done_wr            # Check for bit 31 (sign bit) for more Watch registers
                mtc0    $zero, C0_WATCHLO, 4    # clear WatchLo4

                mtc0    $v1, C0_WATCHHI, 5      # write WatchHi5
                mfc0    $v0, C0_WATCHHI, 5      # read WatchHi5
                bgez    $v0, done_wr            # Check for bit 31 (sign bit) for more Watch registers
                mtc0    $zero, C0_WATCHLO, 5    # clear WatchLo5

                mtc0    $v1, C0_WATCHHI, 6      # write WatchHi6
                mfc0    $v0, C0_WATCHHI, 6      # read WatchHi6
                bgez    $v0, done_wr            # Check for bit 31 (sign bit) for more Watch registers
                mtc0    $zero, C0_WATCHLO, 6    # clear WatchLo6

                mtc0    $v1, C0_WATCHHI, 7      # write WatchHi7
                mtc0    $zero, C0_WATCHLO, 7    # clear WatchLo7

done_wr:
                # Clear WP bit to avoid watch exception upon user code entry, IV, and software interrupts.
                mtc0    $zero, C0_CAUSE         # clear Cause: init AFTER init of WatchHi/Lo registers.

                # Clear timer interrupt. (Count was cleared at the reset vector to allow timing boot.)
                b       init_tlb                # Jump over exception vectors
                mtc0    $zero, C0_COMPARE       # clear Compare

                //
                // Clear TLB: generate unique EntryHi contents per entry pair.
                //
init_tlb:
                # Determine if we have a TLB
                mfc0    $v1, C0_CONFIG          # read Config
                ext     $v1, $v1, 7, 3          # extract MT field
                li      $a3, 0x1                # load a 1 to check against
                bne     $v1, $a3, init_icache

                # Config1MMUSize == Number of TLB entries - 1
                mfc0    $v0, C0_CONFIG1         # Config1
                ext     $v1, $v0, CFG1_MMUSSHIFT, 6     # extract MMU Size
                mtc0    $zero, C0_ENTRYLO0      # clear EntryLo0
                mtc0    $zero, C0_ENTRYLO1      # clear EntryLo1
                mtc0    $zero, C0_PAGEMASK      # clear PageMask
                mtc0    $zero, C0_WIRED         # clear Wired
                li      $a0, 0x80000000

next_tlb_entry:
                mtc0    $v1, C0_INDEX           # write Index
                mtc0    $a0, C0_ENTRYHI         # write EntryHi
                ehb
                tlbwi
                add     $a0, 2<<13              # Add 8K to the address to avoid TLB conflict with previous entry

                bne     $v1, $zero, next_tlb_entry
                add     $v1, -1

                //
                // Clear L1 instruction cache.
                //
init_icache:
                # Determine how big the I-cache is
                mfc0    $v0, C0_CONFIG1         # read Config1
                ext     $v1, $v0, CFG1_ILSHIFT, 3       # extract I-cache line size
                beq     $v1, $zero, done_icache # Skip ahead if no I-cache
                nop

                mfc0    $s1, C0_CONFIG7         # Read Config7
                ext     $s1, $s1, 18, 1         # extract HCI
                bnez    $s1, done_icache        # Skip when Hardware Cache Initialization bit set

                li      $a2, 2
                sllv    $v1, $a2, $v1           # Now have true I-cache line size in bytes

                ext     $a0, $v0, CFG1_ISSHIFT, 3       # extract IS
                li      $a2, 64
                sllv    $a0, $a2, $a0           # I-cache sets per way

                ext     $a1, $v0, CFG1_IASHIFT, 3       # extract I-cache Assoc - 1
                add     $a1, 1
                mul     $a0, $a0, $a1           # Total number of sets
                lui     $a2, 0x8000             # Get a KSeg0 address for cacheops

                mtc0    $zero, C0_ITAGLO        # Clear ITagLo register
                move    $a3, $a0

next_icache_tag:
                # Index Store Tag Cache Op
                # Will invalidate the tag entry, clear the lock bit, and clear the LRF bit
                cache   0x8, 0($a2)             # ICIndexStTag
                add     $a3, -1                 # Decrement set counter
                bne     $a3, $zero, next_icache_tag
                add     $a2, $v1                # Get next line address
done_icache:

                //
                // Enable cacheability of kseg0 segment.
                // Need to switch to kseg1, modify kseg0 CCA, then switch back.
                //
                la      $a2, enable_k0_cache
                li      $a1, 0xf
                ins     $a2, $a1, 29, 1         # changed to KSEG1 address by setting bit 29
                jr      $a2
                nop

enable_k0_cache:
                # Set CCA for kseg0 to cacheable.
                # NOTE! This code must be executed in KSEG1 (not KSEG0 uncached)
                mfc0    $v0, C0_CONFIG          # read C0_Config
                li      $v1, 3                  # CCA for single-core processors
                ins     $v0, $v1, 0, 3          # instert K0
                mtc0    $v0, C0_CONFIG          # write C0_Config

                la      $a2, init_dcache
                jr      $a2                     # switch back to KSEG0
                ehb

                //
                // Initialize the L1 data cache
                //
init_dcache:
                mfc0    $v0, C0_CONFIG1         # read C0_Config1
                ext     $v1, $v0, CFG1_DLSHIFT, 3       # extract D-cache line size
                beq     $v1, $zero, done_dcache # Skip ahead if no D-cache
                nop

                mfc0    $s1, C0_CONFIG7         # Read Config7
                ext     $s1, $s1, 18, 1         # extract HCI
                bnez    $s1, done_dcache        # Skip when Hardware Cache Initialization bit set

                li      $a2, 2
                sllv    $v1, $a2, $v1           # Now have true D-cache line size in bytes

                ext     $a0, $v0, CFG1_DSSHIFT, 3       # extract DS
                li      $a2, 64
                sllv    $a0, $a2, $a0           # D-cache sets per way

                ext     $a1, $v0, CFG1_DASHIFT, 3       # extract D-cache Assoc - 1
                add     $a1, 1
                mul     $a0, $a0, $a1           # Get total number of sets
                lui     $a2, 0x8000             # Get a KSeg0 address for cacheops

                mtc0    $zero, C0_ITAGLO        # Clear ITagLo/DTagLo registers
                mtc0    $zero, C0_DTAGLO
                move    $a3, $a0

next_dcache_tag:
                # Index Store Tag Cache Op
                # Will invalidate the tag entry, clear the lock bit, and clear the LRF bit
                cache   0x9, 0($a2)             # DCIndexStTag
                add     $a3, -1                 # Decrement set counter
                bne     $a3, $zero, next_dcache_tag
                add     $a2, $v1                # Get next line address
done_dcache:

                //
                // Call main() function.
                //
                la      $sp, u_end - 16                 # Stack at end of U area
                la      $a0, main
                jalr    $a0                             # Jump to main()
                lui     $gp, 0x8000                     # Set global pointer (delay slot)

                la      $k0, UBASE
                mtc0    $k0, C0_EPC                     # Entry to user code.

                mfc0    $k0, C0_STATUS
                ori     $k0, $k0, ST_UM | ST_EXL | ST_IE # Set user mode and enable interrupts
                mtc0    $k0, C0_STATUS                  # Put SR back
                ehb
                eret                                    # PC <= EPC; EXL <= 0
                nop                                     # just to be safe


#---------------------------------------
# Secondary entry point for RetroBSD bootloader.
#
                .section .exception,"ax",@progbits
_exception_base_: .globl _exception_base_

                .org    0
                .type   _entry_vector_, @function
_entry_vector_: .globl  _entry_vector_
                la      $k0, _reset_vector_
                jr      $k0
                nop

#---------------------------------------
# Exception vector: handle interrupts and exceptions
#
                .org    0x200
                .type   _exception_vector_, @function
_exception_vector_: .globl _exception_vector_

                mfc0    $k0, C0_STATUS
                andi    $k1, $k0, ST_UM                 # Check user mode
                beqz    $k1, kernel_exception
                move    $k1, $sp

                #
                # Exception in user mode: switch stack.
                #
user_exception:
                la      $sp, u_end                      # Stack at end of U area
kernel_exception:
                addi    $sp, -16-FRAME_WORDS*4          # Allocate space for registers
save_regs:
                sw      $k0, (16+FRAME_STATUS*4) ($sp)
                sw      $k1, (16+FRAME_SP*4) ($sp)

                .set    noat
                sw      $1, (16+FRAME_R1*4) ($sp)       # Save general registers
                sw      $2, (16+FRAME_R2*4) ($sp)
                sw      $3, (16+FRAME_R3*4) ($sp)
                sw      $4, (16+FRAME_R4*4) ($sp)
                sw      $5, (16+FRAME_R5*4) ($sp)
                sw      $6, (16+FRAME_R6*4) ($sp)
                sw      $7, (16+FRAME_R7*4) ($sp)
                sw      $8, (16+FRAME_R8*4) ($sp)
                sw      $9, (16+FRAME_R9*4) ($sp)
                sw      $10, (16+FRAME_R10*4) ($sp)
                sw      $11, (16+FRAME_R11*4) ($sp)
                sw      $12, (16+FRAME_R12*4) ($sp)
                sw      $13, (16+FRAME_R13*4) ($sp)
                sw      $14, (16+FRAME_R14*4) ($sp)
                sw      $15, (16+FRAME_R15*4) ($sp)
                sw      $16, (16+FRAME_R16*4) ($sp)
                sw      $17, (16+FRAME_R17*4) ($sp)
                sw      $18, (16+FRAME_R18*4) ($sp)
                sw      $19, (16+FRAME_R19*4) ($sp)
                sw      $20, (16+FRAME_R20*4) ($sp)
                sw      $21, (16+FRAME_R21*4) ($sp)
                sw      $22, (16+FRAME_R22*4) ($sp)
                sw      $23, (16+FRAME_R23*4) ($sp)
                sw      $24, (16+FRAME_R24*4) ($sp)
                sw      $25, (16+FRAME_R25*4) ($sp)
                # Skip $26 - K0
                # Skip $27 - K1
                sw      $28, (16+FRAME_GP*4) ($sp)
                # Skip $29 - SP
                sw      $30, (16+FRAME_FP*4) ($sp)
                sw      $31, (16+FRAME_RA*4) ($sp)
                .set    at

                mfhi    $k0                             # Save special registers
                sw      $k0, (16+FRAME_HI*4) ($sp)

                mflo    $k0
                sw      $k0, (16+FRAME_LO*4) ($sp)

                mfc0    $k0, C0_EPC
                sw      $k0, (16+FRAME_PC*4) ($sp)

                move    $a0, $sp
                addi    $a0, 16                         # Arg 0: saved regs.
                jal     exception                       # Call C code.
                lui     $gp, 0x8000                     # Set global pointer (delay slot)

                #
                # Restore CPU state and return from interrupt.
                #
restore_regs:
                lw      $a0, (16+FRAME_LO*4) ($sp)      # Load HI, LO registers
                mtlo    $a0
                lw      $a0, (16+FRAME_HI*4) ($sp)
                mthi    $a0

                .set    noat
                lw      $1, (16+FRAME_R1*4) ($sp)       # Load general registers
                lw      $2, (16+FRAME_R2*4) ($sp)
                lw      $3, (16+FRAME_R3*4) ($sp)
                lw      $4, (16+FRAME_R4*4) ($sp)
                lw      $5, (16+FRAME_R5*4) ($sp)
                lw      $6, (16+FRAME_R6*4) ($sp)
                lw      $7, (16+FRAME_R7*4) ($sp)
                lw      $8, (16+FRAME_R8*4) ($sp)
                lw      $9, (16+FRAME_R9*4) ($sp)
                lw      $10, (16+FRAME_R10*4) ($sp)
                lw      $11, (16+FRAME_R11*4) ($sp)
                lw      $12, (16+FRAME_R12*4) ($sp)
                lw      $13, (16+FRAME_R13*4) ($sp)
                lw      $14, (16+FRAME_R14*4) ($sp)
                lw      $15, (16+FRAME_R15*4) ($sp)
                lw      $16, (16+FRAME_R16*4) ($sp)
                lw      $17, (16+FRAME_R17*4) ($sp)
                lw      $18, (16+FRAME_R18*4) ($sp)
                lw      $19, (16+FRAME_R19*4) ($sp)
                lw      $20, (16+FRAME_R20*4) ($sp)
                lw      $21, (16+FRAME_R21*4) ($sp)
                lw      $22, (16+FRAME_R22*4) ($sp)
                lw      $23, (16+FRAME_R23*4) ($sp)
                lw      $24, (16+FRAME_R24*4) ($sp)
                lw      $25, (16+FRAME_R25*4) ($sp)
                # Skip $26 - K0
                # Skip $27 - K1
                lw      $28, (16+FRAME_GP*4) ($sp)
                # Skip $29 - SP
                lw      $30, (16+FRAME_FP*4) ($sp)
                .set    at

                # Do not use k0/k1 here, as interrupts are still enabled
                lw      $31, (16+FRAME_STATUS*4) ($sp)  # K0 = saved status
                ori     $31, ST_EXL                     # Set EXL
                mtc0    $31, C0_STATUS                  # put SR back: disable interrupts
                ehb

                lw      $k0, (16+FRAME_PC*4) ($sp)      # K0 = EPC
                mtc0    $k0, C0_EPC                     # put PC in EPC
                ext     $k1, $31, 27, 1                 # get RP bit: single-step request

                lw      $31, (16+FRAME_RA*4) ($sp)
                lw      $sp, (16+FRAME_SP*4) ($sp)      # Restore stack

                # Return from exception
                bnez    $k1, debug_request              # single-step request
                ehb
                eret                                    # PC <= EPC; EXL <= 0
debug_request:
                sdbbp                                   # enter debug mode

#---------------------------------------
# Debug exception processing.
#
                .org    0x480
                .type   _debug_vector_, @function
_debug_vector_: .globl _debug_vector_

                mfc0    $k0, C0_DEPC
                la      $k1, debug_request
                bne     $k0, $k1, single_step_done
                nop

                # single step request
                mfc0    $k0, C0_DEBUG
                ori     $k0, DB_SST                     # set SST bit
                mtc0    $k0, C0_DEBUG

                mfc0    $k1, C0_EPC
                mtc0    $k1, C0_DEPC                    # DEPC <= EPC
                mfc0    $k0, C0_STATUS
                xori    $k0, ST_EXL                     # Clear EXL
                mtc0    $k0, C0_STATUS
                ehb
                deret                                   # PC <= DEPC; DM <= 0

single_step_done:
                mtc0    $k0, C0_EPC                     # EPC <= DEPC

                la      $k1, _exception_vector_
                mtc0    $k1, C0_DEPC                    # DEPC <= exception handler

                mfc0    $k0, C0_DEBUG
                sw      $k0, c0_debug                   # save Debug register
                ori     $k0, DB_SST
                xori    $k0, DB_SST                     # clear SST bit
                mtc0    $k0, C0_DEBUG

                mfc0    $k1, C0_STATUS
                ori     $k1, ST_EXL                     # Set EXL
                mtc0    $k1, C0_STATUS
                ehb
                deret                                   # PC <= DEPC; DM <= 0

#---------------------------------------
# Icode is copied out to process 1 to exec /sbin/init.
# If the exec fails, process 1 exits.
#
                .globl  icode, icodeend
                .type   icode, @function
                .type   icodeend, @function
icode:
                la      $a0, UBASE
                move    $a1, $a0
                addi    $a0, etcinit - icode
                addi    $a1, argv - icode
                syscall 11                              # SYS_execv
                move    $a0, $v0
                syscall 1                               # SYS_exit
etcinit:
                .ascii  "/sbin/init\0"
initflags:
                .ascii  "-\0"                          # ASCII initflags
argv:
                .word   etcinit + 6 - icode + UBASE     # address of "init\0"
                .word   initflags - icode + UBASE       # init options
                .word   0

icodeend:       nop

#---------------------------------------
# int setjmp (label_t *env);
#
# Setjmp(env) will save the process' current register variables, stack
# and program counter context and return a zero.
#
                .type   setjmp, @function
setjmp:         .globl  setjmp
                sw      $s0, (0 * 4) ($a0)              # save register variables s0-s8
                sw      $s1, (1 * 4) ($a0)
                sw      $s2, (2 * 4) ($a0)
                sw      $s3, (3 * 4) ($a0)
                sw      $s4, (4 * 4) ($a0)
                sw      $s5, (5 * 4) ($a0)
                sw      $s6, (6 * 4) ($a0)
                sw      $s7, (7 * 4) ($a0)
                sw      $s8, (8 * 4) ($a0)              # frame pointer
                sw      $ra, (9 * 4) ($a0)              # return address
                sw      $gp, (10 * 4) ($a0)             # global data pointer
                sw      $sp, (11 * 4) ($a0)             # stack pointer
                j       $ra
                move    $v0, $zero                      # return a zero for the setjmp call

#---------------------------------------
# void longjmp (memaddr uaddr, label_t *env);
#
# Longjmp(uaddr, env) will generate a "return(1)" from the last
# call to setjmp(env) by mapping in the user structure pointed to by uaddr,
# restoring the context saved by setjmp in env and returning a "1".
# Note that registers are recovered statically from the env buffer.
# Stack is not used.
#
# This longjmp differs from the longjmp found in the standard library -
# it's actually closer to the resume routine of the 4.3BSD kernel.
#
                .type   longjmp, @function
longjmp:        .globl  longjmp

                di                              # can't let anything in till we get a valid stack...

                la      $v0, u                  # pointer to &u
                beq     $v0, $a0, 2f            # if uaddr == &u...
                nop                             # ...no need to remap U area

                la      $a3, u_end              # pointer to &u + USIZE
                la      $a0, u0                 # pointer to &u0

                lw      $v1, 0($v0)             # u.u_procp
                sw      $a0, 60($v1)            # u.u_procp->p_addr = &u0

                # exchange contents of u and u0
                move    $v1, $v0
1:
                lw      $t1, 0($v1)
                lw      $t0, 0($a0)
                sw      $t0, 0($v1)
                sw      $t1, 0($a0)
                lw      $t1, 4($v1)
                lw      $t0, 4($a0)
                sw      $t0, 4($v1)
                sw      $t1, 4($a0)
                lw      $t1, 8($v1)
                lw      $t0, 8($a0)
                sw      $t0, 8($v1)
                sw      $t1, 8($a0)
                lw      $t1, 12($v1)
                lw      $t0, 12($a0)
                sw      $t0, 12($v1)
                sw      $t1, 12($a0)
                addiu   $v1, $v1, 16
                bne     $a3, $v1, 1b
                addiu   $a0, $a0, 16

                lw      $v1, 0($v0)             # u.u_procp
                sw      $v0, 60($v1)            # u.u_procp->p_addr = &u
2:
                lw      $s0, (0 * 4) ($a1)      # restore register variables s0-s8
                lw      $s1, (1 * 4) ($a1)
                lw      $s2, (2 * 4) ($a1)
                lw      $s3, (3 * 4) ($a1)
                lw      $s4, (4 * 4) ($a1)
                lw      $s5, (5 * 4) ($a1)
                lw      $s6, (6 * 4) ($a1)
                lw      $s7, (7 * 4) ($a1)
                lw      $s8, (8 * 4) ($a1)      # frame pointer
                lw      $ra, (9 * 4) ($a1)      # return address
                lw      $gp, (10 * 4) ($a1)     # global data pointer
                lw      $sp, (11 * 4) ($a1)     # stack pointer

                ei                              # release interrupts
                j       $ra                     # transfer back to setjmp()
                li      $v0, 1                  # return value of 1
