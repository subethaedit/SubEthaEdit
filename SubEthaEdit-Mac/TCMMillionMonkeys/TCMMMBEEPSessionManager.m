//
//  TCMMMBEEPSessionManager.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Fri Feb 27 2004.
//  Copyright (c) 2004-2007 TheCodingMonkeys. All rights reserved.
//

#import "TCMMMBEEPSessionManager.h"
#import "TCMMMPresenceManager.h"
#import "TCMBEEP.h"
#import "TCMFoundation.h"
#import "TCMMMUserManager.h"
#import "TCMMMSession.h"
#import "TCMHost.h"
#import "HandshakeProfile.h"
#import "SessionProfile.h"
#import "AppController.h"
#import <TCMPortMapper/TCMPortMapper.h>
#import "TCMHost.h"
#import "NSWorkspaceTCMAdditions.h"
#import "PreferenceKeys.h"
#import <netdb.h>       // getaddrinfo, struct addrinfo, AI_NUMERICHOST

#ifdef TCM_ISSEED
    #import "SDAppController.h"
#endif

#define PORTRANGELENGTH 10
NSString * const DefaultPortNumber = @"port";
NSString * const ShouldAutomaticallyMapPort = @"ShouldAutomaticallyMapPort";


NSString * const ProhibitInboundInternetSessions = @"ProhibitInboundInternetSessions";


static NSString *kBEEPSessionStatusNoSession  = @"NoSession";
static NSString *kBEEPSessionStatusGotSession = @"GotSession";
static NSString *kBEEPSessionStatusConnecting = @"Connecting";


NSString * const TCMMMBEEPSessionManagerIsReadyNotification = @"TCMMMBEEPSessionManagerIsReadyNotification";

NSString * const TCMMMBEEPSessionManagerDidAcceptSessionNotification = @"TCMMMBEEPSessionManagerDidAcceptSessionNotification";
NSString * const TCMMMBEEPSessionManagerSessionDidEndNotification = @"TCMMMBEEPSessionManagerSessionDidEndNotification";
NSString * const TCMMMBEEPSessionManagerConnectToHostDidFailNotification = @"TCMMMBEEPSessionManagerConnectToHostDidFailNotification";
NSString * const TCMMMBEEPSessionManagerConnectToHostCancelledNotification = @"TCMMMBEEPSessionManagerConnectToHostCancelledNotification";

NSString * const kTCMMMBEEPSessionManagerDefaultMode=@"kTCMMMBEEPSessionManagerDefaultMode";
NSString * const kTCMMMBEEPSessionManagerTLSMode    =@"kTCMMMBEEPSessionManagerTLSMode";


/*"
    SessionInformation:
        @"RendezvousStatus" => kBEEPSessionStatusNoSession | kBEEPSessionStatusGotSession | kBEEPSessionStatusConnecting
        @"OutgoingRendezvousSessions" => NSArray with Session Attempts
        @"RendezvousSession" => successfully connected rendezvous session
        @"NetService" => NSNetService
        @"TriedNetServiceAddresses" => NSNumber up to how many addresses of the netservice have been tried
        @"InboundRendezvousSession" => RendezvousSession that came from listener
        @"OutboundSessions" => Active Outbound Internet Sessions 
        @"InboundSessions"  => Active Inbound Internet Sessions
"*/


static TCMMMBEEPSessionManager *sharedInstance;

@interface TCMMMBEEPSessionManager (TCMMMBEEPSessionManagerPrivateAdditions)

- (void)TCM_connectToNetServiceWithInformation:(NSMutableDictionary *)aInformation;
- (void)TCM_sendDidAcceptNotificationForSession:(TCMBEEPSession *)aSession;
- (void)TCM_sendDidEndNotificationForSession:(TCMBEEPSession *)aSession error:(NSError *)anError;

@end


@implementation TCMMMBEEPSessionManager

+ (TCMMMBEEPSessionManager *)sharedInstance
{
    if (!sharedInstance) {
        sharedInstance = [self new];
    }
    return sharedInstance;
}

+ (NSURL *)urlForAddress:(NSString *)anAddress {
    NSString *URLString = nil;
    NSString *schemePrefix = [NSString stringWithFormat:@"%@://", @"see"];
    NSString *lowercaseAddress = [anAddress lowercaseString];
    if (![lowercaseAddress hasPrefix:schemePrefix]) {
        // check if the address is an ipv6 address
        NSCharacterSet *ipv6set = [NSCharacterSet characterSetWithCharactersInString:@"1234567890abcdef:"];
        NSScanner *ipv6scanner = [NSScanner scannerWithString:anAddress];
        NSString *scannedString = nil;
        if ([ipv6scanner scanCharactersFromSet:ipv6set intoString:&scannedString]) {
            if ([scannedString length] == [anAddress length]) {
                anAddress = [NSString stringWithFormat:@"[%@]",scannedString];
            } else if ([anAddress length] > [scannedString length]+1 && [anAddress characterAtIndex:[scannedString length]] == '%') {
                anAddress = [NSString stringWithFormat:@"[%@%%25%@]",scannedString,[anAddress substringFromIndex:[scannedString length]+1]];
            }
        }
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
            NSString *URLString = nil;
            NSMutableString *percentEscapedString = [[[NSString stringWithAddressData:addressData] mutableCopy] autorelease];
            [percentEscapedString replaceOccurrencesOfString:@"%" withString:@"%25" options:0 range:NSMakeRange(0,[percentEscapedString length])];
            URLString = [NSString stringWithFormat:@"%@://%@", [anURL scheme], percentEscapedString];
            resultURL = [NSURL URLWithString:URLString];
        } else {
            DEBUGLOG(@"InternetLogDomain", SimpleLogLevel, @"Neither IPv4 nor IPv6 address");
            resultURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@:%d", [anURL scheme], hostAddress,port]];;
        }
        if (portString) {
            free(portString);
        }
        
        if ([[anURL path] length] > 0 && ![[anURL path] isEqualToString:@"/"]) {
            if (aRequest) *aRequest = anURL;
        }
        
    } else {
        DEBUGLOG(@"InternetLogDomain", SimpleLogLevel, @"Invalid URI");
    }
    return resultURL;
}


