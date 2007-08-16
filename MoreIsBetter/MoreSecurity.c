/*
	File:		MoreSecurity.c

	Contains:	Security utilities.

	Written by:	Quinn

	Copyright:	Copyright (c) 2003 by Apple Computer, Inc., All Rights Reserved.

	Disclaimer:	IMPORTANT:  This Apple software is supplied to you by Apple Computer, Inc.
				("Apple") in consideration of your agreement to the following terms, and your
				use, installation, modification or redistribution of this Apple software
				constitutes acceptance of these terms.  If you do not agree with these terms,
				please do not use, install, modify or redistribute this Apple software.

				In consideration of your agreement to abide by the following terms, and subject
				to these terms, Apple grants you a personal, non-exclusive license, under Apple�s
				copyrights in this original Apple software (the "Apple Software"), to use,
				reproduce, modify and redistribute the Apple Software, with or without
				modifications, in source and/or binary forms; provided that if you redistribute
				the Apple Software in its entirety and without modifications, you must retain
				this notice and the following text and disclaimers in all such redistributions of
				the Apple Software.  Neither the name, trademarks, service marks or logos of
				Apple Computer, Inc. may be used to endorse or promote products derived from the
				Apple Software without specific prior written permission from Apple.  Except as
				expressly stated in this notice, no other rights or licenses, express or implied,
				are granted by Apple herein, including but not limited to any patent rights that
				may be infringed by your derivative works or by other works in which the Apple
				Software may be incorporated.

				The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO
				WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
				WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A PARTICULAR
				PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN
				COMBINATION WITH YOUR PRODUCTS.

				IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
				CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
				GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
				ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION
				OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY OF CONTRACT, TORT
				(INCLUDING NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN
				ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

	Change History (most recent first):

$Log: MoreSecurity.c,v $
Revision 1.11  2003/08/14 21:45:54  eskimo1
Improved the way temporary helper tools are handled.  I deleted the special routines to handle this case.  Now you just call the standard routines, passing them kTemporaryFolderType.

Revision 1.10  2003/08/08 15:40:16  eskimo1
Added support for helper tools in the Temporary Items folder. Also, changed some definitions to use the word "ownership" instead of "privileges", because that's what the Finder checkbox actually controls.

Revision 1.9  2003/05/25 12:50:28  eskimo1
Added support for descriptor passing. Modified handling of waitpid to make it easier to debug helper tools.

Revision 1.8  2003/04/14 15:53:13  eskimo1
In CopyDictionaryFromDescriptor, detect when dictSize is 0 and explicitly error.  This isn't strictly speaking necessary, but it means we always run the same code regardless of whether malloc(0) returns NULL or a zero length block.

Revision 1.7  2003/03/26 18:37:32  eskimo1
Fixed a bug where MoreSecIsFolderIgnoringPrivileges was returning false positives if the user's Application Support folder FGID was 99 (unknown).  I forgot that FSSetCatalogInfo doesn't actually set the FUID or FGUID.

Revision 1.6  2003/01/27 12:50:00  eskimo1
Use vfork instead of fork.  In this case speed probably isn't a big issue, but I want to set a good example.

Revision 1.5  2002/12/12 23:15:23  eskimo1
Switch EUID back to RUID after we return from the commandProc, just in case the client left it set the wrong way.

Revision 1.4  2002/12/12 15:41:53  eskimo1
Eliminate MoreAuthCopyRightCFString because it makes no sense.  A helper tool should always have the right name hard-wired into it, and hardwiring a C string is even easier than hardwiring a CFString.  Also added some more debugging printfs.

Revision 1.3  2002/11/25 16:42:25  eskimo1
Significant changes. Handle more edge cases better (for example, volumes with the "ignore permissions" flag turned on). Also brought MoreSecurity more into the CoreServices world.

Revision 1.2  2002/11/14 20:27:59  eskimo1
Compare time stamps in MoreSecCopyHelperToolURLRef to decide whether to throw away the tool and revert to the backup.  This greatly improves the debugging experience.  Also, in MoreSecExecuteRequestInHelperTool, add code to dispose of a partial response if we get an error (prevents a memory leak in some very specific error conditions). Finally, in MoreSecGetErrorFromResponse, eliminate an unnecessary CFRelease.

Revision 1.1  2002/11/09 00:08:36  eskimo1
First checked in. A module containing security helpers.


*/

/////////////////////////////////////////////////////////////////

// Our prototypes

#include "MoreSecurity.h"

// System interfaces

#include <unistd.h>
#include <fcntl.h>
#include <sys/time.h>
#include <sys/resource.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <sys/param.h>
#include <sys/socket.h>
#include <sys/mount.h>

// MIB Interfaces

#include "MoreUNIX.h"
#include "MoreCFQ.h"

/////////////////////////////////////////////////////////////////
#pragma mark ***** UID Management

extern int MoreSecPermanentlySetNonPrivilegedEUID(void)
	// See comment in header.
{
	int err;
                           
    err = setuid(getuid());
    if (err != 0) {
        err = errno;
    }
    return err;
}    
    
extern int MoreSecTemporarilySetNonPrivilegedEUID(void)
	// See comment in header.
{
	int err;
                           
    err = seteuid(getuid());
    if (err != 0) {
        err = errno;
    }
    return err;
}

extern int MoreSecSetPrivilegedEUID(void)
	// See comment in header.
{                           
	int err;

    err = seteuid(0);
    if (err != 0) {
        err = errno;
    }
	return err;
}
    
/////////////////////////////////////////////////////////////////
#pragma mark ***** MoreSecDestroyInheritedEnvironment

static int GetPathToSelf(char **pathToSelfPtr)
	// A simple wrapper around MoreGetExecutablePath which returns 
	// the path in a memory block that you must free.
{
	int 		err;
    uint32_t 	pathSize;
    char		junkChar;

	assert( pathToSelfPtr != NULL);
	assert(*pathToSelfPtr == NULL);

	*pathToSelfPtr = &junkChar;
	
	pathSize = 0;
	err = MoreGetExecutablePath(*pathToSelfPtr, &pathSize);
	if (pathSize == 0) {
		assert(err != 0);
		if (err != 0) {
			err = -1;
		}
		*pathToSelfPtr = NULL;
	} else {
		pathSize += 1;
		
		err = 0;
		*pathToSelfPtr = (char *) malloc(pathSize);
		if ( *pathToSelfPtr == NULL ) {
			err = ENOMEM;
		}

		if (err == 0) {
			err = MoreGetExecutablePath(*pathToSelfPtr, &pathSize);
		}
		
		if (err != 0) {
			free(*pathToSelfPtr);
			*pathToSelfPtr = NULL;
		}
	}

	assert( (err == 0) == (*pathToSelfPtr != NULL) );
	
	return err;
}

static int ResetArgvZero(const char **argv)
    // Sets argv[0] to be the true path to the executable 
    // rather than a potentially hostile value supplied by 
    // our parent process.
{
    int     err;
    char *  execPath;
    
    execPath = NULL;
    
    err = GetPathToSelf(&execPath);
    
    // Copy the real executable path into argv[0].
    
    if (err == 0) {
        argv[0] = execPath;
    }
    
    // If we got an error then free any buffer we may have 
    // allocated.  On no error we end up leaking execPath, but 
    // that's acceptable because this function is usually only 
    // called once at process startup.
    
    if (err != 0) {
        free(execPath);
    }
    
    return err;
}

extern char **environ;

static int ResetEnvironment(void)
    // Clears all environment variables.  There are circumstances 
    // where your process might depend on certain environment 
    // variables being set correctly, but if that's the case you 
    // shouldn't be relying on inheriting good values from an 
    // untrusted parent. You should, instead, set the environment 
    // variables explicitly after calling 
    // MoreSecDestroyInheritedEnvironment.
{
    while ( environ[0] != NULL ) {
        unsetenv(environ[0]);
    }
    return 0;
}

static int CloseOpenFileDescriptorsInRange(int start, int limit)
    // Closes all the file descriptor in the range 
    // start <= fd < limit. 
{
    int err;
    int fd;
    
    err = 0;
    for (fd = start; fd < limit; fd++) {
        err = close(fd);
        if (err == -1) {
            err = errno;
        }
        if (err == EBADF) {
            err = 0;
        }
        if (err != 0) {
            break;
        }
    }
    return err;
}

static int ResetAllSignalsToDefault(void)
    // Resets all signals to their default actions and the signal 
    // mask to its default value (empty). If you use signals in 
    // your program you should establish your signal handlers 
    // after calling MoreSecDestroyInheritedEnvironment.
{
    int         err;
    int         sig;
    sigset_t    empty;

    // First set all of the signals to their default actions.

    err = 0;
    for (sig = 0; sig < NSIG; sig++) {
        if ( signal(sig, SIG_DFL) == SIG_ERR ) {
            if (    sig == 0 
                 || sig == SIGKILL 
                 || sig == SIGSTOP) {
                // ignore the error
            } else {
                err = errno;
                break;
            }
        }
    }

    // Then set the signal mask to its default value (empty).
    
    if (err == 0) {
        err = sigemptyset(&empty);
        if (err == -1) {
            err = errno;
        }
    }
    if (err == 0) {
        err = sigprocmask(SIG_SETMASK, &empty, NULL);
        if (err == -1) {
            err = errno;
        }
    }
    
    return err;
}

// The following is a table of resource limits established 
// by this program. This table is based on the default values 
// from Mac OS X 10.1.x.  Unfortunately there's no way to 
// determine the system-wide defaults programmatically.

typedef struct {
    int     resource;
    rlim_t  rlim_cur;
    rlim_t  rlim_max;
} ResourceLimitTemplate;

