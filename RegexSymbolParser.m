//
//  RegexSymbolParser.m
//  SubEthaEdit
//
//  Created by Martin Pittenauer on Fri Apr 16 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "RegexSymbolParser.h"
#import "SymbolTableEntry.h"
#import "SyntaxHighlighter.h"
#import "DocumentModeManager.h"
#import <OgreKit/OgreKit.h>



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

- (NSArray *)symbolsForTextStorage:(NSTextStorage *)aTextStorage {
    NSMutableArray *returnArray =[NSMutableArray array];
	NSRange currentRange = NSMakeRange(0,0);
	NSRange fullRange = NSMakeRange(0, [aTextStorage length]);
	
	// Iterate through blocks of stuff, using the different Parsers
	while (NSMaxRange(currentRange)<NSMaxRange(fullRange)) {
		NSRange effectiveRange;
		NSString *modeForSymbols = [aTextStorage attribute:kSyntaxHighlightingParentModeForSymbolsAttributeName atIndex:currentRange.location longestEffectiveRange:&effectiveRange inRange:fullRange];
		
		RegexSymbolParser *symbolParser;
		if (modeForSymbols) symbolParser = [[[DocumentModeManager sharedInstance] documentModeForName:modeForSymbols] symbolParser];
		else symbolParser = self;
			
		//NSLog(@"Found %@ within %@. Using parser %@.", modeForSymbols, NSStringFromRange(effectiveRange), symbolParser);
		
		[returnArray addObjectsFromArray:[symbolParser symbolsForTextStorage:aTextStorage inRange:effectiveRange]];
		currentRange = NSMakeRange(NSMaxRange(effectiveRange),0);
	}
	
    return [returnArray sortedArrayUsingSelector:@selector(sortByRange:)];
}


- (NSArray *)symbolsForTextStorage:(NSTextStorage *)aTextStorage inRange:(NSRange)aRange
{
    RegexSymbolDefinition *definition = [self symbolDefinition];
    NSMutableArray *returnArray =[NSMutableArray array];

    //clock_t start_time = clock();

    NSArray *symbols = [definition symbols];
    
    int i,j;
    int count = [symbols count];
    
    for (i=0;i<count;i++) {
        NSDictionary *symbol = [symbols objectAtIndex:i];
        OGRegularExpression *regex = [symbol objectForKey:@"regex"];
        NSString *type = [symbol objectForKey:@"id"];
        int mask = [[symbol objectForKey:@"font-trait"] unsignedIntValue];
        int indent = [[symbol objectForKey:@"indentation"] intValue];
        NSImage *image = [symbol objectForKey:@"image"];
		
        NSEnumerator *matchEnumerator = [[regex allMatchesInString:[aTextStorage string] range:aRange] objectEnumerator];
        OGRegularExpressionMatch *aMatch;
        while ((aMatch = [matchEnumerator nextObject])) {
            NSRange jumprange = [aMatch rangeOfSubstringAtIndex:1];
            if (![aMatch substringAtIndex:1]) jumprange = [aMatch rangeOfMatchedString];
            if (![[aTextStorage attribute:kSyntaxHighlightingTypeAttributeName atIndex:jumprange.location effectiveRange:nil] isEqualToString:@"comment"]) {
				
				NSRange fullrange = [aMatch rangeOfMatchedString];
				NSString *name = [aMatch substringAtIndex:1];
				if (!name) name = [aMatch matchedString];
				
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
				
				SymbolTableEntry *aSymbolTableEntry = [SymbolTableEntry symbolTableEntryWithName:name fontTraitMask:mask image:image type:type indentationLevel:indent jumpRange:jumprange range:fullrange];
				if ([name isEqualToString:@""]) {
					[aSymbolTableEntry setIsSeparator:YES];
				}
				[returnArray addObject:aSymbolTableEntry];
			}
		}
    }
    //NSLog(@"time for symbols: %f",(((double)(clock()-start_time))/CLOCKS_PER_SEC));
    return returnArray;
//    return [returnArray sortedArrayUsingSelector:@selector(sortByRange:)];
}

@end
