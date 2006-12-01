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
}

- (NSMutableArray *)plainTextEditors;

- (void)setEditorSplitView:(NSSplitView *)splitView;
- (NSSplitView *)editorSplitView;

- (void)setDialogSplitView:(NSSplitView *)splitView;
- (NSSplitView *)dialogSplitView;

- (void)setDocumentDialog:(id)dialog;
- (id)documentDialog;

- (void)setWindowController:(PlainTextWindowController *)windowController;
- (PlainTextWindowController *)windowController;

- (void)setDocument:(PlainTextDocument *)document;
- (PlainTextDocument *)document;

- (void)setIsReceivingContent:(BOOL)flag;
- (BOOL)isReceivingContent;

@end
