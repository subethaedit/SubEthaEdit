//
//  TCMMMOperation.m
//  SubEthaEdit
//
//  Created by Martin Ott on Fri Mar 19 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "TCMMMOperation.h"

NSString * const TCMMMOperationTypeKey = @"ot";

static NSMutableDictionary *sClassForOperationTypeDictionary;

@implementation TCMMMOperation

+ (void)registerClass:(Class)aClass forOperationType:(NSString *)aType {
    if (!sClassForOperationTypeDictionary) {
        sClassForOperationTypeDictionary = [NSMutableDictionary new];
    }
    [sClassForOperationTypeDictionary setObject:aClass forKey:aType];
}

+ (id)operationWithDictionaryRepresentation:(NSDictionary *)aDictionary {
    Class class = [sClassForOperationTypeDictionary objectForKey:[aDictionary objectForKey:TCMMMOperationTypeKey]];
    return [[[class alloc] initWithDictionaryRepresentation:aDictionary] autorelease];
}

+ (NSString *)operationID {
    return @"nil";
}

- (id)initWithDictionaryRepresentation:(NSDictionary *)aDictionary {
    return [super init];
}

- (id)copyWithZone:(NSZone *)zone {
    TCMMMOperation *copy = [[[self class] allocWithZone:zone] init];
    return copy;
}

- (NSDictionary *)dictionaryRepresentation {
    return nil;
}

- (NSString *)operationID {
    return [[self class] operationID];
}

@end
