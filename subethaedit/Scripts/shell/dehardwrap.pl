#!/usr/bin/perl
#use strict;

my @lines = <STDIN>;
my $maxlinewidth = 0;

foreach my $line (@lines) {
    if (length($line)-1>$maxlinewidth) {$maxlinewidth=length($line)-1}
}

my $nextLine;
my $thisLine;
my $i;

for ($i=0;$i<$#lines;$i++) {
    
    $thisLine = $lines[$i];
    $nextLine = $lines[$i+1];
    
    if ((length($thisLine) > (max(20,$maxlinewidth*0.8))) and ($nextLine =~ /[^\n\r\t ]/)) {
        $thisLine =~ s/[\n\r]/ /g;
        $thisLine =~ s/ +$/ /g;
        $lines[$i+1] =~ s/^ +//g;
    }
    
        print $thisLine;
}

print $lines[$#lines];


sub max { 
    if ($_[0]<$_[1]) {return $_[1]} else {return $_[0]}; 
}