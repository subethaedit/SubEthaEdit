//
//  TCMMMPresenceManager.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Fri Feb 27 2004.
//  Copyright (c) 2004-2007 TheCodingMonkeys. All rights reserved.
//

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

@interface TCMMMPresenceManager (TCMMMPresenceManagerPrivateAdditions)

- (void)TCM_validateServiceAnnouncement;
- (void)sendReachabilityViaProfile:(TCMMMStatusProfile *)aProfile;

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
        @"shouldSendVisibilityChangeNotification" => nil | NSNumber "YES"  // for internal use only
        @"shouldAutoConnect" => nil | NSNumber "YES" // if we autoconnect to reachability infos of that user - == subscribe to friendcast
        @"hasFriendCast" => nil | NSNumber "YES"
"*/


@implementation TCMMMPresenceManager

+ (TCMMMPresenceManager *)sharedInstance {
    if (!sharedInstance) {
        sharedInstance = [self new];
    }
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    if (self) {
        I_statusOfUserIDs = [NSMutableDictionary new];
        I_statusProfilesInServerRole = [NSMutableSet new];
        I_announcedSessions  = [NSMutableDictionary new];
        I_registeredSessions = [NSMutableDictionary new];
        I_flags.serviceIsPublished=NO;
        I_foundUserIDs=[NSMutableSet new];
        sharedInstance = self;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(TCM_didAcceptSession:) name:TCMMMBEEPSessionManagerDidAcceptSessionNotification object:[TCMMMBEEPSessionManager sharedInstance]]; 
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(TCM_didEndSession:) name:TCMMMBEEPSessionManagerSessionDidEndNotification object:[TCMMMBEEPSessionManager sharedInstance]];
        I_resolveUnconnectedFoundNetServicesTimer = [NSTimer scheduledTimerWithTimeInterval:90. target:self selector:@selector(resolveUnconnectedFoundNetServices:) userInfo:nil repeats:YES];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(broadcastMyReachability) name:TCMPortMapperDidFinishWorkNotification object:[TCMPortMapper sharedInstance]];
        // bind to user defaults
        [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:[@"values." stringByAppendingString:AutoconnectPrefKey] options:0 context:nil];
        
    }
    return self;
}

- (void)observeValueForKeyPath:(NSString *)aKeyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    // send new friendcasting status
    NSEnumerator *profiles = [I_statusProfilesInServerRole objectEnumerator];
    TCMMMStatusProfile *profile = nil;
    BOOL hasFriendCast = [[object valueForKeyPath:aKeyPath] boolValue];
    while ((profile = [profiles nextObject])) {
        [profile sendIsFriendcasting:hasFriendCast];
        if (hasFriendCast) {
            // also send the current friendcast information
            [self sendReachabilityViaProfile:profile];
        }
    }
}

- (void)dealloc 
{
    [I_resolveUnconnectedFoundNetServicesTimer invalidate];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [I_foundUserIDs release];
    [I_announcedSessions release];
    [I_registeredSessions release];
    [I_statusOfUserIDs release];
    [I_netService release];
    [I_browser release];
    [super dealloc];
}

- (void)stopRendezvousBrowsing {
    [I_browser setDelegate:nil];
    [I_browser stopSearch];
    [I_browser release];
    NSString *userID=nil;
    NSEnumerator *userIDs=[I_foundUserIDs objectEnumerator];
    while ((userID=[userIDs nextObject])) {
        NSMutableDictionary *status=[self statusOfUserID:userID];
        [[status objectForKey:@"NetServices"] removeAllObjects];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:TCMMMPresenceManagerUserRendezvousStatusDidChangeNotification object:self userInfo:[NSDictionary dictionaryWithObject:[I_foundUserIDs allObjects] forKey:@"UserIDs"]];
    I_browser=nil;
}

- (void)startRendezvousBrowsing {
    [self stopRendezvousBrowsing];
    I_browser=[[TCMRendezvousBrowser alloc] initWithServiceType:@"_see._tcp." domain:@""];
    [I_browser setDelegate:self];
    [I_browser startSearch];
}

