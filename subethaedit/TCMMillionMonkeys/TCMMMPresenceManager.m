//
//  TCMMMPresenceManager.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Fri Feb 27 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "TCMMMPresenceManager.h"
#import "TCMMMBEEPSessionManager.h"
#import "TCMMMStatusProfile.h"
#import "TCMMMUserManager.h"
#import "TCMMMUser.h"
#import "TCMMMSession.h"

static TCMMMPresenceManager *sharedInstance = nil;

NSString * const TCMMMPresenceManagerUserVisibilityDidChangeNotification=
               @"TCMMMPresenceManagerUserVisibilityDidChangeNotification";
NSString * const TCMMMPresenceManagerUserDidChangeNotification=
               @"TCMMMPresenceManagerUserDidChangeNotification";
NSString * const TCMMMPresenceManagerUserSessionsDidChangeNotification=
               @"TCMMMPresenceManagerUserSessionsDidChangeNotification";

@interface TCMMMPresenceManager (TCMMMPresenceManagerPrivateAdditions)

- (void)TCM_validateServiceAnnouncement;

@end

#pragma mark -

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
        I_statusProfilesInServerRole = [NSMutableSet new];
        I_announcedSessions = [NSMutableDictionary new];
        I_flags.serviceIsPublished=NO;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(TCM_didAcceptSession:) name:TCMMMBEEPSessionManagerDidAcceptSessionNotification object:[TCMMMBEEPSessionManager sharedInstance]]; 
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(TCM_didEndSession:) name:TCMMMBEEPSessionManagerSessionDidEndNotification object:[TCMMMBEEPSessionManager sharedInstance]]; 
    }
    return self;
}

- (void)dealloc 
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
    
    TCMMMUser *me=[[TCMMMUserManager sharedInstance] me];
    if ((I_flags.isVisible || [I_announcedSessions count]>0) && !I_flags.serviceIsPublished) {
        [I_netService setProtocolSpecificInformation:[NSString stringWithFormat:@"txtvers=1\001name=%@\001userid=%@\001version=2",[me name],[me ID]]];
        [I_netService publish];
        I_flags.serviceIsPublished = YES;
    } else if (!(I_flags.isVisible || [I_announcedSessions count]>0) && I_flags.serviceIsPublished){
        [I_netService stop];
    } else if (I_flags.serviceIsPublished) {
//      causes severe mDNSResponderCrash!
//        NSString *txtRecord=[NSString stringWithFormat:@"txtvers=1\001name=%@\001userid=%@\001docs=%d\001version=2",[me name],[me ID],[I_announcedSessions count]];
//        NSLog(@"Updating record with:%@",txtRecord);
//        [I_netService setProtocolSpecificInformation:txtRecord];
    }
}


- (void)setVisible:(BOOL)aFlag
{
    I_flags.isVisible = aFlag;
    [self TCM_validateServiceAnnouncement];
    NSEnumerator *profiles=[I_statusProfilesInServerRole objectEnumerator];
    TCMMMStatusProfile *profile=nil;
    while ((profile=[profiles nextObject])) {
        [profile sendVisibility:aFlag];
    }
}

- (NSMutableDictionary *)statusOfUserID:(NSString *)aUserID {
    NSMutableDictionary *statusOfUserID=[I_statusOfUserIDs objectForKey:aUserID];
    if (!statusOfUserID) {
        statusOfUserID=[NSMutableDictionary dictionary];
        [statusOfUserID setObject:@"NoStatus" forKey:@"Status"];
        [statusOfUserID setObject:aUserID     forKey:@"UserID"];
        [statusOfUserID setObject:[NSMutableDictionary dictionary] forKey:@"Sessions"];
        [I_statusOfUserIDs setObject:statusOfUserID forKey:aUserID];
    }
    return statusOfUserID;
}

- (NSDictionary *)announcedSessions {
    return I_announcedSessions;
}

