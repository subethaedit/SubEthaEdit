//
//  ThousandSeparatorValueTransformer.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 28.09.07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import "ThousandSeparatorValueTransformer.h"


@implementation ThousandSeparatorValueTransformer
+ (Class)transformedValueClass {
    return [NSString class];
}

+ (BOOL)allowsReverseTransformation {
    return NO;   
}

- (id)transformedValue:(id)aValue {
    if (aValue == nil) return nil;
    return [NSString stringByAddingThousandSeparatorsToNumber:aValue];
}

@end
