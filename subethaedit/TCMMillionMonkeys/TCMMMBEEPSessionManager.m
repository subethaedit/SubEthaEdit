//
//  TCMMMBEEPSessionManager.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Fri Feb 27 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "TCMMMBEEPSessionManager.h"
#import "TCMMMPresenceManager.h"
#import "TCMBEEPListener.h"
#import "TCMBEEPSession.h"
#import "TCMBEEPChannel.h"
#import "TCMMMUserManager.h"
#import "TCMMMSession.h"
#import "TCMHost.h"
#import "HandshakeProfile.h"
#import "SessionProfile.h"

#define PORTRANGESTART 12347
#define PORTRANGELENGTH 10

static NSString *kBEEPSessionStatusNoSession =@"NoSession";
static NSString *kBEEPSessionStatusGotSession=@"GotSession";
static NSString *kBEEPSessionStatusConnecting=@"Connecting";


NSString * const TCMMMBEEPSessionManagerDidAcceptSessionNotification = 
               @"TCMMMBEEPSessionManagerDidAcceptSessionNotification";
NSString * const TCMMMBEEPSessionManagerSessionDidEndNotification = 
               @"TCMMMBEEPSessionManagerSessionDidEndNotification";
NSString * const TCMMMBEEPSessionManagerConnectToHostDidFailNotification = 
               @"TCMMMBEEPSessionManagerConnectToHostDidFailNotification";

/*
    SessionInformation:
        @"RendezvousStatus" => kBEEPSessionStatusNoSession | kBEEPSessionStatusGotSession | kBEEPSessionStatusConnecting
        @"OutgoingRendezvousSessions" => NSArray with Session Attempts
        @"RendezvousSession" => successfully connected rendezvous session
        @"NetService" => NSNetService
        @"TriedNetServiceAddresses" => NSNumber up to how many addresses of the netservice have been tried
        @"InboundRendezvousSession" => RendezvousSession that came from listener
        @"OutboundSessions" => Active Outbound Internet Sessions 
        @"InboundSessions"  => Active Inbound Internet Sessions
*/


static TCMMMBEEPSessionManager *sharedInstance;

@interface TCMMMBEEPSessionManager (TCMMMBEEPSessionManagerPrivateAdditions)

- (void)TCM_connectToNetServiceWithInformation:(NSMutableDictionary *)aInformation;
- (void)TCM_sendDidAcceptNotificationForSession:(TCMBEEPSession *)aSession;
- (void)TCM_sendDidEndNotificationForSession:(TCMBEEPSession *)aSession error:(NSError *)anError;


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
        I_sessionInformationByUserID = [NSMutableDictionary new];
        I_pendingSessionProfiles = [NSMutableSet new];
        I_pendingSessions = [NSMutableSet new];
        I_pendingOutboundSessions = [NSMutableDictionary new];
    }
    return self;
}

- (void)dealloc
{
    [I_listener close];
    [I_listener release];
    [I_sessionInformationByUserID release];
    [I_pendingSessionProfiles release];
    [I_pendingSessions release];
    [I_pendingOutboundSessions release];
    [super dealloc];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"BEEPSessionManager sessionInformation:%@\npendingSessionProfiles:%@\npendingSessions:%@\npendingOutboundSessions:%@",[I_sessionInformationByUserID descriptionInStringsFileFormat],[I_pendingSessionProfiles description],[I_pendingSessions description],[I_pendingOutboundSessions description]];
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
        [sessionInformation setObject:kBEEPSessionStatusNoSession forKey:@"RendezvousStatus"];
        [sessionInformation setObject:aUserID forKey:@"peerUserID"];
        [sessionInformation setObject:[NSMutableArray array] forKey:@"InboundSessions"];
        [sessionInformation setObject:[NSMutableArray array] forKey:@"OutboundSessions"];
    }
    return sessionInformation;
}