- (NSString *)serviceName {
    NSString *computerName = (NSString *)SCDynamicStoreCopyComputerName(NULL,NULL);
    return [NSString stringWithFormat:@"%@@%@",NSUserName(),[computerName autorelease]];
}

- (void)TCM_validateServiceAnnouncement {
    // Announce ourselves via rendezvous
    
    if (!I_netService) {
        I_netService=[[NSNetService alloc] initWithDomain:@"" type:@"_see._tcp." name:[self serviceName] port:[[TCMMMBEEPSessionManager sharedInstance] listeningPort]];
        [I_netService setDelegate:self];
    }
    
    TCMMMUser *me=[[TCMMMUserManager sharedInstance] me];
    if ((I_flags.isVisible || [I_announcedSessions count]>0) && !I_flags.serviceIsPublished) {
        [I_netService setTXTRecordByArray:
            [NSArray arrayWithObjects:
                @"txtvers=1",
                [NSString stringWithFormat:@"userid=%@",[me userID]],
                [NSString stringWithFormat:@"name=%@",[me name]],
                @"version=2",
                nil]];
//        [I_netService setProtocolSpecificInformation:[NSString stringWithFormat:@"txtvers=1\001name=%@\001userid=%@\001version=2",[me name],[me userID]]];
        [I_netService publish];
        I_flags.serviceIsPublished = YES;
        [[NSNotificationCenter defaultCenter] postNotificationName:TCMMMPresenceManagerServiceAnnouncementDidChangeNotification object:self];
    } else if (!(I_flags.isVisible || [I_announcedSessions count]>0) && I_flags.serviceIsPublished){
        [I_netService stop];
        [[NSNotificationCenter defaultCenter] postNotificationName:TCMMMPresenceManagerServiceAnnouncementDidChangeNotification object:self];
    } else if (I_flags.serviceIsPublished) {
//      causes severe mDNSResponderCrash!
//        NSString *txtRecord=[NSString stringWithFormat:@"txtvers=1\001name=%@\001userid=%@\001docs=%d\001version=2",[me name],[me ID],[I_announcedSessions count]];
//        NSLog(@"Updating record with:%@",txtRecord);
//        [I_netService setProtocolSpecificInformation:txtRecord];
    }
}

- (BOOL)isVisible {
    return I_flags.isVisible;
}

- (void)setVisible:(BOOL)aFlag
{
    I_flags.isVisible = aFlag;
    [self TCM_validateServiceAnnouncement];
    NSEnumerator *profiles=[I_statusProfilesInServerRole objectEnumerator];
    TCMMMStatusProfile *profile=nil;
    while ((profile=[profiles nextObject])) {
        [profile sendVisibility:aFlag];
    }
    [[TCMMMBEEPSessionManager sharedInstance] validateListener];
}

- (void)setShouldAutoconnect:(BOOL)aFlag forUserID:(NSString *)aUserID {
    NSMutableDictionary *status = [self statusOfUserID:aUserID];
    if (aFlag) {
        [status setObject:[NSNumber numberWithBool:YES] forKey:@"shouldAutoConnect"];
        [[status objectForKey:@"StatusProfile"] requestReachability];
    } else {
        [status removeObjectForKey:@"shouldAutoConnect"];
    }
}


- (NSMutableDictionary *)statusOfUserID:(NSString *)aUserID {
    if (!aUserID) return nil;
    NSMutableDictionary *statusOfUserID=[I_statusOfUserIDs objectForKey:aUserID];
    if (!statusOfUserID) {
        statusOfUserID=[NSMutableDictionary dictionary];
        [statusOfUserID setObject:@"NoStatus" forKey:@"Status"];
        [statusOfUserID setObject:aUserID     forKey:@"UserID"];
        [statusOfUserID setObject:[NSMutableDictionary dictionary] forKey:@"Sessions"];
        [statusOfUserID setObject:[NSArray array] forKey:@"OrderedSessions"];
        [statusOfUserID setObject:[NSMutableSet set] forKey:@"NetServices"];
        [I_statusOfUserIDs setObject:statusOfUserID forKey:aUserID];
    }
    return statusOfUserID;
}