- (void)logRetainCounts
{
    TCMBEEPSession *session = nil;
    for (session in I_sessions) {
        NSLog(@"Session: %@, %@, retainCount: %d", [session description], NSStringFromClass([session class]), [session retainCount]);
    }
}

- (void)sslGenerationDidFinish:(NSNotification *)aNotification {
    I_SSLGenerationCount++;
//    NSLog(@"%s %@",__FUNCTION__,aNotification);
//	NSLog(@"%s count:%d desiredCount:%d",__FUNCTION__,I_SSLGenerationCount,I_SSLGenerationDesiredCount);
    if (I_SSLGenerationCount >= I_SSLGenerationDesiredCount) {
		[[NSNotificationQueue defaultQueue] enqueueNotification:[NSNotification notificationWithName:TCMMMBEEPSessionManagerIsReadyNotification object:self] postingStyle:NSPostASAP];
	}
}

- (id)init
{
    self = [super init];
    if (self) {
    	[AppController sharedInstance]; // making sure the defaults are registered - seem ugly need better way soon
    	I_SSLGenerationCount = 0;
    	I_SSLGenerationDesiredCount = 1;
//    	NSLog(@"%s %@? %d",__FUNCTION__,EnableTLSKey,[[NSUserDefaults standardUserDefaults] boolForKey:EnableTLSKey]);
		if ([[NSUserDefaults standardUserDefaults] boolForKey:EnableTLSKey]) {
			I_SSLGenerationDesiredCount++;
			[TCMBEEPSession prepareDiffiHellmannParameters];
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sslGenerationDidFinish:) name:@"TCMBEEPTempCertificateCreationForSSLDidFinish" object:nil];
		}
        I_greetingProfiles = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
        	[NSMutableArray array],kTCMMMBEEPSessionManagerDefaultMode,
        	[NSMutableArray array],kTCMMMBEEPSessionManagerTLSMode,nil];
        I_handlersForNewProfiles = [NSMutableDictionary new];
        I_sessionInformationByUserID = [NSMutableDictionary new];
        I_pendingSessionProfiles = [NSMutableSet new];
        I_pendingSessions = [NSMutableSet new];
        I_outboundInternetSessions = [NSMutableDictionary new];
        I_sessions = [NSMutableArray new];
        BOOL flag = [[NSUserDefaults standardUserDefaults] boolForKey:ProhibitInboundInternetSessions];
        I_isProhibitingInboundInternetSessions = flag;
        sharedInstance = self;
        [self registerHandler:[TCMMMPresenceManager sharedInstance] forIncomingProfilesWithProfileURI:@"http://www.codingmonkeys.de/BEEP/TCMMMStatus"];

		[self performSelector:@selector(sslGenerationDidFinish:) withObject:nil afterDelay:0];
    }
    return self;
}

- (void)dealloc
{
    [I_greetingProfiles release];
    [I_listener close];
    [I_listener setDelegate:nil];
    [I_listener release];
    [I_sessionInformationByUserID release];
    [I_pendingSessionProfiles release];
    [I_pendingSessions release];
    [I_outboundInternetSessions release];
    [I_sessions release];
    [super dealloc];
}

- (unsigned int)countOfSessions {
    return [I_sessions count];
}

- (TCMBEEPSession *)objectInSessionsAtIndex:(unsigned int)index {
     return [I_sessions objectAtIndex:index];
}

- (void)insertObject:(TCMBEEPSession *)session inSessionsAtIndex:(unsigned int)index {
    [I_sessions insertObject:session atIndex:index];
}


- (void)removeObjectFromSessionsAtIndex:(unsigned int)index {
    [I_sessions removeObjectAtIndex:index];
}

- (NSString *)description
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    TCMMMUserManager *um = [TCMMMUserManager sharedInstance];
    NSEnumerator *userIDs = [I_sessionInformationByUserID keyEnumerator];
    NSString *userID=nil;
    while ((userID = [userIDs nextObject])) {
        TCMMMUser *user = [um userForUserID:userID];
        NSMutableDictionary *valueDict = [[[I_sessionInformationByUserID objectForKey:userID] mutableCopy] autorelease];
        if ([[valueDict objectForKey:@"InboundSessions"] count] >0 ||
            [[valueDict objectForKey:@"OutgoingRendezvousSessions"] count] >0 ||
            [[valueDict objectForKey:@"OutboundSessions"] count] >0 ||
             [valueDict objectForKey:@"RendezvousSession"]) {
            [valueDict removeObjectForKey:@"RendezvousSession"];
            [dictionary setObject:valueDict forKey:user?[user shortDescription]:userID];
        }
    }
    return [NSString stringWithFormat:@"BEEPSessionManager sessionInformation:\n%@\npendingSessionProfiles:%@\npendingSessions:%@\noutboundInternetSessions:%@", [dictionary description], [I_pendingSessionProfiles description], [I_pendingSessions description], [I_outboundInternetSessions description]];
}

- (void)validateListener {
    BOOL isVisible = [[TCMMMPresenceManager sharedInstance] isVisible];
    if (!isVisible && [self isProhibitingInboundInternetSessions]) {
        // stop listening
        [self stopListening];
    } else if (!I_listener) {
        // start listening
        [self stopListening];
        (void)[self listen];
    }
}

