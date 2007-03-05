while (<>) {
    $input = $_;
    chomp($input);
    if ($input =~ /^[+-]/) {
        $input =~ s/: *\([^\)]*\) *[a-zA-Z0-9]*/:/g;
        $input =~ s/(\t| +|\([^\)]*\))/ /g;
        $input =~ s/;.*//g;
        $input =~ s/, ...//g;
        $input =~ s/ +/ /g;
        $input =~ s/^[+-]//g;
        $input =~ s/^ +//g;
        $input =~ s/ {//g;
        $input =~ s/ +$//g;

        $result = `grep "$input" /Users/pittenau/svn/codingmonkeys/subethaedit/trunk/subethaedit/Modes/Objective-C.mode/Contents/Resources/AutocompleteAdditions.txt`;
        if ($result eq '') {
            print $input."\n";
        } 

    }
}