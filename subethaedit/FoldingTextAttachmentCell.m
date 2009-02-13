//
//  FoldingTextAttachmentCell.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 03.02.09.
//  Copyright 2009 TheCodingMonkeys. All rights reserved.
//

#import "FoldingTextAttachmentCell.h"

static NSImage *s_foldingImage = nil;

#define IMAGE_INSET 1.

@implementation FoldingTextAttachmentCell
- (id)init {
	if ((self = [super init])) {
		if (!s_foldingImage) s_foldingImage = [NSImage imageNamed:@"folded"];
	}
	return self;
}

- (NSSize)cellSize {
//	NSLog(@"%s %@ %@",__FUNCTION__,NSStringFromSize([super cellSize]), [self attachment]);
	NSSize result = [s_foldingImage size];
	result.width += 2*IMAGE_INSET;
	result.height += 2*IMAGE_INSET;
	return result;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView  
characterIndex:(unsigned)charIndex layoutManager:(NSLayoutManager *) 
layoutManager {
//    [[NSColor redColor] set];
//    NSLog(@"cell frame %@", NSStringFromRect(cellFrame));
//    NSFrameRect(cellFrame);
	[s_foldingImage 
	  compositeToPoint:NSMakePoint(cellFrame.origin.x + IMAGE_INSET,NSMaxY(cellFrame) - IMAGE_INSET)
	         operation:NSCompositeSourceOver];
}


- (BOOL)wantsToTrackMouseForEvent:(NSEvent *)theEvent inRect:(NSRect)cellFrame ofView:(NSView *)controlView atCharacterIndex:(unsigned)charIndex {
	NSLog(@"%s %@ %@ %@ %d",__FUNCTION__,theEvent, NSStringFromRect(cellFrame), controlView, charIndex);
	return YES;
}

@end
