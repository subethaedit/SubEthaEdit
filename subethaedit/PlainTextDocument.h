//
//  PlainTextDocument.h
//  SubEthaEdit
//
//  Created by Martin Ott on Tue Feb 24 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//


#import <Cocoa/Cocoa.h>

@class TCMMMSession, TCMMMOperation, DocumentMode, EncodingPopUpButton, 
       PlainTextWindowController, WebPreviewWindowController,
       DocumentProxyWindowController, FindAllController;

extern NSString * const PlainTextDocumentSessionWillChangeNotification;
extern NSString * const PlainTextDocumentSessionDidChangeNotification;

extern NSString * const PlainTextDocumentDidChangeSymbolsNotification;
extern NSString * const PlainTextDocumentDidChangeEditStatusNotification;
extern NSString * const PlainTextDocumentParticipantsDidChangeNotification;
extern NSString * const PlainTextDocumentUserDidChangeSelectionNotification;
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
        
    NSDictionary *I_blockeditAttributes;
    
    NSArray *I_symbolArray;
    NSMenu *I_symbolPopUpMenu;
    NSMenu *I_symbolPopUpMenuSorted;
    NSTimer *I_symbolUpdateTimer;
    
    NSTimer *I_webPreviewDelayedRefreshTimer;
    
    DocumentProxyWindowController *I_documentProxyWindowController;
    
    WebPreviewWindowController *I_webPreviewWindowController;
    NSMutableArray *I_rangesToInvalidate;
    NSMutableArray *I_findAllControllers;
}

- (id)initWithSession:(TCMMMSession *)aSession;

- (void)makeProxyWindowController;
- (void)killProxyWindowController;
- (void)proxyWindowWillClose;

- (void)setSession:(TCMMMSession *)aSession;
- (TCMMMSession *)session;

- (NSTextStorage *)textStorage;

- (DocumentMode *)documentMode;
- (void)setDocumentMode:(DocumentMode *)aDocumentMode;

- (BOOL)isAnnounced;
- (void)setIsAnnounced:(BOOL)aFlag;
- (IBAction)toggleIsAnnounced:(id)aSender;

- (NSArray *)plainTextEditors;

- (NSString *)lineEndingString;
- (LineEnding)lineEnding;
- (void)setLineEnding:(LineEnding)newLineEnding;

- (NSFont *)fontWithTrait:(NSFontTraitMask)aFontTrait;
- (NSDictionary *)typingAttributes;
- (NSDictionary *)plainTextAttributes;
- (NSDictionary *)blockeditAttributes;
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

- (IBAction)convertLineEndings:(id)aSender;
- (IBAction)chooseLineEndings:(id)aSender;

- (NSRange)rangeOfPrevious:(BOOL)aPrevious symbolForRange:(NSRange)aRange;
- (NSRange)rangeOfPrevious:(BOOL)aPrevious changeForRange:(NSRange)aRange;

- (void)invalidateLayoutForRange:(NSRange)aRange;
- (void)updateSymbolTable;
- (void)triggerUpdateSymbolTableTimer;
- (NSMenu *)symbolPopUpMenuForView:(NSTextView *)aTextView sorted:(BOOL)aSorted;
- (int)selectedSymbolForRange:(NSRange)aRange;
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

#pragma mark -
#pragma mark ### Session Interaction ###

- (void)sendInitialUserState;
- (NSDictionary *)sessionInformation;
- (void)sessionDidAcceptJoinRequest:(TCMMMSession *)aSession;
- (void)session:(TCMMMSession *)aSession didReceiveSessionInformation:(NSDictionary *)aSessionInformation;
- (void)handleOperation:(TCMMMOperation *)aOperation;


- (void)addFindAllController:(FindAllController *)aController;


@end
