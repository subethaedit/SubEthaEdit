//  RegexSymbolParser.m
//  SubEthaEdit
//
//  Created by Martin Pittenauer on Fri Apr 16 2004.

#import "RegexSymbolParser.h"
#import "SymbolTableEntry.h"
#import "SyntaxHighlighter.h"
#import "DocumentModeManager.h"
#import <OgreKit/OgreKit.h>


@implementation RegexSymbolParser

- (id)initWithSymbolDefinition:(RegexSymbolDefinition *)symbolDefinition  {
    self=[super init];
    if (self) {
        self.symbolDefinition = symbolDefinition;
    }
    return self;
}

- (NSArray *)symbolsForTextStorage:(NSTextStorage *)textStorage {
    NSMutableArray *returnArray = [NSMutableArray array];
	NSRange currentRange = NSMakeRange(0,0);
	NSRange fullRange = NSMakeRange(0, [textStorage length]);
	if (NSMaxRange(fullRange)>[[NSUserDefaults standardUserDefaults] integerForKey:@"StringLengthToStopSymbolRecognition"]) {
		return nil;
	}
	// Iterate through blocks of stuff, using the different Parsers
	while (NSMaxRange(currentRange)<NSMaxRange(fullRange)) {
		NSRange effectiveRange;
		NSString *modeForSymbols = [textStorage attribute:kSyntaxHighlightingParentModeForSymbolsAttributeName atIndex:currentRange.location longestEffectiveRange:&effectiveRange inRange:fullRange];
		
        RegexSymbolParser *symbolParser = modeForSymbols ? [[[DocumentModeManager sharedInstance] documentModeForName:modeForSymbols] symbolParser] : self;
		
		//NSLog(@"Found %@ within %@. Using parser %@.", modeForSymbols, NSStringFromRange(effectiveRange), symbolParser);
		
		[returnArray addObjectsFromArray:[symbolParser symbolsForTextStorage:textStorage inRange:effectiveRange]];
		currentRange = NSMakeRange(NSMaxRange(effectiveRange),0);
	}
	
    return [returnArray sortedArrayUsingSelector:@selector(sortByRange:)];
}


- (NSArray *)symbolsForTextStorage:(NSTextStorage *)textStorage inRange:(NSRange)range {
    RegexSymbolDefinition *definition = [self symbolDefinition];
    NSMutableArray *returnArray = [NSMutableArray array];
    NSString *textStorageString = [textStorage string];

    //clock_t start_time = clock();
	
    NSArray *symbols = [definition symbols];
    
    for (NSDictionary *symbol in symbols) {
        OGRegularExpression *regex = symbol[@"regex"];
        NSString *type = symbol[@"id"];
        int mask = [symbol[@"font-trait"] unsignedIntValue];
        int indent = [symbol[@"indentation"] intValue];
        NSImage *image = symbol[@"symbol"] ? [NSImage symbolImageNamed:symbol[@"symbol"]] : symbol[@"image"];
        
        // this is important because of ogrekit which copies almost the complete string as utf16 in an enumerator.
        @autoreleasepool {
            NSEnumerator *matchEnumerator = [[regex allMatchesInString:textStorageString range:range] objectEnumerator];
            OGRegularExpressionMatch *aMatch;
            while ((aMatch = [matchEnumerator nextObject])) {
                NSRange jumpRange = [aMatch rangeOfSubstringAtIndex:1];

                if (![aMatch substringAtIndex:1]) { jumpRange = [aMatch rangeOfMatchedString]; }
                if (jumpRange.location < [textStorage length]) {
                    NSString *scopeName = [textStorage attribute:kSyntaxHighlightingScopenameAttributeName atIndex:jumpRange.location effectiveRange:nil];

                    BOOL isComment = [scopeName hasPrefix:@"comment"];
                    NSString *typeAttribute = nil;
                    if (!isComment) {
                        typeAttribute = typeAttribute ?: [textStorage attribute:kSyntaxHighlightingTypeAttributeName atIndex:jumpRange.location effectiveRange:nil];
                        isComment = [typeAttribute isEqualToString:kSyntaxHighlightingTypeComment];
                    }

                    BOOL isString = [scopeName hasPrefix:@"string"];
                    if (!isString) {
                        typeAttribute = typeAttribute ?: [textStorage attribute:kSyntaxHighlightingTypeAttributeName atIndex:jumpRange.location effectiveRange:nil];
                        isString = [typeAttribute isEqualToString:kSyntaxHighlightingTypeString];
                    }

                    BOOL showInComments = [symbol[@"show-in-comments"] isEqualToString:@"yes"];
                    if (!isString && (!isComment || showInComments)) {
                        
                        NSRange fullrange = [aMatch rangeOfMatchedString];
                        NSString *name = [aMatch substringAtIndex:1];
                        if (!name) { name = [aMatch matchedString]; }

                        NSArray *postprocess = symbol[@"postprocess"];
                        if (postprocess) {
                            for (NSArray *findreplace in postprocess) {
                                OGRegularExpression *find = [findreplace objectAtIndex:0];
                                NSString *replace = [findreplace objectAtIndex:1];
                                name = [find replaceAllMatchesInString:name withString:replace options:OgreNoneOption];
                            }
                        }
                        
                        SymbolTableEntry *entry = [SymbolTableEntry symbolTableEntryWithName:name fontTraitMask:mask image:image type:type indentationLevel:indent jumpRange:jumpRange range:fullrange];
                        
                        if ([name isEqualToString:@""]) {
                            [entry setIsSeparator:YES];
                        }
                        [returnArray addObject:entry];
                    }
                }
            }
        } // autoreleasepool
    }
    //NSLog(@"time for symbols: %f",(((double)(clock()-start_time))/CLOCKS_PER_SEC));
    return returnArray;
	//    return [returnArray sortedArrayUsingSelector:@selector(sortByRange:)];
}

@end
