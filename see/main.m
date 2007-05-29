//
//  main.m
//  see
//
//  Created by Martin Ott on Tue Apr 14 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Carbon/Carbon.h>
#import <getopt.h>
#import <stdio.h>


/*

see -h
see -v
see -l
see -p [options] [files]
see [options] [files]

*/

static struct option longopts[] = {
    { "help",       no_argument,            0,  'h' }, // command
    { "version",    no_argument,            0,  'v' }, // command
    { "background", no_argument,            0,  'b' }, // option
    { "wait",       no_argument,            0,  'w' }, // option
    { "resume",     no_argument,            0,  'r' }, // option
    { "launch",     no_argument,            0,  'l' }, // command
    { "print",      no_argument,            0,  'p' }, // command/option
    { "encoding",   required_argument,      0,  'e' }, // option
    { "mode",       required_argument,      0,  'm' }, // option
    { "pipe-title", required_argument,      0,  't' }, // option
    { "job-description", required_argument, 0,  'j' }, // option
    { 0,            0,                      0,  0 }
};


static NSString *tempFileName() {
    static int sequenceNumber = 0;
    NSString *origPath = [@"/tmp" stringByAppendingPathComponent:@"see"];
    NSString *name;
    do {
        sequenceNumber++;
        name = [NSString stringWithFormat:@"see-%d-%d-%d", [[NSProcessInfo processInfo] processIdentifier], (int)[NSDate timeIntervalSinceReferenceDate], sequenceNumber];
        name = [[origPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:name];
    } while ([[NSFileManager defaultManager] fileExistsAtPath:name]);
    return name;
}


static void printHelp() {
    fprintf(stdout, "Usage: see [-bhlprvw] [-e encoding_name] [-m mode_identifier] [-t title] [-j description] [file ...]\n");
    fflush(stdout);
}

void parseShortVersionString(int *major, int *minor)
{
    NSString *shortVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    NSScanner *scanner = [NSScanner scannerWithString:shortVersion];
    (void)[scanner scanInt:major];
    (void)[scanner scanString:@"." intoString:nil];
    (void)[scanner scanInt:minor];
}

BOOL meetsRequiredVersion(NSString *string) {
    if (!string) {
        return NO;
    }
    
    int myMajor, myMinor;
    parseShortVersionString(&myMajor, &myMinor);
    
    BOOL result;
    int major = 0;
    int minor = 0;
    NSScanner *scanner = [NSScanner scannerWithString:string];
    result = ([scanner scanInt:&major]
        && [scanner scanString:@"." intoString:nil]
        && [scanner scanInt:&minor]);
    
    if (result) {
        if (major < myMajor
            || (major == myMajor && minor <= myMinor)) {
            return YES;
        }
    }
    
    return NO;
}

CFURLRef URLRefForSubEthaEdit() {
    OSStatus status = noErr;
    CFURLRef appURL = NULL;
    
    ProcessSerialNumber psn;
    psn.lowLongOfPSN = kNoProcess;
	psn.highLongOfPSN = kNoProcess;
    
    int bundleVersion = 0;

    while (!(status = GetNextProcess(&psn))) {
        CFDictionaryRef dict = ProcessInformationCopyDictionary(&psn, kProcessDictionaryIncludeAllInformationMask);
        if (dict) {
            NSString *bundleIdentifier = [(NSDictionary *)dict objectForKey:@"CFBundleIdentifier"];
            if ([bundleIdentifier isEqualToString:@"de.codingmonkeys.SubEthaEdit"]) {
                NSString *bundlePath = [(NSDictionary *)dict objectForKey:@"BundlePath"];
                NSBundle *appBundle = [NSBundle bundleWithPath:bundlePath];
                int version = [[[appBundle infoDictionary] objectForKey:@"CFBundleVersion"] intValue];
                NSString *minimumSeeToolVersionString = [[appBundle infoDictionary] objectForKey:@"TCMMinimumSeeToolVersion"];
                if (version > bundleVersion && meetsRequiredVersion(minimumSeeToolVersionString)) {
                    bundleVersion = version;
                    appURL = (CFURLRef)[NSURL fileURLWithPath:bundlePath];
                }
            }
            CFRelease(dict);
        }
    }
    
    if (appURL) {
        CFRetain(appURL);
        return appURL;
    }
            
    status = LSFindApplicationForInfo('Hdra', CFSTR("de.codingmonkeys.SubEthaEdit"), CFSTR("SubEthaEdit.app"), NULL, &appURL); // release appURL
    if (status == kLSApplicationNotFoundErr) {
        NSBundle *appBundle = [NSBundle bundleWithPath:[(NSURL *)appURL path]];
        NSString *minimumSeeToolVersionString = [[appBundle infoDictionary] objectForKey:@"TCMMinimumSeeToolVersion"];
        if (meetsRequiredVersion(minimumSeeToolVersionString)) {
            return appURL;
        }
        
    }
    
    appURL = NULL;
    bundleVersion = 0;
    CFURLRef testURL = CFURLCreateWithString(NULL, CFSTR("see://egal"), NULL);
    CFArrayRef array = LSCopyApplicationURLsForURL(testURL, kLSRolesAll);
    NSEnumerator *urlEnumerator = [(NSArray *)array objectEnumerator];
    NSURL *url = nil;
    while ((url = [urlEnumerator nextObject])) {
        NSBundle *appBundle = [NSBundle bundleWithPath:[url path]];
        int version = [[[appBundle infoDictionary] objectForKey:@"CFBundleVersion"] intValue];
        NSString *minimumSeeToolVersionString = [[appBundle infoDictionary] objectForKey:@"TCMMinimumSeeToolVersion"];
        if (version > bundleVersion && meetsRequiredVersion(minimumSeeToolVersionString)) {
            bundleVersion = version;
            if (appURL) CFRelease(appURL);
            appURL = (CFURLRef)url;
            CFRetain(appURL);
        }
    }
    if (testURL) CFRelease(testURL);
    if (array) CFRelease(array);
    return appURL;
}

static void printVersion() {
    OSStatus status = noErr;
    CFURLRef appURL = NULL;
    NSString *appVersion = @"";
    NSString *versionString = nil;
    NSString *localizedVersionString = nil;
    NSString *appShortVersionString = @"n/a";
    NSString *bundledSeeToolVersionString = nil;
    
    appURL = URLRefForSubEthaEdit();
    if (appURL != NULL) {
        NSBundle *appBundle = [NSBundle bundleWithPath:[(NSURL *)appURL path]];
        appVersion = [[appBundle infoDictionary] objectForKey:@"CFBundleVersion"];
        versionString = [[appBundle infoDictionary] objectForKey:@"CFBundleShortVersionString"];
        bundledSeeToolVersionString = [[appBundle infoDictionary] objectForKey:@"TCMBundledSeeToolVersion"];
        localizedVersionString = [[appBundle localizedInfoDictionary] objectForKey:@"CFBundleShortVersionString"];
        CFRelease(appURL);
    }
        
    if (versionString) {
        appShortVersionString = versionString;
    } else if (localizedVersionString) {
        appShortVersionString = localizedVersionString;
    }

    NSString *shortVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    NSString *bundleVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    fprintf(stdout, "see %s (%s)\n", [shortVersion UTF8String], [bundleVersion UTF8String]);
    if (appURL != NULL) {
        NSString *path = [(NSURL *)appURL path];
        fprintf(stdout, "%s %s (%s)\n", [path fileSystemRepresentation], [appShortVersionString UTF8String], [appVersion UTF8String]);
        if (bundledSeeToolVersionString) {
            int myMajor, myMinor;
            parseShortVersionString(&myMajor, &myMinor);
        
            BOOL result;
            BOOL newerBundledVersion = NO;
            int major = 0;
            int minor = 0;
            NSScanner *scanner = [NSScanner scannerWithString:bundledSeeToolVersionString];
            result = ([scanner scanInt:&major]
                && [scanner scanString:@"." intoString:nil]
                && [scanner scanInt:&minor]);
            
            if (result) {
                if (major > myMajor
                    || (major == myMajor && minor > myMinor)) {
                    newerBundledVersion = YES;
                }
            }

            if (newerBundledVersion) {
                fprintf(stdout, "\nA newer version of the see command line tool is available.\nThe found SubEthaEdit bundles version %s of the see command.\n\n", [bundledSeeToolVersionString UTF8String]);
            }
        }
    }
    fflush(stdout);
    
    if (kLSApplicationNotFoundErr == status || appURL == NULL) {
        fprintf(stderr, "see: Couldn't find compatible SubEthaEdit.\n     Please install a current version of SubEthaEdit.\n");
        fflush(stderr);
    }
}


static CFURLRef launchSubEthaEdit(NSDictionary *options) {
    OSStatus status = noErr;
    CFURLRef appURL = NULL;

    appURL = URLRefForSubEthaEdit(); 
    if (appURL == NULL) {
        fprintf(stderr, "see: Couldn't find compatible SubEthaEdit.\n     Please install a current version of SubEthaEdit.\n");
        fflush(stderr);
        return NULL;
    } else {
        BOOL dontSwitch = [[options objectForKey:@"background"] boolValue];
        
        LSLaunchURLSpec inLaunchSpec;
        inLaunchSpec.appURL = appURL;
        inLaunchSpec.itemURLs = NULL;
        inLaunchSpec.passThruParams = NULL;
        if (dontSwitch) {
            inLaunchSpec.launchFlags = kLSLaunchAsync | kLSLaunchDontSwitch;
        } else {
            inLaunchSpec.launchFlags = kLSLaunchNoParams;
        }
        inLaunchSpec.asyncRefCon = NULL;
        
        status = LSOpenFromURLSpec(&inLaunchSpec, NULL);
        return appURL;
    }
}


static NSAppleEventDescriptor *propertiesEventDescriptorWithOptions(NSDictionary *options) {
    NSAppleEventDescriptor *propRecord = [NSAppleEventDescriptor recordDescriptor];
    
    NSString *mode = [options objectForKey:@"mode"];
    if (mode) {
        [propRecord setDescriptor:[NSAppleEventDescriptor descriptorWithString:mode]
                       forKeyword:'Mode'];                
    }
    NSString *encoding = [options objectForKey:@"encoding"];
    if (encoding) {
        [propRecord setDescriptor:[NSAppleEventDescriptor descriptorWithString:encoding]
                       forKeyword:'Encd'];                
    }
                    
    return propRecord;
}


static NSArray *see(NSArray *fileNames, NSArray *newFileNames, NSString *stdinFileName, NSDictionary *options) {
    CFURLRef appURL = launchSubEthaEdit(options);
    if (!appURL) {
        return nil;
    }
    
    OSStatus status = noErr;
    NSString *appPath = [(NSURL *)appURL path];
    BOOL hasFound = NO;
    ProcessSerialNumber psn;
    psn.lowLongOfPSN = kNoProcess;
	psn.highLongOfPSN = kNoProcess;

    while (!(status = GetNextProcess(&psn))) {
        CFDictionaryRef dict = ProcessInformationCopyDictionary(&psn, kProcessDictionaryIncludeAllInformationMask);
        if (dict) {
            NSString *bundleIdentifier = [(NSDictionary *)dict objectForKey:@"CFBundleIdentifier"];
            if ([bundleIdentifier isEqualToString:@"de.codingmonkeys.SubEthaEdit"]) {
                NSString *bundlePath = [(NSDictionary *)dict objectForKey:@"BundlePath"];
                if ([appPath isEqualToString:bundlePath]) {
                    hasFound = YES;
                    CFRelease(dict);
                    break;
                }
            }
            CFRelease(dict);
        }
    }

    if (!hasFound) {
        return nil;
    }
    
    NSMutableArray *resultFileNames = [NSMutableArray array];
    AESendMode sendMode = kAENoReply;
    long timeOut = kAEDefaultTimeout;
    NSAppleEventDescriptor *addressDescriptor;
    
    addressDescriptor = [NSAppleEventDescriptor descriptorWithDescriptorType:typeProcessSerialNumber bytes:&psn length:sizeof(ProcessSerialNumber)];
    if (addressDescriptor != nil) {
        NSAppleEventDescriptor *appleEvent = [NSAppleEventDescriptor appleEventWithEventClass:'Hdra' eventID:'See ' targetDescriptor:addressDescriptor returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID];
        if (appleEvent != nil) {
        
            int i;
            int count = [fileNames count];
            if (count > 0) {
                NSAppleEventDescriptor *filesDesc = [NSAppleEventDescriptor listDescriptor];
                for (i = 0; i < count; i++) {
                    [filesDesc insertDescriptor:[NSAppleEventDescriptor descriptorWithString:[fileNames objectAtIndex:i]]
                                        atIndex:i + 1];
                }
                [appleEvent setParamDescriptor:filesDesc
                                    forKeyword:'File'];
            }
            
            count = [newFileNames count];
            if (count > 0) {
                NSAppleEventDescriptor *newFilesDesc = [NSAppleEventDescriptor listDescriptor];
                for (i = 0; i < count; i++) {
                    [newFilesDesc insertDescriptor:[NSAppleEventDescriptor descriptorWithString:[newFileNames objectAtIndex:i]]
                                           atIndex:i + 1];
                }
                [appleEvent setParamDescriptor:newFilesDesc
                                    forKeyword:'NuFl'];
            }
            
            if (stdinFileName) {
                sendMode = kAEWaitReply;
                [appleEvent setParamDescriptor:[NSAppleEventDescriptor descriptorWithString:stdinFileName]
                                    forKeyword:'Stdi'];
            }

            NSAppleEventDescriptor *propRecord = propertiesEventDescriptorWithOptions(options);
            [appleEvent setParamDescriptor:propRecord
                                forKeyword:keyAEPropData];
            
            NSString *jobDescription = [options objectForKey:@"job-description"];
            if (jobDescription) {
                [appleEvent setParamDescriptor:[NSAppleEventDescriptor descriptorWithString:jobDescription]
                                    forKeyword:'JobD'];
            }
            
            NSString *pipeTitle = [options objectForKey:@"pipe-title"];
            if (pipeTitle) {
                [appleEvent setDescriptor:[NSAppleEventDescriptor descriptorWithString:pipeTitle]
                               forKeyword:'Pipe'];

            }
            
            if ([options objectForKey:@"print"]) {
                [appleEvent setParamDescriptor:[NSAppleEventDescriptor descriptorWithBoolean:true]
                                    forKeyword:'Prnt'];
            }            
            
            if ([options objectForKey:@"wait"]) {
                sendMode = kAEWaitReply;
                timeOut = kNoTimeOut;
                [appleEvent setParamDescriptor:[NSAppleEventDescriptor descriptorWithBoolean:true]
                                    forKeyword:'Wait'];
            }
            
            if ([options objectForKey:@"pipe-out"]) {
                [appleEvent setParamDescriptor:[NSAppleEventDescriptor descriptorWithBoolean:true]
                                    forKeyword:'PipO'];
            }
                        
            AppleEvent reply;
            OSStatus err = AESendMessage([appleEvent aeDesc], &reply, sendMode, timeOut);
            if (err == noErr) {
                NSAppleEventDescriptor *replyDesc = [[NSAppleEventDescriptor alloc] initWithAEDescNoCopy:&reply];
                NSAppleEventDescriptor *directObjectDesc = [replyDesc descriptorForKeyword:keyDirectObject];
                if (directObjectDesc) {
                    int i;
                    int count = [directObjectDesc numberOfItems];
                    for (i = 1; i <= count; i++) {
                        NSString *item = [[directObjectDesc descriptorAtIndex:i] stringValue];
                        if (item) {
                            [resultFileNames addObject:item];
                        }
                    }
                }
                [replyDesc release];
            } else {
                fprintf(stderr, "see: Error occurred while sending AppleEvent: %d\n", (int)err);
                fflush(stderr);
            }
        }
    }
    
    return resultFileNames;
}


static void openFiles(NSArray *fileNames, NSDictionary *options) {

    OSErr err = noErr;
    ProcessSerialNumber psn = {0, kNoProcess};
    ProcessSerialNumber noPSN = {0, kNoProcess};
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL wait = [[options objectForKey:@"wait"] boolValue];
    BOOL resume = [[options objectForKey:@"resume"] boolValue];
    NSMutableDictionary *mutatedOptions = [[options mutableCopy] autorelease];
    int i = 0;
    int count = 0;
    
        
    err = GetFrontProcess(&psn);
    if (err != noErr) {
        psn = noPSN;
    }
    
    BOOL isStandardInputATTY = isatty([[NSFileHandle fileHandleWithStandardInput] fileDescriptor]);
    
    BOOL isStandardOutputATTY = isatty([[NSFileHandle fileHandleWithStandardOutput] fileDescriptor]);
    if (!isStandardOutputATTY) {
        [mutatedOptions setObject:[NSNumber numberWithBool:YES] forKey:@"wait"];
        [mutatedOptions setObject:[NSNumber numberWithBool:YES] forKey:@"pipe-out"];
        wait = YES;
    }
    
    
    //
    // Read from stdin when no file names have been specified
    //
    
    NSString *stdinFileName = nil;
    NSMutableArray *files = [NSMutableArray array];
    NSMutableArray *newFileNames = [NSMutableArray array];
    
    if ([fileNames count] == 0 || !isStandardInputATTY) {
        NSString *fileName = tempFileName();
        [fileManager createFileAtPath:fileName contents:[NSData data] attributes:nil];
        NSFileHandle *fdout = [NSFileHandle fileHandleForWritingAtPath:fileName];
        NSFileHandle *fdin = [NSFileHandle fileHandleWithStandardInput];
        unsigned length = 0; 
        while (TRUE) {
            NSData *data = [fdin readDataOfLength:1024];
            length += [data length];
            if ([data length] != 0) {
                [fdout writeData:data];
            } else {
                break;
            }
        }
        [fdout closeFile];
        
        if (length == 0) {
            (void)[[NSFileManager defaultManager] removeFileAtPath:stdinFileName handler:nil];
        } else {
            stdinFileName = fileName;
        }
    }
    
    if ([fileNames count] != 0) {
        BOOL isDir;
        count = [fileNames count];
        for (i = 0; i < count; i++) {
            NSString *fileName = [fileNames objectAtIndex:i];
            if ([fileManager fileExistsAtPath:fileName isDirectory:&isDir]) {
                if (isDir) {
                    //fprintf(stdout, "\"%s\" is a directory.\n", fileName);
                    //fflush(stdout);
                } else {
                    [files addObject:fileName];
                }
            } else {
                [newFileNames addObject:fileName];
            }
        }
    }
    

    NSArray *resultFileNames = see(files, newFileNames, stdinFileName, mutatedOptions);

    //
    // Bring terminal to front when wait and resume was specified
    //
    
    if (resume) {
        Boolean result;
        OSErr err = SameProcess(&psn, &noPSN, &result);
        if (err == noErr && !result) {
            (void)SetFrontProcess(&psn);
        }
    }
        

    //
    // Write files to stdout when it isn't a terminal
    //
    
    if (!isStandardOutputATTY) {
        int count = [resultFileNames count];
        NSFileHandle *fdout = [NSFileHandle fileHandleWithStandardOutput];
        for (i = 0; i < count; i++) {
            NSString *path = [resultFileNames objectAtIndex:i];
            NSFileHandle *fdin = [NSFileHandle fileHandleForReadingAtPath:path];
            while (TRUE) {
                NSData *data = [fdin readDataOfLength:1024];
                if ([data length] != 0) {
                    [fdout writeData:data];
                } else {
                    break;
                }
            }
            [fdin closeFile];
            (void)[[NSFileManager defaultManager] removeFileAtPath:path handler:nil];
        }
    }
    
    
    if (stdinFileName) {
        (void)[[NSFileManager defaultManager] removeFileAtPath:stdinFileName handler:nil];
    }
}


int main (int argc, const char * argv[]) {

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSMutableDictionary *options = [NSMutableDictionary dictionary];
    BOOL launch = NO;
    BOOL version = NO;
    BOOL help = NO;
    NSMutableArray *fileNames = [NSMutableArray array];
    int i;

    
    //
    // Parsing arguments
    //
    
    int ch;
    while ((ch = getopt_long(argc, (char * const *)argv, "bhlprvwe:m:t:j:", longopts, NULL)) != -1) {
        switch(ch) {
            case 'b':
                [options setObject:[NSNumber numberWithBool:YES] forKey:@"background"];
                break;
            case 'h':
                help = YES;
                break;
            case 'v':
                version = YES;
                break;
            case 'w':
                [options setObject:[NSNumber numberWithBool:YES] forKey:@"wait"];
                break;
            case 'r':
                [options setObject:[NSNumber numberWithBool:YES] forKey:@"resume"];
                break;
            case 'l':
                launch = YES;
                break;
            case 'p':
                [options setObject:[NSNumber numberWithBool:YES] forKey:@"print"];
                break;
            case 'e': {
                    // argument is a IANA charset name, convert using CFStringConvertIANACharSetNameToEncoding()
                    NSString *encoding = [NSString stringWithUTF8String:optarg];
                    [options setObject:encoding forKey:@"encoding"];
                } break;
            case 'm': {
                    // identifies mode via BundleIdentifier, e.g. SEEMode.Objective-C ("SEEMode." is optional)
                    NSString *mode = [NSString stringWithUTF8String:optarg];
                    [options setObject:mode forKey:@"mode"];
                } break;
            case 't': {
                    NSString *pipeTitle = [NSString stringWithUTF8String:optarg];
                    [options setObject:pipeTitle forKey:@"pipe-title"];
                } break;
            case 'j': {
                    NSString *jobDesc = [NSString stringWithUTF8String:optarg];
                    [options setObject:jobDesc forKey:@"job-description"];
                } break;
            case ':': // missing option argument
            case '?': // invalid option
            default:
                help = YES;
        }
    }
    
    
    //
    // Parsing filename arguments
    //
    
    argc -= optind;
    argv += optind;
    
    for (i = 0; i < argc; i++) {
        char resolved_path[PATH_MAX];
        char *path = realpath(argv[i], resolved_path);

        if (path) {
            NSString *fileName = [fileManager stringWithFileSystemRepresentation:path length:strlen(path)];
            //NSLog(@"fileName after realpath: %@", fileName);
            [fileNames addObject:fileName];
        } else {
            launch = YES;
            //NSLog(@"Error occurred while resolving path: %s", argv[i]);
        }
    }
        

    //
    // Executing command
    //
    
    if (help) {
        printHelp();
    } else if (version) {
        printVersion();
    } else if (launch && ([fileNames count] == 0)) {
        (void)launchSubEthaEdit(options);
    } else {
        openFiles(fileNames, options);
    }
        
    [pool release];
    return 0;
}