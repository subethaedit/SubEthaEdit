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
    { "encoding",   required_argument,      0,  'e' },
    { "mode",       required_argument,      0,  'm' },
    { "pipe-title", required_argument,      0,  't' },
    { 0,            0,                      0,  0 }
};


static NSString *tempFileName() {
    static int sequenceNumber = 0;
    NSString *origPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"tmp"];
    NSString *name;
    do {
        sequenceNumber++;
        name = [NSString stringWithFormat:@"%d-%d-%d.%@", [[NSProcessInfo processInfo] processIdentifier], (int)[NSDate timeIntervalSinceReferenceDate], sequenceNumber, [origPath pathExtension]];
        name = [[origPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:name];
    } while ([[NSFileManager defaultManager] fileExistsAtPath:name]);
    return name;
}


int main (int argc, const char * argv[]) {

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    BOOL shouldWait = NO;
    AESendMode sendMode = kAENoReply;

    int ch;
    
    while ((ch = getopt_long(argc, (char * const *)argv, "hvwre:m:t:", longopts, NULL)) != -1) {
        switch(ch) {
            case 'h':
                NSLog(@"help");
                break;
            case 'v':
                break;
            case 'w':
                shouldWait = YES;
                sendMode = kAEWaitReply;
                break;
            case 'r':
                break;
            case 'e':
                // argument is a IANA charset name, convert using CFStringConvertIANACharSetNameToEncoding()
                NSLog(@"encoding: %s", optarg);
                break;
            case 'm':
                // identifies mode via BundleIdentifier, e.g. SEEMode.Objective-C ("SEEMode." is optional)
                NSLog(@"mode: %s", optarg);
                break;
            case 't':
                break;
            case '?':
            default:
                NSLog(@"wrong argument");
        }
    }
    
    argc -= optind;
    argv += optind;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSMutableArray *fileNames = [NSMutableArray array];
    NSMutableArray *fileURLs = [NSMutableArray array];
    int i;
    for (i = 0; i < argc; i++) {
        char resolved_path[PATH_MAX];
        char *path = realpath(argv[i], resolved_path);

        if (path) {
            NSLog(@"resolved path: %s", path);
            NSString *fileName = [fileManager stringWithFileSystemRepresentation:path length:strlen(path)];
            [fileNames addObject:fileName];
            [fileURLs addObject:[NSURL fileURLWithPath:fileName]];
        } else {
            NSLog(@"Error occurred while resolving path: %s", argv[i]);
        }
    }
    NSLog(@"fileNames: %@", fileNames);
    NSLog(@"fileURLs: %@", fileURLs);
    
    if ([fileNames count] > 0) {
    
    } else {
        NSString *fileName = tempFileName();
        NSLog(@"write to file: %@", fileName);
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
        //[fileManager removeFileAtPath:fileName handler:nil];
        [fileURLs addObject:[NSURL fileURLWithPath:fileName]];
    }
    
    OSStatus status;
    CFURLRef appURL; // release this url
    //OSStatus status = LSFindApplicationForInfo('Hdra', CFSTR("de.codingmonkeys.SubEthaEdit"), NULL, NULL, &appURL);
    //if (kLSApplicationNotFoundErr == status) {
    //    NSLog(@"kLSApplicationNotFoundErr");
    //} else {
        appURL = (CFURLRef)[NSURL URLWithString:@"file:///Users/Shared/BuildProducts/SubEthaEdit.app"];
        NSLog(@"appURL: %@", (NSURL *)appURL);
        
        LSLaunchURLSpec inLaunchSpec;
        inLaunchSpec.appURL = appURL;
        inLaunchSpec.itemURLs = NULL;
        inLaunchSpec.passThruParams = NULL;
        inLaunchSpec.launchFlags = kLSLaunchNoParams;
        inLaunchSpec.asyncRefCon = NULL;
        
        status = LSOpenFromURLSpec(&inLaunchSpec, NULL);
        NSLog(@"LSOpenFromURLSpec? %d", status);  
                
        OSType creatorCode = 'Hdra';
        NSAppleEventDescriptor *addressDescriptor = [NSAppleEventDescriptor descriptorWithDescriptorType:typeApplSignature bytes:&creatorCode length:sizeof(creatorCode)];
        if (addressDescriptor != nil) {
            NSAppleEventDescriptor *appleEvent = [NSAppleEventDescriptor appleEventWithEventClass:'Foo ' eventID:'Bar ' targetDescriptor:addressDescriptor returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID];
            if (appleEvent != nil) {
                NSAppleEventDescriptor *listDesc = [NSAppleEventDescriptor listDescriptor];
                for (i = 1; i <= [fileURLs count]; i++) {
                    NSString *URLString = [[fileURLs objectAtIndex:i-1] absoluteString];
                    [listDesc insertDescriptor:[NSAppleEventDescriptor descriptorWithString:URLString]
                                       atIndex:i];
                }
                [appleEvent setDescriptor:listDesc forKeyword:keyDirectObject];
                if (shouldWait) {
                    [appleEvent setDescriptor:[NSAppleEventDescriptor descriptorWithBoolean:true]
                                   forKeyword:'Wait'];
                }
                AppleEvent reply;
                OSErr err = AESend([appleEvent aeDesc], &reply, sendMode, kAEHighPriority, kAEDefaultTimeout, NULL, NULL);
                if (err != noErr) {
                    NSLog(@"Error while sending Apple Event");
                }
            }
        }
    //}
    
    NSLog(@"stdout a pipe? %@", isatty([[NSFileHandle fileHandleWithStandardOutput] fileDescriptor]) ? @"NO" : @"YES");
    
    [pool release];
    return 0;
}
