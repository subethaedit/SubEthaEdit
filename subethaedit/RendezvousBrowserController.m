//
//  RendezvousBrowserController.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Wed Feb 25 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "RendezvousBrowserController.h"
#import "TCMRendezvousBrowser.h"
#import "ImagePopUpButtonCell.h"
#import "PullDownButtonCell.h"


static RendezvousBrowserController *sharedInstance=nil;

@interface RendezvousBrowserController (RendezvousBrowserControllerPrivateAdditions)

- (int)TCM_indexOfItemWithUserID:(NSString *)aUserID;

@end

#pragma mark -

@implementation RendezvousBrowserController

+ (RendezvousBrowserController *)sharedInstance {
    return sharedInstance;
}

- (id)init {
    if ((self=[super initWithWindowNibName:@"RendezvousBrowser"])) {
        I_data=[NSMutableArray new];
        I_browser=[[TCMRendezvousBrowser alloc] initWithServiceType:@"_see._tcp." domain:@""];
        [I_browser setDelegate:self];
        [I_browser startSearch];
        I_foundUserIDs=[NSMutableSet new];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidChangeVisibility:) name:TCMMMPresenceManagerUserVisibilityDidChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidChangeAnnouncedDocuments:) name:TCMMMPresenceManagerUserSessionsDidChangeNotification object:nil];
    }
    return self;
}

- (void)awakeFromNib {
    sharedInstance=self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [I_foundUserIDs release];
    [I_data release];
    [super dealloc];
}

- (void)TCM_validateStatusPopUpButton {
    TCMMMPresenceManager *pm=[TCMMMPresenceManager sharedInstance];
    BOOL isVisible=[pm isVisible];
    int announcedCount=[[pm announcedSessions] count];
    NSString *statusString=@"";
    if (announcedCount>0) {
        statusString=[NSString stringWithFormat:NSLocalizedString(@"%d Document(s)","Status string in visibility pull down in Rendezvous and Internet browser"),announcedCount];
    } else if (isVisible) {
        statusString=NSLocalizedString(@"visible",@"Status string in vibilitypulldown in Browsers for visible");
    } else {
        statusString=NSLocalizedString(@"invisible",@"Status string in vibilitypulldown in Browsers for invisible");
    }
    [[[O_statusPopUpButton menu] itemAtIndex:0] setTitle:statusString];
}

- (void)windowWillLoad {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidChange:) name:TCMMMUserManagerUserDidChangeNotification object:nil];
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
    [O_browserListView setTarget:self];
    [O_browserListView setDoubleAction:@selector(joinSession:)];
    [O_scrollView setHasVerticalScroller:YES];
    [[O_scrollView verticalScroller] setControlSize:NSSmallControlSize];
//    [O_scrollView setAutohidesScrollers:YES];
    [O_scrollView setDocumentView:O_browserListView];
    [O_scrollView setDrawsBackground:NO];
//    NSLog(@"Copies on Scroll: %@",([[O_scrollView contentView] copiesOnScroll]?@"YES":@"NO"));
    [[O_scrollView contentView] setCopiesOnScroll:YES];
    [[O_scrollView contentView] setDrawsBackground:NO];
//    NSLog(@"Draws background: %@",([O_scrollView drawsBackground]?@"YES":@"NO"));
//    NSLog(@"Autoresizes Subviews: %@",([[O_scrollView contentView] autoresizesSubviews]?@"YES":@"NO"));
    [[O_scrollView contentView] setAutoresizesSubviews:NO];
    [O_browserListView noteEnclosingScrollView];
    
    [O_actionPullDownButton setCell:[[ImagePopUpButtonCell new] autorelease]];
    [[O_actionPullDownButton cell] setPullsDown:YES];
    [[O_actionPullDownButton cell] setImage:[NSImage imageNamed:@"Action"]];
    [[O_actionPullDownButton cell] setAlternateImage:[NSImage imageNamed:@"ActionPressed"]];
    [[O_actionPullDownButton cell] setUsesItemFromMenu:NO];
    [O_actionPullDownButton addItemsWithTitles:[NSArray arrayWithObjects:@"<do not modify>", @"Ich", @"bin", @"das", @"Action", @"Menü", nil]];
    
    
    PullDownButtonCell *cell=[[[PullDownButtonCell alloc] initTextCell:@"" pullsDown:YES] autorelease];
    NSMenu *oldMenu=[[[O_statusPopUpButton cell] menu] retain];
    [cell setPullsDown:NO];
    NSMenu *menu=[cell menu];
    NSEnumerator *menuItems=[[oldMenu itemArray] objectEnumerator];
    NSMenuItem *item=nil;
    while ((item=[menuItems nextObject])) {
        [menu addItem:[item copy]];
    }
    [oldMenu release];
    [O_statusPopUpButton setCell:cell];
    [cell setControlSize:NSSmallControlSize];
    [O_statusPopUpButton setPullsDown:YES];
    [O_statusPopUpButton setBordered:NO];
    [cell setUsesItemFromMenu:YES];
