//
//  UserChangeOperation.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Mon May 03 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TCMMMOperation.h"

@class TCMMMUser;

enum {
    UserChangeTypeJoin,
    UserChangeTypeLeave,
    UserChangeTypeGroupChange,
    UserChangeTypeCountOfTypes
};

@interface UserChangeOperation : TCMMMOperation {
    NSString *I_theNewGroup;
    int I_type;
    TCMMMUser *I_user;
}

+ (UserChangeOperation *)userChangeOperationWithType:(int)aType userID:(NSString *)aUserID newGroup:(NSString *)aGroup;

+ (UserChangeOperation *)userChangeOperationWithType:(int)aType user:(TCMMMUser *)aUser newGroup:(NSString *)aGroup;


- (NSString *)theNewGroup;
- (void)setTheNewGroup:(NSString *)aGroup;

- (int)type;
- (void)setType:(int)aType;

- (TCMMMUser *)user;
- (void)setUser:(TCMMMUser *)aUser;

@end
