//
//  EncodingPreferences.m
//  SubEthaEdit
//
//  Created by Martin Ott on Thu Feb 26 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "EncodingPreferences.h"


@implementation EncodingPreferences

- (NSImage *)icon
{
    return [[NSImage new] autorelease];
}

- (NSString *)iconLabel
{
    return NSLocalizedStringFromTable(@"EncodingPrefsIconLabel", @"Preferences",Ê@"Label displayed below preference icon and used as window title.");
}

- (NSString *)identifier
{
    return @"de.codingmonkeys.subethaedit.preferences.encoding";
}

- (NSString *)mainNibName
{
    return @"EncodingPrefs";
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
