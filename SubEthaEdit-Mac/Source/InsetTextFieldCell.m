//  InsetTextFieldCell.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 09.01.06.

#import "InsetTextFieldCell.h"

// this file needs arc - add -fobjc-arc in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

@implementation InsetTextFieldCell

- (NSRect)drawingRectForBounds:(NSRect)aRect {
    aRect = [super titleRectForBounds:aRect];
    aRect.origin.y +=1;
    return aRect;
}

@end
