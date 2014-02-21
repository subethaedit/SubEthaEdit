//
//  InternetBrowserController.m
//  SubEthaEdit
//
//  Created by Martin Ott on Wed Mar 03 2004.
//  Copyright (c) 2004-2007 TheCodingMonkeys. All rights reserved.
//

#import "TCMMillionMonkeys/TCMMillionMonkeys.h"
#import "ConnectionBrowserController.h"
#import "TCMHost.h"
#import "TCMBEEP.h"
#import "TCMFoundation.h"
#import "TCMMMUserSEEAdditions.h"
#import "NSWorkspaceTCMAdditions.h"
#import "ConnectionBrowserEntry.h"
#import "PlainTextDocument.h"
#import <AddressBook/AddressBook.h>

#import <netdb.h>       // getaddrinfo, struct addrinfo, AI_NUMERICHOST
#import <TCMPortMapper/TCMPortMapper.h>


@interface ConnectionBrowserController ()
@property (strong) NSMutableArray *entries;

- (void)connectToURL:(NSURL *)anURL retry:(BOOL)isRetrying;

@end


#pragma mark -

@implementation ConnectionBrowserController

+ (ConnectionBrowserController *)sharedInstance {
	static ConnectionBrowserController *sSharedInstance = nil;
	static dispatch_once_t onceToken = 0;
	dispatch_once(&onceToken, ^{
		sSharedInstance = [[[self class] alloc] init];
	});
    return sSharedInstance;
}

- (id)init {
	self = [super init];
    if (self) {
		self.entries = [NSMutableArray new];

		TCMMMBEEPSessionManager *manager = [TCMMMBEEPSessionManager sharedInstance];
		NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];

		[defaultCenter addObserver:self selector:@selector(userDidChangeVisibility:) name:TCMMMPresenceManagerUserVisibilityDidChangeNotification object:nil];
        [defaultCenter addObserver:self selector:@selector(userDidChangeAnnouncedDocuments:) name:TCMMMPresenceManagerUserSessionsDidChangeNotification object:nil];
        [defaultCenter addObserver:self selector:@selector(connectionEntryDidChange:) name:ConnectionBrowserEntryStatusDidChangeNotification object:nil];
        [defaultCenter addObserver:self selector:@selector(connectionEntryDidChange:) name:TCMBEEPSessionAuthenticationInformationDidChangeNotification object:nil];
        [defaultCenter addObserver:self selector:@selector(TCM_didAcceptSession:) name:TCMMMBEEPSessionManagerDidAcceptSessionNotification object:manager];
        [defaultCenter addObserver:self selector:@selector(TCM_sessionDidEnd:) name:TCMMMBEEPSessionManagerSessionDidEndNotification object:manager];

		// not sure if needed
		[defaultCenter addObserver:self selector:@selector(userDidChange:) name:TCMMMUserManagerUserDidChangeNotification object:nil];
    }
    return self;    
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

	self.entries = nil;

	[super dealloc];
}

- (void)portMapperDidStartWork:(NSNotification *)aNotification {
	NSLog(NSLocalizedString(@"Checking port status...",@"Status of port mapping while trying"));
}

- (void)portMapperDidFinishWork:(NSNotification *)aNotification {
    TCMPortMapper *pm = [TCMPortMapper sharedInstance];
    // since we only have one mapping this is fine
    TCMPortMapping *mapping = [[pm portMappings] anyObject];
    if ([mapping mappingStatus]==TCMPortMappingStatusMapped) {
        NSLog(NSLocalizedString(@"see://%@:%d",@"Connection Browser URL display"), [pm externalIPAddress],[mapping externalPort]);
    } else {
        NSLog(NSLocalizedString(@"No public mapping.",@"Connection Browser Display when not reachable"));
    }
}


- (void)windowDidLoad {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(announcedSessionsDidChange:) name:TCMMMPresenceManagerAnnouncedSessionsDidChangeNotification object:[TCMMMPresenceManager sharedInstance]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(announcedSessionsDidChange:) name:TCMMMPresenceManagerServiceAnnouncementDidChangeNotification object:[TCMMMPresenceManager sharedInstance]];

    // Port Mappings
    TCMPortMapper *pm = [TCMPortMapper sharedInstance];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(portMapperDidStartWork:) name:TCMPortMapperDidStartWorkNotification object:pm];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(portMapperDidFinishWork:) name:TCMPortMapperDidFinishWorkNotification object:pm];
    if ([pm isAtWork]) {
        [self portMapperDidStartWork:nil];
    } else {
        [self portMapperDidFinishWork:nil];
    }
}

