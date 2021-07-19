//  FindReplaceController.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Fri Apr 23 2004.

#import <Cocoa/Cocoa.h>
#import <OgreKit/OgreKit.h>
@class FindReplaceController;
#import "SEETextView.h"
#import "SelectionOperation.h"
#import "SEEFindAndReplaceState.h"

extern NSString * const kSEEFindAndReplaceDiscardHistoryKey ;

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


- (NSPanel *)tabWidthPanel;
- (IBAction)orderFrontTabWidthPanel:(id)aSender;
- (IBAction)chooseTabWidth:(id)aSender;

- (NSPanel *)gotoPanel;
- (IBAction)orderFrontGotoPanel:(id)aSender;
- (IBAction)gotoLine:(id)aSender;
- (IBAction)gotoLineAndClosePanel:(id)aSender;

/*! the tag of the sender actually defines what search action is triggered - which is a weird design */
- (void)performFindPanelAction:(id)sender inTargetTextView:(NSTextView *)aTextView;
- (void)performFindPanelAction:(id)sender;
- (void)performTextFinderAction:(NSInteger)aTextFinderActionType textView:(SEETextView *)aTextView;

- (void)loadFindStringFromPasteboard;
- (void)saveFindStringToPasteboard;

/*! array of most recent SEEFindAndReplaceState */
@property (nonatomic, readonly, strong) NSArray *findReplaceHistory;
- (void)clearFindReplaceHistory;
- (void)storeFindeReplaceStateInHistory:(SEEFindAndReplaceState *)aFindReplaceState;
- (void)takeGlobalFindAndReplaceStateValuesFromState:(SEEFindAndReplaceState *)aFindAndReplaceState;

- (void)signalErrorWithDescription:(NSString *)aDescription;

@property (nonatomic, copy) NSString *statusString;

@end


