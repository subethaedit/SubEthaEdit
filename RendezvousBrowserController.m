//
//  RendezvousBrowserController.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Wed Feb 25 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "RendezvousBrowserController.h"
#import "ImagePopUpButtonCell.h"
#import "PullDownButtonCell.h"
#import "TCMMMPresenceManager.h"
#import "TCMMMUserManager.h"
#import "TCMMMUser.h"
#import "TCMMMUserSEEAdditions.h"

enum {
    BrowserContextMenuTagJoin = 1,
    BrowserContextMenuTagShowDocument,
    BrowserContextMenuTagAIM,
    BrowserContextMenuTagEmail
};

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
        I_userIDsInRendezvous=[NSMutableSet new];
        
        
        I_contextMenu = [NSMenu new];
        NSMenuItem *item = nil;

        item = (NSMenuItem *)[I_contextMenu addItemWithTitle:NSLocalizedString(@"BrowserContextMenuJoin", @"Join document entry for Browser context menu") action:@selector(join:) keyEquivalent:@""];
        [item setTarget:self];
        [item setTag:BrowserContextMenuTagJoin];

        item = (NSMenuItem *)[I_contextMenu addItemWithTitle:NSLocalizedString(@"BrowserContextMenuShowDocument", @"Show document entry for Browser context menu") action:@selector(join:) keyEquivalent:@""];
        [item setTarget:self];
        [item setTag:BrowserContextMenuTagShowDocument];
        
        [I_contextMenu addItem:[NSMenuItem separatorItem]];
        
        item = (NSMenuItem *)[I_contextMenu addItemWithTitle:NSLocalizedString(@"BrowserContextMenuAIM", @"AIM user entry for Browser context menu") action:@selector(initiateAIMChat:) keyEquivalent:@""];
        [item setTarget:[TCMMMUserManager sharedInstance]];
        [item setTag:BrowserContextMenuTagAIM];
                
        item = (NSMenuItem *)[I_contextMenu addItemWithTitle:NSLocalizedString(@"BrowserContextMenuEmail", @"Email user entry for Browser context menu") action:@selector(sendEmail:) keyEquivalent:@""];
        [item setTarget:[TCMMMUserManager sharedInstance]];
        [item setTag:BrowserContextMenuTagEmail];
        
        [I_contextMenu setDelegate:self];    
       
       
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidChangeVisibility:) name:TCMMMPresenceManagerUserVisibilityDidChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidChangeAnnouncedDocuments:) name:TCMMMPresenceManagerUserSessionsDidChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidChangeRendezvousStatus:) name:TCMMMPresenceManagerUserRendezvousStatusDidChangeNotification object:nil];
    }
    return self;
}

- (void)awakeFromNib {
    sharedInstance=self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [I_userIDsInRendezvous release];
    [I_data release];
    [I_contextMenu release];
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
        statusString=NSLocalizedString(@"Visible",@"Status string in vibilitypulldown in Browsers for visible");
    } else {
        statusString=NSLocalizedString(@"Invisible",@"Status string in vibilitypulldown in Browsers for invisible");
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
    [O_actionPullDownButton addItemWithTitle:@"<do not modify>"];
    NSMenu *actionMenu = [O_actionPullDownButton menu];
    [actionMenu setDelegate:self];
    NSEnumerator *contextMenuItems = [[I_contextMenu itemArray] objectEnumerator];
    id menuItem = nil;
    while ((menuItem = [contextMenuItems nextObject])) {
        [actionMenu addItem:[[menuItem copy] autorelease]];
    }    
    
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

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionClientStateDidChange:) name:TCMMMSessionClientStateDidChangeNotification object:nil];
}

- (void)sessionClientStateDidChange:(NSNotification *)aNotificaiton {
    [O_browserListView setNeedsDisplay:YES];
}

- (void)announcedSessionsDidChange:(NSNotification *)aNotification {
    [self TCM_validateStatusPopUpButton];
}


enum {
    kNoStateMask = 1,
    kJoiningStateMask = 2,
    kParticipantStateMask = 4
};

