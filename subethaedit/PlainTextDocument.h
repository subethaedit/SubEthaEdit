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
extern NSString * const WrittenByUserIDAttributeName;
extern NSString * const ChangedByUserIDAttributeName;


@interface PlainTextDocument : NSDocument
{
    TCMMMSession *I_session;
    struct {
        BOOL isAnnounced;
        BOOL isRemotelyEditingTextStorage;
        BOOL isPerformingSyntaxHighlighting;
        BOOL highlightSyntax;
        BOOL usesTabs;
        BOOL indentNewLines;
        BOOL wrapsCharacters;
        BOOL showMatchingBrackets;
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
    NSDictionary *I_plainTextAttributes;
    NSDictionary *I_typingAttributes;
    NSMutableParagraphStyle *I_defaultParagraphStyle;
    NSDictionary *I_fileAttributes;
    NSDictionary *I_ODBParameters;
    
    IBOutlet NSView *O_savePanelAccessoryView;
    IBOutlet EncodingPopUpButton *O_encodingPopUpButton;
    NSSaveOperationType I_lastSaveOperation;
    NSStringEncoding I_encodingFromLastRunSaveToOperation;
    
    struct {
        int numberOfBrackets;
        unichar *closingBracketsArray;
        unichar *openingBracketsArray;
        unsigned matchingBracketPosition;
    } I_bracketMatching;
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
- (NSDictionary *)typingAttributes;
- (NSDictionary *)plainTextAttributes;
- (NSParagraphStyle *)defaultParagraphStyle;
- (void)setPlainFont:(NSFont *)aFont;

- (unsigned int)fileEncoding;
- (void)setFileEncoding:(unsigned int)anEncoding;
- (NSDictionary *)fileAttributes;
- (void)setFileAttributes:(NSDictionary *)attributes;
- (NSDictionary *)ODBParameters;
- (void)setODBParameters:(NSDictionary *)aDictionary;

- (BOOL)wrapsCharacters;
- (BOOL)usesTabs;
- (int)tabWidth;
- (void)setTabWidth:(int)aTabWidth;

#pragma mark -
#pragma mark ### Syntax Highlighting ###

- (IBAction)toggleSyntaxHighlighting:(id)aSender;
- (void)highlightSyntaxInRange:(NSRange)aRange;
- (void)performHighlightSyntax;
- (void)highlightSyntaxLoop;

@end
