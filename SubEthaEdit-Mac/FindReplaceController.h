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
#import "SEEFindAndReplaceState.h"

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
    IBOutlet NSProgressIndicator *O_progressIndicator;
    IBOutlet NSProgressIndicator *O_progressIndicatorDet;
}

+ (FindReplaceController *)sharedInstance;

@property (nonatomic, strong) NSObjectController *globalFindAndReplaceStateController;

- (NSPanel *)gotoPanel;
- (NSPanel *)tabWidthPanel;

- (NSTextView *)textViewToSearchIn;

- (IBAction)orderFrontTabWidthPanel:(id)aSender;
- (IBAction)chooseTabWidth:(id)aSender;
- (IBAction)orderFrontGotoPanel:(id)aSender;

- (IBAction)gotoLine:(id)aSender;
- (IBAction)gotoLineAndClosePanel:(id)aSender;
- (unsigned) currentOgreOptions;
- (OgreSyntax) currentOgreSyntax;
- (NSString*)currentOgreEscapeCharacter;

/*! the tag of the sender actually defines what search action is triggered - which is a weird design */
- (void)performFindPanelAction:(id)sender inTargetTextView:(NSTextView *)aTextView;
- (void)performFindPanelAction:(id)sender;

- (BOOL) find:(NSString*)findString forward:(BOOL)forward;
- (void) findNextAndOrderOut:(id)sender;
- (void)loadFindStringFromPasteboard;
- (void)saveFindStringToPasteboard;
- (void) replaceSelection;
- (void) replaceAllInRange:(NSRange)aRange;

@end