- (void)TCM_connectToNetServiceWithInformation:(NSMutableDictionary *)aInformation {
    NSNetService *service=[aInformation objectForKey:@"NetService"];
    NSArray *addresses=[service addresses]; 
    NSMutableArray *outgoingSessions=[aInformation objectForKey:@"OutgoingRendezvousSessions"];
    if (!outgoingSessions) {
        outgoingSessions=[NSMutableArray array];
        [aInformation setObject:outgoingSessions forKey:@"OutgoingRendezvousSessions"];
    }
    int i;
    for (i=0;i<[addresses count];i++) {
        NSData *addressData=[addresses objectAtIndex:i];
        TCMBEEPSession *session = [[TCMBEEPSession alloc] initWithAddressData:addressData];
        [outgoingSessions  addObject:session];
        [[session userInfo] setObject:[aInformation objectForKey:@"peerUserID"] forKey:@"peerUserID"];
        [[session userInfo] setObject:[NSNumber numberWithBool:YES] forKey:@"isRendezvous"];
        [session setProfileURIs:[NSArray arrayWithObjects:@"http://www.codingmonkeys.de/BEEP/SubEthaEditSession", @"http://www.codingmonkeys.de/BEEP/SubEthaEditHandshake", @"http://www.codingmonkeys.de/BEEP/TCMMMStatus", nil]];
        [session setDelegate:self];
        [session open];
    }
    [aInformation setObject:[NSNumber numberWithInt:i] forKey:@"TriedNetServiceAddresses"];
}

- (void)connectToNetService:(NSNetService *)aNetService {

    NSString *userID=[[aNetService TXTRecordDictionary] objectForKey:@"userid"];

    NSMutableDictionary *sessionInformation=[self sessionInformationForUserID:userID];
    NSString *status=[sessionInformation objectForKey:@"RendezvousStatus"];
    if ([status isEqualToString:kBEEPSessionStatusNoSession]) {
        [sessionInformation setObject:aNetService forKey:@"NetService"];
        [sessionInformation setObject:kBEEPSessionStatusConnecting forKey:@"RendezvousStatus"];
        [self TCM_connectToNetServiceWithInformation:sessionInformation];
    } else {
//        TCMBEEPSession *session=[sessionInformation objectForKey:@"RendezvousSession"];
    }
}

- (void)connectToHost:(TCMHost *)aHost
{
    NSLog(@"connectToHost:");

/*
    pendingOutboundSessions {
        <hostname> => {
            "host" => TCMHost
            "sessions" = NSMutableSet
        }
    }
*/
    NSMutableDictionary *infoDict = [NSMutableDictionary dictionary];
    [infoDict setObject:aHost forKey:@"host"];
    
    NSMutableSet *sessions = [NSMutableSet set];
    [infoDict setObject:sessions forKey:@"host"];
    
    [I_pendingOutboundSessions setObject:infoDict forKey:[aHost name]];
    
    NSEnumerator *addresses = [[aHost addresses] objectEnumerator];
    NSData *addressData;
    while ((addressData = [addresses nextObject])) {
        TCMBEEPSession *session = [[TCMBEEPSession alloc] initWithAddressData:addressData];
        [[session userInfo] setObject:[aHost name] forKey:@"name"];
        [sessions addObject:session];
        [session setProfileURIs:[NSArray arrayWithObjects:@"http://www.codingmonkeys.de/BEEP/SubEthaEditSession", @"http://www.codingmonkeys.de/BEEP/SubEthaEditHandshake", @"http://www.codingmonkeys.de/BEEP/TCMMMStatus", nil]];
        [session setDelegate:self];
        [session open];
    }
}

- (TCMBEEPSession *)sessionForUserID:(NSString *)aUserID
{
    NSDictionary *sessionInfo = [I_sessionInformationByUserID objectForKey:aUserID];
    NSLog(@"sessionInfo: %@", sessionInfo);
    return [sessionInfo objectForKey:@"RendezvousSession"];
}

#pragma mark -

