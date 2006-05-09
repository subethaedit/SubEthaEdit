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
    if ((self = [super initWithTextStorage:aTextStorage])) {
        I_lineNumber = aLineNumber;
    }
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (NSRange)rangeRepresentation
{
    unsigned startIndex;
    unsigned lineEndIndex;
    unsigned contentsEndIndex;
    [[I_textStorage string] getLineStart:&startIndex end:&lineEndIndex contentsEnd:&contentsEndIndex forRange:[I_textStorage findLine:I_lineNumber]];
    return NSMakeRange(startIndex, lineEndIndex - startIndex);
}

- (NSRange)innerRangeRepresentation
{
    unsigned startIndex;
    unsigned lineEndIndex;
    unsigned contentsEndIndex;
    [[I_textStorage string] getLineStart:&startIndex end:&lineEndIndex contentsEnd:&contentsEndIndex forRange:[I_textStorage findLine:I_lineNumber]];
    return NSMakeRange(startIndex, contentsEndIndex - startIndex);
}

- (id)objectSpecifier
{
    NSLog(@"%s", __FUNCTION__);
    
    NSScriptClassDescription *containerClassDesc = (NSScriptClassDescription *)[NSScriptClassDescription classDescriptionForClass:[TextStorage class]];
    NSScriptObjectSpecifier *containerSpecifier = [I_textStorage objectSpecifier];

    NSIndexSpecifier *indexSpecifier = 
        [[[NSIndexSpecifier alloc] initWithContainerClassDescription:containerClassDesc
                                                  containerSpecifier:containerSpecifier
                                                                 key:@"scriptedLines"
                                                               index:I_lineNumber-1] autorelease];
                                                               
    return indexSpecifier;
}


- (id)scriptedInnerContents
{
    return [[I_textStorage string] substringWithRange:[self innerRangeRepresentation]];
}

- (void)setScriptedInnerContents:(id)value {
    NSLog(@"%s: %@", __FUNCTION__, value);
    [[I_textStorage delegate] replaceTextInRange:[self innerRangeRepresentation] withString:value];
}


@end
