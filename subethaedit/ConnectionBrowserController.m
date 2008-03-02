//
//  InternetBrowserController.m
//  SubEthaEdit
//
//  Created by Martin Ott on Wed Mar 03 2004.
//  Copyright (c) 2004-2007 TheCodingMonkeys. All rights reserved.
//

#import "TCMMillionMonkeys/TCMMillionMonkeys.h"
#import "ConnectionBrowserController.h"
#import "AppController.h"
#import "TCMHost.h"
#import "TCMBEEP.h"
#import "TCMFoundation.h"
#import "TCMMMUserManager.h"
#import "TCMMMUserSEEAdditions.h"
#import "TCMMMBrowserListView.h"
#import "ImagePopUpButtonCell.h"
#import "PullDownButtonCell.h"
#import "TexturedButtonCell.h"
#import "NSWorkspaceTCMAdditions.h"
#import "ServerConnectionManager.h"
#import "ConnectionBrowserEntry.h"
#import <AddressBook/AddressBook.h>

#import <netdb.h>       // getaddrinfo, struct addrinfo, AI_NUMERICHOST
#import <TCMPortMapper/TCMPortMapper.h>


#define kMaxNumberOfItems 10

enum {
    BrowserContextMenuTagJoin = 1,
    BrowserContextMenuTagAIM,
    BrowserContextMenuTagEmail,
    BrowserContextMenuTagShowDocument,
    BrowserContextMenuTagCancelConnection,
    BrowserContextMenuTagReconnect,
    BrowserContextMenuTagLogIn,
    BrowserContextMenuTagManageFiles,
    BrowserContextMenuTagClear,
    BrowserContextMenuTagPeerExchange
};

@interface ConnectionBrowserController (InternetBrowserControllerPrivateAdditions)

- (NSSet *)selectedEntriesFilteredUsingPredicate:(NSPredicate *)aPredicate;
- (void)connectToURL:(NSURL *)anURL retry:(BOOL)isRetrying;
- (void)TCM_validateStatusPopUpButton;
- (void)TCM_validateClearButton;
- (NSArray *)clearableEntries;

@end

#pragma mark -

static ConnectionBrowserController *sharedInstance = nil;

static NSPredicate *S_cancelableEntryPredicate = nil;
static NSPredicate *S_reconnectableEntryPredicate = nil;
static NSPredicate *S_showableSessionPredicate = nil;
static NSPredicate *S_joinableSessionPredicate = nil;

@implementation ConnectionBrowserController

+ (void)initialize {
    S_cancelableEntryPredicate = [[NSPredicate predicateWithFormat:@"isBonjour == NO AND connectionStatus != %@ AND hostStatus != %@",ConnectionStatusNoConnection,@"HostEntryStatusCancelling"] retain];
    S_reconnectableEntryPredicate = [[NSPredicate predicateWithFormat:@"isBonjour == NO AND connectionStatus == %@ ",ConnectionStatusNoConnection] retain];
    S_showableSessionPredicate = [[NSPredicate predicateWithFormat:@"clientState != %d",TCMMMSessionClientNoState] retain];
    S_joinableSessionPredicate = [[NSPredicate predicateWithFormat:@"clientState = %d",TCMMMSessionClientNoState] retain];
}

+ (ConnectionBrowserController *)sharedInstance {
    return sharedInstance;
}

- (id)init {
    self = [super initWithWindowNibName:@"ConnectionBrowser"];
    if (self) {
        I_storedSelections = [NSMutableArray new];
        I_entriesController = [NSArrayController new];
        [I_entriesController setSortDescriptors:[NSArray arrayWithObjects:
            [[[NSSortDescriptor alloc] initWithKey:@"isBonjour" ascending:NO] autorelease],
            [[[NSSortDescriptor alloc] initWithKey:@"creationDate" ascending:YES] autorelease],
            nil]
        ];
        [I_entriesController setFilterPredicate:[NSPredicate predicateWithFormat:@"isVisible = yes or isBonjour = no"]];
        [I_entriesController setClearsFilterPredicateOnInsertion:NO];
        I_contextMenu = [NSMenu new];
        NSMenuItem *item = nil;
        
        item = (NSMenuItem *)[I_contextMenu addItemWithTitle:NSLocalizedString(@"BrowserContextMenuJoin", @"Join document entry for Browser context menu") action:@selector(join:) keyEquivalent:@""];
        [item setTarget:self];
        [item setTag:BrowserContextMenuTagJoin];
    
        item = (NSMenuItem *)[I_contextMenu addItemWithTitle:NSLocalizedString(@"BrowserContextMenuShowDocument", @"Show document entry for Browser context menu") action:@selector(show:) keyEquivalent:@""];
        [item setTarget:self];
        [item setTag:BrowserContextMenuTagShowDocument];

        [I_contextMenu addItem:[NSMenuItem separatorItem]];

        item = (NSMenuItem *)[I_contextMenu addItemWithTitle:NSLocalizedString(@"BrowserContextMenuAIM", @"AIM user entry for Browser context menu") action:@selector(initiateAIMChat:) keyEquivalent:@""];
        [item setTarget:[TCMMMUserManager sharedInstance]];
        [item setTag:BrowserContextMenuTagAIM];
                
        item = (NSMenuItem *)[I_contextMenu addItemWithTitle:NSLocalizedString(@"BrowserContextMenuEmail", @"Email user entry for Browser context menu") action:@selector(sendEmail:) keyEquivalent:@""];
        [item setTarget:[TCMMMUserManager sharedInstance]];
        [item setTag:BrowserContextMenuTagEmail];
        
        [I_contextMenu addItem:[NSMenuItem separatorItem]];
        
        item = (NSMenuItem *)[I_contextMenu addItemWithTitle:NSLocalizedString(@"BrowserContextMenuCancelConnection", @"Cancel connetion entry for Browser context menu") action:@selector(cancelConnection:) keyEquivalent:@""];
        [item setTarget:self];
        [item setTag:BrowserContextMenuTagCancelConnection];
        
        item = (NSMenuItem *)[I_contextMenu addItemWithTitle:NSLocalizedString(@"BrowserContextMenuReconnect", @"Reconnect entry for Browser context menu") action:@selector(reconnect:) keyEquivalent:@""];
        [item setTarget:self];
        [item setTag:BrowserContextMenuTagReconnect];        
        
        [I_contextMenu addItem:[NSMenuItem separatorItem]];

        item = (NSMenuItem *)[I_contextMenu addItemWithTitle:NSLocalizedString(@"BrowserContextMenuFriendcast", @"Log In entry for Browser context Peer Exchange") action:@selector(togglePeerExchange:) keyEquivalent:@""];
        [item setTarget:self];
        [item setTag:BrowserContextMenuTagPeerExchange];

//        item = (NSMenuItem *)[I_contextMenu addItemWithTitle:NSLocalizedString(@"BrowserContextMenuLogIn", @"Log In entry for Browser context menu") action:@selector(login:) keyEquivalent:@""];
//        [item setTarget:self];
//        [item setTag:BrowserContextMenuTagLogIn];
//
//
//
//
//        item = (NSMenuItem *)[I_contextMenu addItemWithTitle:NSLocalizedString(@"BrowserContextMenuManageFiles", @"Manage files entry for Browser context menu") action:@selector(openServerConnection:) keyEquivalent:@""];
//        [item setTarget:[ServerConnectionManager sharedInstance]];
//        [item setTag:BrowserContextMenuTagManageFiles];

        [I_contextMenu setDelegate:self];        


        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidChangeVisibility:) name:TCMMMPresenceManagerUserVisibilityDidChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidChangeAnnouncedDocuments:) name:TCMMMPresenceManagerUserSessionsDidChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectionEntryDidChange:) name:ConnectionBrowserEntryStatusDidChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectionEntryDidChange:) name:TCMBEEPSessionAuthenticationInformationDidChangeNotification object:nil];    
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

    }
    return self;    
}

