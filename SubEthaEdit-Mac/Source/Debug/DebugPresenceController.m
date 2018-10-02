//
//  DebugUserController.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Sun Apr 25 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#ifndef TCM_NO_DEBUG


#import "DebugPresenceController.h"
#import "TCMMMPresenceManager.h"


@implementation DebugPresenceController

- (id)init {
    if ((self=[super initWithWindowNibName:@"DebugPresence"])) {
    }
    return self;
}

- (void)showWindow:(id)aSender {
    [super showWindow:(id)aSender];
    [O_allUsersController setContent:[[TCMMMPresenceManager sharedInstance] allUsers]];
}
@end


#endif