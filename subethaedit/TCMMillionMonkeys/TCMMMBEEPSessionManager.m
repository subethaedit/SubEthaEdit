//
//  TCMMMBEEPSessionManager.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Fri Feb 27 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "TCMMMBEEPSessionManager.h"
#import "TCMBEEPListener.h"
#import "TCMBEEPSession.h"
#import "TCMBEEPChannel.h"
#import "TCMMMUserManager.h"
#import "HandshakeProfile.h"


#define PORTRANGESTART 12347
#define PORTRANGELENGTH 10

static NSString *kBEEPSessionStatusNoSession =@"NoSession";
static NSString *kBEEPSessionStatusGotSession=@"GotSession";
static NSString *kBEEPSessionStatusConnecting=@"Connecting";


static TCMMMBEEPSessionManager *sharedInstance;

@interface TCMMMBEEPSessionManager (TCMMMBEEPSessionManagerPrivateAdditions)

- (void)TCM_connectToNetServiceWithInformation:(NSMutableDictionary *)aInformation;

@end


@implementation TCMMMBEEPSessionManager

+ (TCMMMBEEPSessionManager *)sharedInstance
{
    if (!sharedInstance) {
        sharedInstance = [self new];
    }
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    if (self) {
        I_sessionInformationByUserID    =[NSMutableDictionary new];
        I_pendingProfileRequestsByUserID=[NSMutableDictionary new];
        I_pendingSessions               =[NSMutableSet new];
    }
    return self;
}

- (void)dealloc {
    [I_listener close];
    [I_listener release];
    [I_sessionInformationByUserID     release];
    [I_pendingProfileRequestsByUserID release];
    [I_pendingSessions release];
    [super dealloc];
}

- (BOOL)listen {
    // set up BEEPListener
    for (I_listeningPort=PORTRANGESTART;I_listeningPort<PORTRANGESTART+PORTRANGELENGTH;I_listeningPort++) {
        I_listener=[[TCMBEEPListener alloc] initWithPort:I_listeningPort];
        [I_listener setDelegate:self];
        if ([I_listener listen]) {
            DEBUGLOG(@"Application",3,@"Listening on Port: %d",I_listeningPort);
            break;
        } else {
            [I_listener release];
            I_listener=nil;
        }
    }
    return (I_listener!=nil);
}

- (int)listeningPort {
    return I_listeningPort;
}

- (NSMutableDictionary *)sessionInformationForUserID:(NSString *)aUserID {
    NSMutableDictionary *sessionInformation=[I_sessionInformationByUserID objectForKey:aUserID];
    if (!sessionInformation) {
        sessionInformation=[NSMutableDictionary dictionary];
        [I_sessionInformationByUserID setObject:sessionInformation forKey:aUserID];
        [sessionInformation setObject:kBEEPSessionStatusNoSession forKey:@"Status"];
        [sessionInformation setObject:aUserID forKey:@"peerUserID"];
    }
    return sessionInformation;
}

- (void)requestStatusProfileForUserID:(NSString *)aUserID netService:(NSNetService *)aNetService sender:(id)aSender {
    NSMutableArray *profileRequests=[I_pendingProfileRequestsByUserID objectForKey:aUserID];
    if (!profileRequests) {
        profileRequests=[NSMutableArray array];
        [I_pendingProfileRequestsByUserID setObject:profileRequests forKey:aUserID];
    }
    
    NSMutableDictionary *request=[NSMutableDictionary dictionary];
    [request setObject:aSender forKey:@"Sender"];
    [request setObject:@"statusProfile" forKey:@"Profile"];
    
    [profileRequests addObject:request];
    
    NSMutableDictionary *sessionInformation=[self sessionInformationForUserID:aUserID];
    NSString *status=[sessionInformation objectForKey:@"Status"];
    if ([status isEqualToString:kBEEPSessionStatusNoSession]) {
        [sessionInformation setObject:aNetService forKey:@"NetService"];
        [sessionInformation setObject:kBEEPSessionStatusConnecting forKey:@"Status"];
        [self TCM_connectToNetServiceWithInformation:sessionInformation];
    } else {
//        TCMBEEPSession *session=[sessionInformation objectForKey:@"Session"];
    }
}

- (void)TCM_connectToNetServiceWithInformation:(NSMutableDictionary *)aInformation {
    NSNetService *service=[aInformation objectForKey:@"NetService"];
    NSArray *addresses=[service addresses]; 
    NSMutableArray *outgoingSessions=[aInformation objectForKey:@"outgoingSessions"];
    if (!outgoingSessions) {
        outgoingSessions=[NSMutableArray array];
        [aInformation setObject:outgoingSessions forKey:@"outgoingSessions"];
    }
    int i;
    for (i=0;i<[addresses count];i++) {
        NSData *addressData=[addresses objectAtIndex:i];
        TCMBEEPSession *session = [[TCMBEEPSession alloc] initWithAddressData:addressData];
        [I_pendingSessions addObject:session];
        [outgoingSessions  addObject:session];
        [session setUserInfo:[NSDictionary dictionaryWithObject:[aInformation objectForKey:@"peerUserID"] forKey:@"peerUserID"]];
        [session setProfileURIs:[NSArray arrayWithObjects:@"http://www.codingmonkeys.de/BEEP/SubEthaEditHandshake", nil]];
        [session setDelegate:self];
        [session open];
    }
    [aInformation setObject:[NSNumber numberWithInt:i] forKey:@"TriedNetServiceAddresses"];
}

