# Oni Guruma Makefile

product_name = oniguruma
dist_tag     = `date '+%Y%m%d'`

SHELL = /bin/sh
AUTOCONF = autoconf

CPPFLAGS = 
CFLAGS = -g -O2 
LDFLAGS =
LOADLIBES =
AR = ar
ARFLAGS = rc
RANLIB = ranlib
INSTALL = install -c
CP      = cp -p
CC = gcc
DEFS = -DHAVE_CONFIG_H -DNOT_RUBY
RUBYDIR = ..
WIN32 = win32

docdir = doc
srcdir = .

prefix = /usr/local
exec_prefix = ${prefix}
libdir     = $(exec_prefix)/lib
includedir = $(prefix)/include

subdirs = 

libname      = libonig.a

onigintheaders = regint.h regparse.h regenc.h
onigheaders  = oniguruma.h $(onigintheaders)
posixheaders = onigposix.h
headers      = $(posixheaders) $(onigheaders) oniggnu.h onigcmpt200.h
encheaders   = regenc.h oniguruma.h config.h

onigobjs     = regerror.o regparse.o regcomp.o regexec.o reggnu.o regenc.o
posixobjs    = regposix.o regposerr.o
libobjs      = $(onigobjs) $(posixobjs)
encobjs      =  $(encdir)/ascii.o $(encdir)/utf8.o \
		$(encdir)/euc_jp.o $(encdir)/euc_tw.o $(encdir)/euc_kr.o \
		$(encdir)/sjis.o \
		$(encdir)/iso8859_1.o  $(encdir)/iso8859_2.o \
		$(encdir)/iso8859_3.o  $(encdir)/iso8859_4.o \
		$(encdir)/iso8859_5.o  $(encdir)/iso8859_6.o \
		$(encdir)/iso8859_7.o  $(encdir)/iso8859_8.o \
		$(encdir)/iso8859_9.o  $(encdir)/iso8859_10.o \
		$(encdir)/iso8859_11.o $(encdir)/iso8859_13.o \
		$(encdir)/iso8859_14.o $(encdir)/iso8859_15.o \
		$(encdir)/iso8859_16.o \
		$(encdir)/koi8.o $(encdir)/koi8_r.o $(encdir)/big5.o

onigsources  = regerror.c regparse.c regcomp.c regexec.c reggnu.c regenc.c
posixsources = regposix.c regposerr.c
libsources   = $(posixsources) $(onigsources)

encdir       = enc
patchfiles   = re.c.168.patch re.c.181.patch
distfiles    =  README COPYING HISTORY index.html INSTALL-RUBY MANIFEST-RUBY \
		.cvsignore Makefile.in configure.in config.h.in configure \
		$(headers) $(libsources) regex.c $(patchfiles) \
		test.rb testconv.rb $(testc).c
win32distfiles = $(WIN32)/Makefile $(WIN32)/config.h $(WIN32)/testc.c
docfiles       = $(docdir)/API $(docdir)/RE $(docdir)/RE.ja
encfiles       = $(encdir)/mktable.c  $(encdir)/ascii.c $(encdir)/utf8.c \
		 $(encdir)/euc_jp.c $(encdir)/euc_tw.c $(encdir)/euc_kr.c \
		 $(encdir)/sjis.c $(encdir)/koi8.c $(encdir)/koi8_r.c \
		 $(encdir)/big5.c \
		 $(encdir)/iso8859_1.c $(encdir)/iso8859_2.c \
		 $(encdir)/iso8859_3.c $(encdir)/iso8859_4.c \
		 $(encdir)/iso8859_5.c $(encdir)/iso8859_6.c \
		 $(encdir)/iso8859_7.c $(encdir)/iso8859_8.c \
		 $(encdir)/iso8859_9.c $(encdir)/iso8859_10.c \
		 $(encdir)/iso8859_11.c $(encdir)/iso8859_13.c \
		 $(encdir)/iso8859_14.c $(encdir)/iso8859_15.c \
		 $(encdir)/iso8859_16.c