- (TCMMMStatusProfile *)statusProfileForUserID:(NSString *)aUserID {
    NSDictionary *status=[self statusOfUserID:aUserID];
    if ([[status objectForKey:@"Status"] isEqualToString:@"GotStatus"]) {
        return [status objectForKey:@"StatusProfile"];
    } else {
        return nil;
    }
}


- (NSDictionary *)announcedSessions {
    return I_announcedSessions;
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
    NSEnumerator *profiles=[I_statusProfilesInServerRole objectEnumerator];
    TCMMMStatusProfile *profile=nil;
    while ((profile=[profiles nextObject])) {
        [profile sendUserDidChangeNotification:[TCMMMUserManager me]];
    }
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
    if ([[status objectForKey:@"Status"] isEqualToString:@"NoStatus"])
        [status removeObjectForKey:@"InternalIsVisible"];
    BOOL newVisibility=(([status objectForKey:@"InternalIsVisible"]!=nil) || ([[status objectForKey:@"Sessions"] count] > 0));
    if (newVisibility!=currentVisibility) {
        if (newVisibility) {
            [status setObject:[NSNumber numberWithBool:YES] forKey:@"isVisible"];
        } else {
            [status removeObjectForKey:@"isVisible"];
        }
        shouldSendNotification = YES;
    }
    if (shouldSendNotification) {
        [[NSNotificationCenter defaultCenter] postNotificationName:TCMMMPresenceManagerUserVisibilityDidChangeNotification object:self 
            userInfo:[NSDictionary dictionaryWithObjectsAndKeys:aUserID,@"UserID",[NSNumber numberWithBool:newVisibility],@"isVisible",nil]];
    }
}

- (NSString *)myReachabilityURLString {
    TCMPortMapper *pm = [TCMPortMapper sharedInstance];
    TCMPortMapping *mapping = [[pm portMappings] anyObject];
    if ([mapping mappingStatus]==TCMPortMappingStatusMapped) {
        return [NSString stringWithFormat:@"see://%@:%d", [pm externalIPAddress],[mapping externalPort]];
    } else {
        return @"";
    }
}

- (void)broadcastMyReachability {
    NSString *reachabilityString = [self myReachabilityURLString];
    NSString *userID = [TCMMMUserManager myUserID];
    NSEnumerator *profiles=[I_statusProfilesInServerRole objectEnumerator];
    TCMMMStatusProfile *profile=nil;
    while ((profile=[profiles nextObject])) {
        [profile sendReachabilityURLString:reachabilityString forUserID:userID];
    }
}

