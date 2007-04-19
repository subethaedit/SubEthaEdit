//
//  main.m
//  seed
//
//  Created by Martin Ott on 3/12/07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "sasl.h"

#import "SDAppController.h"

#import "TCMMillionMonkeys.h"
#import "HandshakeProfile.h"
#import "SessionProfile.h"


static int sasl_getopt_callback(void *context, const char *plugin_name, const char *option, const char **result, unsigned *len);
static int sasl_log_callback(void *context, int level, const char *message);

static sasl_callback_t callbacks[] = {
    {SASL_CB_GETOPT, &sasl_getopt_callback, NULL},
    {SASL_CB_LOG, &sasl_log_callback, NULL},
    {SASL_CB_LIST_END, NULL, NULL}
};

#pragma mark -

static int sasl_getopt_callback(void *context, const char *plugin_name, const char *option, const char **result, unsigned *len)
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
    DEBUGLOG(@"SASLLogDomain", SimpleLogLevel, @"plugin_name: %s, option: %s", plugin_name, option);

    [pool release];
    return SASL_OK;
}

static int sasl_log_callback(void *context, int level, const char *message)
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
    DEBUGLOG(@"SASLLogDomain", SimpleLogLevel, @"level: %d, message: %s", level, message);

    [pool release];
    return SASL_OK;
}

#pragma mark -

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

#pragma mark -

int main(int argc, const char *argv[])
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    BOOL isRunning = YES;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithInt:6942] forKey:DefaultPortNumber];
    [defaults setBool:YES forKey:@"EnableBEEPLogging"];
    [defaults setInteger:0 forKey:@"MillionMonkeysLogDomain"];
    [defaults setInteger:3 forKey:@"BEEPLogDomain"];
    [defaults setInteger:3 forKey:@"SASLLogDomain"];
    
    NSString *shortVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    NSString *bundleVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    NSLog(@"seed %@ (%@)", shortVersion, bundleVersion);
    
    endRunLoop = NO;


    const char *implementation;
    const char *version_string;
    int version_major;
    int version_minor;
    int version_step;
    int version_patch;
    sasl_version_info(&implementation, &version_string, &version_major, &version_minor, &version_step, &version_patch);
    NSLog(@"%s %s (%d.%d.%d.%d)", implementation, version_string, version_major, version_minor, version_step, version_patch);

    int result;
    result = sasl_server_init(callbacks, "seed");
    if (result != SASL_OK) {
        DEBUGLOG(@"SASLLogDomain", SimpleLogLevel, @"sasl_server_init failed");
    }
    
    NSMutableString *mechanisms = [[NSMutableString alloc] init];
    [mechanisms appendString:@"SASL mechanisms:\n"];
    const char **mech_list = sasl_global_listmech();
    const char *mech;
    int i = 0;
    while ((mech = mech_list[i++])) {
        [mechanisms appendFormat:@"\t%s\n", mech];
    }
    DEBUGLOG(@"SASLLogDomain", DetailedLogLevel, mechanisms);

    
    
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