- (void)menuNeedsUpdate:(NSMenu *)aMenu {
   if ([aMenu isEqual:[O_statusPopUpButton menu]]) {
        BOOL isVisible=[[TCMMMPresenceManager sharedInstance] isVisible];
        [[aMenu itemWithTag:10] setState:isVisible?NSOnState:NSOffState];
        [[aMenu itemWithTag:11] setState:(!isVisible)?NSOnState:NSOffState];
        return;
    }
    
    NSMutableIndexSet *documentSet = [NSMutableIndexSet indexSet];
    NSMutableIndexSet *userSet = [NSMutableIndexSet indexSet];
    
    NSMutableIndexSet *set = [[O_browserListView selectedRowIndexes] mutableCopy];
    unsigned int index;
    while ((index = [set firstIndex]) != NSNotFound) {
        ItemChildPair pair = [O_browserListView itemChildPairAtRow:index];
        if (pair.childIndex == -1) {
            [userSet addIndex:index];
        } else {
            [documentSet addIndex:index];
        }
        [set removeIndex:index];
    }
    [set release];
    
    id item;

    if (([userSet count] > 0 && [documentSet count] > 0) || 
        ([userSet count] == 0 && [documentSet count] == 0)) {
        DEBUGLOG(@"InternetLogDomain", AllLogLevel, @"Disabling all menu items because of inconsistent selection");
        item = [aMenu itemWithTag:BrowserContextMenuTagJoin];
        [item setEnabled:NO];
        item = [aMenu itemWithTag:BrowserContextMenuTagShowDocument];
        [item setEnabled:NO];
        item = [aMenu itemWithTag:BrowserContextMenuTagAIM];
        [item setEnabled:NO];
        item = [aMenu itemWithTag:BrowserContextMenuTagEmail];
        [item setEnabled:NO];
        return;
    }
        
    if ([userSet count] > 0) {
        item = [aMenu itemWithTag:BrowserContextMenuTagJoin];
        [item setEnabled:NO];
        item = [aMenu itemWithTag:BrowserContextMenuTagShowDocument];    
        [item setEnabled:NO];
        
        NSMutableSet *userIDs = [NSMutableSet set];
        NSMutableIndexSet *set = [[O_browserListView selectedRowIndexes] mutableCopy];
        unsigned int index;
        while ((index = [set firstIndex]) != NSNotFound) {
            ItemChildPair pair = [O_browserListView itemChildPairAtRow:index];
            NSDictionary *userDict = [I_data objectAtIndex:pair.itemIndex];
            [userIDs addObject:[userDict objectForKey:@"UserID"]];
            [set removeIndex:index];
        }
        [set release];

        TCMMMUserManager *manager = [TCMMMUserManager sharedInstance];
        item = [aMenu itemWithTag:BrowserContextMenuTagAIM];
        [item setRepresentedObject:userIDs];
        [item setEnabled:[manager validateMenuItem:item]];
        item = [aMenu itemWithTag:BrowserContextMenuTagEmail];
        [item setRepresentedObject:userIDs];
        [item setEnabled:[manager validateMenuItem:item]];
       
        return;
    }
    
    
    if ([documentSet count] > 0) {
        item = [aMenu itemWithTag:BrowserContextMenuTagAIM];
        [item setEnabled:NO];
        item = [aMenu itemWithTag:BrowserContextMenuTagEmail];    
        [item setEnabled:NO];    
    
        NSMutableSet *sessionSet = [NSMutableSet set];
        NSMutableIndexSet *set = [[O_browserListView selectedRowIndexes] mutableCopy];
        unsigned int index;
        while ((index = [set firstIndex]) != NSNotFound) {
            ItemChildPair pair = [O_browserListView itemChildPairAtRow:index];
            NSDictionary *dataItem = [I_data objectAtIndex:pair.itemIndex];
            NSArray *sessions = [dataItem objectForKey:@"Sessions"];
            [sessionSet addObject:[sessions objectAtIndex:pair.childIndex]];
            [set removeIndex:index];
        }
        [set release];        
        
        // check for consistent state of selected MMSessions
        int state = 0;
        NSEnumerator *enumerator = [sessionSet objectEnumerator];
        id sessionItem;
        while ((sessionItem = [enumerator nextObject])) {
            if ([sessionItem clientState] == TCMMMSessionClientNoState) {
                state |= kNoStateMask;
            }
            if ([sessionItem clientState] == TCMMMSessionClientJoiningState) {
                state |= kJoiningStateMask;
            }
            if ([sessionItem clientState] == TCMMMSessionClientParticipantState) {
                state |= kParticipantStateMask;
            }        
        }

        if (!(state == 0 || state == 1 || state == 2 || state == 4)) {
            state = 0;
        }
        item = [aMenu itemWithTag:BrowserContextMenuTagJoin];
        [item setEnabled:(state & kNoStateMask) && YES];
        item = [aMenu itemWithTag:BrowserContextMenuTagShowDocument];    
        [item setEnabled:(state & kParticipantStateMask) || (state & kJoiningStateMask)];
        
        return;
    }
}

- (IBAction)setVisibilityByMenuItem:(id)aSender {
    [[TCMMMPresenceManager sharedInstance] setVisible:([aSender tag]==10)];
}

