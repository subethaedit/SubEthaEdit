//
//  StyleSheetPreferences.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Mon Oct 07 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TCMPreferenceModule.h"
#import "SEEStyleSheet.h"

@class DocumentModePopUpButton;
@class SyntaxStyle;
@class TableView;

@interface StyleSheetPreferences : TCMPreferenceModule {
    IBOutlet TableView *O_stylesTableView;

    NSFont *I_baseFont;

    IBOutlet NSButton *O_boldButton, *O_italicButton, *O_underlineButton, *O_strikethroughButton;
    IBOutlet NSColorWell *O_colorWell, 
                         *O_backgroundColorWell;

    IBOutlet NSButton *O_inheritBoldButton, *O_inheritItalicButton, *O_inheritUnderlineButton, *O_inheritStrikethroughButton, *O_inheritColorWell, *O_inheritBackgroundColorWell;

    IBOutlet NSPopUpButton *O_styleSheetPopUpButton;


    IBOutlet NSTextView *O_sheetSnippetTextView;
    
    IBOutlet NSTextField *O_fontLabel;
    SEEStyleSheet *I_currentStyleSheet;
    NSUndoManager *I_undoManager;
}

- (IBAction)changeStyleSheet:(id)aSender;

- (IBAction)changeFontTraitItalic:(id)aSender;
- (IBAction)changeFontTraitBold:(id)aSender;
- (IBAction)changeFontTraitUnderline:(id)aSender;
- (IBAction)changeFontTraitStrikethrough:(id)aSender;
- (IBAction)changeBackgroundColor:(id)aSender;
- (IBAction)changeForegroundColor:(id)aSender;

- (IBAction)takeInheritanceState:(id)aSender;

- (IBAction)changeFontViaPanel:(id)sender;

- (void)setBaseFont:(NSFont *)aFont;
- (NSFont *)baseFont;

@end