- (BOOL)listen {
    // set up BEEPListener
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    int port = [defaults integerForKey:DefaultPortNumber];
    for (I_listeningPort = port; I_listeningPort < port + PORTRANGELENGTH; I_listeningPort++) {
        I_listener = [[TCMBEEPListener alloc] initWithPort:I_listeningPort];
        [I_listener setDelegate:self];
        if ([I_listener listen]) {
            DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"Listening on Port: %d", I_listeningPort);
            break;
        } else {
            [I_listener close];
            [I_listener release];
            I_listener = nil;
        }
    }
    if (I_listener) {
        TCMPortMapper *pm = [TCMPortMapper sharedInstance];
        [pm addPortMapping:[TCMPortMapping portMappingWithLocalPort:I_listeningPort desiredExternalPort:SUBETHAEDIT_DEFAULT_PORT transportProtocol:TCMPortMappingTransportProtocolTCP userInfo:nil]];
        if ([defaults boolForKey:ShouldAutomaticallyMapPort]) {
            [pm start];
        }
    }
    return (I_listener != nil);
}

- (void)stopListening {
    [[TCMPortMapper sharedInstance] stop];
    [I_listener close];
    [I_listener setDelegate:nil];
    [I_listener release];
    I_listener = nil;
}

- (int)listeningPort {
    return I_listeningPort;
}

- (NSArray *)allBEEPSessions {
    return I_sessions;
}

- (void)terminateAllBEEPSessions {
    NSEnumerator *sessionInformationDicts=[[I_sessionInformationByUserID allValues] objectEnumerator];
    NSDictionary *sessionInformation=nil;
    while ((sessionInformation=[sessionInformationDicts nextObject])) {
        [[sessionInformation objectForKey:@"InboundSessions"] makeObjectsPerformSelector:@selector(terminate)];
        [[sessionInformation objectForKey:@"OutboundSessions"] makeObjectsPerformSelector:@selector(terminate)]; 
        [[sessionInformation objectForKey:@"OutgoingRendezvousSessions"] makeObjectsPerformSelector:@selector(terminate)];
        [(TCMBEEPSession *)[sessionInformation objectForKey:@"RendezvousSession"] terminate];
    }
    [I_pendingSessions makeObjectsPerformSelector:@selector(terminate)];
    [I_pendingSessions removeAllObjects];
    NSEnumerator *outboundDicts=[[I_outboundInternetSessions allValues] objectEnumerator];
    NSDictionary *outboundDict=nil;
    while ((outboundDict=[outboundDicts nextObject])) {
        [[outboundDict objectForKey:@"sessions"] makeObjectsPerformSelector:@selector(terminate)];
    }
    [I_outboundInternetSessions removeAllObjects];
}

- (void)setIsProhibitingInboundInternetSessions:(BOOL)flag {
    I_isProhibitingInboundInternetSessions = flag;
    [[NSUserDefaults standardUserDefaults] setBool:flag forKey:ProhibitInboundInternetSessions];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self validateListener];

    TCMBEEPSession *session = nil;
    for (session in I_sessions) {
        [session setIsProhibitingInboundInternetSessions:flag];
    }
}

- (BOOL)isProhibitingInboundInternetSessions {
    return I_isProhibitingInboundInternetSessions;
}

- (NSMutableDictionary *)sessionInformationForUserID:(NSString *)aUserID {
    NSMutableDictionary *sessionInformation = [I_sessionInformationByUserID objectForKey:aUserID];
    if (!sessionInformation) {
        sessionInformation = [NSMutableDictionary dictionary];
        [I_sessionInformationByUserID setObject:sessionInformation forKey:aUserID];
        [sessionInformation setObject:kBEEPSessionStatusNoSession forKey:@"RendezvousStatus"];
        [sessionInformation setObject:aUserID forKey:@"peerUserID"];
        [sessionInformation setObject:[NSMutableArray array] forKey:@"InboundSessions"];
        [sessionInformation setObject:[NSMutableArray array] forKey:@"OutboundSessions"];
    }
    return sessionInformation;
}

- (void)TCM_connectToNetServiceWithInformation:(NSMutableDictionary *)aInformation {
    NSNetService *service = [aInformation objectForKey:@"NetService"];
    NSArray *addresses = [service addresses]; 
    NSMutableArray *outgoingSessions = [aInformation objectForKey:@"OutgoingRendezvousSessions"];
    if (!outgoingSessions) {
        outgoingSessions = [NSMutableArray array];
        [aInformation setObject:outgoingSessions forKey:@"OutgoingRendezvousSessions"];
    }
    int i=0;
    for (i = [[aInformation objectForKey:@"TriedNetServiceAddresses"] intValue]; i < [addresses count]; i++) {
        NSData *addressData = [addresses objectAtIndex:i];
        TCMBEEPSession *session = [[TCMBEEPSession alloc] initWithAddressData:addressData];
        DEBUGLOG(@"RendezvousLogDomain", DetailedLogLevel,@"Trying to connect to %d: %@ - %@",i,[service description],[NSString stringWithAddressData:addressData]);
        [self insertObject:session inSessionsAtIndex:[self countOfSessions]];
        [session setIsProhibitingInboundInternetSessions:[self isProhibitingInboundInternetSessions]];
        
        [outgoingSessions addObject:session];
        [session release];
        [[session userInfo] setObject:[aInformation objectForKey:@"peerUserID"] forKey:@"peerUserID"];
        [[session userInfo] setObject:[NSNumber numberWithBool:YES] forKey:@"isRendezvous"];
        [session addProfileURIs:   [I_greetingProfiles objectForKey:kTCMMMBEEPSessionManagerDefaultMode]];
        [session addTLSProfileURIs:[I_greetingProfiles objectForKey:kTCMMMBEEPSessionManagerTLSMode]];
        [session setDelegate:self];
        [session open];
    }
    [aInformation setObject:[NSNumber numberWithInt:i] forKey:@"TriedNetServiceAddresses"];
}

