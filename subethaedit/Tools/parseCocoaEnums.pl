
# cat `find . -name "*.h"` | perl ~/.svn/subethaedit/subethaedit/Tools/parseCocoaEnums.pl | sort | uniq > ~/Desktop/cocoaenums.txt
$enum = 0;

while (<>) {
    $line = $_;
    if (/\}/) {
        $enum = 0;
    }
    if ($enum == 1) {
        @stuff = split /[ ,]/,$line;

        foreach $part (@stuff) {
            if ($part =~ /(^[ \t]*NS[A-Za-z]+)/) {
                $result = $1;
                $result =~ s/[ \t]//g;
                print "$result\n";
            }
        }
    }
    if (/enum/) {
        $enum = 1;
    }
}