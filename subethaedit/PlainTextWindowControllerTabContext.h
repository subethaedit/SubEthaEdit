//
//  PlainTextWindowControllerTabContext.h
//  SubEthaEdit
//
//  Created by Martin Ott on 10/17/06.
//  Copyright 2006 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PlainTextWindowController, PlainTextDocument;


@interface PlainTextWindowControllerTabContext : NSObject {
    @private
    NSMutableArray *_plainTextEditors;
    NSSplitView *_editorSplitView;
    NSSplitView *_dialogSplitView;
    id _documentDialog;
    BOOL _isReceivingContent;
    PlainTextDocument *_document;
    BOOL _isAlertScheduled;
    
    BOOL _isProcessing;
    NSImage *_icon;
    NSString *_iconName;
    int _objectCount;
    BOOL _isEdited;
}

- (NSMutableArray *)plainTextEditors;

- (void)setEditorSplitView:(NSSplitView *)splitView;
- (NSSplitView *)editorSplitView;

- (void)setDialogSplitView:(NSSplitView *)splitView;
- (NSSplitView *)dialogSplitView;

- (void)setDocumentDialog:(id)dialog;
- (id)documentDialog;

- (void)setDocument:(PlainTextDocument *)document;
- (PlainTextDocument *)document;

- (void)setIsReceivingContent:(BOOL)flag;
- (BOOL)isReceivingContent;

- (void)setIsAlertScheduled:(BOOL)flag;
- (BOOL)isAlertScheduled;

- (BOOL)isProcessing;
- (void)setIsProcessing:(BOOL)value;
- (NSImage *)icon;
- (void)setIcon:(NSImage *)icon;
- (NSString *)iconName;
- (void)setIconName:(NSString *)iconName;
- (int)objectCount;
- (void)setObjectCount:(int)value;
- (BOOL)isEdited;
- (void)setIsEdited:(BOOL)value;

@end
