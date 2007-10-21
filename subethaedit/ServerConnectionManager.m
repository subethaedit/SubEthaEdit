//
//  ServerConnectionManager.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 26.04.07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import "ServerConnectionManager.h"
#import "ServerConnectionWindowController.h"
#import "TCMMillionMonkeys.h"

static ServerConnectionManager *S_sharedInstance = nil;

@implementation ServerConnectionManager

+ (id)sharedInstance {
    if (!S_sharedInstance) [[ServerConnectionManager alloc] init];
    return S_sharedInstance;
}

- (id)init {
    if ((self=[super init])) {
        _windowControllers = [NSMutableArray new];
        S_sharedInstance = self;
    }
    return self;
}

- (void)dealloc {
    [_windowControllers release];
    [super dealloc];
}

- (void)openServerConnectionUsingBEEPSession:(TCMBEEPSession *)aSession {
    NSLog(@"%s",__FUNCTION__);
}

- (void)addConnectionToUser:(TCMMMUser *)aUser {
    ServerConnectionWindowController *wc = 
        [[[ServerConnectionWindowController alloc] initWithMMUser:aUser] autorelease];
    [wc showWindow:self];
    [_windowControllers addObject:wc];
}

- (BOOL)validateMenuItem:(NSMenuItem *)anItem {
    if ([anItem action] == @selector(openServerConnection:) ) {
        return [anItem isEnabled];
    }
    return YES;
}

- (IBAction)openServerConnection:(id)aSender {
    NSLog(@"%s %@",__FUNCTION__,[aSender representedObject]);
    NSEnumerator *userIDs = [[aSender representedObject] objectEnumerator];
    NSString *userID = nil;
    TCMMMUserManager *um = [TCMMMUserManager sharedInstance];
    while ((userID=[userIDs nextObject])) {
        [self addConnectionToUser:[um userForUserID:userID]];
    }
}

- (void)removeWindowController:(ServerConnectionWindowController *)aWindowController {
    [_windowControllers removeObject:aWindowController];
}

@end
