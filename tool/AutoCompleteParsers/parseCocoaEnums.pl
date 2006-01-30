
# cat `find . -name "*.h"` | perl parseenums.pl > ~/Desktop/cocoaenums.txt
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
    if (/typedef enum/) {
        $enum = 1;
    }
}