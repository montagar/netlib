!++
!   DESCRIP.MMS
!
!   MMS (MMK) description file for building NETLIB.
!
!   N.B.: If you are using DEC/MMS to build NETLIB, you
!         must define the macro __AXP__ or __I64__,
!         as needed for your target architecture, on the
!         MMS command line.
!
!   21-SEP-1994	V1.0	Madison	    Initial commenting.
!   31-OCT-1994	V2.0	Madison	    Rewrite for NETLIB V2.
!   30-SEP-1996	V2.1	Madison	    Fixups for non-MadGoat builds.
!   27-NOV-1997	V2.2	Madison	    Separate out version info.
!   12-MAR-1998	V2.2A	Madison	    CMSized, TCPware build change.
!   23-APR-1998	V2.2B	Madison	    Version check on install.
!   02-AUG-1998	V2.2C	Madison	    CMU name-to-address lookup fix.
!   15-NOV-1998	V2.2D	Madison	    MXLOOK fix.
!   12-DEC-1998	V2.2E	Madison	    Another TCPware fix.
!   26-DEC-2000	V2.3	Madison	    Kit installs .EXEs now.
!   18-JAN-2001	V2.3A	Madison	    DNS query fixes.
!   03-MAR-2001 V2.3B   Madison     Linemode returned length fix.
!   10-JAN-2002 V2.3C   Madison     strtoaddr fix.
!   04-FEB-2002 V2.3D   Madison     Correct strtoaddr fix.
!   21-SEP-2003 V2.3E   Madison     Fix for dns_skipname.
!   07-NOV-2004 V2.4    Madison     IA64 support.  Removed VAX.
!   19-NOV-2012 V3.0	Sneddon     VAX support. SSL support.
!   04-APR-2013 V3.0-1  Sneddon	    Moved version definitions into
!				     NETLIB_VERSION.MMS.
!   05-AUG-2013 V3.1	Sneddon	    Add NETLIBDEF target.
!--

.INCLUDE NETLIB_VERSION.MMS

.IFDEF __MADGOAT_BUILD__
.IFDEF MG_FACILITY
.ELSE
MG_FACILITY = NETLIB
.ENDIF

.IFDEF __VAX__
MG_VMSVER = V53
.ENDIF
.IFDEF __AXP__
MG_VMSVER = V6
.ENDIF
.IFDEF __I64__
MG_VMSVER = V82
.ENDIF
.INCLUDE MG_TOOLS:HEADER.MMS
.IFDEF LIS
MFLAGS = $(MFLAGS)/LIST=MG_ETC:$(MMS$TARGET_FNAME)
CFLAGS = $(CFLAGS)/LIST=MG_ETC:$(MMS$TARGET_FNAME)
LINKFLAGS = $(LINKFLAGS)/MAP=MG_ETC:$(MMS$TARGET_FNAME)/CROSS/FULL
.ENDIF
.ELSE
ETCDIR = SYS$DISK:[]
KITDIR =
SRCDIR = SYS$DISK:[]
BINDIR =
.ENDIF

.IFDEF __MMK_V32__

.IFDEF __VAX__
ARCH = VAX
VEC = ,$(BINDIR)NETLIB_VECTOR.OBJ
SSLVEC = ,$(BINDIR)NETLIB_SSL_VECTOR.OBJ
OPTFILE = $(SRCDIR)NETLIB.OPT
SSLOPTFILE = $(SRCDIR)NETLIB_SSL.OPT
VERFILE = $(ETCDIR)NETLIB_VERSION.OPT
.ELSE
ARCH = $(MMS$ARCH_NAME)
VEC =
OPTFILE = $(SRCDIR)NETLIB.$(ARCH)_OPT
SSLOPTFILE = $(SRCDIR)NETLIB_SSL.$(ARCH)_OPT
VERFILE = $(ETCDIR)NETLIB_VERSION.OPT
.ENDIF
.IFDEF __MADGOAT_BUILD__
.ELSE
BINDIR = [.BIN-$(ARCH)]
.FIRST
    @ IF F$PARSE("[.BIN-$(ARCH)]") .EQS. "" THEN CREATE/DIR [.BIN-$(ARCH)]
    @ DEFINE BIN_DIR SYS$DISK:[.BIN-$(ARCH)]
{}.C{$(BINDIR)}.OBJ :
{}.B32{$(BINDIR)}.OBJ :
{}.MAR{$(BINDIR)}.OBJ :
{$(SRCDIR)}.C{$(BINDIR)}.OBJ :
{$(SRCDIR)}.B32{$(BINDIR)}.OBJ :
{$(SRCDIR)}.MAR{$(BINDIR)}.OBJ :
.IFDEF DBG
CFLAGS = $(CFLAGS)$(DBG)/NOOPT
LINKFLAGS = $(LINKFLAGS)$(DBG)
MFLAGS = $(MFLAGS)$(DBG)
BFLAGS = $(BFLAGS)$(DBG)
.ELSE
LINKFLAGS = $(LINKFLAGS)/NOTRACE
.ENDIF
.ENDIF

