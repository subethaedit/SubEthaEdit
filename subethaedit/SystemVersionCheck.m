//
//  SystemVersionCheck.m
//  SystemVersionCheck
//
//  Created by Chris Campbell on 12/03/2005.
//  Copyright Big Nerd Ranch 2005. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include <stdlib.h>

static void GetVersionComponentsFromString(int *majorPtr, int *minorPtr, int *bugfixPtr, NSString *versionString)
{
    int major = 0;
    int minor = 0;
    int bugfix = 0;
    
    NSArray *array = [versionString componentsSeparatedByString:@"."];
    
    if ([array count] > 0) {
        major = [[array objectAtIndex:0] intValue];
        
        if ([array count] > 1) {
            minor = [[array objectAtIndex:1] intValue];
            
            if ([array count] > 2) {
                bugfix = [[array objectAtIndex:2] intValue];
            }
        }
    }
    
    if (majorPtr != NULL) {
        *majorPtr = major;
    }
    
    if (minorPtr != NULL) {
        *minorPtr = minor;
    }
    
    if (bugfixPtr != NULL) {
        *bugfixPtr = bugfix;
    }
}

static BOOL CheckSystemVersion(NSString **requiredVersionPtr, BOOL *sameMajorMinorPtr)
{
    // Determine the required version
            
    NSString *requiredVersion = [[[[NSBundle mainBundle] infoDictionary] objectForKey:@"LSEnvironment"] objectForKey:@"MinimumSystemVersion"];
    
    if ([requiredVersion length] == 0) {
        requiredVersion = @"10.3.9";
    }
    
    if (requiredVersionPtr != NULL) {
        *requiredVersionPtr = requiredVersion;
    }
    
    int requiredMajor, requiredMinor, requiredBugfix;
    GetVersionComponentsFromString(&requiredMajor, &requiredMinor, &requiredBugfix, requiredVersion);
    
    // Determine the system version
    
    NSString *systemVersion = [[NSDictionary dictionaryWithContentsOfFile:@"/System/Library/CoreServices/SystemVersion.plist"] objectForKey:@"ProductVersion"];    
    
    if ([systemVersion length] == 0) {
        // Can't parse the system version
        if (sameMajorMinorPtr != NULL) {
            *sameMajorMinorPtr = NO;
            return NO;
        }
    }
    
    int systemMajor, systemMinor, systemBugfix;
    GetVersionComponentsFromString(&systemMajor, &systemMinor, &systemBugfix, systemVersion);
    
    if (sameMajorMinorPtr != NULL) {
        *sameMajorMinorPtr = (systemMajor == requiredMajor && systemMinor == requiredMinor);
    }
    
    if (systemMajor < requiredMajor) {
        return NO;
    } else if (systemMajor > requiredMajor) {
        return YES;
    }
    
    // systemMajor == requiredMajor...
    
    if (systemMinor < requiredMinor) {
        return NO;
    } else if (systemMinor > requiredMinor) {
        return YES;
    }
    
    // systemMinor == requiredMinor...
    
    if (systemBugfix < requiredBugfix) {
        return NO;
    }
    
    // systemBugfix >= requiredBugfix...
    
    return YES;
}

static NSString *LocalizedInfoStringForKey(NSString *key)
{
    // First, look for an InfoPlist.strings entry
    
    NSBundle *bundle = [NSBundle mainBundle];
    
    NSString *value = [bundle localizedStringForKey:key value:nil table:@"InfoPlist"];

    if (key != value) {
        return value;
    }
    
    // Otherwise, look in the Info.plist file
    
    return [[bundle infoDictionary] objectForKey:key];
}

static NSString *LocalizedApplicationName()
{
    NSString *value = LocalizedInfoStringForKey(@"CFBundleDisplayName");

    if (!value) {
        value = LocalizedInfoStringForKey(@"CFBundleName");
    }
    
    return value;
}

