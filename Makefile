#RM's makefile for retroBSD

#we need to get the directories to go into
include sys/kernel/Makefile
include sys/pic32/Makefile

#kinda ugly but it makes this easier
vpath %.c sys/kernel:sys/pic32
vpath %.S sys/pic32

#gcc variables
GCCPREFIX   = /usr/local/pic32-tools/bin/pic32-
LDFLAGS     = -Wl,--oformat=elf32-tradlittlemips

#linker script is important
LDSCRIPT = ldscripts/bare.ld

#defs from kernel-post.mk
CC              = $(GCCPREFIX)gcc -EL -mips32r2
CC              += -nostdinc -fno-builtin -Werror -Wall -fno-dwarf2-cfi-asm
LDFLAGS         += -nostdlib -T $(LDSCRIPT) -Wl,-Map=unix.map
SIZE            = $(GCCPREFIX)size
OBJDUMP         = $(GCCPREFIX)objdump
OBJCOPY         = $(GCCPREFIX)objcopy
PROGTOOL        = $(AVRDUDE) -c stk500v2 -p pic32 -b 115200
BLLDFLAGS       = -nostdlib -T$(BUILDPATH)/cfg/boot.ld -Wl,-Map=usbboot.map


#defs from the explorer16 makefile
DEFS += -DBUS_DIV=1
DEFS += -DBUS_KHZ=80000
DEFS += -DCONSOLE_DEVICE=tty1
DEFS += -DCPU_IDIV=2
DEFS += -DCPU_KHZ=80000
DEFS += -DCPU_MUL=20
DEFS += -DCPU_ODIV=1
DEFS += -DCRYSTAL=8
DEFS += -DDC0_DEBUG=DEVCFG0_DEBUG_DISABLED
DEFS += -DDC0_ICE=0
DEFS += -DDC1_CKM=0
DEFS += -DDC1_CKS=0
DEFS += -DDC1_FNOSC=DEVCFG1_FNOSC_PRIPLL
DEFS += -DDC1_IESO=DEVCFG1_IESO
DEFS += -DDC1_OSCIOFNC=0
DEFS += -DDC1_PBDIV=DEVCFG1_FPBDIV_1
DEFS += -DDC1_POSCMOD=DEVCFG1_POSCMOD_HS
DEFS += -DDC1_SOSC=0
DEFS += -DDC1_WDTEN=0
DEFS += -DDC1_WDTPS=DEVCFG1_WDTPS_1
DEFS += -DDC2_PLLIDIV=DEVCFG2_FPLLIDIV_2
DEFS += -DDC2_PLLMUL=DEVCFG2_FPLLMUL_20
DEFS += -DDC2_PLLODIV=DEVCFG2_FPLLODIV_1
DEFS += -DDC2_UPLL=0
DEFS += -DDC2_UPLLIDIV=DEVCFG2_UPLLIDIV_2
DEFS += -DDC3_CAN=DEVCFG3_FCANIO
DEFS += -DDC3_ETH=DEVCFG3_FETHIO
DEFS += -DDC3_MII=DEVCFG3_FMIIEN
DEFS += -DDC3_SRS=DEVCFG3_FSRSSEL_7
DEFS += -DDC3_USBID=DEVCFG3_FUSBIDIO
DEFS += -DDC3_USERID=0xffff
DEFS += -DDC3_VBUSON=DEVCFG3_FVBUSONIO
DEFS += -DEXEC_AOUT
DEFS += -DEXEC_ELF
DEFS += -DEXEC_SCRIPT
DEFS += -DGPIO_ENABLED=YES
DEFS += -DKERNEL
DEFS += -DLED_DISK_PIN=0
DEFS += -DLED_DISK_PORT=TRISA
DEFS += -DLED_KERNEL_PIN=1
DEFS += -DLED_KERNEL_PORT=TRISA
DEFS += -DLED_SWAP_PIN=3
DEFS += -DLED_SWAP_PORT=TRISA
DEFS += -DLED_TTY_PIN=2
DEFS += -DLED_TTY_PORT=TRISA
DEFS += -DPIC32MX7
DEFS += -DSD0_CS_PIN=1
DEFS += -DSD0_CS_PORT=TRISB
DEFS += -DSD0_MHZ=10
DEFS += -DSD0_PORT=1
DEFS += -DUART2_BAUD=115200
DEFS += -DUART2_ENABLED=YES
DEFS += -DUCB_METER

#other defs for compiling
CPPFLAGS += -Isys/include -Iinclude $(DEFS)
CFLAGS += -O

#kobj:
#	echo $(KERNOBJ-y) > /tmp/my16.out

unix.elf:       $(KERNOBJ-y) $(LDSCRIPT)
	$(CC) $(LDFLAGS) $(KERNOBJ-y) -o $@
	chmod -x $@
	$(OBJDUMP) -d -S $@ > unix.dis
	$(OBJCOPY) -O binary -R .boot -R .config $@ unix.bin
	$(OBJCOPY) -O binary -j .boot -j .config $@ boot.bin
	test -s boot.bin || rm boot.bin
	$(OBJCOPY) -O ihex --change-addresses=0x80000000 $@ unix.hex
	chmod -x $@ unix.bin

clean:
	rm -f *.o *.bin *.dis *.elf *.hex *.map

# CONFIGURATION STUFF
menuconfig: .config
	$(MAKE) -C scripts
	scripts/mconf Config.in

.config:
	cp kconfig .config
