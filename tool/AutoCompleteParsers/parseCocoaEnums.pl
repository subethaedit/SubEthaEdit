
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
                
                $foo = `grep ">$result<" /Users/pittenau/svn/codingmonkeys/subethaedit/trunk/subethaedit/Modes/Objective-C.mode/Contents/Resources/SyntaxDefinition.xml`;
                if ($foo ne '') {
                    print $result."\n";
                } 
            }
        }
    }
    if (/typedef enum/) {
        $enum = 1;
    }
}