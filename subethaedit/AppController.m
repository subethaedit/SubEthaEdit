//
//  AppController.m
//  SubEthaEdit
//
//  Created by Martin Ott on Wed Feb 25 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "AppController.h"
#import "TCMMMUserManager.h"
#import "TCMPreferenceController.h"
#import "RendezvousBrowserController.h"
#import "DebugPreferences.h"

#define PORTRANGESTART 12347
#define PORTRANGELENGTH 10

@implementation AppController

- (void)dealloc {
    [I_listener close];
    [I_listener release];
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {

    DebugPreferences *debugPrefs = [[DebugPreferences new] autorelease];
    [TCMPreferenceController registerPrefModule:debugPrefs];
    
    TCMMMUserManager *userManager=[TCMMMUserManager sharedInstance];
    // add self as user - now just to kill the warning: nothing
    [userManager description];
    // set up BEEPListener
    for (I_listeningPort=PORTRANGESTART;I_listeningPort<PORTRANGESTART+PORTRANGELENGTH;I_listeningPort++) {
        I_listener=[[TCMBEEPListener alloc] initWithPort:I_listeningPort];
        [I_listener setDelegate:self];
        if ([I_listener listen]) {
            DEBUGLOG(@"Application",3,@"Listening on Port: %d",I_listeningPort);
            break;
        } else {
            [I_listener release];
            I_listener=nil;
        }
    }
    // Announce ourselves via rendevous
    NSString *serviceName=[[NSHost currentHost] name];
    I_netService=[[NSNetService alloc] initWithDomain:@"" type:@"_emac._tcp." name:serviceName port:I_listeningPort];
    [I_netService setDelegate: self];
    [I_netService publish];
    
    [[RendezvousBrowserController new] showWindow:self];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    
}

#pragma mark -
#pragma mark ### Published NetService Delegate ###

// Error handling code
- (void)handleError:(NSNumber *)error withService:(NSNetService *)service
{
    NSLog(@"An error occurred with service %@.%@.%@, error code = %@",
        [service name], [service type], [service domain], error);
    // Handle error here
}

// Sent when the service is about to publish
- (void)netServiceWillPublish:(NSNetService *)netService {
    DEBUGLOG(@"Network",3,@"netServiceWillPublish: %@",netService);
    // You may want to do something here, such as updating a user interface
}


// Sent if publication fails
- (void)netService:(NSNetService *)netService
        didNotPublish:(NSDictionary *)errorDict {
    [self handleError:[errorDict objectForKey:NSNetServicesErrorCode] withService:netService];
}


// Sent when the service stops
- (void)netServiceDidStop:(NSNetService *)netService
{
    DEBUGLOG(@"Network",3,@"netServiceDidStop: %@",netService);
    // You may want to do something here, such as updating a user interface
}

#pragma mark -
#pragma mark ### BEEPListener delegate ###

- (BOOL)BEEPListener:(TCMBEEPListener *)aBEEPListener shouldAcceptBEEPSession:(TCMBEEPSession *)aBEEPSession {
    DEBUGLOG(@"Application",3,@"somebody talks to our listener: %@",[aBEEPSession description]);
    return YES;
}

- (void)BEEPListener:(TCMBEEPListener *)aBEEPListener didAcceptBEEPSession:(TCMBEEPSession *)aBEEPSession {
    NSLog(@"Got Session %@",aBEEPSession);
    //[aBEEPSession setProfileURIs:[NSArray arrayWithObject:kSimpleSendProfileURI]];
    [aBEEPSession open];
    [aBEEPSession setDelegate:self];
    [aBEEPSession retain];
}


@end
