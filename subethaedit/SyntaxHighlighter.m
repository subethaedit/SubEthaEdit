//
//  SyntaxHighlighter.m
//  SyntaxTestBench
//
//  Created by Martin Pittenauer on Thu Mar 04 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "SyntaxHighlighter.h"
#import "time.h"
#import <OgreKit/OgreKit.h>

#define chunkSize              		5000

NSString * const kSyntaxHighlightingIsDirtyAttributeName =@"HighlightingIsDirtyName";
NSString * const kSyntaxHighlightingIsDirtyAttributeValue=@"Dirty";


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

-(BOOL)highlightDirtyRangesOfAttributedString:(NSMutableAttributedString*)aString 
{
    return YES;
}

- (void)stateMachineOnAttributedString:(NSMutableAttributedString *)aString inRange:(NSRange)aRange 
{
}

-(void)highlightPlainStringsOfAttributedString:(NSMutableAttributedString*)aString inRange:(NSRange)aRange
{
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
     I_syntaxDefinition = [aSyntaxDefinition copy];
}


#pragma mark - 
#pragma mark - Document Interaction
#pragma mark - 
/*"Colorizes at least one chunk of the TextStorage, returns NO if there is still work to do"*/
- (BOOL)colorizeDirtyRanges:(NSTextStorage *)aTextStorage {
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
            [aTextStorage addAttribute:NSForegroundColorAttributeName value:[NSColor redColor] range:dirtyRange];
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
- (void)cleanUpTextStorage:(NSTextStorage *)aTextStorage {

}


@end
