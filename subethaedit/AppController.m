//
//  AppController.m
//  SubEthaEdit
//
//  Created by Martin Ott on Wed Feb 25 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <AddressBook/AddressBook.h>

#import "AppController.h"
#import "TCMMMUserManager.h"
#import "TCMMMUser.h"
#import "TCMPreferenceController.h"
#import "RendezvousBrowserController.h"
#import "DebugPreferences.h"
#import "EncodingPreferences.h"

#define PORTRANGESTART 12347
#define PORTRANGELENGTH 10

@implementation AppController

- (void)dealloc {
    [I_listener close];
    [I_listener release];
    [super dealloc];
}

- (void)addMe {
    ABPerson *meCard=[[ABAddressBook sharedAddressBook] me];

    // add self as user 
    TCMMMUser *me=[TCMMMUser new];
    
    NSString *myName;            
    NSImage *myImage;
    NSImage *scaledMyImage;
    if (meCard) {
        NSString *firstName = [meCard valueForProperty:kABFirstNameProperty];
        NSString *lastName = [meCard valueForProperty:kABLastNameProperty];            

        if ((firstName!=nil) && (lastName!=nil)) {
            myName=[NSString stringWithFormat:@"%@ %@",firstName,lastName];
        } else if (firstName!=nil) {
            myName=firstName;
        } else if (lastName!=nil) {
            myName=lastName;
        } else {
            myName=NSFullUserName();
        }
        NSData  *imageData;
        if (imageData=[meCard imageData]) {
            myImage=[[NSImage alloc]initWithData:imageData];
            [myImage setCacheMode:NSImageCacheNever];
        } else {
            myImage=[NSImage imageNamed:@"DefaultPerson.tiff"];
        }
    } else {
        myName=NSFullUserName();
        myImage=[NSImage imageNamed:@"DefaultPerson.tiff"];
    }
    
    // resizing the image
    [myImage setScalesWhenResized:YES];
    NSSize originalSize=[myImage size];
    NSSize newSize=NSMakeSize(64.,64.);
    if (originalSize.width>originalSize.height) {
        newSize.height=(int)(originalSize.height/originalSize.width*newSize.width);
        if (newSize.height<=0) newSize.height=1;
    } else {
        newSize.width=(int)(originalSize.width/originalSize.height*newSize.height);            
        if (newSize.width <=0) newSize.width=1;
    }
    [myImage setSize:newSize];
    scaledMyImage=[[NSImage alloc] initWithSize:newSize];
    [scaledMyImage lockFocus];
    NSGraphicsContext *context=[NSGraphicsContext currentContext];
    NSImageInterpolation oldInterpolation=[context imageInterpolation];
    [context setImageInterpolation:NSImageInterpolationHigh];
    [NSColor clearColor];
    NSRectFill(NSMakeRect(0.,0.,newSize.width,newSize.height));
    [myImage compositeToPoint:NSMakePoint(0.,0.) operation:NSCompositeCopy];
    [context setImageInterpolation:oldInterpolation];
    [scaledMyImage unlockFocus];

    NSString *userID=[[NSUserDefaults standardUserDefaults] stringForKey:@"UserID"];
    if (!userID) {
        CFUUIDRef myUUID = CFUUIDCreate(NULL);
        CFStringRef myUUIDString = CFUUIDCreateString(NULL, myUUID);
        userID=[[(NSString *)myUUIDString retain] autorelease];
        CFRelease(myUUIDString);
        CFRelease(myUUID);
        [[NSUserDefaults standardUserDefaults] setObject:userID forKey:@"UserID"];
    }
    [me setID:userID];

    [me setName:myName];
    [[me properties] setObject:scaledMyImage forKey:@"Image"];
    [myImage       release];
    [scaledMyImage release];
    TCMMMUserManager *userManager=[TCMMMUserManager sharedInstance];
    [userManager setMe:[me autorelease]];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    DebugPreferences *debugPrefs = [[DebugPreferences new] autorelease];
    [TCMPreferenceController registerPrefModule:debugPrefs];
    EncodingPreferences *encodingPrefs = [[EncodingPreferences new] autorelease];
    [TCMPreferenceController registerPrefModule:encodingPrefs];
    
    [self addMe];
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
    
    // Announce ourselves via rendezvous
    I_netService=[[NSNetService alloc] initWithDomain:@"" type:@"_emac._tcp." name:@"" port:I_listeningPort];
    TCMMMUser *me=[[TCMMMUserManager sharedInstance] me];
    [I_netService setProtocolSpecificInformation:[NSString stringWithFormat:@"txtvers=1\001name=%@\001userid=%@\001version=2",[me name],[me ID]]];
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
