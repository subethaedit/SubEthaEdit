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


static struct option longopts[] = {
    { "help",       no_argument,            0,  'h' },
    { "version",    no_argument,            0,  'v' },
    { "wait",       no_argument,            0,  'w' },
    { "resume",     no_argument,            0,  'r' },
    { "launch",     no_argument,            0,  'l' },
    { "print",      no_argument,            0,  'p' },
    { "encoding",   required_argument,      0,  'e' },
    { "mode",       required_argument,      0,  'm' },
    { "pipe-title", required_argument,      0,  't' },
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
    fprintf(stdout, "Usage: see [-hlprvw] [-e encoding_name] [-m mode_name] [-t title] [file ...]\n");
    fflush(stdout);
}


static void printVersion() {
    fprintf(stdout, "see 1.0 (vXXX)\n");
    fflush(stdout);
}


static BOOL launchSubEthaEdit() {
    OSStatus status = noErr;
    CFURLRef appURL = NULL;

    status = LSFindApplicationForInfo('Hdra', CFSTR("de.codingmonkeys.SubEthaEdit"), NULL, NULL, &appURL); // release appURL
    if (kLSApplicationNotFoundErr == status) {
        fprintf(stdout, "Couldn't find SubEthaEdit: kLSApplicationNotFoundErr\n");
        fflush(stdout);
        return NO;
    } else {
        
        //appURL = (CFURLRef)[NSURL URLWithString:@"file:///Users/Shared/BuildProducts/SubEthaEdit.app"];
        
        LSLaunchURLSpec inLaunchSpec;
        inLaunchSpec.appURL = appURL;
        inLaunchSpec.itemURLs = NULL;
        inLaunchSpec.passThruParams = NULL;
        inLaunchSpec.launchFlags = kLSLaunchNoParams;
        inLaunchSpec.asyncRefCon = NULL;
        
        status = LSOpenFromURLSpec(&inLaunchSpec, NULL);
        return YES;
    }
}


static NSAppleEventDescriptor *eventDescriptorFromOptions(NSArray *fileURLs, BOOL wait, NSString *encoding, NSString *mode, BOOL temp, NSString *pipeTitle, BOOL print) {
    int i;
    OSType creatorCode = 'Hdra';
    NSAppleEventDescriptor *addressDescriptor;
    
    addressDescriptor = [NSAppleEventDescriptor descriptorWithDescriptorType:typeApplSignature bytes:&creatorCode length:sizeof(creatorCode)];
    if (addressDescriptor != nil) {
        NSAppleEventDescriptor *appleEvent = [NSAppleEventDescriptor appleEventWithEventClass:'Hdra' eventID:'See ' targetDescriptor:addressDescriptor returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID];
        if (appleEvent != nil) {
            NSAppleEventDescriptor *listDesc = [NSAppleEventDescriptor listDescriptor];
            for (i = 1; i <= [fileURLs count]; i++) {
                NSString *URLString = [[fileURLs objectAtIndex:i-1] absoluteString];
                [listDesc insertDescriptor:[NSAppleEventDescriptor descriptorWithString:URLString]
                                   atIndex:i];
            }
            [appleEvent setDescriptor:listDesc forKeyword:keyDirectObject];
            if (wait) {
                [appleEvent setDescriptor:[NSAppleEventDescriptor descriptorWithBoolean:true]
                               forKeyword:'Wait'];
            }
            if (encoding) {
                [appleEvent setDescriptor:[NSAppleEventDescriptor descriptorWithString:encoding]
                               forKeyword:'Enc '];
            }
            if (mode) {
                [appleEvent setDescriptor:[NSAppleEventDescriptor descriptorWithString:mode]
                               forKeyword:'Mode'];
            }
            if (temp) {
                [appleEvent setDescriptor:[NSAppleEventDescriptor descriptorWithBoolean:true]
                               forKeyword:'Temp'];
            }
            if (pipeTitle) {
                [appleEvent setDescriptor:[NSAppleEventDescriptor descriptorWithString:pipeTitle]
                               forKeyword:'Name'];
            }
            if (print) {
                [appleEvent setDescriptor:[NSAppleEventDescriptor descriptorWithBoolean:true]
                               forKeyword:'Prnt'];
            }
    
            return appleEvent;
        }
    }
    
    return nil;
}


