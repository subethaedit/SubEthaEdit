//
//  FoldableTextStorage.h
//  TextEdit
//
//  Created by Dominik Wagner on 04.01.09.
//  Copyright 2009 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "FoldedTextAttachment.h"
#import "AbstractFoldingTextStorage.h"
#import "TextStorage.h"

@class FullTextStorage, TextStorage;

extern NSString * const BlockeditAttributeName ;
extern NSString * const BlockeditAttributeValue;

@interface FoldableTextStorage : TextStorage {
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
    
}

- (NSRange)foldedRangeForFullRange:(NSRange)inRange;
- (NSRange)fullRangeForFoldedRange:(NSRange)inRange;
- (FullTextStorage *)fullTextStorage;

- (void)fullTextDidReplaceCharactersInRange:(NSRange)inRange withString:(NSString *)inString;
- (void)fullTextDidSetAttributes:(NSDictionary *)inAttributes range:(NSRange)inRange;

#pragma mark folding methods
- (void)foldRange:(NSRange)inRange;
- (void)unfoldAttachment:(FoldedTextAttachment *)inAttachment atCharacterIndex:(unsigned)inIndex;

#pragma mark line numbers
- (int)lineNumberForLocation:(unsigned)location;
- (NSString *)positionStringForRange:(NSRange)aRange;
- (NSRange)findLine:(int)aLineNumber;
- (void)setHasMixedLineEndings:(BOOL)aFlag;

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

@end

@interface NSObject (TextStorageBlockeditDelegateAdditions)

- (NSDictionary *)blockeditAttributesForTextStorage:(TextStorage *)aTextStorage;
- (void)textStorageDidStopBlockedit:(TextStorage *)aTextStorage;
- (void)textStorageDidStartBlockedit:(TextStorage *)aTextStorage;

@end

