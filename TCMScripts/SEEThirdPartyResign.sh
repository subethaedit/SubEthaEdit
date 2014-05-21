#!/bin/sh

#############################################################################################
# Apply a codesigning to a given file of app
# Argument $1 = developer certificate name
# Argument $2 = path og Mach-o
# Argument $3 = optional arguments
#############################################################################################
function _app_signing_apply_resign()
{
	local certificate="${1}"
	local path="${2}"
	local entitlements="${3}"
	local prefix="${4}"

	local workspace=$(pwd)
	local tmp="/tmp/$RANDOM"
	local tmp_entitlement="/tmp/$RANDOM"

	# extract entitlements from Binary
	local macho_entitlements=$(codesign --display --entitlements=- "${path}" 2>/dev/null)
	local macho_entitlements=${macho_entitlements##*<?xml}

	local entitlement_file=""

	export CODESIGN_ALLOCATE=`xcode-select -print-path`/Toolchains/XcodeDefault.xctoolchain/usr/bin/codesign_allocate

	# sign with entitlements
	if [[ "${macho_entitlements}" != "" ]]; then

		# save entitlement to file
		entitlement_file=$(basename "${path}")
		entitlement_file="${workspace}/${entitlement_file}.entitlement"

		# make valid XML file end export it
		macho_entitlements="<?xml${macho_entitlements}"

		codesign --force --verbose=2 --sign="${certificate}" --entitlements "${entitlement_file}" --timestamp=none --preserve-metadata=i,res "${path}" 2>| $tmp

		$(rm -f "${entitlement_file}")

	# sign without entitlements
	else

		# use entitlement
		if [[ "${entitlements}" != "" ]]; then
	   		if [[ "${prefix}" != "" ]]; then
		   		echo "${prefix}" "${entitlements}"
				codesign --force --verbose=3 --sign="${certificate}" --entitlements "${entitlements}" --prefix "${prefix}" --timestamp=none --preserve-metadata=res "${path}" # 2>| $tmp
			else
				codesign --force --verbose=3 --sign="${certificate}" --entitlements "${entitlements}"  --timestamp=none --preserve-metadata=i,res "${path}" # 2>| $tmp
			fi
		#without entitlements
		else
			codesign --force --verbose=3 --sign="${certificate}" --timestamp=none --preserve-metadata=i,res "${path}" # 2>| $tmp
		fi
	fi
}

path_xpcservice="${CONFIGURATION_BUILD_DIR}/${XPCSERVICES_FOLDER_PATH}"
path_plugins="${CONFIGURATION_BUILD_DIR}/${PLUGINS_FOLDER_PATH}"
path_frameworks="${CONFIGURATION_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
path_resources="${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
path_spotligth="${CONFIGURATION_BUILD_DIR}/${CONTENTS_FOLDER_PATH}/${LOCAL_LIBRARY_DIR}/Spotlight"
sign_sh1=$(security find-identity -v | grep "${CODE_SIGN_IDENTITY}:" | awk '{print $2}' | sed -e '2,$d')

# Frameworks
_app_signing_apply_resign "${sign_sh1}" "${path_frameworks}/OgreKit.framework/Versions/A/OgreKit"
_app_signing_apply_resign "${sign_sh1}" "${path_frameworks}/PSMTabBarControl.framework/Versions/A/PSMTabBarControl"
_app_signing_apply_resign "${sign_sh1}" "${path_frameworks}/TCMPortMapper.framework/Versions/A/TCMPortMapper"
_app_signing_apply_resign "${sign_sh1}" "${path_frameworks}/UniversalDetector.framework/Versions/A/UniversalDetector"

# make sure sub frameworks are signed before signing outer framework
_app_signing_apply_resign "${sign_sh1}" "${path_frameworks}/HockeySDK.framework/Versions/A/HockeySDK"

#spotlight plugins
_app_signing_apply_resign "${sign_sh1}" "${path_spotligth}/SeeTextImporter.mdimporter/Contents/MacOS/SeeTextImporter"

#luac in lua mode
_app_signing_apply_resign "${sign_sh1}" "${path_resources}/Modes/Lua.seemode/Contents/Resources/Scripts/shell/luac" "${SRCROOT}/LuaC.entitlements" "org.lua."