- (void)joinSessionsWithIndexes:(NSIndexSet *)indexes {
    DEBUGLOG(@"InternetLogDomain", DetailedLogLevel, @"join");
    NSMutableIndexSet *indexSet = [indexes mutableCopy];
    unsigned int index;
    while ((index = [indexSet firstIndex]) != NSNotFound) {
        ItemChildPair pair = [O_browserListView itemChildPairAtRow:index];
        if (pair.childIndex!=-1) {
            NSDictionary *userDict = [I_data objectAtIndex:pair.itemIndex];
            NSArray *sessions = [userDict objectForKey:@"Sessions"];
            TCMMMSession *session = [sessions objectAtIndex:pair.childIndex];
            DEBUGLOG(@"RendezvousLogDomain", AllLogLevel, @"Found session: %@", session);
            [session joinUsingBEEPSession:nil];
        }    
        [indexSet removeIndex:index];
    }
    [indexSet release];
}

- (void)join:(id)sender {
    [self joinSessionsWithIndexes:[O_browserListView selectedRowIndexes]];
}

- (IBAction)joinSession:(id)aSender
{
    int row = [aSender clickedRow];
    DEBUGLOG(@"RendezvousLogDomain", AllLogLevel, @"joinSession in row: %d", row);

    ItemChildPair pair = [aSender itemChildPairAtRow:row];
    if (pair.childIndex!=-1) {
        [self joinSessionsWithIndexes:[NSIndexSet indexSetWithIndex:row]];
        /*
        NSDictionary *userDict = [I_data objectAtIndex:pair.itemIndex];
        NSArray *sessions = [userDict objectForKey:@"Sessions"];
        TCMMMSession *session = [sessions objectAtIndex:pair.childIndex];
        DEBUGLOG(@"RendezvousLogDomain", AllLogLevel, @"Found session: %@", session);
        [session joinUsingBEEPSession:nil];
        */
    }
}

#pragma mark -
#pragma mark ### TCMMMBrowserListViewDataSource methods ###

- (NSMenu *)contextMenuForListView:(TCMListView *)listView clickedAtRow:(int)row {
    return I_contextMenu;
}

- (int)listView:(TCMListView *)aListView numberOfEntriesOfItemAtIndex:(int)anItemIndex {
    if (anItemIndex==-1) {
        return [I_data count];
    } else {
        if (anItemIndex>=0 && anItemIndex<[I_data count]) {
            NSMutableDictionary *item=[I_data objectAtIndex:anItemIndex];
            return [[item objectForKey:@"Sessions"] count];
        }
        return 0;
    }
}

// not used
- (BOOL)listView:(TCMListView *)aListView isItemExpandedAtIndex:(int)anItemIndex {
    if (anItemIndex>=0 && anItemIndex<[I_data count]) {
        NSMutableDictionary *item=[I_data objectAtIndex:anItemIndex];
        return [[item objectForKey:@"isExpanded"] boolValue];
    }
    return YES;
}

- (void)listView:(TCMListView *)aListView setExpanded:(BOOL)isExpanded itemAtIndex:(int)anItemIndex {
    if (anItemIndex>=0 && anItemIndex<[I_data count]) {
        NSMutableDictionary *item=[I_data objectAtIndex:anItemIndex];
        [item setObject:[NSNumber numberWithBool:isExpanded] forKey:@"isExpanded"];
    }
}



