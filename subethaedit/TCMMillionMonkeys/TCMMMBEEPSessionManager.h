//
//  TCMMMBEEPSessionManager.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Fri Feb 27 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TCMBEEPListener, TCMHost;

@interface TCMMMBEEPSessionManager : NSObject
{
    TCMBEEPListener *I_listener;
    int I_listeningPort;
    NSMutableDictionary *I_sessionInformationByUserID;
    NSMutableDictionary *I_pendingProfileRequestsByUserID;
    NSMutableSet *I_pendingSessions;
    
    NSMutableDictionary *I_pendingOutboundSessions;
}

+ (TCMMMBEEPSessionManager *)sharedInstance;
- (BOOL)listen;
- (int)listeningPort;

- (void)connectToNetService:(NSNetService *)aNetService;
- (void)connectToHost:(TCMHost *)aHost;

@end
