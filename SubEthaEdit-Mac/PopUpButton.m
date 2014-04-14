//
//  PopUpButton.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Tue Apr 20 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif


#import "PopUpButton.h"
#import "PopUpButtonCell.h"

@implementation PopUpButton

+ (void)initialize {
    if (self == [PopUpButton class]) {
        [self setCellClass:[PopUpButtonCell class]];
    }
}

+ (Class)cellClass {
    return [PopUpButtonCell class];
}

- (id)initWithFrame:(NSRect)frameRect pullsDown:(BOOL)flag {   
    self=[super initWithFrame:frameRect pullsDown:flag];
	if (self) {
		[[self cell] setArrowPosition:NSPopUpNoArrow];
		[[self cell] setControlSize:NSSmallControlSize];
		[self setBordered:NO];
		[self setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSSmallControlSize]]];
		self.lineDrawingEdge = CGRectMaxXEdge;
		self.lineColor = [NSColor grayColor]; // just a default
	}
    return self;
}

- (void)dealloc {
    [self setDelegate:nil];
}

- (void)mouseDown:(NSEvent *)theEvent {
    id delegate=[self delegate];
    if ([delegate respondsToSelector:@selector(popUpWillShowMenu:)]) {
        [delegate popUpWillShowMenu:self];
    }
    [super mouseDown:theEvent];
}

- (NSSize)intrinsicContentSize {
	NSSize result = [super intrinsicContentSize];
	CGFloat symbolPopupWidth = [(PopUpButtonCell *)[self cell] desiredWidth];
	result.width = round(symbolPopupWidth);
	return result;
}

- (void)drawRect:(NSRect)aRect {
    [super drawRect:aRect];
    NSRect bounds=NSIntegralRect([self bounds]);
	bounds = NSInsetRect(bounds, 0.5, 0);
    [self.lineColor set];
    [NSBezierPath setDefaultLineWidth:1.];

	if (self.lineDrawingEdge == CGRectMaxXEdge) {
		[NSBezierPath strokeLineFromPoint:NSMakePoint(NSMaxX(bounds),NSMinY(bounds))
								  toPoint:NSMakePoint(NSMaxX(bounds),NSMaxY(bounds))];
	} else if (self.lineDrawingEdge == CGRectMinXEdge) {
		[NSBezierPath strokeLineFromPoint:NSMakePoint(NSMinX(bounds),NSMinY(bounds))
								  toPoint:NSMakePoint(NSMinX(bounds),NSMaxY(bounds))];
	} else {
		NSLog(@"%s - Unknown line drawing option: %u", __FUNCTION__, self.lineDrawingEdge);
	}

    CGContextRef ctx = [[NSGraphicsContext currentContext] graphicsPort];
    CGContextSetRGBFillColor (ctx, 0.0, 0.0, 0.0, 1);
    CGContextBeginPath(ctx);
    NSRect triangleRect;
    triangleRect.size.height=bounds.size.height*.6;
    triangleRect.size.width=bounds.size.height / 4.;
    triangleRect.origin.x=NSMaxX(bounds)-triangleRect.size.width*2.;
    triangleRect.origin.y=(bounds.size.height - triangleRect.size.height)/2.;
    triangleRect = NSIntegralRect(triangleRect);
    float triangleSpacing = triangleRect.size.height*.15;

    if ([self pullsDown]) {
		triangleRect = NSOffsetRect(triangleRect, 0, 0.5);
		CGContextMoveToPoint(ctx,NSMinX(triangleRect)-triangleSpacing/2.,NSMidY(triangleRect)-2*triangleSpacing);
		CGContextAddLineToPoint(ctx,NSMaxX(triangleRect)+triangleSpacing/2.,NSMidY(triangleRect)-2*triangleSpacing);
		CGContextAddLineToPoint(ctx,NSMidX(triangleRect),NSMaxY(triangleRect)-2*triangleSpacing);
		CGContextClosePath(ctx);
    } else {
		CGContextMoveToPoint(ctx,NSMinX(triangleRect),NSMidY(triangleRect)-triangleSpacing);
		CGContextAddLineToPoint(ctx,NSMaxX(triangleRect),NSMidY(triangleRect)-triangleSpacing);
		CGContextAddLineToPoint(ctx,NSMidX(triangleRect),NSMinY(triangleRect));
		CGContextClosePath(ctx);
		
		CGContextMoveToPoint(ctx,NSMinX(triangleRect),NSMidY(triangleRect)+triangleSpacing);
		CGContextAddLineToPoint(ctx,NSMaxX(triangleRect),NSMidY(triangleRect)+triangleSpacing);
		CGContextAddLineToPoint(ctx,NSMidX(triangleRect),NSMaxY(triangleRect));
		CGContextClosePath(ctx);
    }
    
    CGContextFillPath(ctx);
}

@end
