//
//  main.m
//  see
//
//  Created by Martin Ott on Tue Apr 14 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <getopt.h>
#import <stdio.h>

 static struct option longopts[] = {
    { "help",       no_argument,            0,  'h' },
    { "version",    no_argument,            0,  'v' },
    { "wait",       no_argument,            0,  'w' },
    { "resume",     no_argument,            0,  'r' },
    { "encoding",   required_argument,      0,  'e' },
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
    
    int ch;
    
    while ((ch = getopt_long(argc, (char * const *)argv, "hvwre:t:", longopts, NULL)) != -1) {
        switch(ch) {
            case 'h':
                NSLog(@"help");
                break;
            case 'v':
                break;
            case 'w':
                break;
            case 'r':
                break;
            case 'e':
                NSLog(@"encoding: %s", optarg);
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
    int i;
    for (i = 0; i < argc; i++) {
        [fileNames addObject:[fileManager stringWithFileSystemRepresentation:argv[i] length:strlen(argv[i])]];
    }
    NSLog(@"fileNames: %@", fileNames);
    
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
        [fileManager removeFileAtPath:fileName handler:nil];
    }
    
    [pool release];
    return 0;
}
