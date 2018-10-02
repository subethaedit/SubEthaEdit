//
//  AdvancedPreferences.m
//  SubEthaEdit
//
//  Created by Martin Ott on Tue Sep 07 2004.
//  Copyright 2004 TheCodingMonkeys. All rights reserved.
//

#import "AdvancedPreferences.h"
#import "SEEDocumentController.h"
#import "GeneralPreferences.h"
#import <sys/stat.h>

@implementation AdvancedPreferences

- (NSImage *)icon {
    return [NSImage imageNamed:NSImageNameAdvanced];
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

#pragma mark -

- (void)mainViewDidLoad {
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    BOOL disableState=([defaults objectForKey:@"AppleScreenAdvanceSizeThreshold"] && [[defaults objectForKey:@"AppleScreenAdvanceSizeThreshold"] floatValue]<=1.);
    [self.O_disableScreenFontsButton setState:disableState?NSOnState:NSOffState];
    [self.O_synthesiseFontsButton setState:[defaults boolForKey:SynthesiseFontsPreferenceKey]?NSOnState:NSOffState];
}

- (void)didSelect {
}

#pragma mark -

- (IBAction)visitCommandLineToolWebsite:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:NSLocalizedString(@"WEBSITE_COMMANDLINETOOL", @"CommandLineTool Website Link")]];
}

#pragma mark -

- (IBAction)changeDisableScreenFonts:(id)aSender {
    if ([aSender state]==NSOnState) {
        [[NSUserDefaults standardUserDefaults] setFloat:1. forKey:@"AppleScreenAdvanceSizeThreshold"];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"AppleScreenAdvanceSizeThreshold"];
    }
}

- (IBAction)changeSynthesiseFonts:(id)aSender {
    [[NSUserDefaults standardUserDefaults] setBool:[aSender state]==NSOnState forKey:SynthesiseFontsPreferenceKey];
    // trigger update
    [[[SEEDocumentController sharedInstance] documents] makeObjectsPerformSelector:@selector(applyStylePreferences)];
}


@end
