//
//  FullTextStorage.h
//  TextEdit
//
//  Created by Dominik Wagner on 04.01.09.
//  Copyright 2009 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AbstractFoldingTextStorage.h"

@class FoldableTextStorage;

@interface FullTextStorage : AbstractFoldingTextStorage {
	NSMutableAttributedString *I_internalAttributedString;
	FoldableTextStorage *I_foldableTextStorage;
	int I_shouldNotSynchronize;
	int I_linearAttributeChangeState;
	NSRange I_unionRangeOfLinearAttributeChanges;
	int I_linearAttributeChangesCount;

    NSMutableArray *I_lineStarts;
    unsigned int I_lineStartsValidUpTo;
    unsigned I_numberOfWords;
    
    unsigned int I_encoding;
    LineEnding I_lineEnding;
	struct {
        BOOL hasMixedLineEndings;
        BOOL shouldWatchLineEndings;
    } I_flags;

}

- (id)initWithFoldableTextStorage:(FoldableTextStorage *)inTextStorage;

#pragma mark -
- (NSString *)positionStringForRange:(NSRange)aRange;
- (int)lineNumberForLocation:(unsigned)location;
- (NSMutableArray *)lineStarts;
- (void)setLineStartsOnlyValidUpTo:(unsigned int)aLocation;
- (NSRange)findLine:(int)aLineNumber;

#pragma mark - line endings and encoding
- (LineEnding)lineEnding;
- (void)setLineEnding:(LineEnding)newLineEnding;
- (void)setShouldWatchLineEndings:(BOOL)aFlag;
- (BOOL)hasMixedLineEndings;
- (void)setHasMixedLineEndings:(BOOL)aFlag;
- (unsigned int)encoding;
- (void)setEncoding:(unsigned int)anEncoding;
- (NSArray *)selectionOperationsForRangesUnconvertableToEncoding:(NSStringEncoding)encoding;

#pragma mark -
//- (void)replaceCharactersInRange:(NSRange)inRange withAttributedString:(NSAttributedString *)inAttributedString synchronize:(BOOL)inSynchronizeFlag;
//- (void)replaceCharactersInRange:(NSRange)inRange withAttributedString:(NSAttributedString *)inAttributedString;
- (void)removeAttribute:(NSString *)anAttribute range:(NSRange)aRange synchronize:(BOOL)aSynchronizeFlag;
- (NSRange)foldableRangeForCharacterAtIndex:(unsigned long int)index;

- (void)replaceCharactersInRange:(NSRange)inRange withAttributedString:(NSAttributedString *)inAttributedString synchronize:(BOOL)inSynchronizeFlag;

// disables synchronisation until linear attribute changing ends;
- (void)beginLinearAttributeChanges;
- (void)endLinearAttributeChanges;

#pragma mark -


- (BOOL)hasMixedLineEndingsInRange:(NSRange)aRange;
- (void)validateHasMixedLineEndings;

@end
