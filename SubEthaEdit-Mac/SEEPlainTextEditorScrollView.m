//
//  SEEPlainTextEditorScrollView.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Thu Apr 15 2004.
//  Recreated by Michael Ehrmannn on Tue Jan 21 2014
//
//  Copyright (c) 2004 - 2014 TheCodingMonkeys. All rights reserved.
//

#import "SEEPlainTextEditorScrollView.h"

#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

@implementation SEEPlainTextEditorScrollView

- (void)tile {
    // Let the superclass do most of the work.
    [super tile];

    if ([self hasVerticalScroller]) {
        NSScroller *verticalScroller = self.verticalScroller;
        NSRect verticalScrollerFrame = verticalScroller.frame;

        verticalScrollerFrame.size.height -= self.topOverlayHeight + self.bottomOverlayHeight;
        verticalScrollerFrame.origin.y    += self.topOverlayHeight;

        verticalScroller.frame = verticalScrollerFrame;
    }

	if ([self hasHorizontalScroller]) {
		NSScroller *horizontalScroller = self.horizontalScroller;
		NSRect horizontalScrollerFrame = horizontalScroller.frame;

		horizontalScrollerFrame.origin.y -= self.bottomOverlayHeight;
		horizontalScroller.frame = horizontalScrollerFrame;
	}
}


- (void)setTopOverlayHeightNumber:(NSNumber *)heightNumber {
	self.topOverlayHeight = heightNumber.doubleValue;
}

- (void)setBottomOverlayHeightNumber:(NSNumber *)heightNumber {
	self.bottomOverlayHeight = heightNumber.doubleValue;
}

@end
