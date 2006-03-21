//
//  PlainTextDocument.h
//  SubEthaEdit
//
//  Created by Martin Ott on Tue Feb 24 2004.
//  Copyright (c) 2004-2006 TheCodingMonkeys. All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import <Security/Security.h>
#import "EncodingManager.h"

enum {
    UnknownStringEncoding = NoStringEncoding,
    SmallestCustomStringEncoding = 0xFFFFFFF0
};



@class TCMMMSession, TCMMMOperation, DocumentMode, EncodingPopUpButton, 
       PlainTextWindowController, WebPreviewWindowController,
       DocumentProxyWindowController, FindAllController, UndoManager, TextOperation;

extern NSString * const PlainTextDocumentSessionWillChangeNotification;
extern NSString * const PlainTextDocumentSessionDidChangeNotification;

extern NSString * const PlainTextDocumentDidChangeTextStorageNotification;
extern NSString * const PlainTextDocumentDidChangeSymbolsNotification;
extern NSString * const PlainTextDocumentDidChangeEditStatusNotification;
extern NSString * const PlainTextDocumentParticipantsDataDidChangeNotification;
extern NSString * const PlainTextDocumentUserDidChangeSelectionNotification;
extern NSString * const PlainTextDocumentDefaultParagraphStyleDidChangeNotification;
extern NSString * const PlainTextDocumentDidChangeDisplayNameNotification;

extern NSString * const WrittenByUserIDAttributeName;
extern NSString * const ChangedByUserIDAttributeName;
extern NSString * const PlainTextDocumentDidSaveNotification;

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
        BOOL isContinuousSpellCheckingEnabled; // Editor
        BOOL keepDocumentVersion;
        BOOL isFileWritable;
        BOOL editAnyway;
        BOOL isReceivingContent;
        BOOL isReadingFile;
        BOOL didPauseBecauseOfMarkedText;
        BOOL shouldChangeChangeCount;
        BOOL shouldChangeExtensionOnModeChange;
        BOOL shouldSelectModeOnSave;
        BOOL isHandlingUndoManually;
        BOOL isWaiting;
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
    NSMutableDictionary *I_styleCacheDictionary;
    NSDictionary *I_plainTextAttributes;
    NSDictionary *I_typingAttributes;
    NSParagraphStyle *I_defaultParagraphStyle;
    NSDictionary *I_fileAttributes;
    NSDictionary *I_ODBParameters;
    NSString *I_jobDescription;
    NSString *I_temporaryDisplayName;
    NSString *I_directoryForSavePanel;
    
    IBOutlet NSView *O_savePanelAccessoryView;
    IBOutlet NSView *O_savePanelAccessoryView2;
    IBOutlet NSButton *O_goIntoBundlesCheckbox;
    IBOutlet NSButton *O_goIntoBundlesCheckbox2;
    IBOutlet NSButton *O_showHiddenFilesCheckbox;
    IBOutlet NSButton *O_showHiddenFilesCheckbox2;
    IBOutlet EncodingPopUpButton *O_encodingPopUpButton;
    NSSavePanel *I_savePanel;
    NSSaveOperationType I_lastSaveOperation;
    NSStringEncoding I_encodingFromLastRunSaveToOperation;
    
    NSColor *I_documentBackgroundColor;
    NSColor *I_documentForegroundColor;
    
    int I_lineEnding;
    NSString *I_lineEndingString;
    
    struct {
        int numberOfBrackets;
        unichar *closingBracketsArray;
        unichar *openingBracketsArray;
        unsigned matchingBracketPosition;
    } I_bracketMatching;
        
    NSDictionary *I_blockeditAttributes;
    NSTextView   *I_blockeditTextView;
    
    NSArray *I_symbolArray;
    NSMenu *I_symbolPopUpMenu;
    NSMenu *I_symbolPopUpMenuSorted;
    NSTimer *I_symbolUpdateTimer;
    
    NSTimer *I_webPreviewDelayedRefreshTimer;
    
    DocumentProxyWindowController *I_documentProxyWindowController;
    
    WebPreviewWindowController *I_webPreviewWindowController;
    NSMutableArray *I_rangesToInvalidate;
    NSMutableArray *I_findAllControllers;
    
    UndoManager *I_undoManager;
    TextOperation *I_lastRegisteredUndoOperation;
    
    NSMutableDictionary *I_printOptions;
    // Print nib
    IBOutlet NSView *O_printOptionView;
    IBOutlet NSObjectController *O_printOptionController;
    BOOL I_printOperationIsRunning;

    // export nib
    IBOutlet NSWindow *O_exportSheet;
    IBOutlet NSObjectController *O_exportSheetController;
    
    AuthorizationRef I_authRef;
}

- (id)initWithSession:(TCMMMSession *)aSession;

- (IBAction)newView:(id)aSender;
- (IBAction)goIntoBundles:(id)sender;
- (IBAction)showHiddenFiles:(id)sender;

- (BOOL)isProxyDocument;
- (BOOL)isPendingInvitation;
- (void)makeProxyWindowController;
- (void)killProxyWindowController;
- (void)proxyWindowWillClose;
- (void)updateProxyWindow;

- (void)setSession:(TCMMMSession *)aSession;
- (TCMMMSession *)session;

- (NSTextStorage *)textStorage;

- (DocumentMode *)documentMode;
- (void)setDocumentMode:(DocumentMode *)aDocumentMode;
- (void)takeStyleSettingsFromDocumentMode;
- (void)takeEditSettingsFromDocumentMode;


