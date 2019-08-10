//  TCMMMPresenceManager.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Fri Feb 27 2004.

// this file needs arc - either project wide,
// or add -fobjc-arc on a per file basis in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif


#import "TCMMMPresenceManager.h"
#import "TCMMMBEEPSessionManager.h"
#import "TCMMMStatusProfile.h"
#import "TCMMMUserManager.h"
#import "TCMMMUser.h"
#import "TCMMMSession.h"
#import "TCMRendezvousBrowser.h"
#import "TCMHost.h"
#import <SystemConfiguration/SystemConfiguration.h>
#import <TCMPortMapper/TCMPortMapper.h>

NSString * const VisibilityPrefKey = @"VisibilityPrefKey";
NSString * const AutoconnectPrefKey = @"shouldAutoConnect";

static TCMMMPresenceManager *sharedInstance = nil;

NSString * const TCMMMPresenceManagerUserVisibilityDidChangeNotification=
               @"TCMMMPresenceManagerUserVisibilityDidChangeNotification";
NSString * const TCMMMPresenceManagerUserRendezvousStatusDidChangeNotification=
               @"TCMMMPresenceManagerUserRendezvousStatusDidChangeNotification";
NSString * const TCMMMPresenceManagerUserSessionsDidChangeNotification=
               @"TCMMMPresenceManagerUserSessionsDidChangeNotification";
NSString * const TCMMMPresenceManagerAnnouncedSessionsDidChangeNotification=
               @"TCMMMPresenceManagerAnnouncedSessionsDidChangeNotification";
NSString * const TCMMMPresenceManagerServiceAnnouncementDidChangeNotification=
               @"TCMMMPresenceManagerServiceAnnouncementDidChangeNotification";
NSString * const TCMMMPresenceManagerDidReceiveTokenNotification=
               @"TCMMMPresenceManagerDidReceiveTokenNotification";


NSString * const TCMMMPresenceStatusKey = @"Status";
NSString * const TCMMMPresenceUnknownStatusValue = @"NoStatus";
NSString * const TCMMMPresenceKnownStatusValue = @"GotStatus";
NSString * const TCMMMPresenceUserIDKey = @"UserID";
NSString * const TCMMMPresenceAutoconnectOriginUserIDKey = @"AutoconnectOriginUserID";
NSString * const TCMMMPresenceReachabiltyURLKey = @"ReachabilityURL";
NSString * const TCMMMPresenceSessionsKey = @"Sessions";
NSString * const TCMMMPresenceOrderedSessionsKey = @"OrderedSessions";
NSString * const TCMMMPresenceNetServicesKey = @"NetServices";
NSString * const TCMMMPresenceStatusProfileKey = @"StatusProfile";

NSString * const TCMMMPresenceTXTRecordUserIDKey = @"userid";
NSString * const TCMMMPresenceTXTRecordNameKey = @"name";



@interface TCMMMPresenceManager (TCMMMPresenceManagerPrivateAdditions)

- (void)TCM_validateServiceAnnouncement;
- (void)sendReachabilityViaProfile:(TCMMMStatusProfile *)aProfile;
- (void)broadcastMyReachability;
@end

#pragma mark -

/*"
    StatusInformation:
        @"Status" => @"NoStatus" | @"GotStatus"
        @"UserID" => userID
        @"Sessions" => TCMMMSessions
        @"NetServices" => NSNetServices
        @"isVisible"  => nil | NSNumber "YES"
        @"InternalIsVisible" => nil | NSNumber "YES" // for internal use only
        @"StatusProfile" => TCMMMStatusProfile if present
        @"shouldSendVisibilityChangeNotification" => nil | NSNumber "YES"  // for internal use only
        @"shouldAutoConnect" => nil | NSNumber "YES" // if we autoconnect to reachability infos of that user - == subscribe to friendcast
        @"hasFriendCast" => nil | NSNumber "YES"
"*/


@implementation TCMMMPresenceManager

+ (instancetype)sharedInstance {
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
        sharedInstance = [self new];
	});
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        I_statusOfUserIDs = [NSMutableDictionary new];
        I_statusProfilesInServerRole = [NSMutableSet new];
        I_announcedSessions  = [NSMutableDictionary new];
        I_registeredSessions = [NSMutableDictionary new];
        I_autoAcceptInviteSessions = [NSMutableDictionary new];
        I_flags.serviceIsPublished=NO;
        I_foundUserIDs=[NSMutableSet new];
        sharedInstance = self;
		I_serviceNameAddition = 0;
		TCMMMBEEPSessionManager *sessionManager = [TCMMMBEEPSessionManager sharedInstance];
		[sessionManager registerHandler:self forIncomingProfilesWithProfileURI:@"http://www.codingmonkeys.de/BEEP/TCMMMStatus"];

		NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
        [defaultCenter addObserver:self selector:@selector(TCM_didAcceptSession:) name:TCMMMBEEPSessionManagerDidAcceptSessionNotification object:[TCMMMBEEPSessionManager sharedInstance]];
        [defaultCenter addObserver:self selector:@selector(TCM_didEndSession:) name:TCMMMBEEPSessionManagerSessionDidEndNotification object:[TCMMMBEEPSessionManager sharedInstance]];
        I_resolveUnconnectedFoundNetServicesTimer = [NSTimer scheduledTimerWithTimeInterval:90. target:self selector:@selector(resolveUnconnectedFoundNetServices:) userInfo:nil repeats:YES];
        [defaultCenter addObserver:self selector:@selector(broadcastMyReachability) name:TCMPortMapperDidFinishWorkNotification object:[TCMPortMapper sharedInstance]];
        // bind to user defaults
        [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:[@"values." stringByAppendingString:AutoconnectPrefKey] options:0 context:nil];
        
    }
    return self;
}

