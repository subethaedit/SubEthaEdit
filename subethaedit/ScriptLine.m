//
//  ScriptLine.m
//  SubEthaEdit
//
//  Created by Martin Ott on 5/2/06.
//  Copyright 2006 TheCodingMonkeys. All rights reserved.
//

#import "ScriptLine.h"
#import "TextStorage.h"
#import "PlainTextDocument.h"

@implementation ScriptLine

+ (id)scriptLineWithTextStorage:(TextStorage *)aTextStorage lineNumber:(int)aLineNumber {
    return [[[ScriptLine alloc] initWithTextStorage:aTextStorage lineNumber:aLineNumber] autorelease];
}

- (id)initWithTextStorage:(TextStorage *)aTextStorage lineNumber:(int)aLineNumber
{
    if ((self = [super init])) {
        I_textStorage = [aTextStorage retain];
        I_lineNumber = aLineNumber;
    }
    return self;
}

- (void)dealloc
{
    [I_textStorage release];
    [super dealloc];
}

- (NSNumber *)scriptedLength
{
    return [NSNumber numberWithInt:[self lineRangeWithoutLineFeed].length];
}

- (NSNumber *)scriptedCharacterOffset
{
    return [NSNumber numberWithInt:[self lineRangeWithoutLineFeed].location];
}

- (NSNumber *)scriptedStartLine
{
    return [NSNumber numberWithInt:I_lineNumber];
}

- (NSNumber *)scriptedEndLine
{
    return [NSNumber numberWithInt:I_lineNumber];
}

- (NSRange)lineRangeWithoutLineFeed
{
    unsigned startIndex;
    unsigned lineEndIndex;
    unsigned contentsEndIndex;
    [[I_textStorage string] getLineStart:&startIndex end:&lineEndIndex contentsEnd:&contentsEndIndex forRange:[I_textStorage findLine:I_lineNumber]];
    return NSMakeRange(startIndex, contentsEndIndex - startIndex);
}

- (NSString *)text
{
    return [[I_textStorage string] substringWithRange:[self lineRangeWithoutLineFeed]];
}

- (void)setText:(id)value {
    NSLog(@"%s: %d", __FUNCTION__, value);
    [[I_textStorage delegate] replaceTextInRange:[self lineRangeWithoutLineFeed] withString:value];
}

- (id)objectSpecifier
{
    NSLog(@"%s", __FUNCTION__);
    
    NSScriptClassDescription *containerClassDesc = (NSScriptClassDescription *)[NSScriptClassDescription classDescriptionForClass:[TextStorage class]];
    NSScriptObjectSpecifier *containerSpecifier = [I_textStorage objectSpecifier];

    NSIndexSpecifier *indexSpecifier = 
        [[[NSIndexSpecifier alloc] initWithContainerClassDescription:containerClassDesc
                                                  containerSpecifier:containerSpecifier
                                                                 key:@"lines"
                                                               index:I_lineNumber-1] autorelease];
                                                               
    return indexSpecifier;
}

@end
