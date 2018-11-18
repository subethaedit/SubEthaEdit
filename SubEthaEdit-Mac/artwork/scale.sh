#!/bin/sh
SUBDIR="Media.xcassets/SubEthaEdit.appiconset"
FLAGS="-unsharp 0x3+0.5+0"

convert ${SUBDIR}/1024.png -resize  16 $FLAGS ${SUBDIR}/16.png
convert ${SUBDIR}/1024.png -resize  32 $FLAGS ${SUBDIR}/32.png
convert ${SUBDIR}/1024.png -resize  64 $FLAGS ${SUBDIR}/64.png
convert ${SUBDIR}/1024.png -resize 128 $FLAGS ${SUBDIR}/128.png
convert ${SUBDIR}/1024.png -resize 256 $FLAGS ${SUBDIR}/256.png
convert ${SUBDIR}/1024.png -resize 512 $FLAGS ${SUBDIR}/512.png
