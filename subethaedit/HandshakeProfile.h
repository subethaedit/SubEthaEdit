//
//  HandshakeProfile.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Fri Feb 27 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TCMBEEP.h"
#import "TCMMillionMonkeys/TCMMillionMonkeys.h"


@interface HandshakeProfile : TCMBEEPProfile
{
    NSMutableDictionary *I_remoteInfos;
}

- (void)shakeHandsWithUserID:(NSString *)aUserID;

- (void)setRemoteInfos:(NSDictionary *)aDictionary;
- (NSDictionary *)remoteInfos;

@end


@interface NSObject (HandshakeProfileDelegateAdditions)

- (NSString *)profile:(HandshakeProfile *)aProfile shouldProceedHandshakeWithUserID:(NSString *)aUserID;
- (BOOL)profile:(HandshakeProfile *)aProfile shouldAckHandshakeWithUserID:(NSString *)aUserID;
- (void)profile:(HandshakeProfile *)aProfile didAckHandshakeWithUserID:(NSString *)aUserID;
- (void)profile:(HandshakeProfile *)aProfile receivedAckHandshakeWithUserID:(NSString *)aUserID;
@end
