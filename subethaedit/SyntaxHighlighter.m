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

#define chunkSize              		5000
#define makeDirty              		 100

NSString * const kSyntaxHighlightingIsCorrectAttributeName  = @"HighlightingIsCorrect";
NSString * const kSyntaxHighlightingIsCorrectAttributeValue = @"Correct";
NSString * const kSyntaxHighlightingStackName = @"HighlightingStack";
NSString * const kSyntaxHighlightingStateDelimiterName = @"HighlightingStateDelimiter";
NSString * const kSyntaxHighlightingStyleIDAttributeName = @"styleID";
NSString * const kSyntaxHighlightingTypeAttributeName = @"Type";
NSString * const kSyntaxHighlightingParentModeForSymbolsAttributeName = @"ParentModeForSymbols";
NSString * const kSyntaxHighlightingParentModeForAutocompleteAttributeName = @"ParentModeForAutocomplete";

@implementation SyntaxHighlighter
/*"A Syntax Highlighter"*/

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
    
    NSRange currentRange = aRange;
    int delimiterStateNumber;
    NSDictionary *defaultState = [definition defaultState];
    NSDictionary *currentState = nil;
    NSMutableArray *stack = nil;
    
    OGRegularExpression *stateDelimiter;
    OGRegularExpressionMatch *delimiterMatch;


    // Clean up state attributes in the string we work on now
	NSArray *attributesToCleanup = [NSArray arrayWithObjects:kSyntaxHighlightingStackName,kSyntaxHighlightingStateDelimiterName,kSyntaxHighlightingTypeAttributeName,kSyntaxHighlightingParentModeForSymbolsAttributeName,kSyntaxHighlightingParentModeForAutocompleteAttributeName,kSyntaxHighlightingIsCorrectAttributeName,nil];
    [aString removeAttributes:attributesToCleanup range:aRange];

    NSMutableDictionary *scratchAttributes = [NSMutableDictionary dictionary];

    // Initialize (or preserve) stack
    NSArray *savedStack = nil;
    if ((!stack)&&(currentRange.location>0)) {
        stack = [NSMutableArray arrayWithArray:[aString attribute:kSyntaxHighlightingStackName atIndex:currentRange.location-1 effectiveRange:nil]];
        if ([[aString attribute:kSyntaxHighlightingStateDelimiterName atIndex:currentRange.location-1 effectiveRange:nil] isEqualTo:@"End"]) {
            [stack removeLastObject];
        }
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
			if (combinedDelimiterString && [OGRegularExpression isValidExpressionString:combinedDelimiterString]) {
				stateDelimiter = [[[OGRegularExpression alloc] initWithString:combinedDelimiterString options:OgreFindNotEmptyOption|OgreCaptureGroupOption] autorelease];
			}
		}
        
        NSRange delimiterRange, stateRange, startRange, nextRange;
        startRange = NSMakeRange(NSNotFound,0);
        // Add start to colorRange to color keywords within
        // But check for starts that contain \n
        NSRange attRange;
        if (currentRange.location>0) 
        if ((currentRange.location-1>=aRange.location)&&([[aString attribute:kSyntaxHighlightingStateDelimiterName atIndex:currentRange.location-1 longestEffectiveRange:&attRange inRange:aRange] isEqualToString:@"Start"])){
            NSRange sameStackRange;
            [aString attribute:kSyntaxHighlightingStackName atIndex:currentRange.location-1 longestEffectiveRange:&sameStackRange inRange:aRange];
            startRange = NSIntersectionRange(attRange,sameStackRange);
            if (startRange.length == 0) startRange.location = NSNotFound;
        } 
                            
        if ((delimiterMatch = [stateDelimiter matchInString:theString range:currentRange])) { // Search for a delimiter
            //NSLog(@"Searching for next delimiter");
            delimiterRange = [delimiterMatch rangeOfMatchedString];
            
            stateRange = NSMakeRange(currentRange.location, NSMaxRange(delimiterRange) - currentRange.location);

            NSString *delimiterName = [delimiterMatch nameOfSubstringAtIndex:[delimiterMatch indexOfFirstMatchedSubstring]];
            delimiterStateNumber = [[delimiterName substringFromIndex:16] intValue];
            
            if (delimiterStateNumber<4242) { // Found a start within current state
                //NSLog(@"Found a start: '%@'",[[aString string] substringWithRange:delimiterRange]);
				
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
						if (groupName && replacement) [combinedDelimiterString replaceOccurrencesOfString:[NSString stringWithFormat:@"(?#see-insert-start-group:%@)",groupName] withString:replacement options:0 range:NSMakeRange(0,[combinedDelimiterString length])];
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
                [scratchAttributes setObject:@"Start" forKey:kSyntaxHighlightingStateDelimiterName];
				NSString *typeAttributeString;
				if ((typeAttributeString=[subState objectForKey:@"type"]))
					[scratchAttributes setObject:typeAttributeString forKey:kSyntaxHighlightingTypeAttributeName];
				
				[scratchAttributes setObject:[currentState objectForKey:[definition keyForInheritedSymbols]] forKey:kSyntaxHighlightingParentModeForSymbolsAttributeName];
				[scratchAttributes setObject:kSyntaxHighlightingIsCorrectAttributeValue forKey:kSyntaxHighlightingIsCorrectAttributeName];
				[scratchAttributes setObject:[currentState objectForKey:[definition keyForInheritedAutocomplete]] forKey:kSyntaxHighlightingParentModeForAutocompleteAttributeName];
				
                [aString addAttributes:scratchAttributes range:delimiterRange];
            } else { // Found end of current state
                //NSLog(@"Found and end");
                nextRange.location = NSMaxRange(stateRange);
                nextRange.length = currentRange.length - stateRange.length;
                [aString addAttribute:kSyntaxHighlightingStateDelimiterName value:@"End" range:delimiterRange];
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
		
		[scratchAttributes setObject:[currentState objectForKey:[definition keyForInheritedSymbols]] forKey:kSyntaxHighlightingParentModeForSymbolsAttributeName];
		[scratchAttributes setObject:[currentState objectForKey:[definition keyForInheritedAutocomplete]] forKey:kSyntaxHighlightingParentModeForAutocompleteAttributeName];
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
        
        [syntaxPool release];
    } while (currentRange.length>0);
    
    // Check if the string after the area we just colored matches up
    // Make it dirty if there is a logical glitch
    
    int nextIndex = NSMaxRange(aRange);
    if (nextIndex >= [theString length]) return;
    
    if (([aString attribute:kSyntaxHighlightingIsCorrectAttributeName atIndex:nextIndex effectiveRange:nil])) {
        BOOL matchesUp = NO;
        BOOL leftIsEnd = [[aString attribute:kSyntaxHighlightingStateDelimiterName atIndex:nextIndex-1 effectiveRange:nil] isEqualTo:@"End"];
        BOOL rightIsStart = [[aString attribute:kSyntaxHighlightingStateDelimiterName atIndex:nextIndex effectiveRange:nil] isEqualTo:@"Start"];
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

-(void)highlightPlainStringsOfAttributedString:(NSMutableAttributedString*)aString inRange:(NSRange)aRange forState:(NSString *)aState
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

        NSDictionary *attributes=[theDocument styleAttributesForStyleID:[currentRegexStyle objectAtIndex:1]];
                
        NSEnumerator *matchEnumerator = [[aRegex allMatchesInString:theString range:aRange] objectEnumerator];
        while ((aMatch = [matchEnumerator nextObject])) {
            [aString addAttributes:attributes range:[aMatch rangeOfSubstringAtIndex:1]]; // Only color first group.
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
    unsigned int position=0;
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
    double return_after = 0.2;
    BOOL returnvalue = NO;
    BOOL returncontrol = NO;
    clock_t start_time = clock();
    int chunks=0;
    NSRange dirtyRange;
    NSRange chunkRange;
    id correct;
    
    theDocument = sender;
    [aTextStorage beginEditing];
    
    unsigned int position;
    position=0;
    while (position<NSMaxRange(textRange)) {
        correct=[aTextStorage attribute:kSyntaxHighlightingIsCorrectAttributeName atIndex:position longestEffectiveRange:&dirtyRange inRange:textRange];
        if (!correct) {
            while (YES) {
                chunks++;
                chunkRange = dirtyRange;
                if (chunkRange.length > chunkSize) chunkRange.length = chunkSize;
                else {
                    NSRange newRange = chunkRange;
                    newRange.length =+ 3; // To stretch to the new line if the dirty range ends with linebreak.
                    if (NSMaxRange(newRange)<=NSMaxRange(textRange)) chunkRange = newRange;
                }
                
                chunkRange = [[aTextStorage string] lineRangeForRange:chunkRange];

                //DEBUGLOG(@"SyntaxHighlighterDomain", AllLogLevel, @"Chunk #%d, Dirty: %@, Chunk: %@", chunks, NSStringFromRange(dirtyRange),NSStringFromRange(chunkRange));


                [self highlightAttributedString:aTextStorage inRange:chunkRange];
                
                
                if ((((double)(clock()-start_time))/CLOCKS_PER_SEC) > return_after) {
                    DEBUGLOG(@"SyntaxHighlighterDomain", AllLogLevel, @"Coloring took too long, aborting after %f seconds",(((double)(clock()-start_time))/CLOCKS_PER_SEC));
                    returncontrol = YES;
                    break;
                }
                
                unsigned int lastDirty=NSMaxRange(dirtyRange);
                if (NSMaxRange(chunkRange) < lastDirty) {
                    dirtyRange.location = NSMaxRange(chunkRange);
                    dirtyRange.length = lastDirty-dirtyRange.location;
                } else {
                    DEBUGLOG(@"SyntaxHighlighterDomain", AllLogLevel, @"Finished coloring of dirtyRange after %f seconds",(((double)(clock()-start_time))/CLOCKS_PER_SEC));
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
            DEBUGLOG(@"SyntaxHighlighterDomain", AllLogLevel, @"Returning control");
            break;
        }

        // adjust Range
        textRange.length=NSMaxRange(textRange);
        textRange.location=position;
        textRange.length  =textRange.length-position;
    }
    
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
    [aTextStorage removeAttributes:[NSArray arrayWithObjects:kSyntaxHighlightingIsCorrectAttributeName,kSyntaxHighlightingStackName,kSyntaxHighlightingStateDelimiterName,kSyntaxHighlightingTypeAttributeName,kSyntaxHighlightingParentModeForAutocompleteAttributeName,kSyntaxHighlightingParentModeForSymbolsAttributeName,nil] range:aRange];
    [aTextStorage endEditing];
}


@end