// this is only for observing the user defaults setting which we don't do anymore
- (void)observeValueForKeyPath:(NSString *)aKeyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    // send new friendcasting status
    TCMMMStatusProfile *profile = nil;
    BOOL shouldDoFriendcasting = [self shouldDoFriendcasting];
    for (profile in I_statusProfilesInServerRole) {
        [profile sendIsFriendcasting:shouldDoFriendcasting];
        if (shouldDoFriendcasting) {
            // also send the current friendcast information
            [self sendReachabilityViaProfile:profile];
        }
    }
}

- (void)dealloc  {
    [I_resolveUnconnectedFoundNetServicesTimer invalidate];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)stopRendezvousBrowsing {
    [I_browser setDelegate:nil];
    [I_browser stopSearch];

    NSString *userID=nil;
    for (userID in I_foundUserIDs) {
        NSMutableDictionary *status=[self statusOfUserID:userID];
        [[status objectForKey:TCMMMPresenceNetServicesKey] removeAllObjects];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:TCMMMPresenceManagerUserRendezvousStatusDidChangeNotification object:self userInfo:[NSDictionary dictionaryWithObject:[I_foundUserIDs allObjects] forKey:@"UserIDs"]];
    I_browser=nil;
	[self TCM_validateServiceAnnouncement];
}

- (void)startRendezvousBrowsing {
    [self stopRendezvousBrowsing];
    I_browser=[[TCMRendezvousBrowser alloc] initWithServiceType:@"_see._tcp." domain:@""];
    [I_browser setDelegate:self];
    [I_browser startSearch];
	[self TCM_validateServiceAnnouncement];
}

- (NSString *)serviceName {
    NSString *computerName = CFBridgingRelease(SCDynamicStoreCopyComputerName(NULL,NULL));
	NSString *result = [NSString stringWithFormat:@"%@@%@",NSUserName(),computerName];
	int listeningPort = [[TCMMMBEEPSessionManager sharedInstance] listeningPort];
	if (listeningPort != 6942) {
		result = [result stringByAppendingFormat:@"_%d",listeningPort];
	}
	if (I_serviceNameAddition > 0) {
		result = [result stringByAppendingFormat:@" (%ld)",(long)I_serviceNameAddition];
	}
    return result;
}

- (void)TCM_validateServiceAnnouncement {
    // Announce ourselves via rendezvous
    
    TCMMMUser *me = [[TCMMMUserManager sharedInstance] me];
	NSArray *txtRecordArray = [NSArray arrayWithObjects:
							   @"txtvers=1",
							   [NSString stringWithFormat:@"%@=%@",TCMMMPresenceTXTRecordUserIDKey,[me userID]],
							   [NSString stringWithFormat:@"%@=%@",TCMMMPresenceTXTRecordNameKey,[me name]],
							   @"version=2",
							   nil];
	
    if (!self.isCurrentlyReallyInvisible &&
		!I_flags.serviceIsPublished) {
		I_netService=[[NSNetService alloc] initWithDomain:@"" type:@"_see._tcp." name:[self serviceName] port:[[TCMMMBEEPSessionManager sharedInstance] listeningPort]];
		[I_netService setDelegate:self];
        [I_netService setTXTRecordByArray:txtRecordArray];
        [I_netService publish];
        I_flags.serviceIsPublished = YES;
        [[NSNotificationCenter defaultCenter] postNotificationName:TCMMMPresenceManagerServiceAnnouncementDidChangeNotification object:self];
    } else if (self.isCurrentlyReallyInvisible && I_flags.serviceIsPublished){
        [I_netService stop];
        [[NSNotificationCenter defaultCenter] postNotificationName:TCMMMPresenceManagerServiceAnnouncementDidChangeNotification object:self];
    } else if (I_flags.serviceIsPublished) {
		[I_netService setTXTRecordByArray:txtRecordArray];
    }
}

- (BOOL)isCurrentlyReallyInvisible {
	BOOL result = NO;
	if (!(I_flags.isVisible) && [self announcedSessions].count == 0) {
		result = YES;
	}
	if ([[TCMMMBEEPSessionManager sharedInstance] isNetworkingDisabled]) {
		result = YES;
	}
	return result;
}

- (BOOL)isVisible {
    return I_flags.isVisible;
}

- (void)setVisible:(BOOL)aFlag {
    I_flags.isVisible = aFlag;
    [self TCM_validateServiceAnnouncement];
    [self broadcastMyReachability];
	BOOL shouldDoFriendcasting = [self shouldDoFriendcasting];
    for (TCMMMStatusProfile *profile in I_statusProfilesInServerRole) {
        [profile sendVisibility:aFlag];
		[profile sendIsFriendcasting:shouldDoFriendcasting];
		if (shouldDoFriendcasting) {
			[self sendReachabilityViaProfile:profile];
			NSString *peerID = [[[profile session] userInfo] objectForKey:@"peerUserID"];
			TCMMMStatusProfile *profile = [self statusProfileForUserID:peerID];
			[profile requestReachability];
		}
    }
	
    [[TCMMMBEEPSessionManager sharedInstance] validateListener];
}

- (void)setShouldAutoconnect:(BOOL)aFlag forUserID:(NSString *)aUserID {
    NSMutableDictionary *status = [self statusOfUserID:aUserID];
    if (aFlag) {
        [status setObject:[NSNumber numberWithBool:YES] forKey:@"shouldAutoConnect"];
        [[status objectForKey:TCMMMPresenceStatusProfileKey] requestReachability];
    } else {
        [status removeObjectForKey:@"shouldAutoConnect"];
    }
}

