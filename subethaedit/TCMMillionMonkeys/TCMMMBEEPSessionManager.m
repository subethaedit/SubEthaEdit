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
#import "TCMHost.h"
#import "HandshakeProfile.h"

#import <netinet/in.h>

#define PORTRANGESTART 12347
#define PORTRANGELENGTH 10

static NSString *kBEEPSessionStatusNoSession =@"NoSession";
static NSString *kBEEPSessionStatusGotSession=@"GotSession";
static NSString *kBEEPSessionStatusConnecting=@"Connecting";


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
        
    Internet:
        pendingOutboundSessions {
            <hostname> => {
                "host" => TCMHost
                "sessions" = NSMutableSet
            }
        }
        
        inboundPendingSessions:
    
        (outbound|inbound)sessions:
*/


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
        I_pendingOutboundSessions = [NSMutableDictionary new];
    }
    return self;
}

- (void)dealloc
{
    [I_listener close];
    [I_listener release];
    [I_sessionInformationByUserID release];
    [I_pendingProfileRequestsByUserID release];
    [I_pendingSessions release];
    [I_pendingOutboundSessions release];
    [super dealloc];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"BEEPSessionManager sessionInformation:%@\npendingProfileRequests:%@\npendingSessions:%@",[I_sessionInformationByUserID descriptionInStringsFileFormat],[I_pendingProfileRequestsByUserID descriptionInStringsFileFormat],[I_pendingSessions description]];
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
        [session setProfileURIs:[NSArray arrayWithObjects:@"http://www.codingmonkeys.de/BEEP/SubEthaEditHandshake",@"http://www.codingmonkeys.de/BEEP/TCMMMStatus", nil]];
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
    
    NSEnumerator *addresses = [[aHost addresses] objectEnumerator];
    NSData *addressData;
    while ((addressData = [addresses nextObject])) {
        NSLog(@"trying addressData: %@", [NSString stringWithAddressData:addressData]);
        int i;
        for (i = PORTRANGESTART; i < PORTRANGESTART + PORTRANGELENGTH; i++) {
            NSMutableData *mutableAddressData = [addressData mutableCopy];
            struct sockaddr_in *address = (struct sockaddr_in *)[mutableAddressData mutableBytes];
            address->sin_port = htons(i);
            NSLog(@"trying mutableAddressData: %@", [NSString stringWithAddressData:mutableAddressData]);

            TCMBEEPSession *session = [[TCMBEEPSession alloc] initWithAddressData:mutableAddressData];
            [[session userInfo] setObject:[NSNumber numberWithBool:YES] forKey:@"isInternet"];
            [[session userInfo] setObject:[aHost name] forKey:@"name"];
            [sessions addObject:session];
            [session setDelegate:self];
            [session open];
            
            [mutableAddressData autorelease];
        }
    }
}

#pragma mark -

