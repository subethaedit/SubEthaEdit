//
//  SyntaxHighlighter.m
//  SyntaxTestBench
//
//  Created by Martin Pittenauer on Thu Mar 04 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//
// blabla 

#import "SyntaxHighlighter.h"
#import "PlainTextDocument.h"
#import "time.h"
#import <OgreKit/OgreKit.h>

#define chunkSize              		5000

NSString * const kSyntaxHighlightingIsCorrectAttributeName  = @"HighlightingIsCorrect";
NSString * const kSyntaxHighlightingIsCorrectAttributeValue = @"Correct";
NSString * const kSyntaxHighlightingStateName = @"HighlightingState";
NSString * const kSyntaxHighlightingStateDelimiterName = @"HighlightingStateDelimiter";

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
    }
    DEBUGLOG(@"SyntaxHighlighterDomain", AllLogLevel, @"Initiated new SyntaxHighlighter:%@",[self description]);
    return self;
}

#pragma mark - 
#pragma mark - Highlighting
#pragma mark - 

-(void)highlightAttributedString:(NSMutableAttributedString*)aString inRange:(NSRange)aRange
{
    [self stateMachineOnAttributedString:aString inRange:aRange];
}

-(void)stateMachineOnAttributedString:(NSMutableAttributedString *)aString inRange:(NSRange)aRange 
{
    SyntaxDefinition *definition = [self syntaxDefinition];
    if (!definition) NSLog(@"ERROR: No defintion for highlighter.");
    NSString *theString = [aString string];
    aRange = [theString lineRangeForRange:aRange];
    
    NSRange currentRange = aRange;
    int stateNumber;
    NSDictionary *foundState;
    NSDictionary *defaultState = [definition defaultState];
    NSNumber *stateName;
    
    OGRegularExpression *stateStarts = [definition combinedStateRegex];
    OGRegularExpression *stateEnd;
    OGRegularExpressionMatch *startMatch;
    OGRegularExpressionMatch *endMatch;

    /*
    Basic layout of the Chunky State Machine Algorithm:
    
    do {
        if (state) 
            searchEnd
            color
        else
            colorDefaultState
            searchAndMarkNextState
    } while (ready)
    
    */
    
    if (stateStarts) do {
        DEBUGLOG(@"SyntaxHighlighterDomain", AllLogLevel, @"New loop with Range: %@",NSStringFromRange(currentRange));
        NSAutoreleasePool *syntaxPool = [NSAutoreleasePool new];

        // Are we already in a state?
        if ((currentRange.location>0) && 
            (stateName = [aString attribute:kSyntaxHighlightingStateName atIndex:currentRange.location-1 effectiveRange:nil]) && 
            (!([[aString attribute:kSyntaxHighlightingStateDelimiterName atIndex:currentRange.location-1 effectiveRange:nil] isEqualTo:@"End"]))) {
            stateNumber = [stateName intValue];
            if ((foundState = [[definition states] objectAtIndex:stateNumber])) {
            // Search for the end
                    @try{
                    if ((stateEnd = [foundState objectForKey:@"EndsWithRegex"])) {    
                        NSRange endRange;
                        NSRange stateRange;
                        //NSLog(@"Trying to search '%@' in '%@'",stateEnd, [theString substringWithRange:currentRange]);
                        if ((endMatch = [stateEnd matchInString:theString range:currentRange])) { // Search for end of state
                            endRange = [endMatch rangeOfMatchedString];
                            [aString addAttribute:kSyntaxHighlightingStateDelimiterName value:@"End" range:endRange];
                            stateRange = NSMakeRange(currentRange.location, NSMaxRange(endRange) - currentRange.location);
                            //DEBUGLOG(@"SyntaxHighlighterDomain", AllLogLevel, @"Found State End: %@ at %d",[foundState objectForKey:@"id"], endRange.location);
                        } else {  // No end found in chunk, so mark the whole chunk
                            //DEBUGLOG(@"SyntaxHighlighterDomain", AllLogLevel, @"State %@ does not end in chunk",[foundState objectForKey:@"id"]);
                            stateRange = NSMakeRange(currentRange.location, NSMaxRange(aRange) - currentRange.location);
                        }
                        
                        NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                                    [foundState objectForKey:@"color"], NSForegroundColorAttributeName,
                                                    [theDocument fontWithTrait:[[foundState objectForKey:@"font-trait"] unsignedIntValue]], NSFontAttributeName,
                                                    [NSNumber numberWithInt:stateNumber],kSyntaxHighlightingStateName,
                                                    nil];
                                                    
                        [aString addAttributes:attributes range:stateRange];
                        [self highlightRegularExpressionsOfAttributedString:aString inRange:stateRange forState:stateNumber];
                        [self highlightPlainStringsOfAttributedString:aString inRange:stateRange forState:stateNumber];
                        currentRange.location = NSMaxRange(stateRange);
                        currentRange.length = currentRange.length - stateRange.length;
                    } else {
                        NSLog(@"ERROR: Missing EndsWithRegex tag.");
                    }
                    } @catch ( NSException *e ) {NSLog(@"Exception %@  in '%@', string '%@'",[e description], stateEnd, [theString substringWithRange:aRange]); break;}
                }  else {
                    NSLog(@"ERROR: Can't lookup state. This is very fishy.");
                }
        } else { // Currently not in a state -> Search next.
            NSRange defaultStateRange = currentRange;
            if ((startMatch = [stateStarts matchInString:theString range:currentRange])) { // Found new state
                NSRange startRange = [startMatch rangeOfMatchedString];
                defaultStateRange.length = startRange.location - currentRange.location;
                stateNumber = [startMatch indexOfFirstMatchedSubstring] - 1;
                foundState = [[definition states] objectAtIndex:stateNumber];
                NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                            [foundState objectForKey:@"color"], NSForegroundColorAttributeName,                                                    
                                            [theDocument fontWithTrait:[[foundState objectForKey:@"font-trait"] unsignedIntValue]], NSFontAttributeName,
                                            [NSNumber numberWithInt:stateNumber],kSyntaxHighlightingStateName,
                                            @"Start",kSyntaxHighlightingStateDelimiterName,
                                            nil];
                [aString addAttributes:attributes range:startRange];
                currentRange.length = currentRange.length - (NSMaxRange(startRange) - currentRange.location);
                currentRange.location = NSMaxRange(startRange);
            } else { //No state left in chunk 
                currentRange.location = NSMaxRange(currentRange);
                currentRange.length = 0;
            }
            // Color defaultState
            NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [defaultState objectForKey:@"color"], NSForegroundColorAttributeName,
                                        [theDocument fontWithTrait:[[defaultState objectForKey:@"font-trait"] unsignedIntValue]], NSFontAttributeName,
                                        nil];
            [aString addAttributes:attributes range:defaultStateRange];
            [self highlightRegularExpressionsOfAttributedString:aString inRange:defaultStateRange forState:-1];
            [self highlightPlainStringsOfAttributedString:aString inRange:defaultStateRange forState:-1];
        }
        [syntaxPool release];
    } while (currentRange.length>0);
    [aString addAttribute:kSyntaxHighlightingIsCorrectAttributeName value:kSyntaxHighlightingIsCorrectAttributeValue range:aRange];
}

