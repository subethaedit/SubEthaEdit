//
//  SyntaxHighlighter.m
//  SyntaxTestBench
//
//  Created by Martin Pittenauer on Thu Mar 04 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//
// blabla 

#import "SyntaxHighlighter.h"
#import "time.h"
#import <OgreKit/OgreKit.h>

#define chunkSize              		5000

NSString * const kSyntaxHighlightingIsDirtyAttributeName  = @"HighlightingIsDirtyName";
NSString * const kSyntaxHighlightingIsDirtyAttributeValue = @"Dirty";
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

/*- (id)init 
{
    SyntaxDefinition *foo = [[SyntaxDefinition alloc] initWithFile:@"/Users/pittenau/Desktop/syntax.xml"];

    self=[super init];
    if (self) {
        [self setSyntaxDefinition:foo];
    }
    DEBUGLOG(@"SyntaxHighlighterDomain", AllLogLevel, @"Initiated new SyntaxHighlighter:%@",[self description]);
    return self;
}*/


#pragma mark - 
#pragma mark - Highlighting
#pragma mark - 

-(void)highlightAttributedString:(NSMutableAttributedString*)aString inRange:(NSRange)aRange
{
    //[aString addAttribute:NSForegroundColorAttributeName value:[NSColor redColor] range:aRange];
    [self stateMachineOnAttributedString:aString inRange:aRange];
}

-(void)stateMachineOnAttributedString:(NSMutableAttributedString *)aString inRange:(NSRange)aRange 
{
    SyntaxDefinition *definition = [self syntaxDefinition];
    if (!definition) NSLog(@"ERROR: No defintion for highlighter.");
    
    NSString *theString = [aString string];
    aRange = [theString lineRangeForRange:aRange];
    
    int lastEnd = aRange.location;
    NSRange currentRange = aRange;
    
    OGRegularExpression *stateStarts = [definition combinedStateRegex];
    OGRegularExpression *stateEnd;
    OGRegularExpressionMatch *startMatch;
    OGRegularExpressionMatch *endMatch;
    if (stateStarts) do {
        startMatch = [stateStarts matchInString:theString range:currentRange];
        if (startMatch) {
            //DEBUGLOG(@"SyntaxHighlighterDomain", AllLogLevel, @"Old Range: %@",NSStringFromRange(currentRange));            
            NSRange matchRange = [startMatch rangeOfMatchedString];
            [aString addAttribute:kSyntaxHighlightingStateDelimiterName value:@"Start" range:matchRange];  
            
            //FIXME: Wrong place to color defaultState
            if (matchRange.location>aRange.location)
                if (!([aString attribute:kSyntaxHighlightingStateName atIndex:matchRange.location-1 effectiveRange:nil])) {
                    NSRange defaultStateRange = NSMakeRange(lastEnd + 1, matchRange.location - lastEnd);
                    [self highlightPlainStringsOfAttributedString:aString inRange:defaultStateRange forState:-1];
                }
            
            //FIXME: Empty states are not recognized     
            int stateNumber = [startMatch indexOfFirstMatchedSubstring] - 1;
            NSDictionary *foundState = [[definition states] objectAtIndex:stateNumber];
            if (foundState) {
                //DEBUGLOG(@"SyntaxHighlighterDomain", AllLogLevel, @"Found State: %@ at %d",[foundState objectForKey:@"id"], matchRange.location);
                
                if (stateEnd = [foundState objectForKey:@"EndsWithRegex"]) {
                    currentRange.length -= NSMaxRange(matchRange) - currentRange.location;
                    currentRange.location = NSMaxRange(matchRange);
                    NSRange secondMatchRange;
                    NSRange stateRange;
                    if (endMatch = [stateEnd matchInString:theString range:currentRange]) { // Search for end of state
                        secondMatchRange = [endMatch rangeOfMatchedString];
                        [aString addAttribute:kSyntaxHighlightingStateDelimiterName value:@"End" range:secondMatchRange];
                        stateRange = NSMakeRange(matchRange.location, NSMaxRange(secondMatchRange) - matchRange.location);
                    } else {  // No end found in chunk, so mark the whole chunk
                        DEBUGLOG(@"SyntaxHighlighterDomain", AllLogLevel, @"State %@ does not end in chunk",[foundState objectForKey:@"id"]);
                        stateRange = NSMakeRange(matchRange.location, NSMaxRange(aRange) - matchRange.location);
                    }
                    
                    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                                [foundState objectForKey:@"color"], NSForegroundColorAttributeName,
                                                [NSNumber numberWithInt:stateNumber],kSyntaxHighlightingStateName,
                                                nil];
                                                
                    [aString addAttributes:attributes range:stateRange];
                    [self highlightPlainStringsOfAttributedString:aString inRange:stateRange forState:stateNumber];
                    lastEnd = NSMaxRange(stateRange);
                }
            } else {
                NSLog(@"ERROR: Can't lookup state or missing EndsWithRegex attribute.");
            }
            
            currentRange.length -= lastEnd - currentRange.location;
            currentRange.location = lastEnd;
            //DEBUGLOG(@"SyntaxHighlighterDomain", AllLogLevel, @"New Range: %@",NSStringFromRange(currentRange));
        }
    } while (startMatch);
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
                if (style = [definition styleForToken:token inState:state]) {
                    NSRange foundRange = NSMakeRange([scanner scanLocation]-[token length],[token length]);
                    if (NSMaxRange(foundRange)>NSMaxRange(aRange)) break;
                    [aString addAttribute:NSForegroundColorAttributeName value:[style objectForKey:@"color"] range:foundRange];
                }
            }
        } else break;
    } while ([scanner scanLocation]< NSMaxRange(aRange));
}

-(void)highlightRegularExpressionsOfAttributedString:(NSMutableAttributedString*)aString inRange:(NSRange)aRange
{

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
- (BOOL)colorizeDirtyRanges:(NSTextStorage *)aTextStorage 
{
    // just to show when there is colorization
    NSRange textRange=NSMakeRange(0,[aTextStorage length]);
    NSRange dirtyRange;
    id dirty;
    BOOL returnValue = NO;
    
    [aTextStorage beginEditing];
    
    unsigned int position;
    position=0;
    while (position<NSMaxRange(textRange)) {
        dirty=[aTextStorage attribute:kSyntaxHighlightingIsDirtyAttributeName atIndex:position
                longestEffectiveRange:&dirtyRange inRange:textRange];
        if (dirty) {
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

}


@end
