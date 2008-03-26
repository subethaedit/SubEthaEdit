//
//  Controller.m
//  DwarfTosser
//
//  Created by Martin Pittenauer on 18.12.07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import "Controller.h"
#import <OgreKit/OgreKit.h>


@implementation Controller


- (NSString *) resolveSymbolsInString:(NSString *)inString 
{
    NSMutableString *returnString = [NSMutableString stringWithString:inString];
    OGRegularExpression *regex;
    OGRegularExpressionMatch *match;
    NSString *version = nil;
    NSString *architecture = nil;
        
    // 10.4 and 10.5 version parsing
    regex = [OGRegularExpression regularExpressionWithString:@"^Version: +(.*)"];
    match = [regex matchInString:inString];
    version = [match lastMatchSubstring];
    
    // 10.5 architecure parsing
    regex = [OGRegularExpression regularExpressionWithString:@"^Code Type: +(...)"];
    match = [regex matchInString:inString];
    if ([match count]>0) {
        if ([[match lastMatchSubstring] isEqualToString:@"X86"]) architecture = @"i386";
        if ([[match lastMatchSubstring] isEqualToString:@"PPC"]) architecture = @"ppc";
    }
    
    if (!architecture) {
        // Looks like a 10.4 crash report, have to deduce architecure by Thread state.
        // Works as 10.5 fallback too.
        regex = [OGRegularExpression regularExpressionWithString:@"crashed with (...) Thread State"];
        match = [regex matchInString:inString];
        if ([match count]>0) {
            if ([[match lastMatchSubstring] isEqualToString:@"X86"]) architecture = @"i386";
            if ([[match lastMatchSubstring] isEqualToString:@"PPC"]) architecture = @"ppc";
        }
    }
    
    regex = [OGRegularExpression regularExpressionWithString:@"^\\d+ +([\\w.]+) +([0-9a-f]x[0-9a-f]+) +([0-9a-f]x[0-9a-f]+)"];

    
    NSEnumerator *enumerator = [[regex allMatchesInString:inString] reverseObjectEnumerator];
    while ((match = [enumerator nextObject])) {
        NSRange replaceRange = [match rangeOfLastMatchSubstring];
        NSString *dsymName = [match substringAtIndex:1];
        NSString *offset = [match substringAtIndex:2];
        NSString *dsymPath = [self dsymPathForName:dsymName andVersion:version];
        
        NSTask *task;
        task = [[NSTask alloc] init];
        [task setLaunchPath: @"/usr/bin/dwarfdump"];
        
        NSArray *arguments;
        arguments = [NSArray arrayWithObjects:[NSString stringWithFormat:@"--lookup=%@", offset], [NSString stringWithFormat:@"--arch=%@", architecture], dsymPath, nil];
        [task setArguments: arguments];
        
        NSPipe *pipe;
        pipe = [NSPipe pipe];
        [task setStandardOutput: pipe];
        
        NSFileHandle *file;
        file = [pipe fileHandleForReading];
        
        [task launch];
        
        NSData *data;
        data = [file readDataToEndOfFile];
        
        NSString *outputString;
        outputString = [[[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding] autorelease];
        
        [task release];
        
        if ([outputString rangeOfString:@"debug information...not found"].location!=NSNotFound) {
            NSLog(@"Could not resolve symbol: %@", offset);
        } else {
            regex = [OGRegularExpression regularExpressionWithString:@"AT_name\\( \"([^\"]+)"];
            match = [[regex allMatchesInString:outputString] lastObject];
            NSString *resolvedSymbol = [match lastMatchSubstring];
//            NSLog(@"Resolved %@ to %@", offset, resolvedSymbol);
            
            [returnString replaceCharactersInRange:replaceRange withString:resolvedSymbol];
        }
        
        //NSLog(@"dsym: '%@', offset:'%@'", dsymName, offset);
    }
    
    //NSLog(@"returnString: %@", returnString);
    return returnString;
}

- (NSString *)dsymPathForName:(NSString *)inName andVersion:(NSString *)inVersion
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *paths = [NSMutableDictionary dictionaryWithDictionary:[defaults dictionaryForKey:@"CachedDSYMPaths"]];
    NSString *key = [NSString stringWithFormat:@"%@ %@",inName,inVersion];
    NSString *path;
    
    if ((path = [paths objectForKey:key])) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) return path;
    }
    
    // Still here? So we did not hit the cache and have to annoy the user.
    
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setTitle:[NSString stringWithFormat:@"Select dsym for %@ %@", inName, inVersion]];
    [openPanel runModalForDirectory:nil file:nil types:[NSArray arrayWithObject:@"dSYM"]];
    path = [[openPanel filenames] lastObject];
    
    if (!path) return nil;
    
    // Cache path
    
    [paths setObject:path forKey:key];
    [defaults setObject:paths forKey:@"CachedDSYMPaths"];
    [defaults synchronize];
    
    return path;
}

- (IBAction) resolveSymbols:(id)sender 
{
	[o_textView setString:[self resolveSymbolsInString:[[o_textView textStorage] string]]];
}


@end
