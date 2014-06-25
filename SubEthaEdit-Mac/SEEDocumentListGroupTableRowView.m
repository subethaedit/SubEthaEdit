//
//  SEENetworkBrowserGroupTableRowView.m
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 24.02.14.
//  Copyright (c) 2014 TheCodingMonkeys. All rights reserved.
//

#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

#import "SEEDocumentListGroupTableRowView.h"

#import <QuartzCore/QuartzCore.h>

@implementation SEEDocumentListGroupTableRowView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    return self;
}

- (void)drawBackgroundInRect:(NSRect)dirtyRect {
	if (self.window.isKeyWindow) {
		NSGradient *gradient = [[NSGradient alloc] initWithColorsAndLocations:
								[[NSColor colorWithDeviceRed:0.87 green:0.92 blue:0.97 alpha:0.85] shadowWithLevel:0.1], 0.0,
								[[NSColor colorWithDeviceRed:0.89 green:0.92 blue:0.95 alpha:0.85] shadowWithLevel:0.1], 0.45,
								[[NSColor colorWithDeviceRed:0.87 green:0.92 blue:0.97 alpha:0.85] shadowWithLevel:0.1], 1.0,
								nil];
		[gradient drawInRect:self.bounds angle:90.0];
	} else {
		NSGradient *gradient = [[NSGradient alloc] initWithColorsAndLocations:
								[[NSColor colorWithDeviceRed:0.9 green:0.9 blue:0.9 alpha:0.85] shadowWithLevel:0.1], 0.0,
								[[NSColor colorWithDeviceRed:0.93 green:0.93 blue:0.93 alpha:0.85] shadowWithLevel:0.1], 0.45,
								[[NSColor colorWithDeviceRed:0.9 green:0.9 blue:0.9 alpha:0.85] shadowWithLevel:0.1], 1.0,
								nil];
		[gradient drawInRect:self.bounds angle:90.0];
	}

	if (! self.floating) {
		if (self.isFlipped) {
			[[NSColor lightGrayColor] set];
			NSRect bounds = self.bounds;
			[NSBezierPath strokeLineFromPoint:NSMakePoint(NSMinX(bounds), NSMaxY(bounds))
									  toPoint:NSMakePoint(NSMaxX(bounds), NSMaxY(bounds))];

			if (self.drawTopLine) {
				[NSBezierPath strokeLineFromPoint:NSMakePoint(NSMinX(bounds), NSMinY(bounds))
										  toPoint:NSMakePoint(NSMaxX(bounds), NSMinY(bounds))];
			}
		}
	}
}

- (void)drawSelectionInRect:(NSRect)dirtyRect {
	NSGradient *gradient = [[NSGradient alloc] initWithColorsAndLocations:
							[[NSColor colorWithDeviceRed:0.87 green:0.92 blue:0.97 alpha:0.85] shadowWithLevel:0.2], 0.0,
							[[NSColor colorWithDeviceRed:0.89 green:0.92 blue:0.95 alpha:0.85] shadowWithLevel:0.2], 0.7,
							[[NSColor colorWithDeviceRed:0.87 green:0.92 blue:0.97 alpha:0.85] shadowWithLevel:0.2], 1.0,
							nil];
	[gradient drawInRect:dirtyRect angle:90.0];
}

- (void)drawSeparatorInRect:(NSRect)dirtyRect {
	[super drawSeparatorInRect:dirtyRect];
}

- (BOOL)isOpaque {
	return NO;
}

@end
