//
//  PlainTextWindowControllerTabContext.h
//  SubEthaEdit
//
//  Created by Martin Ott on 10/17/06.
//  Copyright 2006 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PlainTextWindowControllerTabContext : NSObject {
    @private
    NSMutableArray *_plainTextEditors;
    NSSplitView *_editorSplitView;
    NSSplitView *_dialogSplitView;
    id _documentDialog;
}

- (NSMutableArray *)plainTextEditors;

- (void)setEditorSplitView:(NSSplitView *)splitView;
- (NSSplitView *)editorSplitView;

- (void)setDialogSplitView:(NSSplitView *)splitView;
- (NSSplitView *)dialogSplitView;

- (void)setDocumentDialog:(id)dialog;
- (id)documentDialog;

@end
