//
//  SessionProfile.h
//  SubEthaEdit
//
//  Created by Martin Ott on Tue Mar 09 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TCMBEEP/TCMBEEP.h"


@interface SessionProfile : TCMBEEPProfile
{
    int32_t I_lastMessageNumber;
}

- (void)sendJoinRequestForSessionID:(NSString *)aSessionID;
- (void)acceptInvitation;
- (void)acceptJoin;

@end


@interface NSObject (SessionProfileDelegateAdditions)

- (void)profile:(SessionProfile *)profile didReceiveJoinRequestForSessionID:(NSString *)sessionID;
- (void)profile:(SessionProfile *)profile didReceiveInvitationForSessionID:(NSString *)sessionID;
- (void)profileDidAcceptJoinRequest:(SessionProfile *)profile;
- (void)profileDidAcceptInvitation:(SessionProfile *)profile;

@end
