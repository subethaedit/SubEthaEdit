//
//  TCMMMSession.h
//  SubEthaEdit
//
//  Created by Martin Ott on Mon Mar 08 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>


extern NSString * const TCMMMSessionPendingUsersDidChangeNotification;

typedef enum TCMMMSessionState {
    TCMMMSessionStartingChannelForJoin = 0,
    TCMMMSessionStartingChannelForInvite = 1,
    TCMMMSessionRequestingJoin = 2,
    TCMMMSessionRequestingInvite = 3
} TCMMMSessionState;

@class SessionProfile;

@interface TCMMMSession : NSObject
{
    NSDocument *I_document;
    NSString *I_sessionID;
    NSString *I_hostID;
    NSString *I_filename;
    NSMutableDictionary *I_profilesByUserID;
    TCMMMSessionState *I_state;
    NSMutableDictionary *I_participants;
    NSMutableArray *I_pendingUsers;
    NSMutableDictionary *I_stateByUserID;
    
    struct {
        BOOL isServer;
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

- (NSArray *)pendingUsers;

- (NSData *)sessionBencoded;

- (void)setState:(NSString *)aState forPendingUsersWithIndexes:(NSIndexSet *)aSet;

- (void)join;
- (void)inviteUserWithID:(NSString *)aUserID;

- (void)joinRequestWithProfile:(SessionProfile *)profile;
- (void)invitationWithProfile:(SessionProfile *)profile;

@end
