//
//  BorderedTextField.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 07.12.05.
//  Copyright 2005 TheCodingMonkeys. All rights reserved.
//

#import "BorderedTextField.h"


@implementation BorderedTextField

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setHasRightBorder: YES];
        [self setHasLeftBorder:   NO];
        [self setBorderColor:[NSColor grayColor]];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aCoder {
    self = [super initWithCoder:aCoder];
    [self setHasRightBorder: YES];
    [self setHasLeftBorder:   NO];
    [self setBorderColor:[NSColor grayColor]];
    return self;
}

- (void)dealloc {
    [self setBorderColor:nil];
    [super dealloc];
}

- (void)setHasRightBorder:(BOOL)aFlag {
    if (I_flags.hasRightBorder!=aFlag) {
        I_flags.hasRightBorder =aFlag;
        [self setNeedsDisplay:YES];
    }
}
- (void)setHasLeftBorder:(BOOL)aFlag {
    if (I_flags.hasLeftBorder!=aFlag) {
        I_flags.hasLeftBorder =aFlag;
        [self setNeedsDisplay:YES];
    }
}
- (void)setBorderColor:(NSColor *)aColor {
    [I_borderColor autorelease];
     I_borderColor=[aColor retain];
}

- (void)mouseDown:(NSEvent *)anEvent {
    if ([self action]) {
        [self sendAction:[self action] to:[self target]];
    }
}

- (void)drawRect:(NSRect)aRect {
    [super drawRect:aRect];
    [I_borderColor set];
    NSRect bounds=NSIntegralRect([self bounds]);
    if (I_flags.hasRightBorder) {
        [NSBezierPath setDefaultLineWidth:1.];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(NSMaxX(bounds),NSMinY(bounds))
                                  toPoint:NSMakePoint(NSMaxX(bounds),NSMaxY(bounds))];
    }
    if (I_flags.hasLeftBorder) {
        [NSBezierPath setDefaultLineWidth:1.];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(NSMinX(bounds),NSMinY(bounds))
                                  toPoint:NSMakePoint(NSMinX(bounds),NSMaxY(bounds))];
    }
}

@end
