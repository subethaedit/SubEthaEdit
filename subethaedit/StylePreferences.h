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
@class SyntaxStyle;
@class TableView;

@interface StylePreferences : TCMPreferenceModule {
    IBOutlet DocumentModePopUpButton *O_modePopUpButton;
    IBOutlet NSObjectController *O_modeController;
    IBOutlet TableView *O_stylesTableView;
    NSMutableDictionary *I_baseStyleDictionary;
    NSFont *I_baseFont;
    SyntaxStyle *I_currentSyntaxStyle;
    IBOutlet NSButton *O_lightBackgroundButton,*O_darkBackgroundButton;
    IBOutlet NSButton *O_boldButton,*O_italicButton;
    IBOutlet NSColorWell *O_colorWell, *O_invertedColorWell, 
                         *O_backgroundColorWell,*O_invertedBackgroundColorWell;
    IBOutlet NSButton *O_defaultStyleButton;
}

- (IBAction)changeFontTraitItalic:(id)aSender;
- (IBAction)changeFontTraitBold:(id)aSender;
- (IBAction)changeLightBackgroundColor:(id)aSender;
- (IBAction)changeDarkBackgroundColor:(id)aSender;
- (IBAction)changeLightForegroundColor:(id)aSender;
- (IBAction)changeDarkForegroundColor:(id)aSender;
- (IBAction)changeMode:(id)aSender;
- (IBAction)validateDefaultsState:(id)aSender;
- (IBAction)changeDefaultState:(id)aSender;
- (IBAction)export:(id)aSender;

- (void)setBaseFont:(NSFont *)aFont;
- (NSFont *)baseFont;


@end