.ELSE  ! MMK pre-V3.2, or MMS

.IFDEF __AXP__
ARCH = ALPHA
VEC =
.ENDIF
.IFDEF __I64__
ARCH = IA64
VEC =
.ENDIF
.IFDEF __VAX__
ARCH = VAX
VEC = ,$(BINDIR)NETLIB_VECTOR.OBJ
SSLVEC = ,$(BINDIR)NETLIB_SSL_VECTOR.OBJ
.ENDIF
OPT = $(ARCH)_OPT

OPTFILE = NETLIB$(OPT)
SSLOPTFILE = NETLIB_SSL$(OPT)
VERFILE = NETLIB_VERSION.OPT
.ENDIF

SDL = SDL/VAX

SSL_MODULES	    = NETLIB_SSL!, SSL_API
UCX_MODULES 	    = NETLIB_UCX
COMMON_MODULES	    = MEM, LINEMODE, MISC, CONNECT, COMPATIBILITY, -
    	    	      DNS, DNS_QUERY, DNS_MXLOOK

.FIRST
    @ DID_VERSION_CHECK == 0
    @ IF F$SEARCH("$(SRCDIR)CHECK_VERSION.COM") THEN @$(SRCDIR)CHECK_VERSION $(VERFILE) "$(TEXT_VERSION)" "$(GSMATCH)"
    @ IF F$SEARCH("$(SRCDIR)CHECK_VERSION.COM") THEN DID_VERSION_CHECK == 1

ALL 	    	: CHECK_VERSION,-
    	    	  $(BINDIR)NETLIB_GET_VERSION.EXE,-
		  $(BINDIR)NETLIB_SHR.EXE,$(BINDIR)NETLIB_SSL.EXE
    @ !

PREFETCH    	: $(SRCDIR)CHECK_VERSION.COM

CHECK_VERSION	: $(SRCDIR)CHECK_VERSION.COM
    @ IF .NOT. DID_VERSION_CHECK THEN @$(SRCDIR)CHECK_VERSION $(VERFILE) "$(TEXT_VERSION)" "$(GSMATCH)"
    @ DID_VERSION_CHECK == 1

NETLIBDEF	: $(SRCDIR)NETLIBDEF.BAS,$(SRCDIR)NETLIBDEF.H,-
		  $(SRCDIR)NETLIBDEF.PAS,$(SRCDIR)NETLIBDEF.PLI,-
		  $(SRCDIR)NETLIBDEF.R32
$(SRCDIR)NETLIBDEF.BAS		: $(SRCDIR)NETLIBDEF.SDL
    $(SDL)/LANGUAGE=BASIC=$(MMS$TARGET)/VMS_DEVELOPMENT $(MMS$SOURCE)
$(SRCDIR)NETLIBDEF.H		: $(SRCDIR)NETLIBDEF.SDL
    $(SDL)/LANGUAGE=CC=$(MMS$TARGET)/VMS_DEVELOPMENT $(MMS$SOURCE)
$(SRCDIR)NETLIBDEF.PAS		: $(SRCDIR)NETLIBDEF.SDL
    $(SDL)/LANGUAGE=PASCAL=$(MMS$TARGET)/VMS_DEVELOPMENT $(MMS$SOURCE)
