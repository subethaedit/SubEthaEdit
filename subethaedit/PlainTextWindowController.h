//
//  PlainTextWindowController.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Fri Mar 05 2004.
//  Copyright (c) 2004-2007 TheCodingMonkeys. All rights reserved.
//

#import <AppKit/AppKit.h>
#import <TCMPortMapper/TCMPortMapper.h>

#if defined(CODA)
@class ParticipantsView, PlainTextEditor, PlainTextDocument,URLImageView;
#else
@class ParticipantsView, PlainTextEditor, PSMTabBarControl, PlainTextDocument,URLImageView;
#endif //defined(CODA)

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
    IBOutlet NSButton            *O_followButton;
    
    IBOutlet URLImageView         *O_URLImageView;
    IBOutlet NSTextField          *O_URLTextField;
    
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
#if !defined(CODA)	
    NSTabView *I_tabView;
    PSMTabBarControl *I_tabBar;
#endif //!defined(CODA)	
    
    NSMutableArray *I_documents;
    NSDocument *I_documentBeingClosed;

    NSImageView *I_lockImageView;

}

- (IBAction)changePendingUsersAccess:(id)aSender;
- (NSArray *)plainTextEditors;
- (PlainTextEditor *)activePlainTextEditor;
- (PlainTextEditor *)activePlainTextEditorForDocument:(PlainTextDocument *)aDocument;

- (void)refreshDisplay;

- (IBAction)openParticipantsDrawer:(id)aSender;
- (IBAction)closeParticipantsDrawer:(id)aSender;

- (void)validateButtons;

- (IBAction)kickButtonAction:(id)aSender;
- (IBAction)readOnlyButtonAction:(id)aSender;
- (IBAction)readWriteButtonAction:(id)aSender;
- (IBAction)followUser:(id)aSender;
- (IBAction)toggleFollowUser:(id)aSender;
 
- (IBAction)openInSeparateWindow:(id)sender;

- (void)gotoLine:(unsigned)aLine;
- (void)selectRange:(NSRange)aRange;
- (void)selectRangeInBackground:(NSRange)aRange;

- (void)document:(PlainTextDocument *)document isReceivingContent:(BOOL)flag;
- (void)documentDidLoseConnection:(PlainTextDocument *)document;

- (void)setSizeByColumns:(int)aColumns rows:(int)aRows;
- (void)setShowsBottomStatusBar:(BOOL)aFlag;

- (BOOL)showsGutter;
- (void)setShowsGutter:(BOOL)aFlag;
- (IBAction)toggleLineNumbers:(id)aSender;

- (void)setDocumentDialog:(id)aDocumentDialog;
- (id)documentDialog;

- (void)documentWillClose:(NSDocument *)document;

#if !defined(CODA)
- (void)documentUpdatedChangeCount:(PlainTextDocument *)document;
- (NSTabViewItem *)addDocument:(NSDocument *)document;
- (void)moveAllTabsToWindowController:(PlainTextWindowController *)windowController;
- (NSTabViewItem *)tabViewItemForDocument:(PlainTextDocument *)document;
- (NSArray *)plainTextEditorsForDocument:(id)aDocument;
- (BOOL)selectTabForDocument:(id)aDocument;
- (BOOL)hasManyDocuments;
- (IBAction)closeTab:(id)sender;
- (IBAction)selectNextTab:(id)sender;
- (IBAction)selectPreviousTab:(id)sender;
- (IBAction)showDocumentAtIndex:(id)aMenuEntry;
- (void)closeAllTabs;
#endif //!defined(CODA)
- (void)reviewChangesAndQuitEnumeration:(BOOL)cont;

#if !defined(CODA)
- (NSArray *)orderedDocuments;
#endif //!defined(CODA)
- (NSArray *)documents;

- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName document:(PlainTextDocument *)document;

#if !defined(CODA)
- (PSMTabBarControl *)tabBar;
- (NSTabView *)tabView;
#endif //!defined(CODA)

- (NSRect)dissolveToFrame;
#if !defined(CODA)
- (void)cascadeWindow;
#endif //!defined(CODA)
@end
