//
//  NSNetServiceTCMAdditions.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Fri Feb 27 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "NSNetServiceTCMAdditions.h"


@implementation NSNetService (NSNetServiceTCMAdditions)
- (NSDictionary *)TXTRecordDictionary {
    NSMutableDictionary *result=[NSMutableDictionary dictionary];
    NSString *txtRecord=[self protocolSpecificInformation];
    NSArray *pairsArray=[txtRecord componentsSeparatedByString: @"\001"];
    NSEnumerator *pairs=[pairsArray objectEnumerator];
    NSString *pair;
    while ((pair = [pairs nextObject])) {
        NSRange foundRange=[pair rangeOfString:@"="];
        if (foundRange.location!=NSNotFound) {
            NSString *key = [[pair substringToIndex:foundRange.location] lowercaseString];
            NSString *value=[pair substringFromIndex:NSMaxRange(foundRange)];
            [result setObject:value forKey:key];
        }
    }
    return result;
}
@end
