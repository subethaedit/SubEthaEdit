# Oniguruma Makefile for Win32

product_name = oniguruma

CPPFLAGS = 
CFLAGS = -O2 -nologo /W3
LDFLAGS =
LOADLIBES =
ARLIB = lib
ARLIB_FLAGS = -nologo
ARDLL = cl
ARDLL_FLAGS = -nologo -LD $(LINKFLAGS) -dll
LINKFLAGS = -link -incremental:no -pdb:none

INSTALL = install -c
CP      = copy
CC = cl
DEFS = -DHAVE_CONFIG_H -DNOT_RUBY -DEXPORT
RUBYDIR = ..

subdirs = 

libbase   = onig
libname   = $(libbase)_s.lib
dllname   = $(libbase).dll
dlllib    = $(libbase).lib

onigheaders  = oniguruma.h regint.h regparse.h regenc.h
posixheaders = onigposix.h
headers      = $(posixheaders) $(onigheaders)

onigobjs     = reggnu.obj regerror.obj regparse.obj regcomp.obj \
	       regexec.obj regenc.obj
posixobjs    = regposix.obj regposerr.obj
libobjs      = $(onigobjs) $(posixobjs)

jp_objs      =  $(encdir)\euc_jp.obj $(encdir)\sjis.obj
iso8859_objs =  $(encdir)\iso8859_1.obj  $(encdir)\iso8859_2.obj \
		$(encdir)\iso8859_3.obj  $(encdir)\iso8859_4.obj \
		$(encdir)\iso8859_5.obj  $(encdir)\iso8859_6.obj \
		$(encdir)\iso8859_7.obj  $(encdir)\iso8859_8.obj \
		$(encdir)\iso8859_9.obj  $(encdir)\iso8859_10.obj \
		$(encdir)\iso8859_11.obj $(encdir)\iso8859_13.obj \
		$(encdir)\iso8859_14.obj $(encdir)\iso8859_15.obj \
		$(encdir)\iso8859_16.obj

encobjs      =  $(encdir)\ascii.obj $(encdir)\utf8.obj \
		$(jp_objs) $(iso8859_objs) \
		$(encdir)\euc_tw.obj $(encdir)\euc_kr.obj \
		$(encdir)\koi8.obj $(encdir)\koi8_r.obj \
		$(encdir)\big5.obj

onigsources  = regerror.c regparse.c regcomp.c regexec.c regenc.c reggnu.c
posixsources = regposix.c regposerr.c
libsources   = $(posixsources) $(onigsources)
rubysources  = regex.c $(onigsources)

encdir       = enc
patchfiles   = re.c.168.patch re.c.181.patch
distfiles    = README COPYING INSTALL-RUBY HISTORY \
		Makefile.in configure.in config.h.in configure \
		$(headers) $(libsources) regex.c $(patchfiles) \
		test.rb testconv.rb
testc        = testc
testp        = testp

makeargs = $(MFLAGS) CPPFLAGS='$(CPPFLAGS)' CFLAGS='$(CFLAGS)' CC='$(CC)'

.SUFFIXES:
.SUFFIXES: .obj .c .h .ps .dvi .info .texinfo

.c.obj:
	$(CC) $(CFLAGS) $(CPPFLAGS) $(DEFS) /I. /I.. /Fo$@ /c $<

# targets
default: all

setup:
	$(CP) win32\config.h config.h
	$(CP) win32\testc.c  testc.c


all: $(libname) $(dllname) 

$(libname): $(libobjs) $(encobjs)
	$(ARLIB) $(ARLIB_FLAGS) -out:$@ $(libobjs) $(encobjs)

$(dllname): $(libobjs) $(encobjs)
	$(ARDLL) $(libobjs) $(encobjs) -Fe$@ $(ARDLL_FLAGS)

regparse.obj: regparse.c $(onigheaders) config.h
regcomp.obj:  regcomp.c  $(onigheaders) config.h
regexec.obj:  regexec.c  regint.h regenc.h oniguruma.h config.h
reggnu.obj:   reggnu.c   regint.h regenc.h oniguruma.h config.h oniggnu.h
regerror.obj: regerror.c regint.h regenc.h oniguruma.h config.h
regenc.obj:   regenc.c   regenc.h oniguruma.h config.h
regposix.obj: regposix.c $(posixheaders) oniguruma.h config.h
regposerr.obj: regposerr.c $(posixheaders) config.h

