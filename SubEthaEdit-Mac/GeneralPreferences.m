//
//  GeneralPreferences.m
//  SubEthaEdit
//
//  Created by Martin Ott on Mon Mar 29 2004.
//  Copyright (c) 2004-2006 TheCodingMonkeys. All rights reserved.
//

#import "GeneralPreferences.h"

#import "DocumentModeManager.h"
#import "AppController.h"
#import "TCMMMUserManager.h"

@implementation GeneralPreferences

+ (void)initialize {
	if (self == [GeneralPreferences class]) {
		NSMutableDictionary *defaultDict = [NSMutableDictionary dictionary];
		
		[defaultDict setObject:[NSNumber numberWithFloat:25.0]
						forKey:ChangesSaturationPreferenceKey];
		[defaultDict setObject:[NSNumber numberWithFloat:45.0]
						forKey:SelectionSaturationPreferenceKey];
		[defaultDict setObject:[NSNumber numberWithFloat:0.0]
						forKey:CustomMyColorHuePreferenceKey];
		[defaultDict setObject:[NSNumber numberWithFloat:50.0]
						forKey:MyColorHuePreferenceKey];
		[defaultDict setObject:[NSArray array]
						forKey:MyAIMsPreferenceKey];
		[defaultDict setObject:[NSArray array]
						forKey:MyEmailsPreferenceKey];
		[defaultDict setObject:[NSNumber numberWithBool:YES]
						forKey:OpenDocumentOnStartPreferenceKey];
		[defaultDict setObject:[NSNumber numberWithInt:0]
						forKey:AdditionalShownPathComponentsPreferenceKey];
		[defaultDict setObject:[NSNumber numberWithBool:YES]
						forKey:HighlightChangesPreferenceKey];
		[defaultDict setObject:[NSNumber numberWithBool:NO]
						forKey:HighlightChangesAlonePreferenceKey];
		[defaultDict setObject:[NSNumber numberWithBool:YES]
						forKey:OpenNewDocumentInTabKey];
		[defaultDict setObject:[NSNumber numberWithBool:YES]
						forKey:AlwaysShowTabBarKey];
		[defaultDict setObject:BASEMODEIDENTIFIER
						forKey:ModeForNewDocumentsPreferenceKey];
		
		[[NSUserDefaults standardUserDefaults] registerDefaults:defaultDict];
	}    
}

- (IBAction)changeModeForNewDocuments:(id)aSender {
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    [defaults setObject:[aSender selectedModeIdentifier] forKey:ModeForNewDocumentsPreferenceKey];
    [[AppController sharedInstance] performSelector:@selector(addShortcutToModeForNewDocumentsEntry)          withObject:nil afterDelay:0.0];
    [[AppController sharedInstance] performSelector:@selector(addShortcutToModeForNewAlternateDocumentsEntry) withObject:nil afterDelay:0.0];
}

#pragma mark - Preference Module - Basics
- (NSImage *)icon {
    return [NSImage imageNamed:NSImageNamePreferencesGeneral];
}

- (NSString *)iconLabel {
    return NSLocalizedString(@"GeneralPrefsIconLabel",@"Label displayed below general icon and used as window title.");
}

- (NSString *)identifier {
    return @"de.codingmonkeys.subethaedit.preferences.general";
}

- (NSString *)mainNibName {
    return @"GeneralPrefs";
}

- (void)mainViewDidLoad {
    // Initialize user interface elements to reflect current preference settings
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    
    [O_modeForNewDocumentsPopUpButton setSelectedModeIdentifier:
        [defaults objectForKey:ModeForNewDocumentsPreferenceKey]];
}

- (void)didUnselect {
    // Save preferences
}

#pragma mark - View Update Notification

- (IBAction)postGeneralViewPreferencesDidChangeNotificiation:(id)aSender {
    [self TCM_sendGeneralViewPreferencesDidChangeNotificiation];
}

- (void)TCM_sendGeneralViewPreferencesDidChangeNotificiation {
    [[NSNotificationQueue defaultQueue]
	 enqueueNotification:[NSNotification notificationWithName:GeneralViewPreferencesDidChangeNotificiation object:self]
	 postingStyle:NSPostWhenIdle
	 coalesceMask:NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender
	 forModes:[NSArray arrayWithObject:NSDefaultRunLoopMode]];
}

@end
