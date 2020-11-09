//  AdvancedPreferences.m
//  SubEthaEdit
//
//  Created by Martin Ott on Tue Sep 07 2004.

#import "AdvancedPreferences.h"
#import "SEEDocumentController.h"
#import "GeneralPreferences.h"
#import <sys/stat.h>
#import "AppController.h"

@implementation AdvancedPreferences

- (NSImage *)icon {
    if (@available(macOS 10.16, *)) {
        return [NSImage imageWithSystemSymbolName:@"gear" accessibilityDescription:nil];
    } else {
        return [NSImage imageNamed:NSImageNameAdvanced];
    }
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
    
    NSString *absolutePath = [[AppController sharedInstance].URLOfInstallCommand path];
    [self.commandLineInstallTextField setStringValue:[@"sudo " stringByAppendingString:[absolutePath stringByReplacingOccurrencesOfString:@" " withString:@"\\ "]]];
}

- (void)didSelect {
}

- (IBAction)revealInstallCommandInFinder:(id)sender {
    [[AppController sharedInstance] revealInstallCommandInFinder:sender];
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