- (void)dealloc {
    [I_storedSelections release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [I_entriesController release];
    [I_contextMenu release];
    [super dealloc];
}

- (void) validateButtons {
    NSSet *entries = [self selectedEntriesFilteredUsingPredicate:[NSPredicate predicateWithValue:YES]];
    if ([entries count] == 1 && [[NSUserDefaults standardUserDefaults] boolForKey:AutoconnectPrefKey]) {
        ConnectionBrowserEntry *entry = [entries anyObject];
        NSMutableDictionary *status = [[TCMMMPresenceManager sharedInstance] statusOfUserID:[[entry user] userID]];
        [O_toggleFriendcastButton setEnabled:[[status objectForKey:@"hasFriendCast"] boolValue]];
        [O_toggleFriendcastButton setState:[[status objectForKey:@"shouldAutoConnect"] boolValue]?NSOnState:NSOffState];
    } else {
        [O_toggleFriendcastButton setState:NSOffState];
        [O_toggleFriendcastButton setEnabled:NO];
    }
}

// on application launch (mainmenu.nib)
- (void)awakeFromNib {
    sharedInstance = self;
}


// on window load (Internet.nib)
- (void)windowWillLoad {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidChange:) name:TCMMMUserManagerUserDidChangeNotification object:nil];
}

- (void)storeSelection {
    NSMutableDictionary *selectedObjects = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSMutableSet set],@"Entries",[NSMutableDictionary dictionary],@"SessionsByEntry",nil];

    NSIndexSet *indexes = [O_browserListView selectedRowIndexes];
    if (indexes) {
        unsigned int index = [indexes firstIndex];
        while (index != NSNotFound) {
            ItemChildPair pair = [O_browserListView itemChildPairAtRow:index];
            ConnectionBrowserEntry *entry = [[I_entriesController arrangedObjects] objectAtIndex:pair.itemIndex];
            if (pair.childIndex == -1) {
                [[selectedObjects objectForKey:@"Entries"] addObject:entry];
            } else {
                NSMutableSet *set = [[selectedObjects objectForKey:@"SessionsByEntry"] objectForKey:[entry creationDate]];
                if (!set) {
                    set=[NSMutableSet set];
                    [[selectedObjects objectForKey:@"SessionsByEntry"] setObject:set forKey:[entry creationDate]];
                }
                [set addObject:[[entry announcedSessions] objectAtIndex:pair.childIndex]];
            }
            index = [indexes indexGreaterThanIndex:index];
        }
        [I_storedSelections addObject:selectedObjects];
    }
}
- (void)restoreSelection {
    NSDictionary *selectedObjects = [I_storedSelections lastObject];
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
    NSArray *arrangedObjects = [I_entriesController arrangedObjects];
    int i = 0;
    int index = 0;
    for (i = 0; i<[arrangedObjects count];i++) {
        ConnectionBrowserEntry *entry = [arrangedObjects objectAtIndex:i];
        if ([[selectedObjects objectForKey:@"Entries"] containsObject:entry]) {
            [indexes addIndex:index];
        }
        index +=1;
        NSArray *announcedSessions = [entry announcedSessions];
        NSSet *selectedSessions = [[selectedObjects objectForKey:@"SessionsByEntry"] objectForKey:[entry creationDate]];
        if (selectedSessions && [entry isDisclosed]) {
            int j = 0;
            for (j=0;j<[announcedSessions count];j++) {
                if ([selectedSessions containsObject:[announcedSessions objectAtIndex:j]]) {
                    [indexes addIndex:index+j];
                }
            }
        }
        if ([entry isDisclosed]) index += [announcedSessions count];

    }
    [O_browserListView selectRowIndexes:indexes byExtendingSelection:NO];
    if (selectedObjects) [I_storedSelections removeLastObject];
}



- (void)TCM_synchronizeMyNameAndPicture {
    TCMMMUser *me=[TCMMMUserManager me];
    [O_myNameTextField setStringValue:[me name]];
    NSImage *myImage = [me image];
    [myImage setFlipped:NO];
    [O_imageView setImage:myImage];
}

- (void)portMapperDidStartWork:(NSNotification *)aNotification {
    [O_portStatusProgressIndicator startAnimation:self];
    [O_portStatusImageView setHidden:YES];
    [O_portStatusTextField setStringValue:NSLocalizedString(@"Checking port status...",@"Status of port mapping while trying")];
}

- (void)portMapperDidFinishWork:(NSNotification *)aNotification {
    [O_portStatusProgressIndicator stopAnimation:self];

    TCMPortMapper *pm = [TCMPortMapper sharedInstance];
    // since we only have one mapping this is fine
    TCMPortMapping *mapping = [[pm portMappings] anyObject];
    if ([mapping mappingStatus]==TCMPortMappingStatusMapped) {
        [O_portStatusImageView setImage:[NSImage imageNamed:@"URLIconOK"]];
        [O_portStatusTextField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"see://%@:%d",@"Connection Browser URL display"), [pm externalIPAddress],[mapping externalPort]]];
    } else {
        [O_portStatusImageView setImage:[NSImage imageNamed:@"URLIconNotOK"]];
        [O_portStatusTextField setStringValue:NSLocalizedString(@"No public mapping.",@"Connection Browser Display when not reachable")];
    }
    [O_portStatusImageView setHidden:NO];
}


