//  TCMMMStatusProfile.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Tue Mar 02 2004.

#import <Foundation/Foundation.h>
#import "../TCMBEEP/TCMBEEP.h"

@class TCMMMUser, TCMMMSession, TCMMMStatusProfile;

@protocol TCMMMStatusProfileDelegate <NSObject>
- (void)profileDidReceiveReachabilityRequest:(TCMMMStatusProfile *)aProfile;
- (void)profile:(TCMMMStatusProfile *)aProfile didReceiveFriendcastingChange:(BOOL)isFriendcasting;
- (void)profile:(TCMMMStatusProfile *)aProfile didReceiveVisibilityChange:(BOOL)isVisible;
- (void)profile:(TCMMMStatusProfile *)aProfile didReceiveAnnouncedSession:(TCMMMSession *)aSession;
- (void)profile:(TCMMMStatusProfile *)aProfile didReceiveConcealedSessionID:(NSString *)anID;
- (void)profile:(TCMMMStatusProfile *)aProfile didReceiveReachabilityURLString:(NSString *)anURLString forUserID:(NSString *)aUserID;
- (void)profile:(TCMMMStatusProfile *)aProfile didReceiveToken:(NSString *)aToken;
@end

@interface TCMMMStatusProfile : TCMBEEPProfile {
    NSMutableDictionary *I_options;
}

+ (NSData *)defaultInitializationData;
- (NSDictionary *)optionDictionary;
- (void)announceSession:(TCMMMSession *)aSession;
- (void)requestUser;
- (void)requestReachability;
- (void)sendUserDidChangeNotification:(TCMMMUser *)aUser;
- (void)sendVisibility:(BOOL)isVisible;
- (void)sendIsFriendcasting:(BOOL)isFriendcasting;
- (void)sendReachabilityURLString:(NSString *)anURLString forUserID:(NSString *)aUserID;
- (BOOL)sendToken:(NSString *)aToken;
- (void)setDelegate:(id <TCMBEEPProfileDelegate, TCMMMStatusProfileDelegate>)aDelegate;
- (id <TCMBEEPProfileDelegate, TCMMMStatusProfileDelegate>)delegate;
@property (nonatomic, readonly) BOOL lastSentFriendcastingStatus;
@end