- (void)connectToNetService:(NSNetService *)aNetService {

    NSString *userID = [[aNetService TXTRecordDictionary] objectForKey:@"userid"];
    if (userID) {
        NSMutableDictionary *sessionInformation = [self sessionInformationForUserID:userID];
        NSString *status = [sessionInformation objectForKey:@"RendezvousStatus"];
        if (![status isEqualToString:kBEEPSessionStatusGotSession]) {
            [sessionInformation setObject:aNetService forKey:@"NetService"];
            [sessionInformation setObject:kBEEPSessionStatusConnecting forKey:@"RendezvousStatus"];
            [sessionInformation setObject:[NSNumber numberWithInt:0] forKey:@"TriedNetServiceAddresses"];
            [self TCM_connectToNetServiceWithInformation:sessionInformation];
        } else {
    //        TCMBEEPSession *session = [sessionInformation objectForKey:@"RendezvousSession"];
        }
    }
}

- (void)connectToHost:(TCMHost *)aHost
{
    DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"connectToHost:");

/*
    outboundInternetSessions {
        <URLString> => {
            "host" => TCMHost
            "sessions" => NSMutableArray
        }
    }
*/
    NSMutableDictionary *infoDict = [NSMutableDictionary dictionary];
    [infoDict setObject:aHost forKey:@"host"];
    [infoDict setObject:[NSNumber numberWithBool:YES] forKey:@"pending"];
    NSMutableArray *sessions = [NSMutableArray array];
    [infoDict setObject:sessions forKey:@"sessions"];
    
    [I_outboundInternetSessions setObject:infoDict forKey:[[aHost userInfo] objectForKey:@"URLString"]];
    
    NSEnumerator *addresses = [[aHost addresses] objectEnumerator];
    NSData *addressData;
    while ((addressData = [addresses nextObject])) {
        TCMBEEPSession *session = [[TCMBEEPSession alloc] initWithAddressData:addressData];
        [[session userInfo] setObject:[[aHost userInfo] objectForKey:@"URLString"] forKey:@"URLString"];
        if ([[aHost userInfo] objectForKey:@"isAutoConnect"]) {
            [[session userInfo] setObject:[[aHost userInfo] objectForKey:@"isAutoConnect"] forKey:@"isAutoConnect"];
        }
        [self insertObject:session inSessionsAtIndex:[self countOfSessions]];
        [session setIsProhibitingInboundInternetSessions:[self isProhibitingInboundInternetSessions]];

        [sessions addObject:session];
        [session release];
        [session addProfileURIs:[I_greetingProfiles objectForKey:kTCMMMBEEPSessionManagerDefaultMode]];
        [session addTLSProfileURIs:[I_greetingProfiles objectForKey:kTCMMMBEEPSessionManagerTLSMode]];
        [session setDelegate:self];
        [session open];
    }
}

- (void)cancelConnectToHost:(TCMHost *)aHost
{
    NSMutableDictionary *infoDict = [I_outboundInternetSessions objectForKey:[[aHost userInfo] objectForKey:@"URLString"]];
    if (infoDict) {
        [infoDict setObject:[NSNumber numberWithBool:YES] forKey:@"cancelled"];
        NSArray *sessions = [infoDict objectForKey:@"sessions"];
        [sessions makeObjectsPerformSelector:@selector(terminate)];
    }
}

- (TCMBEEPSession *)sessionForUserID:(NSString *)aUserID
{
    DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"sessionInfo: %@", [I_sessionInformationByUserID objectForKey:aUserID]);
    return [self sessionForUserID:aUserID URLString:nil]; 
}

- (TCMBEEPSession *)sessionForUserID:(NSString *)aUserID URLString:(NSString *)aURLString
{
    TCMBEEPSession *fallbackSession = nil;
    
    NSDictionary *info = [self sessionInformationForUserID:aUserID];
    NSArray *outboundSessions = [info objectForKey:@"OutboundSessions"];
    TCMBEEPSession *session = nil;
    for (session in outboundSessions) {
        if ([session sessionStatus] == TCMBEEPSessionStatusOpen) {
            if (aURLString && [[[session userInfo] objectForKey:@"URLString"] isEqualToString:aURLString]) {
                return session;
            } else {
                if (!fallbackSession) fallbackSession = session;
            }
        }
    }

    NSArray *inboundSessions = [info objectForKey:@"InboundSessions"];
    for (session in inboundSessions) {
        if ([session sessionStatus] == TCMBEEPSessionStatusOpen) {
            if (aURLString && [[[session userInfo] objectForKey:@"URLString"] isEqualToString:aURLString]) {
                return session;
            } else {
                if (!fallbackSession) fallbackSession = session;
            }
        }
    }

    if ([[info objectForKey:@"RendezvousStatus"] isEqualToString:kBEEPSessionStatusGotSession]) {
        session=[info objectForKey:@"RendezvousSession"];
        if ([session sessionStatus] == TCMBEEPSessionStatusOpen) {
            return session;
        }
    }
    
    return fallbackSession;
}

