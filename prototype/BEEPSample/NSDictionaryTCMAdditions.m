//
//  NSDictionaryTCMAdditions.m
//  BEEPSample
//
//  Created by Martin Ott on Wed Feb 18 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "NSDictionaryTCMAdditions.h"


@implementation NSDictionary (NSDictionaryTCMAdditions)
-(id)objectForLong:(long)aLong {
    return [self objectForKey:[NSNumber numberWithLong:aLong]];
}
@end


@implementation NSMutableDictionary (NSDictionaryTCMAdditions)
-(void)setObject:(id)aObject forLong:(long)aLong {
    [self setObject:aObject forKey:[NSNumber numberWithLong:aLong]];
}

- (void)removeObjectForLong:(long)aLong
{
    [self removeObjectForKey:[NSNumber numberWithLong:aLong]];
}

@end

