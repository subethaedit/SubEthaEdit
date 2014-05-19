#!/usr/bin/perl
use strict;

my $html = join "",<STDIN>;

$html =~ s/<head>/<head><base href="http:\/\/validator.w3.org\/"\/>/g;

open FILE, ">/tmp/w3cvalidationresult.html";
print FILE $html;
close FILE;

`open /tmp/w3cvalidationresult.html`;
#`rm -f /tmp/w3cvalidationresult.html`;
