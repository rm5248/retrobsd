#
# Created by gmakemake Unknown (Dec 12 2013) on Wed Jun 25 09:47:07 2014
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
CLIBFLAGS = 	-lm
CCLIBFLAGS = 	
########## End of default flags


CPP_FILES =	
C_FILES =	mconf.c zconf.tab.c
H_FILES =	expr.h lkc.h lkc_proto.h
SOURCEFILES =	$(H_FILES) $(CPP_FILES) $(C_FILES) $(S_FILES)
.PRECIOUS:	$(SOURCEFILES)
OBJFILES =	zconf.tab.o

#
# Main targets
#

all:	 mconf 

mconf:	mconf.o $(OBJFILES)
	$(CC) $(CFLAGS) -o mconf mconf.o $(OBJFILES) $(CLIBFLAGS)

#
# Dependencies
#

confdata.o: confdata.c lkc.h expr.h lkc_proto.h
expr.o: expr.c lkc.h expr.h lkc_proto.h
kxgettext.o: kxgettext.c lkc.h expr.h lkc_proto.h
lex.zconf.o: lex.zconf.c lkc.h expr.h lkc_proto.h
mconf.o: mconf.c lkc.h expr.h lkc_proto.h
menu.o: menu.c lkc.h expr.h lkc_proto.h
symbol.o: symbol.c lkc.h expr.h lkc_proto.h
util.o: util.c lkc.h expr.h lkc_proto.h
zconf.hash.o: zconf.hash.c
zconf.tab.o: zconf.tab.c lkc.h expr.h lkc_proto.h zconf.hash.c \
 lex.zconf.c util.c confdata.c expr.c symbol.c menu.c

c compiler: |gcc|
#
# Housekeeping
#

Archive:	archive.tgz

archive.tgz:	$(SOURCEFILES) Makefile
	tar cf - $(SOURCEFILES) Makefile | gzip > archive.tgz

clean:
	$(RM) $(OBJFILES) kxgettext.o mconf.o core 2> /dev/null

realclean:        clean
	$(RM) -rf kxgettext mconf 
