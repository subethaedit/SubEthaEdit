//  NSArraySEEAdditions.h
//  SubEthaEdit
//
//  Created by dom on 10/7/18.

@import Foundation;

@interface NSArray (NSArraySEEAdditions)

- (id)SEE_firstObjectPassingTest:(BOOL (^)(id))test;

@end

