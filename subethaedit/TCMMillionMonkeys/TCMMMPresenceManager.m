//
//  TCMMMPresenceManager.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Fri Feb 27 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "TCMMMPresenceManager.h"
#import "TCMMMBEEPSessionManager.h"
#import "TCMMMUserManager.h"
#import "TCMMMUser.h"

static TCMMMPresenceManager *sharedInstance = nil;

@interface TCMMMPresenceManager (TCMMMPresenceManagerPrivateAdditions)

- (void)TCM_validateServiceAnnouncement;

@end

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
        I_flags.serviceIsPublished=NO;
    }
    return self;
}

- (void)dealloc {
    [I_statusOfUserIDs release];
    [I_netService release];
    [super dealloc];
}

- (void)TCM_validateServiceAnnouncement {
    // Announce ourselves via rendezvous
    if (!I_netService) {
        I_netService=[[NSNetService alloc] initWithDomain:@"" type:@"_emac._tcp." name:@"" port:[[TCMMMBEEPSessionManager sharedInstance] listeningPort]];
        [I_netService setDelegate:self];
    }
    
    if (I_flags.isVisible && !I_flags.serviceIsPublished) {
        TCMMMUser *me=[[TCMMMUserManager sharedInstance] me];
        [I_netService setProtocolSpecificInformation:[NSString stringWithFormat:@"txtvers=1\001name=%@\001userid=%@\001version=2",[me name],[me ID]]];
        [I_netService publish];
        I_flags.serviceIsPublished = YES;
    } else if (!I_flags.isVisible && I_flags.serviceIsPublished){
        [I_netService stop];
    }
}


- (void)setVisible:(BOOL)aFlag
{
    I_flags.isVisible = aFlag;
    [self TCM_validateServiceAnnouncement];
}

- (void)statusConnectToNetService:(NSNetService *)aNetService userID:(NSString *)aUserID sender:(id)aSender
{
    DEBUGLOG(@"Presence",5,@"netservice: %@",aNetService);
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


#pragma mark -
#pragma mark ### Published NetService Delegate ###

// Error handling code
- (void)handleError:(NSNumber *)error withService:(NSNetService *)service
{
    NSLog(@"An error occurred with service %@.%@.%@, error code = %@",
        [service name], [service type], [service domain], error);
    // Handle error here
}

// Sent when the service is about to publish
- (void)netServiceWillPublish:(NSNetService *)netService
{
    DEBUGLOG(@"Network", 3, @"netServiceWillPublish: %@",netService);
    // You may want to do something here, such as updating a user interface
}


// Sent if publication fails
- (void)netService:(NSNetService *)netService
        didNotPublish:(NSDictionary *)errorDict
{
    I_flags.serviceIsPublished=NO;
    [self handleError:[errorDict objectForKey:NSNetServicesErrorCode] withService:netService];
}


// Sent when the service stops
- (void)netServiceDidStop:(NSNetService *)netService
{
    I_flags.serviceIsPublished=NO;
    DEBUGLOG(@"Network", 3, @"netServiceDidStop: %@", netService);
    // You may want to do something here, such as updating a user interface
}

@end
