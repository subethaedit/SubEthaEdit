#!/usr/bin/perl
use strict;

my $data = join "",<STDIN>;
$data =~ s/([^\n\r])([\n\r][\n\r])([^\n\r])/\1TheCodingMonkeysTheCodingMonkeysTheCodingMonkeysTheCodingMonkeysTheCodingMonkeysNewLineBackupTheCodingMonkeysTheCodingMonkeysTheCodingMonkeysTheCodingMonkeysTheCodingMonkeysNewLineBackup\3/g;
$data =~ s/([\n\r][^\n\r]{1,60}[\n\r])/\1TheCodingMonkeysTheCodingMonkeysTheCodingMonkeysTheCodingMonkeysTheCodingMonkeysNewLineBackup/g;

$data =~ s/([^\n\r]) *[\n\r] *([^\n\r])/\1 \2/g;

$data =~ s/TheCodingMonkeysTheCodingMonkeysTheCodingMonkeysTheCodingMonkeysTheCodingMonkeysNewLineBackup/\n/g;

print $data;