- (NSURL*)applicationConnectionURL {
    TCMPortMapper *pm = [TCMPortMapper sharedInstance];
    NSString *URLString = [NSString stringWithFormat:@"see://%@:%d", [pm localIPAddress],[[TCMMMBEEPSessionManager sharedInstance] listeningPort]];
    TCMPortMapping *mapping = [[pm portMappings] anyObject];
    if ([mapping mappingStatus]==TCMPortMappingStatusMapped) {
        URLString = [NSString stringWithFormat:@"see://%@:%d", [pm externalIPAddress],[mapping externalPort]];
    }
    return [NSURL URLWithString:URLString];
}


#pragma mark -
#pragma mark ### connection actions ###

- (void)connectToAddress:(NSString *)address {
    DEBUGLOG(@"InternetLogDomain", DetailedLogLevel, @"connect to address: %@", address);
    
    NSURL *url = [TCMMMBEEPSessionManager urlForAddress:address];
    
    DEBUGLOG(@"InternetLogDomain", DetailedLogLevel, @"scheme: %@\nhost: %@\nport: %@\npath: %@\nparameterString: %@\nquery: %@", [url scheme], [url host],  [url port], [url path], [url parameterString], [url query]);
    
    if (url != nil && [url host] != nil) {
        [self connectToURL:url retry:NO];
    } else {
        DEBUGLOG(@"InternetLogDomain", SimpleLogLevel, @"Entered invalid URI");
        NSBeep();
    }
}

- (ConnectionBrowserEntry *)connectionEntryForURL:(NSURL *)anURL {
    NSEnumerator *entries = [self.entries objectEnumerator];
    ConnectionBrowserEntry *entry = nil;
    while ((entry=[entries nextObject])) {
        if ([entry handleURL:anURL]) {
            return entry;
        }
    }
    entry = [[[ConnectionBrowserEntry alloc] initWithURL:anURL] autorelease];
    [self.entries addObject:entry];
    return entry;
}

- (void)connectToURL:(NSURL *)anURL retry:(BOOL)isRetrying {
    DEBUGLOG(@"InternetLogDomain", DetailedLogLevel, @"Connect to URL: %@", [anURL description]);
    NSParameterAssert(anURL != nil && [anURL host] != nil);
    
    ConnectionBrowserEntry *entry = [self connectionEntryForURL:anURL];
    [entry connect];
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    DEBUGLOG(@"InternetLogDomain", SimpleLogLevel, @"alertDidEnd:");
    
    NSDictionary *alertContext = (NSDictionary *)contextInfo;
    if (returnCode == NSAlertFirstButtonReturn) {
        DEBUGLOG(@"InternetLogDomain", SimpleLogLevel, @"abort connection");
        NSSet *set = [alertContext objectForKey:@"items"];
        ConnectionBrowserEntry *entry=nil;
        for (entry in set) {
            [entry cancel];
        }
    }
    
    [alertContext autorelease];
}

- (NSArray *)clearableEntries {
    return [self.entries filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"connectionStatus = %@",ConnectionStatusNoConnection]];
}

#pragma mark -
#pragma mark ### Entry lifetime management ###

- (void)TCM_didAcceptSession:(NSNotification *)notification {
    DEBUGLOG(@"InternetLogDomain", DetailedLogLevel, @"TCM_didAcceptSession: %@", notification);
    TCMBEEPSession *session = [[notification userInfo] objectForKey:@"Session"];
    
    NSEnumerator *entries = [self.entries objectEnumerator];
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
        [self.entries addObject:entry];
    }
}

- (void)TCM_sessionDidEnd:(NSNotification *)notification {
    DEBUGLOG(@"InternetLogDomain", DetailedLogLevel, @"TCM_sessionDidEnd: %@", notification);
    TCMBEEPSession *session = [[notification userInfo] objectForKey:@"Session"];
    ConnectionBrowserEntry *concernedEntry = nil;
    NSEnumerator *entries = [self.entries objectEnumerator];
    ConnectionBrowserEntry *entry = nil;
    while ((entry=[entries nextObject])) {
        if ([entry BEEPSession] == session) {
            concernedEntry = entry;
            break;
        }
    }
    if (concernedEntry) {
        if (![concernedEntry handleSessionDidEnd:session]) {
            [self.entries removeObject:concernedEntry];
        } 
    }
}


#pragma mark -
#pragma mark ### update notification handling ###

