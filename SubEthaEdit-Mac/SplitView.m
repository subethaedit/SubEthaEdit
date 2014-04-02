//
//  SplitView.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Tue Apr 13 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "SplitView.h"


@implementation SplitView

- (id)initWithFrame:(NSRect)frameRect {
    if ((self = [super initWithFrame:frameRect])) {
        I_dividerThickness = -1.;
    }
    return self;
}

- (void)setDividerThickness:(float)aDividerThickness {
    I_dividerThickness = aDividerThickness;
}

- (CGFloat)dividerThickness {
    return I_dividerThickness<0. ? [super dividerThickness] : I_dividerThickness;
}

- (void)drawDividerInRect:(NSRect)aRect {
    static NSColor *color;
    if (!color) {
		color = [[[NSColor whiteColor] colorWithAlphaComponent:0.4] retain];
    }
    [color set];
    [[NSBezierPath bezierPathWithRect:aRect] fill];
    aRect.origin.x-=1;
    aRect.size.width+=2;
    if (I_dividerThickness <0. || I_dividerThickness > 8.)
        [super drawDividerInRect:aRect];
    [[NSColor lightGrayColor] set];
    NSFrameRect(aRect);
}

#pragma mark - State Restoration

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
//	NSLog(@"%s - %d : %@", __FUNCTION__, __LINE__, self);
	[super encodeRestorableStateWithCoder:coder];
}

- (void)restoreStateWithCoder:(NSCoder *)coder {
//	NSLog(@"%s - %d : %@", __FUNCTION__, __LINE__, self);
	[super restoreStateWithCoder:coder];
}

@end
