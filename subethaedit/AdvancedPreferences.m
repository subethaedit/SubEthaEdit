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
        [O_installCommandLineToolButton setEnabled:NO];
        [O_removeCommandLineToolButton setEnabled:YES];   
    } else {
        [O_installCommandLineToolButton setEnabled:YES];
        [O_removeCommandLineToolButton setEnabled:NO];
    }
}

- (IBAction)installCommandLineTool:(id)sender {
    BOOL result = [SetupController installCommandLineTool];
    if (result) {
        [O_installCommandLineToolButton setEnabled:NO];
        [O_removeCommandLineToolButton setEnabled:YES];
    }
}

- (IBAction)removeCommandLineTool:(id)sender {
     BOOL result = [SetupController removeCommandLineTool];
     if (result) {
        [O_installCommandLineToolButton setEnabled:YES];
        [O_removeCommandLineToolButton setEnabled:NO];
     }
}

@end
