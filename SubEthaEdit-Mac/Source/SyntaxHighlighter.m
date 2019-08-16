//  SyntaxHighlighter.m
//  SyntaxTestBench
//
//  Created by Martin Pittenauer on Thu Mar 04 2004.
//

#import "SyntaxHighlighter.h"
#import "PlainTextDocument.h"
#import "time.h"
#import <OgreKit/OgreKit.h>
#import "NSMutableAttributedStringSEEAdditions.h"
#import "NSStringSEEAdditions.h"
#import "FullTextStorage.h"

#define chunkSize              		5000
#define padding              		 100
#define makeDirty              		 100

NSString * const kSyntaxHighlightingIsCorrectAttributeName  = @"HighlightingIsCorrect";
NSString * const kSyntaxHighlightingIsCorrectAttributeValue = @"Correct";
NSString * const kSyntaxHighlightingIsTrimmedStartAttributeName = @"HighlightingIsATrimmedStart";
NSString * const kSyntaxHighlightingIsTrimmedStartAttributeValue = @"Jup";
NSString * const kSyntaxHighlightingStackName = @"HighlightingStack";
NSString * const kSyntaxHighlightingStateDelimiterName = @"HighlightingStateDelimiter";
NSString * const kSyntaxHighlightingStateDelimiterStartValue = @"Start";
NSString * const kSyntaxHighlightingStateDelimiterEndValue = @"End";
NSString * const kSyntaxHighlightingFoldDelimiterName = @"HighlightingFoldDelimiter";
NSString * const kSyntaxHighlightingStyleIDAttributeName = @"styleID";
NSString * const kSyntaxHighlightingTypeAttributeName = @"Type";
NSString * const kSyntaxHighlightingScopenameAttributeName = @"scope";
NSString * const kSyntaxHighlightingParentModeForSymbolsAttributeName = @"ParentModeForSymbols";
NSString * const kSyntaxHighlightingParentModeForAutocompleteAttributeName = @"ParentModeForAutocomplete";
NSString * const kSyntaxHighlightingFoldingDepthAttributeName = @"FoldingDepth";
NSString * const kSyntaxHighlightingAutocompleteEndName = @"AutocompleteEnd";
NSString * const kSyntaxHighlightingIndentLevelName = @"IndentLevel";


NSString * const kSyntaxHighlightingTypeComment = @"comment";
NSString * const kSyntaxHighlightingTypeString = @"string";

static NSArray *S_attributesToCleanup = nil;

@implementation SyntaxHighlighter
/*"A Syntax Highlighter"*/

static  NSMutableDictionary *S_transientRegexCache = nil;

+ (void)initialize {
	if (!S_attributesToCleanup) {
		S_attributesToCleanup = [[NSArray alloc] initWithObjects:kSyntaxHighlightingStackName,kSyntaxHighlightingStateDelimiterName,kSyntaxHighlightingFoldDelimiterName,kSyntaxHighlightingScopenameAttributeName,kSyntaxHighlightingTypeAttributeName,kSyntaxHighlightingParentModeForSymbolsAttributeName,kSyntaxHighlightingParentModeForAutocompleteAttributeName,kSyntaxHighlightingIsCorrectAttributeName,kSyntaxHighlightingFoldingDepthAttributeName,NSLinkAttributeName,kSyntaxHighlightingIsTrimmedStartAttributeName,kSyntaxHighlightingAutocompleteEndName,kSyntaxHighlightingIndentLevelName,nil];
	}
}

#pragma mark - Initizialisation (fizzle televizzle)

/*"Initiates the Highlighter with a Syntax Definition"*/

- (instancetype)initWithSyntaxDefinition:(SyntaxDefinition *)aSyntaxDefinition  {
    self=[super init];
    if (self) {
        _syntaxDefinition = aSyntaxDefinition;
        if (!S_transientRegexCache) S_transientRegexCache = [NSMutableDictionary new];
    }
    DEBUGLOG(@"SyntaxHighlighterDomain", AllLogLevel, @"Initiated new SyntaxHighlighter:%@",[self description]);
    return self;
}

#pragma mark - Highlighting

/*"Highlights an NSAttributedString using the Chunky State Machine Algorithm:

    do {
        if (state) 
            searchEnd
            color
        else
            colorDefaultState
            searchAndMarkNextState
    } while (ready)

"*/

static unsigned int trimmedStartOnLevel = UINT_MAX;

