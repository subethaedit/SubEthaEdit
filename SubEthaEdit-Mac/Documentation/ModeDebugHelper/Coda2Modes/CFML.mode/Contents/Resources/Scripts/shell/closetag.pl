#!/usr/bin/perl
use strict;

my $data = join "",<STDIN>;
$data =~ s/[\n\r]/ /g;          # throw out line breaks
$data =~ s/\A[^<]*//g;          # filter all characters up to first tag
$data =~ s/<!--.*?-->//g;       # strip comments
$data =~ s/(?<=>)[^<]*//g;      # remove everthing that's not a tag
$data =~ s/ .*?(\/?) *>/\1>/g;  # remove attributes
$data =~ s/\A<//g;              # remove everything up to the first <
$data =~ s/>[^>]*\Z//g;         # remove eyerthing after the last >
$data =~ s/ //g;

my @tags = split /></,$data;    # make array of tags
my @stack;

#print "Data:".$data."\n";

foreach my $tag (reverse @tags) {              # iterate through reversed xml tree
#    print "Tag:".$tag."\n";
    if ($tag =~ /^[\?\!]/) {next;}
    if ($tag =~ /[\/]$/) {next;}
    if ($tag =~ /^\//) {
        push @stack, $tag;
#        print "Pushing:".$tag."\n";
    } else {
        if ($stack[$#stack] eq "/$tag") {
#            print "Poping:".$tag."\n";
            pop @stack;
        } else {
#            print "Else:".$tag."\n";
            print "</$tag>"; exit(0);
        }
    }
}

exit(-1);