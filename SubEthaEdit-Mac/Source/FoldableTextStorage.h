//
//  FoldableTextStorage.h
//  TextEdit
//
//  Created by Dominik Wagner on 04.01.09.
//  Copyright 2009 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <OgreKit/OgreKit.h>
#import "NSMutableAttributedStringSEEAdditions.h"

#import "FoldedTextAttachment.h"
#import "AbstractFoldingTextStorage.h"
@class FoldableTextStorage;

#import "FullTextStorage.h"

@protocol FoldableTextStorageDelegate;
@protocol TextStorageBlockeditDelegate;

extern NSString * const TextStorageLineEndingDidChange;
extern NSString * const TextStorageHasMixedLineEndingsDidChange;


extern NSString * const BlockeditAttributeName ;
extern NSString * const BlockeditAttributeValue;

@interface FoldableTextStorage : AbstractFoldingTextStorage {
	FullTextStorage *I_fullTextStorage;
	NSMutableArray *I_sortedFoldedTextAttachments;
	int I_editingCount;

    struct {
        BOOL hasBlockeditRanges;
        BOOL  isBlockediting;
        BOOL didBlockedit;
        NSRange didBlockeditRange;
        NSRange didBlockeditLineRange;
    } I_blockedit;

    NSMutableAttributedString *I_internalAttributedString;

    struct {
        int length;
        int characterOffset;
        int startLine;
        int endLine;
    } I_scriptingProperties;
    
}

- (NSRange)foldedRangeForFullRange:(NSRange)inRange;
- (NSRange)foldedRangeForFullRange:(NSRange)inRange expandIfFolded:(BOOL)aFlag;
- (NSRange)fullRangeForFoldedRange:(NSRange)inRange;
- (FullTextStorage *)fullTextStorage;

- (void)fullTextDidReplaceCharactersInRange:(NSRange)inRange withString:(NSString *)inString;
- (void)fullTextDidSetAttributes:(NSDictionary *)inAttributes range:(NSRange)inRange;

#pragma mark folding methods
- (int)numberOfTopLevelFoldings;
- (void)foldRange:(NSRange)inRange;
- (void)unfoldAttachment:(FoldedTextAttachment *)inAttachment atCharacterIndex:(unsigned)inIndex;
- (void)unfoldAll;
// returns YES if a folding was unfolded, NO otherwise
- (BOOL)unfoldFoldingForPosition:(unsigned)aPosition;
- (void)foldAllWithFoldingLevel:(int)aFoldingLevel;
- (void)foldAllComments;
- (NSRange)foldableCommentRangeForCharacterAtIndex:(unsigned long int)anIndex;

- (int)foldingDepthForLine:(int)aLineNumber;
- (NSRange)foldingRangeForLine:(int)aLineNumber;

- (void)foldAccordingToDataRepresentation:(NSData *)aData;
- (NSData *)dataRepresentationOfFoldedRangesWithMaxDepth:(int)aMaxDepth;


#pragma mark line numbers
- (int)lineNumberForLocation:(unsigned)location;
- (NSString *)positionStringForRange:(NSRange)aRange;
- (NSRange)findLine:(int)aLineNumber;

#pragma mark Blockedit
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

- (void)stopBlockedit;


#pragma mark debug output
- (NSMutableAttributedString *)attributedStringOfFolding:(FoldedTextAttachment *)inAttachment;
- (NSString *)foldedStringRepresentationOfRange:(NSRange)inRange foldings:(NSArray *)inFoldings level:(int)inLevel;
- (NSString *)foldedStringRepresentation;

- (LineEnding)lineEnding;
- (void)setLineEnding:(LineEnding)newLineEnding;
- (void)setShouldWatchLineEndings:(BOOL)aFlag;
- (BOOL)hasMixedLineEndings;
- (void)setHasMixedLineEndings:(BOOL)aFlag;
- (NSStringEncoding)encoding;
- (void)setEncoding:(NSStringEncoding)anEncoding;
- (NSArray *)selectionOperationsForRangesUnconvertableToEncoding:(NSStringEncoding)encoding;


@end

@protocol FoldableTextStorageDelegate
- (void)textStorageDidChangeNumberOfTopLevelFoldings:(FoldableTextStorage *)aTextStorage;
@end

@protocol TextStorageBlockeditDelegate
- (NSDictionary *)blockeditAttributesForTextStorage:(FoldableTextStorage *)aTextStorage;
- (void)textStorageDidStopBlockedit:(FoldableTextStorage *)aTextStorage;
- (void)textStorageDidStartBlockedit:(FoldableTextStorage *)aTextStorage;
@end

@interface FoldableTextStorage (FoldableTextStorageDelegateAdditions)
- (void)textStorage:(FullTextStorage *)aTextStorage willReplaceCharactersInRange:(NSRange)aRange withString:(NSString *)aString;
- (void)textStorage:(FullTextStorage *)aTextStorage didReplaceCharactersInRange:(NSRange)aRange withString:(NSString *)aString;
@end


#pragma mark -

@interface FoldableTextStorage (TextStorageScriptingAdditions)


- (NSRange)rangeRepresentation;
- (NSNumber *)scriptedLength;
- (NSNumber *)scriptedStartCharacterIndex;
- (NSNumber *)scriptedNextCharacterIndex;
- (NSNumber *)scriptedStartLine;
- (NSNumber *)scriptedEndLine;
- (NSString *)scriptedContents;
- (void)setScriptedContents:(id)string;

// all done by key value coding for performance reasons
//- (id)insertionPoints;
//- (NSArray *)scriptedCharacters;
//- (NSArray *)scriptedLines;

@end

//#endif