- (void)announceSession:(TCMMMSession *)aSession {
    [I_announcedSessions setObject:aSession forKey:[aSession sessionID]];
    [self TCM_validateServiceAnnouncement];
    [I_statusProfilesInServerRole makeObjectsPerformSelector:@selector(announceSession:) withObject:aSession];
}

- (void)concealSession:(TCMMMSession *)aSession {
    [I_announcedSessions removeObjectForKey:[aSession sessionID]];
    [self TCM_validateServiceAnnouncement];
    [I_statusProfilesInServerRole makeObjectsPerformSelector:@selector(concealSession:) withObject:aSession];
}


#pragma mark -
#pragma mark ### TCMMMStatusProfile interaction

- (void)TCM_validateVisibilityOfUserID:(NSString *)aUserID {
    NSMutableDictionary *status=[self statusOfUserID:aUserID];
    BOOL currentVisibility=([status objectForKey:@"isVisible"]!=nil);
    BOOL newVisibility=(([status objectForKey:@"InternalIsVisible"]!=nil) || ([[status objectForKey:@"Sessions"] count] > 0));
    if (newVisibility!=currentVisibility) {
        if (newVisibility) {
            [status setObject:[NSNumber numberWithBool:YES] forKey:@"isVisible"];
        } else {
            [status removeObjectForKey:@"isVisible"];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:TCMMMPresenceManagerUserVisibilityDidChangeNotification object:self 
            userInfo:[NSDictionary dictionaryWithObjectsAndKeys:aUserID,@"UserID",[NSNumber numberWithBool:newVisibility],@"isVisible",nil]];
    }
}

- (void)sendInitialStatusViaProfile:(TCMMMStatusProfile *)aProfile {
    [aProfile sendMyself:[TCMMMUserManager me]];
    [aProfile sendVisibility:YES];
    NSEnumerator *sessions=[[self announcedSessions] objectEnumerator];
    TCMMMSession *session=nil;
    while ((session=[sessions nextObject])) {
        [aProfile announceSession:session];
    }
    NSLog(@"%@",[[TCMMMBEEPSessionManager sharedInstance] description]);
}

- (void)profile:(TCMMMStatusProfile *)aProfile didReceiveUser:(TCMMMUser *)aUser {
    [[TCMMMUserManager sharedInstance] setUser:aUser forID:[aUser ID]];
}

- (void)profile:(TCMMMStatusProfile *)aProfile didReceiveVisibilityChange:(BOOL)isVisible {
    NSString *userID=[[[aProfile session] userInfo] objectForKey:@"peerUserID"];
    NSMutableDictionary *status=[self statusOfUserID:userID];
    if (isVisible) {
        [status setObject:[NSNumber numberWithBool:YES] forKey:@"InternalIsVisible"];
    } else {
        [status removeObjectForKey:@"InternalIsVisible"];
    }
    [self TCM_validateVisibilityOfUserID:userID];
}

- (void)profile:(TCMMMStatusProfile *)aProfile didReceiveAnnouncedSession:(TCMMMSession *)aSession
{
    DEBUGLOG(@"Presence",5,@"didReceiveAnnouncedSession: %@",[aSession description]);
    NSString *userID=[[[aProfile session] userInfo] objectForKey:@"peerUserID"];
    NSMutableDictionary *status=[self statusOfUserID:userID];
    NSMutableDictionary *sessions=[status objectForKey:@"Sessions"];
    // TODO: merge session if already existing session is here
    [sessions setObject:aSession forKey:[aSession sessionID]];
    [self TCM_validateVisibilityOfUserID:userID];
    NSMutableDictionary *userInfo=[NSMutableDictionary dictionaryWithObjectsAndKeys:userID,@"UserID",sessions,@"Sessions",nil];
    [userInfo setObject:aSession forKey:@"AnnouncedSession"];
    [[NSNotificationCenter defaultCenter] postNotificationName:TCMMMPresenceManagerUserSessionsDidChangeNotification object:self 
            userInfo:userInfo];
}

