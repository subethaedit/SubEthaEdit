#!/bin/sh

#  TCM_GenerateRevisionConfig.sh
#  Created by Michael Ehrmann on 21.10.13.

# this script needs to be included in the app build scheme prebuild phase using
# ${SRCROOT}/../TCMScripts/TCM_GenerateRevisionConfig.sh

# You can override TCM_WORKSPACE_ROOT to have a differnt repository layout. Default is having a BuildConfig folder on ../${SOURCE_ROOT}
# YOU CAN CHANGE THIS by defining custom build setting called TCM_WORKSPACE_ROOT

if [ -n "${TCM_WORKSPACE_ROOT}" ]; then
echo "TCM_WORKSPACE_ROOT set by project to ${TCM_WORKSPACE_ROOT}"
else
echo "TCM_WORKSPACE_ROOT not set by project, using ${SOURCE_ROOT}/../"
TCM_WORKSPACE_ROOT="${SOURCE_ROOT}/../"
fi


# generate app revision numbers
cd "${TCM_WORKSPACE_ROOT}"
REV_SHA1=`git rev-parse HEAD`

# count all the comits which make up the current revision we add 10.000 to this changecount to avoid collitions with former svn revision numbers
GIT_REV=`git rev-list HEAD | wc -l;`
REV=`echo $(( ${GIT_REV}+4000 ))` # adding 4000 to identify a GIT revision

if [ `git ls-files -m | wc -l` -gt 0 ]; then
if [ -n "$TCM_APP_STYLE" ]; then
	MODIFIED="+"
fi
fi

cd -

echo "Setting TCM_APP_REVISION   ${REV}${MODIFIED}"
echo "Setting TCM_APP_REVISION_HASH ${REV_SHA1}"
echo "Setting TCM_APP_BUILD_STYLE ${CONFIGURATION}"

# write the TCMRevision xcconfig into TCMShared buildconfig location
echo "TCM_APP_REVISION = ${REV}${MODIFIED}\nTCM_APP_REVISION_HASH = ${MODIFIED}${REV_SHA1}\nTCM_APP_BUILD_STYLE = ${CONFIGURATION}\n" > "${TCM_WORKSPACE_ROOT}BuildConfig/TCMRevision.xcconfig"

