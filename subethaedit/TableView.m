//
//  TableView.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 14.10.04.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "TableView.h"


@implementation TableView
-(void)setLightBackgroundColor:(NSColor *)aColor {
    [I_lightBackgroundColor autorelease];
     I_lightBackgroundColor=[aColor retain];
}

-(void)setDarkBackgroundColor:(NSColor *)aColor {
    [I_darkBackgroundColor autorelease];
     I_darkBackgroundColor=[aColor retain];
}

- (void)drawBackgroundInClipRect:(NSRect)clipRect {
    [I_lightBackgroundColor set];
    NSRectFill([self rectOfColumn:0]);
    [I_darkBackgroundColor set];
    NSRectFill([self rectOfColumn:1]);
}

// Focus Ring methods

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


@end
