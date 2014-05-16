#!/usr/bin/perl
use strict;

my $html = join "",<STDIN>;

$html =~ s/<head>/<head><base href="http:\/\/validator.w3.org\/"\/>/g;

open FILE, ">/tmp/cssvalidationresult.html";
print FILE $html;
close FILE;

`open /tmp/cssvalidationresult.html`;
