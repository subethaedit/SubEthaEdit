//
//  GeneralPreferences.h
//  SubEthaEdit
//
//  Created by Martin Ott on Mon Mar 29 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TCMPreferenceModule.h"

extern NSString * const MyColorHuePreferenceKey            ;
extern NSString * const CustomMyColorHuePreferenceKey      ;
extern NSString * const SelectionSaturationPreferenceKey   ;
extern NSString * const ChangesSaturationPreferenceKey     ;
extern NSString * const HighlightChangesPreferenceKey      ;
extern NSString * const HighlightChangesAlonePreferenceKey ;
extern NSString * const OpenDocumentOnStartPreferenceKey   ;
extern NSString * const SelectedMyColorPreferenceKey;


@interface GeneralPreferences : TCMPreferenceModule {
    IBOutlet NSButton    *O_useAddressbookButton;
    IBOutlet NSImageView *O_pictureImageView;
    IBOutlet NSTextField *O_nameTextField;
    IBOutlet NSTextField *O_aimTextField;
    IBOutlet NSTextField *O_emailTextField;

    IBOutlet NSPopUpButton *O_colorsPopUpButton;
    
    IBOutlet NSSlider    *O_selectionSaturationSlider;
    IBOutlet NSSlider    *O_changeSaturationSlider;
    IBOutlet NSColorWell *O_selectionLightColorWell;
    IBOutlet NSColorWell *O_selectionDarkColorWell;
    IBOutlet NSColorWell *O_changesLightColorWell;
    IBOutlet NSColorWell *O_changesDarkColorWell;
    
    IBOutlet NSButton *O_higlightChangesButton;
    IBOutlet NSButton *O_alsoInLocalDocumentsButton;
    
    IBOutlet NSButton *O_openNewDocumentAtStartupButton;
    IBOutlet NSPopUpButton *O_defaultModePopUpButton;
}

- (IBAction)changeMyColor:(id)aSender;
@end