- (void)BEEPSession:(TCMBEEPSession *)aBEEPSession didReceiveGreetingWithProfileURIs:(NSArray *)aProfileURIArray
{
    NSNumber *flag;
    if ((flag = [[aBEEPSession userInfo] objectForKey:@"isInternet"])) {
        if ([flag boolValue]) {
            if ([[aBEEPSession peerProfileURIs] containsObject:@"http://www.codingmonkeys.de/BEEP/SubEthaEditHandshake"]) {
                if ([aBEEPSession isInitiator]) {
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

                    NSLog(@"starting handshake channel on internet session.");
                    [aBEEPSession startChannelWithProfileURIs:[NSArray arrayWithObject:@"http://www.codingmonkeys.de/BEEP/SubEthaEditHandshake"] andData:nil];
                }
            } else {
                [aBEEPSession setDelegate:nil];
                [aBEEPSession close];
                NSString *name = [[aBEEPSession userInfo] objectForKey:@"name"];
                NSDictionary *info = [I_pendingOutboundSessions objectForKey:name];
                [[info objectForKey:@"sessions"] removeObject:aBEEPSession];
            }
        }
        return;
    }
    
    
    if ([[aBEEPSession peerProfileURIs] containsObject:@"http://www.codingmonkeys.de/BEEP/SubEthaEditHandshake"]) {
        if ([aBEEPSession isInitiator]) {
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
            [aBEEPSession startChannelWithProfileURIs:[NSArray arrayWithObject:@"http://www.codingmonkeys.de/BEEP/SubEthaEditHandshake"] andData:nil];
        }
    } else {
        [aBEEPSession setDelegate:nil];
        [aBEEPSession close];
        NSString *aUserID=[[aBEEPSession userInfo] objectForKey:@"peerUserID"];
        if ([aBEEPSession isInitiator] && aUserID) {
            NSMutableDictionary *information=[self sessionInformationForUserID:aUserID];
            [[information objectForKey:@"OutgoingRendezvousSessions"] removeObject:aBEEPSession];
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
        if (![[aProfile channel] isServer]) {
            NSString *aUserID=[[aBEEPSession userInfo] objectForKey:@"peerUserID"];
            NSMutableDictionary *information=[self sessionInformationForUserID:aUserID];
            if ([[information objectForKey:@"OutgoingRendezvousSessions"] count]) {
                NSLog(@"Can't happen");
            }
            [(HandshakeProfile *)aProfile shakeHandsWithUserID:[TCMMMUserManager myID]];
        }
    } else if ([[aProfile profileURI] isEqualToString:@"http://www.codingmonkeys.de/BEEP/TCMMMStatus"]) {
        [[TCMMMPresenceManager sharedInstance] acceptStatusProfile:(TCMMMStatusProfile *)aProfile];
        if ([[aProfile channel] isServer]) {
            // distribute the profile to the corresponding handler
        } else {
            // find the open request
        }
    }
}

- (void)BEEPSession:(TCMBEEPSession *)aBEEPSession didFailWithError:(NSError *)anError
{
    NSLog(@"BEEPSession:didFailWithError:%@",anError);
    NSString *aUserID=[[aBEEPSession userInfo] objectForKey:@"peerUserID"];
    NSMutableDictionary *sessionInformation=[self sessionInformationForUserID:aUserID];
    NSString *status=[sessionInformation objectForKey:@"RendezvousStatus"];
    [[aBEEPSession retain] autorelease];
    if ([status isEqualToString:kBEEPSessionStatusGotSession]) {
        if ([sessionInformation objectForKey:@"RendezvousSession"]==aBEEPSession) {
            [sessionInformation removeObjectForKey:@"RendezvousSession"];
            [sessionInformation setObject:kBEEPSessionStatusNoSession forKey:@"RendezvousStatus"];
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

    [I_pendingSessions removeObject:aBEEPSession];
    NSLog(@"%@",[self description]);
}

#pragma mark -
#pragma mark ### HandshakeProfile delegate methods ###

- (NSString *)profile:(HandshakeProfile *)aProfile shouldProceedHandshakeWithUserID:(NSString *)aUserID {
    NSMutableDictionary *information=[self sessionInformationForUserID:aUserID];
    [[[[aProfile channel] session] userInfo] setObject:aUserID forKey:@"peerUserID"];
    if ([[information objectForKey:@"RendezvousStatus"] isEqualTo:kBEEPSessionStatusGotSession]) {
        return nil;
    } else if ([[information objectForKey:@"RendezvousStatus"] isEqualTo:kBEEPSessionStatusNoSession]) {
        if ([[[aProfile channel] session] isInitiator]) {
            DEBUGLOG(@"Network",4,@"As initiator you should not get this callback by: %@",aProfile);
            return nil;
        } else {
            [information setObject:[[aProfile channel] session] forKey:@"InboundRendezvousSession"];
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
                [information setObject:[[aProfile channel] session] forKey:@"InboundRendezvousSession"];
                return [TCMMMUserManager myID]; 
            }
        } else {
            TCMBEEPSession *inboundSession=[information objectForKey:@"InboundRendezvousSession"];
            NSLog(@"WTF? %@ tries to handshake twice, bad guy: %@",aUserID, inboundSession);
            return nil;
        }
    }
    
    return nil; // should not happen
}

- (BOOL)profile:(HandshakeProfile *)aProfile shouldAckHandshakeWithUserID:(NSString *)aUserID {
    NSMutableDictionary *information=[self sessionInformationForUserID:aUserID];
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
}

- (void)profile:(HandshakeProfile *)aProfile didAckHandshakeWithUserID:(NSString *)aUserID {
    // trigger creating profiles for clients
}

- (void)profile:(HandshakeProfile *)aProfile receivedAckHandshakeWithUserID:(NSString *)aUserID {
    NSMutableDictionary *information=[self sessionInformationForUserID:aUserID];
    [information setObject:[[aProfile channel] session] forKey:@"RendezvousSession"];
    [information setObject:kBEEPSessionStatusGotSession forKey:@"RendezvousStatus"];
    [I_pendingSessions removeObject:[[aProfile channel] session]];
    NSLog(@"received ACK");
    [[[aProfile channel] session] startChannelWithProfileURIs:[NSArray arrayWithObject:@"http://www.codingmonkeys.de/BEEP/TCMMMStatus"] andData:nil];
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
