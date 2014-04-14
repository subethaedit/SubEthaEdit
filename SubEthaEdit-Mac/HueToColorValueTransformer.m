//
//  HueToColorValueTransformer.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Mon Mar 29 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "HueToColorValueTransformer.h"


@implementation HueToColorValueTransformer

+ (Class)transformedValueClass {
    return [NSColor class];
}

+ (BOOL)allowsReverseTransformation {
    return YES;   
}

- (id)transformedValue:(id)aValue {
    if (aValue == nil) return nil;
    CGFloat hue = [aValue doubleValue] / 100.0;
    return [NSColor colorWithCalibratedHue:hue saturation:1.0 brightness:1.0 alpha:1.0];
}

- (id)reverseTransformedValue:(id)value {
    if (![value isKindOfClass:[NSColor class]]) return nil;

	NSColor *color = [(NSColor *)value colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    CGFloat hue = 0.0;
    [color getHue:&hue saturation:NULL brightness:NULL alpha:NULL];
    
    return [NSNumber numberWithDouble:hue * 100.0];
}
@end
