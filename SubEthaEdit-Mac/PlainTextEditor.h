//
//  PlainTextEditor.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Tue Apr 06 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "TCMMMOperation.h"
#import "SelectionOperation.h"
#import "PlainTextWindowControllerTabContext.h"
#import "PopUpButton.h"

@class PlainTextWindowControllerTabContext,PlainTextDocument,SEEPlainTextEditorScrollView,PopUpButton,RadarScroller,TCMMMUser, TextView;

@interface PlainTextEditor : NSResponder <NSTextViewDelegate, PopUpButtonDelegate> {
    IBOutlet NSImageView *O_waitPipeStatusImageView;
    IBOutlet NSTextField *O_positionTextField;
    IBOutlet PopUpButton *O_tabStatusPopUpButton;
    IBOutlet NSTextField *O_windowWidthTextField;
    IBOutlet NSTextField *O_writtenByTextField;
    IBOutlet PopUpButton *O_modePopUpButton;
    IBOutlet PopUpButton *O_encodingPopUpButton;
    IBOutlet PopUpButton *O_lineEndingPopUpButton;
    IBOutlet PopUpButton *O_symbolPopUpButton;
    IBOutlet NSButton	 *O_splitButton;
    IBOutlet SEEPlainTextEditorScrollView *O_scrollView;
    RadarScroller   *I_radarScroller;
    TextView        *I_textView;
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


- (id)initWithWindowControllerTabContext:(PlainTextWindowControllerTabContext *)aWindowControllerTabContext splitButton:(BOOL)aFlag;
- (NSView *)editorView;
- (NSTextView *)textView;
- (PlainTextDocument *)document;
- (void)setIsSplit:(BOOL)aFlag;

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
- (void)takeStyleSettingsFromDocument;
- (void)takeSettingsFromDocument;

- (void)updateSelectedSymbol;
- (void)updateSymbolPopUpSorted:(BOOL)aSorted;

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

- (IBAction)shiftRight:(id)aSender;
- (IBAction)shiftLeft:(id)aSender;
- (IBAction)detab:(id)aSender;

- (IBAction)insertStateClose:(id)aSender;
- (IBAction)entab:(id)aSender;

- (IBAction)jumpToNextSymbol:(id)aSender;
- (IBAction)jumpToPreviousSymbol:(id)aSender;

- (IBAction)jumpToNextChange:(id)aSender;
- (IBAction)jumpToPreviousChange:(id)aSender;

- (void)selectRange:(NSRange)aRange;
- (void)selectRangeInBackground:(NSRange)aRange;
- (void)selectRangeInBackgroundWithoutIndication:(NSRange)aRange expandIfFolded:(BOOL)aFlag;
- (void)gotoLine:(unsigned)aLine;
- (void)gotoLineInBackground:(unsigned)aLine;


// funnel point for all our internal pointers for additional text checking
- (void)scheduleTextCheckingForRange:(NSRange)aRange;


@end

@interface PlainTextEditor (PlainTextEditorScriptingAdditions)
- (id)scriptSelection;
- (void)setScriptSelection:(id)selection;
@end