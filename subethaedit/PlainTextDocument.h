//
//  PlainTextDocument.h
//  SubEthaEdit
//
//  Created by Martin Ott on Tue Feb 24 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//


#import <Cocoa/Cocoa.h>

@class TCMMMSession, TCMMMOperation, DocumentMode, EncodingPopUpButton;

extern NSString * const PlainTextDocumentDefaultParagraphStyleDidChangeNotification;
extern NSString * const PlainTextDocumentDidChangeDisplayNameNotification;

@interface PlainTextDocument : NSDocument
{
    TCMMMSession *I_session;
    struct {
        BOOL isAnnounced;
        BOOL isRemotelyEditingTextStorage;
        BOOL isPerformingSyntaxHighlighting;
        BOOL highlightSyntax;
        BOOL useTabs;
        BOOL indentNewLines;
    } I_flags;
    int I_tabWidth;
    DocumentMode  *I_documentMode;
    NSTextStorage *I_textStorage;
    struct {
        NSFont *plainFont;
        NSFont *boldFont;
        NSFont *italicFont;
        NSFont *boldItalicFont;
    } I_fonts;
    NSDictionary  *I_plainTextAttributes;
    NSMutableParagraphStyle *I_defaultParagraphStyle;
    NSDictionary *I_fileAttributes;
    
    IBOutlet NSView *O_savePanelAccessoryView;
    IBOutlet EncodingPopUpButton *O_encodingPopUpButton;
    NSSaveOperationType I_lastSaveOperation;
    NSStringEncoding I_encodingFromLastRunSaveToOperation;
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

- (NSFont *)fontWithTrait:(NSFontTraitMask)aFontTrait;
- (NSDictionary *)plainTextAttributes;
- (NSParagraphStyle *)defaultParagraphStyle;
- (void)setPlainFont:(NSFont *)aFont;

- (unsigned int)fileEncoding;
- (void)setFileEncoding:(unsigned int)anEncoding;
- (NSDictionary *)fileAttributes;
- (void)setFileAttributes:(NSDictionary *)attributes;

- (void)setTabWidth:(int)aTabWidth;

#pragma mark -
#pragma mark ### Syntax Highlighting ###

- (IBAction)toggleSyntaxHighlighting:(id)aSender;
- (void)highlightSyntaxInRange:(NSRange)aRange;
- (void)performHighlightSyntax;
- (void)highlightSyntaxLoop;

@end