- (void)windowDidLoad {
    [[self window] setFrameAutosaveName:@"InternetBrowser"];
    [self TCM_synchronizeMyNameAndPicture];
    [((NSPanel *)[self window]) setFloatingPanel:NO];
    [[self window] setHidesOnDeactivate:NO];
    
    NSRect frame = [[O_scrollView contentView] frame];
    O_browserListView = [[TCMMMBrowserListView alloc] initWithFrame:frame];
    [O_scrollView setBorderType:NSBezelBorder];
    [O_browserListView setDataSource:self];
    [O_browserListView setDelegate:self];
    [O_browserListView setTarget:self];
    [O_browserListView setAction:@selector(actionTriggered:)];
    [O_browserListView setDoubleAction:@selector(doubleAction:)];
    [O_scrollView setHasVerticalScroller:YES];
    [[O_scrollView verticalScroller] setControlSize:NSSmallControlSize];
    [O_scrollView setDocumentView:O_browserListView];
    [O_scrollView setDrawsBackground:NO];
    [[O_scrollView contentView] setCopiesOnScroll:YES];
    [[O_scrollView contentView] setDrawsBackground:NO];
    [[O_scrollView contentView] setAutoresizesSubviews:NO];
    [O_browserListView noteEnclosingScrollView];

    TexturedButtonCell *textureCell=[[TexturedButtonCell new] autorelease];
    [textureCell setTarget:[[O_clearButton cell] target]];
    [textureCell setAction:[[O_clearButton cell] action]];
    [O_clearButton setCell:textureCell];
    [[O_clearButton cell] setButtonType:NSMomentaryLightButton];
    [O_clearButton setTitle:NSLocalizedString(@"InternetClear",@"Title of Clear Button in InternetBrowser")];
    [[O_clearButton cell] setTextureImage:[NSImage imageNamed:@"EmptyButton"]];
    [[O_clearButton cell] setControlSize:NSSmallControlSize];
    [[O_clearButton cell] setBordered:NO];
    [[O_clearButton cell] setBezeled:NO];
    [[O_clearButton cell] setHighlightsBy:NSNoCellMask];
    [O_clearButton setEnabled:YES];
    [O_clearButton setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSSmallControlSize]]];
    NSRect buttonFrame=[O_clearButton frame];
    [O_clearButton sizeToFit];
    NSRect newButtonFrame=[O_clearButton frame];
    float widthdifference=newButtonFrame.size.width-buttonFrame.size.width+8;
    buttonFrame.origin.x-=widthdifference;
    buttonFrame.size.width+=widthdifference;
    [O_clearButton setFrame:buttonFrame];
    [O_clearButton setEnabled:NO];
    
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

    PullDownButtonCell *cell = [[[PullDownButtonCell alloc] initTextCell:@"" pullsDown:YES] autorelease];
    NSMenu *oldMenu = [[[O_statusPopUpButton cell] menu] retain];
    [cell setPullsDown:NO];
    NSMenu *menu = [cell menu];
    NSEnumerator *menuItems = [[oldMenu itemArray] objectEnumerator];
    NSMenuItem *item=nil;
    while ((item = [menuItems nextObject])) {
        [menu addItem:[item copy]];
    }
    [oldMenu release];
    [O_statusPopUpButton setCell:cell];
    [cell setControlSize:NSSmallControlSize];
    [O_statusPopUpButton setPullsDown:YES];
    [O_statusPopUpButton setBordered:NO];
    [cell setUsesItemFromMenu:YES];
    [O_statusPopUpButton setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSSmallControlSize]]];
    [[O_statusPopUpButton menu] setDelegate:self];
    [self TCM_validateStatusPopUpButton];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(announcedSessionsDidChange:) name:TCMMMPresenceManagerAnnouncedSessionsDidChangeNotification object:[TCMMMPresenceManager sharedInstance]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(announcedSessionsDidChange:) name:TCMMMPresenceManagerServiceAnnouncementDidChangeNotification object:[TCMMMPresenceManager sharedInstance]];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionClientStateDidChange:) name:TCMMMSessionClientStateDidChangeNotification object:nil];

    [O_addressComboBox setUsesDataSource:YES];
    [O_addressComboBox setDataSource:self];
    [O_addressComboBox setCompletes:YES];
    [self setComboBoxItems:[[NSUserDefaults standardUserDefaults] objectForKey:AddressHistory]];
    [O_addressComboBox noteNumberOfItemsChanged];
    [O_addressComboBox reloadData];
    if ([[self comboBoxItems] count] > 0) {
        [O_addressComboBox setObjectValue:[[self comboBoxItems] objectAtIndex:0]];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(validateButtons) name:ListViewDidChangeSelectionNotification object:O_browserListView];

    [self validateButtons];
    // Port Mappings
    TCMPortMapper *pm = [TCMPortMapper sharedInstance];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(portMapperDidStartWork:) name:TCMPortMapperDidStartWorkNotification object:pm];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(portMapperDidFinishWork:) name:TCMPortMapperDidFinishWorkNotification object:pm];
    [O_portStatusImageView setDelegate:self];
    if ([pm isAtWork]) {
        [self portMapperDidStartWork:nil];
    } else {
        [self portMapperDidFinishWork:nil];
    }
    
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:[@"values." stringByAppendingString:AutoconnectPrefKey] options:0 context:nil];
}

- (void)observeValueForKeyPath:(NSString *)aKeyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	[O_browserListView setNeedsDisplay:YES];
	[self validateButtons];
}


- (NSURL*)URLForURLImageView:(URLImageView *)anImageView {
    TCMPortMapper *pm = [TCMPortMapper sharedInstance];
    NSString *URLString = [NSString stringWithFormat:@"see://%@:%d", [pm localBonjourHostName],[[TCMMMBEEPSessionManager sharedInstance] listeningPort]];
    TCMPortMapping *mapping = [[pm portMappings] anyObject];
    if ([mapping mappingStatus]==TCMPortMappingStatusMapped) {
        URLString = [NSString stringWithFormat:@"see://%@:%d", [pm externalIPAddress],[mapping externalPort]];
    }
    return [NSURL URLWithString:URLString];
}


- (void)sessionClientStateDidChange:(NSNotification *)aNotificaiton {
    [O_browserListView setNeedsDisplay:YES];
}

- (void)windowWillClose:(NSNotification *)aNotification {
    DEBUGLOG(@"InternetLogDomain", DetailedLogLevel, @"InternetBrowser willClose");
    [[NSUserDefaults standardUserDefaults] setObject:[self comboBoxItems] forKey:AddressHistory];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark -
#pragma mark ### Menu validation ###

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    SEL selector = [menuItem action];
    if (selector == @selector(join:) ||
        selector == @selector(login:) ||
        selector == @selector(togglePeerExchange:) ||
        selector == @selector(show:) ||
        selector == @selector(reconnect:) ||
        selector == @selector(clear:) ||
        selector == @selector(cancelConnection:)) {
        return [menuItem isEnabled];
    }
    return YES;
}

