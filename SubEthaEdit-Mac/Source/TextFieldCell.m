//  TextFieldCell.m
//  SubEthaEdit
//
//  Created by Martin Pittenauer on 14.10.04.

#import "TextFieldCell.h"


@implementation TextFieldCell

- (void)setHighlighted:(BOOL)flag {
    [super setHighlighted:NO];
}

- (void)highlight:(BOOL)flag withFrame:(NSRect)cellFrame inView:(NSView *)controlView {
}

- (NSColor *)highlightColorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
     //NSLog(@"highlightColorWithFrame");
     return nil;
 }

- (NSRect)drawingRectForBounds:(NSRect)aRect {
    return NSInsetRect([super drawingRectForBounds:aRect],3,0);
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	NSAttributedString *styledText = [self attributedStringValue];
	if (styledText.length > 0) {
	    NSColor *backgroundColor = [[self attributedStringValue] attribute:NSBackgroundColorAttributeName atIndex:0 effectiveRange:NULL];
	    if (backgroundColor) {
		    [backgroundColor set];
		    [NSBezierPath fillRect:cellFrame];
	    }
	}
    if (floor(NSAppKitVersionNumber) > 824.) {
        [[self attributedStringValue] drawInRect:NSInsetRect(cellFrame,5.,0)];
    } else {
        [super drawInteriorWithFrame:cellFrame inView:controlView];
    }
}
@end
