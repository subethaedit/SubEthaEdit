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
    [aColor set];
    NSFrameRect(NSInsetRect([self rectOfRow:[self selectedRow]],aInset,aInset));
}

- (void)highlightSelectionInClipRect:(NSRect)clipRect {
    NSLog(@"highlightSelectionInClipRect");
    [self higlightWithColor:[NSColor greenColor] inset:2.];
//    [super highlightSelectionInClipRect:clipRect];
    [self higlightWithColor:[NSColor redColor] inset:1.];
}

- (void)drawBackgroundInClipRect:(NSRect)clipRect {
    NSLog(@"drawBackground");
    [super drawBackgroundInClipRect:clipRect];
    [self higlightWithColor:[NSColor greenColor] inset:3.];
}

- (void)drawGridInClipRect:(NSRect)aRect {
    NSLog(@"drawGridInClipRect");
    [super drawGridInClipRect:aRect];
}

- (void)drawRow:(int)rowIndex clipRect:(NSRect)clipRect {
    NSLog(@"drawRow clipRect");
    [super drawRow:(int)rowIndex clipRect:(NSRect)clipRect];
    [self higlightWithColor:[NSColor blackColor] inset:4.+rowIndex];
}
@end
