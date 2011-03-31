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

@interface StyleSheetPreferences : TCMPreferenceModule <NSComboBoxDataSource, NSComboBoxDelegate, NSTextFieldDelegate>{
    IBOutlet TableView *O_stylesTableView;
    IBOutlet DocumentModePopUpButton *O_modePopUpButton;
    IBOutlet NSObjectController *O_modeController;

    NSFont *I_baseFont;

    IBOutlet NSButton *O_boldButton, *O_italicButton, *O_underlineButton, *O_strikethroughButton;
    IBOutlet NSColorWell *O_colorWell, 
                         *O_backgroundColorWell;

    IBOutlet NSButton *O_inheritBoldButton, *O_inheritItalicButton, *O_inheritUnderlineButton, *O_inheritStrikethroughButton, *O_inheritColorWell, *O_inheritBackgroundColorWell;

    IBOutlet NSPopUpButton *O_styleSheetPopUpButton;


    IBOutlet NSTextView *O_sheetSnippetTextView;
    
    IBOutlet NSButton *O_saveStyleSheetButton;
    IBOutlet NSButton *O_revertStyleSheetButton;
    IBOutlet NSButton *O_revealInFinderButton;
    
    IBOutlet NSButton *O_duplicateStyleSheetButton;
    
    IBOutlet NSButton *O_addScopeButton;
    IBOutlet NSButton *O_removeScopeButton;
    
    IBOutlet NSComboBox *O_scopeComboBox;
    
    IBOutlet NSTextField *O_fontLabel;
    SEEStyleSheet *I_currentStyleSheet;
    NSUndoManager *I_undoManager;
    
    id copiedStyle;
}

@property (nonatomic, copy) id copiedStyle;

- (IBAction)changeStyleSheet:(id)aSender;

- (IBAction)changeMode:(id)aSender;

- (IBAction)applyToOpenDocuments:(id)aSender;


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

- (IBAction)saveStyleSheet:(id)aSender;
- (IBAction)revealStyleSheetInFinder:(id)aSender;
- (IBAction)revertStyleSheet:(id)aSender;

- (IBAction)removeScope:(id)aSender;
- (IBAction)addScope:(id)aSender;

@end
