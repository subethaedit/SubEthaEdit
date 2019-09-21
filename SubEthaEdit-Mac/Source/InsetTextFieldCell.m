//  InsetTextFieldCell.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 09.01.06.

#import "InsetTextFieldCell.h"

@implementation InsetTextFieldCell

- (NSRect)drawingRectForBounds:(NSRect)aRect {
    aRect = [super titleRectForBounds:aRect];
    aRect.origin.y +=1;
    return aRect;
}

@end
