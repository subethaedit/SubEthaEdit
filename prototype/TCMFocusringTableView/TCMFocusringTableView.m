//
//  TCMFocusringTableView.m
//  TCMFocusringTableView
//
//  Created by Martin Pittenauer on 12.10.04.
//  Copyright 2004 TheCodingMonkeys. All rights reserved.
//

#import "TCMFocusringTableView.h"


@implementation TCMFocusringTableView

- (void)higlightWithColor:(NSColor *)aColor inset:(float)aInset {
    if ([self selectedRow]>=0) {
        [NSGraphicsContext saveGraphicsState];
        NSSetFocusRingStyle (NSFocusRingOnly);
        [[NSBezierPath bezierPathWithRect:NSInsetRect([self rectOfRow:[self selectedRow]],aInset,aInset)] fill];
        [NSGraphicsContext restoreGraphicsState];
    }
    [self setNeedsDisplay:YES];
}

- (void)highlightSelectionInClipRect:(NSRect)clipRect {
    [self higlightWithColor:nil inset:1.];
    [self setFocusRingType:NSFocusRingTypeNone];
}


- (void)selectRowIndexes:(NSIndexSet *)indexes byExtendingSelection:(BOOL)extend {
    [super selectRowIndexes:indexes byExtendingSelection:extend];
    [self setNeedsDisplay:YES];
}
/*
- (void)drawBackgroundInClipRect:(NSRect)clipRect {
    //NSLog(@"drawBackground");
    [super drawBackgroundInClipRect:clipRect];
    //[self higlightWithColor:[NSColor greenColor] inset:3.];
}

- (void)drawGridInClipRect:(NSRect)aRect {
    //NSLog(@"drawGridInClipRect");
    [super drawGridInClipRect:aRect];
}

- (void)drawRow:(int)rowIndex clipRect:(NSRect)clipRect {
    //NSLog(@"drawRow clipRect");
    [super drawRow:(int)rowIndex clipRect:(NSRect)clipRect];
    //[self higlightWithColor:[NSColor blackColor] inset:4.+rowIndex];
}
*/
@end
