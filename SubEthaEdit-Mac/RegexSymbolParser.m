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

#if defined(CODA)
static NSString* PostProcessMatch(NSString* string, NSArray* postprocess);
#endif //defined(CODA)


@implementation RegexSymbolParser

- (id)initWithSymbolDefinition:(RegexSymbolDefinition *)aSymbolDefinition 
{
    self=[super init];
    if (self) {
        [self setSyntaxDefinition:aSymbolDefinition];
    }
    return self;
}

- (void)dealloc {
    [I_symbolDefinition release];
    [super dealloc];
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
	if (NSMaxRange(fullRange)>[[NSUserDefaults standardUserDefaults] integerForKey:@"StringLengthToStopSymbolRecognition"]) {
	   return nil;
	}
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
    
	for (NSDictionary *symbol in symbols) {
        OGRegularExpression *regex = [symbol objectForKey:@"regex"];
        NSString *type = [symbol objectForKey:@"id"];
        int mask = [[symbol objectForKey:@"font-trait"] unsignedIntValue];
        int indent = [[symbol objectForKey:@"indentation"] intValue];
        NSImage *image = [symbol objectForKey:@"image"];
		
        // this is important because of ogrekit which copies almost the complete string as utf16 in an enumerator.
		NSAutoreleasePool *ogrePool = [[NSAutoreleasePool alloc] init];
        NSEnumerator *matchEnumerator = [[regex allMatchesInString:[aTextStorage string] range:aRange] objectEnumerator];
        OGRegularExpressionMatch *aMatch;
        while ((aMatch = [matchEnumerator nextObject])) {
#if defined(CODA)
			// If no substrings are matched, indexOfFirstMatchedSubstring returns 0 which is the entire match range
			unsigned indexOfFirstSubstring = [aMatch indexOfFirstMatchedSubstring];
			NSRange jumprange = [aMatch rangeOfSubstringAtIndex:indexOfFirstSubstring];
#else
            NSRange jumprange = [aMatch rangeOfSubstringAtIndex:1];
            if (![aMatch substringAtIndex:1]) jumprange = [aMatch rangeOfMatchedString];
#endif // defined(CODA)
			if ( jumprange.location < [aTextStorage length] )
			{
				BOOL isComment = [[aTextStorage attribute:kSyntaxHighlightingScopenameAttributeName atIndex:jumprange.location effectiveRange:nil] hasPrefix:@"comment"];
				if (!isComment) isComment = [[aTextStorage attribute:kSyntaxHighlightingTypeAttributeName atIndex:jumprange.location effectiveRange:nil] isEqualToString:kSyntaxHighlightingTypeComment];
				BOOL showInComments = [[symbol objectForKey:@"show-in-comments"] isEqualToString:@"yes"];
				if (!isComment||showInComments) {
					
					NSRange fullrange = [aMatch rangeOfMatchedString];
#if defined(CODA)
					NSString* name = PostProcessMatch([aMatch substringAtIndex:indexOfFirstSubstring], [symbol objectForKey:@"postprocess"]);
#else
					NSString *name = [aMatch substringAtIndex:1];
					if (!name) name = [aMatch matchedString];
#endif // defined(CODA)
					NSArray *postprocess = [symbol objectForKey:@"postprocess"];
					if (postprocess) {
						for (NSArray *findreplace in postprocess) {
							OGRegularExpression *find = [findreplace objectAtIndex:0];
							NSString *replace = [findreplace objectAtIndex:1];
							name = [find replaceAllMatchesInString:name withString:replace options:OgreNoneOption];
						}
					}
					
					SymbolTableEntry *aSymbolTableEntry = [SymbolTableEntry symbolTableEntryWithName:name fontTraitMask:mask image:image type:type indentationLevel:indent jumpRange:jumprange range:fullrange];
					
#if defined(CODA)
					NSMutableArray* substrings = [NSMutableArray arrayWithCapacity:[aMatch count]];
					
					for ( unsigned substringIdx = [aMatch indexOfFirstMatchedSubstring]; substringIdx > 0; substringIdx = [aMatch indexOfFirstMatchedSubstringAfterIndex:(substringIdx + 1)] )
					{
						[substrings addObject:PostProcessMatch([aMatch substringAtIndex:substringIdx], [symbol objectForKey:@"postprocess"])];
					}
					
					OGRegularExpressionCapture* captureHistory = [aMatch captureHistory];
					
					if ( captureHistory != nil )
					{
						if ( [substrings count] == 0 )
						{
							unsigned numberOfChildren = [captureHistory numberOfChildren];
							
							for ( unsigned childIdx = 0; childIdx < numberOfChildren; ++childIdx )
								[substrings addObject:PostProcessMatch([[captureHistory childAtIndex:childIdx] string], [symbol objectForKey:@"postprocess"])];
						}
						else
						{
							unsigned numberOfChildren = [captureHistory numberOfChildren];
							unsigned prevGroupIdx = 0;
							unsigned numberOfReplacements = 0;
							
							for ( unsigned childIdx = 0; childIdx < numberOfChildren; ++childIdx )
							{
								OGRegularExpressionCapture* curCapture = [captureHistory childAtIndex:childIdx];
								unsigned curGroupIdx = [curCapture groupIndex];
								unsigned indexOfCapture = (curGroupIdx - indexOfFirstSubstring + childIdx - numberOfReplacements);
								if ( prevGroupIdx != curGroupIdx )
								{
									[substrings replaceObjectAtIndex:indexOfCapture withObject:PostProcessMatch([curCapture string], [symbol objectForKey:@"postprocess"])];
									prevGroupIdx = curGroupIdx;
									++numberOfReplacements;
								}
								else
									[substrings insertObject:PostProcessMatch([curCapture string], [symbol objectForKey:@"postprocess"]) atIndex:(indexOfCapture + 1)];
							}
						}
					}
					
					aSymbolTableEntry.substrings = substrings;
					aSymbolTableEntry.documentModeIdentifier = [[I_symbolDefinition mode] documentModeIdentifier];
#endif //defined(CODA)

					
					if ([name isEqualToString:@""]) {
						[aSymbolTableEntry setIsSeparator:YES];
					}
					[returnArray addObject:aSymbolTableEntry];
				}
			}
		}
		[ogrePool release];
    }
    //NSLog(@"time for symbols: %f",(((double)(clock()-start_time))/CLOCKS_PER_SEC));
    return returnArray;
//    return [returnArray sortedArrayUsingSelector:@selector(sortByRange:)];
}

@end

#if defined(CODA)

static NSString* PostProcessMatch(NSString* string, NSArray* postprocess)
{
	for (NSArray *findreplace in postprocess) {
		OGRegularExpression *find = [findreplace objectAtIndex:0];
		NSString *replace = [findreplace objectAtIndex:1];
		string = [find replaceAllMatchesInString:string withString:replace options:OgreNoneOption];
	}
	
	return string;
}

#endif //defined(CODA)

