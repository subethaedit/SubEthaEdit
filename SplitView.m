//
//  SplitView.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Tue Apr 13 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "SplitView.h"


@interface NSColor (AppleInternalAdditions)

+ (NSColor *) _toolbarBackgroundColor;

@end

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

- (float)dividerThickness {
    return I_dividerThickness<0. ? [super dividerThickness] : I_dividerThickness;
}

- (void)drawDividerInRect:(NSRect)aRect {
    static NSColor *color;
    if (!color) {
        if ([NSColor respondsToSelector:@selector(_toolbarBackgroundColor)]) {
            color = [[NSColor _toolbarBackgroundColor] retain];
        } else {
            color = [[[NSColor whiteColor] colorWithAlphaComponent:0.4] retain];
        }
    }
    [color set];
    [[NSBezierPath bezierPathWithRect:aRect] fill];
    [[NSColor lightGrayColor] set];
    aRect.origin.x-=1;
    aRect.size.width+=2;
    NSFrameRect(aRect);
    if (I_dividerThickness <0. || I_dividerThickness > 8.)
        [super drawDividerInRect:aRect];
}

@end
