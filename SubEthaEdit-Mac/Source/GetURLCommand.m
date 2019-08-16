//  GetURLCommand.m
//  SubEthaEdit
//
//  Created by Martin Ott on Wed May 05 2004.

#import "GetURLCommand.h"
#import "SEEConnectionManager.h"
#import "SEEDocumentController.h"

@implementation GetURLCommand

- (id)performDefaultImplementation {
    DEBUGLOG(@"InternetLogDomain", SimpleLogLevel, @"GetURLCommand: %@", [self description]);
    DEBUGLOG(@"InternetLogDomain", DetailedLogLevel, @"command: %@", [[self commandDescription] commandName]);
    NSString *address = [self directParameter];
    DEBUGLOG(@"InternetLogDomain", DetailedLogLevel, @"address: %@", address);
    [[SEEDocumentController sharedInstance] showDocumentListWindow:nil];
    [[SEEConnectionManager sharedInstance] connectToAddress:address];
    return nil;
}

@end
