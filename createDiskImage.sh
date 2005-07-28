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
chgrp -R admin "${BUILT_PRODUCTS_DIR}/${DiskImageProduct}"
echo "...done"
echo "Setting permissions..."
chmod -R g+w "${BUILT_PRODUCTS_DIR}/${DiskImageProduct}"
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
          -e " 	  set myPosition to position of container window of mountedDiskImage" \
          -e "    set bounds of container window of mountedDiskImage to {item 1 of myPosition, item 2 of myPosition, (item 1 of myPosition) + 384 + sidebar width of container window of mountedDiskImage, (item 2 of myPosition) + 384}" \
          -e "    set current view of container window of mountedDiskImage to icon view" \
          -e "    set toolbar visible of container window of mountedDiskImage to false" \
          -e "    set statusbar visible of container window of mountedDiskImage to false" \
          -e "    set icon size of icon view options of container window of mountedDiskImage to 128" \
          -e "    set text size of icon view options of container window of mountedDiskImage to 16" \
          -e "    set arrangement of icon view options of container window of mountedDiskImage to not arranged" \
          -e "    set myApplicationFile to get application file \"${DiskImageProduct}\" of container window of mountedDiskImage" \
          -e "    set position of myApplicationFile to {384 / 2, 304 / 2}" \
          -e "end tell" \
          > /dev/null
echo "...done"
echo

echo -n "Finder syncs .DS_Store "
LIMIT=10
for ((a=1; a <= LIMIT ; a++))
do
  echo -n .
  sleep 1
done
echo
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
hdiutil internet-enable -yes "${dmgBasePath}.dmg"
echo "...done"
echo

osascript -e "tell application \"Finder\"" -e "select posix file \"${TARGET_BUILD_DIR}/${DiskImageVolumeName}.dmg\"" -e "end tell" > /dev/null

exit 0