- (NSMutableDictionary *)statusOfUserID:(NSString *)aUserID {
    if (!aUserID) return nil;
    NSMutableDictionary *statusOfUserID=[I_statusOfUserIDs objectForKey:aUserID];
    if (!statusOfUserID) {
        statusOfUserID=[NSMutableDictionary dictionary];
        [statusOfUserID setObject:TCMMMPresenceUnknownStatusValue forKey:TCMMMPresenceStatusKey];
        [statusOfUserID setObject:aUserID     forKey:TCMMMPresenceUserIDKey];
        [statusOfUserID setObject:[NSMutableDictionary dictionary] forKey:TCMMMPresenceSessionsKey];
        [statusOfUserID setObject:[NSArray array] forKey:TCMMMPresenceOrderedSessionsKey];
        [statusOfUserID setObject:[NSMutableSet set] forKey:TCMMMPresenceNetServicesKey];
        [I_statusOfUserIDs setObject:statusOfUserID forKey:aUserID];
    }
    return statusOfUserID;
}

- (TCMMMStatusProfile *)statusProfileForUserID:(NSString *)aUserID {
    NSDictionary *status=[self statusOfUserID:aUserID];
    if ([[status objectForKey:TCMMMPresenceStatusKey] isEqualToString:TCMMMPresenceKnownStatusValue]) {
        return [status objectForKey:TCMMMPresenceStatusProfileKey];
    } else {
        return nil;
    }
}


- (NSArray *)announcedSessions {
    return [[I_announcedSessions allValues] sortedArrayUsingComparator:^NSComparisonResult(TCMMMSession *session1, TCMMMSession *session2) {
		NSComparisonResult result = [session1.filename compare:session2.filename options:NSDiacriticInsensitiveSearch | NSCaseInsensitiveSearch | NSWidthInsensitiveSearch | NSForcedOrderingSearch | NSNumericSearch];
		return result;
	}];
}

- (void)announcedSessionDidChange:(NSNotification *)aNotification {
    [I_statusProfilesInServerRole makeObjectsPerformSelector:@selector(announceSession:) withObject:[aNotification object]];
}

- (void)TCM_sendAnnouncedSessionsDidChangeNotification {
    [[NSNotificationQueue defaultQueue] 
    enqueueNotification:[NSNotification notificationWithName:TCMMMPresenceManagerAnnouncedSessionsDidChangeNotification object:self]
           postingStyle:NSPostWhenIdle 
           coalesceMask:NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender 
               forModes:[NSArray arrayWithObject:NSDefaultRunLoopMode]];
}

- (void)announceSession:(TCMMMSession *)aSession {
    if (![aSession isServer]) { 
        NSLog(@"tried to announce session although we are not the host: %@", [aSession description]);
    } else {
        [I_announcedSessions setObject:aSession forKey:[aSession sessionID]];
        [self TCM_validateServiceAnnouncement];
        [I_statusProfilesInServerRole makeObjectsPerformSelector:@selector(announceSession:) withObject:aSession];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(announcedSessionDidChange:) name:TCMMMSessionDidChangeNotification object:aSession];
        [self TCM_sendAnnouncedSessionsDidChangeNotification];
    }
}

- (void)concealSession:(TCMMMSession *)aSession {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:TCMMMSessionDidChangeNotification object:aSession];
    [I_announcedSessions removeObjectForKey:[aSession sessionID]];
    [self TCM_validateServiceAnnouncement];
    [I_statusProfilesInServerRole makeObjectsPerformSelector:@selector(concealSession:) withObject:aSession];
    [self TCM_sendAnnouncedSessionsDidChangeNotification];
}

- (TCMMMSession *)sessionForSessionID:(NSString *)aSessionID
{
    return [[I_registeredSessions objectForKey:aSessionID] objectForKey:@"Session"];
}

- (void)propagateChangeOfMyself {
    TCMMMStatusProfile *profile=nil;
    for (profile in I_statusProfilesInServerRole) {
        [profile sendUserDidChangeNotification:[TCMMMUserManager me]];
    }
	[self TCM_validateServiceAnnouncement]; // update announcement txt record
}

- (NSArray *)allUsers {
    return [I_statusOfUserIDs allValues];
}

#pragma mark -
#pragma mark ### Registered Sessions ###

- (void)registerSession:(TCMMMSession *)aSession {
    NSMutableDictionary *sessionEntry=[I_registeredSessions objectForKey:[aSession sessionID]];
    if (!sessionEntry) {
        sessionEntry=[NSMutableDictionary dictionary];
        [sessionEntry setObject:aSession forKey:@"Session"];
        [sessionEntry setObject:[NSNumber numberWithInt:1] forKey:@"Count"];
        [I_registeredSessions setObject:sessionEntry forKey:[aSession sessionID]];
    } else {
        if (!([sessionEntry objectForKey:@"Session"]==aSession)) {
            DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"SessionRegistry: tried to register Session that differs from already registered Session");
            [sessionEntry setObject:aSession forKey:@"Session"];
        }
        [sessionEntry setObject:[NSNumber numberWithInt:[[sessionEntry objectForKey:@"Count"] intValue]+1] 
                         forKey:@"Count"];
    }
}

