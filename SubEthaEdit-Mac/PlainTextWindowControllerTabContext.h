//
//  PlainTextWindowControllerTabContext.h
//  SubEthaEdit
//
//  Created by Martin Ott on 10/17/06.
//  Copyright 2006 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PlaintextWindowControllerTabContext;

#import "SEEEditorSplitViewDelegate.h"
#import "SEEDialogSplitViewDelegate.h"
#import "SEEWebPreviewSplitViewDelegate.h"
#import "PlainTextEditor.h"

extern NSString * const SEEPlainTextWindowControllerTabContextActiveEditorDidChangeNotification;

@class PlainTextWindowController, WebPreviewViewController, PlainTextDocument, PlainTextLoadProgress;

@interface PlainTextWindowControllerTabContext : NSResponder
@property (nonatomic, strong) PlainTextDocument *document;

@property (nonatomic, strong) NSSplitView *editorSplitView;
@property (nonatomic, strong) SEEEditorSplitViewDelegate *editorSplitViewDelegate;
@property (nonatomic, strong) NSMutableArray *plainTextEditors;
@property (nonatomic,   weak) PlainTextEditor *activePlainTextEditor;

@property (nonatomic, strong) NSSplitView *dialogSplitView;
@property (nonatomic, strong) SEEDialogSplitViewDelegate *dialogSplitViewDelegate;
@property (nonatomic, strong) id documentDialog;

@property (nonatomic, strong) NSSplitView *webPreviewSplitView;
@property (nonatomic, strong) SEEWebPreviewSplitViewDelegate *webPreviewSplitViewDelegate;
@property (nonatomic, strong) WebPreviewViewController *webPreviewViewController;

@property (nonatomic, assign) BOOL isReceivingContent;
@property (nonatomic, assign) BOOL isAlertScheduled;
@property (nonatomic, strong) PlainTextLoadProgress *loadProgress;

@property (nonatomic, assign) BOOL isProcessing;
@property (nonatomic, assign) BOOL isEdited;
@property (nonatomic, strong) NSImage *icon;
@property (nonatomic, strong) NSString *iconName;

@end
