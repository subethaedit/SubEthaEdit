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
        $input =~ s/^ //g;
        print $input."\n";
    }
}