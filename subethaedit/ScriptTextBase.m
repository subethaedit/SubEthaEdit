//
//  ScriptTextBase.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 03.05.06.
//  Copyright 2006 TheCodingMonkeys. All rights reserved.
//

#import "ScriptTextBase.h"
#import "ScriptLine.h"
#import "ScriptCharacters.h"
#import "TextStorage.h"
#import "PlainTextDocument.h"


@implementation ScriptTextBase

- (id)initWithTextStorage:(TextStorage *)aTextStorage {
    if ((self=[super init])) {
        I_textStorage = [aTextStorage retain];
    }
    return self;
}

- (void)dealloc {
    [I_textStorage release];
    [super dealloc];
}

- (NSRange)rangeRepresentation {
    return NSMakeRange(0,NSNotFound);
}

- (NSNumber *)scriptedLength {
    return [NSNumber numberWithInt:[self rangeRepresentation].length];
}

- (NSNumber *)scriptedStartCharacterIndex {
    return [NSNumber numberWithInt:[self rangeRepresentation].location +1];
}

- (NSNumber *)scriptedNextCharacterIndex {
    return [NSNumber numberWithInt:((int)NSMaxRange([self rangeRepresentation]))+1];
}

- (NSNumber *)scriptedStartLine {
    return [NSNumber numberWithInt:[I_textStorage lineNumberForLocation:[self rangeRepresentation].location]];
}

- (NSNumber *)scriptedEndLine {
    return [NSNumber numberWithInt:[I_textStorage lineNumberForLocation:EndCharacterIndex([self rangeRepresentation])]];
}

- (NSArray *)scriptedLines {
    int index    = [[self scriptedStartLine] intValue];
    int endIndex = [[self scriptedEndLine] intValue];
    NSMutableArray *result = [NSMutableArray array];
    for (;index<=endIndex;index++) {
        [result addObject:[ScriptLine scriptLineWithTextStorage:I_textStorage lineNumber:index]];
    }
    return result;
}

- (NSArray *)words {
    return [[[[NSTextStorage alloc] initWithAttributedString:[I_textStorage attributedSubstringFromRange:[self rangeRepresentation]]] autorelease] words];
}

- (void)setWords:(NSArray *)wordArray {
    NSBeep();
}

- (id)scriptedCharacters {
    NSLog(@"%s", __FUNCTION__);
    NSMutableArray *result=[NSMutableArray array];
    NSRange range=[self rangeRepresentation];
    int nextIndex=NSMaxRange(range);
    int index=range.location;
    while (index<nextIndex) {
        [result addObject:[ScriptCharacters scriptCharactersWithTextStorage:I_textStorage characterRange:NSMakeRange(index++,1)]];
    }
    return result;
}

- (unsigned int)countOfScriptedCharacters {
    return [self rangeRepresentation].length;
}

- (id)valueInScriptedCharactersAtIndex:(unsigned)index {
    NSLog(@"%s: %d", __FUNCTION__, index);
    return [ScriptCharacters scriptCharactersWithTextStorage:I_textStorage characterRange:NSMakeRange(index+[[self scriptedStartCharacterIndex] intValue],1)];
}

- (id)scriptedContents
{
    return [[I_textStorage string] substringWithRange:[self rangeRepresentation]];
}

- (void)setScriptedContents:(id)value {
    NSLog(@"%s: %@", __FUNCTION__, value);
    [[I_textStorage delegate] replaceTextInRange:[self rangeRepresentation] withString:value];
}

@end