- (TCMBEEPSession *)sessionForUserID:(NSString *)aUserID peerAddressData:(NSData *)anAddressData {
    TCMBEEPSession *fallbackSession = nil;
    
    NSDictionary *info = [self sessionInformationForUserID:aUserID];
    NSArray *outboundSessions = [info objectForKey:@"OutboundSessions"];
    TCMBEEPSession *session = nil;
    for (session in outboundSessions) {
        if ([session sessionStatus] == TCMBEEPSessionStatusOpen) {
            if ([[session peerAddressData] isEqualTo:anAddressData]) {
                return session;
            } else {
                if (!fallbackSession) fallbackSession = session;
            }
        }
    }

    NSArray *inboundSessions = [info objectForKey:@"InboundSessions"];
    for (session in inboundSessions) {
        if ([session sessionStatus] == TCMBEEPSessionStatusOpen) {
            if ([[session peerAddressData] isEqualTo:anAddressData]) {
                return session;
            } else {
                if (!fallbackSession) fallbackSession = session;
            }
        }
    }

    if ([[info objectForKey:@"RendezvousStatus"] isEqualToString:kBEEPSessionStatusGotSession]) {
        session=[info objectForKey:@"RendezvousSession"];
        if ([session sessionStatus] == TCMBEEPSessionStatusOpen) {
            return session;
        }
    }
    
    return fallbackSession;
}


- (void)registerHandler:(id)aHandler forIncomingProfilesWithProfileURI:(NSString *)aProfileURI {
    [I_handlersForNewProfiles setObject:aHandler forKey:aProfileURI];
}

- (void)registerProfileURI:(NSString *)aProfileURI forGreetingInMode:(NSString *)aMode {
    [[I_greetingProfiles objectForKey:aMode] addObject:aProfileURI];
}


#pragma mark -

- (void)BEEPSession:(TCMBEEPSession *)aBEEPSession didReceiveGreetingWithProfileURIs:(NSArray *)aProfileURIArray
{
    if ([[aBEEPSession peerProfileURIs] containsObject:@"http://www.codingmonkeys.de/BEEP/SubEthaEditHandshake"]) {
        if ([aBEEPSession isInitiator]) {
            if ([[aBEEPSession userInfo] objectForKey:@"isRendezvous"]) {
                NSString *aUserID = [[aBEEPSession userInfo] objectForKey:@"peerUserID"];
                NSMutableDictionary *sessionInformation = [self sessionInformationForUserID:aUserID];
                if ([sessionInformation objectForKey:@"NetService"]) {
                    // rendezvous: close all other sessions
                    NSMutableArray *outgoingSessions = [sessionInformation objectForKey:@"OutgoingRendezvousSessions"];
                    TCMBEEPSession *session;
                    while ((session = [outgoingSessions lastObject])) {
                        [[session retain] autorelease];
                        [outgoingSessions removeObjectAtIndex:[outgoingSessions count]-1];
                        if (session == aBEEPSession) {
                            [sessionInformation setObject:session forKey:@"RendezvousSession"];
                        } else {
                            [self removeSessionFromSessionsArray:session];
                            [session setDelegate:nil];
                            [session terminate];
                        }
                    }
                }
            } else {
                NSString *URLString = [[aBEEPSession userInfo] objectForKey:@"URLString"];
                NSDictionary *info = [I_outboundInternetSessions objectForKey:URLString];
                NSMutableArray *sessions = [info objectForKey:@"sessions"];
                TCMBEEPSession *session;
                while ((session = [sessions lastObject])) {
                    [[session retain] autorelease];
                    [sessions removeObjectAtIndex:[sessions count]-1];
                    if (session != aBEEPSession) {
                        [self removeSessionFromSessionsArray:session];
                        [session setDelegate:nil];
                        [session terminate];
                    } else {
                        DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"retain this session somewhere: %@", session);
                    }
                }
            }
            [aBEEPSession startChannelWithProfileURIs:[NSArray arrayWithObject:@"http://www.codingmonkeys.de/BEEP/SubEthaEditHandshake"] andData:nil sender:self];
        }
    } else {
        [self removeSessionFromSessionsArray:[[aBEEPSession retain] autorelease]];
        [aBEEPSession setDelegate:nil];
        [aBEEPSession terminate];
        
        if ([[aBEEPSession userInfo] objectForKey:@"isRendezvous"]) {
            NSString *aUserID = [[aBEEPSession userInfo] objectForKey:@"peerUserID"];
            if ([aBEEPSession isInitiator] && aUserID) {
                NSMutableDictionary *information = [self sessionInformationForUserID:aUserID];
                [[information objectForKey:@"OutgoingRendezvousSessions"] removeObject:aBEEPSession];
            }
        } else {
            if ([aBEEPSession isInitiator]) {
                NSString *URLString = [[aBEEPSession userInfo] objectForKey:@"URLString"];
                NSDictionary *info = [I_outboundInternetSessions objectForKey:URLString];
                [[info objectForKey:@"sessions"] removeObject:aBEEPSession];
                [self TCM_sendDidEndNotificationForSession:aBEEPSession error:nil];
            }
        }
        [I_pendingSessions removeObject:aBEEPSession];
    }
}

- (NSMutableDictionary *)BEEPSession:(TCMBEEPSession *)aBEEPSession willSendReply:(NSMutableDictionary *)aReply forChannelRequests:(NSArray *)aRequests
{
    if ([[aReply objectForKey:@"ProfileURI"] isEqualToString:@"http://www.codingmonkeys.de/BEEP/SubEthaEditSession"]) {
        [aReply setObject:[SessionProfile defaultInitializationData] forKey:@"Data"];
    } else if ([[aReply objectForKey:@"ProfileURI"] isEqualToString:@"http://www.codingmonkeys.de/BEEP/TCMMMStatus"]) {
        [aReply setObject:[TCMMMStatusProfile defaultInitializationData] forKey:@"Data"];
    }
    return aReply;
}

