//
//  AppController.m
//  BEEPSEEKiller
//
//  Created by Dominik Wagner on 29.03.05.
//  Copyright (c) 2005 TheCodingMonkeys. All rights reserved.
//

#import "AppController.h"
#import "sys/socket.h"
#import "netinet/in.h"
#import "netinet6/in6.h"
#import "arpa/inet.h"

#import "dns_sd.h"
#import "nameser.h"

#pragma mark -
#pragma mark ### NSString Additions ###

@interface NSString (NSStringNetworkingAdditions)
+ (NSString *)stringWithAddressData:(NSData *)aAddressData;
@end

@implementation NSString (NSStringNetworkingAdditions) 

+ (NSString *)stringWithAddressData:(NSData *)aAddressData {
    struct sockaddr *socketAddress=(struct sockaddr *)[aAddressData bytes];
    // IPv6 Addresses are "FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF" at max, which is 40 bytes (0-terminated)
    // IPv4 Addresses are "255.255.255.255" at max which is smaller
    char stringBuffer[40];
    NSString *addressAsString=nil;
    if (socketAddress->sa_family == AF_INET) {
        if (inet_ntop(AF_INET,&((struct in_addr)((struct sockaddr_in *)socketAddress)->sin_addr),stringBuffer,40)) {
            addressAsString=[NSString stringWithUTF8String:stringBuffer];
        } else {
            addressAsString=@"IPv4 un-ntopable";
        }
        int port = ((struct sockaddr_in *)socketAddress)->sin_port;
        addressAsString=[addressAsString stringByAppendingFormat:@":%d",port];
    } else if (socketAddress->sa_family == AF_INET6) {
         if (inet_ntop(AF_INET6,&(((struct sockaddr_in6 *)socketAddress)->sin6_addr),stringBuffer,40)) {
            addressAsString=[NSString stringWithUTF8String:stringBuffer];
        } else {
            addressAsString=@"IPv6 un-ntopable";
        }
        int port = ((struct sockaddr_in6 *)socketAddress)->sin6_port;
        // Suggested IPv6 format (see http://www.faqs.org/rfcs/rfc2732.html)
        addressAsString=[NSString stringWithFormat:@"[%@]:%d",addressAsString,port]; 
    } else {
        addressAsString=@"neither IPv6 nor IPv4";
    }
    return [[addressAsString copy] autorelease];
}

@end


@implementation AppController

- (id)init {
    if ((self=[super init])) {
        I_services=[NSMutableArray new];
    }
    return self;
}

- (void)dealloc {
    [self stopRendezvousBrowsing];
    [I_services release];
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    DEBUGLOG(@"fuckitdomain", AlwaysLogLevel, @"applicationDidFinishLaunching:");    
    [O_servicesController bind:@"contentArray" toObject:self withKeyPath:@"I_services" options:nil];
    [self startRendezvousBrowsing];
}

- (void)stopRendezvousBrowsing {
    [I_browser setDelegate:nil];
    [I_browser stopSearch];
    [I_browser release];
    I_browser=nil;
}

- (void)startRendezvousBrowsing {
    [self stopRendezvousBrowsing];
    I_browser=[[TCMRendezvousBrowser alloc] initWithServiceType:@"_see._tcp." domain:@""];
    [I_browser setDelegate:self];
    [I_browser startSearch];
}

- (NSArray *)addressArrayForAddressArray:(NSArray *)anAddressArray {
    NSMutableArray *result=[NSMutableArray array];
    NSEnumerator *addresses=[anAddressArray objectEnumerator];
    NSData *address=nil;
    while ((address=[addresses nextObject])) {
        [result addObject:[NSDictionary dictionaryWithObjectsAndKeys:address,@"address",[NSString stringWithAddressData:address],@"addressAsString",nil]];
    }
    return result;
}

- (void)updateService:(NSNetService *)aNetService {
    NSMutableArray *services=[self mutableArrayValueForKey:@"I_services"];
    unsigned count=[services count];
    while (count--) {
        NSNetService *service=[[services objectAtIndex:count] objectForKey:@"service"];
        if (service==aNetService) {
            [[services objectAtIndex:count] setObject:[self addressArrayForAddressArray:[aNetService addresses]] forKey:@"addresses"];
        }
    }
}

- (IBAction)connect:(id)aSender {
    NSData *addressData=[[[O_addressesController selectedObjects] objectAtIndex:0] objectForKey:@"address"];
    DEBUGLOG(@"MillionMonkeysLogDomain", AlwaysLogLevel, @"%@", addressData);
    if (addressData) {
        TCMBEEPSession *session = [[TCMBEEPSession alloc] initWithAddressData:addressData];
        [session setProfileURIs:[NSArray arrayWithObjects:@"http://www.codingmonkeys.de/BEEP/SubEthaEditSession", @"http://www.codingmonkeys.de/BEEP/SubEthaEditHandshake", @"http://www.codingmonkeys.de/BEEP/TCMMMStatus", nil]];
        [session setDelegate:self];
        [session open];
    }
}

#pragma mark -
#pragma mark ### BEEPSession delegate ###

