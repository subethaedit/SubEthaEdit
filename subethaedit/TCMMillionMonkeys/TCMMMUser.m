//
//  TCMMMUser.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Wed Feb 25 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "TCMBencodingUtilities.h"
#import "TCMMMUser.h"

@interface TCMMMUser (TCMMMUserPrivateAdditions) 

- (void)setProperties:(NSMutableDictionary *)aDictionary;

@end

@implementation TCMMMUser

+ (id)userWithBencodedNotification:(NSData *)aData {
    NSDictionary *notificationDict=TCM_BdecodedObjectWithData(aData);
    TCMMMUser *user=[TCMMMUser new];
    [user setName:[notificationDict objectForKey:@"Name"]];
    [user setUserID:[notificationDict objectForKey:@"UserID"]];
    [user setChangeCount:[[notificationDict objectForKey:@"ChangeCount"] longLongValue]];
    return [user autorelease];
}

- (NSData *)notificationBencoded {
    return TCM_BencodedObject([NSDictionary dictionaryWithObjectsAndKeys:
        [self name],@"Name",
        [self userID],@"UserID",
        [NSNumber numberWithLongLong:[self changeCount]],@"ChangeCount", nil]);
}

- (id)init {
    if ((self=[super init])) {
        I_properties=[NSMutableDictionary new];
        I_changeCount = (long long)[NSDate timeIntervalSinceReferenceDate];
    }
    return self;
}

- (void)dealloc {
    [I_properties release];
    [I_userID release];
    [I_serviceName release];
    [I_name release];
    [super dealloc];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"TCMMMUser <ID:%@,properties:%@>",[self userID],[self properties]];
}

- (void)setUserID:(NSString *)aID {
    [I_userID autorelease];
     I_userID=[aID copy];
}
- (NSString *)userID {
    return I_userID;
}

- (void)setServiceName:(NSString *)aServiceName {
    [I_serviceName autorelease];
     I_serviceName=[aServiceName copy];
}
- (NSString *)serviceName {
    return I_serviceName;
}
- (void)setName:(NSString *)aName {
    [I_name autorelease];
     I_name=[aName copy];
}
- (NSString *)name {
    return I_name;
}

- (NSMutableDictionary *)properties {
    return I_properties;
}

- (void)setProperties:(NSMutableDictionary *)aDictionary {
    [I_properties autorelease];
    I_properties = [aDictionary mutableCopy];
}

- (void)setChangeCount:(long long)aChangeCount {
    I_changeCount = aChangeCount;
}

- (long long)changeCount {
    return I_changeCount;
}

- (void)updateWithUser:(TCMMMUser *)aUser {
    NSParameterAssert([[aUser userID] isEqualTo:[self userID]]);
    [self setProperties:[aUser properties]];
    [self setName:[aUser name]];
    [self setChangeCount:[aUser changeCount]];
}

@end
