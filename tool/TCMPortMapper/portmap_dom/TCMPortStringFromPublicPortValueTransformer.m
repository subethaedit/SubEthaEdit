//
//  TCMPortStringFromPublicPortValueTransformer.m
//  Port Map
//
//  Created by Dominik Wagner on 05.02.08.
//  Copyright 2008 TheCodingMonkeys. All rights reserved.
//

#import "TCMPortStringFromPublicPortValueTransformer.h"


@implementation TCMPortStringFromPublicPortValueTransformer
+ (Class)transformedValueClass {
    return [NSString class];
}

- (id)transformedValue:(id)value {
    if ([value isKindOfClass:[NSNumber class]]) {
        switch([value intValue]) {
            case 0: return NSLocalizedString(@"unmapped",@"");
            default: return [NSString stringWithFormat:@"%d",[value intValue]];
        }
    } else {
        return @"NaN";
    }
}

@end
