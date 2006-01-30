#!/usr/bin/perl

push @states, "default";

open(FUNCTIONS, ">>functions.txt");
open(ENUMS, ">>enums.txt");
open(STRUCTS, ">>structs.txt");
open(DEFINES, ">>defines.txt");
open(TYPEDEFS, ">>typedefs.txt");


while(<STDIN>) {
    $line = $_;
    $state = pop @states;
    push @states,$state;
        
    $line =~ s/\/\*.*\*\///g;

    if ($line =~ /^#define\s+([\w\d_]+)/) {
        print DEFINES $1."\n";
    }

    if ($line =~ /typedef\s+([\w\d_]+)/) {
        print TYPEDEFS $1."\n";
    }

    if ($line =~ /^#/) {next;}
    
    if ($state eq "default") {
        
        if ($line =~ /([\w\d_]+)\s*\(/) {
            #print $1."()\n";
            print FUNCTIONS $1."\n";
        } elsif ($line =~ /struct\s([\w\d_]+)/) {
            #print $1."-\n";
            print STRUCTS $1."\n";
        }
        
    } elsif ($state eq "enum") {
        if ($line =~ /^\s*([\w\d_]+)/) {
            #print $1."\n";
            print ENUMS $1."\n";
        }
        if ($line =~ /}/) {
            pop @states;
        }
    
    }
    
    if ($line =~ /\/\*/) {
        push @states, "comment";
    } elsif ($line =~ /\*\//) {
        pop @states;
    } elsif ($line =~ /^\s*enum\s/) {
        push @states, "enum";
    }  

}

close(FUNCTIONS);
close(ENUMS);
close(STRUCTS);
close(DEFINES);
close(TYPEDEFS);
