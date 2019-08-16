//  SaturationColorValueTransformer.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Mon Mar 29 2004.

#import "SaturationToColorValueTransformer.h"
#import "GeneralPreferences.h"

@implementation SaturationToColorValueTransformer
+ (Class)transformedValueClass {
    return [NSColor class];
}

+ (BOOL)allowsReverseTransformation {
    return NO;   
}

- (instancetype)initWithColor:(NSColor *)aColor {
    self = [super init];
    if (self) {
        I_backgroundColor=[aColor copy];
    }
    return self;
}

- (id)transformedValue:(id)aValue {
    if (aValue == nil) return nil;
    float saturation = [aValue floatValue]/100.;
    NSValueTransformer *hueTransformer=[NSValueTransformer valueTransformerForName:@"HueToColor"];
    NSColor *userColor = (NSColor *)[hueTransformer transformedValue:[[NSUserDefaults standardUserDefaults] objectForKey:MyColorHuePreferenceKey]];
    return [I_backgroundColor blendedColorWithFraction:saturation ofColor:userColor];
}

@end
