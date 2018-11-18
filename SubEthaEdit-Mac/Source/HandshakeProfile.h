//  HandshakeProfile.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Fri Feb 27 2004.

#import <Foundation/Foundation.h>
#import "TCMBEEP.h"

@class HandshakeProfile;

@protocol HandshakeProfileDelegate <NSObject>
- (NSString *)profile:(HandshakeProfile *)aProfile shouldProceedHandshakeWithUserID:(NSString *)aUserID;
- (BOOL)profile:(HandshakeProfile *)aProfile shouldAckHandshakeWithUserID:(NSString *)aUserID;
- (void)profile:(HandshakeProfile *)aProfile didAckHandshakeWithUserID:(NSString *)aUserID;
- (void)profile:(HandshakeProfile *)aProfile receivedAckHandshakeWithUserID:(NSString *)aUserID;
@end

@interface HandshakeProfile : TCMBEEPProfile
{
    NSMutableDictionary *I_remoteInfos;
}

- (void)shakeHandsWithUserID:(NSString *)aUserID;

- (void)setRemoteInfos:(NSDictionary *)aDictionary;
- (NSDictionary *)remoteInfos;

- (void)setDelegate:(id <TCMBEEPProfileDelegate, HandshakeProfileDelegate>)aDelegate;
- (id <TCMBEEPProfileDelegate, HandshakeProfileDelegate>)delegate;

@end


