//  DebugUserController.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Sun Apr 25 2004.

#ifndef TCM_NO_DEBUG


#import "DebugPresenceController.h"
#import "TCMMMPresenceManager.h"


@implementation DebugPresenceController

- (instancetype)init {
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
