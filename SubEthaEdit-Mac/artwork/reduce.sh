#!/bin/sh
SUBDIR="."
FLAGS="-unsharp 0x3+0.5+0"

convert ${SUBDIR}/icon_512x512@2x.png -resize  16 $FLAGS ${SUBDIR}/icon_16x16.png
convert ${SUBDIR}/icon_512x512@2x.png -resize  32 $FLAGS ${SUBDIR}/icon_32x32.png
convert ${SUBDIR}/icon_512x512@2x.png -resize  64 $FLAGS ${SUBDIR}/icon_32x32@2x.png
convert ${SUBDIR}/icon_512x512@2x.png -resize 128 $FLAGS ${SUBDIR}/icon_128x128.png
convert ${SUBDIR}/icon_512x512@2x.png -resize 256 $FLAGS ${SUBDIR}/icon_256x256.png
convert ${SUBDIR}/icon_512x512@2x.png -resize 512 $FLAGS ${SUBDIR}/icon_512x512.png

cp ${SUBDIR}/icon_512x512.png ${SUBDIR}/icon_256x256@2x.png
cp ${SUBDIR}/icon_256x256.png ${SUBDIR}/icon_128x128@2x.png
cp ${SUBDIR}/icon_32x32.png   ${SUBDIR}/icon_16x16@2x.png
