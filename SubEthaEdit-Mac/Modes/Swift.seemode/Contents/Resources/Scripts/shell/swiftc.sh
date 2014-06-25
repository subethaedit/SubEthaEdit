#!/bin/sh

# note that this needs command line tools selected that support swift
# you can choose your command line tools at the bottom of the "Locations" pref pane of Xcode
SWIFT=$(/usr/bin/env xcrun -f swift)

SCRIPTPATH=$1
COMPILEDPATH="$SCRIPTPATH.o"

SDKPATH=$(/usr/bin/env xcrun --show-sdk-path --sdk macosx)

#compile if necessary
if [ $SCRIPTPATH -nt $COMPILEDPATH ]; then
	$SWIFT -o "$COMPILEDPATH" -sdk "$SDKPATH" "$SCRIPTPATH"
	if [ $? -ne 0 ]; then
		exit $?
	fi
fi

# ${@:n} passes on all arguments, sarting with the nth, "${@:n}" makes it work iwth escaped arguments as well (spaces, etc)
$COMPILEDPATH "${@:2}"

