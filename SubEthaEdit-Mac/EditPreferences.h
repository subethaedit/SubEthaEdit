//
//  EditPreferences.h
//  SubEthaEdit
//
//  Created by Martin Ott on Mon Mar 29 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TCMPreferenceModule.h"

@class DocumentModePopUpButton;
@class EncodingPopUpButton;

@interface EditPreferences : TCMPreferenceModule {
    IBOutlet NSTextField   *O_tabWidthTextField;
    IBOutlet NSButton      *O_usesTabsButton;
    IBOutlet NSButton      *O_indentNewLinesButton;
    IBOutlet NSButton      *O_wrapLinesButton;
    IBOutlet NSButton      *O_showMatchingBracketsButton;
    IBOutlet NSTextField   *O_matchingBracketTypesTextField;
    IBOutlet NSButton      *O_showLineNumbersButton;
    IBOutlet NSButton      *O_highlightSyntaxButton;
    IBOutlet EncodingPopUpButton *O_encodingPopUpButton;
    IBOutlet DocumentModePopUpButton *O_modePopUpButton;
    IBOutlet NSObjectController *O_modeController;
    IBOutlet NSObjectController *O_viewController;
    IBOutlet NSObjectController *O_editController;
    IBOutlet NSObjectController *O_fileController;
    IBOutlet NSButton *O_viewDefaultButton;
    IBOutlet NSButton *O_editDefaultButton;
    IBOutlet NSButton *O_fileDefaultButton;
}

- (IBAction)changeMode:(id)aSender;
- (IBAction)validateDefaultsState:(id)aSender;
- (IBAction)applyToOpenDocuments:(id)aSender;

@end
