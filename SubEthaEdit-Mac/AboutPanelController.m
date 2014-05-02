//
//  AboutPanelController.m
//  SubEthaEdit
//
//  Created by Martin Ott on Thu May 13 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "AboutPanelController.h"
#import <OgreKit/OgreKit.h>

// this file needs arc - either project wide,
// or add -fobjc-arc on a per file basis in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

@implementation AboutPanelController

- (id)init {
    self = [super initWithWindowNibName:@"AboutPanel"];
    return self;
}

- (void)windowDidLoad {
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *versionString = [NSString stringWithFormat:NSLocalizedString(@"Version %@ (%@)", @"Marketing version followed by build version e.g. Version 2.0 (739)"), 
                                [mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                                [mainBundle objectForInfoDictionaryKey:@"CFBundleVersion"]];
    NSString *ogreVersion = [NSString stringWithFormat:@"OgreKit v%@, Oniguruma v%@", [OGRegularExpression version], [OGRegularExpression onigurumaVersion]];

    [self.O_versionField setObjectValue:versionString];
    [self.O_ogreVersionField setObjectValue:ogreVersion];
    [self.O_legalTextField setObjectValue:[mainBundle objectForInfoDictionaryKey:@"NSHumanReadableCopyright"]];

    [[self window] center];
}

- (IBAction)showWindow:(id)sender {
    [[self window] center];
    [super showWindow:self];
}

@end
