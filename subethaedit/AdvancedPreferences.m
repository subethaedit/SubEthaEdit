//
//  AdvancedPreferences.m
//  SubEthaEdit
//
//  Created by Martin Ott on Tue Sep 07 2004.
//  Copyright 2004 TheCodingMonkeys. All rights reserved.
//

#import "AdvancedPreferences.h"

#import "MoreUNIX.h"
#import "MoreSecurity.h"
#import "MoreCFQ.h"

#import <sys/stat.h>

#define SEE_TOOL_PATH    @"/usr/bin/see"
#define SEE_MANPAGE_PATH @"/usr/share/man/man1/see.1"


@implementation AdvancedPreferences

- (NSImage *)icon {
    return [NSImage imageNamed:@"AdvancedPrefs"];
}

- (NSString *)iconLabel {
    return NSLocalizedString(@"AdvancedPrefsIconLabel", @"Label displayed below advanced icon and used as window title.");
}

- (NSString *)identifier {
    return @"de.codingmonkeys.subethaedit.preferences.advanced";
}

- (NSString *)mainNibName {
    return @"AdvancedPrefs";
}

- (void)didSelect {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
   if([fileManager contentsEqualAtPath:[[NSBundle mainBundle] pathForAuxiliaryExecutable:@"see"]
                               andPath:SEE_TOOL_PATH]) {
        [O_installCommandLineToolButton setEnabled:NO];
        [O_removeCommandLineToolButton setEnabled:YES];   
    } else {
        [O_installCommandLineToolButton setEnabled:YES];
        [O_removeCommandLineToolButton setEnabled:NO];
    }
}

- (IBAction)installCommandLineTool:(id)sender {
    OSStatus err;
    CFURLRef tool = NULL;
    AuthorizationRef auth = NULL;
    NSDictionary *request = nil;
    NSDictionary *response = nil;


    err = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, kAuthorizationFlagDefaults, &auth);
    if (err == noErr) {
        // If we were doing preauthorization, this is where we'd do it.
    }
    
    if (err == noErr) {
        err = MoreSecCopyHelperToolURLAndCheckBundled(
            CFBundleGetMainBundle(), 
            CFSTR("SubEthaEditHelperToolTemplate"), 
            kApplicationSupportFolderType, 
            CFSTR("SubEthaEdit"), 
            CFSTR("SubEthaEditHelperTool"), 
            &tool);

        // If the home directory is on an volume that doesn't support 
        // setuid root helper tools, ask the user whether they want to use 
        // a temporary tool.
        
        if (err == kMoreSecFolderInappropriateErr) {
            err = MoreSecCopyHelperToolURLAndCheckBundled(
                CFBundleGetMainBundle(), 
                CFSTR("SubEthaEditHelperToolTemplate"), 
                kTemporaryFolderType, 
                CFSTR("SubEthaEdit"), 
                CFSTR("SubEthaEditHelperTool"), 
                &tool);
        }
    }
    
    // Create the request dictionary for a file descriptor
                                    
    if (err == noErr) {
        NSString *pathForSeeTool = [[NSBundle mainBundle] pathForAuxiliaryExecutable:@"see"];
        NSNumber *filePermissions = [NSNumber numberWithUnsignedShort:(S_IRWXU | S_IRGRP | S_IXGRP | S_IROTH | S_IXOTH)];
        NSDictionary *targetAttrs = [NSDictionary dictionaryWithObjectsAndKeys:
                                        filePermissions, NSFilePosixPermissions,
                                        @"root", NSFileOwnerAccountName,
                                        @"wheel", NSFileGroupOwnerAccountName,
                                        nil];
                                        
        request = [NSDictionary dictionaryWithObjectsAndKeys:
                            @"CopyFiles", @"CommandName",
                            pathForSeeTool, @"SourceFile",
                            SEE_TOOL_PATH, @"TargetFile",
                            targetAttrs, @"TargetAttributes",
                            nil];
    }

    // Go go gadget helper tool!

    if (err == noErr) {
        err = MoreSecExecuteRequestInHelperTool(tool, auth, (CFDictionaryRef)request, (CFDictionaryRef *)(&response));
    }
    
    // Extract information from the response.

    if (err == noErr) {
        //NSLog(@"response: %@", response);

        err = MoreSecGetErrorFromResponse((CFDictionaryRef)response);
        if (err == noErr) {
        }
    }
    
    // Clean up after first call of helper tool
        
    if (response) {
        [response release];
        response = nil;
    }

    // Create the request dictionary for exchanging file contents
                                    
    if (err == noErr) {
        NSString *pathForSeeManpage = [[NSBundle mainBundle] pathForResource:@"see.1" ofType:nil];
        NSNumber *filePermissions = [NSNumber numberWithUnsignedShort:(S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH)];
        NSDictionary *targetAttrs = [NSDictionary dictionaryWithObjectsAndKeys:
                                        filePermissions, NSFilePosixPermissions,
                                        @"root", NSFileOwnerAccountName,
                                        @"wheel", NSFileGroupOwnerAccountName,
                                        nil];
                                        
        request = [NSDictionary dictionaryWithObjectsAndKeys:
                            @"CopyFiles", @"CommandName",
                            pathForSeeManpage, @"SourceFile",
                            SEE_MANPAGE_PATH, @"TargetFile",
                            targetAttrs, @"TargetAttributes",
                            nil];
    }

    // Go go gadget helper tool!

    if (err == noErr) {
        err = MoreSecExecuteRequestInHelperTool(tool, auth, (CFDictionaryRef)request, (CFDictionaryRef *)(&response));
    }
    
    // Extract information from the response.
    
    if (err == noErr) {
        //NSLog(@"response: %@", response);

        err = MoreSecGetErrorFromResponse((CFDictionaryRef)response);
        if (err == noErr) {
            [O_installCommandLineToolButton setEnabled:NO];
            [O_removeCommandLineToolButton setEnabled:YES];
        }
    }
    
    // Clean up after second call of helper tool.
    if (response) {
        [response release];
    }


    CFQRelease(tool);
    if (auth != NULL) {
        (void)AuthorizationFree(auth, kAuthorizationFlagDestroyRights);
    }
}