- (void)sendReachabilityViaProfile:(TCMMMStatusProfile *)aProfile {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:AutoconnectPrefKey]) {
        [aProfile sendReachabilityURLString:[self myReachabilityURLString] forUserID:[TCMMMUserManager myUserID]];
        // send reachability for everyone that is connected to me currently and thinks he knows how he can be reached
        NSString *myPeerID = [[[aProfile session] userInfo] objectForKey:@"peerUserID"];
        NSEnumerator *beepSessions = [[[TCMMMBEEPSessionManager sharedInstance] allBEEPSessions] objectEnumerator];
        TCMBEEPSession *beepSession = nil;
        while ((beepSession = [beepSessions nextObject])) {
            NSDictionary *userInfo = [beepSession userInfo];
            NSString *peerUserID = [userInfo objectForKey:@"peerUserID"];
            if (peerUserID && ![peerUserID isEqualToString:myPeerID]) {
                NSString *reachabilityURL = [userInfo objectForKey:@"ReachabilityURL"];
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
    [aProfile sendIsFriendcasting:[[NSUserDefaults standardUserDefaults] boolForKey:AutoconnectPrefKey]];
    [aProfile sendVisibility:[self isVisible]];
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
        [status setObject:[NSNumber numberWithBool:YES] forKey:@"InternalIsVisible"];
    } else {
        [status removeObjectForKey:@"InternalIsVisible"];
    }
    [self TCM_validateVisibilityOfUserID:userID];
}

- (void)profile:(TCMMMStatusProfile *)aProfile didReceiveFriendcastingChange:(BOOL)hasFriendCast {
    NSString *userID=[[[aProfile session] userInfo] objectForKey:@"peerUserID"];
    NSMutableDictionary *status=[self statusOfUserID:userID];
    if (hasFriendCast) {
        [status setObject:[NSNumber numberWithBool:YES] forKey:@"hasFriendCast"];
    } else {
        [status removeObjectForKey:@"hasFriendCast"];
        NSMutableDictionary *sessionUserInfo = [[aProfile session] userInfo];
        [sessionUserInfo removeObjectForKey:@"ReachabilityURL"];
    }
    // make sure the UI gets notified of that change
    [status setObject:[NSNumber numberWithBool:YES] forKey:@"shouldSendVisibilityChangeNotification"];
    [self TCM_validateVisibilityOfUserID:userID];
}


- (void)profile:(TCMMMStatusProfile *)aProfile didReceiveReachabilityURLString:(NSString *)anURLString forUserID:(NSString *)aUserID {
    NSMutableDictionary *sessionUserInfo = [[aProfile session] userInfo];
    NSString *userID=[sessionUserInfo objectForKey:@"peerUserID"];
    if ([userID isEqualToString:aUserID]) {
        //NSLog(@"%s got a self information",__FUNCTION__);
        if ([anURLString isEqualToString:@""]) {
            [sessionUserInfo removeObjectForKey:@"ReachabilityURL"];
        } else {
            [sessionUserInfo setObject:anURLString forKey:@"ReachabilityURL"];
            // we got new personal information - so propagate this information to all others
            NSEnumerator *profiles = [I_statusProfilesInServerRole objectEnumerator];
            TCMMMStatusProfile *profile = nil;
            while ((profile = [profiles nextObject])) {
                if (![[[[profile session] userInfo] objectForKey:@"peerUserID"] isEqualToString:aUserID]) {
                    [profile sendReachabilityURLString:anURLString forUserID:aUserID];
                }
            }
        }
    } else {
        //NSLog(@"%s got information about a third party: %@ %@",__FUNCTION__,anURLString,aUserID);
        // see if we already have a connection to that userID, if not initiate connection to that user
        NSMutableDictionary *status = [self statusOfUserID:userID];
        if ([[NSUserDefaults standardUserDefaults] boolForKey:AutoconnectPrefKey]) {
            if ([[status objectForKey:@"shouldAutoConnect"] boolValue]) {
                // TODO: if we connected to that user manually
                if (![[TCMMMBEEPSessionManager sharedInstance] sessionForUserID:aUserID]) {
                    // we have no session for this userID so let's connect
                    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:anURLString,@"URLString",aUserID,@"UserID",[NSNumber numberWithBool:YES],@"isAutoConnect",nil];
                    NSURL *URL = [NSURL URLWithString:anURLString];
                    NSData *addressData=nil;
                    [TCMMMBEEPSessionManager reducedURL:URL addressData:&addressData documentRequest:nil];
                    TCMHost *host = nil;
                    if (addressData) {
                        host = [[[TCMHost alloc] initWithAddressData:addressData port:[[URL port] intValue] userInfo:userInfo] autorelease];
                        //NSLog(@"%s connecting to host: %@",__FUNCTION__,host);
                        [[TCMMMBEEPSessionManager sharedInstance] connectToHost:host];
                    } else {
                        host = [[[TCMHost alloc] initWithName:[URL host] port:[[URL port] intValue] userInfo:userInfo] autorelease];
                        [host resolve];
                        // give him some time to resolve
                        [[TCMMMBEEPSessionManager sharedInstance] performSelector:@selector(connectToHost:) withObject:host afterDelay:4.0];
                    }
                }
            }
        }
    }
}