- (void)BEEPSession:(TCMBEEPSession *)aBEEPSession didReceiveGreetingWithProfileURIs:(NSArray *)aProfileURIArray
{
    if ([[aBEEPSession peerProfileURIs] containsObject:@"http://www.codingmonkeys.de/BEEP/SubEthaEditHandshake"]) {
        if ([aBEEPSession isInitiator]) {
            if ([[aBEEPSession userInfo] objectForKey:@"isRendezvous"]) {
                NSString *aUserID=[[aBEEPSession userInfo] objectForKey:@"peerUserID"];
                NSMutableDictionary *sessionInformation=[self sessionInformationForUserID:aUserID];
                if ([sessionInformation objectForKey:@"NetService"]) {
                    // rendezvous: close all other sessions
                    NSMutableArray *outgoingSessions=[sessionInformation objectForKey:@"OutgoingRendezvousSessions"];
                    TCMBEEPSession *session;
                    while ((session=[outgoingSessions lastObject])) {
                        [[session retain] autorelease];
                        [outgoingSessions removeObjectAtIndex:[outgoingSessions count]-1];
                        if (session==aBEEPSession) {
                            [sessionInformation setObject:session forKey:@"RendezvousSession"];
                        } else {
                            [session setDelegate:nil];
                            [session close];
                        }
                    }
                }
            } else {
                NSString *name = [[aBEEPSession userInfo] objectForKey:@"name"];
                NSDictionary *info = [I_pendingOutboundSessions objectForKey:name];
                NSMutableArray *sessions = [info objectForKey:@"sessions"];
                TCMBEEPSession *session;
                while ((session = [sessions lastObject])) {
                    if (session != aBEEPSession) {
                        [[session retain] autorelease];
                        [session setDelegate:nil];
                        [session close];
                    }
                }
            }
            [aBEEPSession startChannelWithProfileURIs:[NSArray arrayWithObject:@"http://www.codingmonkeys.de/BEEP/SubEthaEditHandshake"] andData:nil sender:self];
        }
    } else {
        [aBEEPSession setDelegate:nil];
        [aBEEPSession close];
        
        if ([[aBEEPSession userInfo] objectForKey:@"isRendezvous"]) {
            NSString *aUserID=[[aBEEPSession userInfo] objectForKey:@"peerUserID"];
            if ([aBEEPSession isInitiator] && aUserID) {
                NSMutableDictionary *information=[self sessionInformationForUserID:aUserID];
                [[information objectForKey:@"OutgoingRendezvousSessions"] removeObject:aBEEPSession];
            }
        } else {
            if ([aBEEPSession isInitiator]) {
                NSString *name = [[aBEEPSession userInfo] objectForKey:@"name"];
                NSDictionary *info = [I_pendingOutboundSessions objectForKey:name];
                [[info objectForKey:@"sessions"] removeObject:aBEEPSession];
            }
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
    if ([[aProfile profileURI] isEqualToString:@"http://www.codingmonkeys.de/BEEP/SubEthaEditHandshake"]) {
        [aProfile setDelegate:self];
        if (![aProfile isServer]) {
            if ([[aBEEPSession userInfo] objectForKey:@"isRendezvous"]) {
                NSString *aUserID=[[aBEEPSession userInfo] objectForKey:@"peerUserID"];
                NSMutableDictionary *information=[self sessionInformationForUserID:aUserID];
                if ([[information objectForKey:@"OutgoingRendezvousSessions"] count]) {
                    NSLog(@"Can't happen");
                }
            } else {
                // Do something here for internet sessions
            }
            [(HandshakeProfile *)aProfile shakeHandsWithUserID:[TCMMMUserManager myID]];
        }
    } else if ([[aProfile profileURI] isEqualToString:@"http://www.codingmonkeys.de/BEEP/TCMMMStatus"]) {
        [[TCMMMPresenceManager sharedInstance] acceptStatusProfile:(TCMMMStatusProfile *)aProfile];
        if ([aProfile isServer]) {
            // distribute the profile to the corresponding handler
        } else {
            // find the open request
        }
    } else if ([[aProfile profileURI] isEqualToString:@"http://www.codingmonkeys.de/BEEP/SubEthaEditSession"]) {
        NSLog(@"Got SubEthaEditSession profile");
        [aProfile setDelegate:self];
        [I_pendingSessionProfiles addObject:aProfile];
    }
}

- (void)BEEPSession:(TCMBEEPSession *)aBEEPSession didFailWithError:(NSError *)anError
{
    NSLog(@"BEEPSession:didFailWithError:%@",anError);
    NSString *aUserID=[[aBEEPSession userInfo] objectForKey:@"peerUserID"];
    NSMutableDictionary *sessionInformation=[self sessionInformationForUserID:aUserID];
    [aBEEPSession setDelegate:nil];
    [[aBEEPSession retain] autorelease];
    if ([[aBEEPSession userInfo] objectForKey:@"isRendezvous"]) {
        NSString *status=[sessionInformation objectForKey:@"RendezvousStatus"];
        if ([status isEqualToString:kBEEPSessionStatusGotSession]) {
            if ([sessionInformation objectForKey:@"RendezvousSession"]==aBEEPSession) {
                [sessionInformation removeObjectForKey:@"RendezvousSession"];
                [sessionInformation setObject:kBEEPSessionStatusNoSession forKey:@"RendezvousStatus"];
                [self TCM_sendDidEndNotificationForSession:aBEEPSession error:anError];
            }
        } else if ([status isEqualToString:kBEEPSessionStatusConnecting]) {
            if ([[sessionInformation objectForKey:@"OutgoingRendezvousSessions"] containsObject:aBEEPSession]) {
                [[sessionInformation objectForKey:@"OutgoingRendezvousSessions"] removeObject:aBEEPSession];
                if ([[sessionInformation objectForKey:@"OutgoingRendezvousSessions"] count]==0 && 
                    ![sessionInformation objectForKey:@"InboundRendezvousSession"]) {
                    [sessionInformation setObject:kBEEPSessionStatusNoSession forKey:@"RendezvousStatus"];
                }
            } else if ([sessionInformation objectForKey:@"RendezvousSession"]==aBEEPSession) {
                [sessionInformation removeObjectForKey:@"RendezvousSession"];
                [sessionInformation setObject:kBEEPSessionStatusNoSession forKey:@"RendezvousStatus"];
            }
        }
    } else {
        [[sessionInformation objectForKey:@"OutboundSessions"] removeObject:aBEEPSession];
        [[sessionInformation objectForKey:@"InboundSessions"]  removeObject:aBEEPSession];
        NSString *name = [[aBEEPSession userInfo] objectForKey:@"name"];
        NSMutableDictionary *infoDict = [I_pendingOutboundSessions objectForKey:name];
        if (infoDict) {
            NSMutableArray *sessions = [infoDict objectForKey:@"sessions"];
            [sessions removeObject:aBEEPSession];
            if ([sessions count] == 0) {
                [infoDict removeObjectForKey:@"sessions"];
                [[NSNotificationCenter defaultCenter]
                        postNotificationName:TCMMMBEEPSessionManagerConnectToHostDidFailNotification
                                      object:self
                                    userInfo:infoDict];
                [I_pendingOutboundSessions removeObjectForKey:name];
            }
        } else {
            [self TCM_sendDidEndNotificationForSession:aBEEPSession error:anError];
        }
    }

    [I_pendingSessions removeObject:aBEEPSession];
    DEBUGLOG(@"MMBEEPSessions",3,@"%@",[self description]);
}


#pragma mark -
#pragma mark ### notifications ###

- (void)TCM_sendDidAcceptNotificationForSession:(TCMBEEPSession *)aSession {

    [[NSNotificationCenter defaultCenter] 
        postNotificationName:TCMMMBEEPSessionManagerDidAcceptSessionNotification 
                      object:self
                    userInfo:[NSDictionary dictionaryWithObject:aSession forKey:@"Session"]];
}

- (void)TCM_sendDidEndNotificationForSession:(TCMBEEPSession *)aSession error:(NSError *)anError {
    NSMutableDictionary *userInfo=[NSMutableDictionary dictionaryWithObject:aSession forKey:@"Session"];
    if (anError) {
        [userInfo setObject:anError forKey:@"Error"];
    }
    [[NSNotificationCenter defaultCenter] 
        postNotificationName:TCMMMBEEPSessionManagerSessionDidEndNotification 
                      object:self
                    userInfo:userInfo];
}

#pragma mark -
#pragma mark ### HandshakeProfile delegate methods ###

- (NSString *)profile:(HandshakeProfile *)aProfile shouldProceedHandshakeWithUserID:(NSString *)aUserID {
    NSMutableDictionary *information=[self sessionInformationForUserID:aUserID];
    [[[aProfile session] userInfo] setObject:aUserID forKey:@"peerUserID"];
    if ([[[aProfile session] userInfo] objectForKey:@"isRendezvous"]) {
        if ([[information objectForKey:@"RendezvousStatus"] isEqualTo:kBEEPSessionStatusGotSession]) {
            return nil;
        } else if ([[information objectForKey:@"RendezvousStatus"] isEqualTo:kBEEPSessionStatusNoSession]) {
            if ([[aProfile session] isInitiator]) {
                DEBUGLOG(@"Network",4,@"As initiator you should not get this callback by: %@",aProfile);
                return nil;
            } else {
                [information setObject:[aProfile session] forKey:@"InboundRendezvousSession"];
                [information setObject:kBEEPSessionStatusConnecting forKey:@"RendezvousStatus"];
                return [TCMMMUserManager myID];
            }
        } else if ([[information objectForKey:@"RendezvousStatus"] isEqualTo:kBEEPSessionStatusConnecting]) {
            if ([information objectForKey:@"NetService"]) {
                NSLog(@"Received connection for %@ while I already tried connecting",aUserID);
                BOOL iWin=([[TCMMMUserManager myID] compare:aUserID]==NSOrderedDescending);
                NSLog(@"%@ %@ %@",[TCMMMUserManager myID],iWin?@">":@"<=",aUserID);
                if (iWin) {
                    return nil;
                } else {
                    [information setObject:[aProfile session] forKey:@"InboundRendezvousSession"];
                    return [TCMMMUserManager myID]; 
                }
            } else {
                TCMBEEPSession *inboundSession=[information objectForKey:@"InboundRendezvousSession"];
                NSLog(@"WTF? %@ tries to handshake twice, bad guy: %@",aUserID, inboundSession);
                return nil;
            }
        }
    } else {
        return [TCMMMUserManager myID];
    }
    
    return nil; // should not happen
}

- (BOOL)profile:(HandshakeProfile *)aProfile shouldAckHandshakeWithUserID:(NSString *)aUserID {
    NSMutableDictionary *information=[self sessionInformationForUserID:aUserID];
    TCMBEEPSession *session=[aProfile session];
    if ([[session userInfo] objectForKey:@"isRendezvous"]) {
        TCMBEEPSession *inboundSession=[information objectForKey:@"InboundRendezvousSession"];
        if (inboundSession) {
            BOOL iWin=([[TCMMMUserManager myID] compare:aUserID]==NSOrderedDescending);
            if (iWin) {
                [inboundSession setDelegate:nil];
                [inboundSession close];
                [I_pendingSessions removeObject:inboundSession];
                [information removeObjectForKey:@"InboundRendezvousSession"];
                [information setObject:kBEEPSessionStatusGotSession forKey:@"RendezvousStatus"];
                return YES;
            } else {
                return NO;
            }
        } else {
            return YES;
        }
    } else {
        [[[aProfile session] userInfo] setObject:aUserID forKey:@"peerUserID"];
        [[information objectForKey:@"OutboundSessions"] addObject:session];
        NSDictionary *infoDict = [I_pendingOutboundSessions objectForKey:[[session userInfo] objectForKey:@"name"]];
        [[session userInfo] setObject:[infoDict objectForKey:@"host"] forKey:@"host"];
        [I_pendingOutboundSessions removeObjectForKey:[[session userInfo] objectForKey:@"name"]];
        
        return YES;
    }
}

- (void)profile:(HandshakeProfile *)aProfile didAckHandshakeWithUserID:(NSString *)aUserID {
    // trigger creating profiles for clients
    [self TCM_sendDidAcceptNotificationForSession:[aProfile session]];
}

- (void)profile:(HandshakeProfile *)aProfile receivedAckHandshakeWithUserID:(NSString *)aUserID {
    NSMutableDictionary *information=[self sessionInformationForUserID:aUserID];
    TCMBEEPSession *session=[aProfile session];
    if ([[session userInfo] objectForKey:@"isRendezvous"]) {
        [information setObject:session forKey:@"RendezvousSession"];
        [information setObject:kBEEPSessionStatusGotSession forKey:@"RendezvousStatus"];
        [I_pendingSessions removeObject:session];
        NSLog(@"received ACK");
        [self TCM_sendDidAcceptNotificationForSession:session];
//        [session startChannelWithProfileURIs:[NSArray arrayWithObject:@"http://www.codingmonkeys.de/BEEP/TCMMMStatus"] andData:nil];
    } else {
        NSMutableArray *inboundSessions=[information objectForKey:@"InboundSessions"];
        [inboundSessions addObject:session];
        [I_pendingSessions removeObject:session];
        NSLog(@"received ACK");
        [self TCM_sendDidAcceptNotificationForSession:session];
//        [session startChannelWithProfileURIs:[NSArray arrayWithObject:@"http://www.codingmonkeys.de/BEEP/TCMMMStatus"] andData:nil];
    }
}

#pragma mark -

- (void)profile:(SessionProfile *)profile didReceiveJoinRequestForSessionID:(NSString *)sessionID
{
    NSLog(@"didReceiveJoinRequest: %@", sessionID);
    TCMMMSession *session = [[TCMMMPresenceManager sharedInstance] sessionWithID:sessionID];
    if (session) {
        [session joinRequestWithProfile:profile];
        [profile setDelegate:session];
        [I_pendingSessionProfiles removeObject:profile];
    } else {
        // close channel
    }
}

- (void)profile:(SessionProfile *)profile didReceiveInvitationForSessionID:(NSString *)sessionID
{
    NSLog(@"didReceiveInvitation: %@", sessionID);
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
    [aBEEPSession setProfileURIs:[NSArray arrayWithObjects:@"http://www.codingmonkeys.de/BEEP/SubEthaEditHandshake",@"http://www.codingmonkeys.de/BEEP/TCMMMStatus",nil]];
    [aBEEPSession setDelegate:self];
    [aBEEPSession open];
    [I_pendingSessions addObject:aBEEPSession];
}

@end
