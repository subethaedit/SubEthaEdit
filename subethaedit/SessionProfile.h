//
//  SessionProfile.h
//  SubEthaEdit
//
//  Created by Martin Ott on Tue Mar 09 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TCMBEEP/TCMBEEP.h"


@class TCMMMUser;


@interface SessionProfile : TCMBEEPProfile
{
    int32_t I_lastMessageNumber;
}

- (void)sendUser:(TCMMMUser *)aUser;
- (void)sendJoinRequestForSessionID:(NSString *)aSessionID;
- (void)sendSessionContent:(NSDictionary *)aSessionContent;
- (void)sendSessionInformation:(NSDictionary *)aSessionInformation;
- (void)acceptInvitation;
- (void)acceptJoin;

@end


@interface NSObject (SessionProfileDelegateAdditions)

- (void)profile:(SessionProfile *)aProfile didReceiveJoinRequestForSessionID:(NSString *)aSessionID;
- (void)profile:(SessionProfile *)aProfile didReceiveInvitationForSessionID:(NSString *)aSessionID;
- (void)profileDidAcceptJoinRequest:(SessionProfile *)aProfile;
- (void)profileDidAcceptInvitation:(SessionProfile *)aProfile;
- (NSArray *)profile:(SessionProfile *)aProfile userRequestsForSessionInformation:(NSDictionary *)sessionInfo;
- (void)profile:(SessionProfile *)aProfile didReceiveUserRequests:(NSArray *)aUserRequestArray;

@end