int main (int argc, const char * argv[]) {

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL wait = NO;
    BOOL launch = NO;
    BOOL print = NO;
    BOOL version = NO;
    BOOL help = NO;
    BOOL resume = NO;
    NSString *encoding = nil;
    NSString *mode = nil;
    NSString *pipeTitle = nil;
    NSMutableArray *fileNames = [NSMutableArray array];
    NSMutableArray *fileURLs = [NSMutableArray array];
    int i;
    ProcessSerialNumber psn = {0, kNoProcess};
    ProcessSerialNumber noPSN = {0, kNoProcess};

    
    //
    // Parsing options
    //
    
    int ch;
    while ((ch = getopt_long(argc, (char * const *)argv, "hlprvwe:m:t:", longopts, NULL)) != -1) {
        switch(ch) {
            case 'h':
                help = YES;
                break;
            case 'v':
                version = YES;
                break;
            case 'w':
                wait = YES;
                break;
            case 'r':
                resume = YES;
                break;
            case 'l':
                launch = YES;
                break;
            case 'p':
                print = YES;
                break;
            case 'e':
                // argument is a IANA charset name, convert using CFStringConvertIANACharSetNameToEncoding()
                encoding = [NSString stringWithUTF8String:optarg];
                break;
            case 'm':
                // identifies mode via BundleIdentifier, e.g. SEEMode.Objective-C ("SEEMode." is optional)
                mode = [NSString stringWithUTF8String:optarg];
                break;
            case 't':
                pipeTitle = [NSString stringWithUTF8String:optarg];
                break;
            case ':': // missing option argument
            case '?': // invalid option
            default:
                help = YES;
        }
    }
    
    
    if (wait && resume) {
        OSErr err = GetFrontProcess(&psn);
        if (err != noErr) {
            psn = noPSN;
        }
    }
    
    //
    // Processing options
    //
    
    if (help) {
        printHelp();
    } else if (version) {
        printVersion();
    } else if (launch) {
        (void)launchSubEthaEdit();
    } else {
    
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
                [fileNames addObject:fileName];
                
                BOOL isDir;
                if ([fileManager fileExistsAtPath:fileName isDirectory:&isDir]) {
                    if (isDir) {
                        fprintf(stdout, "\"%s\" is a directory.\n", argv[i]);
                        fflush(stdout);
                    } else {
                        [fileURLs addObject:[NSURL fileURLWithPath:fileName]];                        
                    }
                } else {
                    fprintf(stdout, "\"%s\" not found.\n", argv[i]);
                    fflush(stdout);
                }
            } else {
                NSLog(@"Error occurred while resolving path: %s", argv[i]);
            }
        }
            
        /*
        BOOL isStandardOutputATTY = isatty([[NSFileHandle fileHandleWithStandardOutput] fileDescriptor]);
        if (!isStandardOutputATTY) {
            wait = YES;
        }
        NSLog(@"stdout a pipe? %@", isStandardOutputATTY ? @"NO" : @"YES");
        */
        

        //
        // Read from stdin when no file names have been specified
        //
        
        BOOL temp = NO;
        if ([fileNames count] == 0) {
            temp = YES;
            
            NSString *fileName = tempFileName();
            [fileManager createFileAtPath:fileName contents:[NSData data] attributes:nil];
            NSFileHandle *fdout = [NSFileHandle fileHandleForWritingAtPath:fileName];
            NSFileHandle *fdin = [NSFileHandle fileHandleWithStandardInput];
            while (TRUE) {
                NSData *data = [fdin readDataOfLength:1024];
                if ([data length] != 0) {
                    [fdout writeData:data];
                } else {
                    break;
                }
            }
            [fdout closeFile];
            [fileURLs addObject:[NSURL fileURLWithPath:fileName]];
        }
        
        //
        // Launch SubEthaEdit and relay arguments from cli via Apple Event
        //
        
        if (temp || [fileURLs count] > 0) {
            BOOL success = launchSubEthaEdit();
            if (success) {
                AppleEvent reply;
                AESendMode sendMode = kAENoReply;
                long timeOut = kAEDefaultTimeout;
                NSAppleEventDescriptor *desc = eventDescriptorFromOptions(fileURLs, wait, encoding, mode, temp, pipeTitle, print);
                
                if (desc) {
                    if (wait || temp) {
                        sendMode = kAEWaitReply;
                        timeOut = kNoTimeOut;            
                    }
                    
                    OSStatus err = AESendMessage([desc aeDesc], &reply, sendMode, timeOut);
                    if (err != noErr) {
                        NSLog(@"Error while sending Apple Event");
                    }
                }      
            }
        }
        
        //
        // Remove temp file
        //
        
        if (temp) {
            int count = [fileURLs count];
            for (i = 0; i < count; i++) {
                NSString *path = [[fileURLs objectAtIndex:i] path];
                [[NSFileManager defaultManager] removeFileAtPath:path handler:nil];
            }
        }
        
        //
        // Bring terminal to front when wait and resume was specified
        //
        
        if (wait && resume) {
            Boolean result;
            OSErr err = SameProcess(&psn, &noPSN, &result);
            if (err == noErr && !result) {
                (void)SetFrontProcess(&psn);
            }
        }
        
        /*
        if (!isStandardOutputATTY) {
            int count = [fileURLs count];
            NSFileHandle *fdout = [NSFileHandle fileHandleWithStandardOutput];
            for (i = 0; i < count; i++) {
                NSString *path = [[fileURLs objectAtIndex:i] path];
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
            }
        }
        */
    }
        
    [pool release];
    return 0;
}
