
$filename = $ARGV[0];
$file = `cat $filename`;
$file =~ s/\n/ /g;
#print $file;


if ($file =~ /-module\((.*?)\)/) {
    $modulename = $1;
    $modulename =~ s/[ \t\[\]\r\n]//g;
#    print "\n\nModule: ".$modulename.":\n";
}

if ($modulename =~ /[^A-Za-z_0-9]/) {exit;}

@parts = split /-export\(/,$file;

for($i=1;$i<=$#parts;$i++) {
    $exports = $parts[$i];
    $exports =~ s/\).*//g;
    $exports =~ s/[ \t\[\]\r\n]//g;
    $exports =~ s/\/\d/\(\)/g;
    
    @methods = split /,/,$exports;
    
    foreach $method (@methods) {
    unless ($method =~ /['\.\/%"~]/) {
    
    print $modulename.":".$method."\n";
    print $method."\n";
    } else {
    print STDERR "'".$method."'\n";
    
    }

    }
}