static ResourceLimitTemplate kResourceLimits[9] = {
    {RLIMIT_CPU,     RLIM_INFINITY, RLIM_INFINITY},
    {RLIMIT_FSIZE,   RLIM_INFINITY, RLIM_INFINITY},
    {RLIMIT_DATA,    0x600000,      RLIM_INFINITY},
    {RLIMIT_STACK,   0x80000,       0x2000000    },
    {RLIMIT_CORE,    0,             RLIM_INFINITY},
    {RLIMIT_RSS,     RLIM_INFINITY, RLIM_INFINITY},
    {RLIMIT_MEMLOCK, RLIM_INFINITY, RLIM_INFINITY},
    {RLIMIT_NPROC,   100,           RLIM_INFINITY},
    {RLIMIT_NOFILE,  256,           RLIM_INFINITY}
};

// The upper bound for RLIMIT_NPROC is really 100, 
// or 532 if you're EUID 0.
//
// The upper bound for RLIMIT_NOFILE is really 10240, 
// or 12288 if you're EUID 0.
//
// The upper bound for RLIMIT_STACK was 0x4000000 and
// works on 10.3.9 and 10.4.x but not on 10.5.x.
//

static const int kResourceLimitsCount = 
        sizeof(kResourceLimits) / sizeof(kResourceLimits[0]);

static int ResetAllResourceLimitsToDefault(void)
    // Resets all resource limits to their defaults, 
    // based on the kResourceLimits table.  Note that we 
    // only attempt to set the rlim_max if we're EUID 0 
    // because getrlimit sometimes does not return the 
    // real maximum limit [2941095].
{
    int err;
    int i;
    
    err = 0;
    for (i = 0; i < kResourceLimitsCount; i++) {
        struct rlimit thisLimit;
        
        err = getrlimit(kResourceLimits[i].resource, 
                        &thisLimit);
        if (err == -1) {
            err = errno;
        }
        if (err == 0) {
            thisLimit.rlim_cur = kResourceLimits[i].rlim_cur;
            if (geteuid() == 0) {
                thisLimit.rlim_max = kResourceLimits[i].rlim_max;
            }
            err = setrlimit(kResourceLimits[i].resource, 
                            &thisLimit);
            if (err == -1 ) {
                err = errno;
            }
        }
        if (err != 0) {
            break;
        }
    }
    
    return err;
}

static int ResetAllTimers(void)
    // Disables all interval timers that might have 
    // been inherited from the parent process.
{
    int                 err;
    struct itimerval    disable;

    timerclear(&disable.it_interval);
    timerclear(&disable.it_value);
    
    err = setitimer(ITIMER_REAL,    &disable, NULL);
    if (err == -1) {
        err = errno;
    }
    err = setitimer(ITIMER_VIRTUAL, &disable, NULL);
    if (err == -1) {
        err = errno;
    }
    err = setitimer(ITIMER_PROF,    &disable, NULL);
    if (err == -1) {
        err = errno;
    }
    return err;
}

extern int MoreSecDestroyInheritedEnvironment(int whatToDubya, const char **argv)
	// See comment in header.
{
    int err;
    
    assert(    (argv != NULL) 
            || ((whatToDubya & kMoreSecKeepArg0Mask) != 0) );
    
    err = 0;
    
    if (    (err == 0) 
         && !(whatToDubya & kMoreSecKeepArg0Mask) ) {
        err = ResetArgvZero(argv);
    }
    if (    (err == 0) 
         && !(whatToDubya & kMoreSecKeepEnvironmentMask) ) {
        err = ResetEnvironment();
    }
    if (    (err == 0) 
         && !(whatToDubya & kMoreSecKeepStandardFilesMask) ) {
        err = CloseOpenFileDescriptorsInRange(0, 3);
    }
    if (    (err == 0) 
         && !(whatToDubya & kMoreSecKeepOtherFilesMask) ) {
        err = CloseOpenFileDescriptorsInRange(
                              3, 
                              getdtablesize());
    }
    if (    (err == 0) 
         && !(whatToDubya & kMoreSecKeepSignalsMask) ) {
        err = ResetAllSignalsToDefault();
    }
    if (    (err == 0) 
         && !(whatToDubya & kMoreSecKeepUmaskMask) ) {
        (void) umask(S_IRWXG | S_IRWXO);
    }
    if (    (err == 0) 
         && !(whatToDubya & kMoreSecKeepNiceMask) ) {
        err = nice(0);
        if (err == -1) {
            err = errno;
        }
    }
    if (    (err == 0) 
         && !(whatToDubya & kMoreSecKeepResourceLimitsMask) ) {
        err = ResetAllResourceLimitsToDefault();
    }
    if (    (err == 0) 
         && !(whatToDubya & kMoreSecKeepCurrentDirMask) ) {
        err = chdir("/");
        if (err == -1) {
            err = errno;
        }
    }
    if (    (err == 0) 
         && !(whatToDubya & kMoreSecKeepTimersMask) ) {
        err = ResetAllTimers();
    }
    
    return err;
}

/////////////////////////////////////////////////////////////////
#pragma mark ***** Helper Tool Common

static OSStatus CopyDictionaryFromDescriptor(int fdIn, CFDictionaryRef *dictResult)
	// Create a CFDictionary by reading the XML data from fdIn. 
	// It first reads the size of the XML data, then allocates a 
	// buffer for that data, then reads the data in, and finally 
	// unflattens the data into a CFDictionary.
	//
	// See also the companion routine, WriteDictionaryToDescriptor, below.
{
	OSStatus			err;
	CFIndex				dictSize;
	UInt8 *				dictBuffer;
	CFDataRef			dictData;
	CFPropertyListRef 	dict;

	assert(fdIn >= 0);
	assert( dictResult != NULL);
	assert(*dictResult == NULL);
	
	dictBuffer = NULL;
	dictData   = NULL;
	dict       = NULL;

	// Read the data size and allocate a buffer.
	
	err = EXXXToOSStatus( MoreUNIXRead(fdIn, &dictSize, sizeof(dictSize), NULL) );
	if (err == noErr) {
		if (dictSize == 0) {
			// malloc(0) may return NULL, so we specifically check for and error 
			// out in that case.
			err = paramErr;
		} else if (dictSize > (1 * 1024 * 1024)) {
			// Abitrary limit to prevent potentially hostile client overwhelming us with data.
			err = memFullErr;
		}
	}
	if (err == noErr) {
		dictBuffer = (UInt8 *) malloc( (size_t) dictSize);
		if (dictBuffer == NULL) {
			err = memFullErr;
		}
	}
	
	// Read the data and unflatten.
	
	if (err == noErr) {
		err = EXXXToOSStatus( MoreUNIXRead(fdIn, dictBuffer, (size_t) dictSize, NULL) );
	}
	if (err == noErr) {
		dictData = CFDataCreateWithBytesNoCopy(NULL, dictBuffer, dictSize, kCFAllocatorNull);
		err = CFQError(dictData);
	}
	if (err == noErr) {
		dict = CFPropertyListCreateFromXMLData(NULL, dictData, kCFPropertyListImmutable, NULL);
		err = CFQError(dict);
	}
	if ( (err == noErr) && (CFGetTypeID(dict) != CFDictionaryGetTypeID()) ) {
		err = paramErr;		// only CFDictionaries need apply
	}
	// CFShow(dict);
	
	// Clean up.
	
	if (err != noErr) {
		CFQRelease(dict);
		dict = NULL;
	}
	*dictResult = (CFDictionaryRef) dict;

	free(dictBuffer);
	CFQRelease(dictData);
	
	assert( (err == noErr) == (*dictResult != NULL) );
	
	return err;
}

static OSStatus WriteDictionaryToDescriptor(CFDictionaryRef dict, int fdOut)
	// Write a dictionary to a file descriptor by flattening 
	// it into XML.  Send the size of the XML before sending 
	// the data so that CopyDictionaryFromDescriptor knows 
	// how much to read.
{
	OSStatus			err;
	CFDataRef			dictData;
	CFIndex				dictSize;
	UInt8 *				dictBuffer;

	assert(dict != NULL);
	assert(fdOut >= 0);
	
    dictSize   = 0;
	dictData   = NULL;
	dictBuffer = NULL;
	
	dictData = CFPropertyListCreateXMLData(NULL, dict);
	err = CFQError(dictData);
	
	// Allocate sizeof(size_t) extra bytes in the buffer so that we can 
	// prepend the dictSize.  This allows us to write the entire 
	// dict with one MoreUNIXWrite call, which definitely speeds 
	// things up, especially if this is was going over a real wire.
	// Of course, if I was to send this over a real wire, I would 
	// have to guarantee that dictSize was sent in network byte order (-:
	
	if (err == noErr) {
		dictSize = CFDataGetLength(dictData);
		dictBuffer = (UInt8 *) malloc( sizeof(size_t) + dictSize );
		if (dictBuffer == NULL) {
			err = memFullErr;
		}
	}
	
	if (err == noErr) {
		// Copy dictSize into the first size_t bytes of the buffer.
		
		*((size_t *) dictBuffer) = (size_t) dictSize;
		
		// Copy the data into the remaining bytes.
		//
		// Can't use CFDataGetBytePtr because there's no guarantee that 
		// it will succeed.  If it doesn't, we have to copy the bytes anyway,
		// so the allocation code has to exist.  Given that this isn't a 
		// performance critical path, I might as well minimise my code size by 
		// always running the allocation code.
		
		CFDataGetBytes(dictData, CFRangeMake(0, dictSize), dictBuffer + sizeof(size_t));
		
		err = EXXXToOSStatus( MoreUNIXWrite(fdOut, dictBuffer, sizeof(size_t) + dictSize, NULL) );
	}

	free(dictBuffer);
	CFQRelease(dictData);
		
	return err;
}

