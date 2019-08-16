//  SEEOpenPanelAccessoryViewController.m
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 16.01.14.

#import "SEEOpenPanelAccessoryViewController.h"
#import "EncodingManager.h"
#import "DocumentModeManager.h"

@implementation SEEOpenPanelAccessoryViewController

+ (instancetype)openPanelAccessoryControllerForOpenPanel:(NSOpenPanel *)inOpenPanel {
	return [[[self class] alloc] initWithOpenPanel:inOpenPanel];
}

- (instancetype)initWithOpenPanel:(NSOpenPanel *)openPanel {
	self = [self initWithNibName:@"OpenPanelAccessory" bundle:[NSBundle mainBundle]];
	if (self) {
		if (openPanel == nil) {
			return nil;
		}

		[openPanel setAccessoryView:self.view]; // loads the view!

		[self.modePopUpButtonOutlet setHasAutomaticMode:YES];
		[self.modePopUpButtonOutlet setSelectedModeIdentifier:AUTOMATICMODEIDENTIFIER];
		[self.encodingPopUpButtonOutlet setEncoding:ModeStringEncoding defaultEntry:YES modeEntry:YES lossyEncodings:nil];

		BOOL goesIntoBundles = [[NSUserDefaults standardUserDefaults] boolForKey:@"GoIntoBundlesPrefKey"];
		[openPanel setTreatsFilePackagesAsDirectories:goesIntoBundles];
		[openPanel setCanChooseDirectories:YES];
		[self.goIntoBundlesCheckboxOutlet setState:goesIntoBundles ? NSOnState : NSOffState];

		BOOL showsHiddenFiles = [[NSUserDefaults standardUserDefaults] boolForKey:@"ShowsHiddenFiles"];
		[openPanel setShowsHiddenFiles:showsHiddenFiles];
		[self.showHiddenFilesCheckboxOutlet setState:showsHiddenFiles ? NSOnState : NSOffState];

		[openPanel TCM_setAssociatedValue:self forKey:@"OpenPanelAccessoryViewController"];
		self.openPanel = openPanel;
	}
	return self;
}

- (IBAction)goIntoBundles:(id)sender {
    BOOL flag = ([(NSButton*)sender state] == NSOffState) ? NO : YES;
    [self.openPanel setTreatsFilePackagesAsDirectories:flag];
    [[NSUserDefaults standardUserDefaults] setBool:flag forKey:@"GoIntoBundlesPrefKey"];
}

- (IBAction)showHiddenFiles:(id)sender {
    BOOL flag = ([(NSButton*)sender state] == NSOffState) ? NO : YES;
	[self.openPanel setShowsHiddenFiles:flag];
    [[NSUserDefaults standardUserDefaults] setBool:flag forKey:@"ShowsHiddenFiles"];
}

@end
