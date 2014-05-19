//
//  TCMMMUser.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Wed Feb 25 2004.
//  Copyright (c) 2004-2007 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const TCMMMUserWillLeaveSessionNotification;
extern NSString * const TCMMMUserPropertyKeyImageAsPNGData;

@interface TCMMMUser : NSObject {
    NSMutableDictionary *I_properties;
    NSMutableDictionary *I_propertiesBySessionID;
}

@property (nonatomic, copy) NSString *userID;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, readonly, copy) NSString *userIDIncludingChangeCount;
@property (nonatomic) long long changeCount;

+ (instancetype)userWithNotification:(NSDictionary *)aNotificationDict;
+ (instancetype)userWithBencodedNotification:(NSData *)aData;
- (NSData *)notificationBencoded;
- (NSDictionary *)notification;

- (NSMutableDictionary *)properties;

- (BOOL)isMe;

- (void)updateChangeCount;

- (void)joinSessionID:(NSString *)aSessionID;
- (void)leaveSessionID:(NSString *)aSessionID;
- (NSMutableDictionary *)propertiesForSessionID:(NSString *)aSessionID;

- (void)updateWithUser:(TCMMMUser *)aUser;
- (NSString *)shortDescription;

#pragma mark -

+ (TCMMMUser *)userWithBencodedUser:(NSData *)aData;
+ (TCMMMUser *)userWithDictionaryRepresentation:(NSDictionary *)aRepresentation;

- (NSDictionary *)dictionaryRepresentation;
- (NSData *)userBencoded;

// can be nil
@property (nonatomic, strong) NSNumber *userHue;

#pragma mark -
#pragma mark ### accessors for convenience ###
// both accessors return nil if the property is an @"" so they can be used with @unionOfObjects
- (NSString *)aim;
- (NSString *)email;

@end
