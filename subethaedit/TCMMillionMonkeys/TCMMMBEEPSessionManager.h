//
//  TCMMMBEEPSessionManager.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Fri Feb 27 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const TCMMMBEEPSessionManagerDidAcceptSessionNotification;
extern NSString * const TCMMMBEEPSessionManagerSessionDidEndNotification;
extern NSString * const TCMMMBEEPSessionManagerConnectToHostDidFailNotification;


@class TCMBEEPListener, TCMHost, TCMBEEPSession;

@interface TCMMMBEEPSessionManager : NSObject
{
    TCMBEEPListener *I_listener;
    int I_listeningPort;
    NSMutableDictionary *I_sessionInformationByUserID;
    NSMutableSet *I_pendingSessions;
    NSMutableSet *I_pendingSessionProfiles;
    
    NSMutableDictionary *I_pendingOutboundSessions;
}

+ (TCMMMBEEPSessionManager *)sharedInstance;
- (BOOL)listen;
- (int)listeningPort;

- (void)connectToNetService:(NSNetService *)aNetService;
- (void)connectToHost:(TCMHost *)aHost;

- (TCMBEEPSession *)sessionForUserID:(NSString *)aUserID;

@end
