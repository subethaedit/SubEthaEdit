//
//  PopUpButton.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Tue Apr 20 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

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
	}
    return self;
}

- (void)dealloc {
    [self setDelegate:nil];
    [super dealloc];
}

- (void)mouseDown:(NSEvent *)theEvent {
    id delegate=[self delegate];
    if ([delegate respondsToSelector:@selector(popUpWillShowMenu:)]) {
        [delegate popUpWillShowMenu:self];
    }
    [super mouseDown:theEvent];
}

- (void)setDelegate:(id)aDelegate {
    I_delegate=aDelegate;
}

- (id)delegate {
    return I_delegate;
}

- (void)drawRect:(NSRect)aRect {
    [super drawRect:aRect];
    NSRect bounds=NSIntegralRect([self bounds]);
    [[NSColor grayColor] set];
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
