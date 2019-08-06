//  SEEOverlayView.m
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 11.02.14.

// this file needs arc - either project wide,
// or add -fobjc-arc on a per file basis in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

#import "SEEOverlayView.h"
#import <QuartzCore/QuartzCore.h>

@interface SEEOverlayView ()
@property (strong) NSTrackingArea *cursorTrackingArea;
@end

@implementation SEEOverlayView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        
        self.blendingMode = NSVisualEffectBlendingModeWithinWindow;
        self.material = NSVisualEffectMaterialSidebar;
        
		NSTrackingAreaOptions options = NSTrackingCursorUpdate | NSTrackingInVisibleRect | NSTrackingActiveInKeyWindow;

		NSPoint mouseLocationInBounds = [self convertPoint:self.window.mouseLocationOutsideOfEventStream fromView:nil];
		BOOL mouseIsInside = NSMouseInRect(mouseLocationInBounds, self.bounds, self.isFlipped);
		if (mouseIsInside) {
			options |= NSTrackingAssumeInside;
		}

		NSTrackingArea *trackingArea = [[NSTrackingArea alloc] initWithRect:NSZeroRect
																	options:options
																	  owner:self
																   userInfo:nil];

		[self addTrackingArea:trackingArea];
		self.cursorTrackingArea = trackingArea;
    }
    return self;
}

- (void)dealloc {
    [self removeTrackingArea:self.cursorTrackingArea];
}

- (void)cursorUpdate:(NSEvent *)event {
	[[NSCursor arrowCursor] set];
}

@end