- (void)unregisterSession:(TCMMMSession *)aSession {
    NSMutableDictionary *sessionEntry=[I_registeredSessions objectForKey:[aSession sessionID]];
    NSAssert(sessionEntry,@"SessionRegistry: unregistered a Session that was not registered");
    int count=[[sessionEntry objectForKey:@"Count"] intValue]-1;
    if (count<=0) {
        [I_registeredSessions removeObjectForKey:[aSession sessionID]];
    } else {
        [sessionEntry setObject:[NSNumber numberWithInt:count] 
                         forKey:@"Count"];
    }
}

- (TCMMMSession *)referenceSessionForSession:(TCMMMSession *)aSession {
    NSMutableDictionary *sessionEntry=[I_registeredSessions objectForKey:[aSession sessionID]];
    if (sessionEntry) {
        TCMMMSession *session=[sessionEntry objectForKey:@"Session"];
        if ([aSession isServer]==[session isServer]) {
            // merge
            [session setFilename:[aSession filename]];
            [session setAccessState:[aSession accessState]];
            if (![aSession isServer]) {
                [session setIsSecure:[aSession isSecure]];
            }
        }
        return session;
    } else {
        return aSession;
    }
}


#pragma mark -
#pragma mark ### TCMMMStatusProfile interaction

- (void)TCM_validateVisibilityOfUserID:(NSString *)aUserID {
    NSMutableDictionary *status=[self statusOfUserID:aUserID];
    BOOL currentVisibility=([status objectForKey:@"isVisible"]!=nil);
    BOOL shouldSendNotification = [[status objectForKey:@"shouldSendVisibilityChangeNotification"] boolValue];
    [status removeObjectForKey:@"shouldSendVisibilityChangeNotification"];
    if ([[status objectForKey:TCMMMPresenceStatusKey] isEqualToString:TCMMMPresenceUnknownStatusValue])
        [status removeObjectForKey:@"InternalIsVisible"];
    BOOL newVisibility=(([status objectForKey:@"InternalIsVisible"]!=nil) || ([[status objectForKey:TCMMMPresenceSessionsKey] count] > 0));
    if (newVisibility!=currentVisibility) {
        if (newVisibility) {
            [status setObject:@(YES) forKey:@"isVisible"];
        } else {
            [status removeObjectForKey:@"isVisible"];
        }
        shouldSendNotification = YES;
    }
    if (shouldSendNotification) {
        [[NSNotificationCenter defaultCenter] postNotificationName:TCMMMPresenceManagerUserVisibilityDidChangeNotification object:self 
            userInfo:[NSDictionary dictionaryWithObjectsAndKeys:aUserID,TCMMMPresenceUserIDKey,[NSNumber numberWithBool:newVisibility],@"isVisible",nil]];
    }
}

// se also applicationConnectionURL of SEEConnectionManager
- (NSString *)myReachabilityURLString {
    TCMPortMapper *pm = [TCMPortMapper sharedInstance];
    TCMPortMapping *mapping = [[pm portMappings] anyObject];
    if ([pm externalIPAddress] && ![[pm externalIPAddress] isEqual:@"0.0.0.0"] && [mapping mappingStatus]==TCMPortMappingStatusMapped && [self isVisible]) {
        return [NSString stringWithFormat:@"see://%@:%d", [pm externalIPAddress],[mapping externalPort]];
    } else {
        return @"";
    }
}

- (void)broadcastMyReachability {
    NSString *reachabilityString = [self myReachabilityURLString];
    NSString *userID = [TCMMMUserManager myUserID];
    TCMMMStatusProfile *profile=nil;
    for (profile in I_statusProfilesInServerRole) {
        [profile sendReachabilityURLString:reachabilityString forUserID:userID];
    }
}

- (NSString *)reachabilityURLStringOfUserID:(NSString *)aUserID {
	NSString *result = [[[[self statusProfileForUserID:aUserID] session] userInfo] objectForKey:TCMMMPresenceReachabiltyURLKey];
	if ([[TCMMMUserManager myUserID] isEqualTo:aUserID]) {
		result = [self myReachabilityURLString];
	}
    return result;
}

- (BOOL)shouldDoFriendcasting {
	BOOL result = [[NSUserDefaults standardUserDefaults] boolForKey:AutoconnectPrefKey] &&
				  [self isVisible] &&
				  ![[TCMMMBEEPSessionManager sharedInstance] isNetworkingDisabled];
	return result;
}

- (void)sendReachabilityViaProfile:(TCMMMStatusProfile *)aProfile {
    if ([self shouldDoFriendcasting]) {
        [aProfile sendReachabilityURLString:[self myReachabilityURLString] forUserID:[TCMMMUserManager myUserID]];
        // send reachability for everyone that is connected to me currently and thinks he knows how he can be reached
        NSString *myPeerID = [[[aProfile session] userInfo] objectForKey:@"peerUserID"];
        NSEnumerator *beepSessions = [[[TCMMMBEEPSessionManager sharedInstance] allBEEPSessions] objectEnumerator];
        TCMBEEPSession *beepSession = nil;
        while ((beepSession = [beepSessions nextObject])) {
            NSDictionary *userInfo = [beepSession userInfo];
            NSString *peerUserID = [userInfo objectForKey:@"peerUserID"];
            if (peerUserID && ![peerUserID isEqualToString:myPeerID]) {
                NSString *reachabilityURL = [userInfo objectForKey:TCMMMPresenceReachabiltyURLKey];
                if (reachabilityURL) {
                    //NSLog(@"%s sending %@ for %@ to %@",__FUNCTION__,reachabilityURL,peerUserID,myPeerID);
                    [aProfile sendReachabilityURLString:reachabilityURL forUserID:peerUserID];
                }
            }
        }
    }
}

