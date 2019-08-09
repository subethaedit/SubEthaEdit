//  UserChangeOperation.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Mon May 03 2004.

#import <Foundation/Foundation.h>
#import "TCMMMOperation.h"

@class TCMMMUser;

enum {
    UserChangeTypeJoin,
    UserChangeTypeLeave,
    UserChangeTypeGroupChange,
    UserChangeTypeCountOfTypes
};

@interface UserChangeOperation : TCMMMOperation

@property (nonatomic, copy) NSString *theNewGroup;
@property (nonatomic, assign) int type;
@property (nonatomic, retain) TCMMMUser *user;


+ (UserChangeOperation *)userChangeOperationWithType:(int)aType userID:(NSString *)aUserID newGroup:(NSString *)aGroup;

+ (UserChangeOperation *)userChangeOperationWithType:(int)aType user:(TCMMMUser *)aUser newGroup:(NSString *)aGroup;

@end