- (id)listView:(TCMListView *)aListView objectValueForTag:(int)aTag atChildIndex:(int)aChildIndex ofItemAtIndex:(int)anItemIndex {
    if (aChildIndex == -1) {
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
    } else {
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
            if (aChildIndex >= 0 && aChildIndex < [sessions count]) {
                TCMMMSession *session=[sessions objectAtIndex:aChildIndex];
                if (aTag==TCMMMBrowserChildNameTag) {
                    return [session filename];
                } else if (aTag==TCMMMBrowserChildClientStatusTag) {
                    return [NSNumber numberWithInt:[session clientState]];
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
}

- (NSString *)listView:(TCMListView *)aListView toolTipStringAtChildIndex:(int)anIndex ofItemAtIndex:(int)anItemIndex {
    if (anItemIndex>=0 && anItemIndex<[I_data count]) {
        NSMutableDictionary *item=[I_data objectAtIndex:anItemIndex];
        TCMMMUser *user=[[TCMMMUserManager sharedInstance] userForUserID:[item objectForKey:@"UserID"]];
        if (user) {
            return [NSString stringWithFormat:@"AIM:%@\nEmail:%@",[[user properties] objectForKey:@"AIM"],[[user properties] objectForKey:@"Email"]];
        }
    }
    return nil;
}

- (BOOL)listView:(TCMListView *)listView writeRows:(NSIndexSet *)indexes toPasteboard:(NSPasteboard *)pboard {
    BOOL allowDrag = YES;
    NSMutableArray *plist = [NSMutableArray array];
    NSMutableIndexSet *set = [indexes mutableCopy];
    NSMutableString *vcfString= [NSMutableString string];
    unsigned int index;
    TCMMMUserManager *userManager=[TCMMMUserManager sharedInstance];
    while ((index = [set firstIndex]) != NSNotFound) {
        ItemChildPair pair = [listView itemChildPairAtRow:index];
        NSMutableDictionary *item = [I_data objectAtIndex:pair.itemIndex];
        NSMutableDictionary *entry = [NSMutableDictionary new];
        [entry setObject:[item objectForKey:@"UserID"] forKey:@"UserID"];
        if ([item objectForKey:@"URLString"]) {
            [entry setObject:[item objectForKey:@"URLString"] forKey:@"URLString"];
        }
        NSString *vcf=[[userManager userForUserID:[item objectForKey:@"UserID"]] vcfRepresentation];
        if (vcf) {
            [vcfString appendString:vcf];
        }
        [plist addObject:entry];
        [entry release];
        if (pair.childIndex != -1) {
            allowDrag = NO;
            break;
        }
        [set removeIndex:index];
    }
    [set release];
    
    if (allowDrag) {
        [pboard declareTypes:[NSArray arrayWithObjects:@"PboardTypeTBD",NSVCardPboardType,nil] owner:nil];
        [pboard setPropertyList:plist forType:@"PboardTypeTBD"];
        [pboard setData:[vcfString dataUsingEncoding:NSUnicodeStringEncoding] forType:NSVCardPboardType];
    }
    
    return allowDrag;
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

- (void)addUserWithID:(NSString *)aUserID {
    if ([self TCM_indexOfItemWithUserID:aUserID]==-1) {
        // todo: handleSelection
        NSMutableDictionary *status=[[TCMMMPresenceManager sharedInstance] statusOfUserID:aUserID];
        NSMutableArray *sessions=[NSMutableArray array];
        if ([status objectForKey:@"Sessions"]) {
            [sessions addObjectsFromArray:[[status objectForKey:@"Sessions"] allValues]];
        }
        [I_data addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:aUserID,@"UserID",sessions,@"Sessions",[NSNumber numberWithBool:YES],@"isExpanded",nil]];
        [O_browserListView reloadData];
    }
}

- (void)removeUserWithID:(NSString *)aUserID {
    int index=[self TCM_indexOfItemWithUserID:aUserID];
    if (index!=-1) {
        // todo: handleSelection
        [I_data removeObjectAtIndex:index];
        [O_browserListView reloadData];
    }
}

- (void)userDidChangeRendezvousStatus:(NSNotification *)aNotification {
    NSEnumerator *userIDs=[[[aNotification userInfo] objectForKey:@"UserIDs"] objectEnumerator];
    NSString *userID=nil;
    TCMMMPresenceManager *pm=[TCMMMPresenceManager sharedInstance];
    while ((userID=[userIDs nextObject])) {
        NSMutableDictionary *status=[pm statusOfUserID:userID];
        if ([status objectForKey:@"NetService"]) {
            [I_userIDsInRendezvous addObject:userID];
            if ([[status objectForKey:@"Status"] isEqualToString:@"GotStatus"] &&
                [status objectForKey:@"isVisible"]!=nil) {
                [self addUserWithID:userID];
            }
        } else {
            [I_userIDsInRendezvous removeObject:userID];
            [self removeUserWithID:userID];
        }
    }
}

- (void)userDidChangeVisibility:(NSNotification *)aNotification {
    NSDictionary *userInfo=[aNotification userInfo];
    NSString *userID=[userInfo objectForKey:@"UserID"];
    BOOL isVisible=[[userInfo objectForKey:@"isVisible"] boolValue];
    // TODO: handle Selection
    if (isVisible) {
        if ([I_userIDsInRendezvous containsObject:userID]) {
            [self addUserWithID:userID];
        }
    } else {
        [self removeUserWithID:userID];
    }
}

- (void)userDidChangeAnnouncedDocuments:(NSNotification *)aNotification {
    NSDictionary *userInfo=[aNotification userInfo];
    NSString *userID=[userInfo objectForKey:@"UserID"];
    int index=[self TCM_indexOfItemWithUserID:userID];
    // TODO: handle Selection
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
    if ([I_userIDsInRendezvous containsObject:[user userID]]) {
        DEBUGLOG(@"RendezvousLogDomain", AllLogLevel, @"reloadData");
        [O_browserListView reloadData];
    }
}

@end
