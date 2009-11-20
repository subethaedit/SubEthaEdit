//
//  TCMMMUserManager.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Wed Feb 25 2004.
//  Copyright (c) 2004-2007 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TCMMMUser.h"

extern NSString * const TCMMMUserManagerUserDidChangeNotification;

@class TCMMMUser;

@interface TCMMMUserManager : NSObject {
    NSMutableDictionary *I_usersByID;
    NSMutableDictionary *I_userRequestsByID;
    TCMMMUser *I_me;
}

+ (TCMMMUserManager *)sharedInstance;
+ (TCMMMUser *)me;
+ (NSString *)myUserID;
+ (void)didChangeMe;

- (void)didChangeMe;
- (void)setMe:(TCMMMUser *)aUser;
- (TCMMMUser *)me;
- (NSString *)myUserID;
- (TCMMMUser *)userForUserID:(NSString *)aID;
- (void)setUser:(TCMMMUser *)aUser forUserID:(NSString *)aID;

- (void)addUser:(TCMMMUser *)aUser;
- (BOOL)sender:(id)aSender shouldRequestUser:(TCMMMUser *)aUser;

// for debugging only
- (NSArray *)allUsers;
@end
