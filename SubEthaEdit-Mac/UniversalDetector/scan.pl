#!/usr/bin/perl

use strict;

my %charsets;

for(@ARGV)
{
	open FILE,$_ or die;
	$_=do {local $/; <FILE>};

#	$charsets{$1}=1 while(/SequenceModel.*?=.*?\{[^}"]+"([^"]*)"[^}]+\}/gs);
	$charsets{$1}=1 while(/"([A-Za-z0-9_\-]+)"/g);
}

print join "\n",sort keys %charsets;
print "\n";