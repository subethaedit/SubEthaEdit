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

+ (id)userWithNotification:(NSDictionary *)aNotificationDict {
    TCMMMUser *user=[TCMMMUser new];
    [user setName:[aNotificationDict objectForKey:@"Name"]];
    [user setUserID:[aNotificationDict objectForKey:@"UserID"]];
    [user setChangeCount:[[aNotificationDict objectForKey:@"ChangeCount"] longLongValue]];
    return [user autorelease];
}


+ (id)userWithBencodedNotification:(NSData *)aData {
    NSDictionary *notificationDict=TCM_BdecodedObjectWithData(aData);
    return notificationDict?[self userWithNotification:notificationDict]:nil;
}

- (NSData *)notificationBencoded {
    return TCM_BencodedObject([self notification]);
}

- (NSDictionary *)notification {
    return [NSDictionary dictionaryWithObjectsAndKeys:
        [self name],@"Name",
        [self userID],@"UserID",
        [NSNumber numberWithLongLong:[self changeCount]],@"ChangeCount", nil];
}

- (id)init {
    if ((self=[super init])) {
        I_properties=[NSMutableDictionary new];
        I_propertiesBySessionID=[NSMutableDictionary new];
        I_changeCount = (long long)[NSDate timeIntervalSinceReferenceDate];
    }
    return self;
}

- (void)dealloc {
    [I_propertiesBySessionID release];
    [I_properties release];
    [I_userID release];
    [I_serviceName release];
    [I_name release];
    [super dealloc];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"TCMMMUser <ID:%@,Name:%@,properties:%d>",[self userID],[self name],[[self properties] count]];
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

- (void)joinSessionID:(NSString *)aSessionID {
    NSAssert([I_propertiesBySessionID objectForKey:aSessionID]==nil, @"User already joined");
    [I_propertiesBySessionID setObject:[NSMutableDictionary dictionary] forKey:aSessionID];
}

- (void)leaveSessionID:(NSString *)aSessionID {
    [I_propertiesBySessionID removeObjectForKey:aSessionID];
}

- (NSMutableDictionary *)propertiesForSessionID:(NSString *)aSessionID {
    return [I_propertiesBySessionID objectForKey:aSessionID];
}

- (void)updateWithUser:(TCMMMUser *)aUser {
    NSParameterAssert([[aUser userID] isEqualTo:[self userID]]);
    [self setProperties:[aUser properties]];
    [self setName:[aUser name]];
    [self setChangeCount:[aUser changeCount]];
}

@end