- (void)profile:(TCMMMStatusProfile *)aProfile didReceiveConcealedSessionID:(NSString *)anID
{
    DEBUGLOG(@"Presence",5,@"didReceiveConcealSessionID: %@",anID);
    NSString *userID=[[[aProfile session] userInfo] objectForKey:@"peerUserID"];
    NSMutableDictionary *status=[self statusOfUserID:userID];
    NSMutableDictionary *sessions=[status objectForKey:@"Sessions"];
    [sessions removeObjectForKey:anID];
    NSMutableDictionary *userInfo=[NSMutableDictionary dictionaryWithObjectsAndKeys:userID,@"UserID",sessions,@"Sessions",nil];
    [userInfo setObject:anID forKey:@"ConcealedSessionID"];
    [[NSNotificationCenter defaultCenter] postNotificationName:TCMMMPresenceManagerUserSessionsDidChangeNotification object:self 
            userInfo:userInfo];
    [self TCM_validateVisibilityOfUserID:userID];
}

- (void)profile:(TCMBEEPProfile *)aProfile didFailWithError:(NSError *)anError {
    // remove status profile, and inform the rest
    NSString *userID=[[[aProfile session] userInfo] objectForKey:@"peerUserID"];
    NSMutableDictionary *status=[self statusOfUserID:userID];
    [status removeObjectForKey:@"StatusProfile"];
    [status setObject:@"NoStatus" forKey:@"Status"];
    [status setObject:[NSMutableDictionary dictionary] forKey:@"Sessions"];
    [I_statusProfilesInServerRole removeObject:aProfile];
    [aProfile setDelegate:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:TCMMMPresenceManagerUserSessionsDidChangeNotification object:self 
            userInfo:[NSDictionary dictionaryWithObjectsAndKeys:userID,@"UserID",[status objectForKey:@"Sessions"],@"Sessions",nil]];
    [self TCM_validateVisibilityOfUserID:userID];
}

#pragma mark -
#pragma mark ### TCMMMBEEPSessionManager callbacks ###

- (void)acceptStatusProfile:(TCMMMStatusProfile *)aProfile {
    NSLog(@"acceptStatusProfile!");
    [aProfile setDelegate:self];
    if ([aProfile isServer]) {
        [self sendInitialStatusViaProfile:aProfile];
        [I_statusProfilesInServerRole addObject:aProfile];
    } else {
        NSLog(@"mist: nicht server");
    }
}

#pragma mark -
- (void)TCM_didAcceptSession:(NSNotification *)aNotification 
{
    TCMBEEPSession *session=[[aNotification userInfo] objectForKey:@"Session"];
    NSString *userID=[[session userInfo] objectForKey:@"peerUserID"];
    NSMutableDictionary *statusOfUserID=[self statusOfUserID:userID];
    if ([[statusOfUserID objectForKey:@"Status"] isEqualToString:@"NoStatus"]) {
        NSLog(@"starting StatusProfile with: %@",userID);
        [session startChannelWithProfileURIs:[NSArray arrayWithObject:@"http://www.codingmonkeys.de/BEEP/TCMMMStatus"] andData:nil sender:self];
    }
    
}

- (void)TCM_didEndSession:(NSNotification *)aNotification 
{
//    TCMBEEPSession *session=[[aNotification userInfo] objectForKey:@"Session"];
    
}

- (void)BEEPSession:(TCMBEEPSession *)aBEEPSession didOpenChannelWithProfile:(TCMBEEPProfile *)aProfile 
{
    NSLog(@"Got status Channel!");
    NSString *userID=[[[aProfile session] userInfo] objectForKey:@"peerUserID"];
    [aProfile setDelegate:self];
    NSMutableDictionary *statusOfUserID=[self statusOfUserID:userID];
    
    if ([[statusOfUserID objectForKey:@"Status"] isEqualToString:@"GotStatus"]) {
        NSLog(@"Got status profile albeit having one for User: %@",userID);
    } else {
        NSLog(@"Got status profile without trying to connect to User: %@",userID);
    }
    [statusOfUserID setObject:@"GotStatus" forKey:@"Status"];
    [statusOfUserID setObject:aProfile forKey:@"StatusProfile"];
}
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
