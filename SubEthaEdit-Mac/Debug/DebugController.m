//
//  DebugController.m
//  SubEthaEdit
//
//  Created by Martin Ott on Fri Apr 23 2004.
//  Copyright (c) 2004-2007 TheCodingMonkeys. All rights reserved.
//

#ifndef TCM_NO_DEBUG


#import "DebugController.h"
#import "DebugBEEPController.h"
#import "DebugUserController.h"
#import "DebugPresenceController.h"
#import "DebugSendOperationController.h"
#import "DebugHistoryController.h"
#import "TCMMMBEEPSessionManager.h"
#if !defined(CODA)
#import <HDCrashReporter/crashReporter.h>
#endif //!defined(CODA)
#import "DocumentProxyWindowController.h"
#import "TCMMillionMonkeys.h"
#import "TCMMMUserSEEAdditions.h"
#import "DocumentController.h"
#import "DebugAttributeInspectorController.h"


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
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DebugSaveUsersInCache"]) {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(userDidChange:)
                                                         name:TCMMMUserManagerUserDidChangeNotification
                                                       object:nil];
        }
    }
    return sharedInstance;
}

- (void)userDidChange:(NSNotification *)notification
{
    TCMMMUser *user = [[notification userInfo] objectForKey:@"User"];
    if (![user isEqual:[TCMMMUserManager me]]) {
        NSString *saveName = [NSString stringWithFormat:@"%@ - %@", [user name], [user userID]];
        NSData *vcard = [[user vcfRepresentation] dataUsingEncoding:NSUnicodeStringEncoding];
        [vcard writeToFile:[[NSString stringWithFormat:@"~/Library/Caches/SubEthaEdit/%@.vcf", saveName] stringByExpandingTildeInPath] atomically:YES];
        NSData *image = [[user properties] objectForKey:@"ImageAsPNG"];
        if (image) {
            [image writeToFile:[[NSString stringWithFormat:@"~/Library/Caches/SubEthaEdit/%@.png", saveName] stringByExpandingTildeInPath] atomically:YES];
        }
    }
}

