//  FoldedTextAttachment.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 03.02.09.

#import "FoldingTextAttachmentCell.h"
#import "FoldedTextAttachment.h"


@implementation FoldedTextAttachment
- (instancetype)initWithFoldedTextRange:(NSRange)inFoldedTextRange
{
	if ((self = [self init]))
	{
		I_foldedTextRange = inFoldedTextRange;
		I_innerAttachments = [NSMutableArray new];
		[self setAttachmentCell:[[FoldingTextAttachmentCell new] autorelease]];
	}
	return self;
}

- (NSRange)foldedTextRange {
	return I_foldedTextRange;
}

- (void)setFoldedTextRange:(NSRange)inRange {
	I_foldedTextRange = inRange;
}

- (void)moveAttachmentLocation:(int)inLocationDifference {
	I_foldedTextRange.location += inLocationDifference;
	int loopIndex = (int)[I_innerAttachments count];
	while ((--loopIndex) >= 0) {
		[[I_innerAttachments objectAtIndex:loopIndex] moveAttachmentLocation:inLocationDifference];
	}
}

- (NSMutableArray *)innerAttachments {
	return I_innerAttachments;
}

- (void)dealloc
{
	[I_innerAttachments release];
	[super dealloc];
}

@end


