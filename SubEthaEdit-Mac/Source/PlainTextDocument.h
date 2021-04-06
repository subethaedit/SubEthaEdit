//  PlainTextDocument.h
//  SubEthaEdit
//
//  Created by Martin Ott on Tue Feb 24 2004.


#import <Cocoa/Cocoa.h>

@class PlainTextDocument;

#import "EncodingManager.h"
#import "TCMMMSession.h"
#import "SEEDocumentCreationFlags.h"
#import "UndoManager.h"
#import "FoldableTextStorage.h"
#import "FullTextStorage.h"
#import "SEEDocumentController.h"
#import "SEEAlertRecipe.h"

enum {
    UnknownStringEncoding = NoStringEncoding,
    SmallestCustomStringEncoding = 0xFFFFFFF0
};


@class FoldableTextStorage, TCMMMSession, TCMMMOperation, DocumentMode, EncodingPopUpButton, 
       PlainTextWindowController, SEEWebPreviewViewController,
       DocumentProxyWindowController, FindAllController, UndoManager, TextOperation, TCMMMLoggingState, FontForwardingTextField, PlainTextEditor;

extern NSString * const PlainTextDocumentSessionWillChangeNotification;
extern NSString * const PlainTextDocumentSessionDidChangeNotification;

extern NSString * const PlainTextDocumentDidChangeTextStorageNotification;
extern NSString * const PlainTextDocumentDidChangeSymbolsNotification;
extern NSString * const PlainTextDocumentDidChangeEditStatusNotification;
extern NSString * const PlainTextDocumentParticipantsDataDidChangeNotification;
extern NSString * const PlainTextDocumentUserDidChangeSelectionNotification;
extern NSString * const PlainTextDocumentDefaultParagraphStyleDidChangeNotification;
extern NSString * const PlainTextDocumentDidChangeDisplayNameNotification;
extern NSString * const PlainTextDocumentDidChangeDocumentModeNotification;

extern NSString * const SEEWrittenByUserIDAttributeName;
extern NSString * const SEEChangedByUserIDAttributeName;

extern NSString * const PlainTextDocumentDidSaveNotification;
extern NSString * const PlainTextDocumentDidSaveShouldReloadWebPreviewNotification;


@interface PlainTextDocument : NSDocument <SEEDocument, NSTextViewDelegate, NSTextStorageDelegate, NSOpenSavePanelDelegate, NSSharingServicePickerDelegate, NSSharingServiceDelegate>
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
        BOOL showInconsistentIndentation; // Editor
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
        BOOL syntaxHighlightingIsSuspended;
        BOOL textDidChangeSinceLastSyntaxHighlighting;
        BOOL hasUTF8BOM;
        BOOL isSEEText;
        BOOL isAutosavingForStateRestore;
        BOOL keepUndoManagerOnZeroWindowControllers;
        BOOL isSettingFileURL;
		BOOL isPreparedForTermination;
    } I_flags;
    int I_tabWidth;
    DocumentMode  *I_documentMode;
    FoldableTextStorage *I_textStorage;
    
	NSUInteger _currentBracketMatchingBracketPosition;
	
    NSFont *I_plainFont;
    NSFont *I_boldFont;
    NSFont *I_italicFont;
    NSFont *I_boldItalicFont;
    
    NSMutableDictionary *I_styleCacheDictionary;
    NSDictionary *I_plainTextAttributes;
    NSDictionary *I_typingAttributes;
	NSMutableDictionary *I_adjustedTypingAttributes;
    NSParagraphStyle *I_defaultParagraphStyle;
    NSDictionary *I_fileAttributes;
    NSDictionary *I_ODBParameters;
    NSString *I_jobDescription;
    NSString *I_temporaryDisplayName;
    NSString *I_directoryForSavePanel;
    
    NSSaveOperationType I_lastSaveOperation;
    NSStringEncoding I_encodingFromLastRunSaveToOperation;
    
    NSColor *I_documentBackgroundColor;
    NSColor *I_documentForegroundColor;
    
    int I_lineEnding;
    NSString *I_lineEndingString;
            
    NSDictionary *I_blockeditAttributes;
    NSTextView   *I_blockeditTextView;

	NSString *I_lastTextShouldChangeReplacementString;
	NSRange   I_lastTextShouldChangeReplacementRange;
    
    NSArray *I_symbolArray;
    NSMenu *I_symbolPopUpMenu;
    NSMenu *I_symbolPopUpMenuSorted;
    NSTimer *I_symbolUpdateTimer;
    
    NSTimer *I_webPreviewDelayedRefreshTimer;
    
    DocumentProxyWindowController *I_documentProxyWindowController;
    
    NSMutableArray *I_rangesToInvalidate;
    NSMutableArray *I_findAllControllers;
    
    UndoManager *I_undoManager;
    TextOperation *I_lastRegisteredUndoOperation;
    
    NSMutableDictionary *I_printOptions;

    NSMutableArray <TCMMMOperation *> *I_currentTextOperations;
    
    NSDictionary *I_stateDictionaryFromLoading;
    
    #ifndef TCM_NO_DEBUG
        NSMutableString *_readFromURLDebugInformation;
    #endif
}

