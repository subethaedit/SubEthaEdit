//
//  GeneralPreferences.m
//  SubEthaEdit
//
//  Created by Martin Ott on Mon Mar 29 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "GeneralPreferences.h"
#import "TCMMMUserManager.h"
#import "TCMMMUser.h"


NSString * const MyColorHuePreferenceKey             = @"MyColorHue";
NSString * const CustomMyColorHuePreferenceKey       = @"CustomMyColorHue";
NSString * const SelectionSaturationPreferenceKey    = @"SelectionSaturation";
NSString * const ChangesSaturationPreferenceKey      = @"ChangesSaturation";
NSString * const HighlightChangesPreferenceKey       = @"HighlightChanges";
NSString * const HighlightChangesAlonePreferenceKey  = @"HighlightChangesAlone";
NSString * const OpenDocumentOnStartPreferenceKey    = @"OpenDocumentOnStart";
NSString * const SelectedMyColorPreferenceKey        = @"SelectedMyColor";

@implementation GeneralPreferences

+ (void)initialize {
    NSMutableDictionary *defaultDict = [NSMutableDictionary dictionary];
    
    [defaultDict setObject:[NSNumber numberWithFloat:0.0]
                    forKey:CustomMyColorHuePreferenceKey];
    [defaultDict setObject:[NSNumber numberWithFloat:50.0]
                    forKey:MyColorHuePreferenceKey];
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultDict];
    
}

#define COLORMENUIMAGEWIDTH 20.
#define COLORMENUIMAGEHEIGHT 10.

- (NSImage *)TCM_menuImageWithColor:(NSColor *)aColor {
    NSRect rect=NSMakeRect(0,0,COLORMENUIMAGEWIDTH,COLORMENUIMAGEHEIGHT);
    NSImage *image=[[NSImage alloc] initWithSize:rect.size];
    [image lockFocus];
    [aColor drawSwatchInRect:rect];
//    [aColor set];
//    NSRectFill(rect);
    [[NSColor blackColor] set];
    [NSBezierPath strokeRect:rect];
    [image unlockFocus];
    
    return [image autorelease];
}


- (void)TCM_setupColorPopUp {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    NSArray *colorNames=[NSArray arrayWithObjects:@"ColorRed",@"ColorOrange",@"ColorYellow",@"ColorGreen",@"ColorTeal",@"ColorBlue",@"ColorPurple",@"ColorPink",nil];
    int colorHues[]={0,3300/360,6600/360,10900/360,18000/360,22800/360,26400/360,31700/360};
    
    [O_colorsPopUpButton removeAllItems];
    
    int i;
    for (i=0;i<(int)[colorNames count];i++) {
        [O_colorsPopUpButton addItemWithTitle:NSLocalizedStringFromTable([colorNames objectAtIndex:i],@"Preferences",@"Color Names")];
        NSMenuItem *item=[O_colorsPopUpButton lastItem];
        [item setImage:[self TCM_menuImageWithColor:[NSColor colorWithCalibratedHue:colorHues[i]/100.
                                saturation:1. brightness:1. alpha:1.]]];
        [item setTag:colorHues[i]];
    }
    [[O_colorsPopUpButton menu] addItem:[NSMenuItem separatorItem]];
    [O_colorsPopUpButton addItemWithTitle:NSLocalizedStringFromTable(@"ColorCustom",@"Preferences",@"Custom Color Name")];
    [[O_colorsPopUpButton lastItem] setImage:[self TCM_menuImageWithColor:[NSColor colorWithCalibratedHue:
                            [[defaults objectForKey:CustomMyColorHuePreferenceKey] floatValue]
                                saturation:1. brightness:1. alpha:1.]]]; 
    [[O_colorsPopUpButton lastItem] setTag:-1];
    [O_colorsPopUpButton selectItemAtIndex:[defaults integerForKey:SelectedMyColorPreferenceKey]];
}


- (NSImage *)icon {
    return [NSImage imageNamed:@"GeneralPrefs"];
}

- (NSString *)iconLabel {
    return NSLocalizedStringFromTable(@"GeneralPrefsIconLabel", @"Preferences",Ê@"Label displayed below general icon and used as window title.");
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
    
    TCMMMUser *me=[TCMMMUserManager me];
    [O_pictureImageView setImage:[[me properties] objectForKey:@"Image"]];
    [O_nameTextField setStringValue:[me name]];
}

- (void)didUnselect {
    // Save preferences
}

- (void)TCM_updateWells {
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    [defaults setObject:[defaults objectForKey:ChangesSaturationPreferenceKey] forKey:ChangesSaturationPreferenceKey];
    [defaults setObject:[defaults objectForKey:SelectionSaturationPreferenceKey] forKey:SelectionSaturationPreferenceKey];
}

- (IBAction)changeMyCustomColor:(id)aSender {
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    NSValueTransformer *hueTrans=[NSValueTransformer valueTransformerForName:@"HueToColor"];
    NSNumber *hue = (NSNumber *)[hueTrans reverseTransformedValue:[aSender color]];
    [[O_colorsPopUpButton lastItem] 
        setImage: [self TCM_menuImageWithColor:[hueTrans transformedValue:[aSender color]]]];

    [defaults setObject:hue
                 forKey:MyColorHuePreferenceKey];
    [defaults setObject:hue
                 forKey:CustomMyColorHuePreferenceKey];

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
        tag=(int)([[defaults objectForKey:CustomMyColorHuePreferenceKey] floatValue]*100);
    } else {
        [[NSColorPanel sharedColorPanel] orderOut:self];
    }

    NSNumber *value=[NSNumber numberWithFloat:(float)tag];
    [defaults setObject:value
                 forKey:MyColorHuePreferenceKey];
    [self TCM_updateWells];
}


@end