- (void)BEEPSession:(TCMBEEPSession *)aBEEPSession didReceiveGreetingWithProfileURIs:(NSArray *)aProfileURIArray
{
    DEBUGLOG(@"MillionMonkeysLogDomain", AlwaysLogLevel, @"didReceiveGreetingWithProfileURIs: %@",aProfileURIArray);
    /*
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
        [self removeSessionFromSessionsArray:aBEEPSession];
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
    */
}

- (NSMutableDictionary *)BEEPSession:(TCMBEEPSession *)aBEEPSession willSendReply:(NSMutableDictionary *)aReply forChannelRequests:(NSArray *)aRequests
{
    DEBUGLOG(@"MillionMonkeysLogDomain", AlwaysLogLevel, @"%@",aReply);
    return aReply;
}

- (void)BEEPSession:(TCMBEEPSession *)aBEEPSession didOpenChannelWithProfile:(TCMBEEPProfile *)aProfile
{
    DEBUGLOG(@"MillionMonkeysLogDomain", AlwaysLogLevel, @"didOpenChannel");
    /*
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
    } else if ([[aProfile profileURI] isEqualToString:@"http://www.codingmonkeys.de/BEEP/TCMMMStatus"]) {
        [[TCMMMPresenceManager sharedInstance] acceptStatusProfile:(TCMMMStatusProfile *)aProfile];
    } else if ([[aProfile profileURI] isEqualToString:@"http://www.codingmonkeys.de/BEEP/SubEthaEditSession"]) {
        DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"Got SubEthaEditSession profile");
        [aProfile setDelegate:self];
        [I_pendingSessionProfiles addObject:aProfile];
    }
    */
}

- (void)BEEPSession:(TCMBEEPSession *)aBEEPSession didFailWithError:(NSError *)anError
{
    DEBUGLOG(@"MillionMonkeysLogDomain", AlwaysLogLevel, @"BEEPSession:didFailWithError: %@", anError);
/*    [aBEEPSession setDelegate:nil];
    [[aBEEPSession retain] autorelease];
    
    [self TCM_sendDidEndNotificationForSession:aBEEPSession error:anError];

    NSString *aUserID = [[aBEEPSession userInfo] objectForKey:@"peerUserID"];
    BOOL isRendezvous = [[aBEEPSession userInfo] objectForKey:@"isRendezvous"] != nil;
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
*/    
    DEBUGLOG(@"MillionMonkeysLogDomain", AlwaysLogLevel, @"%@", [self description]);
}

- (void)BEEPSessionDidClose:(TCMBEEPSession *)aBEEPSession
{
    DEBUGLOG(@"MillionMonkeysLogDomain", AlwaysLogLevel, @"BEEPSessionDidClose");
}


#pragma mark -
#pragma mark ### NSNetService Delegate ###

- (void)netServiceDidResolveAddress:(NSNetService *)aNetService  {
    [self updateService:aNetService];
}

#pragma mark -
#pragma mark ### TCMRendezvousBrowser Delegate ###
- (void)rendezvousBrowserWillSearch:(TCMRendezvousBrowser *)aBrowser {

}

- (void)rendezvousBrowserDidStopSearch:(TCMRendezvousBrowser *)aBrowser {

}

- (void)rendezvousBrowser:(TCMRendezvousBrowser *)aBrowser didNotSearch:(NSError *)anError {
    DEBUGLOG(@"RendezvousLogDomain", AlwaysLogLevel, @"Mist: %@",anError);
}

- (void)rendezvousBrowser:(TCMRendezvousBrowser *)aBrowser didFindService:(NSNetService *)aNetService {
    DEBUGLOG(@"RendezvousLogDomain", AlwaysLogLevel, @"foundservice: %@",aNetService);
}

- (void)rendezvousBrowser:(TCMRendezvousBrowser *)aBrowser didResolveService:(NSNetService *)aNetService {
//    [I_data addObject:[NSMutableDictionary dictionaryWithObject:[NSString stringWithFormat:@"resolved %@%@",[aNetService name],[aNetService domain]] forKey:@"serviceName"]];
    [[self mutableArrayValueForKey:@"I_services"] addObject:
            [NSMutableDictionary dictionaryWithObjectsAndKeys:aNetService,@"service",
                [self addressArrayForAddressArray:[aNetService addresses]],@"addresses",
                nil]];
    [aNetService setDelegate:self];
}

- (void)rendezvousBrowser:(TCMRendezvousBrowser *)aBrowser didChangeCountOfResolved:(BOOL)wasResolved service:(NSNetService *)aNetService {
    [self updateService:aNetService];
}


- (void)rendezvousBrowser:(TCMRendezvousBrowser *)aBrowser didRemoveResolved:(BOOL)wasResolved service:(NSNetService *)aNetService {
    NSMutableArray *services=[self mutableArrayValueForKey:@"I_services"];
    unsigned count=[services count];
    while (count--) {
        NSNetService *service=[[services objectAtIndex:count] objectForKey:@"service"];
        if (service==aNetService) {
            [services removeObjectAtIndex:count];
        }
    }
}


@end
