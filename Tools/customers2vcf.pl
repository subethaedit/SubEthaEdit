#!/usr/bin/perl

while (<>) {
    $input = $_;
    $input = s/"//g;  #"
    ($lastOrderID, $company, $first, $last, $addr1, $addr2, $city,
     $state, $postal, $country, $phone, $fax, $email) = split /\t/;
    
    open (CARD,">$first$last.vcf");
    print CARD "BEGIN:VCARD\nVERSION:3.0\n";
    print CARD "N:$last;$first;;;\n";
    print CARD "FN:$first $last\n";
    print CARD "ORG:$company;\n";
    print CARD "EMAIL;type=INTERNET;type=WORK;type=pref:$email\n";
    print CARD "TEL;type=WORK;type=pref:$phone\n";
    print CARD "item1.ADR;type=HOME;type=pref:;;$addr1 $addr2;$city\, $state;;$postal;$country\n";
    print CARD "CATEGORY:SEE Customers\n";
    print CARD "END:VCARD\n";
    close CARD;
}