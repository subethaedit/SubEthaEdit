//
//  EditPreferences.m
//  SubEthaEdit
//
//  Created by Martin Ott on Mon Mar 29 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "EditPreferences.h"
#import "DocumentModeManager.h"

@implementation EditPreferences

- (NSImage *)icon {
    return [NSImage imageNamed:@"EditPrefs"];
}

- (NSString *)iconLabel {
    return NSLocalizedStringFromTable(@"EditPrefsIconLabel", @"Preferences",Ê@"Label displayed below edit icon and used as window title.");
}

- (NSString *)identifier {
    return @"de.codingmonkeys.subethaedit.preferences.edit";
}

- (NSString *)mainNibName {
    return @"EditPrefs";
}

- (void)mainViewDidLoad {
    // Initialize user interface elements to reflect current preference settings
    [self changeMode:O_modePopUpButton];
}

- (IBAction)changeMode:(id)aSender {
    DocumentMode *newMode=[aSender selectedMode];
    [O_modeController setContent:newMode];
}


- (void)didUnselect {
    // Save preferences
    [[[NSFontManager sharedFontManager] fontPanel:NO] orderOut:self];
}

- (IBAction)changeFontViaPanel:(id)sender {
    [[NSFontManager sharedFontManager] 
        setSelectedFont:[NSFont userFixedPitchFontOfSize:0.0] 
             isMultiple:NO];
    [[NSFontManager sharedFontManager] orderFrontFontPanel:self];
}

- (void)changeFont:(id)fontManager {
    NSFont *newFont = [fontManager convertFont:[NSFont userFixedPitchFontOfSize:0.0]]; // could be any font here
    NSMutableDictionary *dict=[NSMutableDictionary dictionary];
    [dict setObject:[newFont fontName] 
             forKey:NSFontNameAttribute];
    [dict setObject:[NSNumber numberWithFloat:[newFont pointSize]] 
             forKey:NSFontSizeAttribute];
    [[O_modeController content] setValue:dict forKeyPath:@"defaults.FontAttributes"];
}


@end
