//
//  TCMMMUser.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Wed Feb 25 2004.
//  Copyright (c) 2004-2007 TheCodingMonkeys. All rights reserved.
//

#import "TCMFoundation.h"
#import "TCMBencodingUtilities.h"
#import "TCMMMUserManager.h"
#import "TCMMMUser.h"

// this file needs arc - either project wide,
// or add -fobjc-arc on a per file basis in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

NSString * const TCMMMUserPropertyKeyImageAsPNGData = @"ImageAsPNG";


NSString * const TCMMMUserWillLeaveSessionNotification = @"TCMMMUserWillLeaveSessionNotification";

@interface TCMMMUser ()
@property (nonatomic, copy) NSString *userIDIncludingChangeCount;
@end

@implementation TCMMMUser

#pragma mark - User with Notification
+ (instancetype)userWithNotification:(NSDictionary *)aNotificationDict {
	if (![[aNotificationDict objectForKey:@"name"] isKindOfClass:[NSString class]] ||
		![[aNotificationDict objectForKey:@"cnt"]  isKindOfClass:[NSNumber class]] ||
		![[aNotificationDict objectForKey:@"uID"]  isKindOfClass:[NSData   class]]
	) {
		return nil;
	}
	
	NSString *userID=[NSString stringWithUUIDData:[aNotificationDict objectForKey:@"uID"]];
	if (!userID) return nil;
    TCMMMUser *user=[TCMMMUser new];
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

#pragma mark
- (id)init {
    if ((self=[super init])) {
        I_properties=[NSMutableDictionary new];
        I_propertiesBySessionID=[NSMutableDictionary new];
        [self updateChangeCount];
    }
    return self;
}

#pragma mark
- (NSString *)description {
    return [NSString stringWithFormat:@"TCMMMUser <ID:%@,Name:%@,properties:%lu,cc:%llu>",[self userID],[self name],(unsigned long)[[self properties] count], self.changeCount];
}

#pragma mark
- (BOOL)isMe {
    return [[self userID] isEqualToString:[TCMMMUserManager myUserID]];
}

#pragma mark - Properties
- (NSMutableDictionary *)properties {
    return I_properties;
}

- (void)setProperties:(NSMutableDictionary *)aDictionary {
     I_properties = [aDictionary mutableCopy];
}

#pragma mark - Change Count
- (void)updateChangeCount {
    [self setChangeCount:(long long)[NSDate timeIntervalSinceReferenceDate]];
	self.userIDIncludingChangeCount = nil;
}

- (NSString *)userIDIncludingChangeCount {
	if (!_userIDIncludingChangeCount) {
		_userIDIncludingChangeCount = [NSString stringWithFormat:@"%@+%lld",self.userID,self.changeCount];
	}
	return _userIDIncludingChangeCount;
}

#pragma mark - Session
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

#pragma mark
- (void)updateWithUser:(TCMMMUser *)aUser {
    NSParameterAssert([[aUser userID] isEqualTo:[self userID]]);
    [self setProperties:[aUser properties]];
    [self setName:[aUser name]];
    [self setChangeCount:[aUser changeCount]];
}

#pragma mark
- (NSString *)shortDescription {
    NSMutableArray *additionalData = [NSMutableArray arrayWithObject:[self userID]];
    if ([[self properties] objectForKey:@"AIM"] && [(NSString*)[[self properties] objectForKey:@"AIM"] length]>0) 
        [additionalData addObject:[NSString stringWithFormat:@"aim:%@",[[self properties] objectForKey:@"AIM"]]];
    if ([[self properties] objectForKey:@"Email"] && [(NSString*)[[self properties] objectForKey:@"Email"] length] >0) 
        [additionalData addObject:[NSString stringWithFormat:@"mail:%@",[[self properties] objectForKey:@"Email"]]];
    return [NSString stringWithFormat:@"%@ (%@)",[self name],[additionalData componentsJoinedByString:@", "]];
}


#pragma mark - User Class methods
+ (instancetype)userWithBencodedUser:(NSData *)aData {
    NSDictionary *userDict = TCM_BdecodedObjectWithData(aData);
    return [self userWithDictionaryRepresentation:userDict];
}

+ (instancetype)userWithDictionaryRepresentation:(NSDictionary *)aRepresentation {
    // bail out for malformed data
    if (![[aRepresentation objectForKey:@"name"] isKindOfClass:[NSString class]] ||
        ![[aRepresentation objectForKey:@"uID"] isKindOfClass:[NSData class]] ||
        ![[aRepresentation objectForKey:@"cnt"] isKindOfClass:[NSNumber class]] ||
        ([aRepresentation objectForKey:@"PNG"] && ![[aRepresentation objectForKey:@"PNG"] isKindOfClass:[NSData class]]) ||
        ([aRepresentation objectForKey:@"hue"] && ![[aRepresentation objectForKey:@"hue"] isKindOfClass:[NSNumber class]]))
    {
        return nil;
    }
    
    TCMMMUser *user = [[TCMMMUser alloc] init];
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
    
    [user setUserHue:[aRepresentation objectForKey:@"hue"]];

	if ([aRepresentation[@"hDI"] boolValue]) {
		user.properties[@"HasDefaultImage"] = @(YES);

	} else {
		NSData *pngData = [aRepresentation objectForKey:@"PNG"];
		[user setImageWithPNGData:pngData];
	}
    return user;
}

#pragma mark - Image
- (void)setImageWithPNGData:(NSData *)aPNGData {
	if (aPNGData &&
		aPNGData.length > 0) {
		NSString *md5String = [aPNGData md5String];
		static NSArray *emptyImageHashes = nil;
		if (emptyImageHashes == nil) {
			emptyImageHashes = @[
								 @"f5053bc845cf64013f86610e5c47baaf", // SubEthaEdit old
								 @"7d4a805849dc48827b2bc860431b734b", // Coda old
								 ];
		}
		//NSLog(@"%s md5:%@ userName:%@",__FUNCTION__,md5String,self.name);
		if (![emptyImageHashes containsObject:md5String]) {
			[self.properties setObject:aPNGData forKey:TCMMMUserPropertyKeyImageAsPNGData];

		} else {
			[self.properties setObject:@(YES) forKey:@"HasDefaultImage"];
		}
		// when asking for the image it will be created from the data
		// if there is no image and no data the default image will be set automatically and the default image flag will be turned on

	}
}

#pragma mark
- (NSDictionary *)dictionaryRepresentation {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    if ([self userID]) [dict setObject:[NSData dataWithUUIDString:[self userID]] forKey:@"uID"];
    if ([self name]) [dict setObject:[self name] forKey:@"name"];
    if ([[self properties] objectForKey:@"AIM"]) [dict setObject:[[self properties] objectForKey:@"AIM"] forKey:@"AIM"];
    if ([[self properties] objectForKey:@"Email"]) [dict setObject:[[self properties] objectForKey:@"Email"] forKey:@"mail"];
    if ([[self properties] objectForKey:TCMMMUserPropertyKeyImageAsPNGData]) [dict setObject:[[self properties] objectForKey:TCMMMUserPropertyKeyImageAsPNGData] forKey:@"PNG"];
    if ([[self properties] objectForKey:@"Hue"]) [dict setObject:[[self properties] objectForKey:@"Hue"] forKey:@"hue"];
	[dict setObject:[[self properties] objectForKey:@"HasDefaultImage"]?:@(NO) forKey:@"hDI"];
    [dict setObject:[NSNumber numberWithLong:[self changeCount]] forKey:@"cnt"];
    return dict;
}

- (NSData *)userBencoded {
    NSDictionary *user = [self dictionaryRepresentation];
    return TCM_BencodedObject(user);
}

#pragma mark
- (void)setUserHue:(NSNumber *)aHue {
    if (aHue) {
        [[self properties] setObject:aHue forKey:@"Hue"];
        [[self properties] removeObjectForKey:@"ChangeColor"];
		[self updateChangeCount];
    }
}

#pragma mark
- (NSString *)aim {
    NSString *result = [[self properties] objectForKey:@"AIM"];
    if (result && [result length]>0) return result;
    else return nil;
}
- (NSString *)email {
    NSString *result = [[self properties] objectForKey:@"Email"];
    if (result && [result length]>0) return result;
    else return nil;
}

@end
