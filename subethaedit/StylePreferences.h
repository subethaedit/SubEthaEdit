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
    IBOutlet TableView *O_baseStyleTableView;
    IBOutlet TableView *O_remainingStylesTableView;
    NSMutableDictionary *I_baseStyleDictionary;
    NSFont *I_baseFont;
    SyntaxStyle *I_currentSyntaxStyle;
}

- (IBAction)changeMode:(id)aSender;
- (IBAction)validateDefaultsState:(id)aSender;

- (void)setBaseFont:(NSFont *)aFont;
- (NSFont *)baseFont;


@end
