//
//  TextStorage.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Thu Mar 25 2004.
//  Copyright (c) 2004-2006 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <OgreKit/OgreKit.h>

extern NSString * const BlockeditAttributeName ;
extern NSString * const BlockeditAttributeValue;

extern NSString * const TextStorageLineEndingDidChange;
extern NSString * const TextStorageHasMixedLineEndingsDidChange;

@interface TextStorage : NSTextStorage {
    NSMutableArray *I_lineStarts;
    unsigned int I_lineStartsValidUpTo;
    NSMutableAttributedString *I_contents;
    unsigned int I_encoding;
    LineEnding I_lineEnding;

    struct {
        BOOL hasBlockeditRanges;
        BOOL  isBlockediting;
        BOOL didBlockedit;
        NSRange didBlockeditRange;
        NSRange didBlockeditLineRange;
    } I_blockedit;

    struct {
        BOOL hasMixedLineEndings;
        BOOL shouldWatchLineEndings;
    } I_flags;
    
    TextStorage *I_containerTextStorage;
    struct {
        int length;
        int characterOffset;
        int startLine;
        int endLine;
    } I_scriptingProperties;
}

+ (OGRegularExpression *)wrongLineEndingRegex:(LineEnding)aLineEnding;


- (int)lineNumberForLocation:(unsigned)location;
- (BOOL)lastLineIsEmpty;
- (NSString *)positionStringForRange:(NSRange)aRange;
- (NSMutableArray *)lineStarts;
- (NSRange)findLine:(int)aLineNumber;
- (void)setLineStartsOnlyValidUpTo:(unsigned int)aLocation;

- (LineEnding)lineEnding;
- (void)setLineEnding:(LineEnding)newLineEnding;
- (void)setShouldWatchLineEndings:(BOOL)aFlag;
- (BOOL)hasMixedLineEndings;
- (void)setHasMixedLineEndings:(BOOL)aFlag;
- (unsigned int)encoding;
- (void)setEncoding:(unsigned int)anEncoding;

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