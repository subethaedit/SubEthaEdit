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
    NSMutableArray *I_addresses;
}

+ (TCMHost *)hostWithName:(NSString *)name;

- (id)initWithName:(NSString *)name;

- (void)setDelegate:(id)delegate;
- (id)delegate;

- (NSArray *)addresses;

- (void)checkReachability;
- (void)resolve;

@end


@interface NSObject (TCMHostDelegateAdditions)

- (void)host:(TCMHost *)sender didNotResolve:(NSError *)error;
- (void)hostDidResolveAddress:(TCMHost *)sender;

@end