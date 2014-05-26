//
//  AdvancedPreferences.m
//  SubEthaEdit
//
//  Created by Martin Ott on Tue Sep 07 2004.
//  Copyright 2004 TheCodingMonkeys. All rights reserved.
//

#import "AdvancedPreferences.h"
#import "SEEDocumentController.h"
#import "GeneralPreferences.h"
#import <sys/stat.h>

@implementation AdvancedPreferences

- (NSImage *)icon {
    return [NSImage imageNamed:NSImageNameAdvanced];
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

#pragma mark

- (void)mainViewDidLoad {
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    BOOL disableState=([defaults objectForKey:@"AppleScreenAdvanceSizeThreshold"] && [[defaults objectForKey:@"AppleScreenAdvanceSizeThreshold"] floatValue]<=1.);
    [O_disableScreenFontsButton setState:disableState?NSOnState:NSOffState];
    [O_synthesiseFontsButton setState:[defaults boolForKey:SynthesiseFontsPreferenceKey]?NSOnState:NSOffState];
}

- (void)didSelect {
//    BOOL isDir;
//    if ([[NSFileManager defaultManager] fileExistsAtPath:SEE_TOOL_PATH isDirectory:&isDir] && !isDir) {
//        [O_commandLineToolRemoveButton setEnabled:YES];
//    } else {
//        [O_commandLineToolRemoveButton setEnabled:NO];
//    }
}

#pragma mark

//- (BOOL)installCommandLineTool {
//    OSStatus err;
//    CFURLRef tool = NULL;
//    AuthorizationRef auth = NULL;
//    NSDictionary *request = nil;
//    NSDictionary *response = nil;
//    BOOL result = NO;
//
//
//    err = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, kAuthorizationFlagDefaults, &auth);
//    if (err == noErr) {
//        static const char *kRightName = "de.codingmonkeys.SubEthaEdit.HelperTool";
//        static const AuthorizationFlags kAuthFlags = kAuthorizationFlagDefaults 
//                                                   | kAuthorizationFlagInteractionAllowed
//                                                   | kAuthorizationFlagExtendRights
//                                                   | kAuthorizationFlagPreAuthorize;
//        AuthorizationItem   right  = { kRightName, 0, NULL, 0 };
//        AuthorizationRights rights = { 1, &right };
//
//        err = AuthorizationCopyRights(auth, &rights, kAuthorizationEmptyEnvironment, kAuthFlags, NULL);
//    }
//    
//    if (err == noErr) {
//        err = MoreSecCopyHelperToolURLAndCheckBundled(
//            CFBundleGetMainBundle(), 
//            CFSTR("SubEthaEditHelperToolTemplate"), 
//            kApplicationSupportFolderType, 
//            CFSTR("SubEthaEdit"), 
//            CFSTR("SubEthaEditHelperTool"), 
//            &tool);
//
//        // If the home directory is on an volume that doesn't support 
//        // setuid root helper tools, ask the user whether they want to use 
//        // a temporary tool.
//        
//        if (err == kMoreSecFolderInappropriateErr) {
//            err = MoreSecCopyHelperToolURLAndCheckBundled(
//                CFBundleGetMainBundle(), 
//                CFSTR("SubEthaEditHelperToolTemplate"), 
//                kTemporaryFolderType, 
//                CFSTR("SubEthaEdit"), 
//                CFSTR("SubEthaEditHelperTool"), 
//                &tool);
//        }
//    }
//    
//    // Create the request dictionary for a file descriptor
//                                    
//    if (err == noErr) {
//        NSString *pathForSeeTool = [[NSBundle mainBundle] pathForAuxiliaryExecutable:@"see"];
//        NSNumber *filePermissions = [NSNumber numberWithUnsignedShort:(S_IRWXU | S_IRGRP | S_IXGRP | S_IROTH | S_IXOTH)];
//        NSDictionary *targetAttrs = [NSDictionary dictionaryWithObjectsAndKeys:
//                                        filePermissions, NSFilePosixPermissions,
//                                        @"root", NSFileOwnerAccountName,
//                                        @"wheel", NSFileGroupOwnerAccountName,
//                                        nil];
//                                        
//        request = [NSDictionary dictionaryWithObjectsAndKeys:
//                            @"CopyFiles", @"CommandName",
//                            pathForSeeTool, @"SourceFile",
//                            SEE_TOOL_PATH, @"TargetFile",
//                            targetAttrs, @"TargetAttributes",
//                            nil];
//    }
//
//    // Go go gadget helper tool!
//
//    if (err == noErr) {
//        err = MoreSecExecuteRequestInHelperTool(tool, auth, (CFDictionaryRef)request, (CFDictionaryRef *)(&response));
//    }
//    
//    // Extract information from the response.
//
//    if (err == noErr) {
//        //NSLog(@"response: %@", response);
//
//        err = MoreSecGetErrorFromResponse((CFDictionaryRef)response);
//        if (err == noErr) {
//        }
//    }
//    
//    // Clean up after first call of helper tool
//        
//    if (response) {
//        [response release];
//        response = nil;
//    }
//
//    // Create the request dictionary for exchanging file contents
//                                    
//    if (err == noErr) {
//        NSString *pathForSeeManpage = [[NSBundle mainBundle] pathForResource:@"see.1" ofType:nil];
//        NSNumber *filePermissions = [NSNumber numberWithUnsignedShort:(S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH)];
//        NSDictionary *targetAttrs = [NSDictionary dictionaryWithObjectsAndKeys:
//                                        filePermissions, NSFilePosixPermissions,
//                                        @"root", NSFileOwnerAccountName,
//                                        @"wheel", NSFileGroupOwnerAccountName,
//                                        nil];
//                                        
//        request = [NSDictionary dictionaryWithObjectsAndKeys:
//                            @"CopyFiles", @"CommandName",
//                            pathForSeeManpage, @"SourceFile",
//                            SEE_MANPAGE_PATH, @"TargetFile",
//                            targetAttrs, @"TargetAttributes",
//                            nil];
//    }
//
//    // Go go gadget helper tool!
//
//    if (err == noErr) {
//        err = MoreSecExecuteRequestInHelperTool(tool, auth, (CFDictionaryRef)request, (CFDictionaryRef *)(&response));
//    }
//    
//    // Extract information from the response.
//    
//    if (err == noErr) {
//        //NSLog(@"response: %@", response);
//
//        err = MoreSecGetErrorFromResponse((CFDictionaryRef)response);
//        if (err == noErr) {
//            result = YES;
//        }
//    }
//    
//    // Clean up after second call of helper tool.
//    if (response) {
//        [response release];
//    }
//
//
//    CFQRelease(tool);
//    if (auth != NULL) {
//        (void)AuthorizationFree(auth, kAuthorizationFlagDestroyRights);
//    }
//    
//    return result;
//}
//
//- (BOOL)removeCommandLineTool {
//    OSStatus err;
//    CFURLRef tool = NULL;
//    AuthorizationRef auth = NULL;
//    NSDictionary *request = nil;
//    NSDictionary *response = nil;
//    BOOL result = NO;
//
//
//    err = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, kAuthorizationFlagDefaults, &auth);
//    if (err == noErr) {
//        static const char *kRightName = "de.codingmonkeys.SubEthaEdit.HelperTool";
//        static const AuthorizationFlags kAuthFlags = kAuthorizationFlagDefaults 
//                                                   | kAuthorizationFlagInteractionAllowed
//                                                   | kAuthorizationFlagExtendRights
//                                                   | kAuthorizationFlagPreAuthorize;
//        AuthorizationItem   right  = { kRightName, 0, NULL, 0 };
//        AuthorizationRights rights = { 1, &right };
//
//        err = AuthorizationCopyRights(auth, &rights, kAuthorizationEmptyEnvironment, kAuthFlags, NULL);
//    }
//    
//    if (err == noErr) {
//        err = MoreSecCopyHelperToolURLAndCheckBundled(
//            CFBundleGetMainBundle(), 
//            CFSTR("SubEthaEditHelperToolTemplate"), 
//            kApplicationSupportFolderType, 
//            CFSTR("SubEthaEdit"), 
//            CFSTR("SubEthaEditHelperTool"), 
//            &tool);
//
//        // If the home directory is on an volume that doesn't support 
//        // setuid root helper tools, ask the user whether they want to use 
//        // a temporary tool.
//        
//        if (err == kMoreSecFolderInappropriateErr) {
//            err = MoreSecCopyHelperToolURLAndCheckBundled(
//                CFBundleGetMainBundle(), 
//                CFSTR("SubEthaEditHelperToolTemplate"), 
//                kTemporaryFolderType, 
//                CFSTR("SubEthaEdit"), 
//                CFSTR("SubEthaEditHelperTool"), 
//                &tool);
//        }
//    }
//    
//    // Create the request dictionary for a file descriptor
//
//    if (err == noErr) {
//        NSArray *files = [NSArray arrayWithObjects:SEE_TOOL_PATH, SEE_MANPAGE_PATH, nil];
//        request = [NSDictionary dictionaryWithObjectsAndKeys:
//                            @"RemoveFiles", @"CommandName",
//                            files, @"Files",
//                            nil];
//    }
//
//    // Go go gadget helper tool!
//
//    if (err == noErr) {
//        err = MoreSecExecuteRequestInHelperTool(tool, auth, (CFDictionaryRef)request, (CFDictionaryRef *)(&response));
//    }
//    
//    // Extract information from the response.
//
//    if (err == noErr) {
//        //NSLog(@"response: %@", response);
//
//        err = MoreSecGetErrorFromResponse((CFDictionaryRef)response);
//        if (err == noErr) {
//            result = YES;
//        }
//    }
//            
//    if (response) {
//        [response release];
//        response = nil;
//    }
//        
//    CFQRelease(tool);
//    if (auth != NULL) {
//        (void)AuthorizationFree(auth, kAuthorizationFlagDestroyRights);
//    }
//    
//    return result;
//}

#pragma mark -

//- (IBAction)commandLineToolInstall:(id)sender {
//    BOOL success = [self installCommandLineTool];
//    if (success) {
//        NSAlert *alert = [[NSAlert alloc] init];
//        [alert setAlertStyle:NSInformationalAlertStyle];
//        [alert setMessageText:NSLocalizedString(@"The see command line tool has been installed.", @"Message text in modal dialog in advanced prefs")];
//        [alert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"You can find the see command line tool at:\n \"%@\".", @"Informative text in modal dialog in advanced prefs"), SEE_TOOL_PATH]];
//        [alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
//        (void)[alert runModal];
//        [alert release];
//        [O_commandLineToolRemoveButton setEnabled:YES];
//    } else {
//        NSAlert *alert = [[NSAlert alloc] init];
//        [alert setAlertStyle:NSWarningAlertStyle];
//        [alert setMessageText:NSLocalizedString(@"The installation of the see command line tool failed.", @"Message text in modal dialog in advanced prefs")];
//        [alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
//        (void)[alert runModal];
//        [alert release];
//    }
//}
//
//- (IBAction)commandLineToolRemove:(id)sender {
//    BOOL success = [self removeCommandLineTool];
//    if (success) {
//        NSAlert *alert = [[NSAlert alloc] init];
//        [alert setAlertStyle:NSInformationalAlertStyle];
//        [alert setMessageText:NSLocalizedString(@"The see command line tool has been removed.", @"Message text in modal dialog in advanced prefs")];
//        [alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
//        (void)[alert runModal];
//        [alert release];
//        [O_commandLineToolRemoveButton setEnabled:NO];
//    } else {
//        NSAlert *alert = [[NSAlert alloc] init];
//        [alert setAlertStyle:NSWarningAlertStyle];
//        [alert setMessageText:NSLocalizedString(@"The see command line tool couldn't be removed.", @"Message text in modal dialog in advanced prefs")];
//        [alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
//        (void)[alert runModal];
//		[alert release];
//    }
//}

- (IBAction)visitCommandLineToolWebsite:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://subethaedit.net/commandlinetool/"]];
}

#pragma mark

- (IBAction)changeDisableScreenFonts:(id)aSender {
    if ([aSender state]==NSOnState) {
        [[NSUserDefaults standardUserDefaults] setFloat:1. forKey:@"AppleScreenAdvanceSizeThreshold"];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"AppleScreenAdvanceSizeThreshold"];
    }
}

- (IBAction)changeSynthesiseFonts:(id)aSender {
    [[NSUserDefaults standardUserDefaults] setBool:[aSender state]==NSOnState forKey:SynthesiseFontsPreferenceKey];
    // trigger update
    [[[SEEDocumentController sharedInstance] documents] makeObjectsPerformSelector:@selector(applyStylePreferences)];
}


@end
