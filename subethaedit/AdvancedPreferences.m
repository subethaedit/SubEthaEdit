//
//  AdvancedPreferences.m
//  SubEthaEdit
//
//  Created by Martin Ott on Tue Sep 07 2004.
//  Copyright 2004 TheCodingMonkeys. All rights reserved.
//

#import "AdvancedPreferences.h"
#import "SetupController.h"


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
        [O_commandLineToolStatusTextField setObjectValue:NSLocalizedString(@"AdvancedPrefs InstalledSeeToolUpToDate", @"Status text telling that the installed see tool is up to date")];
        [O_installCommandLineToolButton setEnabled:NO];
        [O_removeCommandLineToolButton setEnabled:YES];   
    } else {
        [O_installCommandLineToolButton setEnabled:YES];
        [O_removeCommandLineToolButton setEnabled:NO];
        BOOL isDir;
        if ([fileManager fileExistsAtPath:SEE_TOOL_PATH isDirectory:&isDir] && !isDir) {
            [O_commandLineToolStatusTextField setObjectValue:NSLocalizedString(@"AdvancedPrefs InstalledSeeToolOutdated", @"Status text telling that the installed see tool is outdated")];
        } else {
            [O_commandLineToolStatusTextField setObjectValue:NSLocalizedString(@"AdvancedPrefs SeeToolNotInstalled", @"Status text telling that the see tool couldn't be located")];
        }
    }
}

- (IBAction)installCommandLineTool:(id)sender {
    BOOL result = [SetupController installCommandLineTool];
    if (result) {
        [O_commandLineToolStatusTextField setObjectValue:NSLocalizedString(@"AdvancedPrefs InstalledSeeToolUpToDate", @"Status text telling that the installed see tool is up to date")];
        [O_installCommandLineToolButton setEnabled:NO];
        [O_removeCommandLineToolButton setEnabled:YES];
    } else {
        [O_commandLineToolStatusTextField setObjectValue:NSLocalizedString(@"AdvancedPrefs InstallingSeeToolFailed", @"Status text telling that the installation of the see tool failed")];
    }
}

- (IBAction)removeCommandLineTool:(id)sender {
     BOOL result = [SetupController removeCommandLineTool];
     if (result) {
        [O_commandLineToolStatusTextField setObjectValue:NSLocalizedString(@"AdvancedPrefs SeeToolNotInstalled", @"Status text telling that the see tool couldn't be located")];
        [O_installCommandLineToolButton setEnabled:YES];
        [O_removeCommandLineToolButton setEnabled:NO];
     } else {
        [O_commandLineToolStatusTextField setObjectValue:NSLocalizedString(@"AdvancedPrefs RemovingSeeToolFailed", @"Status text telling that the removal of the see tool failed")];
     }
}

@end
