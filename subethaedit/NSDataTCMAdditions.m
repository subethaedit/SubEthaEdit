//
//  NSDataTCMAdditions.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Wed Apr 28 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "NSDataTCMAdditions.h"


@implementation NSData (NSDataTCMAdditions)

+ dataWithUUIDString:(NSString *)aUUIDString {
    if (aUUIDString!=nil) {
        CFUUIDRef uuid=CFUUIDCreateFromString(NULL,(CFStringRef)aUUIDString);
        CFUUIDBytes bytes=CFUUIDGetUUIDBytes(uuid);
        CFRelease(uuid);
        return [NSData dataWithBytes:&bytes length:sizeof(CFUUIDBytes)];
    } else {
        return nil;
    }
}

@end
