//
//  InternetBrowserController.m
//  SubEthaEdit
//
//  Created by Martin Ott on Wed Mar 03 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "InternetBrowserController.h"
#import "TCMHost.h"
#import "TCMBEEP/TCMBEEPSession.h"
#import "TCMBEEP/TCMBEEPProfile.h"
#import "ImagePopUpButtonCell.h"


@interface InternetBrowserController (InternetBrowserControllerPrivateAdditions)

- (int)indexOfItemWithHostname:(NSString *)name;
- (int)indexOfItemWithUserID:(NSString *)userID;

@end

#pragma mark -

@implementation InternetBrowserController

- (id)init {
    self = [super initWithWindowNibName:@"InternetBrowser"];
    if (self) {
        I_data = [NSMutableArray new];
        I_resolvingHosts = [NSMutableDictionary new];
        I_resolvedHosts = [NSMutableDictionary new];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidChangeVisibility:) name:TCMMMPresenceManagerUserVisibilityDidChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidChangeAnnouncedDocuments:) name:TCMMMPresenceManagerUserSessionsDidChangeNotification object:nil];
    }
    return self;    
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [I_data release];
    [I_resolvingHosts release];
    [I_resolvedHosts release];
    [super dealloc];
}

- (void)windowWillLoad {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidChange:) name:TCMMMUserManagerUserDidChangeNotification object:nil];
}

- (void)windowDidLoad {
    [[self window] setFrameAutosaveName:@"InternetBrowser"];
    TCMMMUser *me = [TCMMMUserManager me];
    [O_myNameTextField setStringValue:[me name]];
    [O_imageView setImage:[[me properties] objectForKey:@"Image"]];
    [((NSPanel *)[self window]) setFloatingPanel:NO];
    [[self window] setHidesOnDeactivate:NO];
    
    NSRect frame = [[O_scrollView contentView] frame];
    O_browserListView = [[TCMMMBrowserListView alloc] initWithFrame:frame];
    [O_scrollView setBorderType:NSBezelBorder];
    [O_browserListView setDataSource:self];
    [O_browserListView setDelegate:self];
    [O_browserListView setTarget:self];
    [O_browserListView setDoubleAction:@selector(joinSession:)];
    [O_scrollView setHasVerticalScroller:YES];
    [[O_scrollView verticalScroller] setControlSize:NSSmallControlSize];
    [O_scrollView setDocumentView:O_browserListView];
    [O_scrollView setDrawsBackground:NO];
    [[O_scrollView contentView] setCopiesOnScroll:YES];
    [[O_scrollView contentView] setDrawsBackground:NO];
    [[O_scrollView contentView] setAutoresizesSubviews:NO];
    [O_browserListView noteEnclosingScrollView];
    
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

- (IBAction)connect:(id)aSender {
    NSString *address = [aSender objectValue];
    DEBUGLOG(@"Internet", 5, @"connect to peer: %@", address);

    TCMHost *host = [TCMHost hostWithName:address port:[[NSUserDefaults standardUserDefaults] integerForKey:DefaultPortNumber]];
    [I_resolvingHosts setObject:host forKey:[host name]];
    [I_data addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:[host name], @"name", @"Resolving", @"status", nil]];
    [O_browserListView reloadData];
    [host setDelegate:self];
    [host resolve];
}

- (IBAction)setVisibilityByPopUpButton:(id)aSender {
    [[TCMMMPresenceManager sharedInstance] setVisible:([aSender indexOfSelectedItem] == 0)];
}

- (IBAction)joinSession:(id)aSender {
}

- (int)indexOfItemWithHostname:(NSString *)name {
    int index = -1;
    int i;
    for (i = 0; i < [I_data count]; i++) {
        if ([name isEqualToString:[[I_data objectAtIndex:i] objectForKey:@"name"]]) {
            index = i;
            break;
        }
    }
    
    return index;
}

- (int)indexOfItemWithUserID:(NSString *)userID {
    int result = -1;
    int i;
    for (i = 0; i < [I_data count]; i++) {
        if ([userID isEqualToString:[[I_data objectAtIndex:i] objectForKey:@"UserID"]]) {
            result = i;
            break;
        }
    }
    return result;
}

#pragma mark -

