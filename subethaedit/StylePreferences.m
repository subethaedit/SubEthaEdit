//
//  StylePreferences.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Mon Oct 07 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "StylePreferences.h"
#import "DocumentModeManager.h"


@implementation StylePreferences

- (NSImage *)icon {
    return [NSImage imageNamed:@"StylePrefs"];
}

- (NSString *)iconLabel {
    return NSLocalizedString(@"StylePrefsIconLabel", @"Label displayed below tyle pref icon and used as window title.");
}

- (NSString *)identifier {
    return @"de.codingmonkeys.subethaedit.preferences.style";
}

- (NSString *)mainNibName {
    return @"StylePrefs";
}

- (void)mainViewDidLoad {
    // Initialize user interface elements to reflect current preference settings
    [self changeMode:O_modePopUpButton];
}

- (IBAction)validateDefaultsState:(id)aSender {
    DocumentMode *baseMode=[[DocumentModeManager sharedInstance] baseMode];
    DocumentMode *selectedMode=[O_modeController content];
}

- (IBAction)changeMode:(id)aSender {
    DocumentMode *newMode=[aSender selectedMode];
    [O_modeController setContent:newMode];
    [self validateDefaultsState:aSender];
}

- (void)didUnselect {
    // Save preferences
    [[[NSFontManager sharedFontManager] fontPanel:NO] orderOut:self];
}

- (IBAction)changeFontViaPanel:(id)sender {
//    NSDictionary *fontAttributes=[[O_modeController content] defaultForKey:DocumentModeFontAttributesPreferenceKey];
//    NSFont *newFont=[NSFont fontWithName:[fontAttributes objectForKey:NSFontNameAttribute] size:[[fontAttributes objectForKey:NSFontSizeAttribute] floatValue]];
//    if (!newFont) newFont=[NSFont userFixedPitchFontOfSize:[[fontAttributes objectForKey:NSFontSizeAttribute] floatValue]];
//    [[NSFontManager sharedFontManager] 
//        setSelectedFont:newFont 
//             isMultiple:NO];
    [[NSFontManager sharedFontManager] orderFrontFontPanel:self];
}

- (void)changeFont:(id)fontManager {
//    NSFont *newFont = [fontManager convertFont:[NSFont userFixedPitchFontOfSize:0.0]]; // could be any font here
//    NSMutableDictionary *dict=[NSMutableDictionary dictionary];
//    [dict setObject:[newFont fontName] 
//             forKey:NSFontNameAttribute];
//    [dict setObject:[NSNumber numberWithFloat:[newFont pointSize]] 
//             forKey:NSFontSizeAttribute];
//    [[O_modeController content] setValue:dict forKeyPath:@"defaults.FontAttributes"];
}


@end
