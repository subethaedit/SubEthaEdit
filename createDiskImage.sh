#! /bin/sh
#
# createDiskImage

# Requires three or more args
if [ $# -lt 3 ] ; then
    echo "usage: $0 <ImageSizeInMegabytes> <NameOfImageWithNoExtension> <FolderToCopyToImage> ..."
    exit 1
fi

# Grab the size and image name arguments.  Leave the rest of them in $*
imageSize=$1
shift
imageName=$1
shift

# Create the image and format it
echo
echo "Creating ${imageSize} MB disk image named ${imageName}..."

rm -f ${imageName}.dmg
hdiutil create ${imageName}.dmg -megabytes ${imageSize} -layout NONE

hdidOutput=`hdid -nomount ${imageName}.dmg | grep '/dev/disk[0-9]*' | awk '{print $1}'`

/sbin/newfs_hfs -w -v ${imageName} -b 4096  ${hdidOutput}

hdiutil eject ${hdidOutput}

# Mount the image and copy stuff
hdidOutput=`hdid ${imageName}.dmg | grep '/dev/disk[0-9]*' | awk '{print $1}'`
sleep 4 # This sleep is needed and there seems to be no way to know when the image is mounted...

echo "Copying contents to ${imageName}..."
while [ $# -gt 0 ] ; do
    echo "...cleaning ${1}"
    find ${1} -name ".svn" -exec rm -rf "{}" \;
    echo "...setting ownership"
    /usr/sbin/chown -R root:admin ${1}
    echo "...setting permissions"
    /bin/chmod -R ug+w ${1}
    echo "...copying ${1}"
    /Developer/Tools/CpMac -r ${1} /Volumes/${imageName}
    shift
done

hdiutil eject ${hdidOutput}

# Compress the image
echo "Compressing ${imageName} disk image..."

mv ${imageName}.dmg ${imageName}.orig.dmg
hdiutil convert ${imageName}.orig.dmg -format UDCO -o ${imageName}
rm ${imageName}.orig.dmg

# Internet-enable the image
echo "Internet-enabling ${imageName} disk image..."
hdiutil internet-enable -yes ${imageName}.dmg

echo "Done."
echo
