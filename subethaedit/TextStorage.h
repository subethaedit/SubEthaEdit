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


extern NSString * const TextStorageLineEndingDidChange;
extern NSString * const TextStorageHasMixedLineEndingsDidChange;

@interface TextStorage : AbstractFoldingTextStorage {
    NSMutableAttributedString *I_internalAttributedString;
    unsigned I_numberOfWords;

    TextStorage *I_containerTextStorage;
    struct {
        int length;
        int characterOffset;
        int startLine;
        int endLine;
    } I_scriptingProperties;
}

#pragma mark -
- (NSString *)positionStringForRange:(NSRange)aRange;
- (int)lineNumberForLocation:(unsigned)location;
- (NSRange)findLine:(int)aLineNumber;
#pragma mark -


- (unsigned)numberOfLines;
- (unsigned)numberOfCharacters;
- (unsigned)numberOfWords;

- (LineEnding)lineEnding;
- (void)setLineEnding:(LineEnding)newLineEnding;
- (void)setShouldWatchLineEndings:(BOOL)aFlag;
- (BOOL)hasMixedLineEndings;
- (void)setHasMixedLineEndings:(BOOL)aFlag;
- (unsigned int)encoding;
- (void)setEncoding:(unsigned int)anEncoding;
- (NSArray *)selectionOperationsForRangesUnconvertableToEncoding:(NSStringEncoding)encoding;


- (NSDictionary *)dictionaryRepresentation;
- (void)setContentByDictionaryRepresentation:(NSDictionary *)aRepresentation;

- (NSMutableAttributedString *)attributedStringForXHTMLExportWithRange:(NSRange)aRange foregroundColor:(NSColor *)aForegroundColor backgroundColor:(NSColor *)aBackgroundColor;

@end

#pragma mark -

@interface TextStorage (TextStorageDelegateAdditions)
- (void)textStorage:(TextStorage *)aTextStorage willReplaceCharactersInRange:(NSRange)aRange withString:(NSString *)aString;
- (void)textStorage:(TextStorage *)aTextStorage didReplaceCharactersInRange:(NSRange)aRange withString:(NSString *)aString;

@end