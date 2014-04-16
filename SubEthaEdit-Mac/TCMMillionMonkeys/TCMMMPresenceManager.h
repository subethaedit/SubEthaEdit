//
//  TCMMMPresenceManager.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Fri Feb 27 2004.
//  Copyright (c) 2004-2007 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TCMMMStatusProfile, TCMHost, TCMMMSession, TCMRendezvousBrowser;

extern NSString * const VisibilityPrefKey;
extern NSString * const AutoconnectPrefKey;

extern NSString * const TCMMMPresenceManagerUserVisibilityDidChangeNotification;
extern NSString * const TCMMMPresenceManagerUserRendezvousStatusDidChangeNotification;
extern NSString * const TCMMMPresenceManagerUserSessionsDidChangeNotification;
extern NSString * const TCMMMPresenceManagerAnnouncedSessionsDidChangeNotification;
extern NSString * const TCMMMPresenceManagerServiceAnnouncementDidChangeNotification;
extern NSString * const TCMMMPresenceManagerDidReceiveTokenNotification;

extern NSString * const TCMMMPresenceStatusKey;
extern NSString * const TCMMMPresenceUnknownStatusValue;
extern NSString * const TCMMMPresenceKnownStatusValue;
extern NSString * const TCMMMPresenceUserIDKey;
extern NSString * const TCMMMPresenceSessionsKey;
extern NSString * const TCMMMPresenceOrderedSessionsKey;
extern NSString * const TCMMMPresenceNetServicesKey;
extern NSString * const TCMMMPresenceStatusProfileKey;

extern NSString * const TCMMMPresenceTXTRecordUserIDKey;
extern NSString * const TCMMMPresenceTXTRecordNameKey;


@interface TCMMMPresenceManager : NSObject <NSNetServiceDelegate, TCMBEEPProfileDelegate>
{
    NSNetService *I_netService;
    NSMutableDictionary *I_statusOfUserIDs;
    NSMutableSet        *I_statusProfilesInServerRole;
    NSMutableDictionary *I_announcedSessions;
    
    NSMutableDictionary *I_autoAcceptInviteSessions;
    NSMutableDictionary *I_registeredSessions;
    struct {
        BOOL isVisible;
        BOOL serviceIsPublished;
    } I_flags;

    TCMRendezvousBrowser *I_browser;
    NSMutableSet *I_foundUserIDs;
    NSTimer *I_resolveUnconnectedFoundNetServicesTimer;
}

/* depends on TCMMMBeepSessionManager already being initialized - if it isn't it will initialize it*/
+ (instancetype)sharedInstance;

- (void)setShouldAutoAcceptInviteToSessionID:(NSString *)SessionID;
// this call also removes the autoacceptflag
- (BOOL)shouldAutoAcceptInviteToSessionID:(NSString *)aSessionID;

- (TCMMMStatusProfile *)statusProfileForUserID:(NSString *)aUserID;
- (void)stopRendezvousBrowsing;
- (void)startRendezvousBrowsing;
- (BOOL)isVisible;
- (void)setVisible:(BOOL)aFlag;
- (void)setShouldAutoconnect:(BOOL)aFlag forUserID:(NSString *)aUserID;

- (NSArray *)announcedSessions;
- (void)announceSession:(TCMMMSession *)aSession;
- (void)concealSession:(TCMMMSession *)aSession;
- (NSString *)reachabilityURLStringOfUserID:(NSString *)aUserID;
- (NSMutableDictionary *)statusOfUserID:(NSString *)aUserID;
- (TCMMMSession *)sessionForSessionID:(NSString *)aSessionID;
- (void)propagateChangeOfMyself;

- (void)registerSession:(TCMMMSession *)aSession;
- (void)unregisterSession:(TCMMMSession *)aSession;
- (TCMMMSession *)referenceSessionForSession:(TCMMMSession *)aSession;


// debug only
- (NSArray *)allUsers;
@end
