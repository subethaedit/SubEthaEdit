//
//  FoldableTextStorage.h
//  TextEdit
//
//  Created by Dominik Wagner on 04.01.09.
//  Copyright 2009 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class FullTextStorage;

@interface FoldedTextAttachment : NSTextAttachment
{
	NSRange I_foldedTextRange;
}
- (id)initWithFoldedTextRange:(NSRange)inFoldedTextRange;
- (NSRange)foldedTextRange;
- (void)setFoldedTextRange:(NSRange)inRange;
@end


@interface FoldableTextStorage : NSTextStorage {
	NSMutableAttributedString *I_internalAttributedString;
	FullTextStorage *I_fullTextStorage;
}

- (NSRange)fullRangeForFoldableRange:(NSRange)inRange;
- (FullTextStorage *)fullTextStorage;

#pragma mark basic methods for synchronization
- (void)replaceCharactersInRange:(NSRange)aRange withString:(NSString *)aString synchronize:(BOOL)inSynchroFlag;
- (void)setAttributes:(NSDictionary *)attributes range:(NSRange)aRange synchronize:(BOOL)inSynchronizeFlag;

#pragma mark folding methods
- (void)foldRange:(NSRange)inRange;
- (void)unfoldAttachment:(FoldedTextAttachment *)inAttachment atIndex:(NSUInteger)inIndex;


@end