- (void)sendInitialStatusViaProfile:(TCMMMStatusProfile *)aProfile {
    [aProfile sendUserDidChangeNotification:[TCMMMUserManager me]];
    [aProfile sendVisibility:[self isVisible]];
	
    [aProfile sendIsFriendcasting:[self shouldDoFriendcasting]];
    [self sendReachabilityViaProfile:aProfile];
    
    NSEnumerator *sessions=[[self announcedSessions] objectEnumerator];
    TCMMMSession *session=nil;
    while ((session=[sessions nextObject])) {
        [aProfile announceSession:session];
    }
    // send reachability
    DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"%@",[[TCMMMBEEPSessionManager sharedInstance] description]);
}

- (void)profile:(TCMMMStatusProfile *)aProfile didReceiveVisibilityChange:(BOOL)isVisible {
    NSString *userID=[[[aProfile session] userInfo] objectForKey:@"peerUserID"];
    NSMutableDictionary *status=[self statusOfUserID:userID];
    if (isVisible) {
        [status setObject:@(YES) forKey:@"InternalIsVisible"];
    } else {
        [status removeObjectForKey:@"InternalIsVisible"];
    }
    [self TCM_validateVisibilityOfUserID:userID];
}

// the profile is always a profile in client role
- (void)profile:(TCMMMStatusProfile *)aProfile didReceiveFriendcastingChange:(BOOL)hasFriendCast {
    NSString *userID=[[[aProfile session] userInfo] objectForKey:@"peerUserID"];
    NSMutableDictionary *status=[self statusOfUserID:userID];
    if (hasFriendCast) {
        [status setObject:@(YES) forKey:@"hasFriendCast"];
		[aProfile requestReachability];
		[self sendReachabilityViaProfile:aProfile];
    } else {
        [status removeObjectForKey:@"hasFriendCast"];
        NSMutableDictionary *sessionUserInfo = [[aProfile session] userInfo];
        [sessionUserInfo removeObjectForKey:TCMMMPresenceReachabiltyURLKey];
    }
    // make sure the UI gets notified of that change
    [status setObject:[NSNumber numberWithBool:YES] forKey:@"shouldSendVisibilityChangeNotification"];
    [self TCM_validateVisibilityOfUserID:userID];
}

- (void)connectToAutoconnectURL:(NSString *)anURLString userID:(NSString *)aUserID autoconnectOriginUserID:(NSString *)anOriginUserID {
	if ([self shouldDoFriendcasting]) {
		if (![[TCMMMBEEPSessionManager sharedInstance] sessionForUserID:aUserID]) {
			// we have no session for this userID so let's connect
			NSDictionary *userInfo = @{@"URLString":anURLString,
									   TCMMMPresenceUserIDKey:aUserID,
									   @"isAutoConnect":@YES,
									   TCMMMPresenceAutoconnectOriginUserIDKey:anOriginUserID,};
			NSURL *URL = [NSURL URLWithString:anURLString];
			NSData *addressData=nil;
			[TCMMMBEEPSessionManager reducedURL:URL addressData:&addressData documentRequest:nil];
			TCMHost *host = nil;
			if (addressData) {
				host = [[TCMHost alloc] initWithAddressData:addressData port:[[URL port] intValue] userInfo:userInfo];
				//NSLog(@"%s connecting to host: %@",__FUNCTION__,host);
				[[TCMMMBEEPSessionManager sharedInstance] connectToHost:host];
			} else {
				host = [[TCMHost alloc] initWithName:[URL host] port:[[URL port] intValue] userInfo:userInfo];
				[host resolve];
				// give some time to resolve
				[[TCMMMBEEPSessionManager sharedInstance] performSelector:@selector(connectToHost:) withObject:host afterDelay:4.0];
			}
		}
	}
}

- (void)profile:(TCMMMStatusProfile *)aProfile didReceiveReachabilityURLString:(NSString *)anURLString forUserID:(NSString *)aUserID {
	NSMutableDictionary *sessionUserInfo = [[aProfile session] userInfo];
	NSString *userID=[sessionUserInfo objectForKey:@"peerUserID"];
	if ([userID isEqualToString:aUserID]) {
		TCMMMUser *user = [[TCMMMUserManager sharedInstance] userForUserID:userID];
		//NSLog(@"%s got a self information",__FUNCTION__);
		if ([anURLString isEqualToString:@""]) {
			[sessionUserInfo removeObjectForKey:TCMMMPresenceReachabiltyURLKey];
		} else {
			[sessionUserInfo setObject:anURLString forKey:TCMMMPresenceReachabiltyURLKey];
			if ([self shouldDoFriendcasting]) {
				// we got new personal information - so propagate this information to all others
				for (TCMMMStatusProfile *profile in I_statusProfilesInServerRole) {
					if (![[[[profile session] userInfo] objectForKey:@"peerUserID"] isEqualToString:aUserID]) {
						[profile sendReachabilityURLString:anURLString forUserID:aUserID];
					}
				}
			}
		}
		
		if (user) {
			[[NSNotificationCenter defaultCenter] postNotificationName:TCMMMUserManagerUserDidChangeNotification object:user];
		}
		
	} else {
		if ([self shouldDoFriendcasting]) {
			//NSLog(@"%s got information about a third party: %@ %@",__FUNCTION__,anURLString,aUserID);
			// see if we already have a connection to that userID, if not initiate connection to that user
			NSMutableDictionary *status = [self statusOfUserID:userID];
			if ([[NSUserDefaults standardUserDefaults] boolForKey:AutoconnectPrefKey]) {
				if ([[status objectForKey:@"shouldAutoConnect"] boolValue]) {
					// delay a little bit so we don't connect to friendcasting before we connect using bonjour
					[NSOperationQueue TCM_performBlockOnMainQueue:^{
						[self connectToAutoconnectURL:anURLString userID:aUserID autoconnectOriginUserID:userID];
					} afterDelay:0.3];
				}
			}
		}
	}
}

