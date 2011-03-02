//
//  StyleSheetPreferences.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Mon Oct 07 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TCMPreferenceModule.h"

@class DocumentModePopUpButton;
@class SyntaxStyle;
@class TableView;

@interface StyleSheetPreferences : TCMPreferenceModule {
    IBOutlet TableView *O_stylesTableView;

    NSFont *I_baseFont;

    IBOutlet NSButton *O_boldButton, *O_italicButton, *O_underlineButton;
    IBOutlet NSColorWell *O_colorWell, *O_invertedColorWell, 
                         *O_backgroundColorWell,*O_invertedBackgroundColorWell;

    IBOutlet NSTextField *O_fontLabel;
    
    NSUndoManager *I_undoManager;
}

- (IBAction)changeFontTraitItalic:(id)aSender;
- (IBAction)changeFontTraitBold:(id)aSender;
- (IBAction)changeFontTraitUnderline:(id)aSender;
- (IBAction)changeBackgroundColor:(id)aSender;
- (IBAction)changeForegroundColor:(id)aSender;

- (IBAction)changeFontViaPanel:(id)sender;

- (void)setBaseFont:(NSFont *)aFont;
- (NSFont *)baseFont;

@end
