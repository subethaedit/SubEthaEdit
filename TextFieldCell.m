//
//  TextFieldCell.m
//  SubEthaEdit
//
//  Created by Martin Pittenauer on 14.10.04.
//  Copyright 2004 TheCodingMonkeys. All rights reserved.
//

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

@end
