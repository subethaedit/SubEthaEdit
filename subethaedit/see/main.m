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


static NSAppleEventDescriptor *eventDescriptorFromOptions(NSArray *fileURLs, BOOL temp, NSDictionary *options) {
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
            if ([options objectForKey:@"wait"]) {
                [appleEvent setDescriptor:[NSAppleEventDescriptor descriptorWithBoolean:true]
                               forKeyword:'Wait'];
            }
            NSString *encoding = [options objectForKey:@"enocding"];
            if (encoding) {
                [appleEvent setDescriptor:[NSAppleEventDescriptor descriptorWithString:encoding]
                               forKeyword:'Enc '];
            }
            NSString *mode = [options objectForKey:@"mode"];
            if (mode) {
                [appleEvent setDescriptor:[NSAppleEventDescriptor descriptorWithString:mode]
                               forKeyword:'Mode'];
            }
            if (temp) {
                [appleEvent setDescriptor:[NSAppleEventDescriptor descriptorWithBoolean:true]
                               forKeyword:'Temp'];
            }
            NSString *pipeTitle = [options objectForKey:@"pipe-title"];
            if (pipeTitle) {
                [appleEvent setDescriptor:[NSAppleEventDescriptor descriptorWithString:pipeTitle]
                               forKeyword:'Name'];
            }
            if ([options objectForKey:@"print"]) {
                [appleEvent setDescriptor:[NSAppleEventDescriptor descriptorWithBoolean:true]
                               forKeyword:'Prnt'];
            }
    
            return appleEvent;
        }
    }
    
    return nil;
}


static void makeUntitledDocument(NSString *title, NSDictionary *options) {
    if (!launchSubEthaEdit()) {
        return;
    }
    
    OSType creatorCode = 'Hdra';
    NSAppleEventDescriptor *addressDescriptor;
    
    addressDescriptor = [NSAppleEventDescriptor descriptorWithDescriptorType:typeApplSignature bytes:&creatorCode length:sizeof(creatorCode)];
    if (addressDescriptor != nil) {
        NSAppleEventDescriptor *appleEvent = [NSAppleEventDescriptor appleEventWithEventClass:kAECoreSuite eventID:kAECreateElement targetDescriptor:addressDescriptor returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID];
        if (appleEvent != nil) {
            [appleEvent setParamDescriptor:[NSAppleEventDescriptor descriptorWithTypeCode:'pltd']
                                forKeyword:keyAEObjectClass];
            NSAppleEventDescriptor *propRecord = [NSAppleEventDescriptor recordDescriptor];
            [propRecord setDescriptor:[NSAppleEventDescriptor descriptorWithString:title]
                           forKeyword:pName];
            [appleEvent setParamDescriptor:propRecord
                                forKeyword:keyAEPropData];
            
            AppleEvent reply;
            OSStatus err = AESendMessage([appleEvent aeDesc], &reply, kAENoReply, kAEDefaultTimeout);
            if (err != noErr) {
                NSLog(@"Error while sending Apple Event");
            }
        }
    }
}


/*
static void makeUntitledDocumentFromFile(NSString *fileName, NSDictionary *options) {
    if (!launchSubEthaEdit()) {
        return;
    }
    
    OSType creatorCode = 'Hdra';
    NSAppleEventDescriptor *addressDescriptor;
    
    addressDescriptor = [NSAppleEventDescriptor descriptorWithDescriptorType:typeApplSignature bytes:&creatorCode length:sizeof(creatorCode)];
    if (addressDescriptor != nil) {
        NSAppleEventDescriptor *appleEvent = [NSAppleEventDescriptor appleEventWithEventClass:kAECoreSuite eventID:kAECreateElement targetDescriptor:addressDescriptor returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID];
        if (appleEvent != nil) {
            [appleEvent setParamDescriptor:[NSAppleEventDescriptor descriptorWithTypeCode:'pltd']
                                forKeyword:keyAEObjectClass];
            NSString *pipeTitle = [options objectForKey:@"pipe-title"];
            if (pipeTitle) {
                NSAppleEventDescriptor *propRecord = [NSAppleEventDescriptor recordDescriptor];
                [propRecord setDescriptor:[NSAppleEventDescriptor descriptorWithString:pipeTitle]
                               forKeyword:pName];
                [appleEvent setParamDescriptor:propRecord
                                    forKeyword:keyAEPropData];
            }
            
            AppleEvent reply;
            OSStatus err = AESendMessage([appleEvent aeDesc], &reply, kAEWaitReply, kAEDefaultTimeout);
            if (err == noErr) {
                NSAppleEventDescriptor *replyDesc = [[NSAppleEventDescriptor alloc] initWithAEDescNoCopy:&reply];
                NSLog(@"reply: %@", replyDesc);
                [replyDesc release];
            } else {
                NSLog(@"Error while sending Apple Event");
            }
        }
    }
}


static void openDocument(NSString *fileName, NSDictionary *options) {

}
*/


static void openFiles(NSArray *fileNames, NSDictionary *options) {

    OSErr err = noErr;
    ProcessSerialNumber psn = {0, kNoProcess};
    ProcessSerialNumber noPSN = {0, kNoProcess};
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSMutableArray *fileURLs = [NSMutableArray array];
    BOOL temp = NO;
    BOOL wait = [[options objectForKey:@"wait"] boolValue];
    BOOL resume = [[options objectForKey:@"resume"] boolValue];
    int i = 0;
    int count = 0;
    
        
    err = GetFrontProcess(&psn);
    if (err != noErr) {
        psn = noPSN;
    }
    
    
    //
    // Read from stdin when no file names have been specified
    //
    
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
        //makeUntitledDocumentFromFile(fileName, options);
        [fileURLs addObject:[NSURL fileURLWithPath:fileName]];
    } else {
        BOOL isDir;
        count = [fileNames count];
        for (i = 0; i < count; i++) {
            NSString *fileName = [fileNames objectAtIndex:i];
            if ([fileManager fileExistsAtPath:fileName isDirectory:&isDir]) {
                if (isDir) {
                    //fprintf(stdout, "\"%s\" is a directory.\n", fileName);
                    //fflush(stdout);
                } else {
                    //openDocument(fileName, options);
                    [fileURLs addObject:[NSURL fileURLWithPath:fileName]];                      
                }
            } else {
                makeUntitledDocument(fileName, options);
            }
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
    // Launch SubEthaEdit and relay arguments from cli via Apple Event
    //
    
    if (temp || [fileURLs count] > 0) {
        BOOL success = launchSubEthaEdit();
        if (success) {
            AppleEvent reply;
            AESendMode sendMode = kAENoReply;
            long timeOut = kAEDefaultTimeout;
            NSAppleEventDescriptor *desc = eventDescriptorFromOptions(fileURLs, temp, options);
            
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
    while ((ch = getopt_long(argc, (char * const *)argv, "hlprvwe:m:t:", longopts, NULL)) != -1) {
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