-(void)highlightPlainStringsOfAttributedString:(NSMutableAttributedString*)aString inRange:(NSRange)aRange forState:(int)aState
{
    int state = aState + 1; // Default state has index 0 in lookup table, so call with -1 to get it
    NSDictionary *style;
    SyntaxDefinition *definition = [self syntaxDefinition];

    NSScanner *scanner = [NSScanner scannerWithString:[aString string]];
    [scanner setCharactersToBeSkipped:[definition invertedTokenSet]];
    [scanner setScanLocation:aRange.location];
    do {
        NSString *token = nil;
        if ([scanner scanCharactersFromSet:[definition tokenSet] intoString:&token]) {
            if (token) {
                //DEBUGLOG(@"SyntaxHighlighterDomain", AllLogLevel, @"Found Token: %@ in State %d",token, aState);
                if ((style = [definition styleForToken:token inState:state])) {
                    NSRange foundRange = NSMakeRange([scanner scanLocation]-[token length],[token length]);
                    if (NSMaxRange(foundRange)>NSMaxRange(aRange)) break;
                    [aString addAttribute:NSForegroundColorAttributeName value:[style objectForKey:@"color"] range:foundRange];
                    NSFontTraitMask mask = [[style objectForKey:@"font-trait"] unsignedIntValue];
                    [aString addAttribute:NSFontAttributeName value:[theDocument fontWithTrait:mask] range:foundRange];
                }
            }
        } else break;
    } while ([scanner scanLocation]< NSMaxRange(aRange));
}

