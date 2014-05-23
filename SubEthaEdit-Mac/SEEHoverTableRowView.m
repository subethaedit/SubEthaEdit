// this file needs arc - either project wide,
// or add -fobjc-arc on a per file basis in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

#import "SEEHoverTableRowView.h"

@interface SEEHoverTableRowView ()
@property (nonatomic) BOOL mouseInside;
@property (nonatomic, strong) NSTrackingArea *trackingArea;
@end

@implementation SEEHoverTableRowView

- (void)setMouseInside:(BOOL)value {
    if (_mouseInside != value) {
        _mouseInside = value;
        [self setNeedsDisplay:YES];
    }
}

- (void)TCM_updateMouseInside {
	NSPoint mouseLocationInBounds = [self convertPoint:[[self window] convertScreenToBase:[NSEvent mouseLocation]] fromView:nil];
	BOOL isInside = NSMouseInRect(mouseLocationInBounds, self.bounds, self.isFlipped);
	//	NSLog(@"%s isInside: %@ - %@",__FUNCTION__,isInside?@"YES":@"NO",NSStringFromPoint(mouseLocationInBounds));
	self.mouseInside = isInside;
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
}

- (void)mouseEntered:(NSEvent *)theEvent {
    self.mouseInside = YES;
}

- (void)mouseExited:(NSEvent *)theEvent {
    self.mouseInside = NO;
}

static NSGradient *gradientWithTargetColor(NSColor *targetColor) {
    NSArray *colors = [NSArray arrayWithObjects:[targetColor colorWithAlphaComponent:0], targetColor, targetColor, [targetColor colorWithAlphaComponent:0], nil];
    const CGFloat locations[4] = { 0.0, 0.35, 0.65, 1.0 };
    return [[NSGradient alloc] initWithColors:colors atLocations:locations colorSpace:[NSColorSpace sRGBColorSpace]];
}

static NSGradient *gradientWithTargetColorAndLocation(NSColor *targetColor, CGFloat stop1, CGFloat stop2) {
    NSArray *colors = [NSArray arrayWithObjects:[targetColor colorWithAlphaComponent:0], targetColor, targetColor, [targetColor colorWithAlphaComponent:0], nil];
    const CGFloat locations[4] = { 0.0, stop1, stop2, 1.0 };
    return [[NSGradient alloc] initWithColors:colors atLocations:locations colorSpace:[NSColorSpace sRGBColorSpace]];
}


- (void)drawBackgroundInRect:(NSRect)dirtyRect {
    [super drawBackgroundInRect:dirtyRect];
    // Draw a white/alpha gradient
    if (self.mouseInside && [self.window isMainWindow]) {
        NSGradient *gradient;
		CGFloat location = 40.0 / CGRectGetWidth(self.bounds);
		CGFloat highlightWidth = 80.0 / CGRectGetWidth(self.bounds);
		gradient = gradientWithTargetColorAndLocation([NSColor colorWithCalibratedWhite:1.000 alpha:0.350], location, location+highlightWidth);
        [gradient drawInRect:self.bounds angle:0];
    }
}

- (NSRect)separatorRect {
    NSRect separatorRect = self.bounds;
    separatorRect.origin.y = NSMaxY(separatorRect) - 1;
    separatorRect.size.height = 1;
    return separatorRect;
}

// Only called if the table is set with a horizontal grid
- (void)drawSeparatorInRect:(NSRect)dirtyRect {
    // Use a common shared method of drawing the separator
    SEEHovertTableRowDrawSeparatorInRect([self separatorRect]);
}

// Only called if the 'selected' property is yes.
- (void)drawSelectionInRect:(NSRect)dirtyRect {
    // Check the selectionHighlightStyle, in case it was set to None
    if (self.selectionHighlightStyle != NSTableViewSelectionHighlightStyleNone) {
        // We want a hard-crisp stroke, and stroking 1 pixel will border half on one side and half on another, so we offset by the 0.5 to handle this
        NSRect selectionRect = NSInsetRect(self.bounds, 5.5, 5.5);
        [[NSColor colorWithCalibratedWhite:.72 alpha:1.0] setStroke];
        [[NSColor colorWithCalibratedWhite:.82 alpha:1.0] setFill];
        NSBezierPath *selectionPath = [NSBezierPath bezierPathWithRoundedRect:selectionRect xRadius:10 yRadius:10];
        [selectionPath fill];
        [selectionPath stroke];
    }
}

- (void)setFrame:(NSRect)frameRect {
    [super setFrame:frameRect];
    // We need to invalidate more things when live-resizing since we fill with a gradient and stroke
    if ([self inLiveResize]) {
        // Redraw everything if we are using a gradient
        if (self.selected || self.mouseInside) {
            [self setNeedsDisplay:YES];
        } else {
            // Redraw our horizontal grid line, which is a gradient
            [self setNeedsDisplayInRect:[self separatorRect]];
        }
    }
}

@end

void SEEHovertTableRowDrawSeparatorInRect(NSRect rect) {
    // Cache the gradient for performance
    static NSGradient *gradient = nil;
    if (gradient == nil) {
        gradient = gradientWithTargetColor([NSColor colorWithSRGBRed:.80 green:.80 blue:.80 alpha:1]);
    }
    [gradient drawInRect:rect angle:0];
    
}
