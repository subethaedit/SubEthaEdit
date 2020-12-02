//  SEENetworkBrowserGroupTableRowView.m
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 24.02.14.

#import "SEEDocumentListGroupTableRowView.h"

#import <QuartzCore/QuartzCore.h>

@implementation SEEDocumentListGroupTableRowView

- (void)drawBackgroundInRect:(NSRect)dirtyRect {
	if (! self.floating) {
		if (self.isFlipped) {
            if (@available(macOS 10.14, *)) {
                [[NSColor separatorColor] set];
            } else {
                [[NSColor grayColor] set];
            }
            
			NSRect bounds = self.bounds;
			if (self.drawTopLine) {
				[NSBezierPath strokeLineFromPoint:NSMakePoint(NSMinX(bounds), NSMinY(bounds))
										  toPoint:NSMakePoint(NSMaxX(bounds), NSMinY(bounds))];
                // We don't want a hairline on @2x screens, nor a double line @1x
                CGFloat screenScale = [[NSScreen mainScreen] backingScaleFactor];
                [NSBezierPath setDefaultLineWidth:screenScale];
			}
		}
	}
}

- (void)drawSeparatorInRect:(NSRect)dirtyRect {
	[super drawSeparatorInRect:dirtyRect];
}

- (BOOL)isOpaque {
	return NO;
}

@end
