//
//  TCMMMBEEPSessionManager.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Fri Feb 27 2004.
//  Copyright (c) 2004-2007 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>
#define SUBETHAEDIT_DEFAULT_PORT 6942

extern NSString * const DefaultPortNumber;
extern NSString * const ShouldAutomaticallyMapPort;
    
extern NSString * const ProhibitInboundInternetSessions;

extern NSString * const TCMMMBEEPSessionManagerIsReadyNotification;

extern NSString * const TCMMMBEEPSessionManagerDidAcceptSessionNotification;
extern NSString * const TCMMMBEEPSessionManagerSessionDidEndNotification;
extern NSString * const TCMMMBEEPSessionManagerConnectToHostDidFailNotification;
extern NSString * const TCMMMBEEPSessionManagerConnectToHostCancelledNotification;

extern NSString * const kTCMMMBEEPSessionManagerDefaultMode;
extern NSString * const kTCMMMBEEPSessionManagerTLSMode;

@class TCMBEEPListener, TCMHost, TCMBEEPSession;

@interface TCMMMBEEPSessionManager : NSObject <TCMBEEPSessionDelegate, TCMBEEPProfileDelegate>
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
    
    int I_SSLGenerationCount;
    int I_SSLGenerationDesiredCount;
}

+ (TCMMMBEEPSessionManager *)sharedInstance;

+ (NSURL *)urlForAddress:(NSString *)anAddress;
+ (NSURL *)reducedURL:(NSURL *)anURL addressData:(NSData **)anAddressData documentRequest:(NSURL **)aRequest;

- (void)validateListener;
- (BOOL)listen;
- (void)stopListening;
- (int)listeningPort;
- (BOOL)isListening;

- (NSArray *)allBEEPSessions;
- (void)terminateAllBEEPSessions;

@property (nonatomic, getter=isNetworkingDisabled) BOOL networkingDisabled;
- (void)validatePortMapping;

- (void)setIsProhibitingInboundInternetSessions:(BOOL)flag;
- (BOOL)isProhibitingInboundInternetSessions;
- (void)registerHandler:(id)aHandler forIncomingProfilesWithProfileURI:(NSString *)aProfileURI;
- (void)registerProfileURI:(NSString *)aProfileURI forGreetingInMode:(NSString *)aMode;

- (void)connectToNetService:(NSNetService *)aNetService;
- (void)connectToHost:(TCMHost *)aHost;
- (void)cancelConnectToHost:(TCMHost *)aHost;

- (NSArray *)connectedUsers;

- (TCMBEEPSession *)sessionForUserID:(NSString *)aUserID;
- (TCMBEEPSession *)sessionForUserID:(NSString *)aUserID URLString:(NSString *)aURLString;
- (TCMBEEPSession *)sessionForUserID:(NSString *)aUserID peerAddressData:(NSData *)anAddressData;

@end
