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
#import "PullDownButtonCell.h"


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


@interface InternetBrowserController (InternetBrowserControllerPrivateAdditions)

- (int)indexOfItemWithURLString:(NSString *)URLString;
- (int)indexOfItemWithUserID:(NSString *)userID;
- (NSMutableIndexSet *)indexesOfItemsWithUserID:(NSString *)userID;
- (void)connectToURL:(NSURL *)url retry:(BOOL)isRetrying;
- (void)processDocumentURL:(NSURL *)url;
- (void)TCM_validateStatusPopUpButton;

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
    [super dealloc];
}

- (void)awakeFromNib {
    sharedInstance = self;
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
    
    [O_actionPullDownButton setCell:[[ImagePopUpButtonCell new] autorelease]];
    [[O_actionPullDownButton cell] setPullsDown:YES];
    [[O_actionPullDownButton cell] setImage:[NSImage imageNamed:@"Action"]];
    [[O_actionPullDownButton cell] setAlternateImage:[NSImage imageNamed:@"ActionPressed"]];
    [[O_actionPullDownButton cell] setUsesItemFromMenu:NO];
    [O_actionPullDownButton addItemsWithTitles:[NSArray arrayWithObjects:@"<do not modify>", @"Ich", @"bin", @"das", @"Action", @"Menü", nil]];

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

- (void)windowWillClose:(NSNotification *)aNotification {
    DEBUGLOG(@"InternetLogDomain", DetailedLogLevel, @"InternetBrowser willClose");
    [[NSUserDefaults standardUserDefaults] setObject:[self comboBoxItems] forKey:AddressHistory];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)menuNeedsUpdate:(NSMenu *)aMenu {
    BOOL isVisible = [[TCMMMPresenceManager sharedInstance] isVisible];
    [[aMenu itemWithTag:10] setState:isVisible ? NSOnState : NSOffState];
    [[aMenu itemWithTag:11] setState:(!isVisible) ? NSOnState : NSOffState];
    [[aMenu itemWithTag:12] setState:[[TCMMMBEEPSessionManager sharedInstance] isProhibitingInboundInternetSessions] ? NSOnState : NSOffState];
}

- (void)connectToAddress:(NSString *)address {
    DEBUGLOG(@"InternetLogDomain", DetailedLogLevel, @"connect to address: %@", address);
    
    [self showWindow:nil];
        
    NSString *unescapedAddress = (NSString *)CFURLCreateStringByReplacingPercentEscapes(kCFAllocatorDefault, (CFStringRef)address, CFSTR(""));
    DEBUGLOG(@"InternetLogDomain", DetailedLogLevel, @"unescapedAddress: %@", unescapedAddress);
    
    NSString *escapedAddress = nil;
    if (unescapedAddress != nil) {
        [unescapedAddress autorelease];
        escapedAddress = (NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)unescapedAddress, NULL, NULL, CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
        [escapedAddress autorelease];
    } else {
        escapedAddress = address;
    }
    DEBUGLOG(@"InternetLogDomain", DetailedLogLevel, @"escapedAddress: %@", escapedAddress);
    
    NSURL *url;
    NSString *schemePrefix = [NSString stringWithFormat:@"%@://", @"see"];
    NSString *lowercaseEscapedAddress = [escapedAddress lowercaseString];
    if (![lowercaseEscapedAddress hasPrefix:schemePrefix]) {
        NSString *escapedAddressWithPrefix = [schemePrefix stringByAppendingString:escapedAddress];
        url = [NSURL URLWithString:escapedAddressWithPrefix];
    } else {
        url = [NSURL URLWithString:escapedAddress];
    }
    
    DEBUGLOG(@"InternetLogDomain", DetailedLogLevel, @"scheme: %@\nhost: %@\nport: %@\npath: %@\nparameterString: %@\nquery: %@", [url scheme], [url host],  [url port], [url path], [url parameterString], [url query]);
    
    if (url != nil && [url host] != nil) {
        [I_comboBoxItems removeObject:[url absoluteString]];
        [I_comboBoxItems insertObject:[url absoluteString] atIndex:0];
        if ([I_comboBoxItems count] >= kMaxNumberOfItems) {
            [I_comboBoxItems removeLastObject];
        }
        [O_addressComboBox noteNumberOfItemsChanged];
        [O_addressComboBox reloadData];
        
        [self connectToURL:url retry:NO];
    } else {
        NSLog(@"Entered invalid URI");
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
            port = [[NSUserDefaults standardUserDefaults] integerForKey:DefaultPortNumber];
        }
        
        NSString *URLString = [NSString stringWithFormat:@"%@://%@:%d", [url scheme], [url host], port];

        // when I_data entry with URL exists, select entry
        int index = [self indexOfItemWithURLString:URLString];
        if (index != -1) {
            if (!isRetrying) {
                int row = [O_browserListView rowForItem:index child:-1];
                [O_browserListView selectRow:row byExtendingSelection:NO];
            } else {
                [I_resolvingHosts removeObjectForKey:URLString];
                [I_resolvedHosts removeObjectForKey:URLString];
                
                TCMHost *host = [TCMHost hostWithName:[url host] port:port userInfo:[NSDictionary dictionaryWithObject:URLString forKey:@"URLString"]];
                [I_resolvingHosts setObject:host forKey:URLString];
                NSMutableDictionary *item = [I_data objectAtIndex:index];
                [item setObject:HostEntryStatusResolving forKey:@"status"];
                [item setObject:URLString forKey:@"URLString"];
                [host setDelegate:self];
                [host resolve];
            }
        } else {
            // otherwise add new entry to I_data
            TCMHost *host = [TCMHost hostWithName:[url host] port:port userInfo:[NSDictionary dictionaryWithObject:URLString forKey:@"URLString"]];
            [I_resolvingHosts setObject:host forKey:URLString];
            [I_data addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                        URLString, @"URLString",
                                                        HostEntryStatusResolving, @"status",
                                                        url, @"URL", nil]];
            [host setDelegate:self];
            [host resolve];
        }
    } else {
        NSLog(@"Invalid URI");
    }
    
    [O_browserListView reloadData];
}