- (void)BEEPSession:(TCMBEEPSession *)aBEEPSession didOpenChannelWithProfile:(TCMBEEPProfile *)aProfile data:(NSData *)inData
{
//    NSLog(@"%s isServer:%@, %@",__FUNCTION__,[aProfile isServer]?@"YES":@"NO", [aProfile class]);
    if ([[aProfile profileURI] isEqualToString:@"http://www.codingmonkeys.de/BEEP/SubEthaEditHandshake"]) {
        [aProfile setDelegate:self];
        if (![aProfile isServer]) {
            if ([[aBEEPSession userInfo] objectForKey:@"isRendezvous"]) {
                NSString *aUserID = [[aBEEPSession userInfo] objectForKey:@"peerUserID"];
                NSMutableDictionary *information = [self sessionInformationForUserID:aUserID];
                if ([[information objectForKey:@"OutgoingRendezvousSessions"] count]) {
                    //NSLog(@"Can't happen");
                }
            } else {
                // Do something here for internet sessions
            }
            [(HandshakeProfile *)aProfile shakeHandsWithUserID:[TCMMMUserManager myUserID]];
        }
    } else if ([[aProfile profileURI] isEqualToString:@"http://www.codingmonkeys.de/BEEP/SubEthaEditSession"]) {
        DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"Got SubEthaEditSession profile");
        [aProfile setDelegate:self];
        [I_pendingSessionProfiles addObject:aProfile];
    } else {
        // general case
        id handler = [I_handlersForNewProfiles objectForKey:[aProfile profileURI]];
        if (handler) {
            [handler BEEPSession:aBEEPSession didOpenChannelWithProfile:aProfile data:inData];
        }
    }
}

- (void)BEEPSession:(TCMBEEPSession *)aBEEPSession didFailWithError:(NSError *)anError
{
    DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"BEEPSession:didFailWithError: %@", anError);
    [aBEEPSession setDelegate:nil];
    [[aBEEPSession retain] autorelease];
    
    [self TCM_sendDidEndNotificationForSession:aBEEPSession error:anError];

    NSString *aUserID = [[aBEEPSession userInfo] objectForKey:@"peerUserID"];
    BOOL isRendezvous = [[aBEEPSession userInfo] objectForKey:@"isRendezvous"] != nil;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"LogConnections"]) {
        TCMMMUser *user = [[TCMMMUserManager sharedInstance] userForUserID:aUserID];
        NSLog(@"Disconnect: %@ - %@ - %@",[NSString stringWithAddressData:[aBEEPSession peerAddressData]],user?[user shortDescription]:aUserID,[[aBEEPSession userInfo] objectForKey:@"userAgent"]);
    }
    if (aUserID) {
        NSMutableDictionary *sessionInformation = [self sessionInformationForUserID:aUserID];
        if (isRendezvous) {
        
            if ([sessionInformation objectForKey:@"InboundRendezvousSession"] == aBEEPSession) {
                [sessionInformation removeObjectForKey:@"InboundRendezvousSession"];
            }
        
            NSString *status = [sessionInformation objectForKey:@"RendezvousStatus"];
            if ([status isEqualToString:kBEEPSessionStatusGotSession]) {
                DEBUGLOG(@"RendezvousLogDomain", DetailedLogLevel,@"beepsession didFail while connected: %@",[aBEEPSession description]);
                if ([sessionInformation objectForKey:@"RendezvousSession"] == aBEEPSession) {
                    [sessionInformation removeObjectForKey:@"RendezvousSession"];
                    [sessionInformation setObject:kBEEPSessionStatusNoSession forKey:@"RendezvousStatus"];
                } else {
                    if ([[sessionInformation objectForKey:@"OutgoingRendezvousSessions"] containsObject:aBEEPSession]) {
                        [[sessionInformation objectForKey:@"OutgoingRendezvousSessions"] removeObject:aBEEPSession];
                    }
                }
            } else if ([status isEqualToString:kBEEPSessionStatusConnecting]) {
                DEBUGLOG(@"RendezvousLogDomain", DetailedLogLevel,@"beepsession didFail while connecting: %@",[aBEEPSession description]);
                if ([[sessionInformation objectForKey:@"OutgoingRendezvousSessions"] containsObject:aBEEPSession]) {
                    [[sessionInformation objectForKey:@"OutgoingRendezvousSessions"] removeObject:aBEEPSession];
                    if ([[sessionInformation objectForKey:@"OutgoingRendezvousSessions"] count] == 0 && 
                        ![sessionInformation objectForKey:@"InboundRendezvousSession"]) {
                        DEBUGLOG(@"RendezvousLogDomain", DetailedLogLevel,@"sessions information look this way: %@",[sessionInformation description]);
                        if ([[sessionInformation objectForKey:@"TriedNetServiceAddresses"] intValue]<[[[sessionInformation objectForKey:@"NetService"] addresses] count]) {
                            [self TCM_connectToNetServiceWithInformation:sessionInformation];
                        } else {
                            [sessionInformation setObject:kBEEPSessionStatusNoSession forKey:@"RendezvousStatus"];
                        }
                    }
                } else if ([sessionInformation objectForKey:@"RendezvousSession"] == aBEEPSession) {
                    [sessionInformation removeObjectForKey:@"RendezvousSession"];
                    [sessionInformation setObject:kBEEPSessionStatusNoSession forKey:@"RendezvousStatus"];
                }
            } else {
                DEBUGLOG(@"RendezvousLogDomain", DetailedLogLevel,@"beepsession didFail while whatever: %@",[aBEEPSession description]);
            }
        } else {
            [[sessionInformation objectForKey:@"OutboundSessions"] removeObject:aBEEPSession];
            [[sessionInformation objectForKey:@"InboundSessions"] removeObject:aBEEPSession];
            NSString *URLString = [[aBEEPSession userInfo] objectForKey:@"URLString"];
            NSMutableDictionary *infoDict = [I_outboundInternetSessions objectForKey:URLString];
            if (infoDict && [infoDict objectForKey:@"pending"]) {
                NSMutableArray *sessions = [infoDict objectForKey:@"sessions"];
                [sessions removeObject:aBEEPSession];
                if ([sessions count] == 0) {
                    [infoDict removeObjectForKey:@"sessions"];
                    if ([infoDict objectForKey:@"cancelled"]) {
                        [[NSNotificationCenter defaultCenter]
                                postNotificationName:TCMMMBEEPSessionManagerConnectToHostCancelledNotification
                                              object:self
                                            userInfo:infoDict];                    
                    } else {
                        [[NSNotificationCenter defaultCenter]
                                postNotificationName:TCMMMBEEPSessionManagerConnectToHostDidFailNotification
                                              object:self
                                            userInfo:infoDict];
                    }
                    [I_outboundInternetSessions removeObjectForKey:URLString];
                }
            }
        }
    } else if (!isRendezvous) {
        NSString *URLString = [[aBEEPSession userInfo] objectForKey:@"URLString"];
        NSMutableDictionary *infoDict = [I_outboundInternetSessions objectForKey:URLString];
        if (infoDict && [infoDict objectForKey:@"pending"]) {
            NSMutableArray *sessions = [infoDict objectForKey:@"sessions"];
            [sessions removeObject:aBEEPSession];
            if ([sessions count] == 0) {
                [infoDict removeObjectForKey:@"sessions"];
                if ([infoDict objectForKey:@"cancelled"]) {
                    [[NSNotificationCenter defaultCenter]
                            postNotificationName:TCMMMBEEPSessionManagerConnectToHostCancelledNotification
                                          object:self
                                        userInfo:infoDict];                    
                } else {
                    [[NSNotificationCenter defaultCenter]
                            postNotificationName:TCMMMBEEPSessionManagerConnectToHostDidFailNotification
                                          object:self
                                        userInfo:infoDict];
                }
                [I_outboundInternetSessions removeObjectForKey:URLString];
            }
        }
    }
    [I_pendingSessions removeObject:aBEEPSession];
    [self removeSessionFromSessionsArray:aBEEPSession];
    
    DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"%@", [self description]);
}