@property (readwrite, strong) IBOutlet NSWindow *O_exportSheet;
@property (readwrite, strong) IBOutlet NSObjectController *O_exportSheetController;
@property (nonatomic, strong) NSMutableArray *persistentDocumentScopedBookmarkURLs;

@property (nonatomic, strong) SEEDocumentCreationFlags *attachedCreationFlags;

/*!
	@return returns a suitable display string with the additional path components set by the AdditionalShownPathComponentsPreferenceKey - or nil if the array was nil or empty.
 */
+ (NSString *)displayStringWithAdditionalPathComponentsForPathComponents:(NSArray *)aPathComponentsArray;

+ (PlainTextDocument *)transientDocument;

+ (NSDictionary *)parseOpenDocumentEvent:(NSAppleEventDescriptor *)eventDesc;

- (NSImage *)documentIcon;

- (instancetype)initWithSession:(TCMMMSession *)aSession;

- (IBAction)newView:(id)aSender;
//- (IBAction)goIntoBundles:(id)sender;
//- (IBAction)showHiddenFiles:(id)sender;
//- (IBAction)selectFileFormat:(id)aSender;
- (BOOL)isProxyDocument;
- (BOOL)isPendingInvitation;
- (void)makeProxyWindowController;
- (void)killProxyWindowController;
- (void)proxyWindowWillClose;
- (void)updateProxyWindow;
- (DocumentProxyWindowController *)proxyWindowController;

- (void)setSession:(TCMMMSession *)aSession;
- (TCMMMSession *)session;

@property (nonatomic, readonly) NSString *fullTextContentString;
- (FoldableTextStorage *)textStorage;

- (void)fillScriptsIntoContextMenu:(NSMenu *)aMenu;
- (void)adjustModeMenu;
- (DocumentMode *)documentMode;
- (void)setDocumentMode:(DocumentMode *)aDocumentMode;
- (void)takeStyleSettingsFromDocumentMode;
- (void)takeEditSettingsFromDocumentMode;


- (BOOL)isAnnounced;
- (void)setIsAnnounced:(BOOL)aFlag;
- (IBAction)toggleIsAnnounced:(id)aSender;
- (IBAction)toggleIsAnnouncedOnAllDocuments:(id)aSender;
- (IBAction)inviteUsersToDocumentViaSharingService:(id)aSender;
- (BOOL)invitePeopleFromPasteboard:(NSPasteboard *)aPasteboard;
- (IBAction)changePendingUsersAccess:(id)aSender;
- (IBAction)changePendingUsersAccessOnAllDocuments:(id)aSender;

- (BOOL)isEditable;
- (void)validateEditability;

