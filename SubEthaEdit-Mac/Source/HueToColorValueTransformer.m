//  HueToColorValueTransformer.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Mon Mar 29 2004.

#import "HueToColorValueTransformer.h"

// this file needs arc - add -fobjc-arc in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

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
	CGFloat brightness = 1.0;
	CGFloat saturation = 1.0;
	if (hue > 57./360. && hue < 180./360.) {
		brightness = 0.95;
	}
	
    return [NSColor colorWithCalibratedHue:hue saturation:saturation brightness:brightness alpha:1.0];
}

- (id)reverseTransformedValue:(id)value {
    if (![value isKindOfClass:[NSColor class]]) return nil;

	NSColor *color = [(NSColor *)value colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    CGFloat hue = 0.0;
    [color getHue:&hue saturation:NULL brightness:NULL alpha:NULL];
    
    return [NSNumber numberWithDouble:hue * 100.0];
}
@end
