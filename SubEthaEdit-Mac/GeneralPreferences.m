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

#define COLORMENUIMAGEWIDTH 20.
#define COLORMENUIMAGEHEIGHT 10.

- (void)TCM_sendGeneralViewPreferencesDidChangeNotificiation {
    [[NSNotificationQueue defaultQueue] 
    enqueueNotification:[NSNotification notificationWithName:GeneralViewPreferencesDidChangeNotificiation object:self]
           postingStyle:NSPostWhenIdle 
           coalesceMask:NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender 
               forModes:[NSArray arrayWithObject:NSDefaultRunLoopMode]];
}

- (NSImage *)TCM_menuImageWithColor:(NSColor *)aColor {
    NSRect rect = NSMakeRect(0.0, 0.0, COLORMENUIMAGEWIDTH, COLORMENUIMAGEHEIGHT);
	NSImage *image = [NSImage imageWithSize:rect.size flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
		[aColor drawSwatchInRect:dstRect];
		[[NSColor blackColor] set];
		[NSBezierPath strokeRect:dstRect];
		return YES;
	}];
    return image;
}

- (IBAction)changeModeForNewDocuments:(id)aSender {
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    [defaults setObject:[aSender selectedModeIdentifier] forKey:ModeForNewDocumentsPreferenceKey];
    [[AppController sharedInstance] performSelector:@selector(addShortcutToModeForNewDocumentsEntry)          withObject:nil afterDelay:0.0];
    [[AppController sharedInstance] performSelector:@selector(addShortcutToModeForNewAlternateDocumentsEntry) withObject:nil afterDelay:0.0];
}

- (void)TCM_setupColorPopUp {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    NSArray *colorNames=[NSArray arrayWithObjects:@"ColorRed",@"ColorOrange",@"ColorYellow",@"ColorGreen",@"ColorTeal",@"ColorBlue",@"ColorPurple",@"ColorPink",nil];
    int colorHues[]={0,3300/360,6600/360,10900/360,18000/360,22800/360,26400/360,31700/360};
    
    [O_colorsPopUpButton removeAllItems];
    
    int i;
    for (i=0;i<(int)[colorNames count];i++) {
        // (void)NSLocalizedString(@"ColorRed", @"Red");
        // (void)NSLocalizedString(@"ColorOrange", @"Orange");
        // (void)NSLocalizedString(@"ColorYellow", @"Yellow");
        // (void)NSLocalizedString(@"ColorGreen", @"Green");
        // (void)NSLocalizedString(@"ColorTeal", @"Teal");
        // (void)NSLocalizedString(@"ColorBlue", @"Blue");
        // (void)NSLocalizedString(@"ColorPurple", @"Purple");
        // (void)NSLocalizedString(@"ColorPink", @"Pink");
        // (void)NSLocalizedString(@"ColorCustom", @"Custom Color Name");
        [O_colorsPopUpButton addItemWithTitle:NSLocalizedString([colorNames objectAtIndex:i],@"<do not localize>")];
        NSMenuItem *item=[O_colorsPopUpButton lastItem];
        [item setImage:[self TCM_menuImageWithColor:[NSColor colorWithCalibratedHue:colorHues[i]/100.
                                saturation:1. brightness:1. alpha:1.]]];
        [item setTag:colorHues[i]];
    }
    [[O_colorsPopUpButton menu] addItem:[NSMenuItem separatorItem]];
    [O_colorsPopUpButton addItemWithTitle:NSLocalizedString(@"ColorCustom",@"Custom Color Name")];

    NSValueTransformer *hueTrans=[NSValueTransformer valueTransformerForName:@"HueToColor"];
    [[O_colorsPopUpButton lastItem] 
        setImage: [self TCM_menuImageWithColor:[hueTrans transformedValue:[defaults objectForKey:CustomMyColorHuePreferenceKey]]]];
    [[O_colorsPopUpButton lastItem] setTag:-1];
    [O_colorsPopUpButton selectItemAtIndex:[defaults integerForKey:SelectedMyColorPreferenceKey]];
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
    [self TCM_setupColorPopUp];
    
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    
    [O_modeForNewDocumentsPopUpButton setSelectedModeIdentifier:
        [defaults objectForKey:ModeForNewDocumentsPreferenceKey]];
}

- (void)didUnselect {
    // Save preferences
}

#pragma mark
- (void)TCM_updateWells {
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    [defaults setObject:[defaults objectForKey:ChangesSaturationPreferenceKey] forKey:ChangesSaturationPreferenceKey];
    [defaults setObject:[defaults objectForKey:SelectionSaturationPreferenceKey] forKey:SelectionSaturationPreferenceKey];
    [self TCM_sendGeneralViewPreferencesDidChangeNotificiation];
}

- (IBAction)postGeneralViewPreferencesDidChangeNotificiation:(id)aSender {
    [self TCM_sendGeneralViewPreferencesDidChangeNotificiation];
}

- (IBAction)changeMyCustomColor:(id)aSender {
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    NSValueTransformer *hueTrans=[NSValueTransformer valueTransformerForName:@"HueToColor"];
    NSNumber *hue = (NSNumber *)[hueTrans reverseTransformedValue:[aSender color]];
    [[O_colorsPopUpButton lastItem] 
        setImage: [self TCM_menuImageWithColor:[hueTrans transformedValue:hue]]];

    [defaults setObject:hue
                 forKey:MyColorHuePreferenceKey];
    [defaults setObject:hue
                 forKey:CustomMyColorHuePreferenceKey];
    [[TCMMMUserManager me] setUserHue:hue];
    [TCMMMUserManager didChangeMe];

    [self TCM_updateWells];
}

- (IBAction)changeMyColor:(id)aSender {
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    int tag=[[O_colorsPopUpButton selectedItem] tag];
    NSValueTransformer *hueTrans=[NSValueTransformer valueTransformerForName:@"HueToColor"];
    
    [defaults setObject:[NSNumber numberWithInt:[O_colorsPopUpButton indexOfSelectedItem]]
                 forKey:SelectedMyColorPreferenceKey];

    if (tag==-1) {
        [NSColorPanel setPickerMode:NSHSBModeColorPanel];
        NSColorPanel *panel=[NSColorPanel sharedColorPanel];
        [panel setAction:@selector(changeMyCustomColor:)];
        [panel setTarget:self];
        [panel setShowsAlpha:NO];
        [panel orderFront:self];
        [panel setColor:[hueTrans transformedValue:[defaults objectForKey:CustomMyColorHuePreferenceKey]]];
        tag=(int)([[defaults objectForKey:CustomMyColorHuePreferenceKey] floatValue]);
    } else {
        [[NSColorPanel sharedColorPanel] orderOut:self];
    }

    NSNumber *value=[NSNumber numberWithFloat:(float)tag];
    [defaults setObject:value
                 forKey:MyColorHuePreferenceKey];

    [[TCMMMUserManager me] setUserHue:value];
    [TCMMMUserManager didChangeMe];

    [self TCM_updateWells];
}

@end
