//  FoldedTextAttachment.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 03.02.09.

#import "FoldingTextAttachmentCell.h"
#import "FoldedTextAttachment.h"

@implementation FoldedTextAttachment
- (instancetype)initWithFoldedTextRange:(NSRange)inFoldedTextRange
{
	if ((self = [self init])) {
		_foldedTextRange = inFoldedTextRange;
		_innerAttachments = [NSMutableArray new];
        self.attachmentCell = [FoldingTextAttachmentCell new];
	}
	return self;
}

- (void)moveAttachmentLocation:(int)inLocationDifference {
	_foldedTextRange.location += inLocationDifference;
	int loopIndex = (int)[_innerAttachments count];
	while ((--loopIndex) >= 0) {
		[[_innerAttachments objectAtIndex:loopIndex] moveAttachmentLocation:inLocationDifference];
	}
}

@end


