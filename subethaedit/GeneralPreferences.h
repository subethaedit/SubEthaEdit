//
//  GeneralPreferences.h
//  SubEthaEdit
//
//  Created by Martin Ott on Mon Mar 29 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TCMPreferenceModule.h"


@interface GeneralPreferences : TCMPreferenceModule {
    IBOutlet NSImageView *O_pictureImageView;
    IBOutlet NSTextField *O_nameTextField;
    IBOutlet NSTextField *O_aimTextField;
    IBOutlet NSTextField *O_emailTextField;
    IBOutlet NSButton    *O_useAddressbookButton;
    IBOutlet NSColorWell *O_myColorColorWell;
    IBOutlet NSPopUpButton *O_presetColorsPopUpButton;
    IBOutlet NSSlider    *O_selectionSaturationSlider;
    IBOutlet NSSlider    *O_changeSaturationSlider;
}

@end