sampledir    = sample
samplefiles  = $(sampledir)/*.c

testc        = testc
testp        = testp

makeargs = $(MFLAGS) CPPFLAGS='$(CPPFLAGS)' CFLAGS='$(CFLAGS)' CC='$(CC)'

.SUFFIXES:
.SUFFIXES: .o .c .h .ps .dvi .info .texinfo

.c.o:
	$(CC) $(CFLAGS) $(CPPFLAGS) $(DEFS) -I. -I$(srcdir) -I.. -c $< -o $@

# targets
default: all

all: $(libname)

$(libname): make_enc_dir $(libobjs) $(encobjs)
	rm -f $(libname)
	$(AR) $(ARFLAGS) $(libname) $(libobjs) $(encobjs)
	$(RANLIB) $(libname)

regparse.o:  regparse.c  $(onigheaders)    config.h
regcomp.o:   regcomp.c   $(onigheaders)    config.h
regexec.o:   regexec.c   regint.h regenc.h oniguruma.h config.h
reggnu.o:    reggnu.c    regint.h regenc.h oniguruma.h config.h oniggnu.h
regerror.o:  regerror.c  regint.h regenc.h oniguruma.h config.h
regenc.o:    regenc.c    regint.h regenc.h oniguruma.h config.h
regposix.o:  regposix.c  $(posixheaders) oniguruma.h config.h
regposerr.o: regposerr.c $(posixheaders) config.h

$(encdir)/ascii.o:      $(encdir)/ascii.c      $(encheaders)
$(encdir)/utf8.o:       $(encdir)/utf8.c       $(encheaders)
$(encdir)/euc_jp.o:     $(encdir)/euc_jp.c     $(encheaders)
$(encdir)/euc_tw.o:     $(encdir)/euc_tw.c     $(encheaders)
$(encdir)/euc_kr.o:     $(encdir)/euc_kr.c     $(encheaders)
$(encdir)/sjis.o:       $(encdir)/sjis.c       $(encheaders)
$(encdir)/iso8859_1.o:  $(encdir)/iso8859_1.c  $(encheaders)
$(encdir)/iso8859_2.o:  $(encdir)/iso8859_2.c  $(encheaders)
$(encdir)/iso8859_3.o:  $(encdir)/iso8859_3.c  $(encheaders)
$(encdir)/iso8859_4.o:  $(encdir)/iso8859_4.c  $(encheaders)
$(encdir)/iso8859_5.o:  $(encdir)/iso8859_5.c  $(encheaders)
$(encdir)/iso8859_6.o:  $(encdir)/iso8859_6.c  $(encheaders)
$(encdir)/iso8859_7.o:  $(encdir)/iso8859_7.c  $(encheaders)
$(encdir)/iso8859_8.o:  $(encdir)/iso8859_8.c  $(encheaders)
$(encdir)/iso8859_9.o:  $(encdir)/iso8859_9.c  $(encheaders)
$(encdir)/iso8859_10.o: $(encdir)/iso8859_10.c $(encheaders)
$(encdir)/iso8859_11.o: $(encdir)/iso8859_11.c $(encheaders)
$(encdir)/iso8859_13.o: $(encdir)/iso8859_13.c $(encheaders)
$(encdir)/iso8859_14.o: $(encdir)/iso8859_14.c $(encheaders)
$(encdir)/iso8859_15.o: $(encdir)/iso8859_15.c $(encheaders)
$(encdir)/iso8859_16.o: $(encdir)/iso8859_16.c $(encheaders)
$(encdir)/koi8.o:       $(encdir)/koi8.c       $(encheaders)
$(encdir)/koi8_r.o:     $(encdir)/koi8_r.c     $(encheaders)
$(encdir)/big5.o:       $(encdir)/big5.c       $(encheaders)

make_enc_dir:
	test -d enc || mkdir enc

install: all
	test -d $(libdir) || mkdir $(libdir)
	test -d $(includedir) || mkdir $(includedir)
	$(INSTALL) $(libname) $(libdir)/$(libname)
	$(RANLIB)  $(libdir)/$(libname)
	$(INSTALL) $(srcdir)/oniguruma.h  $(includedir)/oniguruma.h
	$(INSTALL) $(srcdir)/onigposix.h  $(includedir)/onigposix.h
	$(INSTALL) $(srcdir)/oniggnu.h    $(includedir)/oniggnu.h

uninstall:
	-rm -f $(libdir)/$(libname)
	-rm -f $(includedir)/oniguruma.h
	-rm -f $(includedir)/onigposix.h
	-rm -f $(includedir)/oniggnu.h

warn:
	make CFLAGS='-g -O2  -Wall'


mktable: enc/mktable.c regenc.h
	$(CC) -I. -o $(encdir)/mktable $(encdir)/mktable.c

# Ruby test
rtest:
	$(RUBYDIR)/ruby -w -Ke $(srcdir)/test.rb

# C library test
ctest: $(testc)
	./$(testc)

# POSIX C library test
ptest: $(testp)
	./$(testp)

$(testc): $(testc).c $(libname)
	$(CC) $(CFLAGS) -o $@ $(srcdir)/$(testc).c $(libname)

$(testp): $(testc).c $(libname)
	$(CC) -DPOSIX_TEST $(CFLAGS) -o $@ $(srcdir)/$(testc).c $(libname)

$(testc).c: test.rb testconv.rb
	ruby -Ke testconv.rb < $(srcdir)/test.rb > $@

$(WIN32)/$(testc).c: test.rb testconv.rb
	ruby -Ke testconv.rb -win < $(srcdir)/test.rb | nkf -cs > $@

clean:
	rm -f *.o $(encdir)/*.o $(libname) $(testc) $(testp) $(testc) \
	*~ win32/*~ $(encdir)/*~ $(docdir)/*~

distclean: clean
	rm -f Makefile config.status


16: cpruby
	patch -d $(RUBYDIR) -p0 < $(srcdir)/re.c.168.patch

18: cpruby
	patch -d $(RUBYDIR) -p0 < $(srcdir)/re.c.181.patch

# backup file suffix
SORIG = ruby_orig

cpruby:
	$(CP) $(RUBYDIR)/regex.c $(RUBYDIR)/regex.c.$(SORIG)
	$(CP) $(RUBYDIR)/regex.h $(RUBYDIR)/regex.h.$(SORIG)
	$(CP) $(RUBYDIR)/re.c    $(RUBYDIR)/re.c.$(SORIG)
	$(CP) $(srcdir)/regex.c     $(RUBYDIR)
	$(CP) $(srcdir)/regerror.c  $(RUBYDIR)
	$(CP) $(srcdir)/regparse.c  $(RUBYDIR)
	$(CP) $(srcdir)/regcomp.c   $(RUBYDIR)
	$(CP) $(srcdir)/regexec.c   $(RUBYDIR)
	$(CP) $(srcdir)/reggnu.c    $(RUBYDIR)
	$(CP) $(srcdir)/regenc.c    $(RUBYDIR)
	$(CP) $(srcdir)/regint.h    $(RUBYDIR)
	$(CP) $(srcdir)/regparse.h  $(RUBYDIR)
	$(CP) $(srcdir)/regenc.h    $(RUBYDIR)
	$(CP) $(srcdir)/oniguruma.h $(RUBYDIR)
	$(CP) $(srcdir)/oniggnu.h   $(RUBYDIR)/regex.h
	test -d $(RUBYDIR)/$(encdir) || mkdir $(RUBYDIR)/$(encdir)
	$(CP) $(srcdir)/$(encdir)/ascii.c  $(RUBYDIR)/$(encdir)/ascii.c
	$(CP) $(srcdir)/$(encdir)/utf8.c   $(RUBYDIR)/$(encdir)/utf8.c
	$(CP) $(srcdir)/$(encdir)/euc_jp.c $(RUBYDIR)/$(encdir)/euc_jp.c
	$(CP) $(srcdir)/$(encdir)/sjis.c   $(RUBYDIR)/$(encdir)/sjis.c

rback:
	$(CP) $(RUBYDIR)/regex.c.$(SORIG) $(RUBYDIR)/regex.c
	$(CP) $(RUBYDIR)/regex.h.$(SORIG) $(RUBYDIR)/regex.h
	$(CP) $(RUBYDIR)/re.c.$(SORIG)    $(RUBYDIR)/re.c

samples: make_sample_dir $(libname) $(sampledir)/simple $(sampledir)/posix \
	 $(sampledir)/names $(sampledir)/listcap $(sampledir)/sql \
	 $(sampledir)/encode $(sampledir)/syntax
	$(sampledir)/simple
	$(sampledir)/posix
	$(sampledir)/names
	$(sampledir)/listcap
	$(sampledir)/sql
	$(sampledir)/encode
	$(sampledir)/syntax

make_sample_dir:
	test -d sample || mkdir sample

$(sampledir)/simple.o:  $(srcdir)/$(sampledir)/simple.c
$(sampledir)/posix.o:   $(srcdir)/$(sampledir)/posix.c
$(sampledir)/names.o:   $(srcdir)/$(sampledir)/names.c
$(sampledir)/listcap.o: $(srcdir)/$(sampledir)/listcap.c
$(sampledir)/sql.o:     $(srcdir)/$(sampledir)/sql.c
$(sampledir)/encode.o:  $(srcdir)/$(sampledir)/encode.c
$(sampledir)/syntax.o:  $(srcdir)/$(sampledir)/syntax.c

$(sampledir)/simple: $(libname) $(sampledir)/simple.o
	$(CC) -o $@ $(sampledir)/simple.o $(libname)
$(sampledir)/posix: $(libname) $(sampledir)/posix.o
	$(CC) -o $@ $(sampledir)/posix.o $(libname)
$(sampledir)/names: $(libname) $(sampledir)/names.o
	$(CC) -o $@ $(sampledir)/names.o $(libname)
$(sampledir)/listcap: $(libname) $(sampledir)/listcap.o
	$(CC) -o $@ $(sampledir)/listcap.o $(libname)
$(sampledir)/sql: $(libname) $(sampledir)/sql.o
	$(CC) -o $@ $(sampledir)/sql.o $(libname)
$(sampledir)/encode: $(libname) $(sampledir)/encode.o
	$(CC) -o $@ $(sampledir)/encode.o $(libname)
$(sampledir)/syntax: $(libname) $(sampledir)/syntax.o
	$(CC) -o $@ $(sampledir)/syntax.o $(libname)


configure: configure.in
	$(AUTOCONF)

config.status: configure
	$(SHELL) ./config.status --recheck

Makefile: Makefile.in config.status
	$(SHELL) ./config.status

# Prevent GNU make 3 from overflowing arg limit on system V.
.NOEXPORT:

manifest:
	for file in $(distfiles); do echo $$file; done


distdir = $(product_name)

dist_auto: $(testc).c $(WIN32)/$(testc).c

dist: configure dist_auto
	rm -rf $(distdir)
	mkdir $(distdir)
	mkdir $(distdir)/$(encdir)
	mkdir $(distdir)/$(docdir)
	mkdir $(distdir)/$(WIN32)
	mkdir $(distdir)/sample
	ln $(distfiles) $(distdir)
	ln $(encfiles)  $(distdir)/$(encdir)
	ln $(docfiles)  $(distdir)/$(docdir)
	ln $(win32distfiles) $(distdir)/$(WIN32)
	ln $(samplefiles)    $(distdir)/sample
	tar chf - $(distdir) | gzip > onigd$(dist_tag).tar.gz
	rm -rf $(distdir)

site: 
	rm -rf $(distdir)
	mkdir $(distdir)
	mkdir $(distdir)/$(docdir)
	mkdir $(distdir)/sample
	mkdir $(distdir)/archive
	ln index.html      $(distdir)
	ln HISTORY         $(distdir)/HISTORY.txt
	ln $(docdir)/API   $(distdir)/$(docdir)/API.txt
	ln $(docdir)/RE    $(distdir)/$(docdir)/RE.txt
	ln $(docdir)/RE.ja $(distdir)/$(docdir)/RE.ja.txt
	ln sample/simple.c $(distdir)/sample
	ln sample/sql.c    $(distdir)/sample
	ln archive/*       $(distdir)/archive
	tar chf - $(distdir) | gzip > onig_site$(dist_tag).tar.gz
	rm -rf $(distdir)
