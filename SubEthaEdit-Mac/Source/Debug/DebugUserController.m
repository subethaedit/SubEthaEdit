//
//  DebugUserController.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Sun Apr 25 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#ifndef TCM_NO_DEBUG


#import "DebugUserController.h"
#import "TCMMMUserManager.h"


@implementation DebugUserController

- (id)init {
    if ((self=[super initWithWindowNibName:@"DebugUsers"])) {
    }
    return self;
}

- (void)showWindow:(id)aSender {
    [super showWindow:(id)aSender];
    [O_allUsersController setContent:[[TCMMMUserManager sharedInstance] allUsers]];
}
@end


#endif