//
//  PlainTextDocument.h
//  SubEthaEdit
//
//  Created by Martin Ott on Tue Feb 24 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//


#import <Cocoa/Cocoa.h>

@class TCMMMSession, TCMMMOperation;

@interface PlainTextDocument : NSDocument
{
    TCMMMSession *I_session;
    struct {
        BOOL isAnnounced;
    } I_flags;
    
    NSTextStorage *I_textStorage;
}

- (void)setSession:(TCMMMSession *)aSession;
- (TCMMMSession *)session;

- (NSTextStorage *)textStorage;

- (IBAction)announce:(id)aSender;
- (IBAction)conceal:(id)aSender;

- (void)handleOperation:(TCMMMOperation *)aOperation;

@end
