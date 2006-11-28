//
//  PlainTextWindowController.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Fri Mar 05 2004.
//  Copyright (c) 2004-2006 TheCodingMonkeys. All rights reserved.
//

#import <AppKit/AppKit.h>


@class ParticipantsView, PlainTextEditor, PSMTabBarControl, PlainTextDocument;

extern NSString * const PlainTextWindowToolbarIdentifier;
extern NSString * const ParticipantsToolbarItemIdentifier;
extern NSString * const ShiftLeftToolbarItemIdentifier;
extern NSString * const ShiftRightToolbarItemIdentifier;
extern NSString * const RendezvousToolbarItemIdentifier;
extern NSString * const InternetToolbarItemIdentifier;
extern NSString * const ToggleChangeMarksToolbarItemIdentifier;
extern NSString * const ToggleAnnouncementToolbarItemIdentifier;

@interface PlainTextWindowController : NSWindowController {

    // Participants drawer views
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
    
    // Pointers to the current instances
    NSSplitView *I_editorSplitView;
    NSSplitView *I_dialogSplitView;
    id I_documentDialog;
    NSMutableArray *I_plainTextEditors;
    
    NSMenu *I_contextMenu;
    struct {
        BOOL zoomFix_defaultFrameHadEqualWidth;
    } I_flags;
    NSTimer *I_dialogAnimationTimer;
    
    @private
    NSTabView *I_tabView;
    PSMTabBarControl *I_tabBar;
    
    NSMutableArray *I_documents;
    NSMutableArray *I_tabContexts;
    NSDocument *I_documentBeingClosed;
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

- (IBAction)openInSeparateWindow:(id)sender;

- (void)gotoLine:(unsigned)aLine;
- (void)selectRange:(NSRange)aRange;

- (void)document:(PlainTextDocument *)document isReceivingContent:(BOOL)flag;
- (void)didLoseConnection;

- (void)setSizeByColumns:(int)aColumns rows:(int)aRows;
- (void)setShowsBottomStatusBar:(BOOL)aFlag;

- (BOOL)showsGutter;
- (void)setShowsGutter:(BOOL)aFlag;
- (IBAction)toggleLineNumbers:(id)aSender;

- (void)setDocumentDialog:(id)aDocumentDialog;
- (id)documentDialog;

- (void)documentWillClose:(NSDocument *)document;

- (NSArray *)plainTextEditorsForDocument:(id)aDocument;
- (BOOL)selectTabForDocument:(id)aDocument;
- (BOOL)hasManyDocuments;
- (IBAction)closeTab:(id)sender;
- (IBAction)selectNextTab:(id)sender;
- (IBAction)selectPreviousTab:(id)sender;
- (void)closeAllTabs;
- (void)reviewChangesAndQuitEnumeration:(BOOL)cont;

- (NSArray *)orderedDocuments;
- (NSArray *)documents;
- (NSArray *)tabContexts;

- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName document:(PlainTextDocument *)document;

- (PSMTabBarControl *)tabBar;
- (NSTabView *)tabView;

@end