- (BOOL)isAnnounced;
- (void)setIsAnnounced:(BOOL)aFlag;
- (IBAction)toggleIsAnnounced:(id)aSender;
- (BOOL)isEditable;
- (void)validateEditability;

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
- (NSColor *)documentBackgroundColor;
- (void)setDocumentBackgroundColor:(NSColor *)aColor;
- (NSColor *)documentForegroundColor;
- (void)setDocumentForegroundColor:(NSColor *)aColor;

- (unsigned int)fileEncoding;
- (void)setFileEncoding:(unsigned int)anEncoding;
- (NSDictionary *)fileAttributes;
- (void)setFileAttributes:(NSDictionary *)attributes;
- (NSDictionary *)ODBParameters;
- (void)setODBParameters:(NSDictionary *)aDictionary;
- (BOOL)isWaiting;
- (void)setIsWaiting:(BOOL)aFlag;
- (NSString *)jobDescription;
- (void)setJobDescription:(NSString *)aString;
- (NSString *)temporaryDisplayName;
- (void)setTemporaryDisplayName:(NSString *)name;
- (void)setDirectoryForSavePanel:(NSString *)path;
- (NSString *)directoryForSavePanel;

- (void)setHighlightsSyntax:(BOOL)aFlag;
- (BOOL)highlightsSyntax;

- (PlainTextWindowController *)topmostWindowController;
- (void)gotoLine:(unsigned)aLine;
- (void)gotoLine:(unsigned)aLine orderFront:(BOOL)aFlag;
- (void)selectRange:(NSRange)aRange;
- (void)selectRangeInBackground:(NSRange)aRange;
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

- (NSURL *)documentURL;

- (UndoManager *)documentUndoManager;

- (NSString *)preparedDisplayName;

#pragma mark -
#pragma mark ### Flag Accessors ###
- (BOOL)isHandlingUndoManually;
- (void)setIsHandlingUndoManually:(BOOL)aFlag;
- (BOOL)shouldChangeChangeCount;
- (void)setShouldChangeChangeCount:(BOOL)aFlag;

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
- (IBAction)clearChangeMarks:(id)aSender;
- (BOOL)indentsNewLines;
- (void)setIndentsNewLines:(BOOL)aFlag;
- (BOOL)showsTopStatusBar;
- (void)setShowsTopStatusBar:(BOOL)aFlag;
- (BOOL)showsBottomStatusBar;
- (BOOL)isRemotelyEditingTextStorage;
- (void)setShowsBottomStatusBar:(BOOL)aFlag;
- (BOOL)keepDocumentVersion;
- (void)setKeepDocumentVersion:(BOOL)aFlag;
- (BOOL)isFileWritable;
- (void)setIsFileWritable:(BOOL)aFlag;
- (BOOL)editAnyway;
- (void)setEditAnyway:(BOOL)aFlag;
- (BOOL)isContinuousSpellCheckingEnabled;
- (void)setContinuousSpellCheckingEnabled:(BOOL)aFlag;
- (BOOL)isReceivingContent;
- (void)setShouldSelectModeOnSave:(BOOL)aFlag;
- (BOOL)shouldSelectModeOnSave;
- (void)setShouldChangeExtensionOnModeChange:(BOOL)aFlag;
- (BOOL)shouldChangeExtensionOnModeChange;
- (void)resizeAccordingToDocumentMode;

#pragma mark -
#pragma mark ### Syntax Highlighting ###

- (IBAction)toggleSyntaxHighlighting:(id)aSender;
- (void)highlightSyntaxInRange:(NSRange)aRange;
- (void)performHighlightSyntax;
- (void)highlightSyntaxLoop;

#pragma mark ### Export ###

- (IBAction)exportDocument:(id)aSender;
- (IBAction)cancelExport:(id)aSender;
- (IBAction)continueExport:(id)aSender;

#pragma mark ### Printing ###
- (IBAction)changeFontViaPanel:(id)sender;
- (NSMutableDictionary *)printOptions;
- (void)setPrintOptions:(NSDictionary *)aPrintOptions;

#pragma mark -
#pragma mark ### Session Interaction ###

- (NSSet *)userIDsOfContributors;
- (void)sendInitialUserState;
- (NSDictionary *)sessionInformation;
- (void)sessionDidAcceptJoinRequest:(TCMMMSession *)aSession;
- (void)session:(TCMMMSession *)aSession didReceiveSessionInformation:(NSDictionary *)aSessionInformation;
- (void)handleOperation:(TCMMMOperation *)aOperation;


- (void)addFindAllController:(FindAllController *)aController;
- (void)removeFindAllController:(FindAllController *)aController;

@end

#pragma mark -

typedef enum {
    kAccessOptionReadWrite = 'RdWr',
    kAccessOptionReadOnly = 'RdOn',
    kAccessOptionLocked = 'Lock'
} AccessOptions;

@interface PlainTextDocument (PlainTextDocumentScriptingAdditions)

- (NSString *)encoding;
- (void)setEncoding:(NSString *)name;
- (AccessOptions)accessOption;
- (void)setAccessOption:(AccessOptions)option;
- (NSString *)announcementURL;
- (NSTextStorage *)text;
- (void)setText:(NSString *)aString;
- (id)selection;
- (void)setSelection:(id)selection;

// Deprecated, but needed for compatibility with see tool.
- (NSString *)mode;
- (void)setMode:(NSString *)identifier;

@end