//
//  main.m
//  seed
//
//  Created by Martin Ott on 3/12/07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SDAppController.h"

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

    SDAppController *appController = [[SDAppController alloc] init];


    // Setup user with ID and name, w/o you can't establish connections
    TCMMMUser *me = [[TCMMMUser alloc] init];
    [me setUserID:[NSString UUIDString]];
    [me setName:@"King Kong"];
    
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

    [[TCMMMBEEPSessionManager sharedInstance] listen];
    [[TCMMMPresenceManager sharedInstance] setVisible:YES];
    

    // set the TERM signal handler to 'catch_term' 
    signal(SIGTERM, catch_term);
    
    /*
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSMutableArray *filenames = [NSMutableArray array];
    int i;
    for (i = 1; i < argc; i++) {
        char resolved_path[PATH_MAX];
        char *path = realpath(argv[i], resolved_path);

        if (path) {
            NSString *fileName = [fileManager stringWithFileSystemRepresentation:path length:strlen(path)];
            NSLog(@"fileName after realpath: %@", fileName);
            [filenames addObject:fileName];
        } else {
            NSLog(@"Error occurred while resolving path: %s", argv[i]);
        }
    }
    
    [appController openFiles:filenames];
    */
    
    NSString *configFile = [defaults stringForKey:@"config"];
    if (configFile) {
        NSArray *configPlist = [NSArray arrayWithContentsOfFile:[configFile stringByExpandingTildeInPath]];
        if (configPlist) {
            NSEnumerator *enumerator = [configPlist objectEnumerator];
            NSDictionary *entry;
            while ((entry = [enumerator nextObject])) {
                NSString *file = [entry objectForKey:@"file"];
                NSString *mode = [entry objectForKey:@"mode"];
                [appController openFile:file modeIdentifier:mode];
            }
        }
    }
    
    
    
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
