//  FoldingTextAttachmentCell.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 03.02.09.

#import "FoldingTextAttachmentCell.h"

// this file needs arc - add -fobjc-arc in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

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
characterIndex:(NSUInteger)charIndex layoutManager:(NSLayoutManager *) 
layoutManager {
//    [[NSColor redColor] set];
//    NSLog(@"cell frame %@", NSStringFromRect(cellFrame));
//    NSFrameRect(cellFrame);
	NSRect targetRect = NSZeroRect;
	targetRect.size = s_foldingImage.size;
	targetRect.origin = NSMakePoint(cellFrame.origin.x + IMAGE_INSET,NSMaxY(cellFrame) - IMAGE_INSET - s_foldingImage.size.height);
	[s_foldingImage drawInRect:targetRect fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1.0 respectFlipped:YES hints:nil];
	
}


- (BOOL)wantsToTrackMouseForEvent:(NSEvent *)theEvent inRect:(NSRect)cellFrame ofView:(NSView *)controlView atCharacterIndex:(NSUInteger)charIndex {
//	NSLog(@"%s %@ %@ %@ %d",__FUNCTION__,theEvent, NSStringFromRect(cellFrame), controlView, charIndex);
	return YES;
}

@end
