//
//  PlainTextWindowControllerTabContext.m
//  SubEthaEdit
//
//  Created by Martin Ott on 10/17/06.
//  Copyright 2006 TheCodingMonkeys. All rights reserved.
//

#import "PlainTextWindowControllerTabContext.h"
#import "PlainTextWindowController.h"


@implementation PlainTextWindowControllerTabContext

- (id)init
{
    self = [super init];
    if (self) {
        _plainTextEditors = [[NSMutableArray alloc] init];
        _isReceivingContent = NO;
        
        _isProcessing = NO;
        _icon = nil;
        _iconName = nil;
        _objectCount = 0;
    }
    return self;
}


- (void)dealloc
{
    _document = nil;
    [_plainTextEditors makeObjectsPerformSelector:@selector(setWindowController:) withObject:nil];
    [_plainTextEditors release];
    [_editorSplitView release];
    [_dialogSplitView release];
    [_documentDialog release];
    
    [_icon release];
    [_iconName release];
    
    [super dealloc];
}


- (NSString *)description
{
    return [NSString stringWithFormat:@"%@, document: %@", [super description], _document];
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


- (void)setWindowController:(PlainTextWindowController *)windowController
{
    NSEnumerator *enumerator = [_plainTextEditors objectEnumerator];
    id editor;
    while ((editor = [enumerator nextObject])) {
        [editor setWindowController:windowController];
    }
}


- (PlainTextWindowController *)windowController
{
    if ([_plainTextEditors count] > 0) {
        return [[_plainTextEditors objectAtIndex:0] windowController];
    } else {
        return nil;
    }
}


- (void)setDocument:(PlainTextDocument *)document
{
    _document = document;
}

- (PlainTextDocument *)document
{
    return _document;
}


- (void)setIsReceivingContent:(BOOL)flag
{
    _isReceivingContent = flag;
    _isProcessing = flag;
}

- (BOOL)isReceivingContent
{
    return _isReceivingContent;
}


- (BOOL)isProcessing
{
    return _isProcessing;
}

- (void)setIsProcessing:(BOOL)value
{
    _isProcessing = value;
    _isReceivingContent = value;
}

- (NSImage *)icon
{
    return _icon;
}

- (void)setIcon:(NSImage *)icon
{
    [icon retain];
    [_icon release];
    _icon = icon;
}

- (NSString *)iconName
{
    return _iconName;
}

- (void)setIconName:(NSString *)iconName
{
    [iconName retain];
    [_iconName release];
    _iconName = iconName;
}

- (int)objectCount
{
    return _objectCount;
}

- (void)setObjectCount:(int)value
{
    _objectCount = value;
}


@end
