//
//  TCMHost.h
//  SubEthaEdit
//
//  Created by Martin Ott on Wed Mar 03 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface TCMHost : NSObject
{
    id I_delegate;
    CFHostRef I_host;
    NSString *I_name;
    unsigned short I_port;
    NSMutableArray *I_addresses;
    NSDictionary *I_userInfo;
}

+ (TCMHost *)hostWithName:(NSString *)name port:(unsigned short)port userInfo:(NSDictionary *)userInfo;

- (id)initWithName:(NSString *)name port:(unsigned short)port userInfo:(NSDictionary *)userInfo;

- (void)setDelegate:(id)delegate;
- (id)delegate;

- (NSArray *)addresses;
- (NSString *)name;
- (NSDictionary *)userInfo;

- (void)checkReachability;
- (void)resolve;

@end


@interface NSObject (TCMHostDelegateAdditions)

- (void)host:(TCMHost *)sender didNotResolve:(NSError *)error;
- (void)hostDidResolveAddress:(TCMHost *)sender;

@end