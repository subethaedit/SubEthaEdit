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
    BOOL isDir;
    if ([[NSFileManager defaultManager] fileExistsAtPath:SEE_TOOL_PATH isDirectory:&isDir] && !isDir) {
        [O_commandLineToolRemoveButton setEnabled:YES];
    } else {
        [O_commandLineToolRemoveButton setEnabled:NO];
    }
}


#pragma mark -

- (IBAction)commandLineToolInstall:(id)sender {
    BOOL success = [SetupController installCommandLineTool];
    if (success) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setAlertStyle:NSInformationalAlertStyle];
        [alert setMessageText:NSLocalizedString(@"The see command line tool has been installed.", @"Message text in modal dialog in advanced prefs")];
        [alert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"You can find the see command line tool at:\n \"%@\".", @"Informative text in modal dialog in advanced prefs"), SEE_TOOL_PATH]];
        [alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
        (void)[alert runModal];
        [alert release];
        [O_commandLineToolRemoveButton setEnabled:YES];
    } else {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert setMessageText:NSLocalizedString(@"The installation of the see command line tool failed.", @"Message text in modal dialog in advanced prefs")];
        [alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
        (void)[alert runModal];
        [alert release];
    }
}

- (IBAction)commandLineToolRemove:(id)sender {
    BOOL success = [SetupController removeCommandLineTool];
    if (success) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setAlertStyle:NSInformationalAlertStyle];
        [alert setMessageText:NSLocalizedString(@"The see command line tool has been removed.", @"Message text in modal dialog in advanced prefs")];
        [alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
        (void)[alert runModal];
        [alert release];
        [O_commandLineToolRemoveButton setEnabled:NO];
    } else {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert setMessageText:NSLocalizedString(@"The see command line tool couldn't be removed.", @"Message text in modal dialog in advanced prefs")];
        [alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
        (void)[alert runModal];
    }
}

@end
