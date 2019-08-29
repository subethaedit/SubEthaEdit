//  ScriptTextBase.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 03.05.06.

#import "ScriptTextBase.h"
#import "ScriptLine.h"
#import "ScriptCharacters.h"
#import "ScriptTextSelection.h"
#import "FoldableTextStorage.h"
#import "PlainTextDocument.h"

@implementation ScriptTextBase 

- (instancetype)initWithTextStorage:(FullTextStorage *)aTextStorage {
    if ((self=[super init])) {
        I_textStorage = aTextStorage;
    }
    return self;
}

- (NSRange)rangeRepresentation {
    return NSMakeRange(0,NSNotFound);
}

- (int)scriptedLength {
    return [self rangeRepresentation].length;
}

- (int)scriptedStartCharacterIndex {
    return [self rangeRepresentation].location+1;
}

- (int)scriptedNextCharacterIndex {
    return (int)NSMaxRange([self rangeRepresentation])+1;
}

- (int)scriptedStartLine {
    return [I_textStorage lineNumberForLocation:[self rangeRepresentation].location];
}

- (int)scriptedEndLine {
    return [I_textStorage lineNumberForLocation:EndCharacterIndex([self rangeRepresentation])];
}

- (NSArray *)scriptedLines {
    int index    = [self scriptedStartLine];
    int endIndex = [self scriptedEndLine];
    NSMutableArray *result = [NSMutableArray array];
    for (;index<=endIndex;index++) {
        [result addObject:[ScriptLine scriptLineWithTextStorage:I_textStorage lineNumber:index]];
    }
    return result;
}

- (void)insertObject:(id)anObject inScriptedLinesAtIndex:(unsigned)anIndex {
    // has to be there for KVC not to mourn
}

- (void)removeObjectFromScriptedLinesAtIndex:(unsigned)anIndex {
    [[[self scriptedLines] objectAtIndex:anIndex] setScriptedContents:@""];
}

- (NSArray *)words {
    return [[[NSTextStorage alloc] initWithAttributedString:[I_textStorage attributedSubstringFromRange:[self rangeRepresentation]]] words];
}

- (void)setWords:(NSArray *)wordArray {
    NSBeep();
}

- (NSUInteger)countOfScriptedCharacters {
    return [self rangeRepresentation].length;
}

- (id)objectInScriptedCharactersAtIndex:(unsigned)index {
    return [ScriptCharacters scriptCharactersWithTextStorage:I_textStorage characterRange:NSMakeRange(index+[self rangeRepresentation].location,1)];
}

- (void)insertObject:(id)anObject inScriptedCharactersAtIndex:(unsigned)anIndex {
    // has to be there for KVC not to mourn
}

- (void)removeObjectFromScriptedCharactersAtIndex:(unsigned)anIndex {
    [[self objectInScriptedCharactersAtIndex:anIndex] setScriptedContents:@""];
}

- (id)scriptedContents
{
    return [[I_textStorage string] substringWithRange:[self rangeRepresentation]];
}

- (void)setScriptedContents:(id)value {
    [(id)[[I_textStorage foldableTextStorage] delegate] replaceTextInRange:[self rangeRepresentation] withString:value];
}

- (unsigned int)countOfInsertionPoints {
	return [self rangeRepresentation].length+1;
}

- (id)objectInInsertionPointsAtIndex:(unsigned)anIndex {
    return [ScriptTextSelection insertionPointWithTextStorage:I_textStorage index:[self rangeRepresentation].location+anIndex];
}


@end
