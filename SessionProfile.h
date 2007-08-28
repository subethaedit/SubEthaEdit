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


@class TCMMMUser, TCMMMState, UserChangeOperation;


@interface SessionProfile : TCMBEEPProfile <TCMMMStateClientProtocol>
{
    int32_t I_lastMessageNumber;
    TCMMMState *I_MMState;
    NSMutableArray *I_outgoingMMMessageQueue;
    struct {
        BOOL contentHasBeenExchanged;
        BOOL isClosing;
        BOOL isTrackingSesConFrames;
    } I_flags;
    int32_t I_numberOfTrackedSesConMSG;
    int32_t I_numberOfUnacknowledgedSessconMSG;
    NSMutableDictionary *I_options;
}

+ (NSData *)defaultInitializationData;

- (NSDictionary *)optionDictionary;
- (void)sendInvitationWithSession:(TCMMMSession *)aSession;
- (void)sendUser:(TCMMMUser *)aUser;
- (void)sendJoinRequestForSessionID:(NSString *)aSessionID;
- (void)sendUserRequest:(NSDictionary *)aUserNotification;
- (void)cancelJoin;
- (void)sendSessionContent:(NSData *)aSessionContent;
- (void)sendSessionInformation:(NSDictionary *)aSessionInformation;
- (void)cancelInvitation;
- (void)acceptInvitation;
- (void)declineInvitation;
- (void)acceptJoin;
- (void)denyJoin;

- (void)setMMState:(TCMMMState *)aState;
- (TCMMMState *)MMState;

- (void)clearOutgoingMMMessageQueue;
- (void)setContentHasBeenExchanged:(BOOL)aFlag;
- (BOOL)contentHasBeenExchanged;

@end


@interface NSObject (SessionProfileDelegateAdditions)

- (void)profile:(SessionProfile *)aProfile didReceiveSessionContent:(id)content;
- (void)profileDidAckSessionContent:(SessionProfile *)aProfile;
- (void)profile:(SessionProfile *)aProfile didReceiveJoinRequestForSessionID:(NSString *)aSessionID;
- (void)profile:(SessionProfile *)aProfile didReceiveInvitationForSession:(TCMMMSession *)aSession;
- (void)profile:(SessionProfile *)aProfile didReceiveSessionContentFrame:(TCMBEEPFrame *)aFrame;
- (void)profileDidCancelJoinRequest:(SessionProfile *)aProfile;
- (void)profileDidDenyJoinRequest:(SessionProfile *)aProfile;
- (void)profileDidAcceptJoinRequest:(SessionProfile *)aProfile;
- (void)profileDidCancelInvitation:(SessionProfile *)aProfile;
- (void)profileDidAcceptInvitation:(SessionProfile *)aProfile;
- (void)profileDidDeclineInvitation:(SessionProfile *)aProfile;
- (NSArray *)profile:(SessionProfile *)aProfile userRequestsForSessionInformation:(NSDictionary *)sessionInfo;
- (void)profile:(SessionProfile *)aProfile didReceiveUserRequests:(NSArray *)aUserRequestArray;
- (void)profile:(SessionProfile *)aProfile didReceiveUserChangeToReadOnly:(UserChangeOperation *)anOperation;

- (void)state:(TCMMMState *)aState handleMessage:(TCMMMMessage *)aMessage;

@end
