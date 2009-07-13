//
//  SyntaxHighlighter.m
//  SyntaxTestBench
//
//  Created by Martin Pittenauer on Thu Mar 04 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//
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
NSString * const kSyntaxHighlightingStackName = @"HighlightingStack";
NSString * const kSyntaxHighlightingStateDelimiterName = @"HighlightingStateDelimiter";
NSString * const kSyntaxHighlightingStateDelimiterStartValue = @"Start";
NSString * const kSyntaxHighlightingStateDelimiterEndValue = @"End";
NSString * const kSyntaxHighlightingFoldDelimiterName = @"HighlightingFoldDelimiter";
NSString * const kSyntaxHighlightingStyleIDAttributeName = @"styleID";
NSString * const kSyntaxHighlightingTypeAttributeName = @"Type";
NSString * const kSyntaxHighlightingParentModeForSymbolsAttributeName = @"ParentModeForSymbols";
NSString * const kSyntaxHighlightingParentModeForAutocompleteAttributeName = @"ParentModeForAutocomplete";
NSString * const kSyntaxHighlightingFoldingDepthAttributeName = @"FoldingDepth";

NSString * const kSyntaxHighlightingTypeComment = @"comment";


@implementation SyntaxHighlighter
/*"A Syntax Highlighter"*/

static  NSMutableDictionary *S_transientRegexCache = nil;

#pragma mark - 
#pragma mark - Initizialisation (fizzle televizzle)
#pragma mark - 

/*"Initiates the Highlighter with a Syntax Definition"*/

- (id)initWithSyntaxDefinition:(SyntaxDefinition *)aSyntaxDefinition 
{
    self=[super init];
    if (self) {
        [self setSyntaxDefinition:aSyntaxDefinition];
        //NSLog(@"Using onigruma %@",[OGRegularExpression onigurumaVersion]);
        if (!S_transientRegexCache) S_transientRegexCache = [NSMutableDictionary new];
    }
    DEBUGLOG(@"SyntaxHighlighterDomain", AllLogLevel, @"Initiated new SyntaxHighlighter:%@",[self description]);
    return self;
}

