//
//  TCMMMUser.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Wed Feb 25 2004.
//  Copyright (c) 2004-2007 TheCodingMonkeys. All rights reserved.
//

#import "TCMBencodingUtilities.h"
#import "TCMMMUserManager.h"
#import "TCMMMUser.h"

NSString * const TCMMMUserWillLeaveSessionNotification =
               @"TCMMMUserWillLeaveSessionNotification";

@interface TCMMMUser (TCMMMUserPrivateAdditions) 

- (void)setProperties:(NSMutableDictionary *)aDictionary;

@end

@implementation TCMMMUser

+ (id)userWithNotification:(NSDictionary *)aNotificationDict {
	if (![[aNotificationDict objectForKey:@"name"] isKindOfClass:[NSString class]] ||
		![[aNotificationDict objectForKey:@"cnt"]  isKindOfClass:[NSNumber class]] ||
		![[aNotificationDict objectForKey:@"uID"]  isKindOfClass:[NSData   class]]
	) {
		return nil;
	}
	NSString *userID=[NSString stringWithUUIDData:[aNotificationDict objectForKey:@"uID"]];
	if (!userID) return nil;
    TCMMMUser *user=[[TCMMMUser new] autorelease];
    [user setName:[aNotificationDict objectForKey:@"name"]];
    [user setUserID:userID];
    [user setChangeCount:[[aNotificationDict objectForKey:@"cnt"] longLongValue]];
    return user;
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
        [self name],@"name",
        [NSData dataWithUUIDString:[self userID]],@"uID",
        [NSNumber numberWithLongLong:[self changeCount]],@"cnt", nil];
}

- (id)init {
    if ((self=[super init])) {
        I_properties=[NSMutableDictionary new];
        I_propertiesBySessionID=[NSMutableDictionary new];
        [self updateChangeCount];
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

- (BOOL)isMe {
    return [[self userID] isEqualToString:[TCMMMUserManager myUserID]];
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

- (void)updateChangeCount {
    [self setChangeCount: (long long)[NSDate timeIntervalSinceReferenceDate]];
}


- (void)joinSessionID:(NSString *)aSessionID {
    if (!([I_propertiesBySessionID objectForKey:aSessionID]==nil)) DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"User already joined");
    [I_propertiesBySessionID setObject:[NSMutableDictionary dictionary] forKey:aSessionID];
}

- (void)leaveSessionID:(NSString *)aSessionID {
    [[NSNotificationCenter defaultCenter] postNotificationName:TCMMMUserWillLeaveSessionNotification object:self userInfo:[NSDictionary dictionaryWithObject:aSessionID forKey:@"SessionID"]];
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

#pragma mark -

+ (TCMMMUser *)userWithBencodedUser:(NSData *)aData {
    NSDictionary *userDict = TCM_BdecodedObjectWithData(aData);
    return [self userWithDictionaryRepresentation:userDict];
}

+ (TCMMMUser *)userWithDictionaryRepresentation:(NSDictionary *)aRepresentation {
    // bail out for malformed data
    if (![[aRepresentation objectForKey:@"name"] isKindOfClass:[NSString class]] ||
        ![[aRepresentation objectForKey:@"uID"] isKindOfClass:[NSData class]] ||
        ![[aRepresentation objectForKey:@"cnt"] isKindOfClass:[NSNumber class]] ||
        ![[aRepresentation objectForKey:@"PNG"] isKindOfClass:[NSData class]] ||
        ![[aRepresentation objectForKey:@"hue"] isKindOfClass:[NSNumber class]])
    {
        return nil;
    }
    
    TCMMMUser *user = [[[TCMMMUser alloc] init] autorelease];
    [user setName:[aRepresentation objectForKey:@"name"]];
	NSString *userID = [NSString stringWithUUIDData:[aRepresentation objectForKey:@"uID"]];
	if (!userID) return nil;
    [user setUserID:userID];
    
    [user setChangeCount:[[aRepresentation objectForKey:@"cnt"] longLongValue]];
    
    NSString *string = [aRepresentation objectForKey:@"AIM"];
    if (string == nil) string = @"";
    else if (![string isKindOfClass:[NSString class]])  return nil;
    [[user properties] setObject:string forKey:@"AIM"];
    
    string = [aRepresentation objectForKey:@"mail"];
    if (string == nil) string = @"";
    else if (![string isKindOfClass:[NSString class]]) return nil;
    [[user properties] setObject:string forKey:@"Email"];
    
    NSData *pngData = [aRepresentation objectForKey:@"PNG"];
    if (pngData) [[user properties] setObject:pngData forKey:@"ImageAsPNG"];
    
    [user setUserHue:[aRepresentation objectForKey:@"hue"]];

    return user;
}

- (NSDictionary *)dictionaryRepresentation {
    return [NSDictionary dictionaryWithObjectsAndKeys:
        [[self properties] objectForKey:@"AIM"], @"AIM",
        [[self properties] objectForKey:@"Email"], @"mail",
        [self name], @"name",
        [NSData dataWithUUIDString:[self userID]], @"uID",
        [[self properties] objectForKey:@"ImageAsPNG"], @"PNG",
        [NSNumber numberWithLong:[self changeCount]], @"cnt",
        [[self properties] objectForKey:@"Hue"], @"hue",
        nil];
}

- (NSData *)userBencoded {
    NSDictionary *user = [self dictionaryRepresentation];
    return TCM_BencodedObject(user);
}

- (void)setUserHue:(NSNumber *)aHue {
    if (aHue) {
        [[self properties] setObject:aHue forKey:@"Hue"];
        [[self properties] removeObjectForKey:@"ColorImage"];
        [[self properties] removeObjectForKey:@"ChangeColor"];
    }
}

@end
