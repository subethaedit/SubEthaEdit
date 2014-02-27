//
//  FindReplaceController.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Fri Apr 23 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <OgreKit/OgreKit.h>
#import "SelectionOperation.h"

typedef enum {
    TCMTextFinderActionFindAll = 1001,
    TCMTextFinderActionSetReplaceString = 1002,
} TCMFindPanelAction;

@interface NSString (NSStringTextFinding)
- (NSRange)findString:(NSString *)string selectedRange:(NSRange)selectedRange options:(unsigned)options wrap:(BOOL)wrap;
@end

@interface NSWindow (AppleInternalKeyViewLoopRedirection)
- (void)_setKeyViewRedirectionDisabled:(BOOL)aBool;
@end

@interface FindReplaceController : NSObject <NSWindowDelegate> {

	// tab width panel (whyever this is managed by us)
	IBOutlet NSPanel *O_tabWidthPanel;
    IBOutlet NSTextField *O_tabWidthTextField;

	// goto line panel
	IBOutlet NSPanel *O_gotoPanel;
    IBOutlet NSTextField *O_gotoLineTextField;

	// old find panel
	IBOutlet NSPanel *O_findPanel;
    IBOutlet NSComboBox *O_findComboBox;
    IBOutlet NSComboBox *O_replaceComboBox;
    IBOutlet NSButton *O_ignoreCaseCheckbox;
    IBOutlet NSProgressIndicator *O_progressIndicator;
    IBOutlet NSProgressIndicator *O_progressIndicatorDet;

	IBOutlet NSTextField *O_statusTextField;
    IBOutlet NSButton *O_wrapAroundCheckbox;
	
    IBOutlet NSButton *O_FindAllButton;
    IBOutlet NSButton *O_NextButton;
    IBOutlet NSButton *O_PrevButton;
    IBOutlet NSButton *O_ReplaceButton;
    IBOutlet NSButton *O_ReplaceAllButton;
    IBOutlet NSButton *O_ReplaceFindButton;

	// old find panel regex options section
    IBOutlet NSDrawer *O_regexDrawer;
    IBOutlet NSButton *O_regexCheckbox;
    IBOutlet NSButton *O_regexCaptureGroupsCheckbox;
    IBOutlet NSButton *O_regexDontCaptureCheckbox;
    IBOutlet NSPopUpButton *O_regexEscapeCharacter;
    IBOutlet NSButton *O_regexExtendedCheckbox;
    IBOutlet NSButton *O_regexFindLongestCheckbox;
    IBOutlet NSButton *O_regexIgnoreEmptyCheckbox;
    IBOutlet NSButton *O_regexMultilineCheckbox;
    IBOutlet NSButton *O_regexNegateSinglelineCheckbox;
    IBOutlet NSView *O_regexOptionsView;
    IBOutlet NSButton *O_regexSinglelineCheckbox;
    IBOutlet NSPopUpButton *O_regexSyntaxPopup;
    IBOutlet NSPopUpButton *O_scopePopup;

}

+ (FindReplaceController *)sharedInstance;

- (NSPanel *)findPanel;
- (NSPanel *)gotoPanel;
- (NSPanel *)tabWidthPanel;
- (NSPopUpButton *)scopePopup;

- (NSTextView *)textViewToSearchIn;

- (IBAction)orderFrontTabWidthPanel:(id)aSender;
- (IBAction)chooseTabWidth:(id)aSender;
- (IBAction)orderFrontGotoPanel:(id)aSender;
- (IBAction)orderFrontFindPanel:(id)aSender;
- (IBAction)gotoLine:(id)aSender;
- (IBAction)gotoLineAndClosePanel:(id)aSender;
- (unsigned) currentOgreOptions;
- (OgreSyntax) currentOgreSyntax;
- (NSString*)currentOgreEscapeCharacter;
- (void)performFindPanelAction:(id)sender inTargetTextView:(NSTextView *)aTextView;
- (void)performFindPanelAction:(id)sender;
- (IBAction)updateRegexDrawer:(id)aSender;
- (BOOL) find:(NSString*)findString forward:(BOOL)forward;
- (void) findNextAndOrderOut:(id)sender;
- (void)loadFindStringFromPasteboard;
- (void)saveFindStringToPasteboard;
- (void) addString:(NSString*)aString toHistory:(NSMutableArray *)anArray;
- (void) replaceSelection;
- (void) replaceAllInRange:(NSRange)aRange;
- (void)loadStateFromPreferences;

@end


