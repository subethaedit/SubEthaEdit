dmgSize=${DiskImageSizeInMB}
dmgBasePath="${TARGET_BUILD_DIR}/${DiskImageVolumeName}"

if [ x${ACTION} = xclean ]; then
	echo "Removing disk image ${dmgBasePath}.dmg"
	rm -f "${dmgBasePath}.dmg"
	exit 0
fi

echo "Creating ${dmgSize} MB disk image named '${DiskImageVolumeName}'..."
rm -f "${dmgBasePath}.dmg"
hdiutil create "${dmgBasePath}.dmg" -volname "${DiskImageVolumeName}" -megabytes ${dmgSize} -layout NONE -fs HFS+ -quiet
if [ $? != 0 ]; then
	echo error:0: Failed to create disk image at ${dmgBasePath}.dmg
	exit 1
fi
echo "...done"
echo

echo "Mounting newly created disk image..."
hdidOutput=`hdiutil mount "${dmgBasePath}.dmg" | grep '/dev/disk[0-9]*' | awk '{print $1}'`
mountedDmgPath="/Volumes/${DiskImageVolumeName}"
if [ $? != 0  -o  ! -x "${mountedDmgPath}" ]; then
	echo error:0: Failed to mount newly created disk image at ${dmgBasePath}.dmg
	exit 1
fi
sleep 2
echo "...done"
echo

echo "Removing .svn directories..."
find "${BUILT_PRODUCTS_DIR}/${DiskImageProduct}" -name ".svn" -exec rm -rvf "{}" \;
echo "...done"
echo
echo "Setting ownership..."
/usr/sbin/chown -R root:admin "${BUILT_PRODUCTS_DIR}/${DiskImageProduct}"
echo "...done"
echo "Setting permissions..."
/bin/chmod -R g+w "${BUILT_PRODUCTS_DIR}/${DiskImageProduct}"
echo "...done"
echo
echo "Copying contents to ${dmgBasePath}..."
ditto -V -rsrc "${BUILT_PRODUCTS_DIR}/${DiskImageProduct}" "${mountedDmgPath}/${DiskImageProduct}"
echo "...done"
echo
echo "${mountedDmgPath}"

echo "Configuring folder properties..."
osascript -e "tell application \"Finder\"" \
          -e "    set mountedDiskImage to disk \"${DiskImageVolumeName}\"" \
          -e "    open mountedDiskImage" \
          -e "    tell container window of mountedDiskImage" \
          -e "        set toolbar visible to false" \
          -e "        set current view to icon view" \
          -e "    end tell" \
          -e "    set icon size of icon view options of container window of mountedDiskImage to 128" \
          -e "end tell" \
          > /dev/null
echo "...done"
echo

echo "Unmounting disk image..."
hdiutil eject -quiet ${hdidOutput}
echo "...done"
echo

echo "Compressing disk image..."
mv "${dmgBasePath}.dmg" "${dmgBasePath}-orig.dmg"
hdiutil convert "${dmgBasePath}-orig.dmg" -format UDZO -o "${dmgBasePath}"
if [ $? != 0 ]; then
	echo error:0: Failed to compress newly created disk image at ${dmgBasePath}.dmg
	exit 1
fi
rm "${dmgBasePath}-orig.dmg"
echo "...done"
echo

echo "Internet-enabling ${dmgBasePath}.dmg disk image..."
hdiutil internet-enable -yes ${dmgBasePath}.dmg
echo "...done"
echo

osascript -e "tell application \"Finder\"" -e "select posix file \"${TARGET_BUILD_DIR}/${DiskImageVolumeName}.dmg\"" -e "end tell" > /dev/null

exit 0

# #! /bin/sh
# #
# # createDiskImage
# 
# # Requires three or more args
# if [ $# -lt 3 ] ; then
#     echo "usage: $0 <ImageSizeInMegabytes> <NameOfImageWithNoExtension> <FolderToCopyToImage> ..."
#     exit 1
# fi
# 
# # Grab the size and image name arguments.  Leave the rest of them in $*
# imageSize=$1
# shift
# imageName=$1
# shift
# 
# # Create the image and format it
# echo
# echo "Creating ${imageSize} MB disk image named ${imageName}..."
# 
# rm -f ${imageName}.dmg
# hdiutil create ${imageName}.dmg -megabytes ${imageSize} -layout NONE
# 
# hdidOutput=`hdid -nomount ${imageName}.dmg | grep '/dev/disk[0-9]*' | awk '{print $1}'`
# 
# /sbin/newfs_hfs -w -v ${imageName} -b 4096  ${hdidOutput}
# 
# hdiutil eject ${hdidOutput}
# 
# # Mount the image and copy stuff
# hdidOutput=`hdid ${imageName}.dmg | grep '/dev/disk[0-9]*' | awk '{print $1}'`
# sleep 4 # This sleep is needed and there seems to be no way to know when the image is mounted...
# 
# echo "Copying contents to ${imageName}..."
# while [ $# -gt 0 ] ; do
#     echo "...cleaning ${1}"
#     find ${1} -name ".svn" -exec rm -rf "{}" \;
#     echo "...setting ownership"
#     /usr/sbin/chown -R root:admin ${1}
#     echo "...setting permissions"
#     /bin/chmod -R g+w ${1}
#     echo "...copying ${1}"
#     /Developer/Tools/CpMac -r ${1} /Volumes/${imageName}
#     shift
# done
# 
# hdiutil eject ${hdidOutput}
# 
# # Compress the image
# echo "Compressing ${imageName} disk image..."
# 
# mv ${imageName}.dmg ${imageName}.orig.dmg
# hdiutil convert ${imageName}.orig.dmg -format UDCO -o ${imageName}
# rm ${imageName}.orig.dmg
# 
# # Internet-enable the image
# echo "Internet-enabling ${imageName} disk image..."
# hdiutil internet-enable -yes ${imageName}.dmg
# 
# echo "Done."
# echo
