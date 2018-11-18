//  PointsToDisplayValueTrasformer.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 16.09.04.

#import "PointsToDisplayValueTransformer.h"


@implementation PointsToDisplayValueTransformer

static BOOL S_isCm;

+ (void)initialize {
	if (self == [PointsToDisplayValueTransformer class]) {
    S_isCm=[[[NSUserDefaults standardUserDefaults] stringForKey:@"AppleMeasurementUnits"] isEqualToString:@"Centimeters"];
   }
}

+ (Class)transformedValueClass {
    return [NSNumber class];
}

+ (BOOL)allowsReverseTransformation {
    return YES;   
}

- (id)transformedValue:(id)aValue {
    if (![aValue isKindOfClass:[NSNumber class]]) return nil;
    float cmToPoints=28.3464567; // google
    float inchToPoints=72;
    return [NSNumber numberWithFloat:[aValue floatValue]/(S_isCm?cmToPoints:inchToPoints)];
}

- (id)reverseTransformedValue:(id)aValue {
    if (![aValue isKindOfClass:[NSNumber class]]) return nil;
    float cmToPoints=28.3464567; // google
    float inchToPoints=72;
    return [NSNumber numberWithFloat:[aValue floatValue]*(S_isCm?cmToPoints:inchToPoints)];
}

@end