- (void)profileDidReceiveReachabilityRequest:(TCMMMStatusProfile *)aProfile {
    //NSLog(@"%s",__FUNCTION__);
    [self sendReachabilityViaProfile:aProfile];
}

- (void)profile:(TCMMMStatusProfile *)aProfile didReceiveAnnouncedSession:(TCMMMSession *)aSession
{
    DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"didReceiveAnnouncedSession: %@",[aSession description]);
    NSString *userID=[[[aProfile session] userInfo] objectForKey:@"peerUserID"];
    NSMutableDictionary *status=[self statusOfUserID:userID];
    NSMutableDictionary *sessions=[status objectForKey:@"Sessions"];
    TCMMMSession *session=[self referenceSessionForSession:aSession];
    if (![session isServer]) {
        if (![sessions objectForKey:[session sessionID]]) {
            [self registerSession:session];
            [sessions setObject:session forKey:[session sessionID]];
            [status setObject:[[sessions allValues] sortedArrayUsingDescriptors:[NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:@"filename" ascending:YES] autorelease]]] forKey:@"OrderedSessions"];
            [self TCM_validateVisibilityOfUserID:userID];
        }
        NSMutableDictionary *userInfo=[NSMutableDictionary dictionaryWithObjectsAndKeys:userID,@"UserID",sessions,@"Sessions",nil];
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
    NSMutableDictionary *sessions=[status objectForKey:@"Sessions"];
    TCMMMSession *session=[sessions objectForKey:anID];
    if (session) {
        [sessions removeObjectForKey:anID];
        [status setObject:[[sessions allValues] sortedArrayUsingDescriptors:[NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:@"filename" ascending:YES] autorelease]]] forKey:@"OrderedSessions"];
        [self unregisterSession:session];
    }
    NSMutableDictionary *userInfo=[NSMutableDictionary dictionaryWithObjectsAndKeys:userID,@"UserID",sessions,@"Sessions",nil];
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
        [status removeObjectForKey:@"StatusProfile"];
        [status setObject:@"NoStatus" forKey:@"Status"];
        NSEnumerator *sessions=[[status objectForKey:@"Sessions"] objectEnumerator];
        TCMMMSession *session=nil;
        while ((session=[sessions nextObject])) {
            [self unregisterSession:session];
        }
        [status setObject:[NSMutableDictionary dictionary] forKey:@"Sessions"];
        [status setObject:[NSArray array] forKey:@"OrderedSessions"];
        [[NSNotificationCenter defaultCenter] postNotificationName:TCMMMPresenceManagerUserSessionsDidChangeNotification object:self 
                userInfo:[NSDictionary dictionaryWithObjectsAndKeys:userID,@"UserID",[status objectForKey:@"Sessions"],@"Sessions",nil]];
        TCMBEEPSession *beepSession=[[TCMMMBEEPSessionManager sharedInstance] sessionForUserID:userID];
        if (beepSession) {
            [beepSession startChannelWithProfileURIs:[NSArray arrayWithObject:@"http://www.codingmonkeys.de/BEEP/TCMMMStatus"] andData:[NSArray arrayWithObject:[TCMMMStatusProfile defaultInitializationData]] sender:self];
        } else {
            if ([[status objectForKey:@"NetServices"] count]) {
                [self performSelector:@selector(connectToRendezvousUserID:) withObject:userID afterDelay:0.3];
            }
        }
    }
    [self TCM_validateVisibilityOfUserID:userID];
}

