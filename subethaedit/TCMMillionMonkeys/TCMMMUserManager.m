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

+(TCMMMUserManager *)sharedInstance {
    if (!sharedInstance) {
        sharedInstance = [self new];
    }
    return sharedInstance;
}

-(id)init {
    if ((self=[super init])) {
        I_usersByID=[NSMutableDictionary new];
    }
    return self;
}

-(void)dealloc {
    [super dealloc];
}

@end
