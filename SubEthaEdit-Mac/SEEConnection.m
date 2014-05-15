//
//  SEEConnection.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 08.05.07.
//	Updated by Michael Ehrmann on Fri Feb 21 2014.
//  Copyright 2007-2014 TheCodingMonkeys. All rights reserved.
//

#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

#import "SEEConnection.h"
#import "AppController.h"
#import "TCMHost.h"
#import "TCMMMUserManager.h"
#import "TCMMMUserSEEAdditions.h"
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

NSString * const SEEConnectionStatusDidChangeNotification = @"SEEConnectionStatusDidChangeNotification";

@interface SEEConnection ()
@property (nonatomic, readwrite, strong) TCMBEEPSession *BEEPSession;
@property (nonatomic, readwrite, strong) NSURL *URL;

@property (nonatomic, readwrite, strong) TCMHost *host;
@property (nonatomic, readwrite, strong) NSString *hostStatus;

@property (nonatomic, readwrite, strong) NSMutableArray *pendingDocumentRequests;
@property (nonatomic, readwrite, strong) NSMutableArray *tokensToSend;
@property (nonatomic, readwrite, strong) NSArray *announcedSessions;


@end

@implementation SEEConnection

@dynamic isBonjour;
@dynamic isVisible;
@dynamic isClearable;

- (void)sendStatusDidChangeNotification {
    [[NSNotificationCenter defaultCenter] postNotificationName:SEEConnectionStatusDidChangeNotification object:self];
}

- (void)checkURLForToken:(NSURL *)anURL {
    NSString *urlQuery = [anURL query];
    NSString *query;
    if (urlQuery != nil) {
        query = (NSString *)CFBridgingRelease(CFURLCreateStringByReplacingPercentEscapes(kCFAllocatorDefault, (CFStringRef)urlQuery, CFSTR("")));
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
                        [self.tokensToSend addObject:token];
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
       NSURL *url = [TCMMMBEEPSessionManager reducedURL:anURL addressData:&addressData documentRequest:&documentRequest];
        if (url == nil) {
			self = nil;
            return self;
        }

		self.URL = url;

        self.hostStatus = HostEntryStatusSessionAtEnd;
        self.pendingDocumentRequests = [NSMutableArray new];
        self.tokensToSend = [NSMutableArray new];
        if (documentRequest) {
            [self.pendingDocumentRequests addObject:documentRequest];
            [self checkURLForToken:documentRequest];
        }
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[url absoluteString] forKey:@"URLString"];
        if (addressData) {
            self.host = [[TCMHost alloc] initWithAddressData:addressData port:[[url port] intValue] userInfo:userInfo];
        } else {
            self.host = [[TCMHost alloc] initWithName:[url host] port:[[url port] intValue] userInfo:userInfo];
        }
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(TCM_connectToHostDidFail:) name:TCMMMBEEPSessionManagerConnectToHostDidFailNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(TCM_connectToHostCancelled:) name:TCMMMBEEPSessionManagerConnectToHostCancelledNotification object:nil];
    }
    return self;
}

- (id)initWithBEEPSession:(TCMBEEPSession *)aSession {
    if ((self=[super init])) {
        self.BEEPSession = aSession;
        self.hostStatus = HostEntryStatusSessionOpen;
        [self reloadAnnouncedSessions];
    }
    return self;
}

- (void)reloadAnnouncedSessions {
     self.announcedSessions = [[[[TCMMMPresenceManager sharedInstance] statusOfUserID:[self userID]] objectForKey:TCMMMPresenceOrderedSessionsKey] copy];
    // check if we need to connect to any of them
    [self checkDocumentRequests];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)handleURL:(NSURL *)anURL {
	NSURL *url = self.URL;
    if (url) {
        NSURL *request=nil;
        NSURL *reducedURL = [TCMMMBEEPSessionManager reducedURL:anURL addressData:nil documentRequest:&request];
        if ([url isEqualTo:reducedURL]) {
            if (request) {
                [self.pendingDocumentRequests addObject:request];
                [self checkURLForToken:anURL];
            }
            return YES;
        }
    }
    return NO;
}

