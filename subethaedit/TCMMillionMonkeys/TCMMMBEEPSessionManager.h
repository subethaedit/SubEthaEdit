//
//  TCMMMBEEPSessionManager.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Fri Feb 27 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface TCMMMBEEPSessionManager : NSObject {
    NSMutableDictionary *I_sessionInformationByUserID;
    NSMutableDictionary *I_pendingProfileRequestsByUserID;
    NSMutableSet *I_pendingSessions;
}

+ (TCMMMBEEPSessionManager *)sharedInstance;

- (void)requestStatusProfileForUserID:(NSString *)aUserID netService:(NSNetService *)aNetService sender:(id)aSender;

@end
