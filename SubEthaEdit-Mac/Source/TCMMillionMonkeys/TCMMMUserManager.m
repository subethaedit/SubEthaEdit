//  TCMMMUserManager.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Wed Feb 25 2004.

#import "TCMMMUserManager.h"
#import "TCMMMUser.h"
#import "TCMMMStatusProfile.h"
#import "TCMMMPresenceManager.h"

// this file needs arc - add -fobjc-arc in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif


NSString * const TCMMMUserManagerUserDidChangeNotification = @"TCMMMUserManagerUserDidChangeNotification";

static TCMMMUserManager *sharedInstance=nil;

@implementation TCMMMUserManager

+ (TCMMMUserManager *)sharedInstance {
    if (!sharedInstance) {
        sharedInstance = [self new];
    }
    return sharedInstance;
}

+ (TCMMMUser *)me {
    return [[self sharedInstance] me];
}

+ (NSString *)myUserID {
    return [[self sharedInstance] myUserID];
}

+ (void)didChangeMe {
    [[self sharedInstance] didChangeMe];
}

- (void)didChangeMe {
    // alter change count
    TCMMMUser *me=[self me];
    [me updateChangeCount];
    // announce change via notification
    [[NSNotificationCenter defaultCenter] postNotificationName:TCMMMUserManagerUserDidChangeNotification object:self userInfo:[NSDictionary dictionaryWithObject:me forKey:@"User"]];
    // announce change via status channels
    [[TCMMMPresenceManager sharedInstance] propagateChangeOfMyself];
}

- (instancetype)init {
    if ((self=[super init])) {
        I_usersByID=[NSMutableDictionary new];
        I_userRequestsByID=[NSMutableDictionary new];
    }
    return self;
}


- (void)setMe:(TCMMMUser *)aUser {
     I_me = aUser;
    [self setUser:I_me forUserID:[I_me userID]];
}
- (TCMMMUser *)me {
    return I_me;
}
- (NSString *)myUserID {
    return [[self me] userID];
}
- (TCMMMUser *)userForUserID:(NSString *)aID {
    return [I_usersByID objectForKey:aID];
}
- (void)setUser:(TCMMMUser *)aUser forUserID:(NSString *)aID {
    DEBUGLOG(@"MillionMonkeysLogDomain",AllLogLevel,@"Set user:%@ forID:%@",aUser,aID);
    [I_usersByID setObject:aUser forKey:aID];
}

- (void)addUser:(TCMMMUser *)aUser {
    DEBUGLOG(@"MillionMonkeysLogDomain",AllLogLevel,@"AddUser: %@",aUser);
    NSAssert(aUser,@"TCMMMUserManager add: User added must not be nil!");
    if (!aUser) {
        NSLog(@"Adding a nil user");
        return;
    }
    NSString *userID=[aUser userID];
    TCMMMUser *user=[self userForUserID:userID];
    BOOL userDidChange=NO;
    if (user) {
        if ([aUser changeCount] > [user changeCount]) {
            userDidChange=YES;
            [user updateWithUser:aUser];
            aUser=user;
        }
    } else {
        userDidChange=YES;
        [I_usersByID setObject:aUser forKey:userID];
        DEBUGLOG(@"MillionMonkeysLogDomain",AllLogLevel,@"new user set");
    }
    if (userDidChange) {
        NSMutableDictionary *request=[I_userRequestsByID objectForKey:userID];
        if (request) {
            if ([aUser changeCount] >= [(TCMMMUser *)[request objectForKey:@"User"] changeCount]) {
                [I_userRequestsByID removeObjectForKey:userID];
            }
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:TCMMMUserManagerUserDidChangeNotification object:self userInfo:[NSDictionary dictionaryWithObject:aUser forKey:@"User"]];
    }
}

- (BOOL)sender:(id)aSender shouldRequestUser:(TCMMMUser *)aUser {
    NSString *userID=[aUser userID];
    TCMMMUser *user=[self userForUserID:userID];
    if (!user) {
        user=[TCMMMUser new];
        [user setChangeCount:0];
        [user setUserID:userID];
        [user setName:[aUser name]];
		[user setUserHue:aUser.userHue];
        [self setUser:user forUserID:userID];
    }
    if ([user changeCount]<[aUser changeCount]) {
        NSMutableDictionary *request=[I_userRequestsByID objectForKey:userID];
        if (request) {
            if ([aUser changeCount] > [(TCMMMUser *)[request objectForKey:@"User"] changeCount]) {
                [request setObject:aUser forKey:@"User"];
                TCMMMStatusProfile *statusProfile=[[TCMMMPresenceManager sharedInstance] statusProfileForUserID:userID];
                if (statusProfile && statusProfile!=aSender) {
                    [request setObject:[NSValue valueWithPointer:(const void *)statusProfile] forKey:@"Sender"];
                    [statusProfile requestUser];
                    return NO;
                } else {
                    [request setObject:[NSValue valueWithPointer:(const void *)aSender] forKey:@"Sender"];
                    return YES;
                }
            } else {
                return NO;
            }
        } else {
            request=[NSMutableDictionary dictionary];
            [I_userRequestsByID setObject:request forKey:userID];
            [request setObject:aUser forKey:@"User"];
            TCMMMStatusProfile *statusProfile=[[TCMMMPresenceManager sharedInstance] statusProfileForUserID:userID];
            if (statusProfile && statusProfile!=aSender) {
                [request setObject:[NSValue valueWithPointer:(const void *)statusProfile] forKey:@"Sender"];
                [statusProfile requestUser];
                return NO;
            } else {
                [request setObject:[NSValue valueWithPointer:(const void *)aSender] forKey:@"Sender"];
                return YES;
            }
        }
    } else {
        return NO;
    }
}

- (NSArray *)allUsers {
    return [I_usersByID allValues];
}

@end
