#!/bin/sh
SUBDIR=${1:-"."} # the nice defaulting bash operator https://stackoverflow.com/questions/6482377/check-existence-of-input-argument-in-a-bash-shell-script
FLAGS="-unsharp 0x3+0.5+0"

convert ${SUBDIR}/icon_512x512@2x.png -strip -resize  32 $FLAGS ${SUBDIR}/icon_32x32.png
convert ${SUBDIR}/icon_512x512@2x.png -strip -resize  64 $FLAGS ${SUBDIR}/icon_32x32@2x.png
convert ${SUBDIR}/icon_512x512@2x.png -strip -resize 128 $FLAGS ${SUBDIR}/icon_128x128.png
convert ${SUBDIR}/icon_512x512@2x.png -strip -resize 256 $FLAGS ${SUBDIR}/icon_256x256.png
convert ${SUBDIR}/icon_512x512@2x.png -strip -resize 512 $FLAGS ${SUBDIR}/icon_512x512.png

cp ${SUBDIR}/icon_512x512.png ${SUBDIR}/icon_256x256@2x.png
cp ${SUBDIR}/icon_256x256.png ${SUBDIR}/icon_128x128@2x.png

if [ ! -f ${SUBDIR}/icon_16x16@2x.png ]; then
	convert ${SUBDIR}/icon_512x512@2x.png -strip -resize  32 $FLAGS ${SUBDIR}/icon_16x16@2x.png
fi

convert ${SUBDIR}/icon_16x16@2x.png -strip -resize  16 $FLAGS ${SUBDIR}/icon_16x16.png

# bye bye metadata
# find ${SUBDIR} -name "*.png" -exec pngcrush -rem allb -blacken -noreduce -s -ow \{\} \;
