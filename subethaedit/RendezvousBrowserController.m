//
//  RendezvousBrowserController.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Wed Feb 25 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "RendezvousBrowserController.h"
#import "TCMRendezvousBrowser.h"
#import "TCMMMPresenceManager.h"
#import "TCMMMBEEPSessionManager.h"
#import "TCMMMUserManager.h"
#import "TCMMMUser.h"

@implementation RendezvousBrowserController
- (id)init {
    if ((self=[super initWithWindowNibName:@"RendezvousBrowser"])) {
        I_data=[NSMutableArray new];
        I_browser=[[TCMRendezvousBrowser alloc] initWithServiceType:@"_emac._tcp." domain:@""];
        [I_browser setDelegate:self];
        [I_browser startSearch];
        I_foundUserIDs=[NSMutableSet new];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidChangeVisibility:) name:TCMMMPresenceManagerUserVisibilityDidChangeNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [I_foundUserIDs release];
    [I_data release];
    [super dealloc];
}

- (void)windowDidLoad {
    [[self window] setFrameAutosaveName:@"RendezvousBrowser"];
    TCMMMUser *me=[TCMMMUserManager me];
    [O_myNameTextField setStringValue:[me name]];
    [O_imageView setImage:[[me properties] objectForKey:@"Image"]];
    [((NSPanel *)[self window]) setFloatingPanel:NO];
    [[self window] setHidesOnDeactivate:NO];
    
    NSRect frame=[[O_scrollView contentView] frame];
    O_browserListView=[[TCMMMBrowserListView alloc] initWithFrame:frame];
    [O_scrollView setBorderType:NSBezelBorder];
    [O_browserListView setDataSource:self];
    [O_browserListView   setDelegate:self];
    [O_scrollView setHasVerticalScroller:YES];
    [[O_scrollView verticalScroller] setControlSize:NSSmallControlSize];
    [O_scrollView setDocumentView:O_browserListView];
    [O_browserListView noteEnclosingScrollView];
    
}

- (IBAction)setVisibilityByPopUpButton:(id)aSender {
    [[TCMMMPresenceManager sharedInstance] setVisible:([aSender indexOfSelectedItem]==0)];
}

#pragma mark -
#pragma mark ### TCMRendezvousBrowser Delegate ###
- (void)rendezvousBrowserWillSearch:(TCMRendezvousBrowser *)aBrowser {

}
- (void)rendezvousBrowserDidStopSearch:(TCMRendezvousBrowser *)aBrowser {

}
- (void)rendezvousBrowser:(TCMRendezvousBrowser *)aBrowser didNotSearch:(NSError *)anError {
    NSLog(@"Mist: %@",anError);
}

- (void)rendezvousBrowser:(TCMRendezvousBrowser *)aBrowser didFindService:(NSNetService *)aNetService {
    NSLog(@"foundservice: %@",aNetService);
}

- (void)rendezvousBrowser:(TCMRendezvousBrowser *)aBrowser didResolveService:(NSNetService *)aNetService {
//    [I_data addObject:[NSMutableDictionary dictionaryWithObject:[NSString stringWithFormat:@"resolved %@%@",[aNetService name],[aNetService domain]] forKey:@"serviceName"]];
    NSString *userID = [[aNetService TXTRecordDictionary] objectForKey:@"userid"];
    if (userID && ![userID isEqualTo:[TCMMMUserManager myID]]) {
        [I_foundUserIDs addObject:userID];
        [[TCMMMBEEPSessionManager sharedInstance] connectToNetService:aNetService];
    }
}

- (void)rendezvousBrowser:(TCMRendezvousBrowser *)aBrowser didRemoveResolved:(BOOL)wasResolved service:(NSNetService *)aNetService {
    NSLog(@"Removed Service: %@",aNetService);
}

#pragma mark -
#pragma mark ### TCMMMBrowserListViewDataSource methods ###

- (int)numberOfItemsInListView:(TCMMMBrowserListView *)aListView {
    return [I_data count];
}

- (int)listView:(TCMMMBrowserListView *)aListView numberOfChildrenOfItemAtIndex:(int)anIndex {
    return 0;
}

- (id)listView:(TCMMMBrowserListView *)aListView objectValueForTag:(int)aTag ofItemAtIndex:(int)anItemIndex {
    if (aTag==TCMMMBrowserItemNameTag) {
        return [[I_data objectAtIndex:anItemIndex] name];
    } else if (aTag==TCMMMBrowserItemStatusTag) {
        return [NSString stringWithFormat:@"%d Document(s)",[[[[TCMMMPresenceManager sharedInstance] statusOfUserID:[[I_data objectAtIndex:anItemIndex] ID]] objectForKey:@"Sessions"] count]];
    } else if (aTag==TCMMMBrowserItemImageTag) {
        return [[(TCMMMUser *)[I_data objectAtIndex:anItemIndex] properties] objectForKey:@"Image32"];
    }
    return nil;
}

- (id)listView:(TCMMMBrowserListView *)aListView objectValueForTag:(int)aTag atIndex:(int)anIndex ofItemAtIndex:(int)anItemIndex {
    return nil;
}


#pragma mark -
#pragma mark ### TCMMMPresenceManager Notifications ###

- (void)userDidChangeVisibility:(NSNotification *)aNotification {
    NSDictionary *userInfo=[aNotification userInfo];
    NSString *userID=[userInfo objectForKey:@"UserID"];
    TCMMMUser *user=[[TCMMMUserManager sharedInstance] userForID:userID];
    if ([[userInfo objectForKey:@"isVisible"] boolValue]) {
        [I_data addObject:user];
    } else {
        [I_data removeObject:user];
    }
    [O_browserListView reloadData];
}

- (void)userChangedAnnouncedDocuments:(NSNotification *)aNotification {

}

@end
