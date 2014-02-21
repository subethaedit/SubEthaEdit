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


- (void)sendStatusDidChangeNotification {
    [[NSNotificationCenter defaultCenter] postNotificationName:ConnectionBrowserEntryStatusDidChangeNotification object:self];
}

- (void)initHelper {
    _isDisclosed = YES;
}

- (void)checkURLForToken:(NSURL *)anURL {
    NSString *urlQuery = [anURL query];
    NSString *query;
    if (urlQuery != nil) {
        query = (NSString *)CFURLCreateStringByReplacingPercentEscapes(kCFAllocatorDefault, (CFStringRef)urlQuery, CFSTR(""));
        [query autorelease];
        NSArray *components = [query componentsSeparatedByString:@"&"];
        NSString *token = nil;
        NSString *sessionID = nil;
        NSString *item;
        for (item in components) {
            NSArray *keyValue = [item componentsSeparatedByString:@"="];
            if ([keyValue count] == 2) {
                if ([[keyValue objectAtIndex:0] isEqualToString:@"token"]) {
                    token = [keyValue objectAtIndex:1];
                    if (token) {
                        [_tokensToSend addObject:token];
                    }
                } else if ([[keyValue objectAtIndex:0] isEqualToString:@"sessionID"]) {
                    sessionID = [keyValue objectAtIndex:1];
                }
            }
        }
        if (sessionID && token) {
            [[TCMMMPresenceManager sharedInstance] setShouldAutoAcceptInviteToSessionID:sessionID];
        }
    }
}