- (void)hostDidResolveAddress:(TCMHost *)sender {
    DEBUGLOG(@"InternetLogDomain", SimpleLogLevel, @"hostDidResolveAddress:");
    int index = [self indexOfItemWithHostname:[sender name]];
    if (index != -1) {
        [[I_data objectAtIndex:index] setObject:@"Connecting" forKey:@"status"];
        [O_browserListView reloadData];
    }
    [I_resolvedHosts setObject:sender forKey:[sender name]];
    [I_resolvingHosts removeObjectForKey:[sender name]];
    [sender setDelegate:nil];
    [[TCMMMBEEPSessionManager sharedInstance] connectToHost:sender];
}

- (void)host:(TCMHost *)sender didNotResolve:(NSError *)error {
    DEBUGLOG(@"InternetLogDomain", SimpleLogLevel, @"host: %@, didNotResolve: %@", sender, error);
    int index = [self indexOfItemWithHostname:[sender name]];
    if (index != -1) {
        [[I_data objectAtIndex:index] setObject:@"Couldn't resolve" forKey:@"status"];
        [O_browserListView reloadData];
    }
    [sender setDelegate:nil];
    [I_resolvingHosts removeObjectForKey:[sender name]];
}

#pragma mark -

- (void)TCM_didAcceptSession:(NSNotification *)notification {
    DEBUGLOG(@"InternetLogDomain", DetailedLogLevel, @"TCM_didAcceptSession: %@", notification);
    TCMBEEPSession *session = [[notification userInfo] objectForKey:@"Session"];    
    int index = [self indexOfItemWithHostname:[[session userInfo] objectForKey:@"name"]];
    if (index != -1) {
        NSMutableDictionary *item = [I_data objectAtIndex:index];
        [item setObject:@"BEEP session established" forKey:@"status"];
        NSString *userID = [[session userInfo] objectForKey:@"peerUserID"];
        [item setObject:userID forKey:@"UserID"];
        NSDictionary *infoDict = [[TCMMMPresenceManager sharedInstance] statusOfUserID:userID];
        [item setObject:[[[infoDict objectForKey:@"Sessions"] allValues] mutableCopy] forKey:@"Sessions"];
        [item setObject:[NSNumber numberWithBool:YES] forKey:@"isExpanded"];
        [O_browserListView reloadData];
    }
}

- (void)TCM_sessionDidEnd:(NSNotification *)notification {
    DEBUGLOG(@"InternetLogDomain", DetailedLogLevel, @"TCM_sessionDidEnd: %@", notification);
    TCMBEEPSession *session = [[notification userInfo] objectForKey:@"Session"];
    int index = [self indexOfItemWithHostname:[[session userInfo] objectForKey:@"name"]];
    if (index != -1) {
        [[I_data objectAtIndex:index] setObject:@"BEEP session ended" forKey:@"status"];
        [O_browserListView reloadData];
    }
}

- (void)TCM_connectToHostDidFail:(NSNotification *)notification {
    DEBUGLOG(@"InternetLogDomain", DetailedLogLevel, @"TCM_connectToHostDidFail: %@", notification);
    
    TCMHost *host = [[notification userInfo] objectForKey:@"host"];
    if (host) {
        [I_resolvedHosts removeObjectForKey:[host name]];
    }
}

#pragma mark -

- (void)BEEPSession:(TCMBEEPSession *)session didOpenChannelWithProfile:(TCMBEEPProfile *)profile {
    DEBUGLOG(@"InternetLogDomain", DetailedLogLevel, @"BEEPSession:%@ didOpenChannel: %@", session, profile);
}

#pragma mark -

- (void)userDidChange:(NSNotification *)aNotification {
    DEBUGLOG(@"InternetLogDomain", AllLogLevel, @"userDidChange: %@", aNotification);
    [O_browserListView reloadData];
}

#pragma mark -

- (void)userDidChangeVisibility:(NSNotification *)aNotification {
    DEBUGLOG(@"InternetLogDomain", AllLogLevel, @"userDidChangeVisibility: %@", aNotification);
    NSDictionary *userInfo = [aNotification userInfo];
    NSString *userID = [userInfo objectForKey:@"UserID"];
    BOOL isVisible = [[userInfo objectForKey:@"isVisible"] boolValue];
    
    if (!isVisible) {
        int index = [self indexOfItemWithUserID:userID];
        if (index >= 0) {
            [I_data removeObjectAtIndex:index];
        }
    }
    [O_browserListView reloadData];
}

