//
//  FindReplaceController.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Fri Apr 23 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class OgreAFPCComboBox;

@interface FindReplaceController : NSObject {
    IBOutlet NSPanel *O_findPanel;
    IBOutlet NSPanel *O_gotoPanel;
    IBOutlet NSTextField *O_gotoLineTextField;
    IBOutlet OgreAFPCComboBox *O_findComboBox;
    IBOutlet OgreAFPCComboBox *O_replaceComboBox;
    IBOutlet NSButton *O_ignoreCaseCheckbox;
    IBOutlet NSProgressIndicator *O_progressIndicator;
    IBOutlet NSDrawer *O_regexDrawer;
    IBOutlet NSButton *O_regexCheckbox;
    IBOutlet NSButton *O_regexCaptureGroupsCheckbox;
    IBOutlet NSButton *O_regexDontCaptureCheckbox;
    IBOutlet NSButton *O_regexEscapeCharacter;
    IBOutlet NSButton *O_regexExtendedCheckbox;
    IBOutlet NSButton *O_regexFindLongestCheckbox;
    IBOutlet NSButton *O_regexIgnoreEmptyCheckbox;
    IBOutlet NSButton *O_regexMultilineCheckbox;
    IBOutlet NSButton *O_regexNegateSinglelineCheckbox;
    IBOutlet NSView *O_regexOptionsView;
    IBOutlet NSButton *O_regexSinglelineCheckbox;
    IBOutlet NSPopUpButton *O_regexSyntaxPopup;
    IBOutlet NSPopUpButton *O_scopePopup;
    IBOutlet NSTextField *O_statusTextField;
    IBOutlet NSButton *O_wrapAroundCheckbox;
}

+ (FindReplaceController *)sharedInstance;

- (NSPanel *)findPanel;
- (NSPanel *)gotoPanel;

- (NSTextView *)textViewToSearchIn;

- (IBAction)orderFrontGotoPanel:(id)aSender;
- (IBAction)orderFrontFindPanel:(id)aSender;
- (IBAction)gotoLine:(id)aSender;
- (IBAction)gotoLineAndClosePanel:(id)aSender;

- (IBAction)updateRegexDrawer:(id)aSender;


@end
