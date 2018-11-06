#!/bin/sh

# Only for Mac App Store Build
if [ -n "$TCM_APP_STYLE" ] ; 
then
  echo "Non App Store version - Nothing to do."
  exit 0  
fi



BUNDLE_CONTENTS_PATH="${CONFIGURATION_BUILD_DIR}/${CONTENTS_FOLDER_PATH}"
BUNDLE_RESOURCES_DIR="${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"

sign_sh1=$(security find-identity -v | grep "${CODE_SIGN_IDENTITY}:" | awk '{print $2}' | sed -e '2,$d')

# luac in lua mode
echo sign luac tool with entitlements "${BUNDLE_RESOURCES_DIR}/Modes/Lua.seemode/Contents/Resources/Scripts/shell/luac" "${SRCROOT}/LuaC.entitlements"
codesign --force -s ${sign_sh1} --entitlements "${SRCROOT}/LuaC.entitlements" -o runtime  "${BUNDLE_RESOURCES_DIR}/Modes/Lua.seemode/Contents/Resources/Scripts/shell/luac"

