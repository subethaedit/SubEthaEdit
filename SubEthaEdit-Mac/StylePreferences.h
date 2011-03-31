//
//  EditPreferences.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Mon Oct 07 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TCMPreferenceModule.h"

@class DocumentModePopUpButton;

@interface StylePreferences : TCMPreferenceModule {
    IBOutlet DocumentModePopUpButton *O_modePopUpButton;
    IBOutlet NSObjectController *O_modeController;
    IBOutlet NSObjectController *O_fontController;

    IBOutlet NSButton *O_fontDefaultButton;

    IBOutlet NSButton *O_styleSheetDefaultRadioButton;
    IBOutlet NSButton *O_styleSheetCustomRadioButton;
    IBOutlet NSButton *O_styleSheetCustomForLanguageContextsRadioButton;
    IBOutlet NSPopUpButton *O_styleSheetCustomPopUpButton;
    IBOutlet NSView *O_customStyleSheetsContainerView;
    
    IBOutlet NSBox *O_styleContainerBox;
    IBOutlet NSBox *O_previewContainerBox;
    
    IBOutlet NSTableView *O_customStylesForLanguageContextsTableView;

    NSFont *I_baseFont;

    NSUndoManager *I_undoManager;
    IBOutlet NSTextView *O_syntaxSampleTextView;
}

- (IBAction)changeMode:(id)aSender;

- (IBAction)validateDefaultsState:(id)aSender;
- (IBAction)changeDefaultState:(id)aSender;

- (IBAction)styleRadioButtonAction:(id)aSender;

- (IBAction)changeCustomStyleSheet:(id)aSender;
- (IBAction)changeFontViaPanel:(id)sender;

- (IBAction)applyToOpenDocuments:(id)aSender;

- (void)setBaseFont:(NSFont *)aFont;
- (NSFont *)baseFont;


@end
