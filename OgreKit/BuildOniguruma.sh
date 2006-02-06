#!/bin/bash

if [ x$1 = "xclean" ]; then
    echo "Cleaning..."
    rm -rf "${TARGET_TEMP_DIR}"
    rm -f "${BUILT_PRODUCTS_DIR}"/libonig.a
    exit
fi


if [ -e "${BUILT_PRODUCTS_DIR}"/libonig.a ]; then
    echo "Found libonig.a"
    exit
fi


mkdir -p "${TARGET_TEMP_DIR}"
cd "${TARGET_TEMP_DIR}"
mkdir ppc
cd ppc
CC=gcc-3.3 ${SRCROOT}/RegularExpression/oniguruma/configure
make

cd "${TARGET_TEMP_DIR}"
mkdir i386
cd i386
CC=gcc-4.0 CFLAGS="-Wl,-syslibroot,/Developer/SDKs/MacOSX10.4u.sdk -arch i386 -Wno-pointer-sign" ${SRCROOT}/RegularExpression/oniguruma/configure --host=i386
sed -i "~" "s#-Wl,-syslibroot,/Developer/SDKs/MacOSX10.4u.sdk##g" Makefile
make

lipo -create -arch ppc "${TARGET_TEMP_DIR}"/ppc/libonig.a -arch i386 "${TARGET_TEMP_DIR}"/i386/libonig.a -output "${BUILT_PRODUCTS_DIR}"/libonig.a

exit