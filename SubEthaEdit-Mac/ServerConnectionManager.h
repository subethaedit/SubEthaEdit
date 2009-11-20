//
//  ServerConnectionManager.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 26.04.07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ServerConnectionWindowController;

@interface ServerConnectionManager : NSObject {
    NSMutableArray *_windowControllers;
}

+ (id)sharedInstance;

- (void)removeWindowController:(ServerConnectionWindowController *)aWindowController;

- (void)openServerConnectionUsingBEEPSession:(TCMBEEPSession *)aSession;
- (IBAction)openServerConnection:(id)aSender;

@end