- (void)highlightAttributedString:(NSMutableAttributedString *)aString inRange:(NSRange)aRange ofDocument:(id)theDocument {
    SyntaxDefinition *definition = [self syntaxDefinition];
    if (!definition) NSLog(@"ERROR: No defintion for highlighter.");
	[definition getReady]; // Make sure everything is setup 
    NSString *theString = [aString string];
	NSUInteger documentEnd = [theString length];
	
    // If our dirty range beings with a start delimiter, make sure it is cleared completely to avoid confusing the engine with zombie starts
    if (aRange.location>0) {
        if ([aString attribute:kSyntaxHighlightingStateDelimiterName atIndex:aRange.location-1 effectiveRange:nil]) {
            NSRange midwayStartDelimiterRange;
            [aString attribute:kSyntaxHighlightingStateDelimiterName atIndex:aRange.location-1 longestEffectiveRange:&midwayStartDelimiterRange inRange:NSMakeRange(0, [theString length])];
            aRange = NSUnionRange(aRange, midwayStartDelimiterRange);
        }
    }
    
    NSRange currentRange = aRange;
    int delimiterStateNumber;
    NSDictionary *defaultState = [definition defaultState];
    NSDictionary *currentState = nil;
    NSMutableArray *stack = nil;
    
    OGRegularExpression *stateDelimiter;
    OGRegularExpressionMatch *delimiterMatch;

    // Clean up state attributes in the string we work on now
	@synchronized ([SyntaxHighlighter class]) {
		[aString removeAttributes:S_attributesToCleanup range:aRange];
	}

    NSMutableDictionary *scratchAttributes = [NSMutableDictionary dictionary];

    // Initialize (or preserve) stack
    NSArray *savedStack = nil;
    int foldingDepth = 0, newFoldingDepth = 0;
    if ((!stack)&&(currentRange.location>0)) {
        stack = [NSMutableArray arrayWithArray:[aString attribute:kSyntaxHighlightingStackName atIndex:currentRange.location-1 effectiveRange:nil]];
        if ([[aString attribute:kSyntaxHighlightingStateDelimiterName atIndex:currentRange.location-1 effectiveRange:nil] isEqualTo:kSyntaxHighlightingStateDelimiterEndValue]) {
            [stack removeLastObject];
        }
        
        foldingDepth = [[aString attribute:kSyntaxHighlightingFoldingDepthAttributeName atIndex:currentRange.location-1 effectiveRange:nil] intValue];
        newFoldingDepth = foldingDepth;
        
        //NSLog(@"Getting stack at: '%@': %@", [[aString string] substringWithRange:NSMakeRange(currentRange.location-1,1)], stack);
    }
    
    // No State yet? Use the default.
    if (!stack) stack = [NSMutableArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:[defaultState objectForKey:@"id"], @"state", [NSNumber numberWithInt:0], kSyntaxHighlightingIndentLevelName, nil], nil];
    
    do {
        @autoreleasepool {
            //NSLog(@"Stack at start: %@", stack);
            currentState = [definition stateForID:[[stack lastObject] objectForKey:@"state"]];
            if (![currentState objectForKey:@"scope"]) NSLog(@"State lookup fail for scope for %@",[currentState objectForKey:@"id"]);
            
            // Identify the next block of homogenous state
            
            stateDelimiter = [currentState objectForKey:@"Combined Delimiter Regex"];
            // If using transcendence we have to compile on the fly.
            @synchronized ([SyntaxHighlighter class]) {
                if (!stateDelimiter) {
                    NSString *combinedDelimiterString = [[stack lastObject] objectForKey:@"combinedDelimiterString"];
                    stateDelimiter = [S_transientRegexCache objectForKey:combinedDelimiterString];
                    if (!stateDelimiter) {
                        if (combinedDelimiterString && [OGRegularExpression isValidExpressionString:combinedDelimiterString]) {
                            stateDelimiter = [[OGRegularExpression alloc] initWithString:combinedDelimiterString options:OgreFindNotEmptyOption|OgreCaptureGroupOption];
                            if (stateDelimiter) [S_transientRegexCache setObject:stateDelimiter forKey:combinedDelimiterString];
                        }
                    }
                }
            }
            
            NSRange delimiterRange, stateRange, startRange, nextRange;
            //        BOOL foundEnd = NO;
            startRange = NSMakeRange(NSNotFound,0);
            // Add start to colorRange to color keywords within
            // But check for starts that contain \n
            NSRange attRange;
            if (currentRange.location>0)
                if ((currentRange.location-1>=aRange.location)&&([[aString attribute:kSyntaxHighlightingStateDelimiterName atIndex:currentRange.location-1 longestEffectiveRange:&attRange inRange:aRange] isEqualToString:kSyntaxHighlightingStateDelimiterStartValue])){
                    NSRange sameStackRange;
                    [aString attribute:kSyntaxHighlightingStackName atIndex:currentRange.location-1 longestEffectiveRange:&sameStackRange inRange:aRange];
                    startRange = NSIntersectionRange(attRange,sameStackRange);
                    if (startRange.length == 0) startRange.location = NSNotFound;
                }
            
            BOOL isBeginningOfLine = YES;
            if (currentRange.location > 0) {
                unichar previousCharacter = [theString characterAtIndex:currentRange.location-1];
                switch (previousCharacter) {
                    case 0x2028: //LSEP
                    case 0x2029: //PSEP
                    case '\n':
                    case '\r':
                        break;
                    default:
                        isBeginningOfLine = NO;
                }
            }
            if ((delimiterMatch = [stateDelimiter matchInString:theString options:isBeginningOfLine?0:OgreNotBOLOption range:currentRange])) { // Search for a delimiter
                //NSLog(@"Searching for next delimiter");
                delimiterRange = [delimiterMatch rangeOfMatchedString];
                
                stateRange = NSMakeRange(currentRange.location, NSMaxRange(delimiterRange) - currentRange.location);
                
                NSString *delimiterName = [delimiterMatch nameOfSubstringAtIndex:[delimiterMatch indexOfFirstMatchedSubstring]];
                delimiterStateNumber = [[delimiterName substringFromIndex:16] intValue];
                
                if (delimiterStateNumber<4242) { // Found a start within current state
                    //NSLog(@"Found a start: '%@' current range: %@",[[aString string] substringWithRange:delimiterRange], NSStringFromRange(currentRange));
                    
                    NSRange startTrimRange = [delimiterMatch rangeOfSubstringNamed:@"trimmedstart"];
                    
                    nextRange.location = (NSMaxRange(stateRange) - startTrimRange.length);
                    nextRange.length = currentRange.length - stateRange.length + startTrimRange.length;
                    
                    //Exclude delimiterRang from stateRange
                    stateRange.length = stateRange.length - delimiterRange.length;
                    
                    NSDictionary *subState = [[currentState objectForKey:@"states"] objectAtIndex:delimiterStateNumber];
                    savedStack = [stack copy];
                    
                    // Check for transcendence
                    // Use substringNamed: of delimiterMatch to get the content of named groups
                    NSArray *captureGroups = [subState objectForKey:@"Combined Delimiter String End Capture Groups"];
                    NSMutableString *combinedDelimiterString = nil;
                    if (captureGroups) {
                        combinedDelimiterString = [[subState objectForKey:@"Combined Delimiter String"] mutableCopy];
                        for (NSString *groupName in captureGroups) {
                            NSString *replacement = [[delimiterMatch substringNamed:groupName] stringByReplacingRegularExpressionOperators];
                            if (groupName && replacement) {
                                [combinedDelimiterString replaceOccurrencesOfString:[NSString stringWithFormat:@"(?#see-insert-start-group:%@)",groupName] withString:replacement options:0 range:NSMakeRange(0,[combinedDelimiterString length])];
                            }
                        }
                    }
                    
                    NSNumber *indentLevel = [[stack lastObject] objectForKey:kSyntaxHighlightingIndentLevelName];
                    if ([[subState objectForKey:@"indent"] isEqualToString:@"yes"]) {
                        indentLevel = @(indentLevel.intValue + 1);
                    }
                    
                    if (combinedDelimiterString) {
                        [stack addObject:[NSDictionary dictionaryWithObjectsAndKeys:[subState objectForKey:@"id"], @"state", indentLevel, kSyntaxHighlightingIndentLevelName, combinedDelimiterString, @"combinedDelimiterString", nil]];
                    } else {
                        [stack addObject:[NSDictionary dictionaryWithObjectsAndKeys:[subState objectForKey:@"id"], @"state", indentLevel, kSyntaxHighlightingIndentLevelName, nil]];
                    }
                    
                    NSUInteger level = [stack count];
                    
                    if ((level==trimmedStartOnLevel+1)||(level==trimmedStartOnLevel)) { // Was previous start a trimmed one?
                        [aString removeAttribute:kSyntaxHighlightingFoldDelimiterName range:delimiterRange];
                    } else if (level>trimmedStartOnLevel+1) {
                        [aString removeAttribute:kSyntaxHighlightingFoldDelimiterName range:stateRange];
                        [aString removeAttribute:kSyntaxHighlightingFoldDelimiterName range:delimiterRange];
                    }
                    
                    [scratchAttributes removeAllObjects];
                    //[scratchAttributes addEntriesFromDictionary:[theDocument styleAttributesForStyleID:[subState objectForKey:kSyntaxHighlightingStyleIDAttributeName]]];
                    NSString *scope = [subState objectForKey:kSyntaxHighlightingScopenameAttributeName];
                    if (scope){
                        [scratchAttributes addEntriesFromDictionary:[theDocument styleAttributesForScope:scope languageContext:[subState objectForKey:[definition keyForInheritedAutocomplete]]]];
                    }
                    
                    if ([subState objectForKey:@"AutoendReplacementString"]) {
                        [scratchAttributes setObject:[[OGReplaceExpression replaceExpressionWithString:[subState objectForKey:@"AutoendReplacementString"]] replaceMatchedStringOf:delimiterMatch] forKey:kSyntaxHighlightingAutocompleteEndName];
                    }
                    
                    [scratchAttributes setObject:[stack copy] forKey:kSyntaxHighlightingStackName];
                    [scratchAttributes setObject:kSyntaxHighlightingStateDelimiterStartValue forKey:kSyntaxHighlightingStateDelimiterName];
                    NSString *typeAttributeString;
                    if ((typeAttributeString=[subState objectForKey:@"type"]))
                        [scratchAttributes setObject:typeAttributeString forKey:kSyntaxHighlightingTypeAttributeName];
                    if ((typeAttributeString=[subState objectForKey:@"scope"]))
                        [scratchAttributes setObject:typeAttributeString forKey:kSyntaxHighlightingScopenameAttributeName];
                    
                    subState = [definition stateForID:[subState objectForKey:@"id"]];
                    if ([subState objectForKey:@"usespellchecking"]) {
                        [scratchAttributes setObject:[subState objectForKey:@"usespellchecking"] forKey:@"usespellchecking"];
                    }
                    //NSLog(@"usespellchecking: %@", [subState objectForKey:@"usespellchecking"]);
                    [scratchAttributes setObject:[subState objectForKey:[definition keyForInheritedSymbols]] forKey:kSyntaxHighlightingParentModeForSymbolsAttributeName];
                    [scratchAttributes setObject:[subState objectForKey:[definition keyForInheritedAutocomplete]] forKey:kSyntaxHighlightingParentModeForAutocompleteAttributeName];
                    if ([[subState objectForKey:@"foldable"] isEqualToString:@"yes"]) {
                        [scratchAttributes setObject:kSyntaxHighlightingStateDelimiterStartValue forKey:kSyntaxHighlightingFoldDelimiterName];
                        newFoldingDepth++;
                    }
                    [scratchAttributes setObject:[NSNumber numberWithInt:newFoldingDepth] forKey:kSyntaxHighlightingFoldingDepthAttributeName];
                    [scratchAttributes setObject:kSyntaxHighlightingIsCorrectAttributeValue forKey:kSyntaxHighlightingIsCorrectAttributeName];
                    if (startTrimRange.length>0) {
                        [scratchAttributes setObject:kSyntaxHighlightingIsTrimmedStartAttributeValue forKey:kSyntaxHighlightingIsTrimmedStartAttributeName];
                        trimmedStartOnLevel = [stack count];
                    }
                    [scratchAttributes setObject:[[stack lastObject] objectForKey:kSyntaxHighlightingIndentLevelName] forKey:kSyntaxHighlightingIndentLevelName];
                    
                    
                    [aString addAttributes:scratchAttributes range:delimiterRange];
                    
                    // In case we are at the end of the document we want to color the start now,
                    // not on first state chunk, hence we're skipping ahead in the state machine
                    if (documentEnd == NSMaxRange(delimiterRange)) {
                        currentState = subState;
                        startRange = delimiterRange;
                    }
                    
                } else { // Found end of current state
                    //NSLog(@"Found an end: '%@' current range: %@",[[aString string] substringWithRange:delimiterRange], NSStringFromRange(currentRange));
                    
                    NSRange matchedEndRange = [delimiterMatch rangeOfSubstringNamed:@"trimmedend"];
                    if (matchedEndRange.location != NSNotFound) delimiterRange = matchedEndRange;
                    
                    NSUInteger level = [stack count];
                    if (level>trimmedStartOnLevel) {
                        [aString removeAttribute:kSyntaxHighlightingFoldDelimiterName range:stateRange];
                    } else {
                        trimmedStartOnLevel = UINT_MAX;
                    }
                    
                    nextRange.location = NSMaxRange(stateRange);
                    nextRange.length = currentRange.length - stateRange.length;
                    [scratchAttributes setObject:kSyntaxHighlightingStateDelimiterEndValue forKey:kSyntaxHighlightingStateDelimiterName];
                    if ([[currentState objectForKey:@"foldable"] isEqualToString:@"yes"]) {
                        [scratchAttributes setObject:kSyntaxHighlightingStateDelimiterEndValue forKey:kSyntaxHighlightingFoldDelimiterName];
                        newFoldingDepth = foldingDepth - 1;
                    }
                    
                    NSString *typeAttributeString;
                    if ((typeAttributeString=[currentState objectForKey:@"type"]))
                        [scratchAttributes setObject:typeAttributeString forKey:kSyntaxHighlightingTypeAttributeName];
                    else [scratchAttributes removeObjectForKey:kSyntaxHighlightingTypeAttributeName];
                    if ((typeAttributeString=[currentState objectForKey:@"scope"]))
                        [scratchAttributes setObject:typeAttributeString forKey:kSyntaxHighlightingScopenameAttributeName];
                    else [scratchAttributes removeObjectForKey:kSyntaxHighlightingScopenameAttributeName];
                    if ([savedStack lastObject]) [scratchAttributes setObject:[[savedStack lastObject] objectForKey:kSyntaxHighlightingIndentLevelName] forKey:kSyntaxHighlightingIndentLevelName];
                    
                    if ([currentState objectForKey:@"usespellchecking"]) {
                        [scratchAttributes setObject:[currentState objectForKey:@"usespellchecking"] forKey:@"usespellchecking"];
                    }
                    
                    [aString addAttributes:scratchAttributes range:delimiterRange];
                    savedStack = [stack copy];
                    [stack removeLastObject]; // Default state doesn't have an end, stack is always > 0
                }
                
                //NSLog(@"Current stack: %@", stack);
                
            } else {  // No end found in chunk, so mark the whole chunk
                //DEBUGLOG(@"SyntaxHighlighterDomain", AllLogLevel, @"State %@ does not end in chunk",[currentState objectForKey:@"id"]);
                stateRange = NSMakeRange(currentRange.location, NSMaxRange(aRange) - currentRange.location);
                nextRange = NSMakeRange(NSNotFound,0);
                savedStack = [stack copy];
            }
            
            // Now apply style to the identified range
            
            //NSLog(@"Building scratch attributes");
            [scratchAttributes removeAllObjects];
            //[scratchAttributes addEntriesFromDictionary:[theDocument styleAttributesForStyleID:[currentState objectForKey:kSyntaxHighlightingStyleIDAttributeName]]];
            NSString *scope = [currentState objectForKey:@"scope"];
            if(scope){
                [scratchAttributes addEntriesFromDictionary:[theDocument styleAttributesForScope:scope languageContext:[currentState objectForKey:[definition keyForInheritedAutocomplete]]]];
                // FIXME default should have scope name by himself
            } else {
                //if ([[currentState objectForKey:kSyntaxHighlightingStyleIDAttributeName] isEqualToString:@"_Default"]) [scratchAttributes addEntriesFromDictionary:[theDocument styleAttributesForScope:@"meta.default"]];
                //else
                NSLog(@"No scope for state %@",[currentState objectForKey:kSyntaxHighlightingStyleIDAttributeName]);
            }
            
            [scratchAttributes setObject:savedStack forKey:kSyntaxHighlightingStackName];
            
            NSString *typeAttributeString=nil;
            if ((typeAttributeString=[currentState objectForKey:@"type"]))
                [scratchAttributes setObject:typeAttributeString forKey:kSyntaxHighlightingTypeAttributeName];
            
            if ((typeAttributeString=[currentState objectForKey:@"scope"]))
                [scratchAttributes setObject:typeAttributeString forKey:kSyntaxHighlightingScopenameAttributeName];
            
            [scratchAttributes setObject:[[savedStack lastObject] objectForKey:kSyntaxHighlightingIndentLevelName] forKey:kSyntaxHighlightingIndentLevelName];
            
            
            id inheritedSymbols = [currentState objectForKey:[definition keyForInheritedSymbols]];
            if ( inheritedSymbols )
                [scratchAttributes setObject:inheritedSymbols forKey:kSyntaxHighlightingParentModeForSymbolsAttributeName];
            id inheritedAutocomplete = [currentState objectForKey:[definition keyForInheritedAutocomplete]];
            if ( inheritedAutocomplete )
                [scratchAttributes setObject:inheritedAutocomplete forKey:kSyntaxHighlightingParentModeForAutocompleteAttributeName];
            [scratchAttributes setObject:kSyntaxHighlightingIsCorrectAttributeValue forKey:kSyntaxHighlightingIsCorrectAttributeName];
            
            [scratchAttributes setObject:[NSNumber numberWithInt:foldingDepth] forKey:kSyntaxHighlightingFoldingDepthAttributeName];
            [scratchAttributes setObject:kSyntaxHighlightingIsCorrectAttributeValue forKey:kSyntaxHighlightingIsCorrectAttributeName];
            
            if ([currentState objectForKey:@"usespellchecking"]) {
                [scratchAttributes setObject:[currentState objectForKey:@"usespellchecking"] forKey:@"usespellchecking"];
            }
            
            //NSLog(@"Calculating color range");
            
            NSRange colorRange;
            
            if (startRange.location!=NSNotFound) {
                colorRange = NSUnionRange(startRange,stateRange);
            } else {
                colorRange = stateRange;
            }
            
            //NSLog(@"Adding scratchAttributes");
            [aString addAttributes:scratchAttributes range:stateRange];
            
            //NSLog(@"Highlighting stuff");
            if ( theDocument != nil && colorRange.length > 0 ) {
                NSString *currentStateID = [currentState objectForKey:@"id"];
                //[self highlightRegularExpressionsOfAttributedString:aString inRange:colorRange forState:[currentState objectForKey:@"id"]];
                //[self highlightPlainStringsOfAttributedString:aString inRange:colorRange forState:[currentState objectForKey:@"id"]];
                
                // highlight regexes
                // and keywords
                
                { // was inline block - temporarily removed again
                    NSString *theString = [aString string];
                    NSArray *regexArray = [definition regularExpressionsInState:currentStateID];
                    
                    OGRegularExpression *aRegex;
                    OGRegularExpressionMatch *aMatch;
                    
                    int styleCount = 0;
                    for (NSArray *currentRegexStyle in regexArray) {
                        aRegex = [currentRegexStyle objectAtIndex:0];
                        //NSString *styleID = [currentRegexStyle objectAtIndex:1];
                        NSDictionary *keywordGroup = [currentRegexStyle objectAtIndex:2]; // should probably be passed in a more verbose and quicker way via an object instead of dictionaries
                        NSString *scope = [keywordGroup objectForKey:kSyntaxHighlightingScopenameAttributeName];
                        NSDictionary *attributes=[theDocument styleAttributesForScope:scope languageContext:[currentState objectForKey:[definition keyForInheritedAutocomplete]]];
                        //NSDictionary *attributes=[theDocument styleAttributesForStyleID:styleID];
                        //NSLog(@"scan %@",[keywordGroup objectForKey:@"id"]);
                        NSEnumerator *matchEnumerator = [[aRegex allMatchesInString:theString range:colorRange] objectEnumerator];
                        while ((aMatch = [matchEnumerator nextObject])) {
                            NSRange matchedRange = [aMatch rangeOfLastMatchSubstring];
                            if (matchedRange.location != NSNotFound) {
                                [aString addAttributes:attributes range:matchedRange]; // only color last matched subgroup - it is important that all regex keywords have exactly and only one matching group for this to work
                                [aString addAttribute:kSyntaxHighlightingScopenameAttributeName value:scope range:matchedRange];
                                //[aString addAttribute:[NSString stringWithFormat:@"%02d-%@-%@",styleCount,currentStateID,[keywordGroup objectForKey:@"id"]] value:scope range:matchedRange]; // For Debugging only
                                
                                if ([[keywordGroup objectForKey:@"type"] isEqualToString:@"url"]) {
                                    NSString *matchedString = [aMatch lastMatchSubstring];
                                    NSString *linkPrefix = [keywordGroup objectForKey:@"uri-prefix"];
                                    if (linkPrefix) matchedString = [linkPrefix stringByAppendingString:matchedString];
                                    
                                    // escape non-ASCII characters that are not yet escaped
                                    NSMutableCharacterSet *set = [NSMutableCharacterSet characterSetWithCharactersInString:@"%&?=#:/"];
                                    [set formUnionWithCharacterSet:[NSCharacterSet URLQueryAllowedCharacterSet]];
                                    matchedString = [matchedString stringByAddingPercentEncodingWithAllowedCharacters:set];
                                    
                                    NSURL *theURL = [NSURL URLWithString:matchedString];
                                    if (theURL && ([theURL host] || ([[theURL scheme] length] > 0 && ![[theURL scheme] hasPrefix:@"http"]))) { [aString addAttribute:NSLinkAttributeName value:theURL range:matchedRange];
                                    } else {
                                        [aString removeAttribute:NSLinkAttributeName range:matchedRange];
                                    }
                                    
                                }
                            }
                        }
                        styleCount++;
                    }
                }
                
                // highlight plain strings
                // TODO: Migrate keywords to one precompiled regex and put into block above.
                
                //			dispatch_queue_t syntaxQueue;
                //			syntaxQueue = dispatch_queue_create("de.codingmonkeys.SubEthaEdit.SyntaxQueue", NULL);
                //			dispatch_queue_t mainQueue;
                //			mainQueue = dispatch_get_main_queue();
                //
                //
                //        dispatch_async(mainQueue,
                //		^ {
                //			NSLog(@"tokens for %@: %@", currentStateID, [definition hasTokensForState:currentStateID]?@"YES":@"NO");
                //			if (![definition hasTokensForState:currentStateID]) return;
                //
                //			NSEnumerator *matchEnumerator = [[[definition tokenRegex] allMatchesInString:theString range:colorRange] objectEnumerator];
                //
                //			OGRegularExpressionMatch *aMatch;
                //		    NSString *styleID;
                //			while ((aMatch = [matchEnumerator nextObject])) {
                //				NSLog(@"foo %@", aMatch);
                //				if ((styleID = [definition styleForToken:[aMatch matchedString] inState:currentStateID])) {
                ////					dispatch_async(mainQueue, ^{
                //						[aString addAttributes:[theDocument styleAttributesForStyleID:styleID] range:[aMatch rangeOfMatchedString]];
                ////					});
                //				}
                //			}
                //		}();
                
                
            }
            //NSLog(@"Finished highlighting for this state %@ '%@'", [currentState objectForKey:@"id"], [[aString string] substringWithRange:colorRange]);
            
            currentRange = nextRange;
            foldingDepth = newFoldingDepth;
        }
    } while (currentRange.length>0);
    
    // Check if the string after the area we just colored matches up
    // Make it dirty if there is a logical glitch
    
    NSInteger nextIndex = NSMaxRange(aRange);
    if (nextIndex >= [theString length]) return;
    
    if (([aString attribute:kSyntaxHighlightingIsCorrectAttributeName atIndex:nextIndex effectiveRange:nil])) {
        BOOL matchesUp = NO;
        BOOL leftIsEnd = [[aString attribute:kSyntaxHighlightingStateDelimiterName atIndex:nextIndex-1 effectiveRange:nil] isEqualTo:kSyntaxHighlightingStateDelimiterEndValue];
        BOOL rightIsStart = [[aString attribute:kSyntaxHighlightingStateDelimiterName atIndex:nextIndex effectiveRange:nil] isEqualTo:kSyntaxHighlightingStateDelimiterStartValue];
        NSArray *leftStack = [aString attribute:kSyntaxHighlightingStackName atIndex:nextIndex-1 effectiveRange:nil];
        NSUInteger leftCount = [leftStack count];
        NSArray *rightStack = [aString attribute:kSyntaxHighlightingStackName atIndex:nextIndex effectiveRange:nil];
        NSUInteger rightCount = [rightStack count];
        
        // Same stack, no ends and begins or both an end and a begin
        if ([leftStack isEqualToArray:rightStack]) {
            if (!leftIsEnd && !rightIsStart) matchesUp = YES; 
            if (leftIsEnd && rightIsStart) matchesUp = YES; 
        }
        // Left stack exactly one bigger than right and there is an end => rightState must include leftState
        else if ((leftCount == rightCount + 1) && leftIsEnd) {
            if ([definition state:[[rightStack lastObject] objectForKey:@"state"] includesState:[[leftStack lastObject] objectForKey:@"state"]]) matchesUp = YES;
        }
        // Left stack exactly one smaller than right and there is a start => leftState must include rightState
        else if ((leftCount + 1 == rightCount) && rightIsStart) {
            if ([definition state:[[leftStack lastObject] objectForKey:@"state"] includesState:[[rightStack lastObject] objectForKey:@"state"]]) matchesUp = YES;
        }

        if (!matchesUp) {
			NSRange doesNotMatchRange = NSMakeRange(nextIndex,MIN(makeDirty,[theString length]-nextIndex));
			[aString removeAttributes:S_attributesToCleanup range:doesNotMatchRange];
        
		}
    }
}



