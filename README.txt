Create a keychain
# security -v create-keychain certkc.keychain

Create server certificate:
# certtool c k=certkc.keychain x=S

Verify encrypted traffic
# sudo tcpdump -i lo0 -vvv -A -s 0 'tcp port 6942'




AppleScript issues:
* tell application "SubEthaEdit" to set startCharacterIndex of selection to nextCharacterIndex of selection", doesn't work with sdef on 10.4 but on 10.5, most probably the last object specifier isn't evaluated immediately on 10.4
-> Want to use only sdef on 10.4 and 10.5
-> Ask Marc Picirelli (Wed. 2:00 PM, Russian Hill)
-> Create an sdef file for both 10.4 and 10.5 then use sdp to create .scriptSuite/.scriptTerminology on both 10.4 and 10.5

Resolve symbols:
% echo 'info line *0x2696' > /tmp/gdbcmds
% gdb --batch --quiet -x /tmp/gdbcmds gdb-i386-apple-darwin.dSYM/ Contents/Resources/DWARF/gdb-i386-apple-darwin
Line 28 of "/tmp/gdb.roots/gdb/src/gdb/gdb.c" starts at address 0x2696 <main> and ends at 0x269d <main+7>.


10.5: with atos

#!/bin/bash

AWK_SCRIPT=/tmp/symbolizecrashlog_$$.awk
SH_SCRIPT=/tmp/symbolizecrashlog_$$.sh

if [[ $# < 2 ]]
then
	echo "Usage: $0 [ -arch <arch> ] symbol-file [ crash.log, ... ]"
	exit 1
fi

ARCH_PARAMS=''
if [[ "${1}" == '-arch' ]]
then
	ARCH_PARAMS="-arch ${2}"
	shift 2
fi

SYMBOL_FILE="${1}"
shift

cat > "${AWK_SCRIPT}" << _END
/^[0-9]+ +[-._a-zA-Z0-9]+ *\t0x[0-9a-fA-F]+ / {
	addr_index = index(\$0,\$3);
	end_index = addr_index+length(\$3);
	line_legnth = length;
	printf("echo '%s'\"\$(symbolize %s '%s')\"\n",substr(\$0,1,end_index),
		\$3,substr(\$0,end_index+1,line_legnth-end_index));
	next;
	}
{ gsub(/'/,"'\\\\''"); printf("echo '%s'\n",\$0); }
_END

function symbolize()
{
	# Translate the address using atos
	SYMBOL=$(atos -o "${SYMBOL_FILE}" ${ARCH_PARAMS} "${1}" 2>/dev/null)
	# If successful, output the translated symbol. If atos returns an address, output the original symbol
	if [[ "${SYMBOL##0x[0-9a-fA-F]*}" ]]
	then
		echo -n "${SYMBOL}"
	else
		echo -n "${2}"
	fi
}

awk -f "${AWK_SCRIPT}" $* > "${SH_SCRIPT}"

. "${SH_SCRIPT}"

rm -f "${AWK_SCRIPT}" "${SH_SCRIPT}"