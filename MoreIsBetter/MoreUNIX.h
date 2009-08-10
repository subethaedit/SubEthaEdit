/*
	File:		MoreUNIX.h

	Contains:	Generic UNIX utilities.

	Written by:	Quinn

	Copyright:	Copyright (c) 2002 by Apple Computer, Inc., All Rights Reserved.

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

$Log: MoreUNIX.h,v $
Revision 1.3  2003/05/23 21:55:51  eskimo1
Added MoreUNIXReadDescriptor and MoreUNIXWriteDescriptor.

Revision 1.2  2002/11/14 20:15:23  eskimo1
In MoreUNIXCopyFile, correctly set the modified and accessed times of the resulting file.

Revision 1.1  2002/11/09 00:15:24  eskimo1
A collection of useful UNIX-level routines.


*/

#pragma once

/////////////////////////////////////////////////////////////////

// MoreIsBetter Setup

#include "MoreSetup.h"

#if !TARGET_RT_MAC_MACHO
	#error MoreUNIX requires the use of Mach-O
#endif

// System prototypes

#include <stdlib.h>

/////////////////////////////////////////////////////////////////

#ifdef __cplusplus
extern "C" {
#endif

// Macros that act like functions to convert OSStatus error codes to errno-style 
// error codes, and vice versa.  Right now these are just pass throughs because 
// OSStatus errors are 32 bit signed values that are generally negative, and 
// errno errors are 32 bit signed values that are small positive.

#define OSStatusToEXXX(os) ((int) (os))
#define EXXXToOSStatus(ex) ((OSStatus) (ex))

// A mechanism to extra errno if a function fails.  You typically use this as 
//
//   fd = open(...);
//   err = MoreUNIXErrno(fd);
//
// or
//
//   err = setuid(0);
//   err = MoreUNIXErrno(err);

#if MORE_DEBUG

	extern int MoreUNIXErrno(int result);

#else

	#define MoreUNIXErrno(err) (((err) < 0) ? errno : 0)

#endif

extern int MoreUNIXRead( int fd,       void *buf, size_t bufSize, size_t *bytesRead   );
	// A wrapper around "read" that keeps reading until either 
	// bufSize bytes are read or until EOF is encountered, 
	// in which case you get EPIPE.
	//
	// If bytesRead is not NULL, *bytesRead will be set to the number 
	// of bytes successfully read.

extern int MoreUNIXWrite(int fd, const void *buf, size_t bufSize, size_t *bytesWritten);
	// A wrapper around "write" that keeps writing until either 
	// all the data is written or an error occurs, in which case 
	// you get EPIPE.
	//
	// If bytesWritten is not NULL, *bytesWritten will be set to the number 
	// of bytes successfully written.

extern int MoreUNIXIgnoreSIGPIPE(void);
	// Sets the handler for SIGPIPE to SIG_IGN.  If you don't call 
	// this, writing to a broken pipe will cause SIGPIPE (rather 
	// than having "write" return EPIPE), which is hardly ever 
	// what you want.

extern int MoreUNIXReadDescriptor(int fd, int *fdRead);
	// Reads a file descriptor from a UNIX domain socket.
	//
	// On entry, fd must be non-negative.
	// On entry, fdRead must not be NULL, *fdRead must be -1
	// On success, *fdRead will be non-negative
	// On error, *fdRead will be -1

extern int MoreUNIXWriteDescriptor(int fd, int fdToWrite);
	// Writes a file descriptor to a UNIX domain socket.
	//
	// On entry, fd must be non-negative, fdToWrite must be 
	// non-negative.

extern int MoreUNIXCopyDescriptorToDescriptor(int source, int dest);
	// A naive copy engine, that copies from source to dest 
	// until EOF is encountered on source.  Not meant for 
	// copying large amounts of data.
	
extern int MoreUNIXCopyFile(const char *source, const char *dest);
	// A very naive file copy implementation, that just opens 
	// up source and dest and copies the contents across 
	// using MoreUNIXCopyDescriptorToDescriptor.
	// It does, however, handle setting the mode and access/modification 
	// times of dest properly.

#ifdef __cplusplus
}
#endif