- (void)menuNeedsUpdate:(NSMenu *)menu {
    
    if ([menu isEqual:[O_statusPopUpButton menu]]) {
        BOOL isVisible = [[TCMMMPresenceManager sharedInstance] isVisible];
        [[menu itemWithTag:10] setState:isVisible ? NSOnState : NSOffState];
        [[menu itemWithTag:11] setState:(!isVisible) ? NSOnState : NSOffState];
        [[menu itemWithTag:12] setState:[[TCMMMBEEPSessionManager sharedInstance] isProhibitingInboundInternetSessions] ? NSOnState : NSOffState];
        return;
    }
    
    NSMutableArray *entries = [NSMutableArray array];
    NSMutableArray *sessions = [NSMutableArray array];
    NSArray *arrangedObjects = [I_entriesController arrangedObjects];
    
    NSIndexSet *indexes = [O_browserListView selectedRowIndexes];
    unsigned int index = [indexes firstIndex];
    while (index != NSNotFound) {
        ItemChildPair pair = [O_browserListView itemChildPairAtRow:index];
        ConnectionBrowserEntry *entry = [arrangedObjects objectAtIndex:pair.itemIndex];
        if (pair.childIndex == -1) {
            [entries addObject:entry];
        } else {
            [sessions addObject:[[entry announcedSessions] objectAtIndex:pair.childIndex]];
        }
        index = [indexes indexGreaterThanIndex:index];
    }

    NSMenuItem *item = nil;

    if ([sessions count] > 0) {
        item = [menu itemWithTag:BrowserContextMenuTagJoin];
        [item setEnabled:([[sessions filteredArrayUsingPredicate:S_joinableSessionPredicate] count]>0)];
        item = [menu itemWithTag:BrowserContextMenuTagShowDocument];
        [item setEnabled:([[sessions filteredArrayUsingPredicate:S_showableSessionPredicate] count]>0)];
    } else {
        item = [menu itemWithTag:BrowserContextMenuTagJoin];
        [item setEnabled:NO];
        item = [menu itemWithTag:BrowserContextMenuTagShowDocument];
        [item setEnabled:NO];
    }
    
    
    // default: disable then check what to enable
    item = [menu itemWithTag:BrowserContextMenuTagAIM];
    [item setEnabled:NO];
    item = [menu itemWithTag:BrowserContextMenuTagEmail];
    [item setEnabled:NO];
    item = [menu itemWithTag:BrowserContextMenuTagCancelConnection];
    [item setEnabled:NO];
    item = [menu itemWithTag:BrowserContextMenuTagReconnect];
    [item setEnabled:NO];
    item = [menu itemWithTag:BrowserContextMenuTagManageFiles];
    [item setRepresentedObject:nil];
    [item setEnabled:NO];

    item = [menu itemWithTag:BrowserContextMenuTagLogIn];
    [item setEnabled:YES];
    
    if ([entries count] > 0) {

        NSArray *users = [entries valueForKeyPath:@"@distinctUnionOfObjects.user"];

        NSArray *userIDsWithEmail = [[users filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"email != NULL"]] valueForKeyPath:@"@unionOfObjects.userID"];
        item = [menu itemWithTag:BrowserContextMenuTagEmail];
        [item setRepresentedObject:userIDsWithEmail];
        [item setEnabled:([userIDsWithEmail count]>0)];
        
        NSArray *userIDsWithAIM = [[users filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"aim != NULL"]] valueForKeyPath:@"@unionOfObjects.userID"];
        item = [menu itemWithTag:BrowserContextMenuTagAIM];
        [item setRepresentedObject:userIDsWithAIM];
        [item setEnabled:([userIDsWithAIM count]>0)];
        
        NSArray *cancelableEntries = [entries filteredArrayUsingPredicate:S_cancelableEntryPredicate];
//        NSLog(@"cancelableEntries: %@",cancelableEntries);
        item = [menu itemWithTag:BrowserContextMenuTagCancelConnection];
        [item setEnabled:([cancelableEntries count] > 0)];
        
        NSArray *reconnectableEntries = [entries filteredArrayUsingPredicate:S_reconnectableEntryPredicate];
//        NSLog(@"reconnectableEntries: %@",reconnectableEntries);
        item = [menu itemWithTag:BrowserContextMenuTagReconnect];
        [item setEnabled:([reconnectableEntries count] > 0)];
        
        item = [menu itemWithTag:BrowserContextMenuTagPeerExchange];
        if ([entries count] == 1 && [users count] == 1 && [[NSUserDefaults standardUserDefaults] boolForKey:AutoconnectPrefKey]) {
            [item setEnabled:YES];
            TCMMMUser *user = [users lastObject];
            NSMutableDictionary *status = [[TCMMMPresenceManager sharedInstance] statusOfUserID:[user userID]];
            [item setState:[[status objectForKey:@"shouldAutoConnect"] boolValue]?NSOnState:NSOffState];
        } else {
            [item setState:NSOffState];
            [item setEnabled:NO];
        }
    }
}

#pragma mark -
#pragma mark ### connection actions ###

- (void)connectToAddress:(NSString *)address {
    DEBUGLOG(@"InternetLogDomain", DetailedLogLevel, @"connect to address: %@", address);
    
    [self showWindow:nil];
    
    NSURL *url = [TCMMMBEEPSessionManager urlForAddress:address];
    
    DEBUGLOG(@"InternetLogDomain", DetailedLogLevel, @"scheme: %@\nhost: %@\nport: %@\npath: %@\nparameterString: %@\nquery: %@", [url scheme], [url host],  [url port], [url path], [url parameterString], [url query]);
    
    if (url != nil && [url host] != nil) {
        NSString *URLString = [url absoluteString];
        [I_comboBoxItems removeObject:URLString];
        [I_comboBoxItems insertObject:URLString atIndex:0];
        if ([I_comboBoxItems count] >= kMaxNumberOfItems) {
            [I_comboBoxItems removeLastObject];
        }
        [O_addressComboBox noteNumberOfItemsChanged];
        [O_addressComboBox reloadData];
        
        [self connectToURL:url retry:NO];
    } else {
        DEBUGLOG(@"InternetLogDomain", SimpleLogLevel, @"Entered invalid URI");
        NSBeep();
    }
}

- (ConnectionBrowserEntry *)connectionEntryForURL:(NSURL *)anURL {
    NSEnumerator *entries = [[I_entriesController content] objectEnumerator];
    ConnectionBrowserEntry *entry = nil;
    while ((entry=[entries nextObject])) {
        if ([entry handleURL:anURL]) {
            return entry;
        }
    }
    entry = [[[ConnectionBrowserEntry alloc] initWithURL:anURL] autorelease];
    [[I_entriesController content] addObject:entry];
    [I_entriesController rearrangeObjects];
    [O_browserListView reloadData];
    [self TCM_validateClearButton];
    return entry;
}

