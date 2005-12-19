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

- (float)dividerThickness {
    return [super dividerThickness];
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
    [super drawDividerInRect:aRect];
}

@end
