//
//  PlainTextWindowController.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Fri Mar 05 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <AppKit/AppKit.h>


@class ParticipantsView,PlainTextEditor;
extern NSString * const PlainTextWindowToolbarIdentifier;
extern NSString * const ParticipantsToolbarItemIdentifier;
extern NSString * const ShiftLeftToolbarItemIdentifier;
extern NSString * const ShiftRightToolbarItemIdentifier;
extern NSString * const RendezvousToolbarItemIdentifier;
extern NSString * const InternetToolbarItemIdentifier;
extern NSString * const ToggleChangeMarksToolbarItemIdentifier;
extern NSString * const ToggleAnnouncementToolbarItemIdentifier;

@interface PlainTextWindowController : NSWindowController {

    // praticipants
    IBOutlet NSDrawer            *O_participantsDrawer;
    IBOutlet NSScrollView        *O_participantsScrollView;
    IBOutlet ParticipantsView    *O_participantsView;
    IBOutlet NSPopUpButton       *O_actionPullDown;
    IBOutlet NSPopUpButton       *O_pendingUsersAccessPopUpButton;
    IBOutlet NSButton            *O_kickButton;
    IBOutlet NSButton            *O_readOnlyButton;
    IBOutlet NSButton            *O_readWriteButton;
    IBOutlet NSView              *O_receivingContentView;
    IBOutlet NSProgressIndicator *O_progressIndicator;
    IBOutlet NSImageView         *O_URLImageView;
    IBOutlet NSTextField         *O_receivingStatusTextField;
    NSSplitView *I_editorSplitView;
    NSSplitView *I_dialogSplitView;
    id I_documentDialog;

    NSMutableArray *I_plainTextEditors;
    NSMenu *I_contextMenu;
    struct {
        BOOL isReceivingContent;
        BOOL zoomFix_defaultFrameHadEqualWidth;
    } I_flags;
    NSTimer *I_dialogAnimationTimer;
}

- (IBAction)changePendingUsersAccess:(id)aSender;
- (NSArray *)plainTextEditors;
- (PlainTextEditor *)activePlainTextEditor;

- (void)refreshDisplay;

- (IBAction)openParticipantsDrawer:(id)aSender;
- (IBAction)closeParticipantsDrawer:(id)aSender;

- (void)validateButtons;

- (IBAction)kickButtonAction:(id)aSender;
- (IBAction)readOnlyButtonAction:(id)aSender;
- (IBAction)readWriteButtonAction:(id)aSender;

- (void)gotoLine:(unsigned)aLine;
- (void)selectRange:(NSRange)aRange;

- (void)setIsReceivingContent:(BOOL)aFlag;
- (void)didLoseConnection;

- (void)setSizeByColumns:(int)aColumns rows:(int)aRows;
- (void)setShowsBottomStatusBar:(BOOL)aFlag;

- (BOOL)showsGutter;
- (void)setShowsGutter:(BOOL)aFlag;
- (IBAction)toggleLineNumbers:(id)aSender;

- (void)setDocumentDialog:(id)aDocumentDialog;
- (id)documentDialog;

@end
