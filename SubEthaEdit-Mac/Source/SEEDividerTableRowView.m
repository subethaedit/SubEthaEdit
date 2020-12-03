//  SEEDividerTableRowView.m
//  SubEthaEdit
//
//  Created by Jan Cornelissen on 03/12/2020.

#import "SEEDividerTableRowView.h"

@implementation SEEDividerTableRowView

- (void)drawBackgroundInRect:(NSRect)dirtyRect {
	if (!self.floating) {
		if (self.isFlipped) {
            NSRect rect = CGRectMake(0, 8, self.bounds.size.width, 1);
            NSBezierPath *divider = [NSBezierPath bezierPathWithRect:rect];
            
            if (@available(macOS 10.14, *)) {
                [[NSColor separatorColor] setFill];
            } else {
                [[NSColor grayColor] setFill];
            }
            
            [divider fill];
		}
	}
}

@end
