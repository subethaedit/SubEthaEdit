//
//  HandshakeProfile.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Fri Feb 27 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TCMBEEPProfile.h"


@interface HandshakeProfile : TCMBEEPProfile
{
    NSMutableDictionary *I_remoteInfos;
}

- (void)shakeHandsWithUserID:(NSString *)aUserID;

@end


@interface NSObject (HandshakeProfileDelegateAdditions)

- (void)profile:(HandshakeProfile *)aProfile didReceiveHandshakeWithUserID:(NSString *)aUserID andInformation:(NSDictionary *)aInfo;

@end
