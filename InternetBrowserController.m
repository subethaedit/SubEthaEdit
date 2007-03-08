//
//  InternetBrowserController.m
//  SubEthaEdit
//
//  Created by Martin Ott on Wed Mar 03 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "InternetBrowserController.h"
#import "AppController.h"
#import "TCMHost.h"
#import "TCMBEEP.h"
#import "TCMFoundation.h"
#import "TCMMMUserManager.h"
#import "TCMMMUserSEEAdditions.h"
#import "ImagePopUpButtonCell.h"
#import "PullDownButtonCell.h"
#import "TexturedButtonCell.h"

#import <netdb.h>       // getaddrinfo, struct addrinfo, AI_NUMERICHOST


#define kMaxNumberOfItems 10

NSString * const HostEntryStatusResolving = @"HostEntryStatusResolving";
NSString * const HostEntryStatusResolveFailed = @"HostEntryStatusResolveFailed";
NSString * const HostEntryStatusContacting = @"HostEntryStatusContacting";
NSString * const HostEntryStatusContactFailed = @"HostEntryStatusContactFailed";
NSString * const HostEntryStatusSessionOpen = @"HostEntryStatusSessionOpen";
NSString * const HostEntryStatusSessionInvisible = @"HostEntryStatusSessionInvisible";
NSString * const HostEntryStatusSessionAtEnd = @"HostEntryStatusSessionAtEnd";
NSString * const HostEntryStatusCancelling = @"HostEntryStatusCancelling";
NSString * const HostEntryStatusCancelled = @"HostEntryStatusCancelled";

enum {
    BrowserContextMenuTagJoin = 1,
    BrowserContextMenuTagAIM,
    BrowserContextMenuTagEmail,
    BrowserContextMenuTagShowDocument,
    BrowserContextMenuTagCancelConnection,
    BrowserContextMenuTagReconnect
};

@interface InternetBrowserController (InternetBrowserControllerPrivateAdditions)

- (int)indexOfItemWithURLString:(NSString *)URLString;
- (int)indexOfItemWithUserID:(NSString *)userID;
- (NSIndexSet *)indexesOfItemsWithUserID:(NSString *)userID;
- (void)connectToURL:(NSURL *)url retry:(BOOL)isRetrying;
- (void)TCM_validateStatusPopUpButton;
- (void)TCM_validateClearButton;

@end

#pragma mark -

static InternetBrowserController *sharedInstance = nil;

@implementation InternetBrowserController

+ (InternetBrowserController *)sharedInstance {
    return sharedInstance;
}

- (id)init {
    self = [super initWithWindowNibName:@"InternetBrowser"];
    if (self) {
        I_data = [NSMutableArray new];
        I_resolvingHosts = [NSMutableDictionary new];
        I_resolvedHosts = [NSMutableDictionary new];
        I_documentRequestTimer = [[NSMutableDictionary alloc] init];

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
        
        [I_contextMenu addItem:[NSMenuItem separatorItem]];
        
        item = (NSMenuItem *)[I_contextMenu addItemWithTitle:NSLocalizedString(@"BrowserContextMenuCancelConnection", @"Cancel connetion entry for Browser context menu") action:@selector(cancelConnection:) keyEquivalent:@""];
        [item setTarget:self];
        [item setTag:BrowserContextMenuTagCancelConnection];
        
        item = (NSMenuItem *)[I_contextMenu addItemWithTitle:NSLocalizedString(@"BrowserContextMenuReconnect", @"Reconnect entry for Browser context menu") action:@selector(reconnect:) keyEquivalent:@""];
        [item setTarget:self];
        [item setTag:BrowserContextMenuTagReconnect];        
        
        [I_contextMenu setDelegate:self];        


        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidChangeVisibility:) name:TCMMMPresenceManagerUserVisibilityDidChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidChangeAnnouncedDocuments:) name:TCMMMPresenceManagerUserSessionsDidChangeNotification object:nil];
    
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
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [I_data release];
    [I_resolvingHosts release];
    [I_resolvedHosts release];
    [[I_documentRequestTimer allValues] makeObjectsPerformSelector:@selector(invalidate)];
    [I_documentRequestTimer release];
    [I_contextMenu release];
    [super dealloc];
}

// on application launch (mainmenu.nib)
- (void)awakeFromNib {
    sharedInstance = self;
}


// on window load (Internet.nib)
- (void)windowWillLoad {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidChange:) name:TCMMMUserManagerUserDidChangeNotification object:nil];
}

- (void)TCM_synchronizeMyNameAndPicture {
    TCMMMUser *me=[TCMMMUserManager me];
    [O_myNameTextField setStringValue:[me name]];
    [O_imageView setImage:[[me properties] objectForKey:@"Image"]];
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
    [O_browserListView setDoubleAction:@selector(joinSession:)];
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

    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    TCMMMBEEPSessionManager *manager = [TCMMMBEEPSessionManager sharedInstance];
    [defaultCenter addObserver:self 
                      selector:@selector(TCM_connectToHostDidFail:)
                          name:TCMMMBEEPSessionManagerConnectToHostDidFailNotification
                        object:manager];
    [defaultCenter addObserver:self
                      selector:@selector(TCM_connectToHostCancelled:)
                          name:TCMMMBEEPSessionManagerConnectToHostCancelledNotification
                        object:manager];
}

- (void)sessionClientStateDidChange:(NSNotification *)aNotificaiton {
    [O_browserListView setNeedsDisplay:YES];
}

