//
//  GetURLCommand.m
//  SubEthaEdit
//
//  Created by Martin Ott on Wed May 05 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "GetURLCommand.h"

@implementation GetURLCommand

- (id)performDefaultImplementation
{
    DEBUGLOG(@"InternetLogDomain", SimpleLogLevel, @"GetURLCommand: %@", [self description]);
    DEBUGLOG(@"InternetLogDomain", DetailedLogLevel, @"command: %@", [[self commandDescription] commandName]);
    NSString *address = [self directParameter];
    DEBUGLOG(@"InternetLogDomain", DetailedLogLevel, @"address: %@", address);
//    [[ConnectionBrowserController sharedInstance] connectToAddress:address];

    return nil;
}

@end
