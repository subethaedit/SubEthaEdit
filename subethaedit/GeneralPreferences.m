//
//  GeneralPreferences.m
//  SubEthaEdit
//
//  Created by Martin Ott on Mon Mar 29 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "GeneralPreferences.h"


@implementation GeneralPreferences

- (NSImage *)icon {
    return [NSImage imageNamed:@"GeneralPrefs"];
}

- (NSString *)iconLabel {
    return NSLocalizedStringFromTable(@"GeneralPrefsIconLabel", @"Preferences",Ê@"Label displayed below general icon and used as window title.");
}

- (NSString *)identifier {
    return @"de.codingmonkeys.subethaedit.preferences.general";
}

- (NSString *)mainNibName {
    return @"GeneralPrefs";
}

- (void)mainViewDidLoad {
    // Initialize user interface elements to reflect current preference settings
}

- (void)didUnselect {
    // Save preferences
}

@end
