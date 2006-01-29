#!/usr/bin/perl -w
use strict;
use Math::BaseCalc;

my $calcHex = new Math::BaseCalc(digits=>[0..9,'A'..'F']);


(my $red, my $green, my $blue) = @ARGV;
my $r = leadingzero($calcHex->to_base($red * 255));
my $g = leadingzero($calcHex->to_base($green * 255));
my $b = leadingzero($calcHex->to_base($blue * 255));

print "#$r$g$b\n";


sub leadingzero {
    (my $s) = @_;
    if (length($s) == 1) {$s = "0$s";}
    return $s;
}