#pragma mark - Accessors

- (NSString *)description {
    return [NSString stringWithFormat:@"SyntaxHighlighter for %@", [_syntaxDefinition name]];
}

- (SyntaxStyle *)defaultSyntaxStyle {
	[_syntaxDefinition getReady];
    return [_syntaxDefinition defaultSyntaxStyle];
}

#pragma mark - Document Interaction


// TODO: update for scopes - probably very broken now
- (void)updateStylesInTextStorage:(NSTextStorage *)aTextStorage ofDocument:(id)aSender {
    NSString *styleID;
    NSRange wholeRange=NSMakeRange(0,[aTextStorage length]);
    [aTextStorage beginEditing];
    NSRange foundRange;
    NSUInteger position=0;
    while (position<NSMaxRange(wholeRange)) {
        styleID=[aTextStorage attribute:kSyntaxHighlightingStyleIDAttributeName atIndex:position longestEffectiveRange:&foundRange inRange:wholeRange];
        if (!styleID) styleID=SyntaxStyleBaseIdentifier;
        NSDictionary *styleAttributes=[aSender styleAttributesForStyleID:styleID];
        if (!styleAttributes) styleAttributes=[aSender styleAttributesForStyleID:SyntaxStyleBaseIdentifier];
        [aTextStorage addAttributes:styleAttributes range:foundRange];
        position=NSMaxRange(foundRange);
    }
    [aTextStorage endEditing];
}