$(encdir)\ascii.obj:      $(encdir)\ascii.c regenc.h config.h
$(encdir)\utf8.obj:       $(encdir)\utf8.c regenc.h config.h
$(encdir)\euc_jp.obj:     $(encdir)\euc_jp.c regenc.h config.h
$(encdir)\euc_tw.obj:     $(encdir)\euc_tw.c regenc.h config.h
$(encdir)\euc_kr.obj:     $(encdir)\euc_kr.c regenc.h config.h
$(encdir)\sjis.obj:       $(encdir)\sjis.c regenc.h config.h
$(encdir)\iso8859_1.obj:  $(encdir)\iso8859_1.c regenc.h config.h
$(encdir)\iso8859_2.obj:  $(encdir)\iso8859_2.c regenc.h config.h
$(encdir)\iso8859_3.obj:  $(encdir)\iso8859_3.c regenc.h config.h
$(encdir)\iso8859_4.obj:  $(encdir)\iso8859_4.c regenc.h config.h
$(encdir)\iso8859_5.obj:  $(encdir)\iso8859_5.c regenc.h config.h
$(encdir)\iso8859_6.obj:  $(encdir)\iso8859_6.c regenc.h config.h
$(encdir)\iso8859_7.obj:  $(encdir)\iso8859_7.c regenc.h config.h
$(encdir)\iso8859_8.obj:  $(encdir)\iso8859_8.c regenc.h config.h
$(encdir)\iso8859_9.obj:  $(encdir)\iso8859_9.c regenc.h config.h
$(encdir)\iso8859_10.obj: $(encdir)\iso8859_10.c regenc.h config.h
$(encdir)\iso8859_11.obj: $(encdir)\iso8859_11.c regenc.h config.h
$(encdir)\iso8859_13.obj: $(encdir)\iso8859_13.c regenc.h config.h
$(encdir)\iso8859_14.obj: $(encdir)\iso8859_14.c regenc.h config.h
$(encdir)\iso8859_15.obj: $(encdir)\iso8859_15.c regenc.h config.h
$(encdir)\iso8859_16.obj: $(encdir)\iso8859_16.c regenc.h config.h
$(encdir)\koi8.obj:       $(encdir)\koi8.c   regenc.h config.h
$(encdir)\koi8_r.obj:     $(encdir)\koi8_r.c regenc.h config.h
$(encdir)\big5.obj:       $(encdir)\big5.c   regenc.h config.h


# Ruby test
rtest:
	$(RUBYDIR)\win32\ruby -w -Ke test.rb

# C library test
ctest: $(testc)
	.\$(testc)

# POSIX C library test
ptest: $(testp)
	.\$(testp)

$(testc): $(testc).c $(libname)
	$(CC) -nologo -o $(testc) -DONIG_EXTERN=extern $(testc).c $(libname)

$(testp): $(testc).c $(dlllib)
	$(CC) -nologo -DPOSIX_TEST -o $(testp) $(testc).c $(dlllib)

clean:
	del *.obj $(encdir)\*.obj *.lib *.exp *.dll $(testp).exe $(testc).exe $(testc).obj


16: cpruby
	patch -d $(RUBYDIR) -p0 < re.c.168.patch

18: cpruby
	patch -d $(RUBYDIR) -p0 < re.c.181.patch

# backup file suffix
SORIG = ruby_orig

cpruby:
	$(CP) $(RUBYDIR)\regex.c $(RUBYDIR)\regex.c.$(SORIG)
	$(CP) $(RUBYDIR)\regex.h $(RUBYDIR)\regex.h.$(SORIG)
	$(CP) $(RUBYDIR)\re.c    $(RUBYDIR)\re.c.$(SORIG)
# $(rubysources)
	$(CP) regex.c      $(RUBYDIR)
	$(CP) regerror.c   $(RUBYDIR)
	$(CP) regparse.c   $(RUBYDIR)
	$(CP) regcomp.c    $(RUBYDIR)
	$(CP) regexec.c    $(RUBYDIR)
	$(CP) regenc.c     $(RUBYDIR)
	$(CP) reggnu.c     $(RUBYDIR)
# $(onigheaders)
	$(CP) oniguruma.h  $(RUBYDIR)
	$(CP) oniggnu.h    $(RUBYDIR)\regex.h
	$(CP) regint.h     $(RUBYDIR)
	$(CP) regparse.h   $(RUBYDIR)
	$(CP) regenc.h     $(RUBYDIR)
# enc
	mkdir $(RUBYDIR)\$(encdir)
	$(CP) $(encdir)\ascii.c   $(RUBYDIR)\$(encdir)
	$(CP) $(encdir)\utf8.c    $(RUBYDIR)\$(encdir)
	$(CP) $(encdir)\euc_jp.c  $(RUBYDIR)\$(encdir)
	$(CP) $(encdir)\sjis.c    $(RUBYDIR)\$(encdir)

rback:
	$(CP) $(RUBYDIR)\regex.c.$(SORIG) $(RUBYDIR)\regex.c
	$(CP) $(RUBYDIR)\regex.h.$(SORIG) $(RUBYDIR)\regex.h
	$(CP) $(RUBYDIR)\re.c.$(SORIG)    $(RUBYDIR)\re.c
	rmdir /S $(RUBYDIR)\$(encdir)

samples: all
	$(CC) $(CFLAGS) -I. -o simple  sample\simple.c  $(dlllib)
	$(CC) $(CFLAGS) -I. -o posix   sample\posix.c   $(dlllib)
	$(CC) $(CFLAGS) -I. -o names   sample\names.c   $(dlllib)
	$(CC) $(CFLAGS) -I. -o listcap sample\listcap.c $(dlllib)
	$(CC) $(CFLAGS) -I. -o sql     sample\sql.c     $(dlllib)
	$(CC) $(CFLAGS) -I. -o encode  sample\encode.c  $(dlllib)
	$(CC) $(CFLAGS) -I. -o syntax  sample\syntax.c  $(dlllib)
