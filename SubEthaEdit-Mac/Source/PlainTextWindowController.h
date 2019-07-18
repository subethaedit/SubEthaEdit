//  PlainTextWindowController.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Fri Mar 05 2004.

#import <AppKit/AppKit.h>
#import <TCMPortMapper/TCMPortMapper.h>
@class PlainTextWindowController;
#import "PlainTextWindowControllerTabContext.h"

@class PlainTextEditor, PlainTextDocument;
#import "SEEEncodingDoctorDialogViewController.h"

@interface PlainTextWindowController : NSWindowController <NSMenuDelegate>
 {
    // Pointers to the current instances
    NSSplitView *I_dialogSplitView;
    PlainTextWindowControllerTabContext *I_tabContext;
    id I_documentDialog;
    
    struct {
        BOOL zoomFix_defaultFrameHadEqualWidth;
    } I_flags;
    NSTimer *I_dialogAnimationTimer;
    BOOL I_doNotCascade;

 @private

    NSMutableArray *I_documents;
    NSDocument *I_documentBeingClosed;

    NSImageView *I_lockImageView;

}

- (void)setInitialRadarStatusForPlainTextEditor:(PlainTextEditor *)editor;
- (IBAction)changePendingUsersAccess:(id)aSender;
- (NSArray *)plainTextEditors;

@property (nonatomic, weak) PlainTextEditor *activePlainTextEditor;

- (PlainTextEditor *)activePlainTextEditorForDocument:(PlainTextDocument *)aDocument;

- (void)refreshDisplay;

- (void)openParticipantsOverlayForDocument:(PlainTextDocument *)aDocument;
- (void)closeParticipantsOverlayForDocument:(PlainTextDocument *)aDocument;

- (void)gotoLine:(unsigned)aLine;
- (void)selectRange:(NSRange)aRange;
- (void)selectRangeInBackground:(NSRange)aRange;

@property (readonly) BOOL isShowingFindAndReplaceInterface;
- (IBAction)showFindAndReplaceInterface:(id)aSender;

- (IBAction)jumpToNextSymbol:(id)aSender;
- (IBAction)jumpToPreviousSymbol:(id)aSender;

- (void)document:(PlainTextDocument *)document isReceivingContent:(BOOL)flag;
- (void)documentDidLoseConnection:(PlainTextDocument *)document;

- (void)setWindowFrame:(NSRect)aFrame constrainedToScreen:(NSScreen *)aScreen display:(BOOL)aFlag;
- (void)setSizeByColumns:(NSInteger)aColumns rows:(NSInteger)aRows;
- (void)setShowsBottomStatusBar:(BOOL)aFlag;

- (BOOL)showsGutter;
- (void)setShowsGutter:(BOOL)aFlag;
- (IBAction)toggleLineNumbers:(id)aSender;

- (void)setDocumentDialog:(NSViewController<SEEDocumentDialogViewController>*)aDocumentDialog;
- (NSViewController<SEEDocumentDialogViewController>*)documentDialog;

- (void)documentWillClose:(NSDocument *)document;

- (void)documentUpdatedChangeCount:(PlainTextDocument *)document;
- (NSTabViewItem *)addDocument:(NSDocument *)document;
- (void)moveAllTabsToWindowController:(PlainTextWindowController *)windowController;
- (NSTabViewItem *)tabViewItemForDocument:(PlainTextDocument *)document;
- (PlainTextWindowControllerTabContext *)windowControllerTabContextForDocument:(PlainTextDocument *)document;
- (NSArray *)plainTextEditorsForDocument:(id)aDocument;
- (BOOL)selectTabForDocument:(id)aDocument;
- (BOOL)hasManyDocuments;
- (IBAction)closeTab:(id)sender;
- (IBAction)showDocumentAtIndex:(id)aMenuEntry;
- (void)closeAllTabs;
- (void)reviewChangesAndQuitEnumeration:(BOOL)cont;

- (NSArray *)orderedDocuments;
- (NSArray *)documents;

- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName document:(PlainTextDocument *)document;

- (void)updateWindowMinSize;
- (IBAction)toggleWebPreview:(id)sender;

@property (nonatomic, readonly) PlainTextWindowControllerTabContext *selectedTabContext;

- (NSRect)dissolveToFrame;
- (void)cascadeWindow;
@end
