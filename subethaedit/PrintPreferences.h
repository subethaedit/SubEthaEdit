//
//  PrintPreferences.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 29.09.04.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "TCMPreferenceModule.h"

@class DocumentModePopUpButton;
@class DocumentMode;

@interface PrintPreferences : TCMPreferenceModule {
    IBOutlet NSView *O_placeholderView;
    IBOutlet DocumentModePopUpButton *O_modePopUpButton;
    IBOutlet NSButton *O_defaultButton;

    // PrintOptions nib
    IBOutlet NSView *O_printOptionView;
    IBOutlet NSObjectController *O_printOptionController;
    
    DocumentMode *I_currentMode;
    NSMutableDictionary  *I_printDictionary;
}

+ (NSArray *)relevantPrintOptionKeys;

- (IBAction)changeMode:(id)aSender;
- (IBAction)changeFontViaPanel:(id)aSender;
- (IBAction)changeUseDefault:(id)aSender;


@end