- (void)selectEntry:(ConnectionBrowserEntry *)anEntry {
    unsigned int index = [[I_entriesController arrangedObjects] indexOfObject:anEntry];
    if (index == NSNotFound) {
        [O_browserListView deselectAll:self];
    } else {
        [O_browserListView selectRow:[O_browserListView rowForItem:index child:-1] byExtendingSelection:NO];
    }
}

- (void)connectToURL:(NSURL *)anURL retry:(BOOL)isRetrying {
    DEBUGLOG(@"InternetLogDomain", DetailedLogLevel, @"Connect to URL: %@", [anURL description]);
    NSParameterAssert(anURL != nil && [anURL host] != nil);
    
    ConnectionBrowserEntry *entry = [self connectionEntryForURL:anURL];
    [self selectEntry:entry];
    [entry connect];
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    DEBUGLOG(@"InternetLogDomain", SimpleLogLevel, @"alertDidEnd:");
    
    NSDictionary *alertContext = (NSDictionary *)contextInfo;
    if (returnCode == NSAlertFirstButtonReturn) {
        DEBUGLOG(@"InternetLogDomain", SimpleLogLevel, @"abort connection");
        NSSet *set = [alertContext objectForKey:@"items"];
        NSEnumerator *enumerator = [set objectEnumerator];
        ConnectionBrowserEntry *entry=nil;
        while ((entry = [enumerator nextObject])) {
            [entry cancel];
        }
    }
    
    [alertContext autorelease];
}

- (NSArray *)clearableEntries {
    return [[I_entriesController arrangedObjects] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"connectionStatus = %@",ConnectionStatusNoConnection]];
}

- (void)TCM_validateStatusPopUpButton {
    TCMMMPresenceManager *pm = [TCMMMPresenceManager sharedInstance];
    BOOL isVisible = [pm isVisible];
    int announcedCount = [[pm announcedSessions] count];
    NSString *statusString = @"";
    if (announcedCount > 0) {
        statusString = [NSString stringWithFormat:NSLocalizedString(@"%d Document(s)",@"Status string showing the number of documents in Rendezvous and Internet browser"), announcedCount];
    } else if (isVisible) {
        statusString = NSLocalizedString(@"Visible", @"Status string in vibilitypulldown in Browsers for visible");
    } else {
        statusString = NSLocalizedString(@"Invisible", @"Status string in vibilitypulldown in Browsers for invisible");
    }
    [[[O_statusPopUpButton menu] itemAtIndex:0] setTitle:statusString];
}

- (void)TCM_validateClearButton {
    [O_clearButton setEnabled:[[self clearableEntries] count] > 0];
}

#pragma mark -
#pragma mark ### IBActions ###

- (IBAction)login:(id)aSender {
    NSSet *entries = [self selectedEntriesFilteredUsingPredicate:[NSPredicate predicateWithValue:YES]];
    // predicateWithFormat:@"BEEPSession.authenticationClient.availableAuthenticationMechanisms.@count > 0"]];
    ConnectionBrowserEntry *entry = [entries anyObject];
    if (entry) {
        [O_loginSheetController setBEEPSession:[entry BEEPSession]];
        [NSApp beginSheet:[O_loginSheetController window] modalForWindow:[self window] modalDelegate:nil didEndSelector:NULL contextInfo:nil];
    } else {
        NSBeep();
    }
}

- (IBAction)connect:(id)aSender {
    DEBUGLOG(@"InternetLogDomain", SimpleLogLevel, @"connect action triggered");
    NSString *address = [aSender objectValue];
    [self connectToAddress:address];
}

- (IBAction)setVisibilityByMenuItem:(id)aSender {
    BOOL isVisible = ([aSender tag] == 10);
    [[TCMMMPresenceManager sharedInstance] setVisible:isVisible];
    [[NSUserDefaults standardUserDefaults] setBool:isVisible forKey:VisibilityPrefKey];
}

- (IBAction)toggleProhibitInboundConnections:(id)aSender {
    if ([aSender state] == NSOffState) {
        [aSender setState:NSOnState];
        [[TCMMMBEEPSessionManager sharedInstance] setIsProhibitingInboundInternetSessions:YES];
    } else if ([aSender state] == NSOnState) {
        [aSender setState:NSOffState];
        [[TCMMMBEEPSessionManager sharedInstance] setIsProhibitingInboundInternetSessions:NO];    
    }
}

- (void)reconnectWithIndexes:(NSIndexSet *)indexes {
    DEBUGLOG(@"InternetLogDomain", DetailedLogLevel, @"trying to reconnect");
    NSMutableSet *set = [NSMutableSet set];
    unsigned int index = [indexes firstIndex];
    while (index != NSNotFound) {
        ItemChildPair pair = [O_browserListView itemChildPairAtRow:index];
        if (pair.childIndex == -1) {
            ConnectionBrowserEntry *entry = [[I_entriesController arrangedObjects] objectAtIndex:pair.itemIndex];
            if (entry) {
                [set addObject:entry];
            }
        }
        index = [indexes indexGreaterThanIndex:index];
    }
    [set makeObjectsPerformSelector:@selector(connect)];    
    [O_browserListView reloadData];
}

- (void)cancelConnectionsWithIndexes:(NSIndexSet *)indexes {
    DEBUGLOG(@"InternetLogDomain", DetailedLogLevel, @"cancel");
    NSMutableSet *set = [NSMutableSet set];
    BOOL abort = NO;
    unsigned int index = [indexes firstIndex];
    while (index != NSNotFound) {
        ItemChildPair pair = [O_browserListView itemChildPairAtRow:index];
        if (pair.childIndex == -1) {
            ConnectionBrowserEntry *entry = [[I_entriesController arrangedObjects] objectAtIndex:pair.itemIndex];
            if ([[[entry BEEPSession] valueForKeyPath:@"channels.@unionOfObjects.profileURI"] containsObject:@"http://www.codingmonkeys.de/BEEP/SubEthaEditSession"]) {
                abort = YES;
            }
            [set addObject:entry];
        }
        index = [indexes indexGreaterThanIndex:index];
    }
    
    if (abort) {
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert setMessageText:NSLocalizedString(@"OpenChannels", @"Sheet message text when user has open document connections")];
        [alert setInformativeText:NSLocalizedString(@"AbortChannels", @"Sheet informative text when user has open document connections")];
        [alert addButtonWithTitle:NSLocalizedString(@"Abort", @"Button title")];
        [alert addButtonWithTitle:NSLocalizedString(@"Keep Connection", @"Button title")];
        [[[alert buttons] objectAtIndex:0] setKeyEquivalent:@"\r"];
        [alert beginSheetModalForWindow:[self window]
                          modalDelegate:self 
                         didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
                            contextInfo:[[NSDictionary dictionaryWithObjectsAndKeys:
                                                    //item, @"item",
                                                    set, @"items",
                                                    nil] retain]]; 
    } else {
        [set makeObjectsPerformSelector:@selector(cancel)];
    }
    [O_browserListView reloadData];
    [self TCM_validateClearButton];
}

