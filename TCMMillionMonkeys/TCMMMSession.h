//
//  TCMMMSession.h
//  SubEthaEdit
//
//  Created by Martin Ott on Mon Mar 08 2004.
//  Copyright (c) 2004-2007 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>


extern NSString * const TCMMMSessionClientStateDidChangeNotification;
extern NSString * const TCMMMSessionParticipantsDidChangeNotification;
extern NSString * const TCMMMSessionPendingUsersDidChangeNotification;
extern NSString * const TCMMMSessionPendingInvitationsDidChange;
extern NSString * const TCMMMSessionDidChangeNotification;
extern NSString * const TCMMMSessionDidReceiveContentNotification;

@class SessionProfile, TCMMMOperation, TCMBEEPSession, TCMMMUser, TCMMMLoggingState;

typedef enum TCMMMSessionAccessState {
    TCMMMSessionAccessLockedState=0,
    TCMMMSessionAccessReadOnlyState=1,
    TCMMMSessionAccessReadWriteState=2
} TCMMMSessionAccessState;

typedef enum TCMMMSessionClientState {
    TCMMMSessionClientNoState=0,
    TCMMMSessionClientJoiningState=1,
    TCMMMSessionClientInvitedState=2,
    TCMMMSessionClientParticipantState=3,
} TCMMMSessionClientState;


@class TCMMMSession,TCMMMState;

@protocol SEEDocument
- (NSDictionary *)sessionInformation;
- (void)sessionDidReceiveKick:(TCMMMSession *)aSession;
- (void)sessionDidReceiveClose:(TCMMMSession *)aSession;
- (void)sessionDidLoseConnection:(TCMMMSession *)aSession;
- (void)sessionDidAcceptJoinRequest:(TCMMMSession *)aSession;
- (void)sessionDidDenyJoinRequest:(TCMMMSession *)aSession;
- (void)sessionDidCancelInvitation:(TCMMMSession *)aSession;
- (void)sessionDidLeave:(TCMMMSession *)aSession;
- (void)session:(TCMMMSession *)aSession didReceiveSessionInformation:(NSDictionary *)aSessionInformation;
- (void)session:(TCMMMSession *)aSession didReceiveContent:(NSDictionary *)aContent;

- (NSString *)preparedDisplayName;
- (void)invalidateLayoutForRange:(NSRange)aRange;
- (NSDictionary *)textStorageDictionaryRepresentation;
- (void)updateProxyWindow;
- (void)showWindows;
- (NSSet *)userIDsOfContributors;
- (NSSet *)allUserIDs;
- (void)sendInitialUserStateViaMMState:(TCMMMState *)aState;
- (BOOL)isReceivingContent;
- (void)validateEditability;
- (BOOL)handleOperation:(TCMMMOperation *)aOperation;
@end


@protocol TCMMMSessionHelper <NSObject>
- (void)playSoundNamed:(NSString *)name;
- (void)playBeep;
- (void)addProxyDocumentWithSession:(TCMMMSession *)session;
@end

@class TCMMMState;

@interface TCMMMSession : NSObject
{
    id <SEEDocument> I_document;
    NSString *I_sessionID;
    NSString *I_hostID;
    NSString *I_filename;
    id <TCMMMSessionHelper> I_helper;
    NSMutableDictionary *I_profilesByUserID;
    NSMutableDictionary *I_participants;
    NSMutableDictionary *I_invitedUsers;
    NSMutableDictionary *I_groupOfInvitedUsers;
    NSMutableDictionary *I_stateOfInvitedUsers;
    NSMutableDictionary *I_sessionContentForUserID;
    NSMutableSet *I_contributors;
    NSMutableArray *I_pendingUsers;
    NSMutableDictionary *I_groupByUserID;
    NSMutableDictionary *I_statesByClientID;
    NSMutableSet *I_statesWithRemainingMessages;
    TCMMMSessionAccessState I_accessState;
    TCMMMSessionClientState I_clientState;
    TCMMMLoggingState *I_loggingState;
    struct {
        BOOL isServer;
        BOOL shouldSendJoinRequest;
        BOOL wasInvited;
        BOOL isPerformingRoundRobin;
        int pauseCount;
    } I_flags;
    unsigned int I_sessionContentLength;
    unsigned int I_receivedContentLength;
}

+ (TCMMMSession *)sessionWithBencodedSession:(NSData *)aData;
+ (TCMMMSession *)sessionWithDictionaryRepresentation:(NSDictionary *)aDictionary;

- (id)initWithDocument:(id <SEEDocument>)aDocument;
- (id)initWithSessionID:(NSString *)aSessionID filename:(NSString *)aFileName;

- (void)setFilename:(NSString *)aFilename;
- (NSString *)filename;

- (void)setSessionID:(NSString *)aSessionID;
- (NSString *)sessionID;

- (void)setDocument:(id <SEEDocument>)aDocument;
- (id <SEEDocument>)document;

- (void)setHostID:(NSString *)aHostID;
- (NSString *)hostID;

- (void)setIsServer:(BOOL)isServer;
- (BOOL)isServer;

- (void)setWasInvited:(BOOL)wasInvited;
- (BOOL)wasInvited;

- (void)setAccessState:(TCMMMSessionAccessState)aState;
- (TCMMMSessionAccessState)accessState;

- (void)setClientState:(TCMMMSessionClientState)aState;
- (TCMMMSessionClientState)clientState;


- (NSDictionary *)invitedUsers;
- (NSString *)stateOfInvitedUserById:(NSString *)aUserID;
- (TCMBEEPSession *)BEEPSessionForUserID:(NSString *)aUserID;
- (unsigned int)participantCount;
- (NSDictionary *)participants;
- (NSArray *)pendingUsers;

- (NSData *)sessionBencoded;
- (NSDictionary *)dictionaryRepresentation;

- (void)addContributors:(NSArray *)Contributors;
- (NSArray *)contributors;

- (BOOL)isEditable;

- (void)setGroup:(NSString *)aGroup forParticipantsWithUserIDs:(NSArray *)aUserIDs;
- (void)setGroup:(NSString *)aGroup forPendingUsersWithIndexes:(NSIndexSet *)aSet;

- (void)joinUsingBEEPSession:(TCMBEEPSession *)aBEEPSession;
- (void)cancelJoin;

- (void)inviteUser:(TCMMMUser *)aUser intoGroup:(NSString *)aGroup usingBEEPSession:(TCMBEEPSession *)aBEEPSession;
- (void)cancelInvitationForUserWithID:(NSString *)aUserID;
- (void)acceptInvitation;
- (void)declineInvitation;

- (void)leave;
- (void)abandon;

- (void)joinRequestWithProfile:(SessionProfile *)profile;
- (void)invitationWithProfile:(SessionProfile *)profile;

- (void)documentDidApplyOperation:(TCMMMOperation *)anOperation;

- (double)percentOfSessionReceived;

- (void)startProcessing;
- (void)pauseProcessing;

- (BOOL)isAddressedByURL:(NSURL *)aURL;

- (TCMMMLoggingState *)loggingState;
- (void)setLoggingState:(TCMMMLoggingState *)aState;

- (NSDictionary *)contributersAsDictionaryRepresentation;

@end
