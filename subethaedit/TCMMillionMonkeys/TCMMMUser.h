//
//  TCMMMUser.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Wed Feb 25 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TCMMMUser : NSObject {
    NSMutableDictionary *I_properties;
    NSString *I_userID;
    NSString *I_serviceName;
    NSString *I_name;
    long long I_changeCount;
}

+ (id)userWithNotification:(NSDictionary *)aNotificationDict;
+ (id)userWithBencodedNotification:(NSData *)aData;
- (NSData *)notificationBencoded;
- (NSDictionary *)notification;

- (NSMutableDictionary *)properties;

- (void)setUserID:(NSString *)aID;
- (NSString *)userID;
- (void)setServiceName:(NSString *)aServiceName;
- (NSString *)serviceName;
- (void)setName:(NSString *)aName;
- (NSString *)name;
- (void)setChangeCount:(long long)aChangeCount;
- (long long)changeCount;


- (void)updateWithUser:(TCMMMUser *)aUser;

@end
