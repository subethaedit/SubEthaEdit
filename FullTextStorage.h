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

    NSMutableArray *I_lineStarts;
    unsigned int I_lineStartsValidUpTo;
    unsigned I_numberOfWords;
}

- (id)initWithFoldableTextStorage:(FoldableTextStorage *)inTextStorage;

#pragma mark -
- (NSString *)positionStringForRange:(NSRange)aRange;
- (int)lineNumberForLocation:(unsigned)location;
- (NSMutableArray *)lineStarts;
- (void)setLineStartsOnlyValidUpTo:(unsigned int)aLocation;
- (NSRange)findLine:(int)aLineNumber;

#pragma mark -
- (void)replaceCharactersInRange:(NSRange)inRange withAttributedString:(NSAttributedString *)inAttributedString synchronize:(BOOL)inSynchronizeFlag;
- (void)replaceCharactersInRange:(NSRange)inRange withAttributedString:(NSAttributedString *)inAttributedString;


@end
