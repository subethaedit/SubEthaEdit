//
//  AppController.m
//  BEEPSEEKiller
//
//  Created by Dominik Wagner on 29.03.05.
//  Copyright (c) 2005 TheCodingMonkeys. All rights reserved.
//

#import "AppController.h"
#import "HandshakeProfile.h"
#import "TCMMMStatusProfile.h"
// #import "SessionProfile.h"

static AppController *S_sharedAppController=nil;

@implementation AppController

+ (id)sharedInstance {
    return S_sharedAppController;
}

- (id)init {
    if ((self=[super init])) {
        I_services=[NSMutableArray new];
        S_sharedAppController = self;
        I_testDescriptions = [[NSArray alloc] initWithObjects:
                                @"No Test",
                                @"Handshake profile: Empty GRT",
                                @"Handshake profile: Malformed GRT",
                                @"Status profile: Incomplete USRFUL",
                                nil];
        I_testNumber = 1;
        [self setUserID:[NSString UUIDString]];
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

    [TCMBEEPChannel setClass:[HandshakeProfile class] forProfileURI:@"http://www.codingmonkeys.de/BEEP/SubEthaEditHandshake"];    
    [TCMBEEPChannel setClass:[TCMMMStatusProfile class] forProfileURI:@"http://www.codingmonkeys.de/BEEP/TCMMMStatus"];    
//    [TCMBEEPChannel setClass:[HandshakeProfile class] forProfileURI:@"http://www.codingmonkeys.de/BEEP/SubEthaEditSession"];    
//    [TCMBEEPChannel setClass:[TCMMMStatusProfile class] forProfileURI:@"http://www.codingmonkeys.de/BEEP/TCMMMStatus"];
//    [TCMBEEPChannel setClass:[SessionProfile class] forProfileURI:@"http://www.codingmonkeys.de/BEEP/SubEthaEditSession"];

    NSMenu *menu=[O_popUpButton menu];
    SEL action=[[menu itemAtIndex:0] action];
    int index=0;
    while (index<[I_testDescriptions count]) {
        NSMenuItem *item=[[[NSMenuItem alloc] initWithTitle:[I_testDescriptions objectAtIndex:index] action:action keyEquivalent:@""] autorelease];
        [item setTag:index];
        [menu addItem:item];
        index++;
    }
//    [O_popUpButton setMenu:menu];

    [O_popUpButton bind:@"selectedTag" toObject:self withKeyPath:@"testNumber" options:nil];
}


- (void)appendString:(NSString *)aString {
    [[O_resultTextView textStorage] appendString:aString];
}

- (void)endTest:(NSString *)aStatusString {
    [I_BEEPSession autorelease];
    I_BEEPSession = nil;
    [self appendString:[NSString stringWithFormat:@"Test %d ended: %@\n-------------\n\n",[self testNumber],aStatusString]];
    [self setTestNumber:[self testNumber]+1];
}

- (IBAction)stop:(id)aSender {
    [self endTest:@"User requested Stop"];
}

- (NSArray *)testDescriptions {
    return I_testDescriptions;
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
        [self appendString:[NSString stringWithFormat:@"Test %d: %@\nconnecting to:%@\n\n",[self testNumber],[[self testDescriptions] objectAtIndex:[self testNumber]],[NSString stringWithAddressData:addressData]]];
         I_BEEPSession = [[TCMBEEPSession alloc] initWithAddressData:addressData];
        [I_BEEPSession setProfileURIs:[NSArray arrayWithObjects:@"http://www.codingmonkeys.de/BEEP/SubEthaEditSession", @"http://www.codingmonkeys.de/BEEP/SubEthaEditHandshake", @"http://www.codingmonkeys.de/BEEP/TCMMMStatus", nil]];
        [I_BEEPSession setDelegate:self];
        [I_BEEPSession open];
    }
}

- (void)setTestNumber:(int)aNumber {
    I_testNumber=aNumber;
    if (aNumber >= [[self testDescriptions] count]) {
        I_testNumber = 0;
    }
}

- (int)testNumber {
    return I_testNumber;
}

- (NSString *)userID {
    return I_userID;
}
- (void)setUserID:(NSString *)aString {
    [I_userID autorelease];
     I_userID = [aString retain];
}


#pragma mark -
#pragma mark ### HandshakeProfile delegate methods ###

- (NSString *)profile:(HandshakeProfile *)aProfile shouldProceedHandshakeWithUserID:(NSString *)aUserID {
    DEBUGLOG(@"MillionMonkeysLogDomain", AlwaysLogLevel, @"%@", aUserID);
    /*
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
    } else {
        return [TCMMMUserManager myUserID];
    }
    */
    
    return [self userID]; // should not happen
}

