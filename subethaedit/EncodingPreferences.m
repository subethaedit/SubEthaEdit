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
    return @"Encoding";
}

- (NSString *)mainNibName
{
    return @"EncodingPrefs";
}

- (void)mainViewDidLoad
{
    // Initialize state of view's graphical elements
}

@end
