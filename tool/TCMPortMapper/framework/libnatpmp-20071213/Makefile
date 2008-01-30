# $Id: Makefile,v 1.4 2007/12/06 22:37:19 nanard Exp $
# This Makefile is designed for use with GNU make
# (c) 2007 Thomas Bernard

# APIVERSION is used in soname
APIVERSION = 0
CFLAGS = -O -fPIC -Wall

LIBOBJS = natpmp.o getgateway.o

OBJS = $(LIBOBJS) testgetgateway.o natpmpc.o

STATICLIB = natpmp.a
SHAREDLIB = natpmp.so
SONAME = $(SHAREDLIB).$(APIVERSION)

EXECUTABLES = testgetgateway natpmpc-shared natpmpc-static

.PHONY:	all clean depend install

all: $(STATICLIB) $(SHAREDLIB) $(EXECUTABLES)

clean:
	$(RM) $(OBJS) $(EXECUTABLES) $(STATICLIB) $(SHAREDLIB)

depend:
	makedepend -f$(MAKEFILE_LIST) -Y $(OBJS:.o=.c) 2>/dev/null

install:

testgetgateway:	testgetgateway.o getgateway.o

natpmpc-static:	natpmpc.o $(STATICLIB)
	$(CC) -o $@ $^

natpmpc-shared:	natpmpc.o $(SHAREDLIB)
	$(CC) -o $@ $^

$(STATICLIB):	$(LIBOBJS)
	$(AR) crs $@ $?

$(SHAREDLIB):	$(LIBOBJS)
	$(CC) -shared -Wl,-soname,$(SONAME) -o $@ $^

# DO NOT DELETE

natpmp.o: natpmp.h getgateway.h
getgateway.o: getgateway.h
testgetgateway.o: getgateway.h
natpmpc.o: natpmp.h