- (IBAction)connect:(id)aSender {
    DEBUGLOG(@"InternetLogDomain", SimpleLogLevel, @"connect action triggered");
    NSString *address = [aSender objectValue];
    [self connectToAddress:address];
}

- (IBAction)setVisibilityByMenuItem:(id)aSender {
    [[TCMMMPresenceManager sharedInstance] setVisible:([aSender tag] == 10)];
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

- (void)alertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    DEBUGLOG(@"InternetLogDomain", SimpleLogLevel, @"alertDidEnd:");
    
    NSDictionary *alertContext = (NSDictionary *)contextInfo;
    if (returnCode == NSAlertSecondButtonReturn) {
        DEBUGLOG(@"InternetLogDomain", SimpleLogLevel, @"abort connection");
        NSMutableDictionary *item = [alertContext objectForKey:@"item"];
        [item removeObjectForKey:@"UserID"];
        [item setObject:[NSNumber numberWithBool:YES] forKey:@"failed"];
        [item setObject:HostEntryStatusCancelling forKey:@"status"];
        [O_browserListView reloadData];
        TCMBEEPSession *session = [alertContext objectForKey:@"session"];
        [session terminate];
        [O_browserListView reloadData];
    }
    
    [alertContext autorelease];
}

- (IBAction)joinSession:(id)aSender {
    int row = [aSender clickedRow];
    DEBUGLOG(@"InternetLogDomain", DetailedLogLevel, @"joinSession in row: %d", row);
    
    ItemChildPair pair = [aSender itemChildPairAtRow:row];
    if (pair.childIndex != -1) {
        NSDictionary *userDict = [I_data objectAtIndex:pair.itemIndex];
        NSArray *sessions = [userDict objectForKey:@"Sessions"];
        TCMMMSession *session = [sessions objectAtIndex:pair.childIndex];
        TCMBEEPSession *BEEPSession = [userDict objectForKey:@"BEEPSession"];
        DEBUGLOG(@"InternetLogDomain", DetailedLogLevel, @"join on session: %@, using BEEPSession: %@", session, BEEPSession);
        [session joinUsingBEEPSession:BEEPSession];
    }
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
        DEBUGLOG(@"InternetLogDomain", DetailedLogLevel, @"trying to reconnect");
        [item removeObjectForKey:@"BEEPSession"];
        [item removeObjectForKey:@"UserID"];
        [item removeObjectForKey:@"Sessions"];
        [item removeObjectForKey:@"failed"];
        [self connectToURL:[item objectForKey:@"URL"] retry:YES];
    } else {
        DEBUGLOG(@"InternetLogDomain", DetailedLogLevel, @"cancel");
        if ([[item objectForKey:@"status"] isEqualToString:HostEntryStatusResolving]) {
            DEBUGLOG(@"InternetLogDomain", DetailedLogLevel, @"cancel resolve");
            [item removeObjectForKey:@"UserID"];
            [item setObject:[NSNumber numberWithBool:YES] forKey:@"failed"];
            TCMHost *host = [I_resolvingHosts objectForKey:[item objectForKey:@"URLString"]];
            [host cancel];
            [host setDelegate:nil];
            [I_resolvingHosts removeObjectForKey:[item objectForKey:@"URLString"]];
            [item setObject:HostEntryStatusCancelled forKey:@"status"];
            [O_browserListView reloadData];
        } else if ([[item objectForKey:@"status"] isEqualToString:HostEntryStatusContacting]) {
            DEBUGLOG(@"InternetLogDomain", DetailedLogLevel, @"cancel contact");
            [item removeObjectForKey:@"UserID"];
            [item setObject:[NSNumber numberWithBool:YES] forKey:@"failed"];
            [item setObject:HostEntryStatusCancelling forKey:@"status"];
            [O_browserListView reloadData];
            TCMHost *host = [I_resolvedHosts objectForKey:[item objectForKey:@"URLString"]];
            [[TCMMMBEEPSessionManager sharedInstance] cancelConnectToHost:host];
        } else if ([[item objectForKey:@"status"] isEqualToString:HostEntryStatusSessionOpen]) {
            DEBUGLOG(@"InternetLogDomain", DetailedLogLevel, @"cancel open session");
            TCMBEEPSession *session = [item objectForKey:@"BEEPSession"];
            BOOL abort = NO;
            NSEnumerator *channels = [[session channels] objectEnumerator];
            TCMBEEPChannel *channel;
            while ((channel = [channels nextObject])) {
                if ([[channel profileURI] isEqualToString:@"http://www.codingmonkeys.de/BEEP/SubEthaEditSession"]  && [channel channelStatus] == TCMBEEPChannelStatusOpen) {
                    abort = YES;
                    break;
                }
            }
            if (abort) {
                NSAlert *alert = [[[NSAlert alloc] init] autorelease];
                [alert setAlertStyle:NSWarningAlertStyle];
                [alert setMessageText:NSLocalizedString(@"OpenChannels", nil)];
                [alert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"AbortChannels", nil)]];
                [alert addButtonWithTitle:NSLocalizedString(@"Keep Connection", nil)];
                [alert addButtonWithTitle:NSLocalizedString(@"Abort", nil)];
                [[[alert buttons] objectAtIndex:0] setKeyEquivalent:@"\r"];
                [alert beginSheetModalForWindow:[self window]
                                  modalDelegate:self 
                                 didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
                                    contextInfo:[[NSDictionary dictionaryWithObjectsAndKeys:
                                                            item, @"item",
                                                            session, @"session",
                                                            nil] retain]]; 

            } else {
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

- (NSMutableIndexSet *)indexesOfItemsWithUserID:(NSString *)userID {
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

- (void)processDocumentURL:(NSURL *)url {
    NSString *urlPath = [url path];
    NSString *path = nil;
    if (urlPath != nil) {
        path = (NSString *)CFURLCreateStringByReplacingPercentEscapes(kCFAllocatorDefault, (CFStringRef)urlPath, CFSTR(""));
        [path autorelease];
    }
    DEBUGLOG(@"InternetLogDomain", DetailedLogLevel, @"path: %@", path);

    if (path != nil && [path length] != 0) {
        NSString *lastPathComponent = [path lastPathComponent];
        DEBUGLOG(@"InternetLogDomain", DetailedLogLevel, @"join: %@", lastPathComponent);
        
        UInt16 port;
        if ([url port] != nil) {
            port = [[url port] unsignedShortValue];
        } else {
            port = [[NSUserDefaults standardUserDefaults] integerForKey:DefaultPortNumber];
        }
        NSString *URLString = [NSString stringWithFormat:@"%@://%@:%d", [url scheme], [url host], port];

        int index = [self indexOfItemWithURLString:URLString];
        if (index != -1) {
            NSDictionary *item = [I_data objectAtIndex:index];
            TCMBEEPSession *BEEPSession = [item objectForKey:@"BEEPSession"];
            NSArray *sessions = [item objectForKey:@"Sessions"];
            NSEnumerator *enumerator = [sessions objectEnumerator];
            TCMMMSession *session;
            BOOL found = NO;
            while ((session = [enumerator nextObject])) {
                if ([lastPathComponent isEqualToString:[session sessionID]]) {
                    found = YES;
                    break;
                }
            }
            if (found) {
                DEBUGLOG(@"InternetLogDomain", DetailedLogLevel, @"found id");
                [session joinUsingBEEPSession:BEEPSession];
            } else {
                NSString *urlQuery = [url query];
                NSString *query;
                NSString *documentId = nil;
                if (urlQuery != nil) {
                    query = (NSString *)CFURLCreateStringByReplacingPercentEscapes(kCFAllocatorDefault, (CFStringRef)urlQuery, CFSTR(""));
                    [query autorelease];
                    NSArray *components = [query componentsSeparatedByString:@"&"];
                    NSEnumerator *enumerator = [components objectEnumerator];
                    NSString *item;
                    while ((item = [enumerator nextObject])) {
                        NSArray *keyValue = [item componentsSeparatedByString:@"="];
                        if ([keyValue count] == 2) {
                            if ([[keyValue objectAtIndex:0] isEqualToString:@"sessionID"]) {
                                documentId = [keyValue objectAtIndex:1];
                            }
                            break;
                        }
                    }
                }
                
                enumerator = [sessions objectEnumerator];
                found = NO;
                while ((session = [enumerator nextObject])) {
                    if ([documentId isEqualToString:[session sessionID]]) {
                        found = YES;
                        break;
                    }
                }
                if (found) {
                    DEBUGLOG(@"InternetLogDomain", DetailedLogLevel, @"found id in query");
                    [session joinUsingBEEPSession:BEEPSession];
                } else {
                    enumerator = [sessions objectEnumerator];
                    while ((session = [enumerator nextObject])) {
                        if ([lastPathComponent compare:[[session filename] lastPathComponent]] == NSOrderedSame) {
                            DEBUGLOG(@"InternetLogDomain", DetailedLogLevel, @"found title");
                            [session joinUsingBEEPSession:BEEPSession];
                        }
                    }                
                }
            }
        }
    }
}

- (void)TCM_validateStatusPopUpButton {
    TCMMMPresenceManager *pm = [TCMMMPresenceManager sharedInstance];
    BOOL isVisible = [pm isVisible];
    int announcedCount = [[pm announcedSessions] count];
    NSString *statusString = @"";
    if (announcedCount > 0) {
        statusString = [NSString stringWithFormat:NSLocalizedString(@"%d Document(s)", "Status string in visibility pull down in Rendezvous and Internet browser"), announcedCount];
    } else if (isVisible) {
        statusString = NSLocalizedString(@"Visible", @"Status string in vibilitypulldown in Browsers for visible");
    } else {
        statusString = NSLocalizedString(@"Invisible", @"Status string in vibilitypulldown in Browsers for invisible");
    }
    [[[O_statusPopUpButton menu] itemAtIndex:0] setTitle:statusString];
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
}

#pragma mark -

- (void)TCM_didAcceptSession:(NSNotification *)notification {
    DEBUGLOG(@"InternetLogDomain", DetailedLogLevel, @"TCM_didAcceptSession: %@", notification);
    TCMBEEPSession *session = [[notification userInfo] objectForKey:@"Session"];
    NSString *URLString = [[session userInfo] objectForKey:@"URLString"];
    BOOL isRendezvous = [[session userInfo] objectForKey:@"isRendezvous"] != nil ? YES : NO;
    if (isRendezvous) {
        return;
    }
    
    int index = [self indexOfItemWithURLString:URLString];
    if (index != -1) {
        NSString *userID = [[session userInfo] objectForKey:@"peerUserID"];
        NSMutableDictionary *item = [I_data objectAtIndex:index];
        [item removeObjectForKey:@"failed"];
        [item setObject:session forKey:@"BEEPSession"];
        [item setObject:HostEntryStatusSessionOpen forKey:@"status"];
        [item setObject:userID forKey:@"UserID"];
        NSDictionary *infoDict = [[TCMMMPresenceManager sharedInstance] statusOfUserID:userID];
        NSMutableArray *array = [[[infoDict objectForKey:@"Sessions"] allValues] mutableCopy];
        [item setObject:array forKey:@"Sessions"];
        [array release];
//        [item setObject:[NSNumber numberWithBool:YES] forKey:@"isExpanded"];
        [O_browserListView reloadData];
        [self processDocumentURL:[item objectForKey:@"URL"]];
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
    }
    [O_browserListView reloadData];
}

- (void)TCM_sessionDidEnd:(NSNotification *)notification {
    DEBUGLOG(@"InternetLogDomain", DetailedLogLevel, @"TCM_sessionDidEnd: %@", notification);
    TCMBEEPSession *session = [[notification userInfo] objectForKey:@"Session"];
    NSString *URLString = [[session userInfo] objectForKey:@"URLString"];
    int index = [self indexOfItemWithURLString:URLString];
    if (index != -1) {
        NSMutableDictionary *item = [I_data objectAtIndex:index];
        if ([[item objectForKey:@"status"] isEqualToString:HostEntryStatusCancelling]) {
            [item setObject:HostEntryStatusCancelled forKey:@"status"];
        } else {
            [item setObject:HostEntryStatusSessionAtEnd forKey:@"status"];
        }
        [item setObject:[NSNumber numberWithBool:YES] forKey:@"failed"];        
        [item removeObjectForKey:@"BEEPSession"];
        [item removeObjectForKey:@"Sessions"];
        [O_browserListView reloadData];
    }
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
        NSMutableIndexSet *indexes = [self indexesOfItemsWithUserID:userID];
        int index;
        while ((index = [indexes firstIndex]) != NSNotFound) {
            [indexes removeIndex:[indexes firstIndex]];
            if (index >= 0) {
                //[I_data removeObjectAtIndex:index];
                NSMutableDictionary *item = [I_data objectAtIndex:index];
                if (isVisible) {
                    [item setObject:HostEntryStatusSessionOpen forKey:@"status"];
                } else {
                    [item setObject:HostEntryStatusSessionInvisible forKey:@"status"];
                }
            }            
        }
    //}
    [O_browserListView reloadData];
}

- (void)userDidChangeAnnouncedDocuments:(NSNotification *)aNotification {
    DEBUGLOG(@"InternetLogDomain", AllLogLevel, @"userDidChangeAnnouncedDocuments: %@", aNotification);
    NSDictionary *userInfo = [aNotification userInfo];
    NSString * userID = [userInfo objectForKey:@"UserID"];
    NSMutableIndexSet *indexes = [self indexesOfItemsWithUserID:userID];
    int index;
    while ((index = [indexes firstIndex]) != NSNotFound) {
        [indexes removeIndex:[indexes firstIndex]];
        if (index >= 0) {
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
    }
        
    [O_browserListView reloadData];
}

#pragma mark -

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
                    return [NSString stringWithFormat:@"%d Document(s)", [[item objectForKey:@"Sessions"] count]];
                } else if (aTag == TCMMMBrowserItemImageTag) {
                    return [[user properties] objectForKey:@"Image32"];
                } else if (aTag == TCMMMBrowserItemImageNextToNameTag) {
                    return [[user properties] objectForKey:@"ColorImage"];
                }
            } else {
                if (aTag == TCMMMBrowserItemNameTag) {
                    return [item objectForKey:@"URLString"];
                } else if (aTag == TCMMMBrowserItemStatusTag) {
                    return NSLocalizedString([item objectForKey:@"status"], @"Status message displayed for each host entry in Internet browser.");
                } else if (aTag == TCMMMBrowserItemImageTag) {
                    return [NSImage imageNamed:@"DefaultPerson"];
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
                } else if (aTag == TCMMMBrowserChildIconImageTag) {
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
        if ([item objectForKey:@"inbound"]) {
            return NSLocalizedString(@"Inbound Connection", @"Inbound Connection ToolTip");
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
    NSMutableIndexSet *set = [indexes mutableCopy];
    unsigned int index;
    while ((index = [set firstIndex]) != NSNotFound) {
        ItemChildPair pair = [listView itemChildPairAtRow:index];
        NSMutableDictionary *item = [I_data objectAtIndex:pair.itemIndex];
        NSMutableDictionary *entry = [NSMutableDictionary new];
        [entry setObject:[item objectForKey:@"UserID"] forKey:@"UserID"];
        if ([item objectForKey:@"URLString"]) {
            [entry setObject:[item objectForKey:@"URLString"] forKey:@"URLString"];
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
        [pboard declareTypes:[NSArray arrayWithObject:@"PboardTypeTBD"] owner:nil];
        [pboard setPropertyList:plist forType:@"PboardTypeTBD"];
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

