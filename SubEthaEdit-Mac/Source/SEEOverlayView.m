//  SEEOverlayView.m
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 11.02.14.

#import "SEEOverlayView.h"
#import <QuartzCore/QuartzCore.h>

@interface SEEOverlayView ()
@property (strong) NSTrackingArea *cursorTrackingArea;
@end

@implementation SEEOverlayView

- (instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        
        self.blendingMode = NSVisualEffectBlendingModeWithinWindow;
        if (@available(macOS 10.14, *)) {
            self.material = NSVisualEffectMaterialHeaderView;
        } else {
            self.material = NSVisualEffectMaterialSidebar;
        }
        
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
