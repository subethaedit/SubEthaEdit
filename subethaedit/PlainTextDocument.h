//
//  PlainTextDocument.h
//  SubEthaEdit
//
//  Created by Martin Ott on Tue Feb 24 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//


#import <Cocoa/Cocoa.h>

@class TCMMMSession, TCMMMOperation, DocumentMode;

@interface PlainTextDocument : NSDocument
{
    TCMMMSession *I_session;
    struct {
        BOOL isAnnounced;
        BOOL isRemotelyEditingTextStorage;
        BOOL isPerformingSyntaxHighlighting;
        BOOL highlightSyntax;
    } I_flags;
    DocumentMode  *I_documentMode;
    NSTextStorage *I_textStorage;
    NSDictionary  *I_plainTextAttributes;
}

- (id)initWithSession:(TCMMMSession *)aSession;

- (void)setSession:(TCMMMSession *)aSession;
- (TCMMMSession *)session;

- (NSTextStorage *)textStorage;

- (DocumentMode *)documentMode;
- (void)setDocumentMode:(DocumentMode *)aDocumentMode;

- (IBAction)announce:(id)aSender;
- (IBAction)conceal:(id)aSender;

- (void)handleOperation:(TCMMMOperation *)aOperation;

- (NSDictionary *)plainTextAttributes;

- (unsigned int)fileEncoding;
- (void)setFileEncoding:(unsigned int)anEncoding;

#pragma mark -
#pragma mark ### Syntax Highlighting ###

- (IBAction)toggleSyntaxHighlighting:(id)aSender;
- (void)highlightSyntaxInRange:(NSRange)aRange;
- (void)performHighlightSyntax;
- (void)highlightSyntaxLoop;

@end
