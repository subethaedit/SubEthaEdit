//
//  DebugController.m
//  SubEthaEdit
//
//  Created by Martin Ott on Fri Apr 23 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#ifndef TCM_NO_DEBUG


#import "DebugController.h"
#import "DebugBEEPController.h"
#import "DebugUserController.h"
#import "DebugPresenceController.h"


static DebugController * sharedInstance = nil;


@implementation DebugController

+ (DebugController *)sharedInstance
{
    return sharedInstance ? sharedInstance : [[self alloc] init];
}

- (id)init {
    if (sharedInstance) {
        [self release];
    } else if ((self = [super init])) {
        sharedInstance = self;
    }
    return sharedInstance;
}

- (void)enableDebugMenu:(BOOL)flag
{
    int indexOfDebugMenu = [[NSApp mainMenu] indexOfItemWithTitle:@"Debug"];
    
    if (flag && indexOfDebugMenu == -1) {
        NSMenuItem *debugItem = [[NSMenuItem alloc] initWithTitle:@"Debug" action:nil keyEquivalent:@""];
        NSMenu *menu = [[[NSMenu alloc] initWithTitle:@"Debug"] autorelease];
        
        NSMenuItem *usersItem = [[NSMenuItem alloc] initWithTitle:@"Show Users" action:@selector(showUsers:) keyEquivalent:@""];
        [usersItem setTarget:self];
        [menu addItem:usersItem];
        [usersItem release];
        
        NSMenuItem *presenceItem = [[NSMenuItem alloc] initWithTitle:@"Show Presence" action:@selector(showPresence:) keyEquivalent:@""];
        [presenceItem setTarget:self];
        [menu addItem:presenceItem];
        [presenceItem release];
        
        NSMenuItem *BEEPItem = [[NSMenuItem alloc] initWithTitle:@"Show Sessions & Channels" action:@selector(showBEEP:) keyEquivalent:@""];
        [BEEPItem setTarget:self];
        [menu addItem:BEEPItem];
                
        [debugItem setSubmenu:menu];
        [[NSApp mainMenu] addItem:debugItem];
        [debugItem release];
    } else if (flag == NO && indexOfDebugMenu != -1) {
        [[NSApp mainMenu] removeItemAtIndex:indexOfDebugMenu];
    }
}

- (IBAction)showPresence:(id)aSender {
    if (!I_debugPresenceController) {
        I_debugPresenceController = [DebugPresenceController new];
    }
    [I_debugPresenceController showWindow:aSender];
}

- (IBAction)showUsers:(id)aSender {
    if (!I_debugUserController) {
        I_debugUserController = [DebugUserController new];
    }
    [I_debugUserController showWindow:aSender];
}

- (IBAction)showBEEP:(id)sender {
    if (!I_debugBEEPController) {
        I_debugBEEPController = [DebugBEEPController new];
    }
    [I_debugBEEPController showWindow:sender];
}

@end


#endif
