//
//  DebugPreferences.m
//  SubEthaEdit
//
//  Created by Martin Ott on Thu Feb 26 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "DebugPreferences.h"


@implementation DebugPreferences

- (NSImage *)icon
{
    return [NSImage imageNamed:@"debug"];
}

- (NSString *)iconLabel
{
    return @"Debug";
}

- (NSString *)identifier
{
    return @"de.codingmonkeys.subethaedit.preferences.debug";
}

- (NSString *)mainNibName
{
    return @"DebugPrefs";
}

- (void)mainViewDidLoad
{
    // Initialize user interface elements to reflect current preference settings
}

- (void)didUnselect
{
    // Save preferences
}

@end
