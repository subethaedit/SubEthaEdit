//
//  AdvancedPreferences.m
//  SubEthaEdit
//
//  Created by Martin Ott on 07.09.04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "AdvancedPreferences.h"


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

@end