- (id)initWithURL:(NSURL *)anURL {
    if ((self=[super init])) {
		NSURL *documentRequest = nil;
        NSData *addressData = nil;
       _URL = [[TCMMMBEEPSessionManager reducedURL:anURL addressData:&addressData documentRequest:&documentRequest] retain];
        if (!_URL) {
            [self release];
			self = nil;
            return self;
        }

        [self initHelper];
        _hostStatus = HostEntryStatusSessionAtEnd;
        _pendingDocumentRequests = [NSMutableArray new];
        _tokensToSend = [NSMutableArray new];
        if (documentRequest) {
            [_pendingDocumentRequests addObject:documentRequest];
            [self checkURLForToken:documentRequest];
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
        [self initHelper];
        _creationDate = [NSDate new];
        _BEEPSession = aSession;
        _hostStatus = HostEntryStatusSessionOpen;
        [self reloadAnnouncedSessions];
    }
    return self;
}

- (void)reloadAnnouncedSessions {
    [_announcedSessions autorelease];
     _announcedSessions = [[[[TCMMMPresenceManager sharedInstance] statusOfUserID:[self userID]] objectForKey:TCMMMPresenceOrderedSessionsKey] copy];
    // check if we need to connect to any of them
    [self checkDocumentRequests];
}

- (void)dealloc {
    [_announcedSessions release];
    [_creationDate release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_host release];
    [_pendingDocumentRequests release];
    [_tokensToSend release];
    [_URL release];
    [super dealloc];
}

- (NSDate *)creationDate {
    return _creationDate;
}

- (BOOL)handleURL:(NSURL *)anURL {
    if (_URL) {
        NSURL *request=nil;
        NSURL *reducedURL = [TCMMMBEEPSessionManager reducedURL:anURL addressData:nil documentRequest:&request];
        if ([_URL isEqualTo:reducedURL]) {
            if (request) {
                [_pendingDocumentRequests addObject:request];
                [self checkURLForToken:anURL];
            }
            return YES;
        }
    }
    return NO;
}

- (BOOL)handleSession:(TCMBEEPSession *)aSession {
    if (_URL && !_BEEPSession) {
        if ([[[aSession userInfo] objectForKey:@"URLString"] isEqualToString:[_URL absoluteString]]) {
            if ( (_hostStatus==HostEntryStatusCancelling ||  _hostStatus==HostEntryStatusCancelled) && ![[aSession userInfo] objectForKey:@"isAutoConnect"]) {
                _hostStatus = HostEntryStatusCancelled;
            } else {
                _BEEPSession = aSession;
                _hostStatus = HostEntryStatusSessionOpen;
                if (![[aSession userInfo] objectForKey:@"isAutoConnect"]) {
                    [[TCMMMPresenceManager sharedInstance] setShouldAutoconnect:YES forUserID:[self userID]];
                }
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
    if (aTag == TCMMMBrowserItemImageInFrontOfNameTag) {
        if ([self isBonjour]) {
            return [NSImage imageNamed:@"Bonjour13"];
        } else  if ([[_BEEPSession userInfo] objectForKey:@"isAutoConnect"]) {
            return [NSImage imageNamed:@"FriendcastingConnection"];
        } else {
            return [NSImage imageNamed:@"Internet13"];
        }
    }
    if (aTag == TCMMMBrowserItemIsDisclosedTag) {
        return [NSNumber numberWithBool:_isDisclosed];
    }
    BOOL showUser = [self isVisible] && (_hostStatus == HostEntryStatusSessionOpen) && user;
    if (aTag == TCMMMBrowserItemStatusImageOverlayTag) {
        if (_BEEPSession && ![_BEEPSession isTLSEnabled]) {
            return [NSImage imageNamed:@"ssllock18"];
        } else {
            return nil;
        }
    } else
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
//    } else if (aTag == TCMMMBrowserItemImageNextToNameTag) {
//        if ([[_BEEPSession availableSASLProfileURIs] count]) {
//            if ([_BEEPSession authenticationInformation]) {
//                return [NSImage imageNamed:@"LoginButtonIn"];
//            } else {
//                return [NSImage imageNamed:@"LoginButton"];
//            }
//        } else {
//            if (showUser) {
//                return [user colorImage];
//            } else {
//                return nil;
//            }
//        }
    }  else if (aTag == TCMMMBrowserItemStatusImageTag) {
        NSDictionary *status = [[TCMMMPresenceManager sharedInstance] statusOfUserID:[user userID]];
        if ([[status objectForKey:@"hasFriendCast"] boolValue] && showUser) {
            if ([[status objectForKey:@"shouldAutoConnect"] boolValue] && 
                [[NSUserDefaults standardUserDefaults] boolForKey:AutoconnectPrefKey]) {
                return [NSImage imageNamed:@"FriendCast13"]; 
            } else {
                return [NSImage imageNamed:@"FriendCast13Off"]; 
            }
        } else {
            return [NSImage imageNamed:@"FriendCast13None"];
        }

    } else 
    if (aTag == TCMMMBrowserItemNameTag) {
        if (showUser) {
            return [user name];
        } else {
            if (user) {
                return NSLocalizedString(@"Invisible User",@"User name for invisible users in Connection Browser");
            } else if (_URL) {
                return [_URL absoluteString];
            } else {
                return [NSString stringWithFormat:NSLocalizedString(@"Inbound Connection from %@", @"Inbound Connection ToolTip With Address"), [NSString stringWithAddressData:[_BEEPSession peerAddressData]]];
            }
        }
    } else
//  if (aTag == TCMMMBrowserItemUserNameTag) {
//      if (showUser) {
//          return [user name];
//      }
//  } else
    if (aTag == TCMMMBrowserItemStatusTag) {
        if (showUser || ([self connectionStatus] == ConnectionStatusConnected)) {
            NSString *reachabilityURLString = [[TCMMMPresenceManager sharedInstance] reachabilityURLStringOfUserID:[user userID]];
            if ([self isBonjour]) {
                return @"Bonjour";
            } else if (_URL) {
                return [_URL absoluteString];
            } else if (reachabilityURLString) {
                return reachabilityURLString;
            } else if ([[_BEEPSession userInfo] objectForKey:@"isAutoConnect"]) {
                return NSLocalizedString(@"Friend of a Friend",@"Connection browser subtitle for friendcasting connections");
            } else {
                return NSLocalizedString(@"Internet connection",@"Connection browser subtitle for internet connections");
            }

            NSString *documentString = NSLocalizedString(@"None announced",@"Status string showing the number of documents when none are announced");
            unsigned int count = [[self announcedSessions] count];
            if (count == 1) {
                documentString = NSLocalizedString(@"1 Document",@"Status string showing the number of documents when one is announced");
            } else if (count > 1) {
                documentString = [NSString stringWithFormat:NSLocalizedString(@"%d Documents",@"Status string showing the number of documents The browser when there are multiple documents announced"), count];
            }
            return documentString;
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
        } else if (aTag == TCMMMBrowserChildInsetTag) {
            return [NSNumber numberWithInt:0];
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

- (void)toggleDisclosure {
    _isDisclosed = !_isDisclosed;
}

- (BOOL)isDisclosed {
    return _isDisclosed;
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
    if (_BEEPSession && _pendingDocumentRequests && [[self announcedSessions] count]) {
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
    TCMMMStatusProfile *statusProfile = [[TCMMMPresenceManager sharedInstance] statusProfileForUserID:[self userID]];
    if (statusProfile && [_tokensToSend count] && _BEEPSession && _pendingDocumentRequests) {
        int count = [_tokensToSend count];
        while (count-- > 0) {
            if ([statusProfile sendToken:[_tokensToSend objectAtIndex:count]]) {
                [_tokensToSend removeObjectAtIndex:count];
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

        if ([(NSString *)[[user properties] objectForKey:@"AIM"] length] > 0)
            [toolTipArray addObject:[NSString stringWithFormat:@"AIM: %@",[[user properties] objectForKey:@"AIM"]]];
        if ([(NSString *)[[user properties] objectForKey:@"Email"] length] > 0)
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
    
    if (_BEEPSession) {
        if ([_BEEPSession isTLSEnabled]) {
            [toolTipArray addObject:[NSString stringWithFormat:NSLocalizedString(@"Connection is TLS/SSL encrypted using %@",@"SSL Encryption Connection Tooltip Text Encrypted"),[_BEEPSession isTLSAnon] ? @"DH" : @"RSA"]];
        } else {
            [toolTipArray addObject:NSLocalizedString(@"Connection is NOT encrypted",@"SSL Encryption Connection Tooltip Text NOT Encrypted")];
        }
    }
    
    if ([[_BEEPSession userInfo] objectForKey:@"isAutoConnect"]) {
        if (isInbound) {
            [toolTipArray addObject:NSLocalizedString(@"Inbound Friendcast Connection", @"Inbound Friendcast Connection ToolTip")];
        } else {
            [toolTipArray addObject:NSLocalizedString(@"Friendcast Connection", @"Friendcast Connection ToolTip")];
        }
    } else if (isInbound) {
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
