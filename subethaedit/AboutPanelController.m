//
//  AboutPanelController.m
//  SubEthaEdit
//
//  Created by Martin Ott on Thu May 13 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "AboutPanelController.h"


@implementation AboutPanelController

- (id)init {
    self = [super initWithWindowNibName:@"AboutPanel"];
    return self;
}

- (void)windowDidLoad {
    NSBundle *mainBundle = [NSBundle mainBundle];
    [O_appNameField setObjectValue:[mainBundle objectForInfoDictionaryKey:@"CFBundleName"]];
    NSString *versionString = [NSString stringWithFormat:@"%@ (v%@)", 
                                [mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                                [mainBundle objectForInfoDictionaryKey:@"CFBundleVersion"]];
    [O_versionField setObjectValue:versionString];
    [O_legalTextField setObjectValue:[mainBundle objectForInfoDictionaryKey:@"NSHumanReadableCopyright"]];

    [[self window] center];
}

@end
