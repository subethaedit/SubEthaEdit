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
    float hue = [aValue floatValue]/100.;
    
    return [NSColor colorWithCalibratedHue:hue saturation:1.0 brightness:1.0 alpha:1.];
}

- (id)reverseTransformedValue:(id)value {
    if (![value isKindOfClass:[NSColor class]]) return nil;
    CGFloat ignore,hue;
    [[(NSColor *)value colorUsingColorSpaceName:NSCalibratedRGBColorSpace] getHue:&hue saturation:&ignore brightness:&ignore alpha:&ignore];
    
    return [NSNumber numberWithFloat:hue*100];
}
@end
