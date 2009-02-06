//
//  TextStorage.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Thu Mar 25 2004.
//  Copyright (c) 2004-2006 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <OgreKit/OgreKit.h>
#import "NSMutableAttributedStringSEEAdditions.h"
#import "AbstractFoldingTextStorage.h"

extern NSString * const BlockeditAttributeName ;
extern NSString * const BlockeditAttributeValue;

extern NSString * const TextStorageLineEndingDidChange;
extern NSString * const TextStorageHasMixedLineEndingsDidChange;

@interface TextStorage : AbstractFoldingTextStorage {
    NSMutableAttributedString *I_internalAttributedString;
    unsigned I_numberOfWords;

    struct {
        BOOL hasBlockeditRanges;
        BOOL  isBlockediting;
        BOOL didBlockedit;
        NSRange didBlockeditRange;
        NSRange didBlockeditLineRange;
    } I_blockedit;
    
    TextStorage *I_containerTextStorage;
    struct {
        int length;
        int characterOffset;
        int startLine;
        int endLine;
    } I_scriptingProperties;
}

+ (OGRegularExpression *)wrongLineEndingRegex:(LineEnding)aLineEnding;

#pragma mark -
- (NSString *)positionStringForRange:(NSRange)aRange;
- (int)lineNumberForLocation:(unsigned)location;
- (NSRange)findLine:(int)aLineNumber;
#pragma mark -


- (unsigned)numberOfLines;
- (unsigned)numberOfCharacters;
- (unsigned)numberOfWords;

- (BOOL)lastLineIsEmpty;

- (LineEnding)lineEnding;
- (void)setLineEnding:(LineEnding)newLineEnding;
- (void)setShouldWatchLineEndings:(BOOL)aFlag;
- (BOOL)hasMixedLineEndings;
- (void)setHasMixedLineEndings:(BOOL)aFlag;
- (unsigned int)encoding;
- (void)setEncoding:(unsigned int)anEncoding;
- (NSArray *)selectionOperationsForRangesUnconvertableToEncoding:(NSStringEncoding)encoding;

- (BOOL)hasBlockeditRanges;
- (void)setHasBlockeditRanges:(BOOL)aFlag;
- (BOOL)isBlockediting;
- (void)setIsBlockediting:(BOOL)aFlag;
- (BOOL)didBlockedit;
- (void)setDidBlockedit:(BOOL)aFlag;
- (NSRange)didBlockeditRange;
- (void)setDidBlockeditRange:(NSRange)aRange;
- (NSRange)didBlockeditLineRange;
- (void)setDidBlockeditLineRange:(NSRange)aRange;

- (NSRange)blockChangeTextInRange:(NSRange)aRange replacementString:(NSString *)aReplacementString
                   paragraphRange:(NSRange)aParagraphRange inTextView:(NSTextView *)aTextView tabWidth:(unsigned)aTabWidth useTabs:(BOOL)aUseTabs;

- (void)stopBlockedit;

- (NSDictionary *)dictionaryRepresentation;
- (void)setContentByDictionaryRepresentation:(NSDictionary *)aRepresentation;

- (NSMutableAttributedString *)attributedStringForXHTMLExportWithRange:(NSRange)aRange foregroundColor:(NSColor *)aForegroundColor backgroundColor:(NSColor *)aBackgroundColor;

- (void)removeAttributes:(id)anObjectEnumerable range:(NSRange)aRange;

- (NSDictionary *)attributeDictionaryByAddingStyleAttributesForInsertLocation:(unsigned int)inLocation toDictionary:(NSDictionary *)inBaseStyle;

@end

#pragma mark -

@interface TextStorage (TextStorageScriptingAdditions)

- (id)insertionPoints;

- (NSRange)rangeRepresentation;
- (NSNumber *)scriptedLength;
- (NSNumber *)scriptedStartCharacterIndex;
- (NSNumber *)scriptedNextCharacterIndex;
- (NSNumber *)scriptedStartLine;
- (NSNumber *)scriptedEndLine;
- (NSString *)scriptedContents;
- (void)setScriptedContents:(id)string;
- (NSArray *)scriptedCharacters;
- (NSArray *)scriptedLines;

@end

#pragma mark -

@interface NSObject (TextStorageDelegateAdditions)

- (NSDictionary *)blockeditAttributesForTextStorage:(TextStorage *)aTextStorage;
- (void)textStorageDidStopBlockedit:(TextStorage *)aTextStorage;
- (void)textStorageDidStartBlockedit:(TextStorage *)aTextStorage;
- (void)textStorage:(TextStorage *)aTextStorage willReplaceCharactersInRange:(NSRange)aRange withString:(NSString *)aString;
- (void)textStorage:(TextStorage *)aTextStorage didReplaceCharactersInRange:(NSRange)aRange withString:(NSString *)aString;

@end