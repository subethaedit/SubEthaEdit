//  GeneralPreferences.m
//  SubEthaEdit
//
//  Created by Martin Ott on Mon Mar 29 2004.

#import "GeneralPreferences.h"

#import "DocumentModeManager.h"
#import "AppController.h"
#import "TCMMMUserManager.h"

// this file needs arc - either project wide,
// or add -fobjc-arc on a per file basis in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

@implementation GeneralPreferences

+ (void)initialize {
	if (self == [GeneralPreferences class]) {
		NSMutableDictionary *defaultDict = [NSMutableDictionary dictionary];
		
		[defaultDict setObject:[NSNumber numberWithFloat:25.0] forKey:ChangesSaturationPreferenceKey];
		[defaultDict setObject:[NSNumber numberWithFloat:45.0] forKey:SelectionSaturationPreferenceKey];
		[defaultDict setObject:[NSNumber numberWithFloat: 0.0] forKey:CustomMyColorHuePreferenceKey];
		[defaultDict setObject:[NSNumber numberWithFloat:50.0] forKey:MyColorHuePreferenceKey];
		
		[defaultDict setObject:[NSArray array] forKey:MyAIMsPreferenceKey];
		[defaultDict setObject:[NSArray array] forKey:MyEmailsPreferenceKey];
		
		[defaultDict setObject:[NSNumber numberWithBool:YES] forKey:OpenDocumentOnStartPreferenceKey]; // deprecated
		[defaultDict setObject:[NSNumber numberWithBool:YES] forKey:OpenDocumentHubOnStartupPreferenceKey];
		[defaultDict setObject:[NSNumber numberWithBool:NO] forKey:OpenUntitledDocumentOnStartupPreferenceKey];
		[defaultDict setObject:[NSNumber numberWithBool:NO] forKey:DidUpdateOpenDocumentOnStartPreferenceKey];

		[defaultDict setObject:[NSNumber numberWithInt:0]    forKey:AdditionalShownPathComponentsPreferenceKey];

		[defaultDict setObject:[NSNumber numberWithBool:YES] forKey:HighlightChangesPreferenceKey];
		[defaultDict setObject:[NSNumber numberWithBool:NO]  forKey:HighlightChangesAlonePreferenceKey];
		
		[defaultDict setObject:[NSNumber numberWithBool:YES] forKey:kSEEDefaultsKeyOpenNewDocumentInTab];
		
		[defaultDict setObject:BASEMODEIDENTIFIER forKey:ModeForNewDocumentsPreferenceKey];
		
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		[defaults registerDefaults:defaultDict];
		
		if ([defaults boolForKey:DidUpdateOpenDocumentOnStartPreferenceKey] == NO) {
			BOOL result = [[[NSUserDefaults standardUserDefaults] objectForKey:OpenDocumentOnStartPreferenceKey] boolValue];
			[defaults setBool:result forKey:OpenDocumentHubOnStartupPreferenceKey];
			[defaults setBool:YES forKey:DidUpdateOpenDocumentOnStartPreferenceKey];
		}
	}
}

#pragma mark - IBActions

- (IBAction)toggleLocalHighlightDefault:(id)aSender {
	BOOL isEnabled;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	if ([aSender isKindOfClass:[NSButton class]]) {
		NSButton *button = (NSButton *)aSender;
		isEnabled = (button.state == NSOnState);
	} else {
		isEnabled = ![defaults boolForKey:HighlightChangesAlonePreferenceKey];
	}

	if (isEnabled) { // enable changes highlight for collaboration when enabling the local changes highlight
		[defaults setBool:YES forKey:HighlightChangesPreferenceKey];
	}
	[defaults setBool:isEnabled forKey:HighlightChangesAlonePreferenceKey];

	[self setLocalChangesHighlightButtonState:isEnabled];
}

- (IBAction)changeModeForNewDocuments:(id)aSender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
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
    [self setLocalChangesHighlightButtonStateFromDefaults];

    NSString *modeIdentifier = [[NSUserDefaults standardUserDefaults] objectForKey:ModeForNewDocumentsPreferenceKey];
	[self.O_modeForNewDocumentsPopUpButton setSelectedModeIdentifier:modeIdentifier];
}

- (void)willSelect {;
    [self setLocalChangesHighlightButtonStateFromDefaults];
}

- (void)didUnselect {
    // Save preferences
}

#pragma mark - Local Changes Highlight Button Update

- (void)setLocalChangesHighlightButtonStateFromDefaults {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	BOOL localChangesHighlightEnabled = [defaults boolForKey:HighlightChangesAlonePreferenceKey];
	BOOL changesHighlightEnabled = [defaults boolForKey:HighlightChangesPreferenceKey];
	[self setLocalChangesHighlightButtonState:(changesHighlightEnabled && localChangesHighlightEnabled)];
}

- (void)setLocalChangesHighlightButtonState:(BOOL)isEnabled {
	if (isEnabled) {
		[self.O_highlightLocalChangesButton setState:NSOnState];
	} else {
		[self.O_highlightLocalChangesButton setState:NSOffState];
	}
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
