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
        [session setProfileURIs:[NSArray arrayWithObjects:@"http://www.codingmonkeys.de/BEEP/SubEthaEditHandshake",@"http://www.codingmonkeys.de/BEEP/TCMMMStatus", nil]];
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
            NSString *aUserID=[[aBEEPSession userInfo] objectForKey:@"peerUserID"];
            NSMutableDictionary *sessionInformation=[self sessionInformationForUserID:aUserID];
            if ([sessionInformation objectForKey:@"NetService"]) {
                // rendezvous: close all other sessions
                NSMutableArray *outgoingSessions=[sessionInformation objectForKey:@"outgoingSessions"];
                TCMBEEPSession *session;
                while ((session=[outgoingSessions lastObject])) {
                    [[session retain] autorelease];
                    [outgoingSessions removeObjectAtIndex:[outgoingSessions count]-1];
                    [I_pendingSessions removeObject:session];
                    if (session==aBEEPSession) {
                        [sessionInformation setObject:session forKey:@"Session"];
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
    if ([[aProfile profileURI] isEqualToString:@"http://www.codingmonkeys.de/BEEP/SubEthaEditHandshake"]) {
        [aProfile setDelegate:self];
        if (![[aProfile channel] isServer]) {
            NSString *aUserID=[[aBEEPSession userInfo] objectForKey:@"peerUserID"];
            NSMutableDictionary *information=[self sessionInformationForUserID:aUserID];
            if ([[information objectForKey:@"outgoingSessions"] count]) {
                // remove all other sessions
                NSMutableArray *outgoingSessions=[information objectForKey:@"outgoingSessions"];
                TCMBEEPSession *session;
                while ((session=[outgoingSessions lastObject])) {
                    [[session retain] autorelease];
                    [outgoingSessions removeObjectAtIndex:[outgoingSessions count]-1];
                    [I_pendingSessions removeObject:session];
                    if (session==aBEEPSession) {
                        [information setObject:session forKey:@"Session"];
                    } else {
                        [session setDelegate:nil];
                        [session close];
                    }
                }
            }
            [(HandshakeProfile *)aProfile shakeHandsWithUserID:[TCMMMUserManager myID]];
        }
    } else if ([[aProfile profileURI] isEqualToString:@"http://www.codingmonkeys.de/BEEP/TCMMMStatus"])
{
        [[TCMMMPresenceManager sharedInstance] acceptStatusProfile:(TCMMMStatusProfile *)aProfile];
        if ([[aProfile channel] isServer]) {
            // distribute the profile to the corresponding handler
        } else {
            // find the open request
        }
    }
}

#pragma mark -
#pragma mark ### HandshakeProfile delegate methods ###

- (NSString *)profile:(HandshakeProfile *)aProfile shouldProceedHandshakeWithUserID:(NSString *)aUserID {
    NSMutableDictionary *information=[self sessionInformationForUserID:aUserID];
    [[[aProfile channel] session] setUserInfo:[NSDictionary dictionaryWithObject:aUserID forKey:@"peerUserID"]];
    if ([[information objectForKey:@"Status"] isEqualTo:kBEEPSessionStatusGotSession]) {
        return nil;
    } else if ([[information objectForKey:@"Status"] isEqualTo:kBEEPSessionStatusNoSession]) {
        if ([[[aProfile channel] session] isInitiator]) {
            DEBUGLOG(@"Network",4,@"As initiator you should not get this callback by: %@",aProfile);
            return nil;
        } else {
            [information setObject:[[aProfile channel] session] forKey:@"inboundSession"];
            [information setObject:kBEEPSessionStatusConnecting forKey:@"Status"];
            return [TCMMMUserManager myID];
        }
    } else if ([[information objectForKey:@"Status"] isEqualTo:kBEEPSessionStatusConnecting]) {
        if ([information objectForKey:@"NetService"]) {
            NSLog(@"Received connection for %@ while I already tried connecting",aUserID);
            BOOL iWin=([[TCMMMUserManager myID] compare:aUserID]==NSOrderedDescending);
            NSLog(@"%@ %@ %@",[TCMMMUserManager myID],iWin?@">":@"<=",aUserID);
            if (iWin) {
                return nil;
            } else {
                [information setObject:[[aProfile channel] session] forKey:@"inboundSession"];
                return [TCMMMUserManager myID]; 
            }
        } else {
            TCMBEEPSession *inboundSession=[information objectForKey:@"inboundSession"];
            NSLog(@"WTF? %@ tries to handshake twice, bad guy: %@",aUserID, inboundSession);
            return nil;
        }
    }
    
    return nil; // should not happen
}
- (BOOL)profile:(HandshakeProfile *)aProfile shouldAckHandshakeWithUserID:(NSString *)aUserID {
    NSMutableDictionary *information=[self sessionInformationForUserID:aUserID];
    TCMBEEPSession *inboundSession=[information objectForKey:@"inboundSession"];
    if (inboundSession) {
        BOOL iWin=([[TCMMMUserManager myID] compare:aUserID]==NSOrderedDescending);
        if (iWin) {
            [inboundSession setDelegate:nil];
            [inboundSession close];
            [I_pendingSessions removeObject:inboundSession];
            [information removeObjectForKey:@"inboundSession"];
            [information setObject:kBEEPSessionStatusGotSession forKey:@"Status"];
            return YES;
        } else {
            return NO;
        }
    } else {
        return YES;
    }
}

- (void)profile:(HandshakeProfile *)aProfile didAckHandshakeWithUserID:(NSString *)aUserID {
    [[[aProfile channel] session] startChannelWithProfileURIs:[NSArray arrayWithObject:@"http://www.codingmonkeys.de/BEEP/TCMMMStatus"] andData:nil];
    // trigger creating profiles for clients
}

- (void)profile:(HandshakeProfile *)aProfile receivedAckHandshakeWithUserID:(NSString *)aUserID {
    NSMutableDictionary *information=[self sessionInformationForUserID:aUserID];
    [information setObject:[[aProfile channel] session] forKey:@"Session"];
    [information setObject:kBEEPSessionStatusGotSession forKey:@"Status"];
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
