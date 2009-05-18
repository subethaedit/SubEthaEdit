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

@class PlainTextWindowControllerTabContext,PlainTextDocument,PopUpButton,RadarScroller,TCMMMUser, TextView;

@interface PlainTextEditor : NSResponder {
    IBOutlet NSImageView *O_waitPipeStatusImageView;
    IBOutlet NSTextField *O_positionTextField;
    IBOutlet PopUpButton *O_tabStatusPopUpButton;
    IBOutlet NSTextField *O_windowWidthTextField;
    IBOutlet NSTextField *O_writtenByTextField;
    IBOutlet PopUpButton *O_modePopUpButton;
    IBOutlet PopUpButton *O_encodingPopUpButton;
    IBOutlet PopUpButton *O_lineEndingPopUpButton;
    IBOutlet PopUpButton *O_symbolPopUpButton;
    IBOutlet NSScrollView *O_scrollView;
    IBOutlet NSView       *O_editorView;
    IBOutlet NSView       *O_topStatusBarView;
    IBOutlet NSView       *O_bottomStatusBarView;
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

#pragma mark -
#pragma mark ### Actions ###
- (IBAction)toggleWrap:(id)aSender;
- (IBAction)toggleShowsChangeMarks:(id)aSender;

- (IBAction)jumpToNextSymbol:(id)aSender;
- (IBAction)jumpToPreviousSymbol:(id)aSender;

- (IBAction)jumpToNextChange:(id)aSender;
- (IBAction)jumpToPreviousChange:(id)aSender;

- (void)selectRange:(NSRange)aRange;
- (void)selectRangeInBackground:(NSRange)aRange;
- (void)gotoLine:(unsigned)aLine;
- (void)gotoLineInBackground:(unsigned)aLine;


@end

@interface PlainTextEditor (PlainTextEditorScriptingAdditions)
- (id)scriptSelection;
- (void)setScriptSelection:(id)selection;
@end