extern void MoreSecCloseDescriptorArray(CFArrayRef descArray)
	// See comment in header.
{
	int			junk;
	CFIndex		descCount;
	CFIndex		descIndex;

	// I decided to allow descArray to be NULL because it makes it 
	// easier to call this routine using the code.
	//
	// MoreSecCloseDescriptorArray((CFArrayRef) CFDictionaryGetValue(response, kMoreSecFileDescriptorsKey));
	
	if (descArray != NULL) {
		if (CFGetTypeID(descArray) == CFArrayGetTypeID()) {
			descCount = CFArrayGetCount(descArray);

			for (descIndex = 0; descIndex < descCount; descIndex++) {
				CFNumberRef thisDescNum;
				int 		thisDesc;
		
				thisDescNum = (CFNumberRef) CFArrayGetValueAtIndex(descArray, descIndex);
				if (   (thisDescNum == NULL) 
					|| (CFGetTypeID(thisDescNum) != CFNumberGetTypeID()) 
					|| ! CFNumberGetValue(thisDescNum, kCFNumberIntType, &thisDesc) ) {
					assert(false);
				} else {
					assert(thisDesc >= 0);
					junk = close(thisDesc);
					assert(junk == 0);
				}
			}
		} else {
			assert(false);
		}
	}
}

static int CopyDictionaryTranslatingDescriptors(int fdIn, CFDictionaryRef *response)
	// Reads a dictionary and its associated descriptors from fdIn, 
	// putting the dictionary (modified to include the translated 
	// descriptor numbers) in *response.
{
	int 				err;
	int 				junk;
	CFDictionaryRef		receivedResponse;
	CFArrayRef 			incomingDescs;
	
	assert(fdIn >= 0);
	assert( response != NULL);
	assert(*response == NULL);
	
	receivedResponse = NULL;
	
	// Read the dictionary.
	
	err = OSStatusToEXXX( CopyDictionaryFromDescriptor(fdIn, &receivedResponse) );
	
	// Now read the descriptors, if any.
	
	if (err == 0) {
		incomingDescs = (CFArrayRef) CFDictionaryGetValue(receivedResponse, kMoreSecFileDescriptorsKey);
		if (incomingDescs == NULL) {
			// No descriptors.  Not much to do.  Just use receivedResponse as 
			// the response.
			
			*response = receivedResponse;
			receivedResponse = NULL;
		} else {
			CFMutableArrayRef 		translatedDescs;
			CFMutableDictionaryRef	mutableResponse;
			CFIndex					descCount;
			CFIndex					descIndex;
			
			// We have descriptors, so there's lots of stuff to do.  Have to 
			// receive each of the descriptors assemble them into the 
			// translatedDesc array, then create a mutable dictionary based 
			// on response (mutableResponse) and replace the 
			// kMoreSecFileDescriptorsKey with translatedDesc.
			
			translatedDescs  = NULL;
			mutableResponse  = NULL;

			// Start by checking incomingDescs.
					
			if ( CFGetTypeID(incomingDescs) != CFArrayGetTypeID() ) {
				err = kCFQDataErr;
			}
			
			// Create our output data.
			
			if (err == 0) {
				err = CFQArrayCreateMutable(&translatedDescs);
			}
			if (err == 0) {
				mutableResponse = CFDictionaryCreateMutableCopy(NULL, 0, receivedResponse);
				if (mutableResponse == NULL) {
					err = OSStatusToEXXX( coreFoundationUnknownErr );
				}
			}

			// Now read each incoming descriptor, appending the results 
			// to translatedDescs as we go.  By keeping our working results 
			// in translatedDescs, we make sure that we can clean up if 
			// we fail.
			
			if (err == 0) {
				descCount = CFArrayGetCount(incomingDescs);
				
				// We don't actually depend on the descriptor values in the 
				// response (that is, the elements of incomingDescs), because 
				// they only make sense it the context of the sending process. 
				// All we really care about is the number of elements, which 
				// tells us how many times to go through this loop.  However, 
				// just to be paranoid, in the debug build I check that the 
				// incoming array is well formed.

				#if MORE_DEBUG
					for (descIndex = 0; descIndex < descCount; descIndex++) {
						int 		thisDesc;
						CFNumberRef thisDescNum;
						
						thisDescNum = (CFNumberRef) CFArrayGetValueAtIndex(incomingDescs, descIndex);
						assert(thisDescNum != NULL);
						assert(CFGetTypeID(thisDescNum) == CFNumberGetTypeID());
						assert(CFNumberGetValue(thisDescNum, kCFNumberIntType, &thisDesc));
						assert(thisDesc >= 0);
					}
				#endif
				
				// Here's the real work.  For descCount times, read a descriptor 
				// from fdIn, wrap it in a CFNumber, and append it to translatedDescs. 
				// Note that we have to be very careful not to leak a descriptor 
				// if we get an error here.
				
				for (descIndex = 0; descIndex < descCount; descIndex++) {
					int 		thisDesc;
					CFNumberRef thisDescNum;
					
					thisDesc = -1;
					thisDescNum = NULL;
					
					err = MoreUNIXReadDescriptor(fdIn, &thisDesc);
					if (err == 0) {
						thisDescNum = CFNumberCreate(NULL, kCFNumberIntType, &thisDesc);
						if (thisDescNum == NULL) {
							err = OSStatusToEXXX( coreFoundationUnknownErr );
						}
					}
					if (err == 0) {
						CFArrayAppendValue(translatedDescs, thisDescNum);
						// The descriptor is now stashed in translatedDescs, 
						// so this iteration of the loop is no longer responsible 
						// for closing it.
						thisDesc = -1;		
					}
					
					CFQRelease(thisDescNum);
					if (thisDesc != -1) {
						junk = close(thisDesc);
						assert(junk == 0);
					}
					
					if (err != 0) {
						break;
					}
				}
			}

			// Clean up and establish output parameters.
			
			if (err == 0) {
				CFDictionarySetValue(mutableResponse, kMoreSecFileDescriptorsKey, translatedDescs);
				*response = mutableResponse;
			} else {
				MoreSecCloseDescriptorArray(translatedDescs);
				CFQRelease(mutableResponse);
			}
			CFQRelease(translatedDescs);
		}
	}
	
	CFQRelease(receivedResponse);
	
	assert( (err == 0) == (*response != NULL) );
	
	return err;
}

static int WriteDictionaryAndDescriptors(CFDictionaryRef response, int fdOut)
	// Writes a dictionary and its associated descriptors to fdOut.
{
	int 			err;
	CFArrayRef 		descArray;
	CFIndex			descCount;
	CFIndex			descIndex;
	
	// Write the dictionary.
	
	err = OSStatusToEXXX( WriteDictionaryToDescriptor(response, fdOut) );
	
	// Process any descriptors.  The descriptors are indicated by 
	// a special key in the dictionary.  If that key is present, 
	// it's a CFArray of CFNumbers that present the descriptors to be 
	// passed.
	
	if (err == 0) {
		descArray = (CFArrayRef) CFDictionaryGetValue(response, kMoreSecFileDescriptorsKey);
		
		// We only do the following if the special key is present.
		
		if (descArray != NULL) {
		
			// If it's not an array, that's bad.
			
			if ( CFGetTypeID(descArray) != CFArrayGetTypeID() ) {
				err = EINVAL;
			}
			
			// Loop over the array, getting each descriptor and writing it.
			
			if (err == 0) {
				descCount = CFArrayGetCount(descArray);
				
				for (descIndex = 0; descIndex < descCount; descIndex++) {
					CFNumberRef thisDescNum;
					int 		thisDesc;
					
					thisDescNum = (CFNumberRef) CFArrayGetValueAtIndex(descArray, descIndex);
					if (   (thisDescNum == NULL) 
						|| (CFGetTypeID(thisDescNum) != CFNumberGetTypeID()) 
						|| ! CFNumberGetValue(thisDescNum, kCFNumberIntType, &thisDesc) ) {
						err = EINVAL;
					}
					if (err == 0) {
						err = MoreUNIXWriteDescriptor(fdOut, thisDesc);
					}

					if (err != 0) {
						break;
					}
				}
			}
		}
	}

	return err;
}

extern int MoreSecErrorToHelperToolResult(int errNum)
	// See comment in header.
{
	int result;
	
	switch (errNum) {
		case 0:
			result = 0;
			break;
		case errAuthorizationDenied:
			result = (kMoreSecResultPrivilegesErr - kMoreSecResultBase);
			break;
		case errAuthorizationCanceled:
			result = (kMoreSecResultCanceledErr - kMoreSecResultBase);
			break;
		default:
			if ( (errNum >= kMoreSecFirstResultErr) && (errNum <= kMoreSecLastResultErr) ) {
				result = (errNum - kMoreSecResultBase);
			} else {
				result = (kMoreSecResultInternalErrorErr - kMoreSecResultBase);
			}
			break;
	}
	return result;
}

extern int MoreSecHelperToolResultToError(int toolResult)
	// See comment in header.
{
	int err;
	
	if (toolResult == 0) {
		err = 0;
	} else {
		if ( (toolResult > 0) && (toolResult <= (kMoreSecLastResultErr - kMoreSecResultBase)) ) {
			err = (toolResult + kMoreSecResultBase);
		} else {
			err = kMoreSecResultInternalErrorErr;
		}
	}
	return err;
}

/////////////////////////////////////////////////////////////////
#pragma mark ***** Implementation Helper Tool

