//
//  SEEConnectionManager.m
//  SubEthaEdit
//
//  Original (ConnectionBrowserController.h) by Martin Ott on Wed Mar 03 2004.
//	Updated by Michael Ehrmann on Fri Feb 21 2014.
//  Copyright (c) 2004-2014 TheCodingMonkeys. All rights reserved.
//

#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

#import "TCMMillionMonkeys/TCMMillionMonkeys.h"
#import "SEEConnectionManager.h"
#import "TCMHost.h"
#import "TCMBEEP.h"
#import "TCMFoundation.h"
#import "SEEConnection.h"
#import <TCMPortMapper/TCMPortMapper.h>

@implementation SEEConnectionManager

+ (SEEConnectionManager *)sharedInstance {
	static SEEConnectionManager *sSharedInstance = nil;
	static dispatch_once_t onceToken = 0;
	dispatch_once(&onceToken, ^{
		sSharedInstance = [[[self class] alloc] init];
	});
    return sSharedInstance;
}

+ (NSURL *)applicationConnectionURL {
	NSURL *result = nil;
	if ([[TCMMMBEEPSessionManager sharedInstance] isListening]) {
		TCMPortMapper *pm = [TCMPortMapper sharedInstance];
		NSString *URLString = [NSString stringWithFormat:@"see://%@:%d", [pm localIPAddress],[[TCMMMBEEPSessionManager sharedInstance] listeningPort]];
		TCMPortMapping *mapping = [[pm portMappings] anyObject];
		if ([mapping mappingStatus]==TCMPortMappingStatusMapped) {
			URLString = [NSString stringWithFormat:@"see://%@:%d", [pm externalIPAddress],[mapping externalPort]];
		}
		result = [NSURL URLWithString:URLString];
	}
    return result;
}

- (id)init {
	self = [super init];
    if (self) {
		self.entries = [NSMutableArray array];

		NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];

		TCMMMBEEPSessionManager *manager = [TCMMMBEEPSessionManager sharedInstance];
        [defaultCenter addObserver:self selector:@selector(TCM_didAcceptSession:) name:TCMMMBEEPSessionManagerDidAcceptSessionNotification object:manager];
        [defaultCenter addObserver:self selector:@selector(TCM_sessionDidEnd:) name:TCMMMBEEPSessionManagerSessionDidEndNotification object:manager];

		TCMMMPresenceManager *presenceManager = [TCMMMPresenceManager sharedInstance];
		[defaultCenter addObserver:self selector:@selector(userDidChangeVisibility:) name:TCMMMPresenceManagerUserVisibilityDidChangeNotification object:presenceManager];
        [defaultCenter addObserver:self selector:@selector(userDidChangeAnnouncedDocuments:) name:TCMMMPresenceManagerUserSessionsDidChangeNotification object:presenceManager];
		[defaultCenter addObserver:self selector:@selector(announcedSessionsDidChange:) name:TCMMMPresenceManagerAnnouncedSessionsDidChangeNotification object:presenceManager];
		[defaultCenter addObserver:self selector:@selector(announcedSessionsDidChange:) name:TCMMMPresenceManagerServiceAnnouncementDidChangeNotification object:presenceManager];

        [defaultCenter addObserver:self selector:@selector(connectionEntryDidChange:) name:SEEConnectionStatusDidChangeNotification object:nil];
        [defaultCenter addObserver:self selector:@selector(connectionEntryDidChange:) name:TCMBEEPSessionAuthenticationInformationDidChangeNotification object:nil];

		[defaultCenter addObserver:self selector:@selector(userDidChange:) name:TCMMMUserManagerUserDidChangeNotification object:nil];

		[defaultCenter addObserver:self selector:@selector(userDidChange:) name:TCMPortMapperDidFinishWorkNotification object:nil];
}
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}



#pragma mark -
#pragma mark ### connection actions ###

- (void)connectToAddress:(NSString *)address {
    DEBUGLOG(@"InternetLogDomain", DetailedLogLevel, @"connect to address: %@", address);
    
    NSURL *url = [TCMMMBEEPSessionManager urlForAddress:address];
    
    DEBUGLOG(@"InternetLogDomain", DetailedLogLevel, @"scheme: %@\nhost: %@\nport: %@\npath: %@\nparameterString: %@\nquery: %@", [url scheme], [url host],  [url port], [url path], [url parameterString], [url query]);
    
    if (url != nil && [url host] != nil) {
        [self connectToURL:url];
    } else {
        DEBUGLOG(@"InternetLogDomain", SimpleLogLevel, @"Entered invalid URI");
        NSBeep();
    }
}

- (SEEConnection *)connectionEntryForURL:(NSURL *)anURL {
	[self willChangeValueForKey:@"entries"];
	SEEConnection *entry = nil;
    for (entry in self.entries) {
        if ([entry handleURL:anURL]) {
            return entry;
        }
    }

    entry = [[SEEConnection alloc] initWithURL:anURL];
	[self.entries addObject:entry];
	[self didChangeValueForKey:@"entries"];
    return entry;
}

- (void)connectToURL:(NSURL *)anURL {
    DEBUGLOG(@"InternetLogDomain", DetailedLogLevel, @"Connect to URL: %@", [anURL description]);
    NSParameterAssert(anURL != nil && [anURL host] != nil);
    
    SEEConnection *entry = [self connectionEntryForURL:anURL];
    [entry connect];
}

- (NSArray *)clearableEntries {
    return [self.entries filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"connectionStatus = %@",ConnectionStatusNoConnection]];
}

