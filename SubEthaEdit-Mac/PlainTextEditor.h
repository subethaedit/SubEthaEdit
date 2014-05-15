//
//  PlainTextEditor.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Tue Apr 06 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <AppKit/AppKit.h>
@class PlainTextEditor;
#import "TCMMMOperation.h"
#import "SelectionOperation.h"
#import "PlainTextWindowControllerTabContext.h"
#import "PlainTextWindowController.h"
#import "PopUpButton.h"
#import "SEEFindAndReplaceViewController.h"

extern NSString * const PlainTextEditorDidFollowUserNotification;
extern NSString * const PlainTextEditorDidChangeSearchScopeNotification;

@class PlainTextWindowControllerTabContext,PlainTextDocument,SEEPlainTextEditorScrollView,PopUpButton,RadarScroller,TCMMMUser, SEETextView, BorderedTextField;

@interface PlainTextEditor : NSResponder <NSTextViewDelegate> {
    IBOutlet PopUpButton *O_tabStatusPopUpButton;
    IBOutlet PopUpButton *O_modePopUpButton;
    IBOutlet PopUpButton *O_encodingPopUpButton;
    IBOutlet PopUpButton *O_lineEndingPopUpButton;
    IBOutlet BorderedTextField *O_windowWidthTextField;
	IBOutlet NSView *O_bottomBarSeparatorLineView;
    IBOutlet SEEPlainTextEditorScrollView *O_scrollView;
    RadarScroller   *I_radarScroller;
    SEETextView        *I_textView;
    NSTextContainer *I_textContainer;
    NSMutableArray *I_storedSelectedRanges;
    PlainTextWindowControllerTabContext *I_windowControllerTabContext;
    NSString *I_followUserID;
    struct {
        BOOL showTopStatusBar;
        BOOL showBottomStatusBar;
        BOOL hasSplitButton;
        BOOL symbolPopUpIsSorted;
        BOOL pausedProcessing;
    } I_flags;
    SelectionOperation *I_storedPosition;
}

@property (nonatomic, readonly) BOOL hasBottomOverlayView;
@property (nonatomic, readonly) BOOL hasTopOverlayView;
// bottom status bar binding values
@property (nonatomic, assign) BOOL showsNumberOfActiveParticipants;
@property (nonatomic, strong) NSNumber *numberOfActiveParticipants;

@property (nonatomic, strong) NSImage *alternateAnnounceImage;
@property (nonatomic) BOOL canAnnounceAndShare;

@property (nonatomic, copy) NSString *localizedToolTipAnnounceButton;
@property (nonatomic, copy) NSString *localizedToolTipShareInviteButton;
@property (nonatomic, copy) NSString *localizedToolTipToggleParticipantsButton;

@property (nonatomic, readonly) CGFloat desiredMinHeight;

- (void)prepareForDealloc; // because of programatic bindings to the top level object

- (id)initWithWindowControllerTabContext:(PlainTextWindowControllerTabContext *)aWindowControllerTabContext splitButton:(BOOL)aFlag;
- (NSView *)editorView;
- (NSTextView *)textView;
- (PlainTextDocument *)document;
- (void)updateSplitButtonForIsSplit:(BOOL)aFlag;

- (NSSize)desiredSizeForColumns:(int)aColumns rows:(int)aRows;
- (int)displayedColumns;
- (int)displayedRows;

- (void)pushSelectedRanges;
- (void)popSelectedRanges;

- (void)setShowsChangeMarks:(BOOL)aFlag;
- (BOOL)showsChangeMarks;
- (void)setWrapsLines:(BOOL)aFlag;
- (BOOL)wrapsLines;
- (void)setShowsInvisibleCharacters:(BOOL)aFlag;
- (BOOL)showsInvisibleCharacters;
- (BOOL)showsGutter;
- (void)setShowsGutter:(BOOL)aFlag;
- (BOOL)showsTopStatusBar;
- (void)setShowsTopStatusBar:(BOOL)aFlag;
- (BOOL)showsBottomStatusBar;
- (void)setShowsBottomStatusBar:(BOOL)aFlag;
- (void)setFollowUserID:(NSString *)userID;
- (NSString *)followUserID;
- (void)setWindowControllerTabContext:(PlainTextWindowControllerTabContext *)aContext;
- (PlainTextWindowControllerTabContext *)windowControllerTabContext;
- (void)takeStyleSettingsFromDocument;
- (void)takeSettingsFromDocument;

- (void)setRadarMarkForUser:(TCMMMUser *)aUser;

- (void)scrollToUserWithID:(NSString *)aUserID;

- (void)setNeedsDisplayForRuler;

- (void)updateViews;

- (void)storePosition;
- (void)restorePositionAfterOperation:(TCMMMOperation *)aOperation;

- (void)displayViewControllerInBottomArea:(NSViewController *)viewController;

#pragma mark -
#pragma mark ### Actions ###
- (IBAction)toggleWrap:(id)aSender;
- (IBAction)toggleShowsChangeMarks:(id)aSender;

- (IBAction)toggleTopStatusBar:(id)aSender;
- (IBAction)toggleFindAndReplace:(id)aSender;
- (IBAction)showFindAndReplace:(id)aSender;
- (IBAction)hideFindAndReplace:(id)aSender;

- (IBAction)shiftRight:(id)aSender;
- (IBAction)shiftLeft:(id)aSender;
- (IBAction)detab:(id)aSender;

- (IBAction)insertStateClose:(id)aSender;
- (IBAction)entab:(id)aSender;

- (IBAction)jumpToNextSymbol:(id)aSender;
- (IBAction)jumpToPreviousSymbol:(id)aSender;

- (IBAction)jumpToNextChange:(id)aSender;
- (IBAction)jumpToPreviousChange:(id)aSender;

- (IBAction)positionButtonAction:(id)aSender;

- (IBAction)changePendingUsersAccessAndAnnounce:(id)aSender;

- (void)selectRange:(NSRange)aRange;
- (void)selectRangeInBackground:(NSRange)aRange;
- (void)selectRangeInBackgroundWithoutIndication:(NSRange)aRange expandIfFolded:(BOOL)aFlag;
- (void)gotoLine:(unsigned)aLine;
- (void)gotoLineInBackground:(unsigned)aLine;

- (void)lock;
- (void)unlock;

- (void)updateTopScrollViewInset;
- (void)adjustToScrollViewInsets;


@property (nonatomic, readonly) PlainTextWindowController *plainTextWindowController;
@property (nonatomic, readonly) NSValue *searchScopeValue;
- (BOOL)hasSearchScopeInFullRange:(NSRange)aRange;
- (BOOL)hasSearchScope;
- (NSString *)searchScopeRangeString;
- (IBAction)addCurrentSelectionToSearchScope:(id)aSender;
- (IBAction)clearSearchScope:(id)aSender;

@property (nonatomic, readonly) BOOL isShowingFindAndReplaceInterface;
- (void)findAndReplaceViewControllerDidPressDismiss:(SEEFindAndReplaceViewController *)aViewController;

// funnel point for all our internal pointers for additional text checking
- (void)scheduleTextCheckingForRange:(NSRange)aRange;

- (BOOL)hitTestOverlayViewsWithEvent:(NSEvent *)aEvent;

@end

@interface PlainTextEditor (PlainTextEditorScriptingAdditions)
- (id)scriptSelection;
- (void)setScriptSelection:(id)selection;
@end