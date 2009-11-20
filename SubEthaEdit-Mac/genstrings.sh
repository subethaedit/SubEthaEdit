#!/bin/sh
#>English.lproj/Generated.strings

echo "--- generating strings file using genstrings ---"
genstrings *.m TCMMillionMonkeys/*.m Panic/*.m Directory/*.m TCMBEEP/*.m TCMFoundation/*.m
echo "--- Merging English -> English.lproj/Merged.strings ---"
./wincent-strings-util -base Localizable.strings -merge English.lproj/Localizable.strings -output English.lproj/Merged.strings
echo "--- Merging German -> German.lproj/Merged.strings ---"
./wincent-strings-util -base Localizable.strings -merge German.lproj/Localizable.strings -output German.lproj/Merged.strings
echo "--- removing generated strings file ---"
rm Localizable.strings
echo "--- done ---"

