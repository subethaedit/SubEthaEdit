//
//  PlainTextWindowControllerTabContext.m
//  SubEthaEdit
//
//  Created by Martin Ott on 10/17/06.
//  Copyright 2006 TheCodingMonkeys. All rights reserved.
//

#import "PlainTextWindowControllerTabContext.h"


@implementation PlainTextWindowControllerTabContext

- (id)init
{
    self = [super init];
    if (self) 
    {
        _plainTextEditors = [[NSMutableArray alloc] init];
    }
    return self;
}


- (void)dealloc
{
    NSLog(@"%@ %s", [self description], __FUNCTION__);
    [_plainTextEditors makeObjectsPerformSelector:@selector(setWindowController:) withObject:nil];
    [_plainTextEditors release];
    [_editorSplitView release];
    [_dialogSplitView release];
    [_documentDialog release];
    [super dealloc];
}


- (NSMutableArray *)plainTextEditors
{
    return _plainTextEditors;
}


- (void)setEditorSplitView:(NSSplitView *)splitView
{
    [splitView retain];
    [_editorSplitView release];
    _editorSplitView = splitView;
}


- (NSSplitView *)editorSplitView
{
    return _editorSplitView;
}


- (void)setDialogSplitView:(NSSplitView *)splitView
{
    [splitView retain];
    [_dialogSplitView release];
    _dialogSplitView = splitView;
}


- (NSSplitView *)dialogSplitView
{
    return _dialogSplitView;
}


- (void)setDocumentDialog:(id)dialog
{
    [dialog retain];
    [_documentDialog release];
    _documentDialog = dialog;
}


- (id)documentDialog
{
    return _documentDialog;
}

@end