- (void)userDidChange:(NSNotification *)aNotification {
    DEBUGLOG(@"InternetLogDomain", AllLogLevel, @"userDidChange: %@", aNotification);
    if ([[[aNotification userInfo] objectForKey:@"User"] isMe]) {

    } else {

    }
}

- (void)announcedSessionsDidChange:(NSNotification *)aNotification {

}

#pragma mark -

- (void)userDidChangeVisibility:(NSNotification *)aNotification {
    DEBUGLOG(@"InternetLogDomain", AllLogLevel, @"userDidChangeVisibility: %@", aNotification);
//    NSDictionary *userInfo = [aNotification userInfo];
//    NSString *userID = [userInfo objectForKey:@"UserID"];
}

- (void)userDidChangeAnnouncedDocuments:(NSNotification *)aNotification {
    DEBUGLOG(@"InternetLogDomain", AllLogLevel, @"userDidChangeAnnouncedDocuments: %@", aNotification);
//    NSDictionary *userInfo = [aNotification userInfo];
//    NSString *userID = [userInfo objectForKey:@"UserID"];
	NSArray *entries = [[self.entries copy] autorelease];
    [entries makeObjectsPerformSelector:@selector(reloadAnnouncedSessions)];
    [entries makeObjectsPerformSelector:@selector(checkDocumentRequests)];
}

#pragma mark -

- (void)connectionEntryDidChange:(NSNotification *)aNotification {

}

#pragma mark -

+ (NSString *)quoteEscapedStringWithString:(NSString *)aString {
    NSMutableString *string = [[aString mutableCopy] autorelease];
    [string replaceOccurrencesOfString:@"\"" withString:@"\\\"" options:NSLiteralSearch range:NSMakeRange(0,[aString length])];
    return (NSString *)string;
}

+ (void)sendInvitationToServiceWithID:(NSString *)aServiceID buddy:(NSString *)aBuddy url:(NSURL *)anURL {
    // format is service id, id in that service, onlinestatus (0=offline),groupname
    NSString *message = [NSString stringWithFormat:NSLocalizedString(@"Please join me in SubEthaEdit:\n%@\n\n(You can download SubEthaEdit from http://www.codingmonkeys.de/subethaedit )",@"iChat invitation String with Placeholder for actual URL"),[anURL absoluteString]];
    NSString *applescriptString = [NSString stringWithFormat:@"tell application \"iChat\" to send \"%@\" to buddy id \"%@:%@\"",[self quoteEscapedStringWithString:message],aServiceID,aBuddy];
    NSAppleScript *script = [[[NSAppleScript alloc] initWithSource:applescriptString] autorelease];
    // need to delay the sending so we don't try to send while in the dragging event
    [script performSelector:@selector(executeAndReturnError:) withObject:nil afterDelay:0.1];
}

+ (BOOL)invitePeopleFromPasteboard:(NSPasteboard *)aPasteboard intoDocument:(PlainTextDocument *)aDocument group:(NSString *)aGroup {
    BOOL success = NO;
    if ([[aPasteboard types] containsObject:@"PresentityNames"] ||
		[[aPasteboard types] containsObject:@"IMHandleNames"]) {
        NSArray *presentityNames=[[aPasteboard types] containsObject:@"PresentityNames"] ? [aPasteboard propertyListForType:@"PresentityNames"] : [aPasteboard propertyListForType:@"IMHandleNames"]; 
        NSUInteger i=0;
        for (i=0;i<[presentityNames count];i+=4) {
            [self sendInvitationToServiceWithID:[presentityNames objectAtIndex:i] buddy:[presentityNames objectAtIndex:i+1] url:[aDocument documentURLForGroup:aGroup]];
        }
        success = YES;
    }

    return success;
}

+ (BOOL)invitePeopleFromPasteboard:(NSPasteboard *)aPasteboard withURL:(NSURL *)aDocumentURL{
    BOOL success = NO;
    if ([[aPasteboard types] containsObject:@"PresentityNames"] ||
		[[aPasteboard types] containsObject:@"IMHandleNames"]) {
        NSArray *presentityNames=[[aPasteboard types] containsObject:@"PresentityNames"] ? [aPasteboard propertyListForType:@"PresentityNames"] : [aPasteboard propertyListForType:@"IMHandleNames"]; 
        NSUInteger i=0;
        for (i=0;i<[presentityNames count];i+=4) {
            [self sendInvitationToServiceWithID:[presentityNames objectAtIndex:i] buddy:[presentityNames objectAtIndex:i+1] url:aDocumentURL];
        }
        success = YES;
    }

    return success;
}


@end

