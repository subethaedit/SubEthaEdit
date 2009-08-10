//
//  TCMMMNoOperation.m
//  SubEthaEdit
//
//  Created by Martin Ott on Wed May 12 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "TCMMMNoOperation.h"


@implementation TCMMMNoOperation

+ (void)initialize {
	if (self == [TCMMMNoOperation class]) {
	    [TCMMMOperation registerClass:self forOperationType:[self operationID]];
	}
}

+ (NSString *)operationID {
    return @"nop";
}

- (NSString *)description {
    return NSStringFromClass([self class]);
}

@end
