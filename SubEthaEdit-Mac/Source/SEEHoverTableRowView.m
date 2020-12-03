
#import "SEEHoverTableRowView.h"

@interface SEEHoverTableRowView ()
@property (nonatomic) BOOL mouseInside;
@property (nonatomic, strong) NSTrackingArea *trackingArea;
@end

@implementation SEEHoverTableRowView

- (void)setEmphasized:(BOOL)emphasized {
	[super setEmphasized:emphasized];
	// this is also sent on key state change, so let us mark ourselves as dirty so we show the hover initially
	[self setNeedsDisplay:YES];
}

- (void)setMouseInside:(BOOL)value {
    if (_mouseInside != value) {
        _mouseInside = value;
		[self setNeedsDisplay:YES];
    }
}

- (void)TCM_updateMouseInside {
    NSWindow *window = self.window;
    if (window) {
        NSPoint mouseLocationInWindow = [window mouseLocationOutsideOfEventStream];
        NSPoint mouseLocationInBounds = [self convertPoint:mouseLocationInWindow fromView:nil];
        BOOL isInside = NSMouseInRect(mouseLocationInBounds, self.bounds, self.isFlipped);
        //	NSLog(@"%s isInside: %@ - %@",__FUNCTION__,isInside?@"YES":@"NO",NSStringFromPoint(mouseLocationInBounds));
        self.mouseInside = isInside;
    } else {
        self.mouseInside = NO;
    }
}

- (void)ensureTrackingArea {
    if (self.trackingArea == nil) {
		NSTrackingAreaOptions options = NSTrackingInVisibleRect | NSTrackingActiveAlways | NSTrackingMouseEnteredAndExited;
		[self TCM_updateMouseInside];
		if (self.mouseInside) {
			options |= NSTrackingAssumeInside;
		}
        self.trackingArea = [[NSTrackingArea alloc] initWithRect:NSZeroRect options:options owner:self userInfo:nil];
    }
}

- (void)updateTrackingAreas {
    [super updateTrackingAreas];
    [self ensureTrackingArea];
    if (![[self trackingAreas] containsObject:self.trackingArea]) {
        [self addTrackingArea:self.trackingArea];
    }
	[self TCM_updateMouseInside];
}

- (void)mouseEntered:(NSEvent *)theEvent {
    self.mouseInside = YES;
}

- (void)mouseExited:(NSEvent *)theEvent {
    self.mouseInside = NO;
}

- (void)drawBackgroundInRect:(NSRect)dirtyRect {
    [super drawBackgroundInRect:dirtyRect];

    if (self.mouseInside) {
        CGFloat alphaValue = self.clickHighlight ? 0.16 : 0.08;
        [[[NSColor labelColor] colorWithAlphaComponent:alphaValue] setFill];
        CGFloat inset = 1;
        if (@available(macOS 11.0, *)) {
            inset = 10;
        }
        NSRect selectionRect = NSInsetRect(self.bounds, inset, 0);
        NSBezierPath *selectionPath = [NSBezierPath bezierPathWithRoundedRect:selectionRect xRadius:5 yRadius:5];
        [selectionPath fill];
    }
}

@end
