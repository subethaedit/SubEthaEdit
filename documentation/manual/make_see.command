#!/bin/sh
#
# BUILD THE DEVONNOTE DOCUMENTATION
#

# Set constants

software="subethaedit"
version="2.5"
type="Documentation"
helphome="SubEthaEditHelp.html"
referencehome="seehelp.html"
edition_pro="yes"
edition_lite="no"


homedir=/Users/dwagner//Data/TCM/svn/subethaedit-trunk/documentation/manual
docdir=$homedir/SubEthaEdit
helpdir=$docdir/SubEthaEditHelp
export JAVA_HOME="/System/Library/Frameworks/JavaVM.framework/Versions/1.4.2/Home"


# Validating

echo Validating XML files...
java Validate $docdir/xml
java Validate $homedir/shared
echo


# Tidy up source code

# echo Tidying up source codes...
# echo
# for arg in ${docdir}/xml/*.xml
# do
# 	cp $arg ${docdir}/xml/backup/$(basename $arg)
# 	echo $(basename $arg .xml)
# 	tidy -config $homedir/tidy.config $arg
# 	sed -i .sedbak 's/        /	/g' $arg
# 	rm ${arg}.sedbak
# done
# for arg in $homedir/shared/*.xml
# do
# 	cp $arg ${arg}.bak
# 	echo $(basename $arg .xml)
# 	tidy -config $homedir/tidy.config $arg
# 	sed -i .sedbak 's/        /	/g' $arg
# 	rm ${arg}.sedbak
# done
# echo

# Concatenating all XML files

echo Concatenating files...
java org.apache.xalan.xslt.Process -IN "${docdir}/filelist.xml" -XSL $homedir/etc/concatenate.xsl -OUT "${docdir}/temp.xml"

# Replacing ${software} with the software name

sed -i .bak 's/${software}/SubEthaEdit/g' "${docdir}/temp.xml"

# Build online help

echo Making Online Help...
rm ${helpdir}/pgs/*
java org.apache.xalan.xslt.Process -IN ${docdir}/temp.xml -PARAM software "$software" -PARAM version $version -PARAM type $type -PARAM edition_lite $edition_lite -PARAM edition_pro $edition_pro -PARAM helphome $helphome -XSL $homedir/help.xsl -OUT "${helpdir}/pgs/${referencehome}"

for arg in ${helpdir}/pgs/*.html
do
	cp $arg ${arg}.bak
	cat ${arg}.bak | grep -v '<?xml*' > $arg
	rm ${arg}.bak
done


# open "${docdir}/DEVONnoteHelp/DEVONnoteHelp.htm"

# Build PDF manuals

echo Making PDF Documentation...
# 
echo - Making: A5, landscape
# 
/usr/local/bin/xep.sh -quiet -xml "${docdir}/temp.xml" -xsl "$homedir/documentation.xsl" -param format=screen -param software="$software" -param version=$version -param type=$type -param edition_lite=$edition_lite -param edition_pro=$edition_pro  -pdf "${docdir}/SubEthaEditManual_Screen.pdf"
# 
# # open -a /Applications/Preview.app "${docdir}/DEVONnote_Manual_(screen).pdf"
# 
echo - Making: A4, portrait
# 
/usr/local/bin/xep.sh -quiet -xml "${docdir}/temp.xml" -xsl "$homedir/documentation.xsl" -param format=print -param software="$software" -param version=$version -param type=$type -param edition_lite=$edition_lite -param edition_pro=$edition_pro  -pdf "${docdir}/SubEthaEditManual_Print.pdf"
# 
# # rm "${docdir}/temp.xml"
# mv "${docdir}/DEVONnote_Manual_(print).pdf" "${docdir}/DEVONnote Manual (print).pdf"
# mv "${docdir}/DEVONnote_Manual_(screen).pdf" "${docdir}/DEVONnote Manual (screen).pdf"

echo Done.