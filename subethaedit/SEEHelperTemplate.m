//
//  SEEHelperTemplate.m
//  SubEthaEdit
//
//  Created by Martin Ott on Tue Apr 13 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//
//

#import <Foundation/Foundation.h>

#include <stdio.h>
#include <unistd.h>
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


static OSStatus TestToolCommandProc(AuthorizationRef auth, CFDictionaryRef request, CFDictionaryRef *result)
	// Our command callback for MoreSecHelperToolMain.  Extracts 
	// the command name from the request dictionary and calls 
	// through to the appropriate command handler (in this case 
	// there's only one).
{
	OSStatus 	err;
	CFStringRef command;
        CFStringRef fileName;
	
	assert(auth != NULL);
	assert(request != NULL);
	assert( result != NULL);
	assert(*result == NULL);
	assert(geteuid() == getuid());
	
	err = noErr;
	command = (CFStringRef)CFDictionaryGetValue(request, CFSTR("CommandName"));
        fileName = (CFStringRef)CFDictionaryGetValue(request, CFSTR("FileName"));
	if (   (command == NULL) 
		|| (CFGetTypeID(command) != CFStringGetTypeID()) ) {
		err = paramErr;
	}
	if (err == noErr) {
                if (CFEqual(command, CFSTR("GetFileDescriptor"))) {
			// On the other hand, in this example, opening these low-numbered ports is 
			// not considered a privileged operation, and so we don't acquire a right 
			// before doing it.
			
			err = GetFileDescriptor(fileName, result);
		} else {
			err = paramErr;
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