//
//  TCMMMUserManager.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Wed Feb 25 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "TCMMMUserManager.h"
#import "TCMMMUser.h"

static TCMMMUserManager *sharedInstance=nil;

@implementation TCMMMUserManager

+ (TCMMMUserManager *)sharedInstance {
    if (!sharedInstance) {
        sharedInstance = [self new];
    }
    return sharedInstance;
}

+ (NSString *)myID {
    return [[self sharedInstance] myID];
}

- (id)init {
    if ((self=[super init])) {
        I_usersByID=[NSMutableDictionary new];
    }
    return self;
}

- (void)dealloc {
    [I_usersByID release];
    [I_me release];
    [super dealloc];
}

- (void)setMe:(TCMMMUser *)aUser {
    [I_me autorelease];
     I_me = [aUser retain];
    [self setUser:I_me forID:[I_me ID]];
}
- (TCMMMUser *)me {
    return I_me;
}
- (NSString *)myID {
    return [[self me] ID];
}
- (TCMMMUser *)userForID:(NSString *)aID {
    return [I_usersByID objectForKey:aID];
}
- (void)setUser:(TCMMMUser *)aUser forID:(NSString *)aID {
    [I_usersByID setObject:aUser forKey:aID];
}


@end