//    [O_statusPopUpButton setBezeled:NO];
    [O_statusPopUpButton setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSSmallControlSize]]];
    
    [[O_statusPopUpButton menu] setDelegate:self];
    [self TCM_validateStatusPopUpButton];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(announcedSessionsDidChange:) name:TCMMMPresenceManagerAnnouncedSessionsDidChangeNotification object:[TCMMMPresenceManager sharedInstance]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(announcedSessionsDidChange:) name:TCMMMPresenceManagerServiceAnnouncementDidChangeNotification object:[TCMMMPresenceManager sharedInstance]];
}

- (void)announcedSessionsDidChange:(NSNotification *)aNotification {
    [self TCM_validateStatusPopUpButton];
}

- (void)menuNeedsUpdate:(NSMenu *)aMenu {
    BOOL isVisible=[[TCMMMPresenceManager sharedInstance] isVisible];
    [[aMenu itemWithTag:10] setState:isVisible?NSOnState:NSOffState];
    [[aMenu itemWithTag:11] setState:(!isVisible)?NSOnState:NSOffState];
}

- (IBAction)setVisibilityByMenuItem:(id)aSender {
    [[TCMMMPresenceManager sharedInstance] setVisible:([aSender tag]==10)];
}

- (IBAction)joinSession:(id)aSender
{
    int row = [aSender clickedRow];
    DEBUGLOG(@"RendezvousLogDomain", AllLogLevel, @"joinSession in row: %d", row);

    ItemChildPair pair = [aSender itemChildPairAtRow:row];
    if (pair.childIndex!=-1) {
        NSDictionary *userDict = [I_data objectAtIndex:pair.itemIndex];
        NSArray *sessions = [userDict objectForKey:@"Sessions"];
        TCMMMSession *session = [sessions objectAtIndex:pair.childIndex];
        DEBUGLOG(@"RendezvousLogDomain", AllLogLevel, @"Found session: %@", session);
        [session joinUsingBEEPSession:nil];
    }
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
    DEBUGLOG(@"RendezvousLogDomain", AllLogLevel, @"foundservice: %@",aNetService);
}

- (void)rendezvousBrowser:(TCMRendezvousBrowser *)aBrowser didResolveService:(NSNetService *)aNetService {
//    [I_data addObject:[NSMutableDictionary dictionaryWithObject:[NSString stringWithFormat:@"resolved %@%@",[aNetService name],[aNetService domain]] forKey:@"serviceName"]];
    NSString *userID = [[aNetService TXTRecordDictionary] objectForKey:@"userid"];
    if (userID && ![userID isEqualTo:[TCMMMUserManager myUserID]]) {
        [I_foundUserIDs addObject:userID];
        NSDictionary *status=[[TCMMMPresenceManager sharedInstance] statusOfUserID:userID];
        if ([[status objectForKey:@"Status"] isEqualToString:@"GotStatus"]) {
            if ([[status objectForKey:@"isVisible"] boolValue] && [self TCM_indexOfItemWithUserID:userID]==-1) {
                [I_data addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:userID,@"UserID",[NSMutableArray array],@"Sessions",[NSNumber numberWithBool:YES],@"isExpanded",nil]];
                [O_browserListView reloadData];
            }
        } else {
            [[TCMMMBEEPSessionManager sharedInstance] connectToNetService:aNetService];
        }
    }
}

- (void)rendezvousBrowser:(TCMRendezvousBrowser *)aBrowser didRemoveResolved:(BOOL)wasResolved service:(NSNetService *)aNetService {
    DEBUGLOG(@"RendezvousLogDomain", AllLogLevel, @"Removed Service: %@",aNetService);
    if (wasResolved) {
        NSString *userID = [[aNetService TXTRecordDictionary] objectForKey:@"userid"];
        [I_foundUserIDs removeObject:userID];
    }
}

