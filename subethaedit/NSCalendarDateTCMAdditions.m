//
//  NSCalendarDateTCMAdditions.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 21.09.04.
//  Copyright 2004 TheCodingMonkeys. All rights reserved.
//

#import "NSCalendarDateTCMAdditions.h"


@implementation NSCalendarDate (NSCalendarDateTCMAdditions)

- (NSString *)rfc1123Representation {
    NSTimeZone *oldTimeZone=[self timeZone];
    [self setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    NSString *result=[self descriptionWithCalendarFormat:@"%a, %d %b %Y %H:%M:%S GMT"];
    [self setTimeZone:oldTimeZone];
    return result;
}


@end