- (void)connectToRendezvousUserID:(NSString *)aUserID {
    NSDictionary *status=[self statusOfUserID:aUserID];
    NSEnumerator *netServices = [[status objectForKey:@"NetServices"] objectEnumerator];
    id netService = nil;
    while ((netService=[netServices nextObject])) {
        if (![[status objectForKey:@"Status"] isEqualToString:@"GotStatus"]) {
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
    if ([[statusOfUserID objectForKey:@"Status"] isEqualToString:@"NoStatus"]) {
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
        
        if ([[statusOfUserID objectForKey:@"Status"] isEqualToString:@"GotStatus"]) {
            DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"Got status profile albeit having one for User: %@",userID);
        } else {
            DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"Got status profile without trying to connect to User: %@",userID);
        }
        [statusOfUserID setObject:@"GotStatus" forKey:@"Status"];
        [statusOfUserID setObject:aProfile forKey:@"StatusProfile"];
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
    NSString *userID = [[aNetService TXTRecordDictionary] objectForKey:@"userid"];
    if (userID && ![userID isEqualTo:[TCMMMUserManager myUserID]]) {
        [I_foundUserIDs addObject:userID];
        NSMutableDictionary *status=[self statusOfUserID:userID];
        [[status objectForKey:@"NetServices"] addObject:aNetService];
        [[NSNotificationCenter defaultCenter] postNotificationName:TCMMMPresenceManagerUserRendezvousStatusDidChangeNotification object:self userInfo:[NSDictionary dictionaryWithObject:[NSArray arrayWithObject:userID] forKey:@"UserIDs"]];
        if (![[status objectForKey:@"Status"] isEqualToString:@"GotStatus"]) {
            [self performSelector:@selector(connectToRendezvousUserID:) withObject:userID afterDelay:0.3];
        }
    }
}

- (void)resolveUnconnectedFoundNetServices:(NSTimer *)aTimer {
    NSEnumerator *userIDs = [I_foundUserIDs objectEnumerator];
    NSString *userID = nil;
    while ((userID=[userIDs nextObject])) {
        NSMutableDictionary *status=[self statusOfUserID:userID];
        if (![[status objectForKey:@"Status"] isEqualToString:@"GotStatus"]) {
            NSEnumerator *netServices = [[status objectForKey:@"NetServices"] objectEnumerator];
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
        NSString *userID = [[aNetService TXTRecordDictionary] objectForKey:@"userid"];
        if (userID && ![userID isEqualTo:[TCMMMUserManager myUserID]]) {
//            NSLog(@"has userID:%@",userID);
            NSMutableDictionary *status=[self statusOfUserID:userID];
            if (![[status objectForKey:@"Status"] isEqualToString:@"GotStatus"]) {
                [self performSelector:@selector(connectToRendezvousUserID:) withObject:userID afterDelay:0.3];
            }
        }
    }
}


- (void)rendezvousBrowser:(TCMRendezvousBrowser *)aBrowser didRemoveResolved:(BOOL)wasResolved service:(NSNetService *)aNetService {
    DEBUGLOG(@"RendezvousLogDomain", AllLogLevel, @"Removed Service: %@",aNetService);
    if (wasResolved) {
        NSString *userID = [[aNetService TXTRecordDictionary] objectForKey:@"userid"];
        if (userID){
            [I_foundUserIDs removeObject:userID];
            NSMutableDictionary *status=[self statusOfUserID:userID];
            [[status objectForKey:@"NetServices"] removeObject:aNetService];
            [[NSNotificationCenter defaultCenter] postNotificationName:TCMMMPresenceManagerUserRendezvousStatusDidChangeNotification object:self userInfo:[NSDictionary dictionaryWithObject:[NSArray arrayWithObject:userID] forKey:@"UserIDs"]];
        }
    }
}



#pragma mark -
#pragma mark ### Published NetService Delegate ###

// Error handling code
- (void)handleError:(NSNumber *)error withService:(NSNetService *)service
{
    static int count=1;
    // Handle error here
    if ([error intValue]==NSNetServicesCollisionError) {
        [I_netService autorelease];
        I_netService=[[NSNetService alloc] initWithDomain:@"" type:@"_see._tcp." name:[NSString stringWithFormat:@"%@ (%d)",[self serviceName],count++] port:[[TCMMMBEEPSessionManager sharedInstance] listeningPort]];
        [I_netService setDelegate:self];
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


// Sent when the service stops
- (void)netServiceDidStop:(NSNetService *)netService
{
    I_flags.serviceIsPublished=NO;
    DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"netServiceDidStop: %@", netService);
    // You may want to do something here, such as updating a user interface
}

@end