#pragma mark -
#pragma mark ### TCMMMBrowserListViewDataSource methods ###

- (int)numberOfItemsInListView:(TCMMMBrowserListView *)aListView {
    return [I_data count];
}

- (int)listView:(TCMMMBrowserListView *)aListView numberOfChildrenOfItemAtIndex:(int)anItemIndex {
    if (anItemIndex>=0 && anItemIndex<[I_data count]) {
        NSMutableDictionary *item=[I_data objectAtIndex:anItemIndex];
        return [[item objectForKey:@"Sessions"] count];
    }
    return 0;
}

- (BOOL)listView:(TCMMMBrowserListView *)aListView isItemExpandedAtIndex:(int)anItemIndex {
    if (anItemIndex>=0 && anItemIndex<[I_data count]) {
        NSMutableDictionary *item=[I_data objectAtIndex:anItemIndex];
        return [[item objectForKey:@"isExpanded"] boolValue];
    }
    return YES;
}

- (void)listView:(TCMMMBrowserListView *)aListView setExpanded:(BOOL)isExpanded itemAtIndex:(int)anItemIndex {
    if (anItemIndex>=0 && anItemIndex<[I_data count]) {
        NSMutableDictionary *item=[I_data objectAtIndex:anItemIndex];
        [item setObject:[NSNumber numberWithBool:isExpanded] forKey:@"isExpanded"];
    }
}

- (id)listView:(TCMMMBrowserListView *)aListView objectValueForTag:(int)aTag ofItemAtIndex:(int)anItemIndex {
    if (anItemIndex>=0 && anItemIndex<[I_data count]) {
        NSMutableDictionary *item=[I_data objectAtIndex:anItemIndex];
        TCMMMUser *user=[[TCMMMUserManager sharedInstance] userForUserID:[item objectForKey:@"UserID"]];
    
        if (aTag==TCMMMBrowserItemNameTag) {
            return [user name];
        } else if (aTag==TCMMMBrowserItemStatusTag) {
            return [NSString stringWithFormat:@"%d Document(s)",[[item objectForKey:@"Sessions"] count]];
        } else if (aTag==TCMMMBrowserItemImageTag) {
            return [[user properties] objectForKey:@"Image32"];
        } else if (aTag==TCMMMBrowserItemImageNextToNameTag) {
            return [[user properties] objectForKey:@"ColorImage"];
        } 
    }
    return nil;
}

- (id)listView:(TCMMMBrowserListView *)aListView objectValueForTag:(int)aTag atIndex:(int)anIndex ofItemAtIndex:(int)anItemIndex {
    static NSImage *statusLock=nil;
    static NSImage *statusReadOnly=nil;
    static NSImage *statusReadWrite=nil;
    static NSMutableDictionary *icons =nil;
    
    if (!icons) {
        icons=[NSMutableDictionary new];
        statusLock     =[[NSImage imageNamed:@"StatusLock"     ] retain];
        statusReadOnly =[[NSImage imageNamed:@"StatusReadOnly" ] retain];
        statusReadWrite=[[NSImage imageNamed:@"StatusReadWrite"] retain];
    }
    if (anItemIndex>=0 && anItemIndex<[I_data count]) {
        NSDictionary *item=[I_data objectAtIndex:anItemIndex];
//        TCMMMUser *user=[[TCMMMUserManager sharedInstance] userForID:[item objectForKey:@"UserID"]];
        NSArray *sessions=[item objectForKey:@"Sessions"];
        if (anIndex >= 0 && anIndex < [sessions count]) {
            TCMMMSession *session=[sessions objectAtIndex:anIndex];
            if (aTag==TCMMMBrowserChildNameTag) {
                return [session filename];
            } else if (aTag==TCMMMBrowserChildIconImageTag) {
                NSString *extension=[[session filename] pathExtension];
                NSImage *icon=[icons objectForKey:extension];
                if (!icon) {
                    icon = [[[NSWorkspace sharedWorkspace] iconForFileType:extension] copy];
                    [icon setSize:NSMakeSize(16,16)];
                    [icons setObject:[icon autorelease] forKey:extension];
                }
                return icon;
            } else if (aTag==TCMMMBrowserChildStatusImageTag) {
                switch ([session accessState]) {
                    case TCMMMSessionAccessLockedState:
                        return statusLock;
                    case TCMMMSessionAccessReadOnlyState:
                        return statusReadOnly;
                    case TCMMMSessionAccessReadWriteState:
                        return statusReadWrite;
                }
            }
        }
    }
    return nil;
}

