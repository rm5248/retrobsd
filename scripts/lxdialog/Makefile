#
# Created by gmakemake Unknown (Dec 12 2013) on Wed Jun 25 09:44:55 2014
#

#
# Definitions
#

.SUFFIXES:
.SUFFIXES:	.a .o .c .C .cpp .s .S
.c.o:
		$(COMPILE.c) $< -o $@
.C.o:
		$(COMPILE.cc) $< -o $@
.cpp.o:
		$(COMPILE.cc) $< -o $@
.S.s:
		$(CPP) -o $*.s $<
.s.o:
		$(COMPILE.cc) $< -o $@
.c.a:
		$(COMPILE.c) -o $% $<
		$(AR) $(ARFLAGS) $@ $%
.C.a:
		$(COMPILE.cc) -o $% $<
		$(AR) $(ARFLAGS) $@ $%
.cpp.a:
		$(COMPILE.cc) -o $% $<
		$(AR) $(ARFLAGS) $@ $%

CC = 		gcc
CXX = 		g++

RM = rm -f
AR = ar
LINK.c = $(CC) $(CXXFLAGS) $(CPPFLAGS) $(LDFLAGS)
LINK.cc = $(CXX) $(CXXFLAGS) $(CPPFLAGS) $(LDFLAGS)
COMPILE.c = $(CC) $(CFLAGS) $(CPPFLAGS) -c
COMPILE.cc = $(CXX) $(CXXFLAGS) $(CPPFLAGS) -c


########## Default flags (redefine these with a header.mak file if desired)
CPPFLAGS = 	
CFLAGS = 	
CXXFLAGS = 	
CLIBFLAGS = 	-lm -lncurses
CCLIBFLAGS = 	
########## End of default flags


CPP_FILES =	
C_FILES =	checklist.c inputbox.c lxdialog.c menubox.c msgbox.c textbox.c \
util.c \
yesno.c
H_FILES =	colors.h dialog.h
SOURCEFILES =	$(H_FILES) $(CPP_FILES) $(C_FILES) $(S_FILES)
.PRECIOUS:	$(SOURCEFILES)
OBJFILES =	checklist.o inputbox.o menubox.o msgbox.o textbox.o util.o yesno.o 

#
# Main targets
#

all:	lxdialog 

lxdialog:	lxdialog.o $(OBJFILES)
	$(CC) $(CFLAGS) -o lxdialog lxdialog.o $(OBJFILES) $(CLIBFLAGS)

#
# Dependencies
#

checklist.o: checklist.c dialog.h
inputbox.o: inputbox.c dialog.h
lxdialog.o: lxdialog.c dialog.h
menubox.o: menubox.c dialog.h
msgbox.o: msgbox.c dialog.h
textbox.o: textbox.c dialog.h
util.o: util.c dialog.h colors.h
yesno.o: yesno.c dialog.h

c compiler: |gcc|
#
# Housekeeping
#

Archive:	archive.tgz

archive.tgz:	$(SOURCEFILES) Makefile
	tar cf - $(SOURCEFILES) Makefile | gzip > archive.tgz

clean:
	$(RM) $(OBJFILES) lxdialog.o core 2> /dev/null

realclean:        clean
	$(RM) -rf lxdialog 
