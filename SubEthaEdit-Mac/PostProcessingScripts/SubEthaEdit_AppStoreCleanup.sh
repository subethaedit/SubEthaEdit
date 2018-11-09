#!/bin/sh


# De-Sparkle if necessary
if [ -n "$TCM_APP_STYLE" ] ; 
then
  echo "Non App Store version - Nothing to do."
  exit 0  
fi


echo "Cleaning up files."
# Remove SU key from plist
BUNDLE_CONTENTS_PATH="${CONFIGURATION_BUILD_DIR}/${CONTENTS_FOLDER_PATH}"

INFO_PLIST_PATH="${BUNDLE_CONTENTS_PATH}/Info.plist"

echo $INFO_PLIST_PATH
plutil -remove SUPublicDSAKeyFile "${INFO_PLIST_PATH}"

# Remove Sparkle XPCServices (currently all xpc services)
rm -rf "${BUNDLE_CONTENTS_PATH}/XPCServices"

# Remove Sparkle Framework
rm -rf "${BUNDLE_CONTENTS_PATH}/Frameworks/Sparkle.framework"

# Remove name of Sparkle in binary
install_name_tool -change @rpath/Sparkle.framework/Versions/A/Sparkle @rpath/ "${CONFIGURATION_BUILD_DIR}/${EXECUTABLE_PATH}"

# Add see-tool installer pkg
cp "${SOURCE_ROOT}/Resources/SharedSupport/see-tool.pkg" "${BUNDLE_CONTENTS_PATH}/SharedSupport/"

# Remove see binary
rm "${BUNDLE_CONTENTS_PATH}/SharedSupport/bin/see"