// Notes on Code Signing
// ---------------------
// I've decided *not* to implementing a digital signature verification 
// as part of this library.  There are a number of technical reasons 
// that would make digitally signing the code tricky (such as prebinding), 
// but I believe that all of those are surmountable.  The reasons I didn't 
// implementing digital signatures are:
// 
// A) it doesn't improve the security if I implement it here, 
// B) it's extra work for me, and 
// C) its presence might lead folks to believe that this is more 
//    secure than it really is.
//
// The most critical point is point A.  I'll spend a little time explaining 
// that here.
//
// No matter what you do, the current AuthorizationExecuteWithPrivileges 
// model allows for security violations [3093666].  Specifically, AEWP lets 
// you run a non-privileged helper tool as if it was privileged.  However, in 
// the time between the point where you call AEWP (at the point, SigCheck1, 
// below) and the point where the helper tool runs and changes its own 
// permissions to prevent tampering (SigCheck2), there's a window of opportunity 
// where an attacker can modify the tool at will, and the modified tool will be 
// run as root.  They could, for example, open a read/write file descriptor 
// that allows them to modify the tool.  Even if the tool checks its own 
// integrity with a digital signature (at the point SigCheck2, below), there's 
// no way it can revoke the read/write file descriptor, so the attacker could 
// just modify the tool after the digital signature check.
//
// Moreover, there are even simpler attacks.  For example, an attacker 
// could just delete the application's current helper tool and replace 
// the application's template copy of the tool with its own.  The application 
// will quite happily launch that tool, at which point the tool can use  
// AEWP to prompt for the admin password and can launch any program in 
// privileged mode.  The user is not going to be be able to distinguish 
// between the attacker's tool call AEWP and the real helper tool.
//
// You could defeat this second attack by digitally signing the helper tool, 
// but that doesn't really help because if the attacker can change the 
// application program (which is a precondition of being able to substitute 
// a helper tool), they can replace your digital signature with theirs. 
// One way around this would be to use a certificate to verify the 
// authenticity of the digital signature, but that's beyond what I'm 
// prepared to do for sample code.
//
// So, rather than write a lot of code to provide a false sense of security, 
// I've decided to simply ignore the issue of digital signatures altogether.

// File Modes
// ----------
// The following is a declaration of constants that I use when setting and checking
// the file mode (ie permissions).  It's an extreme use of whitespace, but 
// I found the layout helpful.

enum {
	// The mode_t that we set for the helper tool via fchmod.
	
	kSetHelperToolPerms = 0				// r-sr-xr-x
						| S_ISUID
//						| S_ISGID
//						| S_ISVTX

						| S_IRUSR
//						| S_IWUSR
						| S_IXUSR

						| S_IRGRP
//						| S_IWGRP
						| S_IXGRP

						| S_IROTH
//						| S_IWOTH
						| S_IXOTH
						,

	// The mode_t that we check, via stat, to see if the helper tool is valid.

	kRequiredHelperToolPerms = S_IFREG | kSetHelperToolPerms,

	kRequiredHelperToolMask = 0
							| S_IFMT

							| S_ISUID
							| S_ISGID
							| S_ISVTX

							| S_IRWXU
							| S_IRWXG
							| S_IRWXO
};

static int RepairOurPrivileges(const char *pathToSelf)
    // Self-repair code.  We ran ourselves using AuthorizationExecuteWithPrivileges
    // so we need to make ourselves setuid root to avoid the need for this the 
    // next time around.
{
	int			err;    
	int			junk;    
    int 		fd;

	assert(pathToSelf != NULL);
	
	// We don't supply O_EXLOCK to open because that's only an advisory 
	// lock so it doesn't buy us anything.  [AuthSample makes the claim 
	// that this lock is mandatory, but that's just wrong [3090303].]
	
    fd = open(pathToSelf, O_RDONLY, 0);
    err = MoreUNIXErrno(fd);
	
	if (err == 0) {
		// SigCheck2
		//
		// If I was to implement digital signing of the code, this is the 
		// second place I would check the signature.  See note above for 
		// more information on this.
	}

	if (err == 0) {
		// Switch to EUID 0 to do the chown/chmod.
		
		err = MoreSecSetPrivilegedEUID();    

	    // Make it owned by root.
	    
	    if (err == 0) {
	    	// GID = -1 implies no change
	        err = fchown(fd, 0, -1);
	        err = MoreUNIXErrno(err);
	    }

	    // Force the mode flags.

	    if (err == 0) {
		    err = fchmod(fd, kRequiredHelperToolPerms);
		    err = MoreUNIXErrno(err);
	    }

		// Switch back to EUID != 0 once we're done.
		
		junk = MoreSecTemporarilySetNonPrivilegedEUID();
		assert(junk == 0);
	}
    
	// Clean up.
	
	if (fd != -1) {
		junk = close(fd);
		assert(junk == 0);
	}

    return err;
}

static void CheckWaitForDebuggerInterference(int *err, pid_t childPID, int *status)
    // The problem this is trying to solve is as follows.  When we use 
    // GDB to attach to our helper tool (in order to debug it), GDB 
    // temporarily changes the helper tool's parent process to be GDB. 
    // Thus, if we call waitpid while GDB is attached to the helper tool, 
    // waitpid returns ECHILD.
    // 
    // The solution is to set a breakpoint on this second call to waitpid. 
    // If you hit that breakpoint, you should either detach GDB from the 
    // helper tool or allow the helper tool to run to completion.  Either 
    // of these will restore the helper tool's parent process back to the 
    // application, which allows waitpid to succeed.
    //
    // I allow this code to run even in the non-debugging case because, 
    // other than the fprintf, it's pretty benign and it's certainly not 
    // on a performance critical path.
{
    if (*err == ECHILD) {
        #if MORE_DEBUG
            fprintf(stderr, "MoreSecurity: You need to have a breakpoint set here.\n");
        #endif
        *err = waitpid(childPID, status, 0);
        *err = MoreUNIXErrno(*err);
    }
}

static int ExecuteSelfInPrivilegedSelfRepairMode(int fdIn, int fdOut, AuthorizationRef auth, const char *pathToSelf)
	// Execute another copy of the tool in privileged mode via 
	// AuthorizationExecuteWithPrivileges.  Route the command request 
	// from fdIn to the second instance of the tool, and route the
	// command response from the second instance of the tool to fdOut.
{
	int		err;
	int		err2;
	int		status;
	int		junk;
    FILE *	fileConnToChild;
    int		fdConnToChild;
    pid_t	childPID;
    static const char * const kSelfRepairArguments[] = { "--self-repair", NULL };

	assert(fdIn    >= 0);
	assert(fdOut   >= 0);
	assert(auth       != NULL);
	assert(pathToSelf != NULL);

	fileConnToChild = NULL;
	childPID = WAIT_ANY;
	
	err = 0;
	
	// SigCheck1
	//
	// If I was to implement digital signing of the code, this is the 
	// first place I would check the signature.  See note above for 
	// more information on this.
	
	if (err == 0) {
		#if MORE_DEBUG
			fprintf(stderr, "MoreSecurity: Calling AEWP\n");
		#endif
	    err = OSStatusToEXXX( AuthorizationExecuteWithPrivileges(auth, pathToSelf, 
										kAuthorizationFlagDefaults, (char * const *) kSelfRepairArguments, &fileConnToChild) );
		#if MORE_DEBUG
			fprintf(stderr, "MoreSecurity: AEWP returned %d\n", err);
		#endif

		// The cast for kSelfRepairArguments is required because of a bug in the prototype
		// for AuthorizationExecuteWithPrivileges [3090294].
	}
	
	if (err == 0) {
		// Extract the descriptor for the returned FILE *.  As we 
		// never use the FILE * again and there is no data buffered
		// in it, it's safe for us to use the descriptor as if it had 
		// never been embedded in a FILE *.
		
		fdConnToChild = fileno(fileConnToChild);
		err = MoreUNIXErrno(fdConnToChild);

		// Get the PID sent to us by the child.  We need to do this because 
		// AuthorizationExecuteWithPrivileges does not return us the child's 
		// PID [3090277], and we need the child PID in order to properly wait 
		// for the child to terminate.
		
		if (err == 0) {
			err = MoreUNIXRead(fdConnToChild, &childPID, sizeof(childPID), NULL);
		}
			
		// At this point we're just acting as a router between the application 
		// and the second instance of the tool we launched using AEWP.  All we 
		// do is copy the request data to the tool, and then copy the result 
		// back to the app.  This works because we implement a simple 
		// request/response protocol.  If the protocol was more complex 
		// (for example, if the tool handled multiple requests per 
		// session), we would have to implement a more complex copying 
		// algorithm using "select".
		
		if (err == 0) {
			err = MoreUNIXCopyDescriptorToDescriptor(fdIn, fdConnToChild);
		}

		// Close the write side of our connection to the child.  We do this so that 
		// if the child makes a mistake and tries to do a blocking read on its 
		// input for more data that we're sending it, it will see the closed socket 
		// and get EPIPE instead of blocking forever.

		if (err == 0) {
			err = shutdown(fdConnToChild, 1);
			err = MoreUNIXErrno(err);
		}

		// Copy the response back to the app.  We actually have to parse the 
		// response properly because we may have to translate file descriptors.
		// So, unlike the send side, we can't just call MoreUNIXCopyDescriptorToDescriptor, 
		// but instead have to read and write the dictionary and any embedded 
		// descriptors.
		//
		// Note that this code could be more efficient (I don't actually have to 
		// rewrite the dictionary with the new descriptor numbers) but I chose 
		// to implement it this way because it's simpler.  I'm reusing code that 
		// I needed anyway.
		
		if (err == 0) {
			CFDictionaryRef response;
			
			response = NULL;

			err = CopyDictionaryTranslatingDescriptors(fdConnToChild, &response);
			if (err == 0) {
				err = WriteDictionaryAndDescriptors(response, fdOut);
			}
			if (response != NULL) {
				MoreSecCloseDescriptorArray((CFArrayRef) CFDictionaryGetValue(response, kMoreSecFileDescriptorsKey));
			}
			CFQRelease(response);
		}

		// Close the connection to the child, which also closes fdConnToChild.
		
	    if (fileConnToChild != NULL) {
			junk = fclose(fileConnToChild);
			assert(junk == 0);
		}

		// Wait for the child to terminate.  We have to do this, regardless 
		// of whether we get an error, in order to clear the zombie process.
		// 
		// Note that we don't get the pid of the child back from 
		// AuthorizationExecuteWithPrivileges, so we have to have the child 
		// send us its PID via fdConnToChild (see the MoreUNIXRead above).
		// Also note that there's no guarantee that the MoreUNIXRead will 
		// execute without error, thus there's no guarantee that childPID 
		// will be valid.  We handle that by initialising childPID to WAIT_ANY 
		// in the error case, which makes "waitpid" work just like "wait", 
		// that is, wait for any child to terminate.  Of course, there's 
		// no guarantee that in that case the terminating child will actually 
		// be the child we launched with AEWP.  That's sad, but its
		// the best we can do given the current problems with AEWP [3090277].
		
	    err2 = waitpid(childPID, &status, 0);
	    err2 = MoreUNIXErrno(err2);

        CheckWaitForDebuggerInterference(&err2, childPID, &status);

        if (err == 0) {
	    	err = err2;
	    }

		// If we successfully got a wait status from the client (or 
		// our communications with the client failed because of 
		// a generic communications error), let's go see whether 
		// the child's wait status is a more appropriate source of 
		// error information.
		
		if ( (err == 0) || (err == EPIPE) ) {
			if ( ! WIFEXITED(status) ) {
				// If we got a wait status but it's not a valid exit status (perhaps 
				// WIFSIGNALED, indication that the child terminated because of a signal),
				// that's an unexpected error we can't handle.
				
				err = kMoreSecResultInternalErrorErr;
			} else {
				// If we got a valid exit status from the child, map its exit status 
				// into our range so that we return an equivalent status.  The helper 
				// tool's main function can use MoreSecErrorToHelperToolResult to map 
				// this back to a status code.
				
				err = MoreSecHelperToolResultToError(WEXITSTATUS(status));
			}
		}
	}

	return err;
}

