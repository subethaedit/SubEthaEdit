
while(<>) {
    $foo = $_;
    if ($foo =~ /^\@interface.([A-Za-z]+)/) {
        $class = $1;
        $result = `grep ">$class<" /Users/pittenau/svn/codingmonkeys/subethaedit/trunk/subethaedit/Modes/Objective-C.mode/Contents/Resources/SyntaxDefinition.xml /Users/pittenau/svn/codingmonkeys/subethaedit/trunk/subethaedit/Modes/Objective-C.mode/Contents/Resources/AutocompleteAdditions.txt`;
        if ($result eq '') {
            print $class."\n";
        } 
    }
}