- (PlainTextEditor *)activePlainTextEditor;
@property (nonatomic, readonly) NSArray *plainTextEditors;
@property (nonatomic, readonly) NSArray *findAllControllers;

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

- (BOOL)canBeConvertedToEncoding:(NSStringEncoding)encoding;
- (NSStringEncoding)fileEncoding;
- (void)setFileEncoding:(NSUInteger)anEncoding;
- (void)setFileEncodingUndoable:(NSUInteger)anEncoding;
- (void)setAttributedStringUndoable:(NSAttributedString *)aString;
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

- (void)setKeepUndoManagerOnZeroWindowControllers:(BOOL)aFlag;
- (BOOL)keepUndoManagerOnZeroWindowControllers;


- (PlainTextWindowController *)topmostWindowController;
- (void)gotoLine:(unsigned)aLine;
//- (void)gotoLine:(unsigned)aLine orderFront:(BOOL)aFlag;
- (void)selectRange:(NSRange)aRange;
- (void)selectRangeInBackground:(NSRange)aRange;
- (void)handleParsedOpenDocumentEvent:(NSDictionary<NSString *, NSDictionary *> *)parsedEvent;

- (void)convertLineEndingsToLineEnding:(LineEnding)lineEnding;
- (IBAction)convertLineEndings:(id)aSender;
- (IBAction)chooseLineEndings:(id)aSender;
- (IBAction)reindentSelection:(id)aSender;

- (NSRange)rangeOfPrevious:(BOOL)aPrevious symbolForRange:(NSRange)aRange;
- (NSRange)rangeOfPrevious:(BOOL)aPrevious changeForRange:(NSRange)aRange;

- (void)invalidateLayoutForRange:(NSRange)aRange;
- (void)updateSymbolTable;
- (void)triggerUpdateSymbolTableTimer;
- (NSMenu *)symbolPopUpMenuForView:(NSTextView *)aTextView sorted:(BOOL)aSorted;
- (int)selectedSymbolForRange:(NSRange)aRange;

- (NSURL *)documentURL;
- (NSURL *)documentURLForGroup:(NSString *)aGroup;

- (void)autosaveForStateRestore;

- (UndoManager *)documentUndoManager;
- (NSUndoManager *)TCM_undoManagerToUse;

- (NSString *)preparedDisplayName;

- (void)setPlainTextEditorsShowChangeMarksOnInvitation;
- (NSDictionary *)textStorageDictionaryRepresentation;

- (NSEnumerator *)matchEnumeratorForAutocompleteString:(NSString *)aPartialWord;

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
- (BOOL)showInconsistentIndentation;
- (void)setShowInconsistentIndentation:(BOOL)aFlag;
- (BOOL)showsGutter;
- (void)setShowsGutter:(BOOL)aFlag;
- (BOOL)showsMatchingBrackets;
- (void)setShowsMatchingBrackets:(BOOL)aFlag;
- (BOOL)showsChangeMarks;
- (void)setShowsChangeMarks:(BOOL)aFlag;
- (IBAction)clearChangeMarks:(id)aSender;
- (IBAction)restoreChangeMarks:(id)aSender;
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
- (void)takeSpellCheckingSettingsFromEditor:(PlainTextEditor *)anEditor;

- (BOOL)isReceivingContent;
- (void)setShouldSelectModeOnSave:(BOOL)aFlag;
- (BOOL)shouldSelectModeOnSave;
- (void)setShouldChangeExtensionOnModeChange:(BOOL)aFlag;
- (BOOL)shouldChangeExtensionOnModeChange;
- (void)resizeAccordingToDocumentMode;

- (BOOL)didPauseBecauseOfMarkedText;

- (BOOL)isPreparedForTermination;
- (void)setPreparedForTermination:(BOOL)aFlag;

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
- (NSMutableDictionary *)printOptions;
- (void)setPrintOptions:(NSMutableDictionary *)aPrintOptions;

