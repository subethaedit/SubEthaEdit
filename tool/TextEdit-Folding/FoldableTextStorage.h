//
//  FoldableTextStorage.h
//  TextEdit
//
//  Created by Dominik Wagner on 04.01.09.
//  Copyright 2009 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class FullTextStorage;
#import "AbstractFoldingTextStorage.h"

@interface FoldedTextAttachment : NSTextAttachment
{
	NSRange I_foldedTextRange;
}
- (id)initWithFoldedTextRange:(NSRange)inFoldedTextRange;
- (NSRange)foldedTextRange;
- (void)setFoldedTextRange:(NSRange)inRange;
@end


@interface FoldableTextStorage : AbstractFoldingTextStorage {
	NSMutableAttributedString *I_internalAttributedString;
	FullTextStorage *I_fullTextStorage;
	NSMutableArray *I_sortedFoldedTextAttachments;
	int I_editingCount;
}

- (NSRange)fullRangeForFoldedRange:(NSRange)inRange;
- (FullTextStorage *)fullTextStorage;

- (void)fullTextDidReplaceCharactersInRange:(NSRange)inRange withString:(NSString *)inString;
- (void)fullTextDidSetAttributes:(NSDictionary *)inAttributes range:(NSRange)inRange;

#pragma mark folding methods
- (void)foldRange:(NSRange)inRange;
- (void)unfoldAttachment:(FoldedTextAttachment *)inAttachment atCharacterIndex:(NSUInteger)inIndex;

- (NSString *)foldedStringRepresentation;

@end
