//
//  InternetBrowserController.m
//  SubEthaEdit
//
//  Created by Martin Ott on Wed Mar 03 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "InternetBrowserController.h"
#import "TCMMMUser.h"
#import "TCMMMUserManager.h"
#import "TCMHost.h"
#import "TCMMMBEEPSessionManager.h"
#import "TCMBEEPSession.h"
#import "TCMBEEPProfile.h"
#import "ImagePopUpButtonCell.h"


@implementation InternetBrowserController

- (id)init
{
    self = [super initWithWindowNibName:@"InternetBrowser"];
    if (self) {
        I_resolvingHosts = [NSMutableDictionary new];
        I_resolvedHosts = [NSMutableDictionary new];
    }
    return self;    
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [I_resolvingHosts release];
    [I_resolvedHosts release];
    [super dealloc];
}

- (void)windowDidLoad
{
    [[self window] setFrameAutosaveName:@"Internet"];
    TCMMMUser *me = [TCMMMUserManager me];
    [O_myNameTextField setStringValue:[me name]];
    [O_imageView setImage:[[me properties] objectForKey:@"Image"]];
    [((NSPanel *)[self window]) setFloatingPanel:NO];
    [[self window] setHidesOnDeactivate:NO];
    
    [O_actionPullDownButton setCell:[[ImagePopUpButtonCell new] autorelease]];
    [[O_actionPullDownButton cell] setPullsDown:YES];
    [[O_actionPullDownButton cell] setImage:[NSImage imageNamed:@"Action"]];
    [[O_actionPullDownButton cell] setAlternateImage:[NSImage imageNamed:@"ActionPressed"]];
    [[O_actionPullDownButton cell] setUsesItemFromMenu:NO];
    [O_actionPullDownButton addItemsWithTitles:[NSArray arrayWithObjects:@"<do not modify>", @"Ich", @"bin", @"das", @"Action", @"Menü", nil]];

    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    TCMMMBEEPSessionManager *manager = [TCMMMBEEPSessionManager sharedInstance];
    [defaultCenter addObserver:self 
                      selector:@selector(TCM_didAcceptSession:)
                          name:TCMMMBEEPSessionManagerDidAcceptSessionNotification
                        object:manager];
    [defaultCenter addObserver:self 
                      selector:@selector(TCM_sessionDidEnd:)
                          name:TCMMMBEEPSessionManagerSessionDidEndNotification
                        object:manager];
    [defaultCenter addObserver:self 
                      selector:@selector(TCM_connectToHostDidFail:)
                          name:TCMMMBEEPSessionManagerConnectToHostDidFailNotification
                        object:manager];
}

- (IBAction)connect:(id)aSender
{
    NSString *address = [aSender objectValue];
    DEBUGLOG(@"Internet", 5, @"connect to peer: %@", address);

    TCMHost *host = [TCMHost hostWithName:address port:6942];
    [I_resolvingHosts setObject:host forKey:[host name]];
    [host setDelegate:self];
    [host resolve];
}

#pragma mark -

- (void)hostDidResolveAddress:(TCMHost *)sender
{
    NSLog(@"hostDidResolveAddress:");
    [I_resolvedHosts setObject:sender forKey:[sender name]];
    [I_resolvingHosts removeObjectForKey:[sender name]];
    [sender setDelegate:nil];
    [[TCMMMBEEPSessionManager sharedInstance] connectToHost:sender];
}

- (void)host:(TCMHost *)sender didNotResolve:(NSError *)error
{
    DEBUGLOG(@"Internet", 5, @"host: %@, didNotResolve: %@", sender, error);
    [sender setDelegate:nil];
    [I_resolvingHosts removeObjectForKey:[sender name]];
}

#pragma mark -

- (void)TCM_didAcceptSession:(NSNotification *)notification
{
    DEBUGLOG(@"Internet", 5, @"TCM_didAcceptSession: %@", notification);
}

- (void)TCM_sessionDidEnd:(NSNotification *)notification
{
    DEBUGLOG(@"Internet", 5, @"TCM_sessionDidEnd: %@", notification);
}

- (void)TCM_connectToHostDidFail:(NSNotification *)notification
{
    DEBUGLOG(@"Internet", 5, @"TCM_connectToHostDidFail: %@", notification);
    
    TCMHost *host = [[notification userInfo] objectForKey:@"host"];
    if (host) {
        [I_resolvedHosts removeObjectForKey:[host name]];
    }
}

#pragma mark -

- (void)BEEPSession:(TCMBEEPSession *)session didOpenChannelWithProfile:(TCMBEEPProfile *)profile
{
    DEBUGLOG(@"Internet", 5, @"BEEPSession:%@ didOpenChannel: %@", session, profile);
}

@end