- (void)joinSessionsWithIndexes:(NSIndexSet *)indexes {
    DEBUGLOG(@"InternetLogDomain", DetailedLogLevel, @"join");
    unsigned int index = [indexes firstIndex];
    while (index != NSNotFound) {
        ItemChildPair pair = [O_browserListView itemChildPairAtRow:index];
        ConnectionBrowserEntry *entry = [[I_entriesController arrangedObjects] objectAtIndex:pair.itemIndex];
        if (pair.childIndex != -1) {
            NSArray *sessions = [entry announcedSessions];
            TCMMMSession *session = [sessions objectAtIndex:pair.childIndex];
            TCMBEEPSession *BEEPSession = [entry BEEPSession];
            DEBUGLOG(@"InternetLogDomain", DetailedLogLevel, @"join on session: %@, using BEEPSession: %@", session, BEEPSession);
            [session joinUsingBEEPSession:BEEPSession];
        }
        index = [indexes indexGreaterThanIndex:index];
    }
}

- (NSIndexSet *)indexSetOfSelectedSessionsFilteredUsingPredicate:(NSPredicate *)aPredicate {
    NSMutableIndexSet *set = [NSMutableIndexSet indexSet];
    NSIndexSet *indexes = [O_browserListView selectedRowIndexes];
    unsigned int index = [indexes firstIndex];
    while (index != NSNotFound) {
        ItemChildPair pair = [O_browserListView itemChildPairAtRow:index];
        if (pair.childIndex != -1) {
            ConnectionBrowserEntry *entry = [[I_entriesController arrangedObjects] objectAtIndex:pair.itemIndex];
            if ([aPredicate evaluateWithObject:[[entry announcedSessions] objectAtIndex:pair.childIndex]]) {
                [set addIndex:index];
            }
        }
        index = [indexes indexGreaterThanIndex:index];
    }
    return set;
}

- (IBAction)join:(id)sender {
    [self joinSessionsWithIndexes:[self indexSetOfSelectedSessionsFilteredUsingPredicate:S_joinableSessionPredicate]];
}

- (IBAction)show:(id)sender {
    [self joinSessionsWithIndexes:[self indexSetOfSelectedSessionsFilteredUsingPredicate:S_showableSessionPredicate]];
}

- (IBAction)togglePeerExchange:(id)aSender {
    NSIndexSet *indexes = [O_browserListView selectedRowIndexes];
    if ([indexes count] == 1) {
        unsigned int index = [indexes firstIndex];
        ItemChildPair pair = [O_browserListView itemChildPairAtRow:index];
        ConnectionBrowserEntry *entry = [[I_entriesController arrangedObjects] objectAtIndex:pair.itemIndex];
        TCMMMUser *user = [entry user];
        if (user) {
            BOOL newValue = ![[[[TCMMMPresenceManager sharedInstance] statusOfUserID:[user userID]] objectForKey:@"shouldAutoConnect"] boolValue];
            [[TCMMMPresenceManager sharedInstance] setShouldAutoconnect:newValue forUserID:[user userID]];
            [O_browserListView setNeedsDisplay:YES];
        }
    }
    [self validateButtons];
}

- (IBAction)toggleFriendcast:(id)aSender {
    [self togglePeerExchange:aSender];
}


- (NSSet *)selectedEntriesFilteredUsingPredicate:(NSPredicate *)aPredicate {
    NSMutableSet *set = [NSMutableSet set];
    NSIndexSet *indexes = [O_browserListView selectedRowIndexes];
    unsigned int index = [indexes firstIndex];
    while (index != NSNotFound) {
        ItemChildPair pair = [O_browserListView itemChildPairAtRow:index];
        if (pair.childIndex == -1) {
            ConnectionBrowserEntry *entry = [[I_entriesController arrangedObjects] objectAtIndex:pair.itemIndex];
            if ([aPredicate evaluateWithObject:entry]) {
                [set addObject:entry];
            }
        }
        index = [indexes indexGreaterThanIndex:index];
    }
    return set;
}

- (NSIndexSet *)indexSetOfSelectedEntrysFilteredUsingPredicate:(NSPredicate *)aPredicate {
    NSMutableIndexSet *set = [NSMutableIndexSet indexSet];
    NSIndexSet *indexes = [O_browserListView selectedRowIndexes];
    unsigned int index = [indexes firstIndex];
    while (index != NSNotFound) {
        ItemChildPair pair = [O_browserListView itemChildPairAtRow:index];
        if (pair.childIndex == -1) {
            ConnectionBrowserEntry *entry = [[I_entriesController arrangedObjects] objectAtIndex:pair.itemIndex];
            if ([aPredicate evaluateWithObject:entry]) {
                [set addIndex:index];
            }
        }
        index = [indexes indexGreaterThanIndex:index];
    }
    return set;
}

- (IBAction)reconnect:(id)sender {
    [self reconnectWithIndexes:[self indexSetOfSelectedEntrysFilteredUsingPredicate:S_reconnectableEntryPredicate]];
}

- (IBAction)cancelConnection:(id)sender {
    [self cancelConnectionsWithIndexes:[self indexSetOfSelectedEntrysFilteredUsingPredicate:S_cancelableEntryPredicate]];
}

- (IBAction)actionTriggered:(id)aSender {
    int row = [aSender actionRow];
    DEBUGLOG(@"InternetLogDomain", DetailedLogLevel, @"actionTriggerd in row: %d", row);
    ItemChildPair pair = [aSender itemChildPairAtRow:row];
    if (pair.childIndex != -1) {
        return;
    }
    int index = pair.itemIndex;
    ConnectionBrowserEntry *entry = [[I_entriesController arrangedObjects] objectAtIndex:index];
    if ([entry connectionStatus] == ConnectionStatusNoConnection) {
        [entry connect];
    } else {
        [self cancelConnectionsWithIndexes:[NSIndexSet indexSetWithIndex:row]];
    }
}

- (IBAction)clear:(id)aSender {
    [I_entriesController removeObjects:[self clearableEntries]];
    [O_browserListView reloadData];
    [self TCM_validateClearButton];
}