int main(int argc, char *argv[])
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    // Grab the executable name from the Info.plist.
    // If there isn't one, error out and exit
    
    NSBundle *mainBundle = [NSBundle mainBundle];
    
    NSString *executableName = [[mainBundle infoDictionary] objectForKey:@"CFBundleExecutable"];
    
    if (!executableName) {
        fprintf(stderr, "ERROR: %s must be run from inside a .app wrapper\n", argv[0]);
        return EXIT_FAILURE;
    }
    
    NSString *requiredVersion;
    BOOL sameMajorMinor;
    BOOL canLaunch = CheckSystemVersion(&requiredVersion, &sameMajorMinor);
    
    if (!canLaunch) {
                
        NSString *applicationName = LocalizedApplicationName();
        
        // Use the name of the application as the alert window's title
        
        NSString *windowTitle = applicationName;
        if ([windowTitle length] == 0) {
            windowTitle = @"";
        }
        
        if ([applicationName length] == 0) {
            applicationName = @"This application";
        }
        
        NSString *title = [NSString stringWithFormat:@"%@ requires Mac OS X %@", applicationName, requiredVersion];
        
        NSString *messageFormat;
        NSString *defaultButton;
        NSString *alternateButton;
        if (sameMajorMinor) {
            messageFormat = @"Please use Software Update to upgrade to Mac OS X %@ or later.\n";
            defaultButton = @"Software Update...";
            alternateButton = @"Quit";
        } else {
            messageFormat = @"Please install Mac OS X %@ or later.\n";
            defaultButton = @"Quit";
            alternateButton = nil;
        }
        
        // Load NSApplication and all the GUI stuff
        
        [NSApplication sharedApplication];
        
        NSPanel *alertPanel = NSGetAlertPanel(title, messageFormat, defaultButton, alternateButton, nil, requiredVersion);
        [alertPanel setTitle:windowTitle];
        
        int choice = [NSApp runModalForWindow:alertPanel];
        
        NSReleaseAlertPanel(alertPanel);
        alertPanel = nil;
        
        if (sameMajorMinor && choice == NSAlertDefaultReturn) {
            // Software Update...
            [[NSWorkspace sharedWorkspace] openFile:@"/System/Library/CoreServices/Software Update.app"];
        }
        
        return EXIT_SUCCESS;
        
    }
        
    // Get the path of the real executable
    
    // SystemVersionCheck 1.0 used the convention:
    //    HelloWorld = SystemVersionCheck, HelloWorld.real = real application
    // SystemVersionCheck 1.1 uses the convention:
    //    HelloWorld-SystemVersionCheck = SystemVersionCheck, HelloWorld = real application
    // Fall back to 1.0 behavior for compatability with build systems created for SystemVersionCheck 1.0
    
    NSString *realExecutableName = nil;
    NSString *systemVersionCheckSuffix = @"-SystemVersionCheck";
    if ([executableName hasSuffix:systemVersionCheckSuffix]) {
        NSRange range = NSMakeRange(0, ([executableName length] - [systemVersionCheckSuffix length]));
        if (range.length > 0) {
            realExecutableName = [executableName substringWithRange:range];
        }
    } else {
        realExecutableName = [NSString stringWithFormat:@"%@.real", executableName];
    }
    
    if (!realExecutableName) {
        return EXIT_FAILURE;
    }
    
    NSString *path = [mainBundle pathForAuxiliaryExecutable:realExecutableName];
    
    // Construct a new argv array for the exec'ed process
    
    NSMutableData *argvData = [[NSMutableData alloc] initWithBytes:argv length:(argc * sizeof(*argv))];
    
    // Change the first argument to the path of the new executable
    
    ((const char **)[argvData mutableBytes])[0] = [path UTF8String];
    
    // Append a NULL char* to the end of the array
    
    char *nullPtr = NULL;
    
    [argvData appendBytes:&nullPtr length:sizeof(nullPtr)];
    
    execv(((const char **)[argvData bytes])[0], (const char **)[argvData bytes]);
    
    // This should never be reached
        
    [argvData release];
    argvData = nil;
        
    [pool release];
    pool = nil;
    
    return EXIT_FAILURE; 
}
