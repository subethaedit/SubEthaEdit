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
#import "TCMMMBEEPSessionManager.h"
#import <HDCrashReporter/crashReporter.h>
#import "DocumentProxyWindowController.h"
#import "TCMMillionMonkeys.h"
#import "DocumentController.h"


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

        NSMenuItem *CrashItem = [[NSMenuItem alloc] initWithTitle:@"Crash Application" action:@selector(crash:) keyEquivalent:@""];
        [CrashItem setTarget:self];
        [menu addItem:CrashItem];

        NSMenuItem *CrashReportItem = [[NSMenuItem alloc] initWithTitle:@"Resend last crash report" action:@selector(sendCrashReport:) keyEquivalent:@""];
        [CrashReportItem setTarget:self];
        [menu addItem:CrashReportItem];

        NSMenuItem *blahItem = [[NSMenuItem alloc] initWithTitle:@"Show Retain Counts" action:@selector(printMist) keyEquivalent:@""];
        [blahItem setTarget:[TCMMMBEEPSessionManager sharedInstance]];
        [menu addItem:blahItem];
        [blahItem release];
                
        [debugItem setSubmenu:menu];
        [[NSApp mainMenu] addItem:debugItem];
        [debugItem release];

        blahItem = [[NSMenuItem alloc] initWithTitle:@"Copy Thumbnail Of current Document to pb" action:@selector(createThumbnail:) keyEquivalent:@""];
        [blahItem setTarget:nil];
        [menu addItem:blahItem];
        [blahItem release];

        blahItem = [[NSMenuItem alloc] initWithTitle:@"toggle dialog view" action:@selector(toggleDialogView:) keyEquivalent:@""];
        [blahItem setTarget:nil];
        [menu addItem:blahItem];
        [blahItem release];

        blahItem = [[NSMenuItem alloc] initWithTitle:@"create proxy window" action:@selector(createProxyWindow:) keyEquivalent:@""];
        [blahItem setTarget:self];
        [menu addItem:blahItem];
        [blahItem release];

    } else if (flag == NO && indexOfDebugMenu != -1) {
        [[NSApp mainMenu] removeItemAtIndex:indexOfDebugMenu];
    }
}

- (IBAction)createProxyWindow:(id)aSender {
    TCMMMSession *testSession = 
        [TCMMMSession sessionWithDictionaryRepresentation:
                [NSDictionary dictionaryWithObjectsAndKeys:
                    [NSData dataWithUUIDString:[NSString UUIDString]],@"sID",
                    @"/langer/pfad/mit/langer/Testsession.m",@"name",
                    [NSData dataWithUUIDString:[[TCMMMUserManager me] userID]],@"hID",
                    [NSNumber numberWithInt:TCMMMSessionAccessReadOnlyState],@"acc",
                nil]
            ];
    [testSession setClientState:TCMMMSessionClientInvitedState];
    [[DocumentController sharedDocumentController] addProxyDocumentWithSession:testSession];
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

- (IBAction)crash:(id)sender {
    NSLog((NSString *)"crash here"); // This is supposed to crash, don't fix.
}

- (IBAction)sendCrashReport:(id)sender {
    [HDCrashReporter doCrashSubmitting];
}

@end


#endif