static int ReadAndDispatchCommand(int fdIn, int fdOut, AuthorizationRef auth, MoreSecCommandProc commandProc)
	// Read a command from fdIn, execute the command by calling commandProc,
	// and then return the response via fdOut.
{
	int 				err;
	int 				junk;
	CFDictionaryRef 	request;
	CFDictionaryRef		response;
	
	assert(fdIn    >= 0);
	assert(fdOut   >= 0);
	assert(auth    != NULL);
	assert(commandProc != NULL);
	
	request		= NULL;
	response	= NULL;
	
	// Read the request and convert it a CFDictionary.

	err = OSStatusToEXXX( CopyDictionaryFromDescriptor(fdIn, &request) );

	// Call the client's commandProc to actually execute the request.  
	
	if (err == 0) {
		OSStatus    commandErr;
		CFStringRef errorKey = kMoreSecErrorNumberKey;
		
		commandErr = commandProc(auth, (CFDictionaryRef) request, (CFDictionaryRef *) &response);
		// fprintf(stderr, "commandErr = %ld\n", commandErr);
		
		// If the commandProc switched to EUID 0, let's go back to EUID == RUID.
		
		junk = MoreSecTemporarilySetNonPrivilegedEUID();
		assert(junk == 0);
		
		// Check the structure of the response.  It's an error for the commandProc 
		// to return a response that isn't an error, or to return a response that 
		// contains kMoreSecFileDescriptorsKey (that is, descriptors to return 
		// to the calling process) that isn't an array.  We assert these conditions, 
		// rather than handling the errors, because the commandProc is a trusted 
		// piece of code, so it shouldn't be doing bad things.  I do this checking 
		// here because, in the future, I might want to handle this as an error 
		// properly, and thus I have to do the check before I accept the response.
		
		#if MORE_DEBUG
			if (response != NULL) {
				CFArrayRef 			descArray;
				CFIndex 			descCount;
				CFIndex 			descIndex;
				
				assert( CFGetTypeID(response) == CFDictionaryGetTypeID() );
				
				descArray = (CFArrayRef) CFDictionaryGetValue(response, kMoreSecFileDescriptorsKey);
				if (descArray != NULL) {
					assert( CFGetTypeID(descArray) == CFArrayGetTypeID() );
					
					descCount = CFArrayGetCount(descArray);
					
					for (descIndex = 0; descIndex < descCount; descIndex++) {
						CFNumberRef thisDescNum;
						int thisDesc;
						
						thisDescNum = (CFNumberRef) CFArrayGetValueAtIndex(descArray, descIndex);
						assert( (thisDescNum != NULL) && (CFGetTypeID(thisDescNum) == CFNumberGetTypeID()) );

						// Normally it's bad to include function calls that have side effects 
						// within an "assert", but in this case the assert is guaranteed 
						// to be in effect because we're inside a MORE_DEBUG block.
						
						assert( CFNumberGetValue(thisDescNum, kCFNumberIntType, &thisDesc) );
						assert(thisDesc >= 0);
						assert( fcntl(thisDesc, F_GETFD, 0) >= 0 );
					}
				}
			}
		#endif

		// Automatically put the commandProc's function result 
		// into a response dictionary if the commandProc hasn't already done so. 
		// An error from the commandProc does not indicate a failure of the 
		// helper tool itself.
		
		if ( (response == NULL) || ! CFDictionaryContainsKey(response, errorKey) ) {
			CFNumberRef commandErrNum;

			commandErrNum = CFNumberCreate(NULL, kCFNumberSInt32Type, &commandErr);
			err = OSStatusToEXXX( CFQError(commandErrNum) );
			
			if (err == 0) {
				if (response == NULL) {
					response = CFDictionaryCreate(NULL, (const void **) &errorKey, (const void **) &commandErrNum, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
					err = OSStatusToEXXX( CFQError(response) );
				} else {
					CFMutableDictionaryRef temp;
					
					temp = CFDictionaryCreateMutableCopy(NULL, 0, response);
					err = OSStatusToEXXX( CFQError(temp) );
					if (err == 0) {
						CFDictionarySetValue(temp, errorKey, commandErrNum);
						
						CFQRelease(response);
						response = temp;
					}
				}
			}

			CFQRelease(commandErrNum);
		}
		
	}
	
	assert( (err == 0) == (response != NULL) );
	
	// Pass the response back.  We also close our copy of the descriptor, for reasons 
	// that are explained in the "MoreSecurity.h" header.
	
	if (err == 0) {
		err = WriteDictionaryAndDescriptors(response, fdOut);
	}
	if (response != NULL) {
		MoreSecCloseDescriptorArray((CFArrayRef) CFDictionaryGetValue(response, kMoreSecFileDescriptorsKey));
	}
	CFQRelease(response);
	CFQRelease(request);
	
	return err;
}

extern AuthorizationRef MoreSecHelperToolCopyAuthRef(void)
	// See comment in header.
{
	AuthorizationRef result;
	
	result = NULL;

	(void) AuthorizationCopyPrivilegedReference(&result, kAuthorizationFlagDefaults);

	return result;
}

extern int MoreSecHelperToolMain(int fdIn, int fdOut, AuthorizationRef auth, MoreSecCommandProc commandProc, int argc, const char *argv[])
	// See comment in header.
{
	int					err;
	OSStatus			junk;
    char *				pathToSelf;
    Boolean				privileged;

	assert(fdIn    >= 0);
	assert(fdOut   >= 0);
	assert(commandProc != NULL);
	assert( (argc == 1) || (argc == 2) );
	assert(argv    != NULL);
	assert(argv[0] != NULL);

	err        = 0;
	pathToSelf = NULL;

	// Note whether we're privileged, and then switch the EUID to the RUID 
	// so that the rest of the tool runs with a non-zero EUID unless it 
	// specifically requests privileges via MoreSecSetPrivilegedEUID.  
	// This makes things just a little bit safer.
	
	privileged = (geteuid() == 0);
	err = MoreSecTemporarilySetNonPrivilegedEUID();
	
	// We need pathToSelf in both of the following cases, so let's get it here.
	
	if (err == 0) {
		err = GetPathToSelf(&pathToSelf);
	}
	
	// There are three cases:
	//
	// 1a. No command line arguments, privileged -- We can just call 
	//     ReadAndDispatchCommand to execute the request.
	//
	// 1b. No command line arguments, not privileged -- We need to self 
	//     repair by calling ExecuteSelfInPrivilegedSelfRepairMode.
	//     This will launch another copy of the tool, and that copy 
	//     of the tool will actually execute the request using
	//     ReadAndDispatchCommand.
	//
	// 2.  --self-repair command line argument -- We got here by 
	//     step 1b above.  We must be privileged.  If not, bail out. 
	//     We make ourselve setuid root (RepairOurPrivileges) and then 
	//     execute the command via ReadAndDispatchCommand.
	
	if (err == 0) {
	    if (argc == 1) {
		    AuthorizationExternalForm extAuth;

			// The caller gave us a AuthorizationRef, but we're don't use 
			// it in this case.  Just throw it away.
			
			if (auth != NULL) {
				junk = AuthorizationFree(auth, kAuthorizationFlagDefaults);
				assert(junk == noErr);
				
				auth = NULL;
			}
			
			// Started directly by the application.  Read the authorization 
			// "byte blob" from our input, and use that to create our 
			// AuthorizationRef.  
			
			err = MoreUNIXRead(fdIn, &extAuth, sizeof(extAuth), NULL);
		    if (err == 0) {
			    err = OSStatusToEXXX( AuthorizationCreateFromExternalForm(&extAuth, &auth) );
		    }

			// If we're running as root, we can just read the command 
			// and execute it.  Otherwise, we have to self-repair.  
			// Note that this will launch a second instance of this 
			// tool, which is the one that actually reads and executes  
			// the command.
			
		    if (err == 0) {
			    if (privileged) {
					err = ReadAndDispatchCommand(fdIn, fdOut, auth, commandProc);
			    } else {
			    	err = ExecuteSelfInPrivilegedSelfRepairMode(fdIn, fdOut, auth, pathToSelf);
			    }
			}
	    } else if ( (argc == 2) && (strcmp(argv[1], "--self-repair") == 0) ) {
	    	pid_t myPID;
	    
	    	// We get here if we've been launched in self-repair mode by 
	    	// ourselves (see ExecuteSelfInPrivilegedSelfRepairMode).  First we 
	    	// send our parent our PID.  This is needed for reasons that are 
	    	// explained above (in ExecuteSelfInPrivilegedSelfRepairMode).  Then we 
	    	// verify that we're actually been run with EUID 0.  Then we grab our 
	    	// AuthorizationRef from our parent.  Next we self-repair, that is, 
	    	// make our executable setuid root so that the next time around we won't 
	    	// need to run this code path.  Finally, we actually read and 
	    	// dispatch the command.
	    	//
	    	// Note that we don't read the authorization "byte 
	    	// blob" because it's already been read by our parent.
			
			myPID = getpid();
			err = MoreUNIXWrite(fdOut, &myPID, sizeof(myPID), NULL);
			
	    	if (err == 0 && ! privileged ) {
	    		err = kMoreSecResultParamErr;
	    	}
	    	if ( (err == 0) && (auth == NULL) ) {
	    		err = kMoreSecResultParamErr;
	    	}
		    if (err == 0) {
		    	err = RepairOurPrivileges(pathToSelf);
			}
	    	if (err == 0) {
				err = ReadAndDispatchCommand(fdIn, fdOut, auth, commandProc);
			}
	    } else {
	    	err = kMoreSecResultParamErr;
	    }
	}
	
	// Clean up and pass results back to caller.
	
    free(pathToSelf);
	if (auth != NULL) {
		junk = AuthorizationFree(auth, kAuthorizationFlagDefaults);
		assert(junk == noErr);
	}
	return err;
}

/////////////////////////////////////////////////////////////////
#pragma mark ***** Calling Helper Tool

static OSStatus FSSetCatalogInfoIDs(const FSRef *ref, 
                                    FSCatalogInfoBitmap whichInfo, 
                                    const FSCatalogInfo *catalogInfo)
    // A version of FSSetCatalogInfo that actually tries 
    // to set the FUID and FGID if you supply the 
    // kFSCatInfoPermissions flag.  This is the current 
    // recommended workaround for <rdar://problem/2631025>. 
    // You can supply a userID or groupID value of -1 
    // to indicate that you don't want to change the value.
{
    OSStatus                    err;
    const FSPermissionInfo *    permInfo;
    uid_t                       uid;
    gid_t                       gid;
    
    err = FSSetCatalogInfo(ref, whichInfo, catalogInfo);
    if ( (err == noErr) && (whichInfo & kFSCatInfoPermissions) ) {
        permInfo = (const FSPermissionInfo *) catalogInfo->permissions;
        uid = (uid_t) permInfo->userID;
        gid = (gid_t) permInfo->groupID;
        if (uid != -1 || gid != -1 ) {
            char filePath[MAXPATHLEN];
            
            err = FSRefMakePath(ref, (UInt8 *) filePath, sizeof(filePath));
            if (err == noErr) {
                err = chown(filePath, uid, gid);
                if (err == -1) {
                    err = errno;
                }
            }
        }
    }
    return err;
}

extern OSStatus MoreSecIsFolderIgnoringOwnership(const FSRef *folder, Boolean *ignoringOwnership)
	// See comment in header.
{
	OSStatus		err;
	OSStatus		junk;
	int				tries;
	FSRef			fileRef;
	FSCatalogInfo 	info;
	static gid_t kPermissionsUnknownGroupID = 99;
	//static gid_t kPermissionsStaffGroupID   = 20;
	
	assert(folder != NULL);
	assert(ignoringOwnership != NULL);
	
	// Create a temporary file.
	
	tries = 1;
	do {
		AbsoluteTime	now;
		CFStringRef 	tmpStr;
		HFSUniStr255 	tmpStrU;
		
		now = UpTime();
		tmpStr = CFStringCreateWithFormat(NULL, NULL, CFSTR("MoreSecIsFolderIgnoringOwnership Temp %lx%lx"), now.hi, now.lo);
		err = CFQError(tmpStr);
		
		if (err == noErr) {
			assert(CFStringGetLength(tmpStr) <= (sizeof(tmpStrU.unicode) / sizeof(UniChar)) );
			tmpStrU.length = (UInt16) CFStringGetLength(tmpStr);
			CFStringGetCharacters(tmpStr, CFRangeMake(0, tmpStrU.length), tmpStrU.unicode);
		
			err = FSCreateFileUnicode(folder, tmpStrU.length, tmpStrU.unicode, kFSCatInfoNone, NULL, &fileRef, NULL);
		}
		
		CFQRelease(tmpStr);

		tries += 1;
	} while ( (tries < 1000) && (err == dupFNErr) );

	// Probe that temporary file to see if permissions are being ignored.
		
	if (err == noErr) {
		err = FSGetCatalogInfo(&fileRef, kFSCatInfoPermissions, &info, NULL, NULL, NULL);
		if (err == noErr) {
			FSPermissionInfo *permInfo;
			
	        permInfo = (FSPermissionInfo *) info.permissions;

			// If the FGID is not "unknown", then we already know that the volume 
			// is not ignoring ownership.  Otherwise we have to test.

			if (permInfo->groupID != kPermissionsUnknownGroupID) {
				*ignoringOwnership = false;
			} else {
			                
				// Change the FGID to "staff".  If that change is effective, we're 
				// not ignoring ownership.
				
				// permInfo->groupID = kPermissionsStaffGroupID;
                
                // It's not a good idea to assume that users are in the "staff" group
                // because as of 10.3 users are no longer in this group.
                
                gid_t realgid = getgid();
                permInfo->groupID = realgid;
				err = FSSetCatalogInfoIDs(&fileRef, kFSCatInfoPermissions, &info);
				if (err == noErr) {
					err = FSGetCatalogInfo(&fileRef, kFSCatInfoPermissions, &info, NULL, NULL, NULL);
				}
				if (err == noErr) {
					*ignoringOwnership = (permInfo->groupID != realgid);
				}
			}
			assert( (err != noErr) || (*ignoringOwnership == (permInfo->groupID == kPermissionsUnknownGroupID)) );
		}
		junk = FSDeleteObject(&fileRef);
		assert(junk == noErr);
	}
	
	return err;
}

extern OSStatus MoreSecIsFolderIgnoringSetUID(const FSRef *folder, Boolean *ignoringSetUID)
	// See comment in header.
{
	OSStatus		err;
	char 			folderPath[MAXPATHLEN];
	struct statfs	sb;

	// Call statfs and check the MNT_NOSUID flag.
	
	err = FSRefMakePath(folder, (UInt8 *) folderPath, sizeof(folderPath));
	if (err == noErr) {
		err = statfs(folderPath, &sb);
    	err = EXXXToOSStatus( MoreUNIXErrno(err) );
    }
    if (err == noErr) {
    	*ignoringSetUID = ((sb.f_flags & MNT_NOSUID) != 0);
    }

	return err;
}

static OSStatus CheckHelperTool(CFURLRef templateTool, CFURLRef tool, Boolean *looksOK)
	// Checks that the working tool is a reasonably accurate copy of the 
	// templateTool.  This checks that the tool exists, is setuid root, 
	// and has the same size and modification date as the template tool. 
{
	OSStatus      	err;
	char			toolPath[MAXPATHLEN];			// 2K on the stack!
	char			templateToolPath[MAXPATHLEN];	// I'm going to burn in hell.
	struct stat 	toolStat;
	struct stat 	templateToolStat;
	struct timeval	toolStamp;
	struct timeval  templateToolStamp;
	
	assert(templateTool != NULL);
	assert(tool         != NULL);
	assert(looksOK      != NULL);
	
	// Check that the template tool is present.  If the template tool is missing, 
	// we're doooommmmeeeedddd!

	err = CFQErrorBoolean( CFURLGetFileSystemRepresentation(templateTool, true, (UInt8 *)templateToolPath, sizeof(templateToolPath)) );
	if (err == noErr) {
		err = stat(templateToolPath, &templateToolStat);
		err = EXXXToOSStatus( MoreUNIXErrno(err) );
	}

	// If we successfully found the template tool, go looking for the primary tool. 
	
	if (err == noErr) {
		err = CFQErrorBoolean( CFURLGetFileSystemRepresentation(tool, true, (UInt8 *)toolPath, sizeof(toolPath)) );
	}
	if (err == noErr) {
		err = stat(toolPath, &toolStat);
		err = EXXXToOSStatus( MoreUNIXErrno(err) );

		// If the primary tool is either missing, has dropped its 
		// owner or setuid or permissions, or is the wrong size, 
		// or the wrong time stamp (the last two checks help debugging), 
		// then try to restore the tool.
		
		TIMESPEC_TO_TIMEVAL(&templateToolStamp, &templateToolStat.st_mtimespec);
		TIMESPEC_TO_TIMEVAL(&toolStamp, &toolStat.st_mtimespec);

		*looksOK = (err == noErr) 
				&& (toolStat.st_uid == 0) 
				&& ((toolStat.st_mode & kRequiredHelperToolMask) == kRequiredHelperToolPerms) 
				&& (toolStat.st_size  == templateToolStat.st_size)
				&& (toolStamp.tv_sec  == templateToolStamp.tv_sec) 
				&& (toolStamp.tv_usec == toolStamp.tv_usec);
		err = noErr;
	}
	
	return err;
}

static OSStatus CheckAndFixHelperTool(CFURLRef templateTool, CFURLRef tool)
	// Checks that the working tool is a reasonably accurate copy of the 
	// templateTool, using CheckHelperTool, and if these checks fail, 
	// restores tool from the template tool.
	//
	// the tool referenced by templateTool must exist
	//
	// tool must not be NULL; if tool does not exist, the directory in 
	// which tool would be contained must exist
{
	int      		err;
	char			toolPath[MAXPATHLEN];			// 2K on the stack!
	char			templateToolPath[MAXPATHLEN];	// I'm going to burn in hell.
	struct stat 	toolStat;
	Boolean			looksOK;
	
	assert(templateTool != NULL);
	assert(tool         != NULL);
	
	err = CheckHelperTool(templateTool, tool, &looksOK);
	if (err == noErr && !looksOK) {
		err = CFQErrorBoolean( CFURLGetFileSystemRepresentation(templateTool, true, (UInt8 *)templateToolPath, sizeof(templateToolPath)) );
		if (err == noErr) {
			err = CFQErrorBoolean( CFURLGetFileSystemRepresentation(tool, true, (UInt8 *)toolPath, sizeof(toolPath)) );
		}
		if (err == noErr) {
			if ( stat(toolPath, &toolStat) == 0 ) {
				err = unlink(toolPath);
				err = MoreUNIXErrno(err);
				if (err == EPERM) {			// just in case the file name is being used by a directory
					err = rmdir(toolPath);
					err = MoreUNIXErrno(err);
				}
			}
		}
		
		if (err == noErr) {
			err = MoreUNIXCopyFile(templateToolPath, toolPath);
		}
	}
		
	return err;
}

static OSStatus CopyHelperToolURL(short domain, OSType folder, CFStringRef subFolderName, CFStringRef toolName, Boolean createFolder, CFURLRef *tool)
	// Create a URL that points to a helper tool named toolName within the 
	// Folder Manager folder specified by domain and folder.  If subFolderName is 
	// not NULL, the URL points to the tool within that folder, otherwise it 
	// points to the tool directly within the Folder Manager folder.
	// The URL might point to a file that does not exist, but if the call 
	// is successful then the parent folder will exist.
	// 
	// If createFolder is false, this routine will not create any folders; 
	// if it needs to create a folder, it will error instead.
{
	OSStatus		err;
	FSRef 			folderRef;
	CFURLRef		folderURL;

	assert(toolName != NULL);
	assert( tool    != NULL);
	assert(*tool    == NULL);
		
	folderURL = NULL;
	
	err = FSFindFolder(domain, folder, createFolder, &folderRef);
	if (err == noErr && subFolderName != NULL) {
		FSRef 			tmp;
		HFSUniStr255 	subFolderNameU;
		
		tmp = folderRef;

		// Extract the Unicode characters from subFolderName.
		
		assert(CFStringGetLength(subFolderName) <= (sizeof(subFolderNameU.unicode) / sizeof(UniChar)) );
		subFolderNameU.length = (UInt16) CFStringGetLength(subFolderName);
		CFStringGetCharacters(subFolderName, CFRangeMake(0, subFolderNameU.length), subFolderNameU.unicode);

		// If the sub-folder doesn't exist, try to create it.  We can't just create it 
		// and ignore the dupFNErr if it already exists because we need to set up 
		// folderRef.
		
		err = FSMakeFSRefUnicode(&tmp, subFolderNameU.length, subFolderNameU.unicode, kTextEncodingUnknown, &folderRef);
		if (err != noErr && createFolder) {
			err = FSCreateDirectoryUnicode(&tmp, subFolderNameU.length, subFolderNameU.unicode, kFSCatInfoNone, NULL, 
										   &folderRef, NULL, NULL);
		}
	}
	
	// Create a URL to the parent folder, then append the tool name.
	
	if (err == noErr) {
		folderURL = CFURLCreateFromFSRef(NULL, &folderRef);
		err = CFQError(folderURL);
	}
	if (err == noErr) {
		*tool = CFURLCreateCopyAppendingPathComponent(NULL, folderURL, toolName, false);
		err = CFQError(*tool);
	}
	
	CFQRelease(folderURL);

	assert( (err == noErr) == (*tool != NULL) );
		
	return err;
}

static CFURLRef CreateURLToValidHelperToolInFolder(
	SInt16 			domain, 
	OSType 			folder, 
	CFStringRef 	subFolderName, 
	CFStringRef 	toolName,
	CFURLRef	 	templateTool
)
	// Checks whether a valid helper tool (of name toolName) exists 
	// in the folder specified by folder and subFolderName.  If so, 
	// it returns a URL to the tool; otherwise it returns NULL.
	//
	// Validity is determined by comparing the tool to templateTool; 
	// see CheckHelperTool for details.
	//
	// The call sites don't care about the specific reason why a 
	// valid tool isn't found, so this just returns the URL (or NULL) 
	// rather than an OSStatus.
{
	OSStatus 	err;
	Boolean		found;
	CFURLRef	result;
	
	assert( toolName != NULL );
	assert( templateTool != NULL );

	found = false;
	result = NULL;
	
	// Note that we pass false to the createFolder parameter of the 
	// CopyHelperToolURL so that it doesn't create any folders 
	// that are missing.  That's because at this stage we're just looking 
	// for the file, not trying to create it.
	
	err = CopyHelperToolURL(domain, folder, subFolderName, toolName, false, &result);
	if (err == noErr) {
		err = CheckHelperTool(templateTool, result, &found);
	}
	if (!found) {
		CFQRelease(result);
		result = NULL;
	}

	assert( found == (result != NULL) );
	
	return result;
}

static OSStatus	CreateURLToNewHelperToolInFolder(
	OSType 			folder,
	CFStringRef		subFolderName,
	CFStringRef 	toolName,
	CFURLRef	 	templateTool,
	CFURLRef *		tool
)
	// Copies the template helper tool (templateTool) to the location 
	// specified by folder, subFolder and toolName, and creates a 
	// URL to the resulting tool.
{
	OSStatus 	err;
	FSRef 		folderRef;
	Boolean 	ignoring;
	CFURLRef	result;

	assert( toolName != NULL );
	assert( templateTool != NULL );
	assert( tool != NULL );
	assert(*tool == NULL );
	
	result = NULL;
	
	// Let's try to create the tool in the specified folder (typically this is
	// ~/Library/Application Support).  However, before we do that, make sure 
	// that the user isn't ignoring ownership on the volume containing that folder
	// and that the volume actually supports setuid root programs.  If either of 
	// these happens, we have no idea where to put the tool, so we fail with a very 
	// specific error code.

    short domain;
    if (folder == kTemporaryFolderType) {
        domain = kOnSystemDisk;
    } else {
        domain = kUserDomain;
    }
    
    err = FSFindFolder(domain, folder, true, &folderRef);
	if (err == noErr) {
		err = MoreSecIsFolderIgnoringOwnership(&folderRef, &ignoring);
	}
	if (err == noErr && ignoring) {
		err = kMoreSecFolderInappropriateErr;
	}
	if (err == noErr) {
		err = MoreSecIsFolderIgnoringSetUID(&folderRef, &ignoring);
	}
	if (err == noErr && ignoring) {
		err = kMoreSecFolderInappropriateErr;
	}

	// Check that the destination tool is valid and, if not, fix it.
	//
	// Pass true to the createFolder parameter of CopyHelperToolURL 
	// because we want to create the tool (and any enclosing folders).
	
	if (err == noErr) {
		err = CopyHelperToolURL(domain, folder, subFolderName, toolName, true, &result);
	}
	if (err == noErr) {
		err = CheckAndFixHelperTool(templateTool, result);
	}
	
	// Clean up.
	
	if (err != noErr) {
		CFQRelease(result);
		result = NULL;
	}
	*tool = result;
	
	assert( (err == noErr) == (*tool != NULL) );
	
	return err;
}

extern OSStatus MoreSecCopyHelperToolURLAndCheck(
	CFURLRef 		templateTool, 
	OSType 			folder, 
	CFStringRef 	subFolderName, 
	CFStringRef 	toolName, 
	CFURLRef *		tool
)
	// See comment in header.
{
	OSStatus			err;
	CFURLRef			result;
	UInt32   			domainIndex;
	static const SInt16 kFolderDomains[] = {kUserDomain, kLocalDomain, kNetworkDomain, kSystemDomain, 0};

	assert(templateTool != NULL);
	assert(toolName != NULL);
	assert( tool != NULL);
	assert(*tool == NULL);
	
	result = NULL;
	
	// For each folder domain, check whether there's an appropriate helper tool 
	// present.  This allows a sysadmin to put the helper tool in any of the 
	// "Application Support" folders (ie ~/Library, /Library, /Network/Library, 
	// /System/Library) and we'll find it and run without trying to create 
	// another copy of the tool.

	domainIndex = 0;
	do {
		assert(result == NULL);
		
		result = CreateURLToValidHelperToolInFolder(kFolderDomains[domainIndex], folder, subFolderName, toolName, templateTool);
		
		domainIndex += 1;
	} while ( (result == NULL) && (kFolderDomains[domainIndex] != 0) );

	// If we didn't find it in the specified folder, look for it in the 
	// "Temporary Items" folder.  This means that if the client application, 
	// upon getting an kMoreSecFolderInappropriateErr, calls us again 
	// with folder set to kTemporaryFolderType so that we create a 
	// temporary helper tool, then we'll pick up the temporary helper 
	// tool for as long as it exists.
	
	if (result == NULL) {
		result = CreateURLToValidHelperToolInFolder(kUserDomain, kTemporaryFolderType, subFolderName, toolName, templateTool);
	}
	
	// At this point either we found the tool, and result is set to its 
	// URL, or we haven't found the tool and result is NULL.  Note that 
	// we've ignored all errors up to here because we don't care why 
	// the tool wasn't found, just that it wasn't.
		
	if (result != NULL) {

		// Do nothing; result will be copied out to *tool during clean up (below).

		err = noErr;

	} else {
	
		// We couldn't find the tool in any of the folders, so let's go create one 
		// (typically in ~/Library/Application Support).
		
		err = CreateURLToNewHelperToolInFolder(folder, subFolderName, toolName, templateTool, &result);
	}

	// Clean up.

	if (err == noErr) {
		*tool = result;
	} else {
		CFQRelease(result);
	}
	assert( (err == noErr) == (*tool != NULL) );
	
	return err;
}

extern OSStatus MoreSecCopyHelperToolURLAndCheckBundled(
	CFBundleRef 	inBundle, 
	CFStringRef 	templateToolName, 
	OSType 			folder, 
	CFStringRef 	subFolderName, 
	CFStringRef 	toolName, 
	CFURLRef *		tool
)
	// See comment in header.
{
	OSStatus		err;
	CFURLRef 		templateTool;

	assert(inBundle != NULL);
	assert(templateToolName != NULL);
	assert(toolName != NULL);
	assert( tool != NULL);
	assert(*tool == NULL);
	
	// Lots of folks use CFBundleCopyResourceURL, but CFBundleCopyAuxiliaryExecutableURL 
	// is preferred if the resource is an executable because it allows for bundles 
	// to contain multiple different types of executable (Mach-O and CFM, for example).
	
	templateTool = CFBundleCopyAuxiliaryExecutableURL(inBundle, templateToolName);
	err = CFQError(templateTool);
	if (err == noErr) {
		err = MoreSecCopyHelperToolURLAndCheck(templateTool, folder, subFolderName, toolName, tool);
	}

	// Clean up.
	
	CFQRelease(templateTool);

	assert( (err == noErr) == (*tool != NULL) );
	
	return err;
}

extern OSStatus MoreSecExecuteRequestInHelperTool(CFURLRef helperTool, AuthorizationRef auth, CFDictionaryRef request, CFDictionaryRef *response)
	// See comment in header.
{
	OSStatus 					err;
	int 						err2;
	int 						junk;
	char						toolPath[MAXPATHLEN];
    AuthorizationExternalForm 	extAuth;				// spot the Mac OS type!
    int							fdChild;
    int							fdParent;
    int							childPID;
    int							status;

	assert(helperTool != NULL);
	assert(auth       != NULL);
	assert(request    != NULL);
	assert( response  != NULL);
	assert(*response  == NULL);
	
	childPID = -1;
	fdChild  = -1;
	fdParent = -1;
	
	// Preparatory work.  Stuff we want to do before forking, like getting the 
	// tool's path and creating auth's external form.  If either of these fail, 
	// we want to bail out before the fork.
	
	err = CFQErrorBoolean( CFURLGetFileSystemRepresentation(helperTool, true, (UInt8 *)toolPath, sizeof(toolPath)) );
	if (err == noErr) {
		err = AuthorizationMakeExternalForm(auth, &extAuth);
	}
	
	// Create a pair of anonymous UNIX domain sockets for communication between 
	// the us and the tool.  Name them fdChild and fdParent, just to make things 
	// clear.  It does't make any difference which is which because UNIX domain 
	// sockets are bidirectional.
	
	if (err == noErr) {
		int comm[2];
		
		err = socketpair(AF_UNIX, SOCK_STREAM, 0, comm);
		err = EXXXToOSStatus( MoreUNIXErrno(err) );
		
		if (err == noErr) {
			fdChild  = comm[0];
			fdParent = comm[1];
		}
	}
	
	// Fork.  In the child, replace stdin and stdout with fdChild 
	// (bidirectional, remember).  Then close the child's extra 
	// copy of fdChild and fdParent.  Finally, exec the helper tool.
	// Execution continues in the child's "main" function, which 
	// calls MoreSecHelperToolMain (defined above).
	
	if (err == noErr) {
		childPID = vfork();

		if (childPID == 0) {						// Child
			err = dup2(fdChild, STDIN_FILENO);
			err = EXXXToOSStatus( MoreUNIXErrno(err) );
			
			if (err == noErr) {
				err = dup2(fdChild, STDOUT_FILENO);
				err = EXXXToOSStatus( MoreUNIXErrno(err) );
			}

			if (err == noErr) {
				junk = close(fdChild);
				assert(junk == 0);
				junk = close(fdParent);
				assert(junk == 0);

			    err = execl(toolPath, toolPath, NULL);
			    err = EXXXToOSStatus( MoreUNIXErrno(err) );
			}
		    assert(err != noErr);	// otherwise we wouldn't be here
		    
		    // Use "_exit" rather than "exit" because we're still in the 
		    // same address space as the parent, so exit's closing 
		    // of stdio streams will not be helpful.

		    _exit(MoreSecErrorToHelperToolResult(OSStatusToEXXX(err)));
			
			assert(false);			// unreached
		} else if (childPID == -1) {				// Error, Parent
			err = EXXXToOSStatus( MoreUNIXErrno(childPID) );
		} else {
			assert(childPID > 0);					// Parent
		}
	}
	
	// In the parent, things are a little more complex.  First we 
	// close our redundant copy of fdChild.  Then we sent the 
	// authorization external form to the child via the socket. 
	// Finally, we send the request to the child, also via the 
	// socket.
	
	if (fdChild != -1) {
		junk = close(fdChild);
		assert(junk == 0);
		fdChild = -1;
	}
	if (err == noErr) {	
		err = EXXXToOSStatus( MoreUNIXWrite(fdParent, &extAuth, sizeof(extAuth), NULL) );
	}
	if (err == noErr) {
		err = WriteDictionaryToDescriptor(request, fdParent);
	}

	// Close the write side of our connection to the child. 
	// We need to this because it self repair mode 
	// (ExecuteSelfInPrivilegedSelfRepairMode) the child simply 
	// copies its input to its output, and doesn't leave its copy 
	// loop until EOF on input.  This shutdown triggers that EOF.

	if (err == noErr) {
		err = shutdown(fdParent, 1);
		err = EXXXToOSStatus( MoreUNIXErrno(err) );
	}
	
	// Read the response back from the child, translating any file 
	// descriptors that were passed back along the way.

	if (err == noErr) {
		err = EXXXToOSStatus( CopyDictionaryTranslatingDescriptors(fdParent, response) );
	}
	
	// We're all done with our socket, so close it.  It's important 
	// that we do this here, before the waitpid, so that, if the child 
	// is broken and is blocked waiting on input, it'll get an EPIPE 
	// and quit.
	
	if (fdParent != -1) {
		junk = close(fdParent);
		junk = MoreUNIXErrno(junk);
		assert(junk == 0);
		fdParent = -1;
	}

	// If we started a child, we have to reap it, always, regardless of 
	// whether we have encountered an error so far.
	
	if (childPID != -1) {
	    err2 = waitpid(childPID, &status, 0);
        err2 = MoreUNIXErrno(err2);
        
        CheckWaitForDebuggerInterference(&err2, childPID, &status);

	    if (err == noErr) {
	    	err = EXXXToOSStatus( err2 );
	    }

		// If we successfully got a wait status from the client (or 
		// our communications with the client failed because of 
		// a generic communications error), let's go see whether 
		// the child's wait status is a more appropriate source of 
		// error information.
		
		if ( (err == noErr) || (err == EPIPE) ) {
			if ( ! WIFEXITED(status) ) {
				// If we got a wait status but it's not a valid exit status (perhaps 
				// WIFSIGNALED, indication that the child terminated because of a signal),
				// that's an unexpected error we can't handle.
				
				err = kMoreSecResultInternalErrorErr;
			} else {
				// If we got a valid exit status from the child, map its exit status 
				// into our range so that we return an equivalent status.
				
				err = EXXXToOSStatus( MoreSecHelperToolResultToError(WEXITSTATUS(status)) );
			}
		}
	}
	
	if (err != noErr) {
		if (*response != NULL) {
			MoreSecCloseDescriptorArray((CFArrayRef) CFDictionaryGetValue(*response, kMoreSecFileDescriptorsKey));
		}
		CFQRelease(*response);
		*response = NULL;
	}
	
	assert( (err == noErr) == (*response != NULL) );
	
	return err;
}

extern OSStatus MoreSecGetErrorFromResponse(CFDictionaryRef response)
	// See comment in header.
{
	OSStatus	err;
	CFNumberRef num;
	OSStatus	tmp;
	
	assert(response != NULL);
	
	num = (CFNumberRef) CFDictionaryGetValue(response, kMoreSecErrorNumberKey);
	err = CFQError(num);
	
	if (err == noErr) {
		err = CFQErrorBoolean( CFNumberGetValue(num, kCFNumberSInt32Type, &tmp) );
	}
	if (err == noErr) {	
		err = OSStatusToEXXX(tmp);
	}
	
	return err;
}
