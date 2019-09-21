//  PlainTextWindowControllerTabContext.h
//  SubEthaEdit
//
//  Created by Martin Ott on 10/17/06.

#import <Cocoa/Cocoa.h>

@class PlaintextWindowControllerTabContext;

#import "SEEEditorSplitViewDelegate.h"
#import "SEEDialogSplitViewDelegate.h"
#import "SEEWebPreviewSplitViewDelegate.h"
#import "PlainTextEditor.h"
#import "SEEEncodingDoctorDialogViewController.h" // contains the protocol for now

extern CGFloat const SEEMinWebPreviewWidth;
extern CGFloat const SEEMinEditorWidth;

extern NSString * const SEEPlainTextWindowControllerTabContextActiveEditorDidChangeNotification;

@class PlainTextWindowController, SEEWebPreviewViewController, PlainTextDocument, PlainTextLoadProgress;

@interface PlainTextWindowControllerTabContext : NSResponder

@property (nonatomic, strong) NSString *uuid;

@property (nonatomic, strong) PlainTextDocument *document;
@property (nonatomic, readonly) PlainTextWindowController *windowController;
@property (nonatomic, weak) NSView *presentedView;
@property (nonatomic, weak) NSView *contentView;

@property (nonatomic, strong) NSSplitView *editorSplitView;
@property (nonatomic, strong) SEEEditorSplitViewDelegate *editorSplitViewDelegate;
@property (nonatomic, strong) NSMutableArray *plainTextEditors;
@property (nonatomic, weak) PlainTextEditor *activePlainTextEditor;

@property (nonatomic, strong) NSSplitView *dialogSplitView;
@property (nonatomic, strong) SEEDialogSplitViewDelegate *dialogSplitViewDelegate;
@property (nonatomic, strong) NSViewController<SEEDocumentDialogViewController> *documentDialog;

@property (nonatomic, strong) NSSplitView *webPreviewSplitView;
@property (nonatomic, strong) SEEWebPreviewSplitViewDelegate *webPreviewSplitViewDelegate;
@property (nonatomic, strong) SEEWebPreviewViewController *webPreviewViewController;

@property (nonatomic) BOOL isReceivingContent;
@property (nonatomic) BOOL isAlertScheduled;
@property (nonatomic, strong) PlainTextLoadProgress *loadProgress;

@property (nonatomic) BOOL isProcessing;
@property (nonatomic) BOOL isEdited;
@property (nonatomic, strong) NSImage *icon;
@property (nonatomic, strong) NSString *iconName;

- (void)toggleEditorSplit;
@property (nonatomic) BOOL hasEditorSplit;
@property (nonatomic) BOOL hasWebPreviewSplit;

- (IBAction)openParticipantsOverlay:(id)aSender;
- (IBAction)closeParticipantsOverlay:(id)aSender;
- (IBAction)toggleParticipantsOverlay:(id)aSender;
- (BOOL)showsParticipantsOverlay;
@end
