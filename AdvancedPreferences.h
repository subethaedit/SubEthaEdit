//
//  AdvancedPreferences.h
//  SubEthaEdit
//
//  Created by Martin Ott on Tue Sep 07 2004.
//  Copyright 2004 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TCMPreferenceModule.h"

@interface AdvancedPreferences : TCMPreferenceModule {
    IBOutlet NSButton *O_commandLineToolRemoveButton;
    IBOutlet NSButton *O_disableScreenFontsButton;
    IBOutlet NSButton *O_synthesiseFontsButton;
}

- (IBAction)commandLineToolInstall:(id)sender;
- (IBAction)commandLineToolRemove:(id)sender;
- (IBAction)changeDisableScreenFonts:(id)aSender;
- (IBAction)changeSynthesiseFonts:(id)aSender;

@end
