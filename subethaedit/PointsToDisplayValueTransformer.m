//
//  PointsToDisplayValueTrasformer.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 16.09.04.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "PointsToDisplayValueTransformer.h"


@implementation PointsToDisplayValueTransformer

+ (Class)transformedValueClass {
    return [NSNumber class];
}

+ (BOOL)allowsReverseTransformation {
    return YES;   
}

- (id)transformedValue:(id)aValue {
    if (![aValue isKindOfClass:[NSNumber class]]) return nil;
    float cmToPoints=295.3/21.;
    return [NSNumber numberWithFloat:[aValue floatValue]/cmToPoints];
}

- (id)reverseTransformedValue:(id)aValue {
    if (![aValue isKindOfClass:[NSNumber class]]) return nil;
    float cmToPoints=295.3/21.;
    return [NSNumber numberWithFloat:[aValue floatValue]*cmToPoints];
}


@end
