//
//  TCMMMSession.h
//  SubEthaEdit
//
//  Created by Martin Ott on Mon Mar 08 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>


extern NSString * const TCMMMSessionPendingUsersDidChangeNotification;
extern NSString * const TCMMMSessionDidChangeNotification;

@class SessionProfile, TCMMMOperation;

typedef enum TCMMMSessionAccessState {
    TCMMMSessionAccessLockedState=0,
    TCMMMSessionAccessReadOnlyState=1,
    TCMMMSessionAccessReadWriteState=2
} TCMMMSessionAccessState;

@interface TCMMMSession : NSObject
{
    NSDocument *I_document;
    NSString *I_sessionID;
    NSString *I_hostID;
    NSString *I_filename;
    NSMutableDictionary *I_profilesByUserID;
    NSMutableDictionary *I_participants;
    NSMutableDictionary *I_sessionContentForUserID;
    NSMutableSet *I_contributors;
    NSMutableArray *I_pendingUsers;
    NSMutableDictionary *I_groupByUserID;
    NSMutableDictionary *I_statesByClientID;
    TCMMMSessionAccessState I_accessState;
    struct {
        BOOL isServer;
        BOOL shouldSendJoinRequest;
    } I_flags;
}

+ (TCMMMSession *)sessionWithBencodedSession:(NSData *)aData;

- (id)initWithDocument:(NSDocument *)aDocument;
- (id)initWithSessionID:(NSString *)aSessionID filename:(NSString *)aFileName;

- (void)setFilename:(NSString *)aFilename;
- (NSString *)filename;

- (void)setSessionID:(NSString *)aSessionID;
- (NSString *)sessionID;

- (void)setDocument:(NSDocument *)aDocument;
- (NSDocument *)document;

- (void)setHostID:(NSString *)aHostID;
- (NSString *)hostID;

- (void)setIsServer:(BOOL)isServer;
- (BOOL)isServer;

- (void)setAccessState:(TCMMMSessionAccessState)aState;
- (TCMMMSessionAccessState)accessState;

- (NSDictionary *)participants;
- (NSArray *)pendingUsers;

- (NSData *)sessionBencoded;
- (NSDictionary *)dictionaryRepresentation;

- (void)setGroup:(NSString *)aGroup forPendingUsersWithIndexes:(NSIndexSet *)aSet;

- (void)join;
- (void)cancelJoin;
- (void)inviteUserWithID:(NSString *)aUserID;

- (void)joinRequestWithProfile:(SessionProfile *)profile;
- (void)invitationWithProfile:(SessionProfile *)profile;

- (void)documentDidApplyOperation:(TCMMMOperation *)anOperation;

@end


@interface NSDocument (TCMMMSessionDocumentAdditions)

- (NSDictionary *)sessionInformation;
- (void)sessionDidAcceptJoinRequest:(TCMMMSession *)aSession;
- (void)session:(TCMMMSession *)aSession didReceiveSessionInformation:(NSDictionary *)aSessionInformation;
- (void)setContentByDictionaryRepresentation:(NSDictionary *)aRepresentation;
@end
