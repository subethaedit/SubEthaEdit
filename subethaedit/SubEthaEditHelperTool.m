//
//  SubEthaEditHelperTool.m
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

static OSStatus CopyFiles(CFStringRef sourceFile, CFStringRef targetFile, CFDictionaryRef targetAttrs, CFDictionaryRef *result)
{
    OSStatus err;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    err = MoreSecSetPrivilegedEUID();
    if (err == noErr) {
        if ([fileManager fileExistsAtPath:(NSString *)targetFile]) {
            (void)[fileManager removeFileAtPath:(NSString *)targetFile handler:nil];
        }
        BOOL result = [fileManager copyPath:(NSString *)sourceFile toPath:(NSString *)targetFile handler:nil];
        if (result) {
            result = [fileManager changeFileAttributes:(NSDictionary *)targetAttrs atPath:(NSString *)targetFile];
        }
        err = result ? noErr : paramErr;
    }
    
    return err;
}

static OSStatus RemoveFiles(CFArrayRef files, CFDictionaryRef *result)
{
    OSStatus err;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    int i;
    int count;
    
    err = MoreSecSetPrivilegedEUID();
    count = [(NSArray *)files count];
    if (err == noErr) {
        BOOL result = YES;
        for (i = 0; i < count; i++) {
            result = [fileManager removeFileAtPath:[(NSArray *)files objectAtIndex:i] handler:nil];
            if (!result) {
                break;
            }
        }
        err = result ? noErr : paramErr;
    }
    
    return err;
}

static OSStatus GetReadOnlyFileDescriptor(CFStringRef fileName, CFDictionaryRef *result) {
    OSStatus err;
    NSMutableArray *descArray;
    int desc = NULL;
    NSNumber *descNum;
    
    const char *path = [[NSFileManager defaultManager] fileSystemRepresentationWithPath:(NSString *)fileName];
    
    descNum = NULL;
    
    descArray = [NSMutableArray new];
    err = MoreSecSetPrivilegedEUID();
    if (err == noErr) {
        desc = open(path, O_RDONLY, 0);
        (void)MoreSecTemporarilySetNonPrivilegedEUID();
    }
    descNum = [NSNumber numberWithInt:desc];
    [descArray addObject:descNum];
    *result = (CFDictionaryRef)[[NSDictionary dictionaryWithObject:descArray forKey:(NSString *)kMoreSecFileDescriptorsKey] retain];
    [descArray release];
    
    return err;
}

static OSStatus GetFileDescriptor(CFStringRef fileName, CFDictionaryRef *result)
{
    OSStatus err;
    NSMutableArray *descArray;
    int desc = NULL;
    NSNumber *descNum;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    
    descNum = NULL;
    
    descArray = [NSMutableArray new];
    err = MoreSecSetPrivilegedEUID();
    if (err == noErr) {
        const char *path = [fileManager fileSystemRepresentationWithPath:(NSString *)fileName];
        desc = open(path, O_CREAT | O_RDWR, S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH);
        (void)MoreSecTemporarilySetNonPrivilegedEUID();
    }
    descNum = [NSNumber numberWithInt:desc];
    [descArray addObject:descNum];
    *result = (CFDictionaryRef)[[NSDictionary dictionaryWithObject:descArray forKey:(NSString *)kMoreSecFileDescriptorsKey] retain];
    //NSLog(@"result dictionary: %@", (NSDictionary *)*result);
    [descArray release];
    
    return err;
}

static OSStatus ExchangeFileContents(CFStringRef path1, CFStringRef path2, CFDictionaryRef path2Attrs, CFDictionaryRef *result) {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    char cPath1[MAXPATHLEN+1];
    char cPath2[MAXPATHLEN+1];
    int err;
    OSStatus status;
    
    if (![(NSString *)path1 getFileSystemRepresentation:cPath1 maxLength:MAXPATHLEN] || ![(NSString *)path2 getFileSystemRepresentation:cPath2 maxLength:MAXPATHLEN]) return paramErr;

    //NSLog(@"trying MoreSecSetPrivilegedEUID");
    status = MoreSecSetPrivilegedEUID();
    if (status == noErr) {
        //NSLog(@"MoreSecSetPrivilegedEUID succeeded");
        err = exchangedata(cPath1, cPath2, 0) ? errno : 0;

        if (err == EACCES || err == EPERM) {	// Seems to be a write-protected or locked file; try temporarily changing
            //NSLog(@"Seems to be a write-protected or locked file; try temporarily changing");
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
            //NSLog(@"first or second call to exchangedata succeeded");
            [fileManager removeFileAtPath:(NSString *)path1 handler:nil];
        } else {
            //NSLog(@"exchangedata failed, try to move file");
            NSDictionary *curAttrs = [fileManager fileAttributesAtPath:(NSString *)path2 traverseLink:YES];
            BOOL success = [fileManager movePath:(NSString *)path1 toPath:(NSString *)path2 handler:nil];
            if (!success) {
                //NSLog(@"move failed");
                (void)[fileManager removeFileAtPath:(NSString *)path1 handler:nil];
                status = paramErr;
            } else {
                NSDictionary *attrs = (NSDictionary *)path2Attrs;
                if (curAttrs) {
                    attrs = curAttrs;
                }
                (void)[fileManager changeFileAttributes:attrs atPath:(NSString *)path2];
            }
        }
        
        (void)MoreSecTemporarilySetNonPrivilegedEUID();
    }
    
    return status;
}

