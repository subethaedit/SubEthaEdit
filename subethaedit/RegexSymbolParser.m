//
//  RegexSymbolParser.m
//  SubEthaEdit
//
//  Created by Martin Pittenauer on Fri Apr 16 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "RegexSymbolParser.h"
#import "SymbolTableEntry.h"
#import <OgreKit/OgreKit.h>

NSString * const kSymbolParsingIsInABlock  = @"SymbolParsingIsInABlock";


@implementation RegexSymbolParser

- (id)initWithSymbolDefinition:(RegexSymbolDefinition *)aSymbolDefinition 
{
    self=[super init];
    if (self) {
        [self setSyntaxDefinition:aSymbolDefinition];
    }
    return self;
}

#pragma mark - 
#pragma mark - Accessors
#pragma mark - 

- (RegexSymbolDefinition *)symbolDefinition
{
    return I_symbolDefinition;
}

- (void)setSyntaxDefinition:(RegexSymbolDefinition *)aSymbolDefinition
{
    [I_symbolDefinition autorelease];
     I_symbolDefinition = [aSymbolDefinition retain];
}


- (void)markBlocks:(NSTextStorage *)aTextStorage
{
    // NSArray of NSRanges faster??

/*    [aTextStorage removeAttribute:kSymbolParsingIsInABlock range:NSMakeRange(0,[[aTextStorage string] length])];
    NSCharacterSet *brackets = [NSCharacterSet characterSetWithCharactersInString:@"{"];
    NSScanner *scanner = [NSScanner scannerWithString:[aTextStorage string]];
    [scanner setCharactersToBeSkipped:[brackets invertedSet]];
    [scanner setScanLocation:0];
    
    NSString *bracket = nil;
    int level = 0;
    NSRange currentBlock;
    currentBlock.location = 0;
    currentBlock.length = 0;
    
    while ([scanner scanCharactersFromSet:brackets intoString:&bracket]) {
        // Ignore States
        if (![aTextStorage attribute:@"HighlightingState" atIndex:[scanner scanLocation] effectiveRange:nil]) {
            NSLog(@"Ping: %@",bracket);
            BOOL opener = [bracket isEqualToString:@"{"];
            if (!opener) level--;
            if (level==0) { // New block starts
                if (opener) {
                    level++;
                    currentBlock.location = [scanner scanLocation];
                    NSLog(@"Block at: %@",NSStringFromRange(currentBlock));
                } else { // Block ends
                    currentBlock.length = [scanner scanLocation] - currentBlock.location;
                    NSLog(@"Block: %@",NSStringFromRange(currentBlock));
                    [aTextStorage addAttribute:kSymbolParsingIsInABlock value:@"YES" range:currentBlock];
                }
            }   
        }
    } */
}

- (NSArray *)symbolsForTextStorage:(NSTextStorage *)aTextStorage 
{
    RegexSymbolDefinition *definition = [self symbolDefinition];
    NSMutableArray *returnArray =[NSMutableArray array];

    [self markBlocks:aTextStorage];

    NSArray *symbols = [definition symbols];
    
    int i,j;
    int count = [symbols count];
    
    // Aneinander kleben -> Schneller!
    
    for (i=0;i<count;i++) {
        NSDictionary *symbol = [symbols objectAtIndex:i];
        OGRegularExpression *regex = [symbol objectForKey:@"regex"];
        NSString *type = @"bar";
        int mask = [[symbol objectForKey:@"font-trait"] unsignedIntValue];
        NSImage *image = [symbol objectForKey:@"image"];

        NSEnumerator *matchEnumerator = [[regex allMatchesInString:[aTextStorage string]] objectEnumerator];
        OGRegularExpressionMatch *aMatch;
        while ((aMatch = [matchEnumerator nextObject])) {
            NSRange jumprange = [aMatch rangeOfSubstringAtIndex:1];
            NSRange fullrange = [aMatch rangeOfMatchedString];
            if ([aTextStorage attribute:kSymbolParsingIsInABlock atIndex:jumprange.location effectiveRange:nil]) break;
            NSString *name = [aMatch matchedString];
            //NSString *name = [trim replaceAllMatchesInString:[aMatch matchedString] withString:@"" options:OgreNoneOption];
            
            // Replace Stuff!
            NSArray *postprocess = [symbol objectForKey:@"postprocess"];
            if (postprocess) {
                int postprocesscount = [postprocess count];
                for (j=0;j<postprocesscount;j++) {
                    NSArray *findreplace = [postprocess objectAtIndex:j];
                    OGRegularExpression *find = [findreplace objectAtIndex:0];
                    NSString *replace = [findreplace objectAtIndex:1];
                    name = [find replaceAllMatchesInString:name withString:replace options:OgreNoneOption];
                }
            }
            
            [returnArray addObject:[SymbolTableEntry symbolTableEntryWithName:name fontTraitMask:mask image:image type:type indentationLevel:0 jumpRange:jumprange range:fullrange]];
        }
    }
    return [returnArray sortedArrayUsingSelector:@selector(sortByRange:)];
}

@end
