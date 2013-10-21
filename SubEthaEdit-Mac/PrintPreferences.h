//
//  PrintPreferences.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 29.09.04.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "TCMPreferenceModule.h"

extern NSString * PrintPreferencesDidChangeNotification;

@class DocumentModePopUpButton;
@class DocumentMode;
@class FontForwardingTextField;

@interface PrintPreferences : TCMPreferenceModule {
    IBOutlet NSView *O_placeholderView;
    IBOutlet DocumentModePopUpButton *O_modePopUpButton;
    IBOutlet NSButton *O_defaultButton;

    // PrintOptions nib

    DocumentMode *I_currentMode;
    NSMutableDictionary  *I_printDictionary;
    NSMutableDictionary  *I_defaultModeDictionary;
}

@property (readwrite, strong) IBOutlet NSView *O_printOptionView;
@property (readwrite, assign) IBOutlet FontForwardingTextField *O_printOptionTextField;
@property (readwrite, strong) IBOutlet NSObjectController *O_printOptionController;

+ (NSArray *)relevantPrintOptionKeys;

- (IBAction)changeMode:(id)aSender;
- (IBAction)changeFontViaPanel:(id)aSender;
- (IBAction)changeUseDefault:(id)aSender;


@end
