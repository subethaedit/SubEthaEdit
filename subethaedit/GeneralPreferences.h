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
#import "PreferenceKeys.h"

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
