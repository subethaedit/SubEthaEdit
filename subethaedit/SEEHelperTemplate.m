//
//  SEEHelperTemplate.m
//  SubEthaEdit
//
//  Created by Martin Ott on Tue Apr 13 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//
//

#import <Foundation/Foundation.h>

#import <string.h>	// For memcmp()...
#import <unistd.h>	// For exchangedata()
#import <sys/param.h>	// For MAXPATHLEN
#include <stdio.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <fcntl.h>

#include "MoreUNIX.h"
#include "MoreSecurity.h"
#include "MoreCFQ.h"

static OSStatus GetFileDescriptor(CFStringRef fileName, CFDictionaryRef *result)
{
    OSStatus err;
    NSMutableArray *descArray;
    int desc;
    NSNumber *descNum;
    
    NSLog(@"converting fileName: %@", (NSString *)fileName);
    const char *path = [[NSFileManager defaultManager] fileSystemRepresentationWithPath:(NSString *)fileName];
    
    descNum = NULL;
    
    descArray = [NSMutableArray new];
    err = MoreSecSetPrivilegedEUID();
    if (err == noErr) {
        desc = open(path, O_CREAT | O_RDWR, S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH);
        (void)MoreSecTemporarilySetNonPrivilegedEUID();
    }
    descNum = [NSNumber numberWithInt:desc];
    [descArray addObject:descNum];
    *result = (CFDictionaryRef)[[NSDictionary dictionaryWithObject:descArray forKey:(NSString *)kMoreSecFileDescriptorsKey] retain];
    NSLog(@"result dictionary: %@", (NSDictionary *)*result);
    [descArray release];
    
    return noErr;
}

static OSStatus ExchangeFileContents(CFStringRef path1, CFStringRef path2, CFDictionaryRef path2Attrs, CFDictionaryRef *result) {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    char cPath1[MAXPATHLEN+1];
    char cPath2[MAXPATHLEN+1];
    int err;
    OSStatus status;
    
    if (![(NSString *)path1 getFileSystemRepresentation:cPath1 maxLength:MAXPATHLEN] || ![(NSString *)path2 getFileSystemRepresentation:cPath2 maxLength:MAXPATHLEN]) return paramErr;

    status = MoreSecSetPrivilegedEUID();
    if (status == noErr) {
        
        err = exchangedata(cPath1, cPath2, 0) ? errno : 0;

        if (err == EACCES || err == EPERM) {	// Seems to be a write-protected or locked file; try temporarily changing
            NSDictionary *attrs = (NSDictionary *)path2Attrs ? (NSDictionary *)path2Attrs : [fileManager fileAttributesAtPath:(NSString *)path2 traverseLink:YES];
            NSNumber *curPerms = [attrs objectForKey:NSFilePosixPermissions];
            BOOL curImmutable = [attrs fileIsImmutable];
            if (curPerms) [fileManager changeFileAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedLong:[curPerms unsignedLongValue] | 0200], NSFilePosixPermissions, nil] atPath:(NSString *)path2];
            if (curImmutable) [fileManager changeFileAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], NSFileImmutable, nil] atPath:(NSString *)path2];
            err = exchangedata(cPath1, cPath2, 0) ? errno : 0;
            // Restore original values
            if (curPerms) [fileManager changeFileAttributes:[NSDictionary dictionaryWithObjectsAndKeys:curPerms, NSFilePosixPermissions, nil] atPath:(NSString *)path2];
            if (curImmutable) [fileManager changeFileAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSFileImmutable, nil] atPath:(NSString *)path2];
        }
        if (err == 0) {
            [fileManager removeFileAtPath:(NSString *)path1 handler:nil];
        } else {
            BOOL success = [fileManager movePath:(NSString *)path1 toPath:(NSString *)path2 handler:nil];
            if (!success) {
                [fileManager removeFileAtPath:(NSString *)path1 handler:nil];
                status = paramErr;
            }
        }
        
        (void)MoreSecTemporarilySetNonPrivilegedEUID();
    }
    
    return status;
}

static OSStatus TestToolCommandProc(AuthorizationRef auth, CFDictionaryRef request, CFDictionaryRef *result)
	// Our command callback for MoreSecHelperToolMain.  Extracts 
	// the command name from the request dictionary and calls 
	// through to the appropriate command handler (in this case 
	// there's only one).
{
    OSStatus 	err;
    CFStringRef command;

    assert(auth != NULL);
    assert(request != NULL);
    assert( result != NULL);
    assert(*result == NULL);
    assert(geteuid() == getuid());

    err = noErr;
    command = (CFStringRef)CFDictionaryGetValue(request, CFSTR("CommandName"));
    if ((command == NULL) || (CFGetTypeID(command) != CFStringGetTypeID())) {
        err = paramErr;
    }
    if (err == noErr) {
        if (CFEqual(command, CFSTR("GetFileDescriptor"))) {
            CFStringRef fileName = (CFStringRef)CFDictionaryGetValue(request, CFSTR("FileName"));
            err = GetFileDescriptor(fileName, result);
        } else if (CFEqual(command, CFSTR("ExchangeFileContents"))) {
            CFStringRef intermediateFileName = (CFStringRef)CFDictionaryGetValue(request, CFSTR("IntermediateFileName"));
            CFStringRef actualFileName = (CFStringRef)CFDictionaryGetValue(request, CFSTR("ActualFileName"));
            CFDictionaryRef attributes = (CFDictionaryRef)CFDictionaryGetValue(request, CFSTR("Attributes"));
            err = ExchangeFileContents(intermediateFileName, actualFileName, attributes, result);
        }
    }
    return err;
}


int main(int argc, const char *argv[]) {	

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSLog(@"PID %qd starting\nEUID = %ld\nRUID = %ld\n", (long long)getpid(), (long)geteuid(), (long)getuid());
        
    int err;
    int result;
    AuthorizationRef auth;
	
    // It's vital that we get any auth ref passed to us from 
    // AuthorizationExecuteWithPrivileges before we call 
    // MoreSecDestroyInheritedEnvironment, because AEWP passes its 
    // auth ref to us via the environment.
    //
    // auth may come back as NULL, and that's just fine.  It signals 
    // that we're not being executed by AuthorizationExecuteWithPrivileges.
        
    auth = MoreSecHelperToolCopyAuthRef();
    
    // Because we're normally running as a setuid root program, it's 
    // important that we not trust any information coming to us from 
    // our potentially malicious parent process.  
    // MoreSecDestroyInheritedEnvironment eliminates all sources of 
    // such information, so we can't depend on it ever if we try.

    err = MoreSecDestroyInheritedEnvironment(kMoreSecKeepStandardFilesMask, argv);
	
    // Mask SIGPIPE, otherwise stuff won't work properly.
    if (err == 0) {
        err = MoreUNIXIgnoreSIGPIPE();
    }
    
    // Call the MoreSecurity helper routine.
    if (err == 0) {
        err = MoreSecHelperToolMain(STDIN_FILENO, STDOUT_FILENO, auth, TestToolCommandProc, argc, argv);
    }

    // Map the error code to a tool result.
    result = MoreSecErrorToHelperToolResult(err);

    NSLog(@"PID %qd stopping\nerr = %d\nresult = %d", (long long)getpid(), err, result);
    [pool release];
        
    return result;
}