- (void)clear {
	[self willChangeValueForKey:@"entries"];
	{
		NSArray *entriesToDelete = [self clearableEntries];
		[self.entries removeObjectsInArray:entriesToDelete];
	}
	[self didChangeValueForKey:@"entries"];
}


#pragma mark -
#pragma mark ### Entry lifetime management ###

- (void)TCM_didAcceptSession:(NSNotification *)notification {
    DEBUGLOG(@"InternetLogDomain", DetailedLogLevel, @"TCM_didAcceptSession: %@", notification);

	[self willChangeValueForKey:@"entries"];
	{
		TCMBEEPSession *session = [[notification userInfo] objectForKey:@"Session"];
		BOOL sessionWasHandled = NO;
		for (SEEConnection *entry in self.entries) {
			if ([entry handleSession:session]) {
				sessionWasHandled = YES;
				break;
			}
		}
		if (!sessionWasHandled) {
			SEEConnection *entry = [[SEEConnection alloc] initWithBEEPSession:session];
			[self.entries addObject:entry];
		}
	}
	[self didChangeValueForKey:@"entries"];
}

- (void)TCM_sessionDidEnd:(NSNotification *)notification {
    DEBUGLOG(@"InternetLogDomain", DetailedLogLevel, @"TCM_sessionDidEnd: %@", notification);

	{
		TCMBEEPSession *session = [[notification userInfo] objectForKey:@"Session"];
		SEEConnection *concernedEntry = nil;
		for (SEEConnection *entry in self.entries) {
			if ([entry BEEPSession] == session) {
				concernedEntry = entry;
				break;
			}
		}
		if (concernedEntry) {
			if (![concernedEntry handleSessionDidEnd:session]) {
				[self willChangeValueForKey:@"entries"];
				[self.entries removeObject:concernedEntry];
				[self didChangeValueForKey:@"entries"];
			}
		}
	}
}


#pragma mark -
#pragma mark ### update notification handling ###

/*! should be used for frequent changes that don't affect the number of items, but just their status (icon, name, etc) */
- (void)delayedEnsureListUpdate {
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(ensureListUpdate) object:nil];
	[self performSelector:@selector(ensureListUpdate) withObject:nil afterDelay:0.2];
}

- (void)ensureListUpdate {
	[self willChangeValueForKey:@"entries"];
	[self didChangeValueForKey:@"entries"];
}

- (void)userDidChange:(NSNotification *)aNotification {
    DEBUGLOG(@"InternetLogDomain", AllLogLevel, @"userDidChange: %@", aNotification);
	[self delayedEnsureListUpdate];
}

- (void)announcedSessionsDidChange:(NSNotification *)aNotification {
    DEBUGLOG(@"InternetLogDomain", AllLogLevel, @"announcedSessionsDidChange: %@", aNotification);

	[self willChangeValueForKey:@"entries"];
	[self didChangeValueForKey:@"entries"];
}

#pragma mark -

- (void)userDidChangeVisibility:(NSNotification *)aNotification {
    DEBUGLOG(@"InternetLogDomain", AllLogLevel, @"userDidChangeVisibility: %@", aNotification);

	[self willChangeValueForKey:@"entries"];
	[self didChangeValueForKey:@"entries"];
}

- (void)userDidChangeAnnouncedDocuments:(NSNotification *)aNotification {
    DEBUGLOG(@"InternetLogDomain", AllLogLevel, @"userDidChangeAnnouncedDocuments: %@", aNotification);

	[self willChangeValueForKey:@"entries"];
	{
		NSArray *entries = [self.entries copy];
		[entries makeObjectsPerformSelector:@selector(reloadAnnouncedSessions)];
		[entries makeObjectsPerformSelector:@selector(checkDocumentRequests)];
	}
	[self didChangeValueForKey:@"entries"];

}

#pragma mark -

- (void)connectionEntryDidChange:(NSNotification *)aNotification {
    DEBUGLOG(@"InternetLogDomain", AllLogLevel, @"connectionEntryDidChange: %@", aNotification);

	[self willChangeValueForKey:@"entries"];
	[self didChangeValueForKey:@"entries"];
}

#pragma mark -

+ (NSString *)quoteEscapedStringWithString:(NSString *)aString {
    NSMutableString *string = [aString mutableCopy];
    [string replaceOccurrencesOfString:@"\"" withString:@"\\\"" options:NSLiteralSearch range:NSMakeRange(0,[aString length])];
    return (NSString *)string;
}

+ (void)sendInvitationToServiceWithID:(NSString *)aServiceID buddy:(NSString *)aBuddy url:(NSURL *)anURL {
    // format is service id, id in that service, onlinestatus (0=offline),groupname
    NSString *message = [NSString stringWithFormat:NSLocalizedString(@"Please join me in SubEthaEdit:\n%@\n\n(You can download SubEthaEdit from http://www.codingmonkeys.de/subethaedit )",@"iChat invitation String with Placeholder for actual URL"),[anURL absoluteString]];
    NSString *applescriptString = [NSString stringWithFormat:@"tell application \"iChat\" to send \"%@\" to buddy id \"%@:%@\"",[self quoteEscapedStringWithString:message],aServiceID,aBuddy];
    NSAppleScript *script = [[NSAppleScript alloc] initWithSource:applescriptString];
    // need to delay the sending so we don't try to send while in the dragging event
    [script performSelector:@selector(executeAndReturnError:) withObject:nil afterDelay:0.1];
}

@end

