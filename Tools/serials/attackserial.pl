#!/usr/bin/perl -w
use Math::BaseCalc;
use strict;
$| = 1;

my $calc36 = new Math::BaseCalc(digits=>[0..9,'A'..'Z']);
my $tries = 1000000; # Current hitrate: 9 in a million
my $hits = 0;

for(my $i=0;$i<$tries;$i++) {
    my $r1 = $calc36->to_base(int(rand($calc36->from_base("ZZZZ"))));
    my $r2 = $calc36->to_base(int(rand($calc36->from_base("ZZZZ"))));
    my $r3 = $calc36->to_base(int(rand($calc36->from_base("ZZZZ"))));
    my $serial = "SEE-$r1-$r2-$r3";
    if (checkserial($serial)) {
        print "Valid: $serial\n";
        $hits++;
    }
}

if ($hits) {
    print "\nPropability: 1 to ".($tries/$hits)."\n";
}

sub checkserial {
    (my $input) = @_;
    if ($input =~ /...-....-....-..../) {
        (my $prefix, my $rest) = ($input =~ /(...)-(....-....-....)/);
        $rest =~  s/^(.)(.)(.)(.)-(.)(.)(.)(.)-(.)(.)(.)(.)/$8$2$9$11-$1$12$5$4-$6$3$10$7/;
        (my $group1, my $group2, my $group3) = ($rest =~ /(....)-(....)-(....)/);
        
        my $prefixnum = $calc36->from_base($prefix);
        my $number = $calc36->from_base($group1);
        my $randomnumber = $calc36->from_base($group2);
        my $chksum = $calc36->from_base($group3);
        
        if ((($randomnumber % 42)==0) and ($randomnumber >= (42*1111))) {
            if (((($prefixnum+$number+$randomnumber+$chksum) % 4242)==0) and ($chksum >= (42*1111))) {
                return 42;
            } else {
                return 0;
            }
        } else {
            return 0;
        }
    } else {
        #print "Not a serial\n";
        return 0;
    }
}