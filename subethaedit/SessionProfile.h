//
//  SessionProfile.h
//  SubEthaEdit
//
//  Created by Martin Ott on Tue Mar 09 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TCMBEEP/TCMBEEP.h"
#import "TCMMillionMonkeys/TCMMillionMonkeys.h"


@class TCMMMUser, TCMMMState;


@interface SessionProfile : TCMBEEPProfile <TCMMMStateClientProtocol>
{
    int32_t I_lastMessageNumber;
    TCMMMState *I_MMState;
    NSMutableArray *I_outgoingMMMessageQueue;
    struct {
        BOOL contentHasBeenExchanged;
        BOOL isClosing;
    } I_flags;
}

- (void)sendUser:(TCMMMUser *)aUser;
- (void)sendJoinRequestForSessionID:(NSString *)aSessionID;
- (void)sendUserRequest:(NSDictionary *)aUserNotification;
- (void)cancelJoin;
- (void)sendSessionContent:(NSDictionary *)aSessionContent;
- (void)sendSessionInformation:(NSDictionary *)aSessionInformation;
- (void)acceptInvitation;
- (void)acceptJoin;
- (void)denyJoin;

- (void)setMMState:(TCMMMState *)aState;
- (TCMMMState *)MMState;

@end


@interface NSObject (SessionProfileDelegateAdditions)

- (void)profile:(SessionProfile *)aProfile didReceiveSessionContent:(id)content;
- (void)profile:(SessionProfile *)aProfile didReceiveJoinRequestForSessionID:(NSString *)aSessionID;
- (void)profile:(SessionProfile *)aProfile didReceiveInvitationForSessionID:(NSString *)aSessionID;
- (void)profileDidCancelJoinRequest:(SessionProfile *)aProfile;
- (void)profileDidDenyJoinRequest:(SessionProfile *)aProfile;
- (void)profileDidAcceptJoinRequest:(SessionProfile *)aProfile;
- (void)profileDidAcceptInvitation:(SessionProfile *)aProfile;
- (NSArray *)profile:(SessionProfile *)aProfile userRequestsForSessionInformation:(NSDictionary *)sessionInfo;
- (void)profile:(SessionProfile *)aProfile didReceiveUserRequests:(NSArray *)aUserRequestArray;

- (void)state:(TCMMMState *)aState handleMessage:(TCMMMMessage *)aMessage;

@end
