//  PlainTextWindowController.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Fri Mar 05 2004.

#import <AppKit/AppKit.h>
@class PlainTextWindowController;
#import "PlainTextWindowControllerTabContext.h"

@class PlainTextEditor, PlainTextDocument;
#import "SEEEncodingDoctorDialogViewController.h"

@interface PlainTextWindowController : NSWindowController <NSMenuDelegate> 

- (void)setInitialRadarStatusForPlainTextEditor:(PlainTextEditor *)editor;
- (IBAction)changePendingUsersAccess:(id)aSender;
- (NSArray *)plainTextEditors;

@property (nonatomic, weak) PlainTextEditor *activePlainTextEditor;
@property (nonatomic, readonly) PlainTextDocument *plainTextDocument;

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

@property (nonatomic) BOOL showsGutter;

- (IBAction)toggleLineNumbers:(id)aSender;

- (void)setDocumentDialog:(NSViewController<SEEDocumentDialogViewController>*)aDocumentDialog;
- (NSViewController<SEEDocumentDialogViewController>*)documentDialog;
- (void)documentDidUpdateChangeCount;

/** Shims the pre-native tab tab context idea. Should be folded in again, or in a future
    where we do multiple documents per window again, molded into something new */
@property (nonatomic, strong, readonly) PlainTextWindowControllerTabContext *SEE_tabContext;
@property (nonatomic, strong, readonly) NSArray<PlainTextEditor *> *plainTextEditors;

/**
 Semantical replacement for previous "hasManyDocuments"

 @return YES if in a tab group and not alone.
 */
- (BOOL)isInTabGroup;

- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName document:(PlainTextDocument *)document;

- (void)updateWindowMinSize;
- (IBAction)toggleWebPreview:(id)sender;

- (NSRect)dissolveToFrame;
- (void)cascadeWindow;
@end
