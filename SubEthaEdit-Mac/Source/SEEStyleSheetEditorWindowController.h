//  StyleSheetPreferences.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Mon Oct 07 2004.

#import <Foundation/Foundation.h>
#import "TCMPreferenceModule.h"
#import "SEEStyleSheet.h"

@class DocumentModePopUpButton;
@class SyntaxStyle;
@class TableView;

@interface SEEStyleSheetEditorWindowController : NSWindowController <NSComboBoxDataSource, NSComboBoxDelegate, NSTextFieldDelegate>

@property (nonatomic, copy) id copiedStyle;
@property (nonatomic, strong) NSFont *baseFont;

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

- (IBAction)saveStyleSheet:(id)aSender;
- (IBAction)duplicateStyleSheet:(id)aSender;
- (IBAction)revealStyleSheetInFinder:(id)aSender;
- (IBAction)revertStyleSheet:(id)aSender;

- (IBAction)removeScope:(id)aSender;
- (IBAction)addScope:(id)aSender;

- (IBAction)toggleMatchingScopes:(id)aSender;

@end