- (void)windowWillClose:(NSNotification *)aNotification {
    DEBUGLOG(@"InternetLogDomain", DetailedLogLevel, @"InternetBrowser willClose");
    [[NSUserDefaults standardUserDefaults] setObject:[self comboBoxItems] forKey:AddressHistory];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


enum {
    kCancellableStateMask = 1,
    kReconnectableStateMask = 2,
    kOpenStateMask = 4
};

enum {
    kNoStateMask = 1,
    kJoiningStateMask = 2,
    kParticipantStateMask = 4
};


#pragma mark -
#pragma mark ### Menu validation ###

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    SEL selector = [menuItem action];
    if (selector == @selector(join:) ||
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
    
    NSMutableIndexSet *documentSet = [NSMutableIndexSet indexSet];
    NSMutableIndexSet *userSet = [NSMutableIndexSet indexSet];
    
    NSIndexSet *indexes = [O_browserListView selectedRowIndexes];
    unsigned int index = [indexes firstIndex];
    while (index != NSNotFound) {
        ItemChildPair pair = [O_browserListView itemChildPairAtRow:index];
        if (pair.childIndex == -1) {
            [userSet addIndex:index];
        } else {
            [documentSet addIndex:index];
        }
        index = [indexes indexGreaterThanIndex:index];
    }
    
    id item;

    if ([userSet count] > 0 && [documentSet count] > 0) {
        DEBUGLOG(@"InternetLogDomain", AllLogLevel, @"Disabling all menu items because of inconsistent selection");
        item = [menu itemWithTag:BrowserContextMenuTagJoin];
        [item setEnabled:NO];
        item = [menu itemWithTag:BrowserContextMenuTagShowDocument];
        [item setEnabled:NO];
        item = [menu itemWithTag:BrowserContextMenuTagAIM];
        [item setEnabled:NO];
        item = [menu itemWithTag:BrowserContextMenuTagEmail];
        [item setEnabled:NO];
        item = [menu itemWithTag:BrowserContextMenuTagCancelConnection];
        [item setEnabled:NO];
        item = [menu itemWithTag:BrowserContextMenuTagReconnect];
        [item setEnabled:NO];
        return;
    }
        
    if ([userSet count] == 0 && [documentSet count] == 0) {
        item = [menu itemWithTag:BrowserContextMenuTagJoin];
        [item setEnabled:NO];
        item = [menu itemWithTag:BrowserContextMenuTagShowDocument];
        [item setEnabled:NO];
        item = [menu itemWithTag:BrowserContextMenuTagAIM];
        [item setEnabled:NO];
        item = [menu itemWithTag:BrowserContextMenuTagEmail];
        [item setEnabled:NO];
        item = [menu itemWithTag:BrowserContextMenuTagCancelConnection];
        [item setEnabled:NO];
        item = [menu itemWithTag:BrowserContextMenuTagReconnect];
        [item setEnabled:NO];
    }
    
    if ([userSet count] > 0) {
        item = [menu itemWithTag:BrowserContextMenuTagJoin];
        [item setEnabled:NO];
        item = [menu itemWithTag:BrowserContextMenuTagShowDocument];    
        [item setEnabled:NO];

        NSMutableSet *dataSet = [NSMutableSet set];
        NSIndexSet *indexes = [O_browserListView selectedRowIndexes];
        unsigned int index = [indexes firstIndex];
        while (index != NSNotFound) {
            ItemChildPair pair = [O_browserListView itemChildPairAtRow:index];
            [dataSet addObject:[I_data objectAtIndex:pair.itemIndex]];
            index = [indexes indexGreaterThanIndex:index];
        }
        
        
        int state = 0;
        NSEnumerator *enumerator = [dataSet objectEnumerator];
        id dataItem;
        NSMutableSet *userIDs = [NSMutableSet set];
        while ((dataItem = [enumerator nextObject])) {
            NSString *status = [dataItem objectForKey:@"status"];
            if ([status isEqualToString:HostEntryStatusContacting] ||
                [status isEqualToString:HostEntryStatusResolving]) {
                state |= kCancellableStateMask;
            }
            if ([status isEqualToString:HostEntryStatusSessionOpen]) {
                [userIDs addObject:[dataItem objectForKey:@"UserID"]];
                state |= kOpenStateMask;
            }
            if ([dataItem objectForKey:@"failed"]) {
                state |= kReconnectableStateMask;
            }
        }
        
        if (!(state == 0 || state == 1 || state == 2 || state == 4)) {
            state = 0;
        }

        if (state & kOpenStateMask) {
            item = [menu itemWithTag:BrowserContextMenuTagAIM];
            [item setRepresentedObject:userIDs];
            item = [menu itemWithTag:BrowserContextMenuTagEmail];
            [item setRepresentedObject:userIDs];
        }
        TCMMMUserManager *manager = [TCMMMUserManager sharedInstance];
        item = [menu itemWithTag:BrowserContextMenuTagAIM];
        [item setEnabled:(state & kOpenStateMask) && [manager validateMenuItem:item]];
        item = [menu itemWithTag:BrowserContextMenuTagEmail];
        [item setEnabled:(state & kOpenStateMask) && [manager validateMenuItem:item]];
        
        item = [menu itemWithTag:BrowserContextMenuTagCancelConnection];
        [item setEnabled:(state & kCancellableStateMask) || (state & kOpenStateMask)];
        item = [menu itemWithTag:BrowserContextMenuTagReconnect];
        [item setEnabled:(state & kReconnectableStateMask) && YES]; 
                
        return;
    }
    
    
    if ([documentSet count] > 0) {
        item = [menu itemWithTag:BrowserContextMenuTagAIM];
        [item setEnabled:NO];
        item = [menu itemWithTag:BrowserContextMenuTagEmail];
        [item setEnabled:NO];
        item = [menu itemWithTag:BrowserContextMenuTagCancelConnection];
        [item setEnabled:NO];
        item = [menu itemWithTag:BrowserContextMenuTagReconnect];
        [item setEnabled:NO]; 
    
        NSMutableSet *sessionSet = [NSMutableSet set];
        NSIndexSet *indexes = [O_browserListView selectedRowIndexes];
        unsigned int index = [indexes firstIndex];
        while (index != NSNotFound) {
            ItemChildPair pair = [O_browserListView itemChildPairAtRow:index];
            NSDictionary *dataItem = [I_data objectAtIndex:pair.itemIndex];
            NSArray *sessions = [dataItem objectForKey:@"Sessions"];
            [sessionSet addObject:[sessions objectAtIndex:pair.childIndex]];
            index = [indexes indexGreaterThanIndex:index];
        }
        
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
        item = [menu itemWithTag:BrowserContextMenuTagJoin];
        [item setEnabled:(state & kNoStateMask) && YES];
        item = [menu itemWithTag:BrowserContextMenuTagShowDocument];    
        [item setEnabled:(state & kParticipantStateMask) || (state & kJoiningStateMask)];
        
        return;
    }
}

#pragma mark -

- (void)connectToAddress:(NSString *)address {
    DEBUGLOG(@"InternetLogDomain", DetailedLogLevel, @"connect to address: %@", address);
    
    [self showWindow:nil];
    
    NSString *URLString = nil;
    NSString *schemePrefix = [NSString stringWithFormat:@"%@://", @"see"];
    NSString *lowercaseAddress = [address lowercaseString];
    if (![lowercaseAddress hasPrefix:schemePrefix]) {
        NSString *addressWithPrefix = [schemePrefix stringByAppendingString:address];
        URLString = addressWithPrefix;
    } else {
        URLString = address;
    }
    
    DEBUGLOG(@"InternetLogDomain", DetailedLogLevel, @"URLString: %@", URLString);
    NSURL *url = [NSURL URLWithString:URLString];

    DEBUGLOG(@"InternetLogDomain", DetailedLogLevel, @"scheme: %@\nhost: %@\nport: %@\npath: %@\nparameterString: %@\nquery: %@", [url scheme], [url host],  [url port], [url path], [url parameterString], [url query]);
    
    if (url != nil && [url host] != nil) {
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

- (void)connectToURL:(NSURL *)url retry:(BOOL)isRetrying {
    DEBUGLOG(@"InternetLogDomain", DetailedLogLevel, @"Connect to URL: %@", [url description]);
    NSParameterAssert(url != nil && [url host] != nil);
    
    if (url != nil && [url host] != nil) {
        UInt16 port;
        if ([url port] != nil) {
            port = [[url port] unsignedShortValue];
        } else {
            port = SUBETHAEDIT_DEFAULT_PORT;
        }
        
        NSData *addressData = nil;
        NSString *hostAddress = [url host];

        const char *ipAddress = [hostAddress UTF8String];
        struct addrinfo hints;
        struct addrinfo *result = NULL;
        BOOL isIPv6Address = NO;

        memset(&hints, 0, sizeof(hints));
        hints.ai_flags    = AI_NUMERICHOST;
        hints.ai_family   = PF_UNSPEC;
        hints.ai_socktype = SOCK_STREAM;
        hints.ai_protocol = 0;
        
        char *portString = NULL;
        int err = asprintf(&portString, "%d", port);
        NSAssert(err != -1, @"Failed to convert given port from int to char*");

        err = getaddrinfo(ipAddress, portString, &hints, &result);
        if (err == 0) {
            addressData = [NSData dataWithBytes:(UInt8 *)result->ai_addr length:result->ai_addrlen];
            isIPv6Address = result->ai_family == PF_INET6;
            DEBUGLOG(@"InternetLogDomain", DetailedLogLevel, @"getaddrinfo succeeded with addr: %@", [NSString stringWithAddressData:addressData]);
            freeaddrinfo(result);
        } else {
            DEBUGLOG(@"InternetLogDomain", SimpleLogLevel, @"Neither IPv4 nor IPv6 address");
        }
        if (portString) {
            free(portString);
        }
        
        NSString *URLString = nil;
        if (isIPv6Address) {
            URLString = [NSString stringWithFormat:@"%@://[%@]:%d", [url scheme], hostAddress, port];
        } else {
            URLString = [NSString stringWithFormat:@"%@://%@:%d", [url scheme], hostAddress, port];
        }
        
        // when I_data entry with URL exists, select entry
        int index = [self indexOfItemWithURLString:URLString];
        if (index != -1) {
            NSMutableDictionary *item = [I_data objectAtIndex:index];
            NSMutableSet *set = [item objectForKey:@"URLRequests"];
            [set addObject:url];
            
            NSTimer *timer = [I_documentRequestTimer objectForKey:url];
            if (timer) {
                [timer setFireDate:[NSDate dateWithTimeIntervalSinceNow:60.0]];
            }
            
            BOOL shouldReconnect = NO;
            if ([item objectForKey:@"failed"]) {
                DEBUGLOG(@"InternetLogDomain", DetailedLogLevel, @"trying to reconnect");
                [item removeObjectForKey:@"BEEPSession"];
                [item removeObjectForKey:@"UserID"];
                [item removeObjectForKey:@"Sessions"];
                [item removeObjectForKey:@"failed"];
                shouldReconnect = YES;           
            }
            
            shouldReconnect = isRetrying || shouldReconnect;
            if (!shouldReconnect) {
                int row = [O_browserListView rowForItem:index child:-1];
                [O_browserListView selectRow:row byExtendingSelection:NO];
                
                NSEnumerator *enumerator = [[item objectForKey:@"Sessions"] objectEnumerator];
                TCMMMSession *session;
                while ((session = [enumerator nextObject])) {
                    if ([session isAddressedByURL:url]) {
                        [I_documentRequestTimer removeObjectForKey:url];
                        TCMBEEPSession *BEEPSession = [item objectForKey:@"BEEPSession"];
                        [session joinUsingBEEPSession:BEEPSession];
                        
                        NSTimer *timer = [I_documentRequestTimer objectForKey:url];
                        if (timer) {
                            [timer invalidate];
                            [I_documentRequestTimer removeObjectForKey:url];
                        }
                        [[item objectForKey:@"URLRequests"] removeObject:url];
                        break;
                    }
                }                
            } else {
                if (isRetrying) {
                    NSMutableSet *requests = [item objectForKey:@"URLRequests"];
                    [requests removeAllObjects];
                }
                
                [I_resolvingHosts removeObjectForKey:URLString];
                [I_resolvedHosts removeObjectForKey:URLString];
                
                TCMHost *host;
                if (addressData) {
                    host = [TCMHost hostWithAddressData:addressData port:port userInfo:[NSDictionary dictionaryWithObject:URLString forKey:@"URLString"]];
                    [[I_data objectAtIndex:index] setObject:HostEntryStatusContacting forKey:@"status"];
                    [O_browserListView reloadData];
                    [I_resolvedHosts setObject:host forKey:URLString];
                    [[TCMMMBEEPSessionManager sharedInstance] connectToHost:host];
                } else {
                    host = [TCMHost hostWithName:[url host] port:port userInfo:[NSDictionary dictionaryWithObject:URLString forKey:@"URLString"]];
                    [I_resolvingHosts setObject:host forKey:URLString];
                    NSMutableDictionary *item = [I_data objectAtIndex:index];
                    [item setObject:HostEntryStatusResolving forKey:@"status"];
                    [item setObject:URLString forKey:@"URLString"];
                    [host setDelegate:self];
                    [host resolve];
                }
            }
        } else {
            // otherwise add new entry to I_data
            if (addressData) {
                TCMHost *host = [TCMHost hostWithAddressData:addressData port:port userInfo:[NSDictionary dictionaryWithObject:URLString forKey:@"URLString"]];
                [I_data addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                            URLString, @"URLString",
                                                            HostEntryStatusContacting, @"status",
                                                            [NSMutableSet setWithObject:url], @"URLRequests",
                                                            url, @"URL", nil]];
                [O_browserListView reloadData];
                [I_resolvedHosts setObject:host forKey:URLString];
                [[TCMMMBEEPSessionManager sharedInstance] connectToHost:host];
            } else {
                TCMHost *host = [TCMHost hostWithName:[url host] port:port userInfo:[NSDictionary dictionaryWithObject:URLString forKey:@"URLString"]];
                [I_resolvingHosts setObject:host forKey:URLString];
                [I_data addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                            URLString, @"URLString",
                                                            HostEntryStatusResolving, @"status",
                                                            [NSMutableSet setWithObject:url], @"URLRequests",
                                                            url, @"URL", nil]];
                [host setDelegate:self];
                [host resolve];
            }
        }
    } else {
        DEBUGLOG(@"InternetLogDomain", SimpleLogLevel, @"Invalid URI");
    }
    
    [O_browserListView reloadData];
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    DEBUGLOG(@"InternetLogDomain", SimpleLogLevel, @"alertDidEnd:");
    
    NSDictionary *alertContext = (NSDictionary *)contextInfo;
    if (returnCode == NSAlertFirstButtonReturn) {
        DEBUGLOG(@"InternetLogDomain", SimpleLogLevel, @"abort connection");
        NSSet *set = [alertContext objectForKey:@"items"];
        NSEnumerator *enumerator = [set objectEnumerator];
        NSMutableDictionary *item;
        while ((item = [enumerator nextObject])) {
            [item removeObjectForKey:@"UserID"];
            [item setObject:[NSNumber numberWithBool:YES] forKey:@"failed"];
            [item setObject:HostEntryStatusCancelling forKey:@"status"];
            [O_browserListView reloadData];
            TCMBEEPSession *session = [item objectForKey:@"BEEPSession"];
            [session terminate];
            [O_browserListView reloadData];
        }
    }
    
    [alertContext autorelease];
}

- (int)indexOfItemWithURLString:(NSString *)URLString {
    int index = -1;
    int i;
    for (i = 0; i < [I_data count]; i++) {
        if ([URLString isEqualToString:[[I_data objectAtIndex:i] objectForKey:@"URLString"]]) {
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

- (NSIndexSet *)indexesOfItemsWithUserID:(NSString *)userID {
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
    int i;
    for (i = 0; i < [I_data count]; i++) {
        if ([userID isEqualToString:[[I_data objectAtIndex:i] objectForKey:@"UserID"]]) {
            [indexes addIndex:i];
        }
    }
    return indexes;
}

- (NSMutableArray *)comboBoxItems {
    return I_comboBoxItems;
}

- (void)setComboBoxItems:(NSMutableArray *)anArray {
    [I_comboBoxItems autorelease];
    I_comboBoxItems = [anArray mutableCopy];
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
    BOOL isValid = NO;
    int index;
    int count = [I_data count];
    for (index = count - 1; index >= 0; index--) {
        NSDictionary *item = [I_data objectAtIndex:index];
        NSString *status = [item objectForKey:@"status"];
        if ([status isEqualToString:HostEntryStatusResolveFailed] ||
            [status isEqualToString:HostEntryStatusContactFailed] ||
            [status isEqualToString:HostEntryStatusSessionAtEnd] ||
            [status isEqualToString:HostEntryStatusCancelled]) {
            isValid = YES;
            break;
        }
    }
    
    [O_clearButton setEnabled:isValid];
}

#pragma mark -

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
    unsigned int index = [indexes firstIndex];
    while (index != NSNotFound) {
        ItemChildPair pair = [O_browserListView itemChildPairAtRow:index];
        NSMutableDictionary *item = [I_data objectAtIndex:pair.itemIndex];
        if ([item objectForKey:@"failed"]) {
            DEBUGLOG(@"InternetLogDomain", DetailedLogLevel, @"trying to reconnect");
            [item removeObjectForKey:@"BEEPSession"];
            [item removeObjectForKey:@"UserID"];
            [item removeObjectForKey:@"Sessions"];
            [item removeObjectForKey:@"failed"];
            [self connectToURL:[item objectForKey:@"URL"] retry:YES];
        }
        index = [indexes indexGreaterThanIndex:index];
    }
    
    [O_browserListView reloadData];
}

- (void)cancelConnectionsWithIndexes:(NSIndexSet *)indexes {
    DEBUGLOG(@"InternetLogDomain", DetailedLogLevel, @"cancel");
    NSMutableSet *set = [NSMutableSet set];
    BOOL abort = NO;
    unsigned int index = [indexes firstIndex];
    while (index != NSNotFound) {
        ItemChildPair pair = [O_browserListView itemChildPairAtRow:index];
        NSMutableDictionary *item = [I_data objectAtIndex:pair.itemIndex];
        NSString *status = [item objectForKey:@"status"];
        if ([status isEqualToString:HostEntryStatusSessionOpen] || [status isEqualToString:HostEntryStatusSessionInvisible]) {
            TCMBEEPSession *session = [item objectForKey:@"BEEPSession"];
            NSEnumerator *channels = [[session channels] objectEnumerator];
            TCMBEEPChannel *channel;
            while ((channel = [channels nextObject])) {
                if ([[channel profileURI] isEqualToString:@"http://www.codingmonkeys.de/BEEP/SubEthaEditSession"]  && [channel channelStatus] == TCMBEEPChannelStatusOpen) {
                    abort = YES;
                }
            }
        }
        [set addObject:item];
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
        NSEnumerator *enumerator= [set objectEnumerator];
        NSMutableDictionary *item;
        while ((item = [enumerator nextObject])) {
            NSString *status = [item objectForKey:@"status"];
            if ([status isEqualToString:HostEntryStatusResolving]) {
                DEBUGLOG(@"InternetLogDomain", DetailedLogLevel, @"cancel resolve");
                [item removeObjectForKey:@"UserID"];
                [item setObject:[NSNumber numberWithBool:YES] forKey:@"failed"];
                TCMHost *host = [I_resolvingHosts objectForKey:[item objectForKey:@"URLString"]];
                [host cancel];
                [host setDelegate:nil];
                [I_resolvingHosts removeObjectForKey:[item objectForKey:@"URLString"]];
                [item setObject:HostEntryStatusCancelled forKey:@"status"];
                [O_browserListView reloadData];
            } else if ([status isEqualToString:HostEntryStatusContacting]) {
                DEBUGLOG(@"InternetLogDomain", DetailedLogLevel, @"cancel contact");
                [item removeObjectForKey:@"UserID"];
                [item setObject:[NSNumber numberWithBool:YES] forKey:@"failed"];
                [item setObject:HostEntryStatusCancelling forKey:@"status"];
                [O_browserListView reloadData];
                TCMHost *host = [I_resolvedHosts objectForKey:[item objectForKey:@"URLString"]];
                [[TCMMMBEEPSessionManager sharedInstance] cancelConnectToHost:host];
            } else if ([status isEqualToString:HostEntryStatusSessionOpen] || [status isEqualToString:HostEntryStatusSessionInvisible]) {
                TCMBEEPSession *session = [item objectForKey:@"BEEPSession"];
                [item removeObjectForKey:@"UserID"];
                [item setObject:[NSNumber numberWithBool:YES] forKey:@"failed"];
                [item setObject:HostEntryStatusCancelling forKey:@"status"];
                [O_browserListView reloadData];
                [session terminate];            
            }
        }
    }
    
    [O_browserListView reloadData];
}

- (void)joinSessionsWithIndexes:(NSIndexSet *)indexes {
    DEBUGLOG(@"InternetLogDomain", DetailedLogLevel, @"join");
    unsigned int index = [indexes firstIndex];
    while (index != NSNotFound) {
        ItemChildPair pair = [O_browserListView itemChildPairAtRow:index];
        NSMutableDictionary *item = [I_data objectAtIndex:pair.itemIndex];
        if (pair.childIndex != -1) {
            NSArray *sessions = [item objectForKey:@"Sessions"];
            TCMMMSession *session = [sessions objectAtIndex:pair.childIndex];
            TCMBEEPSession *BEEPSession = [item objectForKey:@"BEEPSession"];
            DEBUGLOG(@"InternetLogDomain", DetailedLogLevel, @"join on session: %@, using BEEPSession: %@", session, BEEPSession);
            [session joinUsingBEEPSession:BEEPSession];
        }
        index = [indexes indexGreaterThanIndex:index];
    }
}

- (void)join:(id)sender {
    [self joinSessionsWithIndexes:[O_browserListView selectedRowIndexes]];
}

- (void)reconnect:(id)sender {
    [self reconnectWithIndexes:[O_browserListView selectedRowIndexes]];
}

- (void)cancelConnection:(id)sender {
    [self cancelConnectionsWithIndexes:[O_browserListView selectedRowIndexes]];
}

- (IBAction)actionTriggered:(id)aSender {
    int row = [aSender actionRow];
    DEBUGLOG(@"InternetLogDomain", DetailedLogLevel, @"actionTriggerd in row: %d", row);
    ItemChildPair pair = [aSender itemChildPairAtRow:row];
    if (pair.childIndex != -1) {
        return;
    }
    int index = pair.itemIndex;
    NSMutableDictionary *item = [I_data objectAtIndex:index];
    if ([item objectForKey:@"failed"]) {
        [self reconnectWithIndexes:[NSIndexSet indexSetWithIndex:row]];
    } else {
        [self cancelConnectionsWithIndexes:[NSIndexSet indexSetWithIndex:row]];
    }
    [O_browserListView reloadData];
    [self TCM_validateClearButton];
}

- (IBAction)clear:(id)aSender {
    int index;
    int count = [I_data count];
    for (index = count - 1; index >= 0; index--) {
        NSDictionary *item = [I_data objectAtIndex:index];
        NSString *status = [item objectForKey:@"status"];
        NSString *URLString = [item objectForKey:@"URLString"];
        if ([status isEqualToString:HostEntryStatusResolveFailed] ||
            [status isEqualToString:HostEntryStatusContactFailed] ||
            [status isEqualToString:HostEntryStatusSessionAtEnd] ||
            [status isEqualToString:HostEntryStatusCancelled]) {
            
            if (URLString) {
                [I_resolvingHosts removeObjectForKey:URLString];
                [I_resolvedHosts removeObjectForKey:URLString];
            }
            
            [I_data removeObjectAtIndex:index];   
        }
    }
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

#pragma mark -

- (void)hostDidResolveAddress:(TCMHost *)sender {
    DEBUGLOG(@"InternetLogDomain", SimpleLogLevel, @"hostDidResolveAddress:");
    int index = [self indexOfItemWithURLString:[[sender userInfo] objectForKey:@"URLString"]];
    if (index != -1) {
        [[I_data objectAtIndex:index] setObject:HostEntryStatusContacting forKey:@"status"];
        [O_browserListView reloadData];
    }
    [I_resolvedHosts setObject:sender forKey:[[sender userInfo] objectForKey:@"URLString"]];
    [I_resolvingHosts removeObjectForKey:[[sender userInfo] objectForKey:@"URLString"]];
    [sender setDelegate:nil];
    [[TCMMMBEEPSessionManager sharedInstance] connectToHost:sender];
}

- (void)host:(TCMHost *)sender didNotResolve:(NSError *)error {
    DEBUGLOG(@"InternetLogDomain", SimpleLogLevel, @"host: %@, didNotResolve: %@", sender, error);
    int index = [self indexOfItemWithURLString:[[sender userInfo] objectForKey:@"URLString"]];
    if (index != -1) {
        [[I_data objectAtIndex:index] setObject:HostEntryStatusResolveFailed forKey:@"status"];
        [[I_data objectAtIndex:index] setObject:[NSNumber numberWithBool:YES] forKey:@"failed"];        
        [O_browserListView reloadData];
    }
    [sender setDelegate:nil];
    [I_resolvingHosts removeObjectForKey:[[sender userInfo] objectForKey:@"URLString"]];
    [self TCM_validateClearButton];
}

#pragma mark -

- (void)TCM_didAcceptSession:(NSNotification *)notification {
    DEBUGLOG(@"InternetLogDomain", DetailedLogLevel, @"TCM_didAcceptSession: %@", notification);
    TCMBEEPSession *session = [[notification userInfo] objectForKey:@"Session"];
    NSString *URLString = [[session userInfo] objectForKey:@"URLString"];
    BOOL isRendezvous = [[session userInfo] objectForKey:@"isRendezvous"] != nil;
    if (isRendezvous) {
        return;
    }
    
    int index = [self indexOfItemWithURLString:URLString];
    if (index != -1) {
        NSString *userID = [[session userInfo] objectForKey:@"peerUserID"];
        NSMutableDictionary *item = [I_data objectAtIndex:index];
        [item removeObjectForKey:@"failed"];
        [item setObject:session forKey:@"BEEPSession"];
        [item setObject:userID forKey:@"UserID"];
        [item setObject:HostEntryStatusSessionOpen forKey:@"status"];
        NSDictionary *infoDict = [[TCMMMPresenceManager sharedInstance] statusOfUserID:userID];
        NSMutableArray *array = [[[infoDict objectForKey:@"Sessions"] allValues] mutableCopy];
        [item setObject:array forKey:@"Sessions"];
        [array release];
        [O_browserListView reloadData];
        
        NSEnumerator *enumerator = [[item objectForKey:@"URLRequests"] objectEnumerator];
        NSURL *URL;
        while ((URL = [enumerator nextObject])) {
            if (![I_documentRequestTimer objectForKey:URL]) {
                NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:60.0
                                                                  target:self
                                                                selector:@selector(documentRequestTimerFired:)
                                                                userInfo:[NSDictionary dictionaryWithObjectsAndKeys:URLString, @"URLString", URL, @"URL", nil]
                                                                 repeats:NO];
                [I_documentRequestTimer setObject:timer forKey:URL];
            }
        }
    } else {
        // Inbound session
        NSString *userID = [[session userInfo] objectForKey:@"peerUserID"];
        NSDictionary *infoDict = [[TCMMMPresenceManager sharedInstance] statusOfUserID:userID];
        NSMutableArray *sessions = [[[infoDict objectForKey:@"Sessions"] allValues] mutableCopy];
        NSString *URLString = [[session userInfo] objectForKey:@"URLString"];
        [I_data addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                    userID, @"UserID",
                                                    URLString, @"URLString",
                                                    session, @"BEEPSession",
                                                    [NSNumber numberWithBool:YES], @"inbound",
                                                    sessions, @"Sessions",
                                                    HostEntryStatusSessionOpen, @"status", nil]];
        [sessions release];
    }
    [O_browserListView reloadData];
}

- (void)documentRequestTimerFired:(NSTimer *)aTimer {
    NSDictionary *userInfo = [[aTimer userInfo] retain];
    NSString *URLString = [userInfo objectForKey:@"URLString"];
    NSString *URL = [userInfo objectForKey:@"URL"];
    [aTimer invalidate];
    int index = [self indexOfItemWithURLString:URLString];
    if (index != -1) {
        NSMutableDictionary *item = [I_data objectAtIndex:index];
        NSMutableSet *set = [item objectForKey:@"URLRequests"];
        [set removeObject:URL];
    }
    [I_documentRequestTimer removeObjectForKey:URL];
    [userInfo release];
}

- (void)TCM_sessionDidEnd:(NSNotification *)notification {
    DEBUGLOG(@"InternetLogDomain", DetailedLogLevel, @"TCM_sessionDidEnd: %@", notification);
    TCMBEEPSession *session = [[notification userInfo] objectForKey:@"Session"];
    BOOL isRendezvous = [[session userInfo] objectForKey:@"isRendezvous"] != nil;
    if (isRendezvous) {
        return;
    }
    
    NSString *URLString = [[session userInfo] objectForKey:@"URLString"];
    int index = [self indexOfItemWithURLString:URLString];
    if (index != -1) {
        NSMutableDictionary *item = [I_data objectAtIndex:index];
        NSEnumerator *enumerator = [[item objectForKey:@"URLRequests"] objectEnumerator];
        NSURL *URL;
        while ((URL = [enumerator nextObject])) {
            NSTimer *timer = [I_documentRequestTimer objectForKey:URL];
            if (timer) {
                [timer invalidate];
                [I_documentRequestTimer removeObjectForKey:URL];
            }        
        }
        
        //NSMutableDictionary *item = [I_data objectAtIndex:index];
        if ([item objectForKey:@"inbound"]) {
            [I_data removeObjectAtIndex:index];
        } else {
            if ([[item objectForKey:@"status"] isEqualToString:HostEntryStatusCancelling]) {
                [item setObject:HostEntryStatusCancelled forKey:@"status"];
            } else {
                [item setObject:HostEntryStatusSessionAtEnd forKey:@"status"];
            }
            [item setObject:[NSNumber numberWithBool:YES] forKey:@"failed"];        
            [item removeObjectForKey:@"BEEPSession"];
            [item removeObjectForKey:@"Sessions"];
            [item removeObjectForKey:@"UserID"];
        }
        [O_browserListView reloadData];
    }
    [self TCM_validateClearButton];
}

- (void)TCM_connectToHostDidFail:(NSNotification *)notification {
    DEBUGLOG(@"InternetLogDomain", DetailedLogLevel, @"TCM_connectToHostDidFail: %@", notification);
    
    TCMHost *host = [[notification userInfo] objectForKey:@"host"];
    if (host) {
        [I_resolvedHosts removeObjectForKey:[[host userInfo] objectForKey:@"URLString"]];
        int index = [self indexOfItemWithURLString:[[host userInfo] objectForKey:@"URLString"]];
        if (index != -1) {
            [[I_data objectAtIndex:index] setObject:HostEntryStatusContactFailed forKey:@"status"];
            [[I_data objectAtIndex:index] setObject:[NSNumber numberWithBool:YES] forKey:@"failed"];        
            [O_browserListView reloadData];
        }
    }
    [self TCM_validateClearButton];
}

- (void)TCM_connectToHostCancelled:(NSNotification *)notification {
    DEBUGLOG(@"InternetLogDomain", DetailedLogLevel, @"TCM_connectToHostCancelled: %@", notification);
    
    TCMHost *host = [[notification userInfo] objectForKey:@"host"];
    if (host) {
        [I_resolvedHosts removeObjectForKey:[[host userInfo] objectForKey:@"URLString"]];
        int index = [self indexOfItemWithURLString:[[host userInfo] objectForKey:@"URLString"]];
        if (index != -1) {
            [[I_data objectAtIndex:index] setObject:HostEntryStatusCancelled forKey:@"status"];
            [[I_data objectAtIndex:index] setObject:[NSNumber numberWithBool:YES] forKey:@"failed"];        
            [O_browserListView reloadData];
        }
    }
    [self TCM_validateClearButton];
}

#pragma mark -

- (void)userDidChange:(NSNotification *)aNotification {
    DEBUGLOG(@"InternetLogDomain", AllLogLevel, @"userDidChange: %@", aNotification);
    if ([[[aNotification userInfo] objectForKey:@"User"] isMe]) {
        [self TCM_synchronizeMyNameAndPicture];
    } else {
        [O_browserListView reloadData];
    }
}

- (void)announcedSessionsDidChange:(NSNotification *)aNotification {
    [self TCM_validateStatusPopUpButton];
}

#pragma mark -

- (void)userDidChangeVisibility:(NSNotification *)aNotification {
    DEBUGLOG(@"InternetLogDomain", AllLogLevel, @"userDidChangeVisibility: %@", aNotification);
    NSDictionary *userInfo = [aNotification userInfo];
    NSString *userID = [userInfo objectForKey:@"UserID"];
    BOOL isVisible = [[userInfo objectForKey:@"isVisible"] boolValue];
    
    //if (!isVisible) {
        NSIndexSet *indexes = [self indexesOfItemsWithUserID:userID];
        unsigned int index = [indexes firstIndex];
        while (index != NSNotFound) {
            //[I_data removeObjectAtIndex:index];
            NSMutableDictionary *item = [I_data objectAtIndex:index];
            if (isVisible) {
                [item setObject:HostEntryStatusSessionOpen forKey:@"status"];
            } else {
                [item setObject:HostEntryStatusSessionInvisible forKey:@"status"];
            }
            index = [indexes indexGreaterThanIndex:index];           
        }
    //}
    [O_browserListView reloadData];
}

- (void)userDidChangeAnnouncedDocuments:(NSNotification *)aNotification {
    DEBUGLOG(@"InternetLogDomain", AllLogLevel, @"userDidChangeAnnouncedDocuments: %@", aNotification);
    NSDictionary *userInfo = [aNotification userInfo];
    NSString * userID = [userInfo objectForKey:@"UserID"];
    NSIndexSet *indexes = [self indexesOfItemsWithUserID:userID];
    unsigned int index = [indexes firstIndex];
    while (index != NSNotFound) {
        NSMutableDictionary *item = [I_data objectAtIndex:index];
        TCMMMSession *session = [userInfo objectForKey:@"AnnouncedSession"];
        NSMutableArray *sessions = [item objectForKey:@"Sessions"];
        if ([[userInfo objectForKey:@"Sessions"] count] == 0) {
            [sessions removeAllObjects];
        } else {
            if (session) {
                NSString *sessionID = [session sessionID];
                int i;
                for (i = 0; i < [sessions count]; i++) {
                    if ([sessionID isEqualToString:[[sessions objectAtIndex:i] sessionID]]) {
                        break;
                    }
                }
                if (i == [sessions count]) {
                    [sessions addObject:session];
                }
                
                NSMutableSet *requests = [item objectForKey:@"URLRequests"];
                NSEnumerator *enumerator = [requests objectEnumerator];
                NSURL *URL;
                while ((URL = [enumerator nextObject])) {
                    NSTimer *timer = [I_documentRequestTimer objectForKey:URL];
                    if (timer) {
                        if ([session isAddressedByURL:URL]) {
                            [timer invalidate];
                            [I_documentRequestTimer removeObjectForKey:URL];
                            TCMBEEPSession *BEEPSession = [item objectForKey:@"BEEPSession"];
                            [session joinUsingBEEPSession:BEEPSession];
                            [requests removeObject:URL];
                            break;
                        }
                    }
                }
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
        index = [indexes indexGreaterThanIndex:index];
    }
        
    [O_browserListView reloadData];
}

#pragma mark -

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

- (id)listView:(TCMListView *)aListView objectValueForTag:(int)aTag atChildIndex:(int)aChildIndex ofItemAtIndex:(int)anItemIndex {
    static NSImage *defaultPerson = nil;
    if (!defaultPerson) {
        defaultPerson = [[[NSImage imageNamed:@"DefaultPerson"] resizedImageWithSize:NSMakeSize(32.0, 32.0)] retain];
    }
    
    if (aChildIndex == -1) {
        if (anItemIndex >= 0 && anItemIndex < [I_data count]) {
            NSMutableDictionary *item = [I_data objectAtIndex:anItemIndex];
            TCMMMUser *user = [[TCMMMUserManager sharedInstance] userForUserID:[item objectForKey:@"UserID"]];
            
            BOOL isVisible = NO;
            if (user) {
                NSDictionary *userStatus = [[TCMMMPresenceManager sharedInstance] statusOfUserID:[user userID]];
                isVisible = [userStatus objectForKey:@"isVisible"] == nil ? NO : YES;
            }
    
            if (user && isVisible && ![[item objectForKey:@"status"] isEqualToString:HostEntryStatusSessionAtEnd]) {
                if (aTag == TCMMMBrowserItemNameTag) {
                    return [user name];
                } else if (aTag == TCMMMBrowserItemStatusTag) {
                    return [NSString stringWithFormat:NSLocalizedString(@"%d Document(s)",@"Status string showing the number of documents in Rendezvous and Internet browser"), [[item objectForKey:@"Sessions"] count]];
                } else if (aTag == TCMMMBrowserItemImageTag) {
                    return [[user properties] objectForKey:@"Image32"];
                } else if (aTag == TCMMMBrowserItemImageNextToNameTag) {
                    return [[user properties] objectForKey:@"ColorImage"];
                }
            } else {
                if (aTag == TCMMMBrowserItemNameTag) {
                    return [item objectForKey:@"URLString"];
                } else if (aTag == TCMMMBrowserItemStatusTag) {
                    // (void)NSLocalizedString(@"HostEntryStatusResolving", @"Resolving");
                    // (void)NSLocalizedString(@"HostEntryStatusResolveFailed", @"Could not resolve");
                    // (void)NSLocalizedString(@"HostEntryStatusContacting", @"Contacting");
                    // (void)NSLocalizedString(@"HostEntryStatusContactFailed", @"Could not contact");
                    // (void)NSLocalizedString(@"HostEntryStatusSessionOpen", @"Connected");
                    // (void)NSLocalizedString(@"HostEntryStatusSessionInvisible", @"Invisible");
                    // (void)NSLocalizedString(@"HostEntryStatusSessionAtEnd", @"Connection Lost");
                    // (void)NSLocalizedString(@"HostEntryStatusCancelling", @"Cancelling");
                    // (void)NSLocalizedString(@"HostEntryStatusCancelled", @"Cancelled");
                    return NSLocalizedString([item objectForKey:@"status"], @"<do not localize>");
                } else if (aTag == TCMMMBrowserItemImageTag) {
                    return defaultPerson;
                }
            }
            
            if (aTag == TCMMMBrowserItemActionImageTag) {
                if ([[item objectForKey:@"status"] isEqualToString:HostEntryStatusCancelling]) {
                    return nil;
                }
                
                if ([item objectForKey:@"failed"]) {
                    if ([item objectForKey:@"inbound"]) {
                        return nil;
                    } else {
                        return [NSImage imageNamed:@"InternetResume"];
                    }
                } else {
                    return [NSImage imageNamed:@"InternetStop"];
                }
            }
        }
        return nil;
    } else {
        static NSImage *statusLock = nil;
        static NSImage *statusReadOnly = nil;
        static NSImage *statusReadWrite = nil;
        static NSMutableDictionary *icons = nil;
        
        if (!icons) {
            icons = [NSMutableDictionary new];
            statusLock = [[NSImage imageNamed:@"StatusLock"] retain];
            statusReadOnly = [[NSImage imageNamed:@"StatusReadOnly"] retain];
            statusReadWrite = [[NSImage imageNamed:@"StatusReadWrite"] retain];
        }
        
        if (anItemIndex >= 0 && anItemIndex < [I_data count]) {
            NSDictionary *item = [I_data objectAtIndex:anItemIndex];
            NSArray *sessions = [item objectForKey:@"Sessions"];
            if (aChildIndex >= 0 && aChildIndex < [sessions count]) {
                TCMMMSession *session = [sessions objectAtIndex:aChildIndex];
                if (aTag == TCMMMBrowserChildNameTag) {
                    return [session filename];
                } else if (aTag==TCMMMBrowserChildClientStatusTag) {
                    return [NSNumber numberWithInt:[session clientState]];
                }else if (aTag == TCMMMBrowserChildIconImageTag) {
                    NSString *extension = [[session filename] pathExtension];
                    NSImage *icon = [icons objectForKey:extension];
                    if (!icon) {
                        icon = [[[NSWorkspace sharedWorkspace] iconForFileType:extension] copy];
                        [icon setSize:NSMakeSize(16, 16)];
                        [icons setObject:[icon autorelease] forKey:extension];
                    }
                    return icon;
                } else if (aTag == TCMMMBrowserChildStatusImageTag) {
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
    
    if (anIndex != -1) 
        return nil;
   
    if (anItemIndex >= 0 && anItemIndex < [I_data count]) {
        NSMutableDictionary *item = [I_data objectAtIndex:anItemIndex];
        TCMBEEPSession *BEEPSession = [item objectForKey:@"BEEPSession"];
        NSString *addressDataString = nil;
        if (BEEPSession) {
            addressDataString = [NSString stringWithAddressData:[BEEPSession peerAddressData]];
        }
        if ([item objectForKey:@"inbound"]) {
            if (addressDataString) {
                return [NSString stringWithFormat:NSLocalizedString(@"Inbound Connection from %@", @"Inbound Connection ToolTip With Address"), addressDataString];
            } else {
                return NSLocalizedString(@"Inbound Connection", @"Inbound Connection ToolTip");
            }
        }
        
        if (![item objectForKey:@"failed"]) {
            return [item objectForKey:@"URLString"];
        }
    }
    
    return nil;
}

- (BOOL)listView:(TCMListView *)listView writeRows:(NSIndexSet *)indexes toPasteboard:(NSPasteboard *)pboard {
    BOOL allowDrag = YES;
    NSMutableArray *plist = [NSMutableArray array];
    NSMutableString *vcfString= [NSMutableString string];
    TCMMMUserManager *userManager = [TCMMMUserManager sharedInstance];
    unsigned int index = [indexes firstIndex];
    while (index != NSNotFound) {
        ItemChildPair pair = [listView itemChildPairAtRow:index];
        NSMutableDictionary *item = [I_data objectAtIndex:pair.itemIndex];
        if (![[item objectForKey:@"status"] isEqualToString:HostEntryStatusSessionOpen]) {
            allowDrag = NO;
            break;        
        }
        NSMutableDictionary *entry = [NSMutableDictionary new];
        [entry setObject:[item objectForKey:@"UserID"] forKey:@"UserID"];
        if ([item objectForKey:@"URLString"]) {
            [entry setObject:[item objectForKey:@"URLString"] forKey:@"URLString"];
        }
        NSString *vcf = [[userManager userForUserID:[item objectForKey:@"UserID"]] vcfRepresentation];
        if (vcf) {
            [vcfString appendString:vcf];
        }
        [plist addObject:entry];
        [entry release];
        if (pair.childIndex != -1) {
            allowDrag = NO;
            break;
        }
        index = [indexes indexGreaterThanIndex:index];
    }
    
    if (allowDrag) {
        [pboard declareTypes:[NSArray arrayWithObjects:@"PboardTypeTBD", NSVCardPboardType, nil] owner:nil];
        [pboard setPropertyList:plist forType:@"PboardTypeTBD"];
        [pboard setData:[vcfString dataUsingEncoding:NSUnicodeStringEncoding] forType:NSVCardPboardType];
    }
    
    return allowDrag;
}

#pragma mark -

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

