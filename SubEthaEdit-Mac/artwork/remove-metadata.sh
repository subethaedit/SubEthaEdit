#!/bin/sh

TEMP=${1}_tmp
QPDF=${TEMP}_qpdf
cp $1 $TEMP
exiftool -all:all= -overwrite_original_in_place $TEMP
qpdf --deterministic-id  --linearize $TEMP $QPDF
perl -pi -ne 's/(\/ID\s*\[<*)([\d+a-fA-F]*)(>\s*<)([\d+a-fA-F]*)(>)/\1\4\3\4\5/g' $QPDF
cp $QPDF $1
rm $QPDF $TEMP
# hexdump -v -C $QPDF > ${QPDF}.hex
