//
//  TCMMMPresenceManager.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Fri Feb 27 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "TCMMMPresenceManager.h"
#import "TCMMMBEEPSessionManager.h"

static TCMMMPresenceManager *sharedInstance = nil;

@implementation TCMMMPresenceManager

+ (TCMMMPresenceManager *)sharedInstance {
    if (!sharedInstance) {
        sharedInstance = [self new];
    }
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    if (self) {
        I_statusOfUserIDs = [NSMutableDictionary new];
    }
    return self;
}

- (void)dealloc {
    [I_statusOfUserIDs release];
    [super dealloc];
}

- (void)statusConnectToNetService:(NSNetService *)aNetService userID:(NSString *)aUserID sender:(id)aSender
{
    NSMutableDictionary *statusOfUserID=[I_statusOfUserIDs objectForKey:aUserID];
    if (!statusOfUserID) {
        statusOfUserID=[NSMutableDictionary dictionary];
        [I_statusOfUserIDs setObject:statusOfUserID forKey:aUserID];
    }
    
    if ([statusOfUserID objectForKey:@"ConnectionAttempt"]) {
    
    } else {
        // machen
        [statusOfUserID setObject:aNetService forKey:@"NetService"];
        [statusOfUserID setObject:[NSNumber numberWithBool:YES] forKey:@"ConnectionAttempt"];
        [[TCMMMBEEPSessionManager sharedInstance] requestStatusProfileForUserID:aUserID netService:aNetService sender:self];
    }
}

#pragma mark -
#pragma mark ### TCMMMBEEPSessionManager callbacks ###

@end
