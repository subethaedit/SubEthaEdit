//  NSArraySEEAdditions.m
//  SubEthaEdit
//
//  Created by dom on 10/7/18.

#import "NSArraySEEAdditions.h"

@implementation NSArray (NSArraySEEAdditions)

- (id)SEE_firstObjectPassingTest:(BOOL (^)(id))test {
    __block id result;
    [self enumerateObjectsUsingBlock:^(id  _Nonnull object, NSUInteger _idx, BOOL *stop) {
        if (test(object)) {
            *stop = YES;
            result = object;
        }
    }];
    return result;
}


@end
