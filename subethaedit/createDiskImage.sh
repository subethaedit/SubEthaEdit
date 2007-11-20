dmgSize=${DiskImageSizeInMB}
dmgBasePath="${TARGET_BUILD_DIR}/${DiskImageVolumeName}"

echo "Removing zip file ${dmgBasePath}.zip"
rm -f "${dmgBasePath}.zip"
if [ x${ACTION} = xclean ]; then
	exit 0
fi

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
echo "Creating Zip file ${dmgBasePath}..."
zip -9 -r -y "${dmgBasePath}.zip" "${BUILT_PRODUCTS_DIR}/${DiskImageProduct}"
echo "...done"

# -------------------------

echo "Archiving deployment image and dSYM files..."
echo

REV=`/usr/local/bin/svnversion -n "${SRCROOT}"`
dmgBasePath="${TARGET_BUILD_DIR}/${DiskImageVolumeName}-${REV}"
echo "Creating ${dmgSize} MB disk image named '${DiskImageVolumeName}-${REV}'..."
rm -f "${dmgBasePath}.dmg"
hdiutil create "${dmgBasePath}.dmg" -volname "${DiskImageVolumeName}-${REV}" -megabytes ${dmgSize} -layout NONE -fs HFS+ -quiet
if [ $? != 0 ]; then
	echo error:0: Failed to create disk image at ${dmgBasePath}.dmg
	exit 1
fi
echo "...done"
echo

echo "Mounting newly created disk image..."
hdidOutput=`hdiutil mount "${dmgBasePath}.dmg" | grep '/dev/disk[0-9]*' | awk '{print $1}'`
mountedDmgPath="/Volumes/${DiskImageVolumeName}-${REV}"
if [ $? != 0  -o  ! -x "${mountedDmgPath}" ]; then
	echo error:0: Failed to mount newly created disk image at ${dmgBasePath}.dmg
	exit 1
fi
sleep 2
echo "...done"
echo

echo "Copying..."
cp -Rpv "${TARGET_BUILD_DIR}/${DiskImageProduct}" "${mountedDmgPath}"
cp -Rpv "${TARGET_BUILD_DIR}/SubEthaEdit.zip" "${mountedDmgPath}"
cp -Rpv "${TARGET_BUILD_DIR}/HDCrashReporter.framework.dSYM" "${mountedDmgPath}"
cp -Rpv "${TARGET_BUILD_DIR}/Sparkle.framework.dSYM" "${mountedDmgPath}"
cp -Rpv "${TARGET_BUILD_DIR}/OgreKit.framework.dSYM" "${mountedDmgPath}"
cp -Rpv "${TARGET_BUILD_DIR}/see.dSYM" "${mountedDmgPath}"
cp -Rpv "${TARGET_BUILD_DIR}/SubEthaEditHelperToolTemplate.dSYM" "${mountedDmgPath}"
cp -Rpv "${TARGET_BUILD_DIR}/SubEthaEdit.app.dSYM" "${mountedDmgPath}"
cp -Rpv "${TARGET_BUILD_DIR}/UniversalDetector.framework.dSYM" "${mountedDmgPath}"
cp -Rpv "${TARGET_BUILD_DIR}/SeeTextImporter.mdimporter.dSYM" "${mountedDmgPath}"
cp -Rpv "${TARGET_BUILD_DIR}/HMBlkAppKit.framework.dSYM" "${mountedDmgPath}"
cp -Rpv "${TARGET_BUILD_DIR}/PSMTabBarControl.framework.dSYM" "${mountedDmgPath}"
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

echo "Completed archiving of deployment image and dSYM files..."
echo

# -------------------------

osascript -e "tell application \"Finder\"" -e "select posix file \"${TARGET_BUILD_DIR}/${DiskImageVolumeName}.zip\"" -e "end tell" > /dev/null

exit 0