static OSStatus AquireRight(AuthorizationRef auth)
{
    OSStatus err;
    static const char *kRightName = "de.codingmonkeys.SubEthaEdit.HelperTool";
    static const AuthorizationFlags kAuthFlags = kAuthorizationFlagDefaults 
                                               | kAuthorizationFlagInteractionAllowed
                                               | kAuthorizationFlagExtendRights
                                               ;
    AuthorizationItem   right  = { kRightName, 0, NULL, 0 };
    AuthorizationRights rights = { 1, &right };

    // Before doing our privileged work, acquire an authorization right.
    // This allows the system administrator to configure the system 
    // (via "/etc/authorization") for the security level that they want.
    //
    // Unfortunately, the default rule in "/etc/authorization" always 
    // triggers a password dialog.  Right now, there's no way around 
    // this [2939908].  One commonly accepted workaround is to not 
    // acquire a authorization right (ie don't call AuthorizationCopyRights
    // here) but instead limit your tool in some other way.  For example, 
    // an Internet setup assistant helper tool might only allow the user 
    // to modify network locations that they created.
    
    #if MORE_DEBUG
        fprintf(stderr, "MoreSecurityTest: HelperTool: Calling ACR\n");
    #endif

    err = AuthorizationCopyRights(auth, &rights, kAuthorizationEmptyEnvironment, kAuthFlags, NULL);

    #if MORE_DEBUG
        fprintf(stderr, "MoreSecurityTest: HelperTool: ACR returned %ld\n", err);
    #endif
    
    return err;
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
            err = AquireRight(auth);
            if (err == noErr) {
                err = GetFileDescriptor(fileName, result);
            }
        } else if (CFEqual(command, CFSTR("ExchangeFileContents"))) {
            CFStringRef intermediateFileName = (CFStringRef)CFDictionaryGetValue(request, CFSTR("IntermediateFileName"));
            CFStringRef actualFileName = (CFStringRef)CFDictionaryGetValue(request, CFSTR("ActualFileName"));
            CFDictionaryRef attributes = (CFDictionaryRef)CFDictionaryGetValue(request, CFSTR("Attributes"));
            err = AquireRight(auth);
            if (err == noErr) {
                err = ExchangeFileContents(intermediateFileName, actualFileName, attributes, result);
            }
        } else if (CFEqual(command, CFSTR("CopyFiles"))) {
            CFStringRef sourceFile = (CFStringRef)CFDictionaryGetValue(request, CFSTR("SourceFile"));
            CFStringRef targetFile = (CFStringRef)CFDictionaryGetValue(request, CFSTR("TargetFile"));
            CFDictionaryRef targetAttrs = (CFDictionaryRef)CFDictionaryGetValue(request, CFSTR("TargetAttributes"));
            err = AquireRight(auth);
            if (err == noErr) {
                err = CopyFiles(sourceFile, targetFile, targetAttrs, result);
            }
        } else if (CFEqual(command, CFSTR("RemoveFiles"))) {
            CFArrayRef files = (CFArrayRef)CFDictionaryGetValue(request, CFSTR("Files"));
            err = AquireRight(auth);
            if (err == noErr) {
                err = RemoveFiles(files, result);
            }
        } else if (CFEqual(command, CFSTR("GetReadOnlyFileDescriptor"))) {
            CFStringRef fileName = (CFStringRef)CFDictionaryGetValue(request, CFSTR("FileName"));
            err = AquireRight(auth);
            if (err == noErr) {
                err = GetReadOnlyFileDescriptor(fileName, result);
            }
        }
    }
    return err;
}


int main(int argc, const char *argv[]) {	

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    //NSLog(@"PID %qd starting\nEUID = %ld\nRUID = %ld\n", (long long)getpid(), (long)geteuid(), (long)getuid());
        
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

    //NSLog(@"PID %qd stopping\nerr = %d\nresult = %d", (long long)getpid(), err, result);
    [pool release];
        
    return result;
}