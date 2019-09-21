//  DebugController.m
//  SubEthaEdit
//
//  Created by Martin Ott on Fri Apr 23 2004.

#ifndef TCM_NO_DEBUG


#import "DebugController.h"
#import "DebugBEEPController.h"
#import "DebugUserController.h"
#import "DebugPresenceController.h"
#import "DebugSendOperationController.h"
#import "DebugHistoryController.h"
#import "TCMMMBEEPSessionManager.h"
#import "DocumentProxyWindowController.h"
#import "TCMMillionMonkeys.h"
#import "TCMMMUserSEEAdditions.h"
#import "SEEDocumentController.h"
#import "DebugAttributeInspectorController.h"
#import "AppController.h"
#import "SEEDebugImageGenerationWindowController.h"

static DebugController * sharedInstance = nil;


@implementation DebugController

+ (DebugController *)sharedInstance
{
    return sharedInstance ? sharedInstance : [[self alloc] init];
}

- (instancetype)init {
    if (sharedInstance) {
		self = nil;
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

- (void)userDidChange:(NSNotification *)aNotification { // save user to : .*/Caches/de.codingmonkeys.SubEthaEdit.Mac/%@.vcf and %@.png
    TCMMMUser *user = [[aNotification userInfo] objectForKey:@"User"];
    if (![user isEqual:[TCMMMUserManager me]]) {
		NSFileManager *fileManager = [NSFileManager defaultManager];
		NSArray *possibleURLs = [fileManager URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask];
		NSURL *cachesDirectory = nil;

		if ([possibleURLs count] >= 1) { // Use the first directory (if multiple are returned)
			cachesDirectory = [possibleURLs objectAtIndex:0];
		}
		if (cachesDirectory) {
			NSString *appBundleID = [[NSBundle mainBundle] bundleIdentifier];
			cachesDirectory = [cachesDirectory URLByAppendingPathComponent:appBundleID];

			NSString *saveName = [NSString stringWithFormat:@"%@ - %@", [user name], [user userID]];
			NSURL *vCardURL = [cachesDirectory URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.vcf", saveName]];
			NSData *vcard = [[user vcfRepresentation] dataUsingEncoding:NSUnicodeStringEncoding];
			[vcard writeToURL:vCardURL atomically:YES];

			if (![user hasDefaultImage]) {
				NSURL *imageURL = [cachesDirectory URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", saveName]];
				[user writeImageToUrl:imageURL];
			}
		}
	}
}

- (void)enableDebugMenu:(BOOL)flag
{
    NSInteger indexOfDebugMenu = [[NSApp mainMenu] indexOfItemWithTitle:@"Debug"];
    
    if (flag && indexOfDebugMenu == -1) {
        NSMenuItem *debugItem = [[NSMenuItem alloc] initWithTitle:@"Debug" action:nil keyEquivalent:@""];
        NSMenu *menu = [[NSMenu alloc] initWithTitle:@"Debug"];
        
        NSMenuItem *usersItem = [[NSMenuItem alloc] initWithTitle:@"Users Viewer" action:@selector(showUsers:) keyEquivalent:@""];
        [usersItem setTarget:self];
        [menu addItem:usersItem];
        
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:@"Image Generation Debug Window" action:@selector(showDebugImageGenerationWindowController:) keyEquivalent:@""];
        [item setTarget:self];
        [menu addItem:item];
		
        NSMenuItem *presenceItem = [[NSMenuItem alloc] initWithTitle:@"Presence Viewer" action:@selector(showPresence:) keyEquivalent:@""];
        [presenceItem setTarget:self];
        [menu addItem:presenceItem];
        
        NSMenuItem *BEEPItem = [[NSMenuItem alloc] initWithTitle:@"Sessions Viewer" action:@selector(showBEEP:) keyEquivalent:@""];
        [BEEPItem setTarget:self];
        [menu addItem:BEEPItem];
        
        [menu addItem:[NSMenuItem separatorItem]];

		NSMenuItem *styleEditorItem = [[NSMenuItem alloc] initWithTitle:@"Style Sheet Editor" action:@selector(showStyleSheetEditorWindow:) keyEquivalent:@""];
        [styleEditorItem setTarget:[AppController sharedInstance]];
        [menu addItem:styleEditorItem];

        [menu addItem:[NSMenuItem separatorItem]];

        NSMenuItem *sendOperationItem = [[NSMenuItem alloc] initWithTitle:@"Show Send Operation..." action:@selector(showSendOperation:) keyEquivalent:@""];
        [sendOperationItem setTarget:self];
        [menu addItem:sendOperationItem];

        NSMenuItem *CrashItem = [[NSMenuItem alloc] initWithTitle:@"Crash Application" action:@selector(crash:) keyEquivalent:@""];
        [CrashItem setTarget:self];
        [menu addItem:CrashItem];

        NSMenuItem *CrashReportItem = [[NSMenuItem alloc] initWithTitle:@"Resend Last Crash Report" action:@selector(sendCrashReport:) keyEquivalent:@""];
        [CrashReportItem setTarget:self];
        [menu addItem:CrashReportItem];
		
		[NSOperationQueue TCM_performBlockOnMainQueue:^{
			NSMenuItem *blahItem = [[NSMenuItem alloc] initWithTitle:SEE_NoLocalizationNeeded(@"Log All BEEP Session Retain Counts") action:@selector(logRetainCounts) keyEquivalent:@""];
			[blahItem setTarget:[TCMMMBEEPSessionManager sharedInstance]];
			[menu addItem:blahItem];
		} afterDelay:0.0];
        
        [debugItem setSubmenu:menu];
        [[NSApp mainMenu] addItem:debugItem];

        NSMenuItem *blahItem = [[NSMenuItem alloc] initWithTitle:@"Copy Document Thumbnail to Pasteboard" action:@selector(createThumbnail:) keyEquivalent:@""];
        [blahItem setTarget:nil];
        [menu addItem:blahItem];

        blahItem = [[NSMenuItem alloc] initWithTitle:@"Toggle Dialog View" action:@selector(toggleDialogView:) keyEquivalent:@""];
        [blahItem setTarget:nil];
        [menu addItem:blahItem];

        blahItem = [[NSMenuItem alloc] initWithTitle:@"Create Proxy Window" action:@selector(createProxyWindow:) keyEquivalent:@""];
        [blahItem setTarget:self];
        [menu addItem:blahItem];

        blahItem = [[NSMenuItem alloc] initWithTitle:@"Show History Debugger" action:@selector(showHistoryDebugger:) keyEquivalent:@""];
        [blahItem setTarget:self];
        [menu addItem:blahItem];

        blahItem = [[NSMenuItem alloc] initWithTitle:@"Playback file" action:@selector(playbackLoggingState:) keyEquivalent:@""];
        [blahItem setTarget:nil];
        [menu addItem:blahItem];

        blahItem = [[NSMenuItem alloc] initWithTitle:@"Reverse Playback file" action:@selector(reversePlaybackLoggingState:) keyEquivalent:@""];
        [blahItem setTarget:nil];
        [menu addItem:blahItem];

        blahItem = [[NSMenuItem alloc] initWithTitle:@"Log Mode Precedences to console" action:@selector(printModePrecedences:) keyEquivalent:@""];
        [blahItem setTarget:self];
        [menu addItem:blahItem];
	
        blahItem = [[NSMenuItem alloc] initWithTitle:@"Show Attribute Inspector..." action:@selector(showAttributeInspector:) keyEquivalent:@"a"];
		[blahItem setKeyEquivalentModifierMask:NSEventModifierFlagOption | NSEventModifierFlagControl];
        [blahItem setTarget:self];
        [menu addItem:blahItem];

    } else if (flag == NO && indexOfDebugMenu != -1) {
        [[NSApp mainMenu] removeItemAtIndex:indexOfDebugMenu];
    }
}

- (IBAction)showDebugImageGenerationWindowController:(id)aSender {
	if (!I_debugImageGenerationWindowController) {
		I_debugImageGenerationWindowController = [SEEDebugImageGenerationWindowController new];
	}
	[I_debugImageGenerationWindowController showWindow:aSender];
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
    [[SEEDocumentController sharedDocumentController] addProxyDocumentWithSession:testSession];
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
    NSLog(@"%@",(__bridge NSString *)(void *)0xAFFE); // This is supposed to crash, don't fix.
}


- (IBAction)sendCrashReport:(id)sender {
	// do crash reports here?
}

- (IBAction)printModePrecedences:(id)aSender {
    NSLog(@"%s %@",__FUNCTION__,[[[NSUserDefaults standardUserDefaults] objectForKey:@"ModePrecedences"] performSelector:@selector(debugDescription)]);
}

@end


#endif