- (IBAction)removeCommandLineTool:(id)sender {
    OSStatus err;
    CFURLRef tool = NULL;
    AuthorizationRef auth = NULL;
    NSDictionary *request = nil;
    NSDictionary *response = nil;


    err = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, kAuthorizationFlagDefaults, &auth);
    if (err == noErr) {
        // If we were doing preauthorization, this is where we'd do it.
    }
    
    if (err == noErr) {
        err = MoreSecCopyHelperToolURLAndCheckBundled(
            CFBundleGetMainBundle(), 
            CFSTR("SubEthaEditHelperToolTemplate"), 
            kApplicationSupportFolderType, 
            CFSTR("SubEthaEdit"), 
            CFSTR("SubEthaEditHelperTool"), 
            &tool);

        // If the home directory is on an volume that doesn't support 
        // setuid root helper tools, ask the user whether they want to use 
        // a temporary tool.
        
        if (err == kMoreSecFolderInappropriateErr) {
            err = MoreSecCopyHelperToolURLAndCheckBundled(
                CFBundleGetMainBundle(), 
                CFSTR("SubEthaEditHelperToolTemplate"), 
                kTemporaryFolderType, 
                CFSTR("SubEthaEdit"), 
                CFSTR("SubEthaEditHelperTool"), 
                &tool);
        }
    }
    
    // Create the request dictionary for a file descriptor

    if (err == noErr) {
        NSArray *files = [NSArray arrayWithObjects:SEE_TOOL_PATH, SEE_MANPAGE_PATH, nil];
        request = [NSDictionary dictionaryWithObjectsAndKeys:
                            @"RemoveFiles", @"CommandName",
                            files, @"Files",
                            nil];
    }

    // Go go gadget helper tool!

    if (err == noErr) {
        err = MoreSecExecuteRequestInHelperTool(tool, auth, (CFDictionaryRef)request, (CFDictionaryRef *)(&response));
    }
    
    // Extract information from the response.

    if (err == noErr) {
        //NSLog(@"response: %@", response);

        err = MoreSecGetErrorFromResponse((CFDictionaryRef)response);
        if (err == noErr) {
            [O_installCommandLineToolButton setEnabled:YES];
            [O_removeCommandLineToolButton setEnabled:NO];
        }
    }
            
    if (response) {
        [response release];
        response = nil;
    }
        
    CFQRelease(tool);
    if (auth != NULL) {
        (void)AuthorizationFree(auth, kAuthorizationFlagDestroyRights);
    }
}

@end
