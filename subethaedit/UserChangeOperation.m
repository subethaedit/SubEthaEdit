//
//  UserChangeOperation.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Mon May 03 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "UserChangeOperation.h"
#import "TCMMMUser.h"
#import "TCMMMUserSEEAdditions.h"

@implementation UserChangeOperation

+ (void)initialize {
    [TCMMMOperation registerClass:self forOperationType:[self operationID]];
}

+ (UserChangeOperation *)userChangeOperationWithType:(int)aType userID:(NSString *)aUserID newGroup:(NSString *)aGroup {
    UserChangeOperation *result=[[UserChangeOperation new] autorelease];
    [result setType:aType];
    [result setUserID:aUserID];
    [result setNewGroup:aGroup];
    return result;
}

+ (UserChangeOperation *)userChangeOperationWithType:(int)aType user:(TCMMMUser *)aUser newGroup:(NSString *)aGroup {
    UserChangeOperation *result=[[UserChangeOperation new] autorelease];
    [result setType:aType];
    [result setUserID:[aUser userID]];
    [result setUser:aUser];
    [result setNewGroup:aGroup];
    return result;
}


+ (NSString *)operationID {
    return @"usr";
}

- (id)init {
    self = [super init];
    if (self) {
        [self setNewGroup:@""];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    UserChangeOperation *copy = [super copyWithZone:zone];

    [copy setNewGroup:[self newGroup]];
    [copy setType:[self type]];
    [copy setUser:[self user]];
    
    return copy;
}


- (void)dealloc {
    [I_newGroup release];
    [I_user release];
    [super dealloc];
}

- (NSString *)description {
    NSMutableString *string=[NSMutableString stringWithFormat:@"UserChangeOperation %@",[self userID]];
    NSString *type=nil;
    switch ([self type]) {
        case UserChangeTypeJoin:
            type=@"Join"; break;
        case UserChangeTypeLeave:
            type=@"Leave"; break;
        case UserChangeTypeGroupChange:
            type=@"GroupChange"; break;
    }
    [string appendFormat:@" %@ %@",type,[self newGroup]];
    return string;
}

- (id)initWithDictionaryRepresentation:(NSDictionary *)aDictionary {
    self = [super initWithDictionaryRepresentation:aDictionary];
    if (self) {
        [self setType:[[aDictionary objectForKey:@"typ"] unsignedIntValue]];
        [self setNewGroup:[aDictionary objectForKey:@"grp"]];
        id userDict=[aDictionary objectForKey:@"usr"];
        if (userDict) {
            TCMMMUser *user=[TCMMMUser userWithNotification:userDict];
            [self setUser:user];
        }
        //NSLog(@"operation: %@", [self description]);
    }
    return self;
}


- (NSDictionary *)dictionaryRepresentation {
    NSMutableDictionary *dict = [[[super dictionaryRepresentation] mutableCopy] autorelease];
    [dict setObject:[NSNumber numberWithUnsignedInt:I_type] forKey:@"typ"];
    [dict setObject:[self newGroup] forKey:@"grp"];
    TCMMMUser *user=[self user];
    if (user) {
        [dict setObject:[user notification] forKey:@"usr"];
    }
    return dict;
}

#pragma mark -
#pragma mark ### accessors ###

- (NSString *)newGroup {
    return I_newGroup;
}
- (void)setNewGroup:(NSString *)aGroup {
    [I_newGroup autorelease];
     I_newGroup = [aGroup copy];
}

- (int)type {
    return I_type;
}
- (void)setType:(int)aType {
    I_type=aType;
}

- (TCMMMUser *)user {
    return I_user;
}

- (void)setUser:(TCMMMUser *)aUser {
    [I_user autorelease];
     I_user=[aUser retain];
}

@end