- (IBAction)joinSession:(id)aSender {
    int row = [aSender clickedRow];
    DEBUGLOG(@"InternetLogDomain", DetailedLogLevel, @"joinSession in row: %d", row);
    
    ItemChildPair pair = [aSender itemChildPairAtRow:row];
    if (pair.childIndex != -1) {
        [self joinSessionsWithIndexes:[NSIndexSet indexSetWithIndex:row]];
    }
}

- (IBAction)doubleAction:(id)aSender {
    int row = [aSender clickedRow];
    DEBUGLOG(@"InternetLogDomain", DetailedLogLevel, @"joinSession in row: %d", row);
    
    ItemChildPair pair = [aSender itemChildPairAtRow:row];
    if (pair.childIndex != -1) {
        [self joinSessionsWithIndexes:[NSIndexSet indexSetWithIndex:row]];
    } else {
        [self togglePeerExchange:aSender];
    }
}


#pragma mark -
#pragma mark ### Entry lifetime management ###

- (void)TCM_didAcceptSession:(NSNotification *)notification {
    DEBUGLOG(@"InternetLogDomain", DetailedLogLevel, @"TCM_didAcceptSession: %@", notification);
    TCMBEEPSession *session = [[notification userInfo] objectForKey:@"Session"];
    
    [self storeSelection];
    
    NSEnumerator *entries = [[I_entriesController content] objectEnumerator];
    ConnectionBrowserEntry *entry = nil;
    BOOL sessionWasHandled = NO;
    while ((entry=[entries nextObject])) {
        if ([entry handleSession:session]) {
            sessionWasHandled = YES;
            break;
        }
    }
    if (!sessionWasHandled) {
        ConnectionBrowserEntry *entry = [[[ConnectionBrowserEntry alloc] initWithBEEPSession:session] autorelease];
        [[I_entriesController content] addObject:entry];
    }
    [I_entriesController rearrangeObjects];
    [O_browserListView reloadData];
    [self TCM_validateClearButton];
    [self restoreSelection];
}

- (void)TCM_sessionDidEnd:(NSNotification *)notification {
    [self storeSelection];
    DEBUGLOG(@"InternetLogDomain", DetailedLogLevel, @"TCM_sessionDidEnd: %@", notification);
    TCMBEEPSession *session = [[notification userInfo] objectForKey:@"Session"];
    ConnectionBrowserEntry *concernedEntry = nil;
    NSEnumerator *entries = [[I_entriesController content] objectEnumerator];
    ConnectionBrowserEntry *entry = nil;
    while ((entry=[entries nextObject])) {
        if ([entry BEEPSession] == session) {
            concernedEntry = entry;
            break;
        }
    }
    if (concernedEntry) {
        if (![concernedEntry handleSessionDidEnd:session]) {
            [[I_entriesController content] removeObject:concernedEntry];
        } 
        [I_entriesController rearrangeObjects];
        [O_browserListView reloadData];
    }
    [self TCM_validateClearButton];
    [self restoreSelection];
}


#pragma mark -
#pragma mark ### update notification handling ###

- (void)userDidChange:(NSNotification *)aNotification {
    DEBUGLOG(@"InternetLogDomain", AllLogLevel, @"userDidChange: %@", aNotification);
    if ([[[aNotification userInfo] objectForKey:@"User"] isMe]) {
        [self TCM_synchronizeMyNameAndPicture];
    } else {
        [I_entriesController rearrangeObjects];
        [O_browserListView reloadData];
    }
}

- (void)announcedSessionsDidChange:(NSNotification *)aNotification {
    [self TCM_validateStatusPopUpButton];
}

#pragma mark -

- (void)userDidChangeVisibility:(NSNotification *)aNotification {
    DEBUGLOG(@"InternetLogDomain", AllLogLevel, @"userDidChangeVisibility: %@", aNotification);
//    NSDictionary *userInfo = [aNotification userInfo];
//    NSString *userID = [userInfo objectForKey:@"UserID"];
    [self storeSelection];
    [I_entriesController rearrangeObjects];
    [O_browserListView reloadData];
    [self restoreSelection];
}

- (void)userDidChangeAnnouncedDocuments:(NSNotification *)aNotification {
    DEBUGLOG(@"InternetLogDomain", AllLogLevel, @"userDidChangeAnnouncedDocuments: %@", aNotification);
//    NSDictionary *userInfo = [aNotification userInfo];
//    NSString *userID = [userInfo objectForKey:@"UserID"];
    [self storeSelection];
    [[I_entriesController arrangedObjects] makeObjectsPerformSelector:@selector(reloadAnnouncedSessions)];
    [[I_entriesController arrangedObjects] makeObjectsPerformSelector:@selector(checkDocumentRequests)];
    [O_browserListView reloadData];
    [self restoreSelection];
}

#pragma mark -
#pragma mark ### list view methods ###

- (NSMenu *)contextMenuForListView:(TCMListView *)listView clickedAtRow:(int)row {
    return I_contextMenu;
}

- (BOOL)listView:(TCMListView *)aListView performActionForClickAtPoint:(NSPoint)aPoint atItemChildPair:(ItemChildPair)aPair {
//    NSLog(@"%s %@ %d %d",__FUNCTION__,NSStringFromPoint(aPoint),aPair.itemIndex,aPair.childIndex);
    if (aPair.childIndex == -1) {
        if (aPair.itemIndex>=0 && aPair.itemIndex<[[I_entriesController arrangedObjects] count]) {
            if (NSPointInRect(aPoint,NSMakeRect(62,25,9,9))) {
                [self storeSelection];
                ConnectionBrowserEntry *entry=[[I_entriesController arrangedObjects] objectAtIndex:aPair.itemIndex];
                [entry toggleDisclosure];
                [aListView reloadData];
                [self restoreSelection];
                return YES;
            } else if (NSPointInRect(aPoint,[(TCMMMBrowserListView *)aListView frameForTag:TCMMMBrowserItemImageNextToNameTag atChildIndex:aPair.childIndex ofItemAtIndex:aPair.itemIndex])) { 
                [aListView selectRow:[aListView rowForItem:aPair.itemIndex child:aPair.childIndex] byExtendingSelection:NO];
                [self login:self];
                return YES;
            }

        }
    }
    return NO;
}


- (int)listView:(TCMListView *)aListView numberOfEntriesOfItemAtIndex:(int)anItemIndex {
    if (anItemIndex==-1) {
        return [[I_entriesController arrangedObjects] count];
    } else {
        if (anItemIndex>=0 && anItemIndex<[[I_entriesController arrangedObjects] count]) {
            ConnectionBrowserEntry *entry=[[I_entriesController arrangedObjects] objectAtIndex:anItemIndex];
            return [entry isDisclosed]?[[entry announcedSessions] count]:0;
        }
        return 0;
    }
}

