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
extern NSString * const SelectedMyColorPreferenceKey       ;
extern NSString * const MyNamePreferenceKey ;
extern NSString * const MyAIMPreferenceKey  ;
extern NSString * const MyEmailPreferenceKey;
extern NSString * const MyAIMIdentifierPreferenceKey  ;
extern NSString * const MyEmailIdentifierPreferenceKey;
extern NSString * const MyNamesPreferenceKey ;
extern NSString * const MyAIMsPreferenceKey  ;
extern NSString * const MyEmailsPreferenceKey;


@interface GeneralPreferences : TCMPreferenceModule {
    IBOutlet NSButton    *O_useAddressbookButton;
    IBOutlet NSImageView *O_pictureImageView;
    IBOutlet NSTextField * O_nameTextField;
    IBOutlet NSComboBox  *  O_aimComboBox;
    IBOutlet NSComboBox  *O_emailComboBox;

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

- (IBAction)changeName:(id)aSender;
- (IBAction)changeAIM:(id)aSender;
- (IBAction)changeEmail:(id)aSender;
- (IBAction)changeMyColor:(id)aSender;
@end
