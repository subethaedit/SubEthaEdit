//
//  main.m
//  see
//
//  Created by Martin Ott on Tue Apr 14 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <getopt.h>


 static struct option longopts[] = {
    { "help",       no_argument,            0,  'h' },
    { "version",    no_argument,            0,  'v' },
    { "wait",       no_argument,            0,  'w' },
    { "resume",     no_argument,            0,  'r' },
    { "encoding",   required_argument,      0,  'e' },
    { "pipe-title", required_argument,      0,  't' },
    { 0,            0,                      0,  0 }
 };


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
    
    int i;
    for (i = 0; i < argc; i++) {
        NSLog(@"found file argument: %s", argv[i]);
    }
    
    // [NSFileHandle fileHandleWithStandardInput];
    
    [pool release];
    return 0;
}
