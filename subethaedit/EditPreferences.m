//
//  EditPreferences.m
//  SubEthaEdit
//
//  Created by Martin Ott on Mon Mar 29 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "EditPreferences.h"


@implementation EditPreferences

- (NSImage *)icon {
    return [NSImage imageNamed:@"EditPrefs"];
}

- (NSString *)iconLabel {
    return NSLocalizedStringFromTable(@"EditPrefsIconLabel", @"Preferences",Ê@"Label displayed below edit icon and used as window title.");
}

- (NSString *)identifier {
    return @"de.codingmonkeys.subethaedit.preferences.edit";
}

- (NSString *)mainNibName {
    return @"EditPrefs";
}

- (void)mainViewDidLoad {
    // Initialize user interface elements to reflect current preference settings
}

- (void)didUnselect {
    // Save preferences
}

@end