#pragma mark - 
#pragma mark - Highlighting
#pragma mark - 

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
-(void)highlightAttributedString:(NSMutableAttributedString *)aString inRange:(NSRange)aRange 
{    
    SyntaxDefinition *definition = [self syntaxDefinition];
    if (!definition) NSLog(@"ERROR: No defintion for highlighter.");
	[definition getReady]; // Make sure everything is setup 
    NSString *theString = [aString string];

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
	NSArray *attributesToCleanup = [NSArray arrayWithObjects:kSyntaxHighlightingStackName,kSyntaxHighlightingStateDelimiterName,kSyntaxHighlightingFoldDelimiterName,kSyntaxHighlightingTypeAttributeName,kSyntaxHighlightingParentModeForSymbolsAttributeName,kSyntaxHighlightingParentModeForAutocompleteAttributeName,kSyntaxHighlightingIsCorrectAttributeName,kSyntaxHighlightingFoldingDepthAttributeName,NSLinkAttributeName,nil];
    [aString removeAttributes:attributesToCleanup range:aRange];

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
    if (!stack) stack = [NSMutableArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:[defaultState objectForKey:@"id"], @"state", nil], nil];
    
    do {

        NSAutoreleasePool *syntaxPool = [NSAutoreleasePool new];
                    
        //NSLog(@"Stack at start: %@", stack);
        currentState = [definition stateForID:[[stack lastObject] objectForKey:@"state"]];
        
        // Identify the next block of homogenous state

        stateDelimiter = [currentState objectForKey:@"Combined Delimiter Regex"];
		// If using transcendence we have to compile on the fly.
		if (!stateDelimiter) {
			NSString *combinedDelimiterString = [[stack lastObject] objectForKey:@"combinedDelimiterString"];
            stateDelimiter = [S_transientRegexCache objectForKey:combinedDelimiterString];
            if (!stateDelimiter) {
                if (combinedDelimiterString && [OGRegularExpression isValidExpressionString:combinedDelimiterString]) {
                    stateDelimiter = [[[OGRegularExpression alloc] initWithString:combinedDelimiterString options:OgreFindNotEmptyOption|OgreCaptureGroupOption] autorelease];
                    if (stateDelimiter) [S_transientRegexCache setObject:stateDelimiter forKey:combinedDelimiterString];
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
        
        if ((delimiterMatch = [stateDelimiter matchInString:theString range:currentRange])) { // Search for a delimiter
            //NSLog(@"Searching for next delimiter");
            delimiterRange = [delimiterMatch rangeOfMatchedString];
            
            // FIXME Caret support introduces endless coloring in SoupDump.html
            
//            NSRange checkForStartFalsePositiveRange = [theString lineRangeForRange:delimiterRange];
//            if (checkForStartFalsePositiveRange.location>=aRange.location) {
//                OGRegularExpressionMatch * checkMatch;
//                NSEnumerator *checkMatchEnumerator = [[stateDelimiter allMatchesInString:theString range:checkForStartFalsePositiveRange] objectEnumerator];
//                BOOL valid = NO;
//                while ((checkMatch = [checkMatchEnumerator nextObject])) {
//                    if (checkMatch && [delimiterMatch indexOfFirstMatchedSubstring]==[checkMatch indexOfFirstMatchedSubstring]) {
//                        NSRange secondDelimiterRange = [checkMatch rangeOfMatchedString];
//                        if (secondDelimiterRange.location == delimiterRange.location) valid = YES;
//                    }
//
//                }
//                if (!valid) {
//                    currentRange.location++;
//                    currentRange.length--;
//                    continue;
//                }
//                
//            }
                        
            stateRange = NSMakeRange(currentRange.location, NSMaxRange(delimiterRange) - currentRange.location);

            NSString *delimiterName = [delimiterMatch nameOfSubstringAtIndex:[delimiterMatch indexOfFirstMatchedSubstring]];
            delimiterStateNumber = [[delimiterName substringFromIndex:16] intValue];
            
            if (delimiterStateNumber<4242) { // Found a start within current state
                //NSLog(@"Found a start: '%@' current range: %@",[[aString string] substringWithRange:delimiterRange], NSStringFromRange(currentRange));
				
                nextRange.location = NSMaxRange(stateRange);
                nextRange.length = currentRange.length - stateRange.length;

                //Exclude delimiterRang from stateRange
                stateRange.length = stateRange.length - delimiterRange.length;
                
                NSDictionary *subState = [[currentState objectForKey:@"states"] objectAtIndex:delimiterStateNumber];
                savedStack = [[stack copy] autorelease];

				// Check for transcendence
				// Use substringNamed: of delimiterMatch to get the content of named groups
				NSArray *captureGroups = [subState objectForKey:@"Combined Delimiter String End Capture Groups"];
				NSMutableString *combinedDelimiterString = nil;
				if (captureGroups) {
					combinedDelimiterString = [[[subState objectForKey:@"Combined Delimiter String"] mutableCopy] autorelease];
					int i;
					int count = [captureGroups count];
					for (i=0;i<count;i++) {
						NSString *groupName = [captureGroups objectAtIndex:i];
						NSString *replacement = [[delimiterMatch substringNamed:groupName] stringByReplacingRegularExpressionOperators];
						if (groupName && replacement) {
                            [combinedDelimiterString replaceOccurrencesOfString:[NSString stringWithFormat:@"(?#see-insert-start-group:%@)",groupName] withString:replacement options:0 range:NSMakeRange(0,[combinedDelimiterString length])];
                        }
					}
				}
				
				if (combinedDelimiterString) {
					[stack addObject:[NSDictionary dictionaryWithObjectsAndKeys:[subState objectForKey:@"id"], @"state", combinedDelimiterString, @"combinedDelimiterString", nil]];
				} else {
					[stack addObject:[NSDictionary dictionaryWithObjectsAndKeys:[subState objectForKey:@"id"], @"state", nil]];
				}
                
                [scratchAttributes removeAllObjects];
                [scratchAttributes addEntriesFromDictionary:[theDocument styleAttributesForStyleID:[subState objectForKey:kSyntaxHighlightingStyleIDAttributeName]]];
                [scratchAttributes setObject:[[stack copy] autorelease] forKey:kSyntaxHighlightingStackName];
                [scratchAttributes setObject:kSyntaxHighlightingStateDelimiterStartValue forKey:kSyntaxHighlightingStateDelimiterName];
				NSString *typeAttributeString;
				if ((typeAttributeString=[subState objectForKey:@"type"]))
					[scratchAttributes setObject:typeAttributeString forKey:kSyntaxHighlightingTypeAttributeName];
				                
                subState = [definition stateForID:[subState objectForKey:@"id"]];
				[scratchAttributes setObject:[subState objectForKey:[definition keyForInheritedSymbols]] forKey:kSyntaxHighlightingParentModeForSymbolsAttributeName];
				[scratchAttributes setObject:[subState objectForKey:[definition keyForInheritedAutocomplete]] forKey:kSyntaxHighlightingParentModeForAutocompleteAttributeName];
                if ([[subState objectForKey:@"foldable"] isEqualToString:@"yes"]) [scratchAttributes setObject:kSyntaxHighlightingStateDelimiterStartValue forKey:kSyntaxHighlightingFoldDelimiterName];

                if ([[subState objectForKey:@"foldable"] isEqualToString:@"yes"]) {
                    newFoldingDepth++;
                }
                [scratchAttributes setObject:[NSNumber numberWithInt:newFoldingDepth] forKey:kSyntaxHighlightingFoldingDepthAttributeName];
                [scratchAttributes setObject:kSyntaxHighlightingIsCorrectAttributeValue forKey:kSyntaxHighlightingIsCorrectAttributeName];
				
                [aString addAttributes:scratchAttributes range:delimiterRange];

            } else { // Found end of current state
                //NSLog(@"Found an end: '%@' current range: %@",[[aString string] substringWithRange:delimiterRange], NSStringFromRange(currentRange));
                
                NSRange matchedEndRange = [delimiterMatch rangeOfSubstringNamed:@"trimmedend"];
                if (matchedEndRange.location != NSNotFound) delimiterRange = matchedEndRange;
                
                nextRange.location = NSMaxRange(stateRange);
                nextRange.length = currentRange.length - stateRange.length;
                [scratchAttributes setObject:kSyntaxHighlightingStateDelimiterEndValue forKey:kSyntaxHighlightingStateDelimiterName];
                if ([[currentState objectForKey:@"foldable"] isEqualToString:@"yes"]) {
					[scratchAttributes setObject:kSyntaxHighlightingStateDelimiterEndValue forKey:kSyntaxHighlightingFoldDelimiterName];
                   newFoldingDepth = foldingDepth - 1;
                }
                [aString addAttributes:scratchAttributes range:delimiterRange];
                savedStack = [[stack copy] autorelease];
                [stack removeLastObject]; // Default state doesn't have an end, stack is always > 0
            }
            
        //NSLog(@"Current stack: %@", stack);
        
        } else {  // No end found in chunk, so mark the whole chunk
            //DEBUGLOG(@"SyntaxHighlighterDomain", AllLogLevel, @"State %@ does not end in chunk",[currentState objectForKey:@"id"]);
            //NSLog(@"Nothing interesting here.");
            stateRange = NSMakeRange(currentRange.location, NSMaxRange(aRange) - currentRange.location);
            nextRange = NSMakeRange(NSNotFound,0);
			savedStack = [[stack copy] autorelease];
        }

        // Now apply style to the identified range

        //NSLog(@"Building scratch attributes");
        [scratchAttributes removeAllObjects];
        [scratchAttributes addEntriesFromDictionary:[theDocument styleAttributesForStyleID:[currentState objectForKey:kSyntaxHighlightingStyleIDAttributeName]]];
        [scratchAttributes setObject:savedStack forKey:kSyntaxHighlightingStackName];
		NSString *typeAttributeString;
		if ((typeAttributeString=[currentState objectForKey:@"type"]))
			[scratchAttributes setObject:typeAttributeString forKey:kSyntaxHighlightingTypeAttributeName];
		
		id inheritedSymbols = [currentState objectForKey:[definition keyForInheritedSymbols]]; 
		if ( inheritedSymbols )
			[scratchAttributes setObject:inheritedSymbols forKey:kSyntaxHighlightingParentModeForSymbolsAttributeName];
		id inheritedAutocomplete = [currentState objectForKey:[definition keyForInheritedAutocomplete]];
		if ( inheritedAutocomplete )
			[scratchAttributes setObject:inheritedAutocomplete forKey:kSyntaxHighlightingParentModeForAutocompleteAttributeName];
		[scratchAttributes setObject:kSyntaxHighlightingIsCorrectAttributeValue forKey:kSyntaxHighlightingIsCorrectAttributeName];

        [scratchAttributes setObject:[NSNumber numberWithInt:foldingDepth] forKey:kSyntaxHighlightingFoldingDepthAttributeName];
        [scratchAttributes setObject:kSyntaxHighlightingIsCorrectAttributeValue forKey:kSyntaxHighlightingIsCorrectAttributeName];
			
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
        
        [self highlightRegularExpressionsOfAttributedString:aString inRange:colorRange forState:[currentState objectForKey:@"id"]];
        [self highlightPlainStringsOfAttributedString:aString inRange:colorRange forState:[currentState objectForKey:@"id"]];
        
        //NSLog(@"Finished highlighting for this state %@ '%@'", [currentState objectForKey:@"id"], [[aString string] substringWithRange:colorRange]);

        currentRange = nextRange;
        foldingDepth = newFoldingDepth;
        [syntaxPool release];
    } while (currentRange.length>0);
    
    // Check if the string after the area we just colored matches up
    // Make it dirty if there is a logical glitch
    
    int nextIndex = NSMaxRange(aRange);
    if (nextIndex >= [theString length]) return;
    
    if (([aString attribute:kSyntaxHighlightingIsCorrectAttributeName atIndex:nextIndex effectiveRange:nil])) {
        BOOL matchesUp = NO;
        BOOL leftIsEnd = [[aString attribute:kSyntaxHighlightingStateDelimiterName atIndex:nextIndex-1 effectiveRange:nil] isEqualTo:kSyntaxHighlightingStateDelimiterEndValue];
        BOOL rightIsStart = [[aString attribute:kSyntaxHighlightingStateDelimiterName atIndex:nextIndex effectiveRange:nil] isEqualTo:kSyntaxHighlightingStateDelimiterStartValue];
        NSArray *leftStack = [aString attribute:kSyntaxHighlightingStackName atIndex:nextIndex-1 effectiveRange:nil];
        int leftCount = [leftStack count];
        NSArray *rightStack = [aString attribute:kSyntaxHighlightingStackName atIndex:nextIndex effectiveRange:nil];
        int rightCount = [rightStack count];
        
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
        else if ((leftCount == rightCount - 1) && rightIsStart) {  
            if ([definition state:[[leftStack lastObject] objectForKey:@"state"] includesState:[[rightStack lastObject] objectForKey:@"state"]]) matchesUp = YES;
        }

        if (!matchesUp) {
			NSRange doesNotMatchRange = NSMakeRange(nextIndex,MIN(makeDirty,[theString length]-nextIndex));
			[aString removeAttributes:attributesToCleanup range:doesNotMatchRange];
        }
    }
}

// TODO: Get rid of this. See Below.

-(void)highlightPlainStringsOfAttributedString:(NSMutableAttributedString*)aString inRange:(NSRange)aRange forState:(NSString *)aState
{
    NSString *styleID;
    SyntaxDefinition *definition = [self syntaxDefinition];
    NSString *theString = [aString string];

    if (![definition hasTokensForState:aState]) return;

    NSEnumerator *matchEnumerator = [[[definition tokenRegex] allMatchesInString:theString range:aRange] objectEnumerator];

    OGRegularExpressionMatch *aMatch;
    while ((aMatch = [matchEnumerator nextObject])) {
        if ((styleID = [definition styleForToken:[aMatch matchedString] inState:aState])) {
            [aString addAttributes:[theDocument styleAttributesForStyleID:styleID] range:[aMatch rangeOfMatchedString]];
        }
    }
}

-(void)oldHighlightPlainStringsOfAttributedString:(NSMutableAttributedString*)aString inRange:(NSRange)aRange forState:(NSString *)aState
{
    int aMaxRange = NSMaxRange(aRange);
    int location;
    NSString *styleID;
    SyntaxDefinition *definition = [self syntaxDefinition];
    
    if (![definition hasTokensForState:aState]) return;
    
    
    NSScanner *scanner = [NSScanner scannerWithString:[aString string]];
    [scanner setCharactersToBeSkipped:[definition invertedTokenSet]];
    [scanner setScanLocation:aRange.location];
    do {
        NSString *token = nil;
        if ([scanner scanCharactersFromSet:[definition tokenSet] intoString:&token]) {
            location = [scanner scanLocation];
            if (token) {
                //DEBUGLOG(@"SyntaxHighlighterDomain", AllLogLevel, @"Found Token: %@ in State %d",token, aState);
                if ((styleID = [definition styleForToken:token inState:aState])) {
                    int tokenlength = [token length];
                    NSRange foundRange = NSMakeRange(location-tokenlength,tokenlength);
                    if (NSMaxRange(foundRange)>aMaxRange) break;
                    
                    [aString addAttributes:[theDocument styleAttributesForStyleID:styleID] range:foundRange];
                }
            }
        } else break;
    } while (location < aMaxRange);
    
}

// TODO: Migrate keywords to one precompiled regex
// Roll this method back into the highlighter loop to avoid duplicating efforts

-(void)highlightRegularExpressionsOfAttributedString:(NSMutableAttributedString*)aString inRange:(NSRange)aRange forState:(NSString *)aState
{
    NSArray *regexArray = [[self syntaxDefinition] regularExpressionsInState:aState];    
    
    OGRegularExpression *aRegex;
    OGRegularExpressionMatch *aMatch;
    NSString *theString = [aString string];
    int i;
    int count = [regexArray count];
    
    for (i=0; i<count; i++) {
        NSArray *currentRegexStyle = [regexArray objectAtIndex:i];
        aRegex = [currentRegexStyle objectAtIndex:0];
        NSString *styleID = [currentRegexStyle objectAtIndex:1];
        NSDictionary *attributes=[theDocument styleAttributesForStyleID:styleID];                
        NSEnumerator *matchEnumerator = [[aRegex allMatchesInString:theString range:aRange] objectEnumerator];
        while ((aMatch = [matchEnumerator nextObject])) {
        	NSRange matchedRange = [aMatch rangeOfLastMatchSubstring];
        	if (matchedRange.location != NSNotFound) {
	            [aString addAttributes:attributes range:matchedRange]; // only color last matched subgroup - it is important that all regex keywords have exactly and only one matching group for this to work
                if ([attributes objectForKey:NSLinkAttributeName]) {
                    NSURL *theURL = [NSURL URLWithString:[aMatch lastMatchSubstring]];
                    // TODO: prepend the matched string with the uri-prefix attribute of the keyword group
                    if (theURL && ([theURL host] || ([theURL scheme] && ![[theURL scheme] hasPrefix:@"http"]))) [aString addAttribute:NSLinkAttributeName value:theURL range:matchedRange];
                    else [aString removeAttribute:NSLinkAttributeName range:matchedRange];
                }
	        }
        }
    }
}

#pragma mark - 
#pragma mark - Accessors
#pragma mark - 

- (NSString *)description {
    return [NSString stringWithFormat:@"SyntaxHighlighter for %@", [I_syntaxDefinition name]];
}

- (SyntaxDefinition *)syntaxDefinition
{
    return I_syntaxDefinition;
}

- (void)setSyntaxDefinition:(SyntaxDefinition *)aSyntaxDefinition
{
//    [I_syntaxDefinition autorelease];
//     I_syntaxDefinition = [aSyntaxDefinition retain];
    I_syntaxDefinition = aSyntaxDefinition;
}

- (SyntaxStyle *)defaultSyntaxStyle {
	[I_syntaxDefinition getReady];
    return [I_syntaxDefinition defaultSyntaxStyle];
}

#pragma mark - 
#pragma mark - Document Interaction
#pragma mark - 

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
- (BOOL)colorizeDirtyRanges:(NSTextStorage *)aTextStorage ofDocument:(id)sender
{
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
    
    theDocument = sender;
    [aTextStorage beginEditing];
    if ([aTextStorage respondsToSelector:@selector(beginLinearAttributeChanges)]) [(id)aTextStorage beginLinearAttributeChanges];
    
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


                [self highlightAttributedString:aTextStorage inRange:chunkRange];
                
                
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
    
    if ([aTextStorage respondsToSelector:@selector(endLinearAttributeChanges)]) [(id)aTextStorage endLinearAttributeChanges];
    [aTextStorage endEditing];
    
    return returnvalue;
}

/*"Cleans up any attribute it introduced to the textstorage while colorizing it"*/
- (void)cleanUpTextStorage:(NSTextStorage *)aTextStorage 
{
    [self cleanUpTextStorage:aTextStorage inRange:NSMakeRange(0,[aTextStorage length])];
}

- (void)cleanUpTextStorage:(NSTextStorage *)aTextStorage inRange:(NSRange)aRange
{
    [aTextStorage beginEditing];
    if ([aTextStorage respondsToSelector:@selector(beginLinearAttributeChanges)]) [(id)aTextStorage beginLinearAttributeChanges];
    [aTextStorage removeAttributes:[NSArray arrayWithObjects:kSyntaxHighlightingIsCorrectAttributeName,kSyntaxHighlightingStackName,kSyntaxHighlightingStateDelimiterName,kSyntaxHighlightingTypeAttributeName,kSyntaxHighlightingParentModeForAutocompleteAttributeName,kSyntaxHighlightingParentModeForSymbolsAttributeName,NSLinkAttributeName,nil] range:aRange];
    if ([aTextStorage respondsToSelector:@selector(endLinearAttributeChanges)]) [(id)aTextStorage endLinearAttributeChanges];
    [aTextStorage endEditing];
}


@end
