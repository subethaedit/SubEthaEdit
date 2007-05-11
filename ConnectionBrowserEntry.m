//
//  ConnectionBrowserEntry.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 08.05.07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import "ConnectionBrowserEntry.h"
#import "AppController.h"
#import "TCMMMUserManager.h"
#import "TCMMMUserSEEAdditions.h"
#import "TCMMMBrowserListView.h"
#import "TCMHost.h"
#import "NSWorkspaceTCMAdditions.h"
#import <netdb.h>       // getaddrinfo, struct addrinfo, AI_NUMERICHOST

static NSString * const HostEntryStatusResolving = @"HostEntryStatusResolving";
static NSString * const HostEntryStatusResolveFailed = @"HostEntryStatusResolveFailed";
static NSString * const HostEntryStatusContacting = @"HostEntryStatusContacting";
static NSString * const HostEntryStatusContactFailed = @"HostEntryStatusContactFailed";
static NSString * const HostEntryStatusSessionOpen = @"HostEntryStatusSessionOpen";
static NSString * const HostEntryStatusSessionInvisible = @"HostEntryStatusSessionInvisible";
static NSString * const HostEntryStatusSessionAtEnd = @"HostEntryStatusSessionAtEnd";
static NSString * const HostEntryStatusCancelling = @"HostEntryStatusCancelling";
static NSString * const HostEntryStatusCancelled = @"HostEntryStatusCancelled";

NSString * const ConnectionStatusConnected    = @"ConnectionStatusConnected";
NSString * const ConnectionStatusInProgress   = @"ConnectionStatusInProgress";
NSString * const ConnectionStatusNoConnection = @"ConnectionStatusNoConnection";

NSString * const ConnectionBrowserEntryStatusDidChangeNotification = @"ConnectionBrowserEntryStatusDidChangeNotification";

@implementation ConnectionBrowserEntry

+ (NSURL *)urlForAddress:(NSString *)anAddress {
    NSString *URLString = nil;
    NSString *schemePrefix = [NSString stringWithFormat:@"%@://", @"see"];
    NSString *lowercaseAddress = [anAddress lowercaseString];
    if (![lowercaseAddress hasPrefix:schemePrefix]) {
        NSString *addressWithPrefix = [schemePrefix stringByAppendingString:anAddress];
        URLString = addressWithPrefix;
    } else {
        URLString = anAddress;
    }
    
    NSURL *url = [NSURL URLWithString:URLString];
    return url;
}

+ (NSURL *)reducedURL:(NSURL *)anURL addressData:(NSData **)anAddressData documentRequest:(NSURL **)aRequest {
    NSURL *resultURL = nil;
    if (anURL != nil && [anURL host] != nil) {
        UInt16 port;
        if ([anURL port] != nil) {
            port = [[anURL port] unsignedShortValue];
        } else {
            port = SUBETHAEDIT_DEFAULT_PORT;
        }
        
        NSData *addressData = nil;
        NSString *hostAddress = [anURL host];

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
            if (anAddressData) *anAddressData = addressData;
            freeaddrinfo(result);
        } else {
            DEBUGLOG(@"InternetLogDomain", SimpleLogLevel, @"Neither IPv4 nor IPv6 address");
        }
        if (portString) {
            free(portString);
        }
        
        NSString *URLString = nil;
        if (isIPv6Address) {
            URLString = [NSString stringWithFormat:@"%@://[%@]:%d", [anURL scheme], hostAddress, port];
        } else {
            URLString = [NSString stringWithFormat:@"%@://%@:%d", [anURL scheme], hostAddress, port];
        }
        resultURL = [NSURL URLWithString:URLString];
        
        if ([[anURL path] length] > 0 && ![[anURL path] isEqualToString:@"/"]) {
            if (aRequest) *aRequest = anURL;
        }
        
    } else {
        DEBUGLOG(@"InternetLogDomain", SimpleLogLevel, @"Invalid URI");
    }
    return resultURL;
}

- (void)sendStatusDidChangeNotification {
    [[NSNotificationCenter defaultCenter] postNotificationName:ConnectionBrowserEntryStatusDidChangeNotification object:self];
}