- (id)listView:(TCMListView *)aListView objectValueForTag:(int)aTag atChildIndex:(int)aChildIndex ofItemAtIndex:(int)anItemIndex {
    
    if (anItemIndex >= 0 && anItemIndex < [[I_entriesController arrangedObjects] count]) {
        ConnectionBrowserEntry *entry = [[I_entriesController arrangedObjects] objectAtIndex:anItemIndex];
        if (aChildIndex == -1) {
            return [entry itemObjectValueForTag:aTag];
        } else {
            return [entry objectValueForTag:aTag atChildIndex:aChildIndex];
        }
    }
    return nil;
}

- (NSString *)listView:(TCMListView *)aListView toolTipStringAtChildIndex:(int)anIndex ofItemAtIndex:(int)anItemIndex {
    if (anItemIndex>=0 && anItemIndex<[[I_entriesController arrangedObjects] count]) {
        ConnectionBrowserEntry *entry=[[I_entriesController arrangedObjects] objectAtIndex:anItemIndex];
        return [entry toolTipString];
    }
    
    return nil;
}

- (BOOL)listView:(TCMListView *)listView writeRows:(NSIndexSet *)indexes toPasteboard:(NSPasteboard *)pboard {
    BOOL allowDrag = YES;
    NSMutableArray *plist = [NSMutableArray array];
    NSMutableString *vcfString= [NSMutableString string];
    unsigned int index = [indexes firstIndex];
    while (index != NSNotFound) {
        ItemChildPair pair = [listView itemChildPairAtRow:index];
        if (pair.childIndex != -1) {
            allowDrag = NO;
            break;
        }
        ConnectionBrowserEntry *browserEntry = [[I_entriesController arrangedObjects] objectAtIndex:pair.itemIndex];
        if ([browserEntry connectionStatus] != ConnectionStatusConnected) {
            allowDrag = NO;
            break;
        }
        if ([browserEntry isVisible] && [browserEntry BEEPSession]) {
            NSMutableDictionary *entry = [NSMutableDictionary new];
            [entry setObject:[browserEntry userID] forKey:@"UserID"];
            [entry setObject:[[browserEntry BEEPSession] peerAddressData] forKey:@"PeerAddressData"];
            NSString *vcf = [[browserEntry user] vcfRepresentation];
            if (vcf) {
                [vcfString appendString:vcf];
            }
            [plist addObject:entry];
            [entry release];
        }
        index = [indexes indexGreaterThanIndex:index];
    }
    
    if (allowDrag) {
        [pboard declareTypes:[NSArray arrayWithObjects:@"PboardTypeTBD", NSVCardPboardType,NSCreateFileContentsPboardType(@"vcf"), nil] owner:nil];
        [pboard setPropertyList:plist forType:@"PboardTypeTBD"];
        [pboard setData:[vcfString dataUsingEncoding:NSUnicodeStringEncoding] forType:NSVCardPboardType];
        [pboard setData:[vcfString dataUsingEncoding:NSUnicodeStringEncoding] forType:NSCreateFileContentsPboardType(@"vcf")];
    }
    
    return allowDrag;
}

- (void)connectionEntryDidChange:(NSNotification *)aNotification {
    [O_browserListView reloadData];
    [self TCM_validateClearButton];
}

- (NSDragOperation)listView:(TCMListView *)aListView validateDrag:(id <NSDraggingInfo>)sender {
    NSPasteboard *pboard = [sender draggingPasteboard];
    if ([[pboard types] containsObject:@"PresentityNames"] && [[TCMPortMapper sharedInstance] externalIPAddress]) {
        return NSDragOperationGeneric;
    } else {
        return NSDragOperationNone;
    }
}
- (BOOL)listView:(TCMListView *)aListView prepareForDragOperation:(id <NSDraggingInfo>)sender {
//    NSLog(@"%s",__FUNCTION__);
    return YES;
}
- (BOOL)listView:(TCMListView *)aListView performDragOperation:(id <NSDraggingInfo>)sender{
//    NSLog(@"%s",__FUNCTION__);
    NSPasteboard *pboard = [sender draggingPasteboard];
    return [ConnectionBrowserController invitePeopleFromPasteboard:pboard withURL:[self URLForURLImageView:nil]];
}

+ (NSString *)quoteEscapedStringWithString:(NSString *)aString {
    NSMutableString *string = [[aString mutableCopy] autorelease];
    [string replaceOccurrencesOfString:@"\"" withString:@"\\\"" options:NSLiteralSearch range:NSMakeRange(0,[aString length])];
    return (NSString *)string;
}

+ (BOOL)invitePeopleFromPasteboard:(NSPasteboard *)aPasteboard withURL:(NSURL *)aDocumentURL{
    BOOL success = NO;
    if ([[aPasteboard types] containsObject:@"PresentityNames"] && 
        [[TCMPortMapper sharedInstance] externalIPAddress]) {
        NSArray *presentityNames=[aPasteboard propertyListForType:@"PresentityNames"]; 
        // format is service id, id in that service, onlinestatus (0=offline),groupname
        NSString *message = [NSString stringWithFormat:NSLocalizedString(@"Please join me in SubEthaEdit:\n%@\n\n(You can download SubEthaEdit from http://www.codingmonkeys.de/subethaedit )",@"iChat invitation String with Placeholder for actual URL"),[aDocumentURL absoluteString]];
        int i=0;
        for (i=0;i<[presentityNames count];i+=4) {
            NSString *applescriptString = [NSString stringWithFormat:@"tell application \"iChat\" to send \"%@\" to buddy id \"%@:%@\"",[self quoteEscapedStringWithString:message],[presentityNames objectAtIndex:i],[presentityNames objectAtIndex:i+1]];
            NSAppleScript *script = [[[NSAppleScript alloc] initWithSource:applescriptString] autorelease];
            // need to delay the sending so we don't try to send while in the dragging event
            [script performSelector:@selector(executeAndReturnError:) withObject:nil afterDelay:0.1];
        }
        success = YES;
    }

    return success;
}


#pragma mark -
#pragma mark ### combo box data source methods ###

- (NSMutableArray *)comboBoxItems {
    return I_comboBoxItems;
}

- (void)setComboBoxItems:(NSMutableArray *)anArray {
    [I_comboBoxItems autorelease];
    I_comboBoxItems = [anArray mutableCopy];
}


//
// NSComboBoxDataSource
//

- (unsigned int)comboBox:(NSComboBox *)comboBox indexOfItemWithStringValue:(NSString *)string {
    return [I_comboBoxItems indexOfObject:string];
}

- (id)comboBox:(NSComboBox *)comboBox objectValueForItemAtIndex:(int)index {
    return [I_comboBoxItems objectAtIndex:index];
}

- (int)numberOfItemsInComboBox:(NSComboBox *)comboBox {
    return [I_comboBoxItems count];
}

@end

