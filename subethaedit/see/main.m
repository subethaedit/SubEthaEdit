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
    fprintf(stdout, "Usage: see [-hlprvw] [-e encoding_name] [-m mode_name] [-t title] [-j description] [file ...]\n");
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
    if (kLSApplicationNotFoundErr == status || appURL == NULL) {
        fprintf(stderr, "see: Couldn't locate SubEthaEdit.\n");
        fflush(stderr);
        return NO;
    } else {
        
        //NSBundle *appBundle = [NSBundle bundleWithPath:[(NSURL *)appURL path]];
        //NSString *bundleVersion = [[appBundle infoDictionary] objectForKey:@"CFBundleVersion"];
        //NSLog(@"Retrieved bundle version of installed SubEthaEdit: %@", bundleVersion);
        
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
    if (!launchSubEthaEdit()) {
        return nil;
    }
        
    NSMutableArray *resultFileNames = [NSMutableArray array];
    AESendMode sendMode = kAENoReply;
    long timeOut = kAEDefaultTimeout;
    OSType creatorCode = 'Hdra';
    NSAppleEventDescriptor *addressDescriptor;
    
    addressDescriptor = [NSAppleEventDescriptor descriptorWithDescriptorType:typeApplSignature bytes:&creatorCode length:sizeof(creatorCode)];
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
                //NSLog(@"Error while sending Apple Event: %d", err);
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
        while (TRUE) {
            NSData *data = [fdin readDataOfLength:1024];
            if ([data length] != 0) {
                [fdout writeData:data];
            } else {
                break;
            }
        }
        [fdout closeFile];
        stdinFileName = fileName;
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
    
    if (wait && resume) {
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
    while ((ch = getopt_long(argc, (char * const *)argv, "hlprvwe:m:t:j:", longopts, NULL)) != -1) {
        switch(ch) {
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
    } else if (launch) {
        (void)launchSubEthaEdit();
    } else {
        openFiles(fileNames, options);
    }
        
        
    [pool release];
    return 0;
}