- (void)profileDidReceiveReachabilityRequest:(TCMMMStatusProfile *)aProfile {
    //NSLog(@"%s",__FUNCTION__);
    [self sendReachabilityViaProfile:aProfile];
}

- (void)setShouldAutoAcceptInviteToSessionID:(NSString *)aSessionID {
    [I_autoAcceptInviteSessions setObject:[NSNumber numberWithBool:YES] forKey:aSessionID];
}
// this call also removes the autoacceptflag
- (BOOL)shouldAutoAcceptInviteToSessionID:(NSString *)aSessionID {
    if ([I_autoAcceptInviteSessions objectForKey:aSessionID]) {
        [I_autoAcceptInviteSessions removeObjectForKey:aSessionID];
        return YES;
    } else {
        return NO;
    }
}


- (void)profile:(TCMMMStatusProfile *)aProfile didReceiveToken:(NSString *)aToken {
    NSString *userID=[[[aProfile session] userInfo] objectForKey:@"peerUserID"];
    if (userID && aToken) {
        [[NSNotificationCenter defaultCenter] postNotificationName:TCMMMPresenceManagerDidReceiveTokenNotification object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:userID,TCMMMPresenceUserIDKey,aToken,@"token",nil]];
    }
}


- (void)profile:(TCMMMStatusProfile *)aProfile didReceiveAnnouncedSession:(TCMMMSession *)aSession
{
    DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"didReceiveAnnouncedSession: %@",[aSession description]);
    NSString *userID=[[[aProfile session] userInfo] objectForKey:@"peerUserID"];
    NSMutableDictionary *status=[self statusOfUserID:userID];
    NSMutableDictionary *sessions=[status objectForKey:TCMMMPresenceSessionsKey];
    TCMMMSession *session=[self referenceSessionForSession:aSession];
    if (![session isServer]) {
        if (![sessions objectForKey:[session sessionID]]) {
            [self registerSession:session];
            [sessions setObject:session forKey:[session sessionID]];
			NSArray *sessionValues = [sessions allValues];
			if (sessionValues) {
				NSSortDescriptor *filenameSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"filename" ascending:YES];
				NSArray * orderedSessions = [sessionValues sortedArrayUsingDescriptors:@[filenameSortDescriptor]];
				[status setObject:orderedSessions forKey:TCMMMPresenceOrderedSessionsKey];
			}
            [self TCM_validateVisibilityOfUserID:userID];
        }
        NSMutableDictionary *userInfo=[NSMutableDictionary dictionaryWithObjectsAndKeys:userID,TCMMMPresenceUserIDKey,sessions,TCMMMPresenceSessionsKey,nil];
        [userInfo setObject:aSession forKey:@"AnnouncedSession"];
        [[NSNotificationCenter defaultCenter] postNotificationName:TCMMMPresenceManagerUserSessionsDidChangeNotification object:self 
                userInfo:userInfo];
    }
}

- (void)profile:(TCMMMStatusProfile *)aProfile didReceiveConcealedSessionID:(NSString *)anID
{
    DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"didReceiveConcealSessionID: %@",anID);
    NSString *userID=[[[aProfile session] userInfo] objectForKey:@"peerUserID"];
    NSMutableDictionary *status=[self statusOfUserID:userID];
    NSMutableDictionary *sessions=[status objectForKey:TCMMMPresenceSessionsKey];
    TCMMMSession *session=[sessions objectForKey:anID];
    if (session) {
        [sessions removeObjectForKey:anID];
        [status setObject:[[sessions allValues] sortedArrayUsingDescriptors:@[[[NSSortDescriptor alloc] initWithKey:@"filename" ascending:YES comparator:^NSComparisonResult(id obj1, id obj2) {
			return [obj1 compare:obj2 options:NSDiacriticInsensitiveSearch | NSCaseInsensitiveSearch | NSWidthInsensitiveSearch | NSForcedOrderingSearch | NSNumericSearch];
		}]]] forKey:TCMMMPresenceOrderedSessionsKey];
        [self unregisterSession:session];
    }
    NSMutableDictionary *userInfo=[NSMutableDictionary dictionaryWithObjectsAndKeys:userID,TCMMMPresenceUserIDKey,sessions,TCMMMPresenceSessionsKey,nil];
    [userInfo setObject:anID forKey:@"ConcealedSessionID"];
    [[NSNotificationCenter defaultCenter] postNotificationName:TCMMMPresenceManagerUserSessionsDidChangeNotification object:self 
            userInfo:userInfo];
    [self TCM_validateVisibilityOfUserID:userID];
}