- (id)initWithURL:(NSURL *)anURL {
    if ((self=[super init])) {
        _hostStatus = HostEntryStatusSessionAtEnd;
        _pendingDocumentRequests = [NSMutableArray new];
        NSURL *documentRequest = nil;
        NSData *addressData = nil;
        _URL = [[ConnectionBrowserEntry reducedURL:anURL addressData:&addressData documentRequest:&documentRequest] retain];
        if (!_URL) {
            [_pendingDocumentRequests release];
            [super dealloc];
            return nil;
        }
        if (documentRequest) {
            [_pendingDocumentRequests addObject:documentRequest];
        }
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[_URL absoluteString] forKey:@"URLString"];
        if (addressData) {
            _host = [[TCMHost alloc] initWithAddressData:addressData port:[[_URL port] intValue] userInfo:userInfo];
        } else {
            _host = [[TCMHost alloc] initWithName:[_URL host] port:[[_URL port] intValue] userInfo:userInfo];
        }
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(TCM_connectToHostDidFail:) name:TCMMMBEEPSessionManagerConnectToHostDidFailNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(TCM_connectToHostCancelled:) name:TCMMMBEEPSessionManagerConnectToHostCancelledNotification object:nil];
        _creationDate = [NSDate new];
    }
    return self;
}

- (id)initWithBEEPSession:(TCMBEEPSession *)aSession {
    if ((self=[super init])) {
        _creationDate = [NSDate new];
        _BEEPSession = aSession;
        _hostStatus = HostEntryStatusSessionOpen;
        [self reloadAnnouncedSessions];
    }
    return self;
}

- (void)reloadAnnouncedSessions {
    [_announcedSessions autorelease];
     _announcedSessions = [[[[TCMMMPresenceManager sharedInstance] statusOfUserID:[self userID]] objectForKey:@"OrderedSessions"] copy];
}

- (void)dealloc {
    [_announcedSessions release];
    [_creationDate release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_host release];
    [_pendingDocumentRequests release];
    [_URL release];
    [super dealloc];
}

- (NSDate *)creationDate {
    return _creationDate;
}

- (BOOL)handleURL:(NSURL *)anURL {
    if (_URL) {
        NSURL *request=nil;
        NSURL *reducedURL = [ConnectionBrowserEntry reducedURL:anURL addressData:nil documentRequest:&request];
        if ([_URL isEqualTo:reducedURL]) {
            if (request) [_pendingDocumentRequests addObject:request];
            return YES;
        }
    }
    return NO;
}

- (BOOL)handleSession:(TCMBEEPSession *)aSession {
    if (_URL && !_BEEPSession) {
        if ([[[aSession userInfo] objectForKey:@"URLString"] isEqualToString:[_URL absoluteString]]) {
            if (_hostStatus==HostEntryStatusCancelling ||  _hostStatus==HostEntryStatusCancelled) {
                _hostStatus = HostEntryStatusCancelled;
            } else {
                _BEEPSession = aSession;
                _hostStatus = HostEntryStatusSessionOpen;
            }
            [self reloadAnnouncedSessions];
            return YES;
        }
    }
    return NO;
}

- (BOOL)handleSessionDidEnd:(TCMBEEPSession *)aSession {
    if (_URL && _BEEPSession == aSession) {
        _BEEPSession = nil;
        if (_hostStatus == HostEntryStatusCancelling) _hostStatus = HostEntryStatusCancelled;
        if ([self connectionStatus] != ConnectionStatusNoConnection) {
            _hostStatus = HostEntryStatusSessionAtEnd;
        }
        [self reloadAnnouncedSessions];
        return YES;
    }
    return NO;
}


- (id)itemObjectValueForTag:(int)aTag {
    TCMMMUser *user = [self user];
    BOOL showUser = [self isVisible] && (_hostStatus == HostEntryStatusSessionOpen) && user;
    if (aTag == TCMMMBrowserItemImageTag) {
        if (showUser) {
            return [user image32];
        } else {
            if (_hostStatus == HostEntryStatusSessionInvisible) {
                return [NSImage imageNamed:@"DefaultPerson32"];
            } else {
                return [NSImage imageNamed:@"UnknownPerson32"];
            }
        }
    } else if (aTag == TCMMMBrowserItemImageNextToNameTag) {
        return showUser?[user colorImage]:nil;
    } else 
    if (aTag == TCMMMBrowserItemNameTag) {
        if (showUser) {
            return [user name];
        } else {
            if (_URL) {
                return [_URL absoluteString];
            } else {
                return [NSString stringWithFormat:NSLocalizedString(@"Inbound Connection from %@", @"Inbound Connection ToolTip With Address"), [NSString stringWithAddressData:[_BEEPSession peerAddressData]]];
            }
        }
    } else
    if (aTag == TCMMMBrowserItemStatusTag) {
        if (showUser) {
            return [NSString stringWithFormat:NSLocalizedString(@"%d Document(s)",@"Status string showing the number of documents in Rendezvous and Internet browser"), [[self announcedSessions] count]];
        } else {
            // (void)NSLocalizedString(@"HostEntryStatusResolving", @"Resolving");
            // (void)NSLocalizedString(@"HostEntryStatusResolveFailed", @"Could not resolve");
            // (void)NSLocalizedString(@"HostEntryStatusContacting", @"Contacting");
            // (void)NSLocalizedString(@"HostEntryStatusContactFailed", @"Could not contact");
            // (void)NSLocalizedString(@"HostEntryStatusSessionOpen", @"Connected");
            // (void)NSLocalizedString(@"HostEntryStatusSessionInvisible", @"Invisible");
            // (void)NSLocalizedString(@"HostEntryStatusSessionAtEnd", @"Connection Lost");
            // (void)NSLocalizedString(@"HostEntryStatusCancelling", @"Cancelling");
            // (void)NSLocalizedString(@"HostEntryStatusCancelled", @"Cancelled");
            return NSLocalizedString([self hostStatus], @"<do not localize>");
        }
    } else
    if (aTag == TCMMMBrowserItemActionImageTag) {
        if ([self isBonjour]) {
            return nil;
        } else {
            NSString *connectionStatus = [self connectionStatus];
            if (connectionStatus == ConnectionStatusNoConnection && _URL) {
                return [NSImage imageNamed:@"InternetResume"];
            } else if (_hostStatus == HostEntryStatusCancelling) {
                return nil;
            } else {
                return [NSImage imageNamed:@"InternetStop"];
            }
        }
    }
    return nil;
}