-(void)highlightRegularExpressionsOfAttributedString:(NSMutableAttributedString*)aString inRange:(NSRange)aRange forState:(int)aState
{
    int state = aState + 1; // Default state has index 0 in lookup table, so call with -1 to get it
    SyntaxDefinition *definition = [self syntaxDefinition];
    NSDictionary *regexDict = [definition regularExpressionsInState:state];
    OGRegularExpression *aRegex;
    OGRegularExpressionMatch *aMatch;
    NSDictionary *style;
    
    if (regexDict) {
        NSEnumerator *regexEnumerator = [regexDict keyEnumerator];
        while ((aRegex = [regexEnumerator nextObject])) {
            style = [regexDict objectForKey:aRegex];
            NSEnumerator *matchEnumerator = [[aRegex allMatchesInString:[aString string] range:aRange] objectEnumerator];
            while ((aMatch = [matchEnumerator nextObject])) {
                [aString addAttribute:NSForegroundColorAttributeName value:[style objectForKey:@"color"] range:[aMatch rangeOfMatchedString]];
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
    [I_syntaxDefinition autorelease];
     I_syntaxDefinition = [aSyntaxDefinition retain];
}


#pragma mark - 
#pragma mark - Document Interaction
#pragma mark - 

/*"Colorizes at least one chunk of the TextStorage, returns NO if there is still work to do"*/
- (BOOL)colorizeDirtyRanges:(NSTextStorage *)aTextStorage ofDocument:(id)sender
{
    // just to show when there is colorization
    NSRange textRange=NSMakeRange(0,[aTextStorage length]);
    NSRange dirtyRange;
    id correct;
    BOOL returnValue = NO;
    
    theDocument = sender;
    [aTextStorage beginEditing];
    
    unsigned int position;
    position=0;
    while (position<NSMaxRange(textRange)) {
        correct=[aTextStorage attribute:kSyntaxHighlightingIsCorrectAttributeName atIndex:position longestEffectiveRange:&dirtyRange inRange:textRange];
        if (!correct) {
            [self highlightAttributedString:aTextStorage inRange:dirtyRange];
            position=NSMaxRange(dirtyRange);
        } else {
            position=NSMaxRange(dirtyRange);
            if (position>=[aTextStorage length]) {
                returnValue = YES;
                break;
            }
        }
        // adjust Range
        textRange.length=NSMaxRange(textRange);
        textRange.location=position;
        textRange.length  =textRange.length-position;
    }
    
    [aTextStorage endEditing];
    
    return YES;
}

/*"Cleans up any attribute it introduced to the textstorage while colorizing it"*/
- (void)cleanUpTextStorage:(NSTextStorage *)aTextStorage 
{
    [self cleanUpTextStorage:aTextStorage inRange:NSMakeRange(0,[aTextStorage length])];
}

- (void)cleanUpTextStorage:(NSTextStorage *)aTextStorage inRange:(NSRange)aRange
{
    [aTextStorage beginEditing];
    [aTextStorage removeAttribute:kSyntaxHighlightingIsCorrectAttributeName range:aRange];
    [aTextStorage removeAttribute:kSyntaxHighlightingStateName range:aRange];
    [aTextStorage removeAttribute:kSyntaxHighlightingStateDelimiterName range:aRange];
    [aTextStorage endEditing];
}


@end