- (void)enableDebugMenu:(BOOL)flag
{
    int indexOfDebugMenu = [[NSApp mainMenu] indexOfItemWithTitle:@"Debug"];
    
    if (flag && indexOfDebugMenu == -1) {
        NSMenuItem *debugItem = [[NSMenuItem alloc] initWithTitle:@"Debug" action:nil keyEquivalent:@""];
        NSMenu *menu = [[[NSMenu alloc] initWithTitle:@"Debug"] autorelease];
        
        NSMenuItem *usersItem = [[NSMenuItem alloc] initWithTitle:@"Users Viewer" action:@selector(showUsers:) keyEquivalent:@""];
        [usersItem setTarget:self];
        [menu addItem:usersItem];
        [usersItem release];
        
        NSMenuItem *presenceItem = [[NSMenuItem alloc] initWithTitle:@"Presence Viewer" action:@selector(showPresence:) keyEquivalent:@""];
        [presenceItem setTarget:self];
        [menu addItem:presenceItem];
        [presenceItem release];
        
        NSMenuItem *BEEPItem = [[NSMenuItem alloc] initWithTitle:@"Sessions Viewer" action:@selector(showBEEP:) keyEquivalent:@""];
        [BEEPItem setTarget:self];
        [menu addItem:BEEPItem];
        [BEEPItem release];
        
        [menu addItem:[NSMenuItem separatorItem]];

        NSMenuItem *sendOperationItem = [[NSMenuItem alloc] initWithTitle:@"Show Send Operation..." action:@selector(showSendOperation:) keyEquivalent:@""];
        [sendOperationItem setTarget:self];
        [menu addItem:sendOperationItem];
		[sendOperationItem release];

        NSMenuItem *CrashItem = [[NSMenuItem alloc] initWithTitle:@"Crash Application" action:@selector(crash:) keyEquivalent:@""];
        [CrashItem setTarget:self];
        [menu addItem:CrashItem];
		[CrashItem release];

        NSMenuItem *CrashReportItem = [[NSMenuItem alloc] initWithTitle:@"Resend Last Crash Report" action:@selector(sendCrashReport:) keyEquivalent:@""];
        [CrashReportItem setTarget:self];
        [menu addItem:CrashReportItem];
		[CrashReportItem release];

        NSMenuItem *blahItem = [[NSMenuItem alloc] initWithTitle:@"Log All BEEP Session Retain Counts" action:@selector(logRetainCounts) keyEquivalent:@""];
        [blahItem setTarget:[TCMMMBEEPSessionManager sharedInstance]];
        [menu addItem:blahItem];
        [blahItem release];
                
        [debugItem setSubmenu:menu];
        [[NSApp mainMenu] addItem:debugItem];
        [debugItem release];

        blahItem = [[NSMenuItem alloc] initWithTitle:@"Copy Document Thumbnail to Pasteboard" action:@selector(createThumbnail:) keyEquivalent:@""];
        [blahItem setTarget:nil];
        [menu addItem:blahItem];
        [blahItem release];

        blahItem = [[NSMenuItem alloc] initWithTitle:@"Toggle Dialog View" action:@selector(toggleDialogView:) keyEquivalent:@""];
        [blahItem setTarget:nil];
        [menu addItem:blahItem];
        [blahItem release];

        blahItem = [[NSMenuItem alloc] initWithTitle:@"Create Proxy Window" action:@selector(createProxyWindow:) keyEquivalent:@""];
        [blahItem setTarget:self];
        [menu addItem:blahItem];
        [blahItem release];

        blahItem = [[NSMenuItem alloc] initWithTitle:@"Show History Debugger" action:@selector(showHistoryDebugger:) keyEquivalent:@""];
        [blahItem setTarget:self];
        [menu addItem:blahItem];
        [blahItem release];

        blahItem = [[NSMenuItem alloc] initWithTitle:@"Playback file" action:@selector(playbackLoggingState:) keyEquivalent:@""];
        [blahItem setTarget:nil];
        [menu addItem:blahItem];
        [blahItem release];

        blahItem = [[NSMenuItem alloc] initWithTitle:@"Reverse Playback file" action:@selector(reversePlaybackLoggingState:) keyEquivalent:@""];
        [blahItem setTarget:nil];
        [menu addItem:blahItem];
        [blahItem release];


        blahItem = [[NSMenuItem alloc] initWithTitle:@"Quit Saving State" action:@selector(terminateForRestart:) keyEquivalent:@""];
        [blahItem setTarget:NSApp];
        [menu addItem:blahItem];
        [blahItem release];

        blahItem = [[NSMenuItem alloc] initWithTitle:@"Log Mode Precedences to console" action:@selector(printModePrecedences:) keyEquivalent:@""];
        [blahItem setTarget:self];
        [menu addItem:blahItem];
        [blahItem release];


        blahItem = [[NSMenuItem alloc] initWithTitle:@"Show Attribute Inspector..." action:@selector(showAttributeInspector:) keyEquivalent:@""];
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

- (IBAction)showSendOperation:(id)sender {
    if (!I_debugSendOperationController) {
         I_debugSendOperationController = [DebugSendOperationController new];
    }
        [I_debugSendOperationController showWindow:sender];
}

- (IBAction)showAttributeInspector:(id)sender {
    if (!I_debugAttributeInspectorController) {
         I_debugAttributeInspectorController = [DebugAttributeInspectorController new];
    }
        [I_debugAttributeInspectorController showWindow:sender];
}

- (IBAction)showHistoryDebugger:(id)aSender {
    static DebugHistoryController *cont = nil;
    if (!cont) cont = [DebugHistoryController new];
    [cont showWindow:aSender];
}

- (IBAction)crash:(id)sender {
    NSLog(@"%@",(NSString *)"crash here"); // This is supposed to crash, don't fix.
}


- (IBAction)sendCrashReport:(id)sender {
#if !defined(CODA)
    [HDCrashReporter doCrashSubmitting];
#endif //!defined(CODA)
}

- (IBAction)printModePrecedences:(id)aSender {
    NSLog(@"%s %@",__FUNCTION__,[[[NSUserDefaults standardUserDefaults] objectForKey:@"ModePrecedences"] performSelector:@selector(debugDescription)]);
}

@end


#endif
