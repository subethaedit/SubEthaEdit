
#import "SEEHoverTableRowView.h"

@interface SEEHoverTableRowView ()
@property (nonatomic) BOOL rightClick;
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
        NSRect selectionRect = NSInsetRect(self.bounds, 5, 0);
        [[[NSColor labelColor] colorWithAlphaComponent:alphaValue] setFill];
        NSBezierPath *selectionPath = [NSBezierPath bezierPathWithRoundedRect:selectionRect xRadius:5 yRadius:5];
        [selectionPath fill];
    }
}

// Only called if the 'selected' property is yes.
- (void)drawSelectionInRect:(NSRect)dirtyRect {
    [super drawSelectionInRect:dirtyRect];
    // Check the selectionHighlightStyle, in case it was set to None
//    if (self.selectionHighlightStyle != NSTableViewSelectionHighlightStyleNone) {
        // We want a hard-crisp stroke, and stroking 1 pixel will border half on one side and half on another, so we offset by the 0.5 to handle this
        NSRect selectionRect = NSInsetRect(self.bounds, 5.5, 5.5);
        [[NSColor colorWithCalibratedWhite:.72 alpha:1.0] setStroke];
        [[NSColor colorWithCalibratedWhite:.82 alpha:1.0] setFill];
        NSBezierPath *selectionPath = [NSBezierPath bezierPathWithRoundedRect:selectionRect xRadius:10 yRadius:10];
        [selectionPath fill];
        [selectionPath stroke];
//    }
}

- (void)setFrame:(NSRect)frameRect {
    [super setFrame:frameRect];
    // We need to invalidate more things when live-resizing since we fill with a gradient and stroke
    if ([self inLiveResize]) {
        // Redraw everything if we are using a gradient
        if (self.selected) {
            [self setNeedsDisplay:YES];
        }
    }
}

@end