#pragma mark - Font handling
- (IBAction)changeFont:(id)aSender;

#pragma mark -
#pragma mark ### Session Interaction ###

- (NSDictionary *)documentState;
- (NSData *)stateData;

- (NSDictionary *)sessionInformation;
- (void)takeSettingsFromSessionInformation:(NSDictionary *)aSessionInformation;
- (void)takeSettingsFromDocumentState:(NSDictionary *)aDocumentState;

- (NSSet *)allUserIDs;
- (NSSet *)userIDsOfContributors;
- (void)sendInitialUserStateViaMMState:(TCMMMState *)aState;;
- (void)sessionDidAcceptJoinRequest:(TCMMMSession *)aSession;
- (void)session:(TCMMMSession *)aSession didReceiveSessionInformation:(NSDictionary *)aSessionInformation;
- (BOOL)handleOperation:(TCMMMOperation *)aOperation;
- (void)undoManagerDidPerformUndoGroupWithLastOperation:(TextOperation *)aOperation;

- (void)addFindAllController:(FindAllController *)aController;
- (void)removeFindAllController:(FindAllController *)aController;

- (void)setContentByDictionaryRepresentation:(NSDictionary *)aRepresentation;

- (NSBitmapImageRep *)thumbnailBitmapRepresentation;

#pragma mark - Alert Handling

@property (nonatomic, readonly) BOOL hasAlerts;

/**
 Funnel method do display alerts on a document.
 
 @param recipe alert recipe to show or enqueue
 @return YES if enqueued, NO if not. E.g. because of coalescing.
 */
- (BOOL)showOrEnqueueAlertRecipe:(SEEAlertRecipe *)recipe;

/**
 Succeeds if the alert can be shown immediatly.
 If not NSBeeps() and shows the window with the blocking alert.

 @param recipe alert recipe to show
 @return YES if shown/enqueued. NO otherwise.
 */
- (BOOL)presentAlertRecipeOrShowExistingAlert:(SEEAlertRecipe *)recipe;

/**
 Shows the frontmost window of this document that has an alert attached.

 @return YES if it did show a window, NO if there wasn't a window with an attached sheet.
 */
- (BOOL)showExistingAlertIfAny;

- (void)showOrEnqueueInformationWithMessage:(NSString *)message details:(NSString *)details;
- (void)dismissSafeToDismissSheetsIfAny;

- (void)presentPromotionAlertForTextView:(NSTextView *)textView insertionString:(NSString *)insertionString affectedRange:(NSRange)affectedRange;
- (void)conditionallyEditAnyway:(void (^)(PlainTextDocument *))completionHandler;


@end

#pragma mark -

typedef enum {
    kAccessOptionReadWrite = 'RdWr',
    kAccessOptionReadOnly = 'RdOn',
    kAccessOptionLocked = 'Lock'
} AccessOptions;

@interface PlainTextDocument (PlainTextDocumentScriptingAdditions)
- (void)handleClearChangeMarksCommand:(NSScriptCommand *)command;
- (void)handleShowWebPreviewCommand:(NSScriptCommand *)command;
- (void)replaceTextInRange:(NSRange)range withString:(NSString *)string;
- (NSString *)encoding;
- (void)setEncoding:(NSString *)name;
- (AccessOptions)accessOption;
- (void)setAccessOption:(AccessOptions)option;
- (NSString *)announcementURL;
- (FoldableTextStorage *)scriptedPlainContents;
- (void)setScriptedPlainContents:(id)value;
- (id)scriptSelection;
- (void)setScriptSelection:(id)selection;

// Deprecated, but needed for compatibility with see tool.
- (NSString *)mode;
- (void)setMode:(NSString *)identifier;

//- (NSRange)textView:(NSTextView *)aTextView
//           willChangeSelectionFromCharacterRange:(NSRange)aOldSelectedCharRange
//                                toCharacterRange:(NSRange)aNewSelectedCharRange;

@end