$(SRCDIR)NETLIBDEF.PLI		: $(SRCDIR)NETLIBDEF.SDL
    $(SDL)/LANGUAGE=PLI=$(MMS$TARGET)/VMS_DEVELOPMENT/PLI_DEVELOPMENT $(MMS$SOURCE)
$(SRCDIR)NETLIBDEF.R32		: $(SRCDIR)NETLIBDEF.SDL
    $(SDL)/LANGUAGE=BLISS=$(MMS$TARGET)/VMS_DEVELOPMENT $(MMS$SOURCE)

$(BINDIR)NETLIB_SHR.EXE -
    	    	: $(BINDIR)NETLIB_UCX.OLB($(UCX_MODULES)),-
    	    	  $(BINDIR)NETLIB_COMMON.OLB($(COMMON_MODULES)) $(VEC),-
		  $(OPTFILE), $(VERFILE)
    $(LINK) $(LINKFLAGS)/SHARE $(VERFILE)/OPT, $(OPTFILE)/OPT, $(BINDIR)NETLIB_UCX.OLB/LIB

$(BINDIR)NETLIB_SSL.EXE -
		: $(BINDIR)NETLIB_SSL.OLB($(SSL_MODULES)),-
		  $(BINDIR)NETLIB_COMMON.OLB($(COMMON_MODULES)) $(SSLVEC),-
		  $(SSLOPTFILE), $(VERFILE)
    $(LINK) $(LINKFLAGS)/SHARE $(VERFILE)/OPT, $(SSLOPTFILE)/OPT, $(BINDIR)NETLIB_SSL.OLB/LIB/INCLUDE=SSL_API

$(BINDIR)NETLIB_SSL.OBJ     	: $(SRCDIR)NETLIB.H, $(SRCDIR)NETLIBDEF.H, $(SRCDIR)NETLIB_SSL.H
$(BINDIR)NETLIB_UCX.OBJ     	: $(SRCDIR)NETLIB.H, $(SRCDIR)NETLIBDEF.H, $(SRCDIR)NETLIB_UCX.H, $(SRCDIR)UCX_INETDEF.H

$(BINDIR)MEM.OBJ, -
$(BINDIR)LINEMODE.OBJ, -
$(BINDIR)DNS.OBJ, -
$(BINDIR)DNS_QUERY.OBJ, -
$(BINDIR)DNS_MXLOOK.OBJ, -
$(BINDIR)CONNECT.OBJ, -
$(BINDIR)NAMEADDR.OBJ	    	: $(SRCDIR)NETLIB.H, $(SRCDIR)NETLIBDEF.H

$(BINDIR)COMPATIBILITY.OBJ  	: $(SRCDIR)NETLIBDEF.H

$(BINDIR)MISC.OBJ   	    	: $(SRCDIR)MISC.C, $(SRCDIR)NETLIB.H, $(SRCDIR)NETLIBDEF.H, $(ETCDIR)NETLIB_VERSION.H
    @ DEFINE/USER ETC_DIR $(ETCDIR)
    $(CC) $(CFLAGS) $(SRCDIR)MISC.C

$(VERFILE)			: $(SRCDIR)NETLIB_VERSION.MMS
    @ define/user sys$input nl:
    @ create $(MMS$TARGET)
    @ open/append x $(MMS$TARGET)
    @ write x "IDENT=""NETLIB $(TEXT_VERSION)"""
    @ write x "GSMATCH=$(GSMATCH)"
    @ close x