- (void)removeSessionFromSessionsArray:(TCMBEEPSession *)aBEEPSession {
    int index = 0;
    int count = [self countOfSessions];
    for (index = count-1; index >= 0 ; index--) {
        TCMBEEPSession *session = [self objectInSessionsAtIndex:index];
        if ([session isEqual:aBEEPSession]) {
            [self removeObjectFromSessionsAtIndex:index];
        }
    }

}

- (void)BEEPSessionDidClose:(TCMBEEPSession *)aBEEPSession
{
    DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"BEEPSessionDidClose");
}

#pragma mark -
#pragma mark ### Notifications ###

- (void)TCM_sendDidAcceptNotificationForSession:(TCMBEEPSession *)aSession
{
    [[NSNotificationCenter defaultCenter] 
        postNotificationName:TCMMMBEEPSessionManagerDidAcceptSessionNotification 
                      object:self
                    userInfo:[NSDictionary dictionaryWithObject:aSession forKey:@"Session"]];
}

- (void)TCM_sendDidEndNotificationForSession:(TCMBEEPSession *)aSession error:(NSError *)anError
{
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObject:aSession forKey:@"Session"];
    if (anError) {
        [userInfo setObject:anError forKey:@"Error"];
    }
    [[NSNotificationCenter defaultCenter] 
        postNotificationName:TCMMMBEEPSessionManagerSessionDidEndNotification 
                      object:self
                    userInfo:userInfo];
}

#pragma mark -
#pragma mark ### HandshakeProfile delegate methods ###

- (NSString *)profile:(HandshakeProfile *)aProfile shouldProceedHandshakeWithUserID:(NSString *)aUserID {
    NSMutableDictionary *information = [self sessionInformationForUserID:aUserID];
    [[[aProfile session] userInfo] setObject:aUserID forKey:@"peerUserID"];
    if ([[[aProfile session] userInfo] objectForKey:@"isRendezvous"]) {
        
        if ([[information objectForKey:@"RendezvousStatus"] isEqualTo:kBEEPSessionStatusGotSession]) {
            return nil;
        } else if ([[information objectForKey:@"RendezvousStatus"] isEqualTo:kBEEPSessionStatusNoSession]) {
            if ([[aProfile session] isInitiator]) {
                DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"As initiator you should not get this callback by: %@", aProfile);
                return nil;
            } else {
                [information setObject:[aProfile session] forKey:@"InboundRendezvousSession"];
                [information setObject:kBEEPSessionStatusConnecting forKey:@"RendezvousStatus"];
                return [TCMMMUserManager myUserID];
            }
        } else if ([[information objectForKey:@"RendezvousStatus"] isEqualTo:kBEEPSessionStatusConnecting]) {
            if ([information objectForKey:@"NetService"]) {
                DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"Received connection for %@ while I already tried connecting", aUserID);
                BOOL iWin = ([[TCMMMUserManager myUserID] compare:aUserID] == NSOrderedDescending);
                DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"%@ %@ %@", [TCMMMUserManager myUserID], iWin ? @">" : @"<=", aUserID);
                if (iWin) {
                    return nil;
                } else {
                    [information setObject:[aProfile session] forKey:@"InboundRendezvousSession"];
                    return [TCMMMUserManager myUserID]; 
                }
            } else {
                DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"WTF? %@ tries to handshake twice, bad guy: %@", aUserID, [information objectForKey:@"InboundRendezvousSession"]);
                return nil;
            }
        }
    } else if ([[[aProfile session] userInfo] objectForKey:@"isAutoConnect"]) {
        // check if we already have a valid session to that user
        if ([self sessionForUserID:aUserID]) {
//            NSLog(@"%s already got session",__FUNCTION__);
            return nil;
        } else {
            return [TCMMMUserManager myUserID];
        }
    } else {
        return [TCMMMUserManager myUserID];
    }
    
    return nil; // should not happen
}

