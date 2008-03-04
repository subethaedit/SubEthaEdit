//
//  TCMMMStatusProfile.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Tue Mar 02 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "../TCMBEEP/TCMBEEP.h"

@class TCMMMUser, TCMMMSession;

@interface TCMMMStatusProfile : TCMBEEPProfile {
    NSMutableDictionary *I_options;
}

+ (NSData *)defaultInitializationData;
- (void)announceSession:(TCMMMSession *)aSession;
- (void)requestUser;
- (void)requestReachability;
- (void)sendUserDidChangeNotification:(TCMMMUser *)aUser;
- (void)sendVisibility:(BOOL)isVisible;
- (void)sendIsFriendcasting:(BOOL)isFriendcasting;
- (void)sendReachabilityURLString:(NSString *)anURLString forUserID:(NSString *)aUserID;
@end

@interface NSObject (TCMMMStatusProfileDelegateMethods)
- (void)profileDidReceiveReachabilityRequest:(TCMMMStatusProfile *)aProfile; 
- (void)profile:(TCMMMStatusProfile *)aProfile didReceiveFriendcastingChange:(BOOL)isFriendcasting;
- (void)profile:(TCMMMStatusProfile *)aProfile didReceiveVisibilityChange:(BOOL)isVisible;
- (void)profile:(TCMMMStatusProfile *)aProfile didReceiveAnnouncedSession:(TCMMMSession *)aSession;
- (void)profile:(TCMMMStatusProfile *)aProfile didReceiveConcealedSessionID:(NSString *)anID;
- (void)profile:(TCMMMStatusProfile *)aProfile didReceiveReachabilityURLString:(NSString *)anURLString forUserID:(NSString *)aUserID;

@end
