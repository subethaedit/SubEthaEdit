//
//  PlainTextDocument.h
//  SubEthaEdit
//
//  Created by Martin Ott on Tue Feb 24 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//


#import <Cocoa/Cocoa.h>

@class TCMMMSession, TCMMMOperation, DocumentMode, EncodingPopUpButton, PlainTextWindowController;

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
        BOOL highlightSyntax; // Document 
        BOOL usesTabs; // Document 
        BOOL indentNewLines; // Document 
        BOOL wrapLines; // Editor 
        BOOL wrapMode; // Document 
        BOOL showMatchingBrackets; // Document, mode specific
        BOOL showInvisibleCharacters; // Editor
        BOOL showGutter; //Editor
        BOOL showsChangeMarks; // Editor
        BOOL showsTopStatusBar; // Editor
        BOOL showsBottomStatusBar; // Editor
        BOOL keepDocumentVersion;
        BOOL isFileWritable;
        BOOL editAnyway;
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
    
    int I_lineEnding;
    NSString *I_lineEndingString;
    
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

- (BOOL)isAnnounced;
- (void)setIsAnnounced:(BOOL)aFlag;
- (IBAction)toggleIsAnnounced:(id)aSender;

- (NSArray *)plainTextEditors;

- (void)handleOperation:(TCMMMOperation *)aOperation;

- (NSString *)lineEndingString;
- (LineEnding)lineEnding;
- (void)setLineEnding:(LineEnding)newLineEnding;

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

- (void)setHighlightsSyntax:(BOOL)aFlag;
- (BOOL)highlightsSyntax;

- (PlainTextWindowController *)topmostWindowController;
- (void)gotoLine:(unsigned)aLine;
- (void)gotoLine:(unsigned)aLine orderFront:(BOOL)aFlag;
- (void)selectRange:(NSRange)aRange;
- (void)handleOpenDocumentEvent;

#pragma mark -
#pragma mark ### Flag Accessors ###

- (BOOL)wrapLines;
- (void)setWrapLines:(BOOL)aFlag;
- (void)setWrapMode:(int)newMode;
- (int)wrapMode;
- (void)setUsesTabs:(BOOL)aFlag;
- (BOOL)usesTabs;
- (int)tabWidth;
- (void)setTabWidth:(int)aTabWidth;
- (BOOL)showInvisibleCharacters;
- (void)setShowInvisibleCharacters:(BOOL)aFlag;
- (BOOL)showsGutter;
- (void)setShowsGutter:(BOOL)aFlag;
- (BOOL)showsMatchingBrackets;
- (void)setShowsMatchingBrackets:(BOOL)aFlag;
- (BOOL)showsChangeMarks;
- (void)setShowsChangeMarks:(BOOL)aFlag;
- (BOOL)indentsNewLines;
- (void)setIndentsNewLines:(BOOL)aFlag;
- (BOOL)showsTopStatusBar;
- (void)setShowsTopStatusBar:(BOOL)aFlag;
- (BOOL)showsBottomStatusBar;
- (void)setShowsBottomStatusBar:(BOOL)aFlag;
- (BOOL)keepDocumentVersion;
- (void)setKeepDocumentVersion:(BOOL)aFlag;
- (BOOL)isFileWritable;
- (void)setIsFileWritable:(BOOL)aFlag;
- (BOOL)editAnyway;
- (void)setEditAnyway:(BOOL)aFlag;


#pragma mark -
#pragma mark ### Syntax Highlighting ###

- (IBAction)toggleSyntaxHighlighting:(id)aSender;
- (void)highlightSyntaxInRange:(NSRange)aRange;
- (void)performHighlightSyntax;
- (void)highlightSyntaxLoop;

@end
