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

- (id)init 
{
    self=[super init];
    if (self) {

    }
    return self;
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
    OGRegularExpression *regex, *trim;
    OGRegularExpressionMatch *aMatch;
    NSMutableArray *returnArray =[NSMutableArray array];
    [self markBlocks:aTextStorage];

    regex = [[[OGRegularExpression alloc] initWithString:@"([-+][^(-;]*\\([A-Za-z0-9 *_]*\\)[A-Za-z0-9_ ]+[^{;]*)" options:OgreFindNotEmptyOption] autorelease];
    
    trim = [[[OGRegularExpression alloc] initWithString:@"([\\n\\r]| +|:( *\\([^\\)]*\\) *[a-zA-Z0-9]*))" options:OgreFindNotEmptyOption] autorelease];
    
    NSEnumerator *matchEnumerator = [[regex allMatchesInString:[aTextStorage string]] objectEnumerator];
    while ((aMatch = [matchEnumerator nextObject])) {
        NSRange jumprange = [aMatch rangeOfSubstringAtIndex:1];
        NSRange fullrange = [aMatch rangeOfMatchedString];
        if ([aTextStorage attribute:kSymbolParsingIsInABlock atIndex:jumprange.location effectiveRange:nil]) break;
        
        NSString *name = [trim replaceAllMatchesInString:[aMatch matchedString] withString:@" " options:OgreNoneOption];
        //NSLog(@"Symbol:%@",name);
        NSString *type = @"bar";
        int mask = 0;
        NSImage *image = [NSImage imageNamed:@"SymbolM"];
        
        [returnArray addObject:[SymbolTableEntry symbolTableEntryWithName:name fontTraitMask:mask image:image type:type indentationLevel:rand()%5 jumpRange:jumprange range:fullrange]];
    }

    return returnArray;
}

@end
