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
    } I_flags;
    DocumentMode  *I_documentMode;
    NSTextStorage *I_textStorage;
}

- (void)setSession:(TCMMMSession *)aSession;
- (TCMMMSession *)session;

- (NSTextStorage *)textStorage;

- (DocumentMode *)documentMode;
- (void)setDocumentMode:(DocumentMode *)aDocumentMode;

- (IBAction)announce:(id)aSender;
- (IBAction)conceal:(id)aSender;

- (void)handleOperation:(TCMMMOperation *)aOperation;

@end