- (void)profile:(TCMBEEPProfile *)aProfile didFailWithError:(NSError *)anError {
    // remove status profile, and inform the rest
    NSString *userID=[[[aProfile session] userInfo] objectForKey:@"peerUserID"];
    
    [aProfile setDelegate:nil];
    if ([I_statusProfilesInServerRole containsObject:aProfile]) {
        [I_statusProfilesInServerRole removeObject:aProfile];
    } else {
        NSMutableDictionary *status=[self statusOfUserID:userID];
        [status removeObjectForKey:TCMMMPresenceStatusProfileKey];
        [status setObject:TCMMMPresenceUnknownStatusValue forKey:TCMMMPresenceStatusKey];
        NSEnumerator *sessions=[[status objectForKey:TCMMMPresenceSessionsKey] objectEnumerator];
        TCMMMSession *session=nil;
        while ((session=[sessions nextObject])) {
            [self unregisterSession:session];
        }
        [status setObject:[NSMutableDictionary dictionary] forKey:TCMMMPresenceSessionsKey];
        [status setObject:[NSArray array] forKey:TCMMMPresenceOrderedSessionsKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:TCMMMPresenceManagerUserSessionsDidChangeNotification object:self 
                userInfo:[NSDictionary dictionaryWithObjectsAndKeys:userID,TCMMMPresenceUserIDKey,[status objectForKey:TCMMMPresenceSessionsKey],TCMMMPresenceSessionsKey,nil]];
        TCMBEEPSession *beepSession=[[TCMMMBEEPSessionManager sharedInstance] sessionForUserID:userID];
        if (beepSession) {
            [beepSession startChannelWithProfileURIs:[NSArray arrayWithObject:@"http://www.codingmonkeys.de/BEEP/TCMMMStatus"] andData:[NSArray arrayWithObject:[TCMMMStatusProfile defaultInitializationData]] sender:self];
        } else {
            if ([[status objectForKey:TCMMMPresenceNetServicesKey] count]) {
                [self performSelector:@selector(connectToRendezvousUserID:) withObject:userID afterDelay:0.3];
            }
        }
    }
    [self TCM_validateVisibilityOfUserID:userID];
}

- (void)connectToRendezvousUserID:(NSString *)aUserID {
    NSDictionary *status=[self statusOfUserID:aUserID];
    NSEnumerator *netServices = [[status objectForKey:TCMMMPresenceNetServicesKey] objectEnumerator];
    id netService = nil;
    while ((netService=[netServices nextObject])) {
        if (![[status objectForKey:TCMMMPresenceStatusKey] isEqualToString:TCMMMPresenceKnownStatusValue]) {
            [[TCMMMBEEPSessionManager sharedInstance] connectToNetService:netService];
        }
    }
}

#pragma mark -
#pragma mark ### TCMMMBEEPSessionManager callbacks ###

#pragma mark -
- (void)TCM_didAcceptSession:(NSNotification *)aNotification 
{
    TCMBEEPSession *session=[[aNotification userInfo] objectForKey:@"Session"];
    NSString *userID=[[session userInfo] objectForKey:@"peerUserID"];
    NSMutableDictionary *statusOfUserID=[self statusOfUserID:userID];
    if ([[statusOfUserID objectForKey:TCMMMPresenceStatusKey] isEqualToString:TCMMMPresenceUnknownStatusValue]) {
        DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"starting StatusProfile with: %@", userID);
        [session startChannelWithProfileURIs:[NSArray arrayWithObject:@"http://www.codingmonkeys.de/BEEP/TCMMMStatus"] andData:[NSArray arrayWithObject:[TCMMMStatusProfile defaultInitializationData]] sender:self];
    }
    [statusOfUserID setObject:[NSNumber numberWithBool:YES] forKey:@"shouldSendVisibilityChangeNotification"];    
}

- (void)TCM_didEndSession:(NSNotification *)aNotification 
{
//    TCMBEEPSession *session=[[aNotification userInfo] objectForKey:@"Session"];
    
}

- (void)BEEPSession:(TCMBEEPSession *)aBEEPSession didOpenChannelWithProfile:(TCMBEEPProfile *)aProfile data:(NSData *)inData
{
    [aProfile setDelegate:self];
    [aProfile handleInitializationData:inData];
    if ([aProfile isServer]) {
        DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"acceptStatusProfile!");
        [self sendInitialStatusViaProfile:(TCMMMStatusProfile *)aProfile];
        [I_statusProfilesInServerRole addObject:aProfile];
    } else {
        DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"Got status Channel!");
        NSString *userID=[[[aProfile session] userInfo] objectForKey:@"peerUserID"];
        NSMutableDictionary *statusOfUserID=[self statusOfUserID:userID];
        
        if ([[statusOfUserID objectForKey:TCMMMPresenceStatusKey] isEqualToString:TCMMMPresenceKnownStatusValue]) {
            DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"Got status profile albeit having one for User: %@",userID);
        } else {
            DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"Got status profile without trying to connect to User: %@",userID);
        }
        [statusOfUserID setObject:TCMMMPresenceKnownStatusValue forKey:TCMMMPresenceStatusKey];
        [statusOfUserID setObject:aProfile forKey:TCMMMPresenceStatusProfileKey];
    }
}

- (NSMutableDictionary *)BEEPSession:(TCMBEEPSession *)aBEEPSession willSendReply:(NSMutableDictionary *)aReply forChannelRequests:(NSArray *)aRequests {
    //NSLog(@"%s %@",__FUNCTION__,aReply);
    [aReply setObject:[TCMMMStatusProfile defaultInitializationData] forKey:@"Data"];
    return aReply;
}

#pragma mark -
#pragma mark ### TCMRendezvousBrowser Delegate ###
- (void)rendezvousBrowserWillSearch:(TCMRendezvousBrowser *)aBrowser {

}

- (void)rendezvousBrowserDidStopSearch:(TCMRendezvousBrowser *)aBrowser {

}

- (void)rendezvousBrowser:(TCMRendezvousBrowser *)aBrowser didNotSearch:(NSError *)anError {
    DEBUGLOG(@"RendezvousLogDomain", AllLogLevel, @"Mist: %@",anError);
}