- (BOOL)handleSession:(TCMBEEPSession *)aSession {
 	NSURL *url = self.URL;
   if (url && !self.BEEPSession) {
        if ([[[aSession userInfo] objectForKey:@"URLString"] isEqualToString:[url absoluteString]]) {
            if ( (self.hostStatus==HostEntryStatusCancelling ||  self.hostStatus==HostEntryStatusCancelled) && ![[aSession userInfo] objectForKey:@"isAutoConnect"]) {
                self.hostStatus = HostEntryStatusCancelled;
            } else {
                self.BEEPSession = aSession;
                self.hostStatus = HostEntryStatusSessionOpen;
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
	NSURL *url = self.URL;
    if (url && self.BEEPSession == aSession) {
        self.BEEPSession = nil;
        if (self.hostStatus == HostEntryStatusCancelling) self.hostStatus = HostEntryStatusCancelled;
        if ([self connectionStatus] != ConnectionStatusNoConnection) {
            self.hostStatus = HostEntryStatusSessionAtEnd;
        }
        [self reloadAnnouncedSessions];
        return YES;
    }
    return NO;
}

- (NSString *)userID {
    return [[self.BEEPSession userInfo] objectForKey:@"peerUserID"];
}

- (TCMMMUser *)user {
    return [[TCMMMUserManager sharedInstance] userForUserID:[self userID]];
}

- (BOOL)isBonjour {
    return [[self.BEEPSession userInfo] objectForKey:@"isRendezvous"]!=nil;
}

- (BOOL)isVisible {
    return [[[[TCMMMPresenceManager sharedInstance] statusOfUserID:[self userID]] objectForKey:@"isVisible"] boolValue];
}

+ (NSSet *)keyPathsForValuesAffectingIsClearable {
    return [NSSet setWithObjects:@"connectionStatus", nil];
}

- (BOOL)isClearable {
	return self.connectionStatus == ConnectionStatusNoConnection;
}

+ (NSSet *)keyPathsForValuesAffectingConnectionStatus {
    return [NSSet setWithObjects:@"hostStatus", nil];
}

- (NSString *)connectionStatus {
	NSString *hostStatus = self.hostStatus;
    if (hostStatus == HostEntryStatusSessionOpen ||
        hostStatus == HostEntryStatusSessionInvisible) {
        return ConnectionStatusConnected;
    } else if (hostStatus == HostEntryStatusCancelled ||
               hostStatus == HostEntryStatusContactFailed ||
               hostStatus == HostEntryStatusResolveFailed ||
               hostStatus == HostEntryStatusSessionAtEnd) {
        return ConnectionStatusNoConnection;
    } else {
        return ConnectionStatusInProgress;
    }
}

- (void)checkDocumentRequests {
    if (self.BEEPSession && self.pendingDocumentRequests && [[self announcedSessions] count]) {
        int count = [self.pendingDocumentRequests count];
        while (count-- > 0) {
            NSURL *url = [self.pendingDocumentRequests objectAtIndex:count];
            NSEnumerator *enumerator = [[self announcedSessions] objectEnumerator];
            TCMMMSession *session;
            while ((session = [enumerator nextObject])) {
                if ([session isAddressedByURL:url]) {
                    [session joinUsingBEEPSession:self.BEEPSession];
                    [self.pendingDocumentRequests removeObjectAtIndex:count];
                    break;
                }
            }
        }
    }
    TCMMMStatusProfile *statusProfile = [[TCMMMPresenceManager sharedInstance] statusProfileForUserID:[self userID]];
    if (statusProfile && [self.tokensToSend count] && self.BEEPSession && self.pendingDocumentRequests) {
        int count = [self.tokensToSend count];
        while (count-- > 0) {
            if ([statusProfile sendToken:[self.tokensToSend objectAtIndex:count]]) {
                [self.tokensToSend removeObjectAtIndex:count];
            }
        }
    }
}

- (void)connect {
    // check if Address data is there
    if ([self connectionStatus] == ConnectionStatusNoConnection) {
        if ([[self.host addresses] count] > 0) {
            self.hostStatus = HostEntryStatusContacting;
            [[TCMMMBEEPSessionManager sharedInstance] connectToHost:self.host];
        } else {
            self.hostStatus = HostEntryStatusResolving;
            [self.host setDelegate:self];
            [self.host resolve];
        }
        [self sendStatusDidChangeNotification];
    } else if ([self connectionStatus] == ConnectionStatusConnected) {
        [self checkDocumentRequests];
    }
}

- (void)cancel {
    if (self.hostStatus == HostEntryStatusContacting) {
        self.hostStatus = HostEntryStatusCancelling;
        [[TCMMMBEEPSessionManager sharedInstance] cancelConnectToHost:self.host];
    } else { 
        if (self.BEEPSession) {
            self.hostStatus = HostEntryStatusCancelling;
            [self.BEEPSession terminate];
        }
    }
}

- (NSString *)toolTipString {
    NSMutableArray *toolTipArray = [NSMutableArray array];
    
    NSString *addressDataString = nil, *userAgent=nil;
    BOOL isInbound = NO;
    if (self.BEEPSession) {
        addressDataString = [NSString stringWithAddressData:[self.BEEPSession peerAddressData]];
        userAgent = [[self.BEEPSession userInfo] objectForKey:@"userAgent"];
        if (!userAgent) userAgent = @"SubEthaEdit/2.x";
        isInbound = ![self.BEEPSession isInitiator];
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
    
 	NSURL *url = self.URL;
   if (url) {
        [toolTipArray addObject:[url absoluteString]];
    } else if (addressDataString) {
        [toolTipArray addObject:addressDataString];
    }
        
    if ([[self.BEEPSession userInfo] objectForKey:@"isAutoConnect"]) {
        if (isInbound) {
            [toolTipArray addObject:NSLocalizedString(@"Inbound Friendcast Connection", @"Inbound Friendcast Connection ToolTip")];
        } else {
            [toolTipArray addObject:NSLocalizedString(@"Friendcast Connection", @"Friendcast Connection ToolTip")];
        }
    } else if (isInbound) {
        [toolTipArray addObject:NSLocalizedString(@"Inbound Connection", @"Inbound Connection ToolTip")];
    }
    
	NSString *URLString = [[TCMMMPresenceManager sharedInstance] reachabilityURLStringOfUserID:user.userID];
	if (URLString) {
		[toolTipArray addObject:URLString];
	}
	
    return [toolTipArray count] > 0 ? [toolTipArray componentsJoinedByString:@"\n"] : nil;
}

#pragma mark -
#pragma mark ### TCMHost interaction ###

- (void)hostDidResolveAddress:(TCMHost *)sender {
    DEBUGLOG(@"InternetLogDomain", SimpleLogLevel, @"hostDidResolveAddress:");
    if (self.hostStatus == HostEntryStatusCancelled) return;
    self.hostStatus = HostEntryStatusContacting;
    [sender setDelegate:nil];
    [[TCMMMBEEPSessionManager sharedInstance] connectToHost:sender];
    [self sendStatusDidChangeNotification];
}

- (void)host:(TCMHost *)sender didNotResolve:(NSError *)error {
    DEBUGLOG(@"InternetLogDomain", SimpleLogLevel, @"host: %@, didNotResolve: %@", sender, error);
    if (self.hostStatus == HostEntryStatusCancelled) return;
    self.hostStatus = HostEntryStatusResolveFailed;
    [sender setDelegate:nil];
    [self sendStatusDidChangeNotification];
}


- (void)TCM_connectToHostDidFail:(NSNotification *)notification {
    DEBUGLOG(@"InternetLogDomain", DetailedLogLevel, @"TCM_connectToHostDidFail: %@", notification);
    
    TCMHost *host = [[notification userInfo] objectForKey:@"host"];
    if ([host isEqualTo:self.host]) {
        self.hostStatus = HostEntryStatusContactFailed;
        [self sendStatusDidChangeNotification];
    }
}

- (void)TCM_connectToHostCancelled:(NSNotification *)notification {
    DEBUGLOG(@"InternetLogDomain", DetailedLogLevel, @"TCM_connectToHostCancelled: %@", notification);
    
    TCMHost *host = [[notification userInfo] objectForKey:@"host"];
    if ([host isEqualTo:self.host]) {
        self.hostStatus = HostEntryStatusCancelled;
        [self sendStatusDidChangeNotification];
    }
}


@end
