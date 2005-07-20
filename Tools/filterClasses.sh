find /System/Library/Frameworks/ -name "*.h" | xargs cat | grep "@interface" | perl -npe "s/^\s*\t*(.pragma mark )?.interface //g;s/[ (].*$//g;" | sort | uniq > ~/Desktop/classes.txt
