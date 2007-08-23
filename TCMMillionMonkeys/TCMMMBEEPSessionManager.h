//
//  TCMMMBEEPSessionManager.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Fri Feb 27 2004.
//  Copyright (c) 2004-2007 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const DefaultPortNumber;
    
extern NSString * const ProhibitInboundInternetSessions;

extern NSString * const TCMMMBEEPSessionManagerIsReadyNotification;

extern NSString * const TCMMMBEEPSessionManagerDidAcceptSessionNotification;
extern NSString * const TCMMMBEEPSessionManagerSessionDidEndNotification;
extern NSString * const TCMMMBEEPSessionManagerConnectToHostDidFailNotification;
extern NSString * const TCMMMBEEPSessionManagerConnectToHostCancelledNotification;

extern NSString * const kTCMMMBEEPSessionManagerDefaultMode;
extern NSString * const kTCMMMBEEPSessionManagerTLSMode;

@class TCMBEEPListener, TCMHost, TCMBEEPSession;

@interface TCMMMBEEPSessionManager : NSObject
{
    TCMBEEPListener *I_listener;
    int I_listeningPort;
    NSMutableDictionary *I_sessionInformationByUserID;
    NSMutableSet *I_pendingSessions;
    NSMutableSet *I_pendingSessionProfiles;
    NSMutableArray *I_sessions;
    
    NSMutableDictionary *I_outboundInternetSessions;
    BOOL I_isProhibitingInboundInternetSessions;
    NSMutableDictionary *I_handlersForNewProfiles;
    NSMutableDictionary *I_greetingProfiles;
}

+ (TCMMMBEEPSessionManager *)sharedInstance;

- (void)validateListener;
- (BOOL)listen;
- (void)stopListening;
- (int)listeningPort;

- (void)terminateAllBEEPSessions;

- (void)setIsProhibitingInboundInternetSessions:(BOOL)flag;
- (BOOL)isProhibitingInboundInternetSessions;
- (void)registerHandler:(id)aHandler forIncomingProfilesWithProfileURI:(NSString *)aProfileURI;
- (void)registerProfileURI:(NSString *)aProfileURI forGreetingInMode:(NSString *)aMode;

- (void)connectToNetService:(NSNetService *)aNetService;
- (void)connectToHost:(TCMHost *)aHost;
- (void)cancelConnectToHost:(TCMHost *)aHost;

- (void)removeSessionFromSessionsArray:(TCMBEEPSession *)aBEEPSession;

- (TCMBEEPSession *)sessionForUserID:(NSString *)aUserID;
- (TCMBEEPSession *)sessionForUserID:(NSString *)aUserID URLString:(NSString *)aURLString;
- (TCMBEEPSession *)sessionForUserID:(NSString *)aUserID peerAddressData:(NSData *)anAddressData;

@end