- (id)objectValueForTag:(int)aTag atChildIndex:(int)aChildIndex {
    NSArray *sessions = [self announcedSessions];
    if (aChildIndex >= 0 && aChildIndex < [sessions count]) {
        TCMMMSession *session = [sessions objectAtIndex:aChildIndex];
        if (aTag == TCMMMBrowserChildNameTag) {
            return [session filename];
        } else if (aTag==TCMMMBrowserChildClientStatusTag) {
            return [NSNumber numberWithInt:[session clientState]];
        }else if (aTag == TCMMMBrowserChildIconImageTag) {
            NSString *extension = [[session filename] pathExtension];
            return [[NSWorkspace sharedWorkspace] iconForFileType:extension size:16];
        } else if (aTag == TCMMMBrowserChildStatusImageTag) {
            switch ([session accessState]) {
                case TCMMMSessionAccessLockedState:
                    return [NSImage imageNamed:@"StatusLock"];
                case TCMMMSessionAccessReadOnlyState:
                    return [NSImage imageNamed:@"StatusReadOnly"];
                case TCMMMSessionAccessReadWriteState:
                    return [NSImage imageNamed:@"StatusReadWrite"];
            }            
        }
    }
    return nil;
}

- (TCMBEEPSession *)BEEPSession {
    return _BEEPSession;
}

- (NSString *)userID {
    return [[_BEEPSession userInfo] objectForKey:@"peerUserID"];
}

- (TCMMMUser *)user {
    return [[TCMMMUserManager sharedInstance] userForUserID:[self userID]];
}

- (NSArray *)announcedSessions {
    return _announcedSessions;
}

- (BOOL)isBonjour {
    return [[_BEEPSession userInfo] objectForKey:@"isRendezvous"]!=nil;
}

- (BOOL)isVisible {
    return [[[[TCMMMPresenceManager sharedInstance] statusOfUserID:[self userID]] objectForKey:@"isVisible"] boolValue];
}

- (NSString *)hostStatus {
    return _hostStatus; // only the constants are allowed here so == does work
}

- (NSString *)connectionStatus {
    if (_hostStatus == HostEntryStatusSessionOpen || 
        _hostStatus == HostEntryStatusSessionInvisible) {
        return ConnectionStatusConnected;
    } else if (_hostStatus == HostEntryStatusCancelled ||
               _hostStatus == HostEntryStatusContactFailed ||
               _hostStatus == HostEntryStatusResolveFailed ||
               _hostStatus == HostEntryStatusSessionAtEnd) {
        return ConnectionStatusNoConnection;
    } else {
        return ConnectionStatusInProgress;
    }
}

- (NSURL *)URL {
    return _URL;
}

- (void)checkDocumentRequests {
    if (_BEEPSession) {
        int count = [_pendingDocumentRequests count];
        while (count-- > 0) {
            NSURL *url = [_pendingDocumentRequests objectAtIndex:count];
            NSEnumerator *enumerator = [[self announcedSessions] objectEnumerator];
            TCMMMSession *session;
            while ((session = [enumerator nextObject])) {
                if ([session isAddressedByURL:url]) {
                    [session joinUsingBEEPSession:_BEEPSession];
                    [_pendingDocumentRequests removeObjectAtIndex:count];
                    break;
                }
            }
        }
    }
}