- (BOOL)profile:(HandshakeProfile *)aProfile shouldAckHandshakeWithUserID:(NSString *)aUserID {
    NSMutableDictionary *information = [self sessionInformationForUserID:aUserID];
    TCMBEEPSession *session = [aProfile session];

    // disallow self connect
    if ([aUserID isEqualToString:[TCMMMUserManager myUserID]]) {
        return NO;
    }

    if ([[session userInfo] objectForKey:@"isRendezvous"]) {
        TCMBEEPSession *inboundSession = [information objectForKey:@"InboundRendezvousSession"];
        if (inboundSession) {
            BOOL iWin = ([[TCMMMUserManager myUserID] compare:aUserID] == NSOrderedDescending);
            if (iWin) {
                [inboundSession setDelegate:nil];
                [inboundSession terminate];
                [I_pendingSessions removeObject:inboundSession];
                [information removeObjectForKey:@"InboundRendezvousSession"];
                [information setObject:kBEEPSessionStatusGotSession forKey:@"RendezvousStatus"];
                return YES;
            } else {
                return NO;
            }
        } else {
            [information setObject:kBEEPSessionStatusGotSession forKey:@"RendezvousStatus"];
            return YES;
        }

    } else {
        if ([[session userInfo] objectForKey:@"isAutoConnect"]) {
            // check if we already have a valid session to that user
            if ([self sessionForUserID:aUserID]) return NO;
        }        
        [[[aProfile session] userInfo] setObject:aUserID forKey:@"peerUserID"];
        [[information objectForKey:@"OutboundSessions"] addObject:session];
        NSDictionary *infoDict = [I_outboundInternetSessions objectForKey:[[session userInfo] objectForKey:@"URLString"]];
        [[session userInfo] setObject:[infoDict objectForKey:@"host"] forKey:@"host"];
        //[I_outboundInternetSessions removeObjectForKey:[[session userInfo] objectForKey:@"URLString"]];
        [[I_outboundInternetSessions objectForKey:[[session userInfo] objectForKey:@"URLString"]] removeObjectForKey:@"pending"];
        return YES;
    }
}

- (void)profile:(HandshakeProfile *)aProfile didAckHandshakeWithUserID:(NSString *)aUserID {
    // trigger creating profiles for clients
    [self TCM_sendDidAcceptNotificationForSession:[aProfile session]];
}

- (void)profile:(HandshakeProfile *)aProfile receivedAckHandshakeWithUserID:(NSString *)aUserID {
    NSMutableDictionary *information = [self sessionInformationForUserID:aUserID];
    TCMBEEPSession *session = [aProfile session];
    if ([[session userInfo] objectForKey:@"isRendezvous"]) {
        [information setObject:session forKey:@"RendezvousSession"];
        [information setObject:kBEEPSessionStatusGotSession forKey:@"RendezvousStatus"];
        [I_pendingSessions removeObject:session];
        DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"received ACK");
        [self TCM_sendDidAcceptNotificationForSession:session];
    } else {
        NSMutableArray *inboundSessions = [information objectForKey:@"InboundSessions"];
        [inboundSessions addObject:session];
        [I_pendingSessions removeObject:session];
        DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"received ACK");
        [self TCM_sendDidAcceptNotificationForSession:session];
    }
}

#pragma mark -
#pragma mark ### Session Profile delegate methods ###

- (void)profile:(SessionProfile *)aProfile didReceiveInvitationForSession:(TCMMMSession *)aSession {
    TCMMMSession *session=[[TCMMMPresenceManager sharedInstance] referenceSessionForSession:aSession];
    if (session) {
        [aProfile setDelegate:nil];
        [session invitationWithProfile:aProfile];
        [I_pendingSessionProfiles removeObject:aProfile];
    } else {
        [[aProfile channel] close];
    }
}


- (void)profile:(SessionProfile *)aProfile didReceiveJoinRequestForSessionID:(NSString *)sessionID {
    DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"didReceiveJoinRequest: %@", sessionID);
    TCMMMSession *session = [[TCMMMPresenceManager sharedInstance] sessionForSessionID:sessionID];
    if (session) {
        [aProfile setDelegate:nil];
        [session joinRequestWithProfile:aProfile];
        [I_pendingSessionProfiles removeObject:aProfile];
    } else {
        DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"WARNING: Closing channel where never a channel was closed before");
        [[aProfile channel] close];
    }
}

#pragma mark -
#pragma mark ### BEEPListener delegate ###

- (BOOL)BEEPListener:(TCMBEEPListener *)aBEEPListener shouldAcceptBEEPSession:(TCMBEEPSession *)aBEEPSession {
    DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"BEEPListener:shouldAcceptBEEPSession %@", [aBEEPSession description]);
    return YES;
}

- (void)BEEPListener:(TCMBEEPListener *)aBEEPListener didAcceptBEEPSession:(TCMBEEPSession *)aBEEPSession {
    DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"BEEPListener:didAcceptBEEPSession: %@", aBEEPSession);
    [aBEEPSession addProfileURIs:[I_greetingProfiles objectForKey:kTCMMMBEEPSessionManagerDefaultMode]];
    [aBEEPSession addTLSProfileURIs:[I_greetingProfiles objectForKey:kTCMMMBEEPSessionManagerTLSMode]];
    [aBEEPSession setDelegate:self];
#ifdef TCM_ISSEED
    [aBEEPSession setAuthenticationDelegate:[SDAppController sharedInstance]];
#endif
    [aBEEPSession open];

    [I_pendingSessions addObject:aBEEPSession];
    [self insertObject:aBEEPSession inSessionsAtIndex:[self countOfSessions]];
}

@end
