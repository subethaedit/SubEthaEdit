#!/usr/bin/perl -w
use strict;
use Math::BaseCalc;

my $calc36 = new Math::BaseCalc(digits=>[0..9,'A'..'Z']);

while (<>) {
    my $input = $_;
    chomp($input);
    checkserial($input);
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
        
        print "Serial pretends to be # $number\n";
        
        if ((($randomnumber % 42)==0) and ($randomnumber >= (42*1111))) {
            print "Random number check : YES\n";
            
            if (((($prefixnum+$number+$randomnumber+$chksum) % 4242)==0) and ($chksum >= (42*1111))) {
                print "Checksum check : YES\n";
                return 42;
            } else {
                print "Checksum check : NO\n";
                return 0;
            }
            
        } else {
            print "Random number check : NO\n";
            return 0;
        }
    
    } else {
        print "Not a serial\n";
        return 0;
    }
}