- (void)rendezvousBrowser:(TCMRendezvousBrowser *)aBrowser didFindService:(NSNetService *)aNetService {
    DEBUGLOG(@"RendezvousLogDomain", AllLogLevel, @"foundservice: %@",aNetService);
}

- (void)rendezvousBrowser:(TCMRendezvousBrowser *)aBrowser didResolveService:(NSNetService *)aNetService {
//    [I_data addObject:[NSMutableDictionary dictionaryWithObject:[NSString stringWithFormat:@"resolved %@%@",[aNetService name],[aNetService domain]] forKey:@"serviceName"]];
    NSString *userID = [[aNetService TXTRecordDictionary] objectForKey:TCMMMPresenceTXTRecordUserIDKey];
    if (userID && ![userID isEqualTo:[TCMMMUserManager myUserID]]) {
        [I_foundUserIDs addObject:userID];
        NSMutableDictionary *status=[self statusOfUserID:userID];
        [[status objectForKey:TCMMMPresenceNetServicesKey] addObject:aNetService];
        [[NSNotificationCenter defaultCenter] postNotificationName:TCMMMPresenceManagerUserRendezvousStatusDidChangeNotification object:self userInfo:[NSDictionary dictionaryWithObject:[NSArray arrayWithObject:userID] forKey:@"UserIDs"]];
        if (![[status objectForKey:TCMMMPresenceStatusKey] isEqualToString:TCMMMPresenceKnownStatusValue]) {
            [self performSelector:@selector(connectToRendezvousUserID:) withObject:userID afterDelay:0.3];
        }
    }
}

- (void)resolveUnconnectedFoundNetServices:(NSTimer *)aTimer {
    NSString *userID = nil;
    for (userID in I_foundUserIDs) {
        NSMutableDictionary *status=[self statusOfUserID:userID];
        if (![[status objectForKey:TCMMMPresenceStatusKey] isEqualToString:TCMMMPresenceKnownStatusValue]) {
            NSEnumerator *netServices = [[status objectForKey:TCMMMPresenceNetServicesKey] objectEnumerator];
            id netService = nil;
            while ((netService=[netServices nextObject])) {
                [netService resolveWithTimeout:15.];
                [self performSelector:@selector(connectToRendezvousUserID:) withObject:userID afterDelay:0.3];
            }
        }
    }
}

- (void)rendezvousBrowser:(TCMRendezvousBrowser *)aBrowser didChangeCountOfResolved:(BOOL)wasResolved service:(NSNetService *)aNetService {
    DEBUGLOG(@"RendezvousLogDomain", AllLogLevel, @"ChangedCountOfService: %@",aNetService);
    if (wasResolved) {
//        NSLog(@"Was resolved");
        NSString *userID = [[aNetService TXTRecordDictionary] objectForKey:TCMMMPresenceTXTRecordUserIDKey];
        if (userID && ![userID isEqualTo:[TCMMMUserManager myUserID]]) {
//            NSLog(@"has userID:%@",userID);
            NSMutableDictionary *status=[self statusOfUserID:userID];
            if (![[status objectForKey:TCMMMPresenceStatusKey] isEqualToString:TCMMMPresenceKnownStatusValue]) {
                [self performSelector:@selector(connectToRendezvousUserID:) withObject:userID afterDelay:0.3];
            }
        }
    }
}


- (void)rendezvousBrowser:(TCMRendezvousBrowser *)aBrowser didRemoveResolved:(BOOL)wasResolved service:(NSNetService *)aNetService {
    DEBUGLOG(@"RendezvousLogDomain", AllLogLevel, @"Removed Service: %@",aNetService);
    if (wasResolved) {
        NSString *userID = [[aNetService TXTRecordDictionary] objectForKey:TCMMMPresenceTXTRecordUserIDKey];
        if (userID){
            [I_foundUserIDs removeObject:userID];
            NSMutableDictionary *status=[self statusOfUserID:userID];
            [[status objectForKey:TCMMMPresenceNetServicesKey] removeObject:aNetService];
            [[NSNotificationCenter defaultCenter] postNotificationName:TCMMMPresenceManagerUserRendezvousStatusDidChangeNotification object:self userInfo:[NSDictionary dictionaryWithObject:[NSArray arrayWithObject:userID] forKey:@"UserIDs"]];
        }
    }
}



#pragma mark -
#pragma mark ### Published NetService Delegate ###

// Error handling code
- (void)handleError:(NSNumber *)error withService:(NSNetService *)service
{
    // Handle error here
    if ([error intValue]==NSNetServicesCollisionError) {
		I_serviceNameAddition++;
        [self TCM_validateServiceAnnouncement];
    } else {
        DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"An error occurred with service %@.%@.%@, error code = %@",
            [service name], [service type], [service domain], error);
    }
}

// Sent when the service is about to publish
- (void)netServiceWillPublish:(NSNetService *)netService
{
    DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"netServiceWillPublish: %@",netService);
    // You may want to do something here, such as updating a user interface
}


// Sent if publication fails
- (void)netService:(NSNetService *)netService
        didNotPublish:(NSDictionary *)errorDict
{
    I_flags.serviceIsPublished=NO;
    [self handleError:[errorDict objectForKey:NSNetServicesErrorCode] withService:netService];
}

- (void)netServiceDidPublish:(NSNetService *)netService {
    DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"netServiceDidPublish: %@",netService);
}

// Sent when the service stops
- (void)netServiceDidStop:(NSNetService *)netService
{
    I_flags.serviceIsPublished=NO;
    DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"netServiceDidStop: %@", netService);
    // You may want to do something here, such as updating a user interface
	I_serviceNameAddition = 0;
}

@end
