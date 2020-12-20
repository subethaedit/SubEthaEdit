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
        return [NSImage imageWithSystemSymbolName:@"gearshape.2" accessibilityDescription:nil];
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
    [self.O_disableScreenFontsButton setState:disableState?NSControlStateValueOn:NSControlStateValueOff];
    [self.O_synthesiseFontsButton setState:[defaults boolForKey:SynthesiseFontsPreferenceKey]?NSControlStateValueOn:NSControlStateValueOff];
    
    NSString *absolutePath = [[AppController sharedInstance].URLOfInstallCommand path];
    [self.commandLineInstallTextField setStringValue:[@"sudo " stringByAppendingString:[absolutePath stringByReplacingOccurrencesOfString:@" " withString:@"\\ "]]];
}

- (void)didSelect {
}

- (IBAction)copyScriptAction:(id)sender {
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    [pasteboard clearContents];
    [pasteboard setString:self.commandLineInstallTextField.stringValue forType:NSPasteboardTypeString];
}

- (IBAction)revealInstallCommandInFinder:(id)sender {
    [[AppController sharedInstance] revealInstallCommandInFinder:sender];
}

#pragma mark -

- (IBAction)changeDisableScreenFonts:(id)aSender {
    if ([aSender state]==NSControlStateValueOn) {
        [[NSUserDefaults standardUserDefaults] setFloat:1. forKey:@"AppleScreenAdvanceSizeThreshold"];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"AppleScreenAdvanceSizeThreshold"];
    }
}

- (IBAction)changeSynthesiseFonts:(id)aSender {
    [[NSUserDefaults standardUserDefaults] setBool:[aSender state]==NSControlStateValueOn forKey:SynthesiseFontsPreferenceKey];
    // trigger update
    [[[SEEDocumentController sharedInstance] documents] makeObjectsPerformSelector:@selector(applyStylePreferences)];
}


@end