/*"Colorizes at least one chunk of the TextStorage, returns NO if there is still work to do
    document must provide the following methods:
"*/
- (BOOL)colorizeDirtyRanges:(NSTextStorage *)aTextStorage ofDocument:(id)sender {
    NSRange textRange=NSMakeRange(0,[aTextStorage length]);
    if (textRange.length == 0) return YES; // special case of empty storage
    double return_after = 0.20;
    BOOL returnvalue = NO;
    BOOL returncontrol = NO;
    clock_t start_time = clock();
    int chunks=0;
    NSRange dirtyRange;
    NSRange chunkRange;
    id correct;
    
    id theDocument = sender;

    [aTextStorage beginEditing];
    if ([aTextStorage respondsToSelector:@selector(beginLinearAttributeChanges)]) { [(id)aTextStorage beginLinearAttributeChanges];
    }
    
    NSUInteger position;
    position=0;
    while (position<NSMaxRange(textRange)) {
		correct=[aTextStorage attribute:kSyntaxHighlightingIsCorrectAttributeName atIndex:position longestEffectiveRange:&dirtyRange inRange:textRange];
        if (!correct) {
//        	NSLog(@"%s found a dirty range: %@",__FUNCTION__,NSStringFromRange(dirtyRange));
            while (YES) {
                chunks++;
                chunkRange = dirtyRange;
                if (chunkRange.length > chunkSize) chunkRange.length = chunkSize;
                else {
                    NSRange newRange = chunkRange;
                    newRange.length += 3; // To stretch to the new line if the dirty range ends with linebreak.
                    if (NSMaxRange(newRange)<=NSMaxRange(textRange)) chunkRange = newRange;
                }
                
                // Optimization path for very long lines
                // Extends dirty range based upon white space
                
                NSRange linerange = [[aTextStorage string] lineRangeForRange:chunkRange];
                if (linerange.location>=2) { // Extend linerange so matching newlines at the start works correctly.
                    linerange.location = linerange.location - 2;
                    linerange.length = linerange.length + 2;
                    linerange = [[aTextStorage string] lineRangeForRange:linerange];
                }
                if (linerange.length<=2*chunkSize) //Optimization for humongously long lines
                    chunkRange = linerange;
                else {
                    NSRange nextWhiteSpaceRange = [[aTextStorage string] rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet] options:0 range:NSMakeRange(NSMaxRange(chunkRange), [[aTextStorage string] length] - NSMaxRange(chunkRange))];
                    NSRange prevWhiteSpaceRange = [[aTextStorage string] rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet] options:NSBackwardsSearch range:NSMakeRange(0, chunkRange.location)];

                    if (nextWhiteSpaceRange.location==NSNotFound)
                        chunkRange = NSUnionRange(chunkRange, NSMakeRange(NSMaxRange(linerange), 0));
                    else
                        chunkRange = NSUnionRange(chunkRange, nextWhiteSpaceRange);
                    
                    if (prevWhiteSpaceRange.location!=NSNotFound)
                        chunkRange = NSUnionRange(chunkRange, prevWhiteSpaceRange);                    
                }

                
                //DEBUGLOG(@"SyntaxHighlighterDomain", SimpleLogLevel, @"Chunk #%d, Dirty: %@, Chunk: %@", chunks, NSStringFromRange(dirtyRange),NSStringFromRange(chunkRange));
								
				[self highlightAttributedString:aTextStorage inRange:chunkRange ofDocument:theDocument];
				
								   
                if ((((double)(clock()-start_time))/CLOCKS_PER_SEC) > return_after) {
                    DEBUGLOG(@"SyntaxHighlighterDomain", SimpleLogLevel, @"Coloring took too long, aborting after %f seconds",(((double)(clock()-start_time))/CLOCKS_PER_SEC));
                    returncontrol = YES;
                    break;
                }
                
                NSUInteger lastDirty=NSMaxRange(dirtyRange);
                if (NSMaxRange(chunkRange) < lastDirty) {
                    dirtyRange.location = NSMaxRange(chunkRange);
                    dirtyRange.length = lastDirty-dirtyRange.location;
                } else {
                    DEBUGLOG(@"SyntaxHighlighterDomain", SimpleLogLevel, @"Finished coloring of dirtyRange after %f seconds",(((double)(clock()-start_time))/CLOCKS_PER_SEC));
                    break;
                }
            }
            position=NSMaxRange(chunkRange);
        } else {
            position=NSMaxRange(dirtyRange);
            if (position>=[aTextStorage length]) {
                returnvalue = YES;
                break;
            }
        }

        if (returncontrol) {
            DEBUGLOG(@"SyntaxHighlighterDomain", SimpleLogLevel, @"Returning control");
            break;
        }

        // adjust Range
        textRange.length=NSMaxRange(textRange);
        textRange.location=position;
        textRange.length  =textRange.length-position;
    }

    if ([aTextStorage respondsToSelector:@selector(endLinearAttributeChanges)]) { [(id)aTextStorage endLinearAttributeChanges];
    }
    [aTextStorage endEditing];

    theDocument = nil; //Fixes a crasher accessing zombies
    
    return returnvalue;
}

/*"Cleans up any attribute it introduced to the textstorage while colorizing it"*/
- (void)cleanUpTextStorage:(NSTextStorage *)aTextStorage  {
    [self cleanUpTextStorage:aTextStorage inRange:NSMakeRange(0,[aTextStorage length])];
}

- (void)cleanUpTextStorage:(NSTextStorage *)aTextStorage inRange:(NSRange)aRange {
    [aTextStorage beginEditing];
    if ([aTextStorage respondsToSelector:@selector(beginLinearAttributeChanges)]) { [(id)aTextStorage beginLinearAttributeChanges];
    }
    [aTextStorage removeAttributes:S_attributesToCleanup range:aRange];
    if ([aTextStorage respondsToSelector:@selector(endLinearAttributeChanges)]) { [(id)aTextStorage endLinearAttributeChanges];
    }
    [aTextStorage endEditing];
}


@end




/*
 
Ideas:
 
- separted parsing from coloring.
- data structure to represent stacks of ranges
- color only visible code
 
 
 */