- (BOOL)profile:(HandshakeProfile *)aProfile shouldAckHandshakeWithUserID:(NSString *)aUserID {
    DEBUGLOG(@"MillionMonkeysLogDomain", AlwaysLogLevel, @"%@", aUserID);
/*    NSMutableDictionary *information = [self sessionInformationForUserID:aUserID];
    TCMBEEPSession *session = [aProfile session];
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
        if ([aUserID isEqualToString:[TCMMMUserManager myUserID]]) {
            return NO;
        }
        
        [[[aProfile session] userInfo] setObject:aUserID forKey:@"peerUserID"];
        [[information objectForKey:@"OutboundSessions"] addObject:session];
        NSDictionary *infoDict = [I_outboundInternetSessions objectForKey:[[session userInfo] objectForKey:@"URLString"]];
        [[session userInfo] setObject:[infoDict objectForKey:@"host"] forKey:@"host"];
        //[I_outboundInternetSessions removeObjectForKey:[[session userInfo] objectForKey:@"URLString"]];
        [[I_outboundInternetSessions objectForKey:[[session userInfo] objectForKey:@"URLString"]] removeObjectForKey:@"pending"];
        return YES;
    }
*/
    return YES;
}

- (void)profile:(HandshakeProfile *)aProfile didAckHandshakeWithUserID:(NSString *)aUserID {
    DEBUGLOG(@"MillionMonkeysLogDomain", AlwaysLogLevel, @"%@", aUserID);
    // trigger creating profiles for clients
    // [self TCM_sendDidAcceptNotificationForSession:[aProfile session]];
}

- (void)profile:(HandshakeProfile *)aProfile receivedAckHandshakeWithUserID:(NSString *)aUserID {
    DEBUGLOG(@"MillionMonkeysLogDomain", AlwaysLogLevel, @"%@", aUserID);
/*    NSMutableDictionary *information = [self sessionInformationForUserID:aUserID];
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
    }*/
}

#pragma mark -
#pragma mark ### BEEPSession delegate ###

- (void)BEEPSession:(TCMBEEPSession *)aBEEPSession didReceiveGreetingWithProfileURIs:(NSArray *)aProfileURIArray
{
    DEBUGLOG(@"MillionMonkeysLogDomain", AlwaysLogLevel, @"didReceiveGreetingWithProfileURIs: %@",aProfileURIArray);
    if ([[aBEEPSession peerProfileURIs] containsObject:@"http://www.codingmonkeys.de/BEEP/SubEthaEditHandshake"]) {
        [aBEEPSession startChannelWithProfileURIs:[NSArray arrayWithObject:@"http://www.codingmonkeys.de/BEEP/SubEthaEditHandshake"] andData:nil sender:self];
    }
}

- (NSMutableDictionary *)BEEPSession:(TCMBEEPSession *)aBEEPSession willSendReply:(NSMutableDictionary *)aReply forChannelRequests:(NSArray *)aRequests
{
    DEBUGLOG(@"MillionMonkeysLogDomain", AlwaysLogLevel, @"%@",aReply);
    return aReply;
}

- (void)BEEPSession:(TCMBEEPSession *)aBEEPSession didOpenChannelWithProfile:(TCMBEEPProfile *)aProfile
{
    DEBUGLOG(@"MillionMonkeysLogDomain", AlwaysLogLevel, @"didOpenChannel");
    if ([[aProfile profileURI] isEqualToString:@"http://www.codingmonkeys.de/BEEP/SubEthaEditHandshake"]) {
        [aProfile setDelegate:self];
        if (![aProfile isServer]) {
            [(HandshakeProfile *)aProfile shakeHandsWithUserID:[self userID]];
        }
    } else if ([[aProfile profileURI] isEqualToString:@"http://www.codingmonkeys.de/BEEP/TCMMMStatus"]) {
        TCMMMStatusProfile *profile=(TCMMMStatusProfile *)aProfile;
        [profile setDelegate:self];
        if ([profile isServer]) {
            [profile sendUserDidChangeNotification];
            [profile sendVisibility:YES];
        }
//        [[TCMMMPresenceManager sharedInstance] acceptStatusProfile:(TCMMMStatusProfile *)aProfile];
    } else if ([[aProfile profileURI] isEqualToString:@"http://www.codingmonkeys.de/BEEP/SubEthaEditSession"]) {
        DEBUGLOG(@"MillionMonkeysLogDomain", AlwaysLogLevel, @"Got SubEthaEditSession profile");
        [aProfile setDelegate:self];
        //[I_pendingSessionProfiles addObject:aProfile];
    }
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
    [self endTest:@"failed"];
    DEBUGLOG(@"MillionMonkeysLogDomain", AlwaysLogLevel, @"%@", [self description]);
}

- (void)BEEPSessionDidClose:(TCMBEEPSession *)aBEEPSession
{
    [self endTest:@"closed"];
    [[I_BEEPSession retain] autorelease];
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
