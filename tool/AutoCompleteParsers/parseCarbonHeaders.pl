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
        $class = $1;
        $result = `grep "$class" /Users/pittenau/svn/codingmonkeys/subethaedit/trunk/subethaedit/Modes/Objective-C.mode/Contents/Resources/SyntaxDefinition.xml /Users/pittenau/svn/codingmonkeys/subethaedit/trunk/subethaedit/Modes/Objective-C.mode/Contents/Resources/AutocompleteAdditions.txt`;
        if ($result eq '') {
            print DEFINES $class."\n";
        } 
    }

    if ($line =~ /typedef\s+([\w\d_]+)/) {
        $class = $1;
        $result = `grep "$class" /Users/pittenau/svn/codingmonkeys/subethaedit/trunk/subethaedit/Modes/Objective-C.mode/Contents/Resources/SyntaxDefinition.xml /Users/pittenau/svn/codingmonkeys/subethaedit/trunk/subethaedit/Modes/Objective-C.mode/Contents/Resources/AutocompleteAdditions.txt`;
        if ($result eq '') {
            print TYPEDEFS $class."\n";
        } 
    }

    if ($line =~ /^#/) {next;}
    
    if ($state eq "default") {
        
        if ($line =~ /([\w\d_]+)\s*\(/) {
        $class = $1;
        $result = `grep "$class" /Users/pittenau/svn/codingmonkeys/subethaedit/trunk/subethaedit/Modes/Objective-C.mode/Contents/Resources/SyntaxDefinition.xml /Users/pittenau/svn/codingmonkeys/subethaedit/trunk/subethaedit/Modes/Objective-C.mode/Contents/Resources/AutocompleteAdditions.txt`;
        if ($result eq '') {
            print FUNCTIONS $class."\n";
        } 
        } elsif ($line =~ /struct\s([\w\d_]+)/) {
        $class = $1;
        $result = `grep "$class" /Users/pittenau/svn/codingmonkeys/subethaedit/trunk/subethaedit/Modes/Objective-C.mode/Contents/Resources/SyntaxDefinition.xml /Users/pittenau/svn/codingmonkeys/subethaedit/trunk/subethaedit/Modes/Objective-C.mode/Contents/Resources/AutocompleteAdditions.txt`;
        if ($result eq '') {
            print STRUCTS $class."\n";
        } 
        }
        
    } elsif ($state eq "enum") {
        if ($line =~ /^\s*([\w\d_]+)/) {
        $class = $1;
        $result = `grep "$class" /Users/pittenau/svn/codingmonkeys/subethaedit/trunk/subethaedit/Modes/Objective-C.mode/Contents/Resources/SyntaxDefinition.xml /Users/pittenau/svn/codingmonkeys/subethaedit/trunk/subethaedit/Modes/Objective-C.mode/Contents/Resources/AutocompleteAdditions.txt`;
        if ($result eq '') {
            print ENUMS $class."\n";
        } 
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