- (NSString *)listView:(TCMMMBrowserListView *)aListView toolTipStringAtIndex:(int)anIndex ofItemAtIndex:(int)anItemIndex {
    if (anItemIndex>=0 && anItemIndex<[I_data count]) {
        NSMutableDictionary *item=[I_data objectAtIndex:anItemIndex];
        TCMMMUser *user=[[TCMMMUserManager sharedInstance] userForUserID:[item objectForKey:@"UserID"]];
        if (user) {
            return [NSString stringWithFormat:@"AIM:%@\nEmail:%@",[[user properties] objectForKey:@"AIM"],[[user properties] objectForKey:@"Email"]];
        }
    }
    return nil;
}


#pragma mark -
#pragma mark ### TCMMMPresenceManager Notifications ###

- (int)TCM_indexOfItemWithUserID:(NSString *)aUserID {
    int result=-1;
    int i;
    for (i = 0; i < [I_data count]; i++) {
        if ([aUserID isEqualToString:[[I_data objectAtIndex:i] objectForKey:@"UserID"]]) {
            result=i;
            break;
        }
    }
    return result;
}

- (void)userDidChangeVisibility:(NSNotification *)aNotification {
    NSDictionary *userInfo=[aNotification userInfo];
    NSString *userID=[userInfo objectForKey:@"UserID"];
    BOOL isVisible=[[userInfo objectForKey:@"isVisible"] boolValue];
    // TODO: handle Selection
    if (isVisible) {
        if ([I_foundUserIDs containsObject:userID]) {
            if ([self TCM_indexOfItemWithUserID:userID]==-1) {
                [I_data addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:userID,@"UserID",[NSMutableArray array],@"Sessions",[NSNumber numberWithBool:YES],@"isExpanded",nil]];
            }
        }
    } else {
        int index=[self TCM_indexOfItemWithUserID:userID];
        if (index >= 0) {
            [I_data removeObjectAtIndex:index];
        }
    }
    [O_browserListView reloadData];
}

- (void)userDidChangeAnnouncedDocuments:(NSNotification *)aNotification {
    NSDictionary *userInfo=[aNotification userInfo];
    NSString *userID=[userInfo objectForKey:@"UserID"];
    int index=[self TCM_indexOfItemWithUserID:userID];
    if (index >= 0) {
        NSMutableDictionary *item=[I_data objectAtIndex:index];
        TCMMMSession *session=[userInfo objectForKey:@"AnnouncedSession"];
        NSMutableArray *sessions=[item objectForKey:@"Sessions"];
        if ([[userInfo objectForKey:@"Sessions"] count] == 0) {
            [sessions removeAllObjects];
        } else {
            if (session) {
                NSString *sessionID=[session sessionID];
                int i;
                for (i=0;i<[sessions count];i++) {
                    if ([sessionID isEqualToString:[[sessions objectAtIndex:i] sessionID]]) {
                        break;
                    }
                }
                if (i==[sessions count]) {
                    [sessions addObject:session];
                }
            } else {
                NSString *concealedSessionID=[userInfo objectForKey:@"ConcealedSessionID"];
                int i;
                for (i = 0; i < [sessions count]; i++) {
                    if ([concealedSessionID isEqualToString:[[sessions objectAtIndex:i] sessionID]]) {
                        [sessions removeObjectAtIndex:i];
                        break;
                    }
                }
            }
        }
    }
    [O_browserListView reloadData];
}

#pragma mark -
#pragma mark ### TCMMMUserManager Notifications ###

- (void)userDidChange:(NSNotification *)aNotification {
    DEBUGLOG(@"RendezvousLogDomain", AllLogLevel, @"userDidChange: %@", aNotification);
    TCMMMUser *user = [[aNotification userInfo] objectForKey:@"User"];
    if ([I_foundUserIDs containsObject:[user userID]]) {
        DEBUGLOG(@"RendezvousLogDomain", AllLogLevel, @"reloadData");
        [O_browserListView reloadData];
    }
}

@end