$(ETCDIR)NETLIB_VERSION.H    	: $(VERFILE)
    @ open/read x $(VERFILE)
    @ read x __cmd
    @ close x
    @ '__cmd
    @ define/user sys$input nl:
    @ create $(MMS$TARGET)
    @ open/append x $(MMS$TARGET)
    @ WRITE x "#ifndef __NETLIB_VERSION_H__"
    @ WRITE x "#define __NETLIB_VERSION_H__"
    @ WRITE x "#define NETLIB_T_VERSION """, ident, """"
    @ WRITE x "#endif /* __NETLIB_VERSION_H__ */"
    @ CLOSE x

$(KITDIR)NETLIB_INSTALLING_VERSION.DAT : $(VERFILE)
    @ open/read x $(VERFILE)
    @ read x __cmd
    @ close x
    @ '__cmd
    @ define/user sys$input nl:
    @ create $(MMS$TARGET)
    @ open/append x $(MMS$TARGET)
    @ write x ident
    @ close x

$(BINDIR)NETLIB_GET_VERSION.EXE	    : $(BINDIR)NETLIB_GET_VERSION.OBJ
    $(LINK) $(LINKFLAGS) $(BINDIR)NETLIB_GET_VERSION.OBJ

$(KITDIR)NETLIB_GET_VERSION.VAX_EXE : $(BINVAX)NETLIB_GET_VERSION.EXE
    COPY $(MMS$SOURCE) $(MMS$TARGET)

$(KITDIR)NETLIB_GET_VERSION.AXP_EXE : $(BINAXP)NETLIB_GET_VERSION.EXE
    COPY $(MMS$SOURCE) $(MMS$TARGET)

$(KITDIR)NETLIB_GET_VERSION.I64_EXE : $(BINI64)NETLIB_GET_VERSION.EXE
    COPY $(MMS$SOURCE) $(MMS$TARGET)

$(KITDIR)NETLIB_SHR.AXP_EXE : $(BINAXP)NETLIB_SHR.EXE
    COPY $(MMS$SOURCE) $(MMS$TARGET)

$(KITDIR)NETLIB_SHR.I64_EXE : $(BINI64)NETLIB_SHR.EXE
    COPY $(MMS$SOURCE) $(MMS$TARGET)

!++
!   End of dependencies for binaries.  Kit dependencies follow.
!--

DOC      = DOCUMENT
DOCFLAGS = /CONTENTS/NOPRINT/OUTPUT=$(MMS$TARGET)/DEVICE=BLANK_PAGES/SYMBOLS=$(ETCDIR)DYNAMIC_SYMBOLS.SDML
BRFLAGS  = /CONTENTS/NOPRINT/OUTPUT=$(MMS$TARGET)/SYMBOLS=$(ETCDIR)DYNAMIC_SYMBOLS.SDML

$(KITDIR)NETLIB_DOC.PS	    	: $(SRCDIR)NETLIB_DOC.SDML, $(ETCDIR)DYNAMIC_SYMBOLS.SDML
    @ IF F$TRNLNM("DECC$SHR") .NES. "" THEN DEFINE/USER DECC$SHR SYS$SYSROOT:[SYSLIB]DECC$SHR
    $(DOC) $(DOCFLAGS) $(MMS$SOURCE) SOFTWARE.REFERENCE PS
$(KITDIR)NETLIB_DOC.TXT	    	: $(SRCDIR)NETLIB_DOC.SDML, $(ETCDIR)DYNAMIC_SYMBOLS.SDML
    @ IF F$TRNLNM("DECC$SHR") .NES. "" THEN DEFINE/USER DECC$SHR SYS$SYSROOT:[SYSLIB]DECC$SHR
    $(DOC) $(DOCFLAGS) $(MMS$SOURCE) SOFTWARE.REFERENCE MAIL
$(KITDIR)NETLIB_DOC.HTML	: $(SRCDIR)NETLIB_DOC.SDML, $(ETCDIR)DYNAMIC_SYMBOLS.SDML
    @ IF F$TRNLNM("DECC$SHR") .NES. "" THEN DEFINE/USER DECC$SHR SYS$SYSROOT:[SYSLIB]DECC$SHR
    $(DOC) $(BRFLAGS) $(MMS$SOURCE) SOFTWARE.REFERENCE HTML /INDEX

$(KITDIR)NETLIB_INST.PS	    	: $(SRCDIR)NETLIB_INST.SDML, $(ETCDIR)DYNAMIC_SYMBOLS.SDML
    @ IF F$TRNLNM("DECC$SHR") .NES. "" THEN DEFINE/USER DECC$SHR SYS$SYSROOT:[SYSLIB]DECC$SHR
    $(DOC) $(DOCFLAGS) $(MMS$SOURCE) SOFTWARE.REFERENCE PS
$(KITDIR)NETLIB_INST.TXT	    	: $(SRCDIR)NETLIB_INST.SDML, $(ETCDIR)DYNAMIC_SYMBOLS.SDML
    @ IF F$TRNLNM("DECC$SHR") .NES. "" THEN DEFINE/USER DECC$SHR SYS$SYSROOT:[SYSLIB]DECC$SHR
    $(DOC) $(DOCFLAGS) $(MMS$SOURCE) SOFTWARE.REFERENCE MAIL
$(KITDIR)NETLIB_INST.HTML	: $(SRCDIR)NETLIB_INST.SDML, $(ETCDIR)DYNAMIC_SYMBOLS.SDML
    @ IF F$TRNLNM("DECC$SHR") .NES. "" THEN DEFINE/USER DECC$SHR SYS$SYSROOT:[SYSLIB]DECC$SHR
    $(DOC) $(BRFLAGS) $(MMS$SOURCE) SOFTWARE.REFERENCE HTML /INDEX

$(ETCDIR)DYNAMIC_SYMBOLS.SDML	    	: $(SRCDIR)GENERATE_SYMBOLS.COM, $(VERFILE)
    @GENERATE_SYMBOLS $(VERFILE) $(MMS$TARGET)

CLEAN :
    - DELETE $(ETCDIR)*.*;*
    - DELETE $(BINDIR)*.*;*

DOCS	    	    	    	: $(KITDIR)NETLIB_DOC.PS,-
    	    	    	    	  $(KITDIR)NETLIB_DOC.TXT,-
    	    	    	    	  $(KITDIR)NETLIB_INST.PS,-
    	    	    	    	  $(KITDIR)NETLIB_INST.TXT
    @ !

KIT 	    	    	    	: $(KITDIR)NETLIB$(NUM_VERSION).ZIP
    @ !

KITFILES   	    	    	= $(SRCDIR)AAAREADME.DOC,-
    	    	    	    	  $(KITDIR)NETLIB$(NUM_VERSION).A,-
    	    	    	    	  $(KITDIR)NETLIB$(NUM_VERSION).B,-
    	    	    	    	  $(KITDIR)NETLIB_SRC.BCK
$(KITDIR)NETLIB$(NUM_VERSION).ZIP : $(KITFILES)
    IF F$SEARCH("$(MMS$TARGET)") .NES. "" THEN DELETE $(MMS$TARGET);*
    $(ZIP)/VMS $(MMS$TARGET) $(KITFILES)

$(KITDIR)NETLIB$(NUM_VERSION).RELEASE_NOTES -
    	    	    	    	: $(SRCDIR)NETLIB$(NUM_VERSION).SDML, $(ETCDIR)DYNAMIC_SYMBOLS.SDML
    @ IF F$TRNLNM("DECC$SHR") .NES. "" THEN DEFINE/USER DECC$SHR SYS$SYSROOT:[SYSLIB]DECC$SHR
    $(DOC) $(DOCFLAGS) $(MMS$SOURCE) SOFTWARE.REFERENCE MAIL

$(KITDIR)NETLIB$(NUM_VERSION).A	: $(SRCDIR)KITINSTAL.COM,-
    	    	    	    	  $(SRCDIR)NETLIB_INSTALL.COM,-
    	    	    	    	  $(SRCDIR)NETLIB_USER_INSTALL.COM,-
    	    	    	    	  $(SRCDIR)NETLIB_STARTUP_TEMPLATE.COM,-
    	    	    	    	  $(SRCDIR)NETLIB_LOGIN_TEMPLATE.COM,-
    	    	    	    	  $(KITDIR)NETLIB_INSTALLING_VERSION.DAT,-
    	    	    	    	  $(KITDIR)NETLIB$(NUM_VERSION).RELEASE_NOTES,-
    	    	    	    	  $(KITDIR)NETLIB_GET_VERSION.VAX_EXE,-
    	    	    	    	  $(KITDIR)NETLIB_GET_VERSION.AXP_EXE,-
    	    	    	    	  $(KITDIR)NETLIB_GET_VERSION.I64_EXE,-
                                  $(KITDIR)NETLIB_SHR.VAX_EXE,-
                                  $(KITDIR)NETLIB_SHR.AXP_EXE,-
                                  $(KITDIR)NETLIB_SHR.I64_EXE
    PURGE/NOLOG $(MMS$SOURCE_LIST)
    BACKUP $(MMS$SOURCE_LIST) $(MMS$TARGET)/SAVE/INTERCHANGE/BLOCK=8192/NOCRC/GROU=0

$(KITDIR)NETLIB$(NUM_VERSION).B	: $(SRCDIR)NETLIBDEF.H, $(SRCDIR)NETLIBDEF.R32,-
    	    	    	    	  $(SRCDIR)ECHOCLIENT.C, $(SRCDIR)ECHOSERVER.C,-
    	    	    	    	  $(SRCDIR)ECHOSERVER_STANDALONE.C,-
    	    	    	    	  $(KITDIR)NETLIB_DOC.PS,-
    	    	    	    	  $(KITDIR)NETLIB_DOC.TXT,-
    	    	    	    	  $(KITDIR)NETLIB_INST.PS,-
    	    	    	    	  $(KITDIR)NETLIB_INST.TXT
    PURGE/NOLOG $(MMS$SOURCE_LIST)
    BACKUP $(MMS$SOURCE_LIST) $(MMS$TARGET)/SAVE/INTERCHANGE/BLOCK=8192/NOCRC/GROU=0

SOURCE_LIST_A	    	    	= $(SRCDIR)DESCRIP.MMS,-
    	    	    	    	  $(SRCDIR)COMPATIBILITY.C, $(SRCDIR)CONNECT.C, $(SRCDIR)DNS.C, -
    	    	    	    	  $(SRCDIR)DNS_MXLOOK.C, $(SRCDIR)DNS_QUERY.C, $(SRCDIR)LINEMODE.C, -
    	    	    	    	  $(SRCDIR)MEM.C, $(SRCDIR)MISC.C, $(SRCDIR)NAMEADDR.C, -
    	    	    	    	  $(SRCDIR)NETLIB_UCX.C, -
    	    	    	    	  $(SRCDIR)NETLIB_UCX.H, $(SRCDIR)UCX_INETDEF.H
SOURCE_LIST_B	    	    	= $(SRCDIR)NETLIB.H, $(SRCDIR)NETLIBDEF.H, $(SRCDIR)NETLIBDEF.R32, -
    	    	    	    	  $(SRCDIR)NETLIB.ALPHA_OPT, $(SRCDIR)NETLIB.IA64_OPT,-
    	    	    	    	  $(SRCDIR)NETLIB_DOC.SDML, $(SRCDIR)NETLIB_INST.SDML,-
    	    	    	    	  $(SRCDIR)GENERATE_SYMBOLS.COM, $(SRCDIR)CHECK_VERSION.COM,-
    	    	    	    	  $(ETCDIR)NETLIB_VERSION.H, $(VERFILE),-
    	    	    	    	  $(SRCDIR)NETLIB$(NUM_VERSION).SDML, $(SRCDIR)NETLIB_GET_VERSION.B32
$(KITDIR)NETLIB_SRC.BCK	    	: $(SOURCE_LIST_A),$(SOURCE_LIST_B)
    PURGE/NOLOG $(SOURCE_LIST_A)
    PURGE/NOLOG $(SOURCE_LIST_B)
    @ IF F$SEARCH("$(KITDIR)SRC.DIR") .NES. "" THEN TREDEL $(KITDIR)SRC.DIR
    @ olddef = F$ENV("DEFAULT")
    @ IF "$(KITDIR)" .NES. "" THEN SET DEFAULT $(KITDIR)
    @ CREATE/DIRECTORY [.SRC]
    BACKUP $(SOURCE_LIST_A) [.SRC]*.*
    BACKUP $(SOURCE_LIST_B) [.SRC]*.*
    SET PROTECTION=W:RE [.SRC]*.*
    BACKUP [.SRC]*.*; $(MMS$TARGET)/SAVE/INTERCHANGE/BLOCK=8192/NOCRC/GROU=0
    @ TREDEL $(KITDIR)SRC.DIR
    @ SET DEFAULT 'olddef'