#pragma mark -

- (void)BEEPSession:(TCMBEEPSession *)aBEEPSession didReceiveGreetingWithProfileURIs:(NSArray *)aProfileURIArray
{
    if (![I_pendingSessions containsObject:aBEEPSession]) {
        NSLog(@"didReceiveGreeting for non-pending session");
        return;
    }
    
    if ([[aBEEPSession peerProfileURIs] containsObject:@"http://www.codingmonkeys.de/BEEP/SubEthaEditHandshake"]) {
        if ([aBEEPSession isInitiator]) {
            [aBEEPSession startChannelWithProfileURIs:[NSArray arrayWithObject:@"http://www.codingmonkeys.de/BEEP/SubEthaEditHandshake"] andData:nil];
        }
    } else {
        [aBEEPSession close];
        NSString *aUserID=[[aBEEPSession userInfo] objectForKey:@"peerUserID"];
        if ([aBEEPSession isInitiator] && aUserID) {
            NSMutableDictionary *information=[self sessionInformationForUserID:aUserID];
            [[information objectForKey:@"outgoingSessions"] removeObject:aBEEPSession];
        }
        [I_pendingSessions removeObject:aBEEPSession];
    }
}

- (NSMutableDictionary *)BEEPSession:(TCMBEEPSession *)aBEEPSession willSendReply:(NSMutableDictionary *)aReply forChannelRequests:(NSArray *)aRequests
{
    return aReply;
}

- (void)BEEPSession:(TCMBEEPSession *)aBEEPSession didOpenChannelWithProfile:(TCMBEEPProfile *)aProfile
{
    [aProfile setDelegate:self];
    if (![[aProfile channel] isServer]) {
        NSString *aUserID=[[aBEEPSession userInfo] objectForKey:@"peerUserID"];
        NSMutableDictionary *information=[self sessionInformationForUserID:aUserID];
        if (![information objectForKey:@"sentGreetingOutgoingSession"]) { 
            [information setObject:aBEEPSession forKey:@"sentGreetingOutgoingSession"];
            [(HandshakeProfile *)aProfile shakeHandsWithUserID:[TCMMMUserManager myID]];
        }
    }
}

#pragma mark -
#pragma mark ### HandshakeProfile delegate methods ###

- (NSString *)profile:(HandshakeProfile *)aProfile shouldProceedHandshakeWithUserID:(NSString *)aUserID {
    NSMutableDictionary *information=[self sessionInformationForUserID:aUserID];
    if ([[information objectForKey:@"Status"] isEqualTo:kBEEPSessionStatusGotSession]) {
        return nil;
    } else if ([[information objectForKey:@"Status"] isEqualTo:kBEEPSessionStatusNoSession]) {
        if ([[[aProfile channel] session] isInitiator]) {
            return nil;
        } else {
            NSMutableArray *inboundSessions=[information objectForKey:@"inboundSessions"];
            if (!inboundSessions) {
                inboundSessions=[NSMutableArray array];
                [information setObject:inboundSessions forKey:@"inboundSessions"];
            }
            [inboundSessions addObject:[[aProfile channel] session]];
            [information setObject:kBEEPSessionStatusConnecting forKey:@"Status"];
            return [TCMMMUserManager myID];
        }
    } else if ([[information objectForKey:@"Status"] isEqualTo:kBEEPSessionStatusConnecting]) {
        return [TCMMMUserManager myID]; // preliminary
    }
    
    return nil; // should not happen
}
- (BOOL)profile:(HandshakeProfile *)aProfile shouldAckHandshakeWithUserID:(NSString *)aUserID {
    return YES;
}
- (void)profile:(HandshakeProfile *)aProfile didAckandshakeWithUserID:(NSString *)aUserID {

}


- (void)profile:(HandshakeProfile *)aProfile didReceiveHandshakeWithUserID:(NSString *)aUserID andInformation:(NSDictionary *)aInfo
{
    NSLog(@"receivedHandshake: %@, %@",aUserID,aInfo);
    // [I_pendingSessions removeObject:aBEEPSession];
    NSMutableDictionary *sessionInformation=[self sessionInformationForUserID:aUserID];
    [sessionInformation setObject:[[aProfile channel] session] forKey:@"Session"];
    [sessionInformation setObject:@"Session" forKey:@"Session"];
}

#pragma mark -
#pragma mark ### BEEPListener delegate ###

- (BOOL)BEEPListener:(TCMBEEPListener *)aBEEPListener shouldAcceptBEEPSession:(TCMBEEPSession *)aBEEPSession
{
    DEBUGLOG(@"Application", 3, @"somebody talks to our listener: %@", [aBEEPSession description]);
    return YES;
}

- (void)BEEPListener:(TCMBEEPListener *)aBEEPListener didAcceptBEEPSession:(TCMBEEPSession *)aBEEPSession
{
    NSLog(@"Got Session %@", aBEEPSession);
    [aBEEPSession setProfileURIs:[NSArray arrayWithObject:@"http://www.codingmonkeys.de/BEEP/SubEthaEditHandshake"]];
    [aBEEPSession setDelegate:self];
    [aBEEPSession open];
    [I_pendingSessions addObject:aBEEPSession];
}

@end
