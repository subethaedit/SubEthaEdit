/*
 *  SEEHelperTemplate.c
 *  SubEthaEdit
 *
 *  Created by Martin Ott on Tue Apr 13 2004.
 *  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
 *
 */

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
    CFShow(*result);
    OSStatus err;
    CFMutableArrayRef descArray;
    int desc;
    CFStringRef key;
    CFNumberRef descNum;
    
    descNum = NULL;
    
    err = CFQArrayCreateMutable(&descArray);
    if (err == noErr) {
        CFShow(CFSTR("created array"));
        err = MoreSecSetPrivilegedEUID();
        if (err == noErr) {
            desc = open("/tmp/foo", O_CREAT | O_RDWR, S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH);
            (void)MoreSecTemporarilySetNonPrivilegedEUID();
        }
        descNum = CFNumberCreate(NULL, kCFNumberIntType, &desc);
        CFArrayAppendValue(descArray, descNum);
        key = kMoreSecFileDescriptorsKey;
        *result = CFDictionaryCreate(NULL, (const void **)&key, (const void **)&descArray, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    } else {
    
        CFShow(CFSTR("failed to create array"));
    }
    
    
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


int main(int argc, const char *argv[])
	// Our main function.  Apart from comments and debugging, this looks 
	// remarkably like the template shown in "MoreSecurity.h" (-:
{	
	int 				err;
	int 				result;
	AuthorizationRef 	auth;
	
	#if MORE_DEBUG
		if (1) {
			fprintf(stderr, "PID %qd starting\n", (long long) getpid());
			fprintf(stderr, "  EUID = %ld\n", (long) geteuid());
			fprintf(stderr, "  RUID = %ld\n", (long) getuid());
			if (0) {
				fprintf(stderr, "Waiting for debugger\n");
				(void) pause();
			}
		}
	#endif
	
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

	#if MORE_DEBUG
		if (1) {
			fprintf(stderr, "PID %qd stopping\n", (long long) getpid());
			fprintf(stderr, "  err    = %d\n", err);
			fprintf(stderr, "  result = %d\n", result);
		}
	#endif
	
	return result;
}