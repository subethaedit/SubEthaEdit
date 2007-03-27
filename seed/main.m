//
//  main.m
//  seed
//
//  Created by Martin Ott on 3/12/07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SDAppController.m"

#import "TCMMillionMonkeys.h"
#import "HandshakeProfile.h"
#import "SessionProfile.h"


// 
// Signal handler for the TERM signal
//
void catch_term(int sig_num)
{
    // re-set the signal handler again to catch_term, for next time
    signal(SIGTERM, catch_term);
    write(fd, &sig_num, sizeof(sig_num));
    endRunLoop = YES;
}

int main(int argc, const char *argv[])
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    BOOL isRunning = YES;
    
    endRunLoop = NO;

    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithInt:6942] forKey:DefaultPortNumber];
    [defaults setBool:YES forKey:@"EnableBEEPLogging"];
    [defaults setInteger:3 forKey:@"MillionMonkeysLogDomain"];
    [defaults setInteger:0 forKey:@"BEEPLogDomain"];



    [[NSRunLoop currentRunLoop] addPort:[NSPort port] forMode:NSDefaultRunLoopMode];

    // Setup user with ID and name, w/o you can't establish connections
    TCMMMUser *me = [[TCMMMUser alloc] init];
    [me setUserID:[NSString UUIDString]];
    [me setName:@"Foo Bar"];
    //[[me properties] setObject:[NSData dataWithContentsOfFile:@"/Users/mbo/Pictures/mbo.png"] forKey:@"ImageAsPNG"];
    [me setUserHue:[NSNumber numberWithInt:5]];
    [[me properties] setObject:@"" forKey:@"Email"];
    [[me properties] setObject:@"" forKey:@"AIM"];
    [[TCMMMUserManager sharedInstance] setMe:me];
    [me release];
    
    
    [TCMBEEPChannel setClass:[HandshakeProfile class] forProfileURI:@"http://www.codingmonkeys.de/BEEP/SubEthaEditHandshake"];    
    [TCMBEEPChannel setClass:[TCMMMStatusProfile class] forProfileURI:@"http://www.codingmonkeys.de/BEEP/TCMMMStatus"];
    [TCMBEEPChannel setClass:[SessionProfile class] forProfileURI:@"http://www.codingmonkeys.de/BEEP/SubEthaEditSession"];

    [[TCMMMBEEPSessionManager sharedInstance] listen];
    [[TCMMMPresenceManager sharedInstance] setVisible:YES];
    
    
    SDAppController *appController = [[SDAppController alloc] init];
    
    // set the TERM signal handler to 'catch_term' 
    signal(SIGTERM, catch_term);
    
    
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
