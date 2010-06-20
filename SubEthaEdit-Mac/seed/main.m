//
//  main.m
//  seed
//
//  Created by Martin Ott on 3/12/07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SDAppController.h"
#import "SDDocumentManager.h"
#import "TCMMillionMonkeys.h"
#import "HandshakeProfile.h"
#import "SessionProfile.h"
#import "ServerManagementProfile.h"
#import "BacktracingException.h"
#import "SelectionOperation.h"
#import "TextOperation.h"
#import "UserChangeOperation.h"
#import "GenericSASLProfile.h"

#pragma mark -

// 
// Signal handler
//
void catch_signal(int sig_num) {
    write(fd, &sig_num, sizeof(sig_num));
}

#pragma mark -

int main(int argc, const char *argv[])
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    BOOL isRunning = YES;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithInt:6942] forKey:DefaultPortNumber];
    [defaults setBool:YES forKey:@"EnableTLS"];
    [defaults setBool:YES forKey:@"LogConnections"];
    [defaults setBool:NO forKey:@"EnableBEEPLogging"];
    [defaults setInteger:0 forKey:@"MillionMonkeysLogDomain"];
    [defaults setInteger:0 forKey:@"BEEPLogDomain"];
    [defaults setInteger:0 forKey:@"SASLLogDomain"];
    [defaults setObject:BASE_LOCATION forKey:@"base_location"];
    
    NSString *shortVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    NSString *bundleVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    NSLog(@"seed %@ (%@)", shortVersion, bundleVersion);
    
    endRunLoop = NO;
        
//    [BacktracingException install];
    [[NSRunLoop currentRunLoop] addPort:[NSPort port] forMode:NSDefaultRunLoopMode];

    [[TCMMMTransformator sharedInstance] registerTransformationTarget:[TextOperation class] selector:@selector(transformTextOperation:serverTextOperation:) forOperationId:[TextOperation operationID] andOperationID:[TextOperation operationID]];
    [[TCMMMTransformator sharedInstance] registerTransformationTarget:[SelectionOperation class] selector:@selector(transformOperation:serverOperation:) forOperationId:[SelectionOperation operationID] andOperationID:[TextOperation operationID]];
    [UserChangeOperation class];
    [TCMMMNoOperation class];

    SDAppController *appController = [[SDAppController alloc] init];

    
    
    // Setup user with ID and name, w/o you can't establish connections
    TCMMMUser *me = [[TCMMMUser alloc] init];
    [me setUserID:[NSString UUIDString]];
    NSString *myName = [defaults stringForKey:@"user_name"];
    if (!myName) myName = @"King Kong";
    [me setName:myName];
    
    NSString *imagePath = [defaults stringForKey:@"image"];
    if (imagePath) {
        NSData *imageData = [NSData dataWithContentsOfFile:[imagePath stringByExpandingTildeInPath]];
        if (imageData) {
            [[me properties] setObject:imageData forKey:@"ImageAsPNG"];
        }
    }
    
    [me setUserHue:[NSNumber numberWithInt:5]];
    [[me properties] setObject:@"monkeys@codingmonkeys.de" forKey:@"Email"];
    [[me properties] setObject:@"" forKey:@"AIM"];
    [[TCMMMUserManager sharedInstance] setMe:me];
    [me release];
    
    
    [TCMBEEPChannel setClass:[HandshakeProfile class] forProfileURI:@"http://www.codingmonkeys.de/BEEP/SubEthaEditHandshake"];    
    [TCMBEEPChannel setClass:[TCMMMStatusProfile class] forProfileURI:@"http://www.codingmonkeys.de/BEEP/TCMMMStatus"];
    [TCMBEEPChannel setClass:[SessionProfile class] forProfileURI:@"http://www.codingmonkeys.de/BEEP/SubEthaEditSession"];
    [TCMBEEPChannel setClass:[ServerManagementProfile class] forProfileURI:@"http://www.codingmonkeys.de/BEEP/SeedManagement"];
    [TCMBEEPChannel setClass:[GenericSASLProfile class] forProfileURI:TCMBEEPSASLPLAINProfileURI];

    TCMMMBEEPSessionManager *sm = [TCMMMBEEPSessionManager sharedInstance];
    [sm registerProfileURI:@"http://www.codingmonkeys.de/BEEP/SubEthaEditHandshake" forGreetingInMode:kTCMMMBEEPSessionManagerDefaultMode];
    [sm registerProfileURI:@"http://www.codingmonkeys.de/BEEP/TCMMMStatus"          forGreetingInMode:kTCMMMBEEPSessionManagerDefaultMode];
    [sm registerProfileURI:@"http://www.codingmonkeys.de/BEEP/SubEthaEditSession"   forGreetingInMode:kTCMMMBEEPSessionManagerDefaultMode];

    [sm registerProfileURI:@"http://www.codingmonkeys.de/BEEP/SubEthaEditHandshake" forGreetingInMode:kTCMMMBEEPSessionManagerTLSMode];
    [sm registerProfileURI:@"http://www.codingmonkeys.de/BEEP/TCMMMStatus"          forGreetingInMode:kTCMMMBEEPSessionManagerTLSMode];
    [sm registerProfileURI:@"http://www.codingmonkeys.de/BEEP/SubEthaEditSession"   forGreetingInMode:kTCMMMBEEPSessionManagerTLSMode];
    [sm registerProfileURI:@"http://www.codingmonkeys.de/BEEP/SeedManagement"   forGreetingInMode:kTCMMMBEEPSessionManagerTLSMode];
    [sm registerProfileURI:TCMBEEPSASLPLAINProfileURI                               forGreetingInMode:kTCMMMBEEPSessionManagerTLSMode];

    [sm listen];
    [[TCMMMPresenceManager sharedInstance] setVisible:YES];
    // [[TCMMMPresenceManager sharedInstance] startRendezvousBrowsing];
    

    // set the TERM signal handler to 'catch_term' 
    signal(SIGTERM, catch_signal);
    signal(SIGINT, catch_signal);
    signal(SIGINFO, catch_signal);
    
    
    NSString *configFile = [defaults stringForKey:@"config_file_path"];
    if (!configFile) {
        configFile = [[defaults stringForKey:@"base_location"] stringByAppendingPathComponent:@"config.plist"];
    }
    [appController readConfig:configFile];
    
    do {
        NSAutoreleasePool *subPool = [[NSAutoreleasePool alloc] init];
        isRunning = [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                             beforeDate:[NSDate distantFuture]];
        [subPool release];
    } while (isRunning && !endRunLoop);


    [appController release];
    
    NSLog(@"Bye bye!");

    [pool release];
    return 0;
}