- (void)userDidChangeAnnouncedDocuments:(NSNotification *)aNotification {
    DEBUGLOG(@"InternetLogDomain", AllLogLevel, @"userDidChangeAnnouncedDocuments: %@", aNotification);
    NSDictionary *userInfo = [aNotification userInfo];
    NSString * userID = [userInfo objectForKey:@"UserID"];
    int index = [self indexOfItemWithUserID:userID];
    if (index >= 0) {
        NSMutableDictionary *item = [I_data objectAtIndex:index];
        TCMMMSession *session = [userInfo objectForKey:@"AnnouncedSession"];
        NSMutableArray *sessions = [item objectForKey:@"Sessions"];
        if ([[userInfo objectForKey:@"Sessions"] count] == 0) {
            [sessions removeAllObjects];
        } else {
            if (session) {
                [sessions addObject:session];
            } else {
                NSString *concealedSessionID = [userInfo objectForKey:@"ConcealedSessionID"];
                int i;
                for (i = 0; i < [sessions count]; i++) {
                    if ([concealedSessionID isEqualToString:[[sessions objectAtIndex:i] sessionID]]) {
                        [sessions removeObjectAtIndex:i];
                    }
                }
            }
        }
    }
    [O_browserListView reloadData];
}

#pragma mark -

- (int)numberOfItemsInListView:(TCMMMBrowserListView *)aListView {
    return [I_data count];
}

- (int)listView:(TCMMMBrowserListView *)aListView numberOfChildrenOfItemAtIndex:(int)anItemIndex {
    if (anItemIndex >= 0 && anItemIndex < [I_data count]) {
        NSMutableDictionary *item=[I_data objectAtIndex:anItemIndex];
        return [[item objectForKey:@"Sessions"] count];
    }
    return 0;
}

- (BOOL)listView:(TCMMMBrowserListView *)aListView isItemExpandedAtIndex:(int)anItemIndex {
    if (anItemIndex >= 0 && anItemIndex < [I_data count]) {
        NSMutableDictionary *item = [I_data objectAtIndex:anItemIndex];
        return [[item objectForKey:@"isExpanded"] boolValue];
    }
    return NO;
}

- (void)listView:(TCMMMBrowserListView *)aListView setExpanded:(BOOL)isExpanded itemAtIndex:(int)anItemIndex {
    if (anItemIndex >= 0 && anItemIndex < [I_data count]) {
        NSMutableDictionary *item = [I_data objectAtIndex:anItemIndex];
        [item setObject:[NSNumber numberWithBool:isExpanded] forKey:@"isExpanded"];
    }
}

- (id)listView:(TCMMMBrowserListView *)aListView objectValueForTag:(int)aTag ofItemAtIndex:(int)anItemIndex {
    if (anItemIndex >= 0 && anItemIndex < [I_data count]) {
        NSMutableDictionary *item = [I_data objectAtIndex:anItemIndex];
        
        TCMMMUser *user=[[TCMMMUserManager sharedInstance] userForUserID:[item objectForKey:@"UserID"]];

        if (user) {
            if (aTag == TCMMMBrowserItemNameTag) {
                return [user name];
            } else if (aTag == TCMMMBrowserItemStatusTag) {
                return [NSString stringWithFormat:@"%d Document(s)", [[item objectForKey:@"Sessions"] count]];
            } else if (aTag == TCMMMBrowserItemImageTag) {
                return [[user properties] objectForKey:@"Image32"];
            } else if (aTag == TCMMMBrowserItemImageNextToNameTag) {
                return [[user properties] objectForKey:@"ColorImage"];
            }
        } else {
            if (aTag == TCMMMBrowserItemNameTag) {
                return [item objectForKey:@"name"];
            } else if (aTag == TCMMMBrowserItemStatusTag) {
                return [item objectForKey:@"status"];
            }
        }
    }

    return nil;
}

- (id)listView:(TCMMMBrowserListView *)aListView objectValueForTag:(int)aTag atIndex:(int)anIndex ofItemAtIndex:(int)anItemIndex {
    if (anItemIndex >= 0 && anItemIndex < [I_data count]) {
        NSDictionary *item = [I_data objectAtIndex:anItemIndex];
        NSArray *sessions = [item objectForKey:@"Sessions"];
        if (anIndex >= 0 && anIndex < [sessions count]) {
            TCMMMSession *session = [sessions objectAtIndex:anIndex];
            if (aTag == TCMMMBrowserChildNameTag) {
                return [session filename];
            }
        }
    }
    return nil;
}

@end

