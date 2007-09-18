//
//  GeneralPreferences.h
//  SubEthaEdit
//
//  Created by Martin Ott on Mon Mar 29 2004.
//  Copyright (c) 2004-2006 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TCMPreferenceModule.h"
#import "PCRolloverImageView.h"

extern NSString * const GeneralViewPreferencesDidChangeNotificiation;


extern NSString * const MyColorHuePreferenceKey;
extern NSString * const CustomMyColorHuePreferenceKey;
extern NSString * const SelectionSaturationPreferenceKey;
extern NSString * const ChangesSaturationPreferenceKey;
extern NSString * const HighlightChangesPreferenceKey;
extern NSString * const HighlightChangesAlonePreferenceKey;
extern NSString * const OpenDocumentOnStartPreferenceKey;
extern NSString * const SelectedMyColorPreferenceKey;
extern NSString * const ModeForNewDocumentsPreferenceKey;
extern NSString * const AdditionalShownPathComponentsPreferenceKey;
extern NSString * const MyNamePreferenceKey;
extern NSString * const MyAIMPreferenceKey ;
extern NSString * const MyEmailPreferenceKey;
extern NSString * const MyImagePreferenceKey;
extern NSString * const MyAIMIdentifierPreferenceKey;
extern NSString * const MyEmailIdentifierPreferenceKey;
extern NSString * const MyNamesPreferenceKey;
extern NSString * const MyAIMsPreferenceKey;
extern NSString * const MyEmailsPreferenceKey;
extern NSString * const SynthesiseFontsPreferenceKey;
extern NSString * const OpenNewDocumentInTabKey;
extern NSString * const AlwaysShowTabBarKey;

@class DocumentModePopUpButton;

@interface GeneralPreferences : TCMPreferenceModule {
    IBOutlet NSButton    *O_useAddressbookButton;
    IBOutlet PCRolloverImageView *O_pictureImageView;
    IBOutlet NSTextField *O_nameTextField;
    IBOutlet NSComboBox  *O_aimComboBox;
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
    
    IBOutlet DocumentModePopUpButton *O_modeForNewDocumentsPopUpButton;
}

- (IBAction)useAddressBookImage:(id)aSender;
- (IBAction)chooseImage:(id)aSender;
- (IBAction)clearImage:(id)aSender;
- (IBAction)takeImageFromImageView:(id)aSender;

- (IBAction)postGeneralViewPreferencesDidChangeNotificiation:(id)aSender;
- (IBAction)changeName:(id)aSender;
- (IBAction)changeAIM:(id)aSender;
- (IBAction)changeEmail:(id)aSender;
- (IBAction)changeMyColor:(id)aSender;
- (IBAction)changeModeForNewDocuments:(id)aSender;
@end
