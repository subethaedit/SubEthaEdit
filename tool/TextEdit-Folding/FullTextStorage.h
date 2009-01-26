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
}

- (id)initWithFoldableTextStorage:(FoldableTextStorage *)inTextStorage;

- (void)replaceCharactersInRange:(NSRange)inRange withAttributedString:(NSAttributedString *)inAttributedString synchronize:(BOOL)inSynchronizeFlag;
- (void)replaceCharactersInRange:(NSRange)inRange withAttributedString:(NSAttributedString *)inAttributedString;


@end
