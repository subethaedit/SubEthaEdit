//
//  FoldedTextAttachment.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 03.02.09.
//  Copyright 2009 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface FoldedTextAttachment : NSTextAttachment
{
	NSRange I_foldedTextRange;
	NSMutableArray *I_innerAttachments;
}
- (id)initWithFoldedTextRange:(NSRange)inFoldedTextRange;
- (NSRange)foldedTextRange;
- (NSMutableArray *)innerAttachments;
- (void)setFoldedTextRange:(NSRange)inRange;
- (void)moveAttachmentLocation:(int)inLocationDifference;
@end

