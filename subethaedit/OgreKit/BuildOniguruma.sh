#!/bin/bash

if [ x$1 = "xclean" ]; then
    cd RegularExpression/oniguruma
    if [ -e Makefile ]; then
        make distclean
    fi
    rm -f libonig_*
    exit
fi

cd RegularExpression/oniguruma

if [ -e libonig.a ]; then
    if [ -e libonig_ppc.a ]; then
        if [ -e libonig_i386.a ]; then
            echo "Found libonig*"
            exit
        fi
    fi
fi

if [ -e Makefile ]; then
    make distclean
fi
rm -f libonig_*

CC=gcc-3.3 ./configure
make
mv libonig.a libonig_ppc.a

make distclean
CC=gcc-4.0 CFLAGS="-Wl,-syslibroot,/Developer/SDKs/MacOSX10.4u.sdk -arch i386 -Wno-pointer-sign" ./configure --host=i386
sed -i "~" "s#-Wl,-syslibroot,/Developer/SDKs/MacOSX10.4u.sdk##g" Makefile
make
mv libonig.a libonig_i386.a

lipo -create -arch ppc libonig_ppc.a -arch i386 libonig_i386.a -output libonig.a

exit