- (void)connect {
    // check if Address data is there
    if ([self connectionStatus] == ConnectionStatusNoConnection) {
        if ([[_host addresses] count] > 0) {
            _hostStatus = HostEntryStatusContacting;
            [[TCMMMBEEPSessionManager sharedInstance] connectToHost:_host];
        } else {
            _hostStatus = HostEntryStatusResolving;
            [_host setDelegate:self];
            [_host resolve];
        }
        [self sendStatusDidChangeNotification];
    } else if ([self connectionStatus] == ConnectionStatusConnected) {
        [self checkDocumentRequests];
    }
}

- (void)cancel {
    if (_hostStatus == HostEntryStatusContacting) {
        _hostStatus = HostEntryStatusCancelling;
        [[TCMMMBEEPSessionManager sharedInstance] cancelConnectToHost:_host];
    } else { 
        if (_BEEPSession) {
            _hostStatus = HostEntryStatusCancelling;
            [_BEEPSession terminate];
        }
    }
}

- (NSString *)toolTipString {
    NSMutableArray *toolTipArray = [NSMutableArray array];
    
    NSString *addressDataString = nil, *userAgent=nil;
    BOOL isInbound = NO;
    if (_BEEPSession) {
        addressDataString = [NSString stringWithAddressData:[_BEEPSession peerAddressData]];
        userAgent = [[_BEEPSession userInfo] objectForKey:@"userAgent"];
        if (!userAgent) userAgent = @"SubEthaEdit/2.x";
        isInbound = ![_BEEPSession isInitiator];
    }
    
    TCMMMUser *user = [self user];
    if (user && [self isVisible]) {
        [toolTipArray addObject:[user name]];
        if ([[[user properties] objectForKey:@"AIM"] length] > 0)
            [toolTipArray addObject:[NSString stringWithFormat:@"AIM: %@",[[user properties] objectForKey:@"AIM"]]];
        if ([[[user properties] objectForKey:@"Email"] length] > 0)
            [toolTipArray addObject:[NSString stringWithFormat:@"Email: %@",[[user properties] objectForKey:@"Email"]]];
    }
    
    if (userAgent) {
        [toolTipArray addObject:userAgent];
    }
    
    if (_URL) {
        [toolTipArray addObject:[_URL absoluteString]];
    } else if (addressDataString) {
        [toolTipArray addObject:addressDataString];
    }
    
    if (isInbound) {
        [toolTipArray addObject:NSLocalizedString(@"Inbound Connection", @"Inbound Connection ToolTip")];
    }
    
    return [toolTipArray count] > 0 ? [toolTipArray componentsJoinedByString:@"\n"] : nil;
}

#pragma mark -
#pragma mark ### TCMHost interaction ###

- (void)hostDidResolveAddress:(TCMHost *)sender {
    DEBUGLOG(@"InternetLogDomain", SimpleLogLevel, @"hostDidResolveAddress:");
    if (_hostStatus == HostEntryStatusCancelled) return;
    _hostStatus = HostEntryStatusContacting;
    [sender setDelegate:nil];
    [[TCMMMBEEPSessionManager sharedInstance] connectToHost:sender];
    [self sendStatusDidChangeNotification];
}

- (void)host:(TCMHost *)sender didNotResolve:(NSError *)error {
    DEBUGLOG(@"InternetLogDomain", SimpleLogLevel, @"host: %@, didNotResolve: %@", sender, error);
    if (_hostStatus == HostEntryStatusCancelled) return;
    _hostStatus = HostEntryStatusResolveFailed;
    [sender setDelegate:nil];
    [self sendStatusDidChangeNotification];
}


- (void)TCM_connectToHostDidFail:(NSNotification *)notification {
    DEBUGLOG(@"InternetLogDomain", DetailedLogLevel, @"TCM_connectToHostDidFail: %@", notification);
    
    TCMHost *host = [[notification userInfo] objectForKey:@"host"];
    if ([host isEqualTo:_host]) {
        _hostStatus = HostEntryStatusContactFailed;
        [self sendStatusDidChangeNotification];
    }
}

- (void)TCM_connectToHostCancelled:(NSNotification *)notification {
    DEBUGLOG(@"InternetLogDomain", DetailedLogLevel, @"TCM_connectToHostCancelled: %@", notification);
    
    TCMHost *host = [[notification userInfo] objectForKey:@"host"];
    if ([host isEqualTo:_host]) {
        _hostStatus = HostEntryStatusCancelled;
        [self sendStatusDidChangeNotification];
    }
//    [self TCM_validateClearButton];
}


@end
