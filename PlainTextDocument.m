//
//  PlainTextDocument.m
//  SubEthaEdit
//
//  Created by Martin Ott on Tue Feb 24 2004.
//  Copyright (c) 2004-2007 TheCodingMonkeys. All rights reserved.
// 

#import <Carbon/Carbon.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <objc/objc-runtime.h>			// for objc_msgSend

#import <PSMTabBarControl/PSMTabBarControl.h>
#import "TCMMillionMonkeys/TCMMillionMonkeys.h"
#import "PlainTextEditor.h"
#import "DocumentController.h"
#import "PlainTextDocument.h"
#import "PlainTextWindowController.h"
#import "PlainTextWindowControllerTabContext.h"
#import "WebPreviewWindowController.h"
#import "DocumentProxyWindowController.h"
#import "UndoManager.h"
#import "TCMMMUserSEEAdditions.h"
#import "PrintPreferences.h"
#import "AppController.h"
#import "NSSavePanelTCMAdditions.h"
#import "EncodingDoctorDialog.h"
#import "NSMutableAttributedStringSEEAdditions.h"

#import "DocumentModeManager.h"
#import "DocumentMode.h"
#import "SyntaxHighlighter.h"
#import "SymbolTableEntry.h"

#import "TextStorage.h"
#import "LayoutManager.h"
#import "TextView.h"
#import "EncodingManager.h"
#import "TextOperation.h"
#import "SelectionOperation.h"
#import "ODBEditorSuite.h"
#import "GeneralPreferences.h"

#import "FindAllController.h"
#import "MultiPagePrintView.h"

#import "MoreUNIX.h"
#import "MoreSecurity.h"
#import "MoreCFQ.h"
#import <fcntl.h>
#import <sys/param.h>
#import <sys/stat.h>
#import <string.h>
#import <pwd.h>
#import <grp.h>

#import "ScriptTextSelection.h"
#import "ScriptWrapper.h"
#import "NSMenuTCMAdditions.h"

#import "TCMMMLoggingState.h"
#import "BacktracingException.h"

#import "UKXattrMetadataStore.h"

#import <UniversalDetector/UniversalDetector.h>

#pragma options align=mac68k
struct SelectionRange
{
    short unused1; // 0 (not used)
    short lineNum; // line to select (<0 to specify range)
    long startRange; // start of selection range (if line < 0)
    long endRange; // end of selection range (if line < 0)
    long unused2; // 0 (not used)
    long theDate; // modification date/time
};
#pragma options align=reset


static PlainTextDocument *transientDocument = nil;
static NSRect transientDocumentWindowFrame;

static NSString * const PlainTextDocumentSyntaxColorizeNotification =
                      @"PlainTextDocumentSyntaxColorizeNotification";
static NSString * PlainTextDocumentInvalidateLayoutNotification =
                @"PlainTextDocumentInvalidateLayoutNotification";
NSString * const PlainTextDocumentSessionWillChangeNotification =
               @"PlainTextDocumentSessionWillChangeNotification";
NSString * const PlainTextDocumentSessionDidChangeNotification =
               @"PlainTextDocumentSessionDidChangeNotification";

NSString * const PlainTextDocumentRefreshWebPreviewNotification =
               @"PlainTextDocumentRefreshWebPreviewNotification";
NSString * const PlainTextDocumentDidChangeSymbolsNotification =
               @"PlainTextDocumentDidChangeSymbolsNotification";
NSString * const PlainTextDocumentDidChangeEditStatusNotification =
               @"PlainTextDocumentDidChangeEditStatusNotification";
NSString * const PlainTextDocumentParticipantsDataDidChangeNotification =
               @"PlainTextDocumentParticipantsDataDidChangeNotification";
NSString * const PlainTextDocumentUserDidChangeSelectionNotification =
               @"PlainTextDocumentUserDidChangeSelectionNotification";
NSString * const PlainTextDocumentDidChangeDisplayNameNotification =
               @"PlainTextDocumentDidChangeDisplayNameNotification";
NSString * const PlainTextDocumentDidChangeDocumentModeNotification =
               @"PlainTextDocumentDidChangeDocumentModeNotification";
NSString * const PlainTextDocumentDidChangeTextStorageNotification =
               @"PlainTextDocumentDidChangeTextStorageNotification";
NSString * const PlainTextDocumentDefaultParagraphStyleDidChangeNotification =
               @"PlainTextDocumentDefaultParagraphStyleDidChangeNotification";
NSString * const PlainTextDocumentDidSaveNotification =
               @"PlainTextDocumentDidSaveNotification";
NSString * const WrittenByUserIDAttributeName = @"WrittenByUserID";
NSString * const ChangedByUserIDAttributeName = @"ChangedByUserID";


// Something that's used by our override of -shouldCloseWindowController:delegate:shouldCloseSelector:contextInfo: down below.
@interface PlainTextDocumentShouldCloseContext : NSObject {
    @public
    PlainTextWindowController *windowController;
    id originalDelegate;
    SEL originalSelector;
    void *originalContext;
}
@end
@implementation PlainTextDocumentShouldCloseContext
@end


@interface PlainTextDocument (PlainTextDocumentPrivateAdditions)
- (NSTextView *)printableView;
- (void)TCM_invalidateDefaultParagraphStyle;
- (void)TCM_invalidateTextAttributes;
- (void)TCM_styleFonts;
- (void)TCM_initHelper;
- (void)TCM_sendPlainTextDocumentDidChangeDisplayNameNotification;
- (void)TCM_sendPlainTextDocumentDidChangeEditStatusNotification;
- (void)TCM_sendODBCloseEvent;
- (void)TCM_sendODBModifiedEvent;
- (BOOL)TCM_validateDocument;
- (NSDictionary *)TCM_propertiesOfCurrentSeeEvent;
- (BOOL)TCM_readFromURL:(NSURL *)fileName ofType:(NSString *)docType properties:(NSDictionary *)properties error:(NSError **)anError;
- (void)TCM_validateLineEndings;
@end

#pragma mark -

static NSDictionary *plainSymbolAttributes=nil, *italicSymbolAttributes=nil, *boldSymbolAttributes=nil, *boldItalicSymbolAttributes=nil;



@implementation PlainTextDocument

+ (void)initialize {
    NSFontManager *fontManager=[NSFontManager sharedFontManager];
    NSMutableDictionary *attributes=[NSMutableDictionary new];
    NSMutableParagraphStyle *style=[NSMutableParagraphStyle new];
    [style setLineBreakMode:NSLineBreakByTruncatingTail];
    [attributes setObject:style forKey:NSParagraphStyleAttributeName];
    NSFont *font=[NSFont menuFontOfSize:[NSFont systemFontSizeForControlSize:NSSmallControlSize]];
    NSFont *boldFont      =[fontManager convertFont:font toHaveTrait:NSBoldFontMask];
    NSFont *italicFont    =[fontManager convertFont:font toHaveTrait:NSItalicFontMask];
    NSFont *boldItalicFont=[fontManager convertFont:boldFont toHaveTrait:NSItalicFontMask];
    [attributes setObject:font forKey:NSFontAttributeName];
    plainSymbolAttributes=[attributes copy];

    [attributes setObject:boldFont forKey:NSFontAttributeName];
    boldSymbolAttributes=[attributes copy];

    [attributes setObject:italicFont forKey:NSFontAttributeName];
    if ([italicFont isEqualTo:font]) {
        [attributes setObject:[NSNumber numberWithFloat:.2] forKey:NSObliquenessAttributeName];
    }
    italicSymbolAttributes=[attributes copy];

    [attributes setObject:boldItalicFont forKey:NSFontAttributeName];
    boldItalicSymbolAttributes=[attributes copy];

    [attributes release];
    [style release];
}

+ (PlainTextDocument *)transientDocument
{
    return transientDocument;
}

- (void)setFileType:(NSString *)aString {
    [self willChangeValueForKey:@"documentIcon"];
    I_flags.isSEEText = [@"SEETextType" isEqualToString:aString];
    [super setFileType:aString];
    [self didChangeValueForKey:@"documentIcon"];
}

- (NSImage *)documentIcon {
    if ([@"SEETextType" isEqualToString:[self fileType]]) {
        return [NSImage imageNamed:@"seetext"];
    } else {
        return [NSImage imageNamed:@"SubEthaEditFiles"];
    }
}


static NSString *tempFileName(NSString *origPath) {
    static int sequenceNumber = 0;
    NSString *name;
    do {
        sequenceNumber++;
        name = [NSString stringWithFormat:@"_%d_%d_%d", [[NSProcessInfo processInfo] processIdentifier], (int)[NSDate timeIntervalSinceReferenceDate], sequenceNumber];
        if ([[origPath pathExtension] length] != 0) {
            name = [name stringByAppendingFormat:@".%@", [origPath pathExtension]];
        }
        name = [[origPath stringByDeletingPathExtension] stringByAppendingString:name];
    } while ([[NSFileManager defaultManager] fileExistsAtPath:name]);
    return name;
}

- (void)TCM_sendPlainTextDocumentDidChangeDisplayNameNotification {
    [self willChangeValueForKey:@"displayName"];
    [[NSNotificationQueue defaultQueue]
    enqueueNotification:[NSNotification notificationWithName:PlainTextDocumentDidChangeDisplayNameNotification object:self]
           postingStyle:NSPostWhenIdle
           coalesceMask:NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender
               forModes:[NSArray arrayWithObject:NSDefaultRunLoopMode]];
    [self didChangeValueForKey:@"displayName"];
}

- (void)TCM_sendPlainTextDocumentDidChangeEditStatusNotification {
    [[NSNotificationQueue defaultQueue]
    enqueueNotification:[NSNotification notificationWithName:PlainTextDocumentDidChangeEditStatusNotification object:self]
           postingStyle:NSPostWhenIdle
           coalesceMask:NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender
               forModes:nil];
}

- (void)TCM_textStorageLineEndingDidChange:(NSNotification *)aNotification {
     I_lineEndingString = [NSString lineEndingStringForLineEnding:[(TextStorage *)[self textStorage] lineEnding]];
    [self TCM_sendPlainTextDocumentDidChangeEditStatusNotification];
}

- (void)TCM_sendPlainTextDocumentParticipantsDataDidChangeNotification {
    [[NSNotificationQueue defaultQueue]
    enqueueNotification:[NSNotification notificationWithName:PlainTextDocumentParticipantsDataDidChangeNotification object:self]
           postingStyle:NSPostWhenIdle
           coalesceMask:NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender
               forModes:[NSArray arrayWithObject:NSDefaultRunLoopMode]];
}


- (void)TCM_styleFonts {
    [I_fonts.boldFont autorelease];
    [I_fonts.italicFont autorelease];
    [I_fonts.boldItalicFont autorelease];
    NSFontManager *manager=[NSFontManager sharedFontManager];
    I_fonts.boldFont       = [[manager convertFont:I_fonts.plainFont toHaveTrait:NSBoldFontMask] retain];
    I_fonts.italicFont     = [[manager convertFont:I_fonts.plainFont toHaveTrait:NSItalicFontMask] retain];
    I_fonts.boldItalicFont = [[manager convertFont:I_fonts.boldFont  toHaveTrait:NSItalicFontMask] retain];
}

- (void)TCM_initHelper {
    I_printOperationIsRunning=NO;
    I_flags.isAutosavingForRestart=NO;
    I_flags.isHandlingUndoManually=NO;
    I_flags.shouldSelectModeOnSave=YES;
    [self setUndoManager:nil];
    I_rangesToInvalidate = [NSMutableArray new];
    I_findAllControllers = [NSMutableArray new];
    NSNotificationCenter *center=[NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(TCM_webPreviewRefreshNotification:)
        name:PlainTextDocumentRefreshWebPreviewNotification object:self];
    [center addObserver:self selector:@selector(performHighlightSyntax)
        name:PlainTextDocumentSyntaxColorizeNotification object:self];
    [center addObserver:self
                                             selector:@selector(applicationDidBecomeActive:)
                                                 name:NSApplicationDidBecomeActiveNotification
                                               object:NSApp];
    [center addObserver:self selector:@selector(executeInvalidateLayout:)
        name:PlainTextDocumentInvalidateLayoutNotification object:self];

    [center addObserver:self selector:@selector(userWillLeaveSession:) name:TCMMMUserWillLeaveSessionNotification object:nil];

    [center addObserver:self selector:@selector(updateViewBecauseOfPreferences:) name:GeneralViewPreferencesDidChangeNotificiation object:nil];
    [center addObserver:self selector:@selector(printPreferencesDidChange:) name:PrintPreferencesDidChangeNotification object:nil];
    [center addObserver:self selector:@selector(applyStylePreferences:) name:DocumentModeApplyStylePreferencesNotification object:nil];
    [center addObserver:self selector:@selector(applyEditPreferences:) name:DocumentModeApplyEditPreferencesNotification object:nil];
    [center addObserver:self selector:@selector(scriptWrapperWillRunScriptNotification:) name:ScriptWrapperWillRunScriptNotification object:nil];
    [center addObserver:self selector:@selector(scriptWrapperDidRunScriptNotification:) name:ScriptWrapperDidRunScriptNotification object:nil];

    I_blockeditTextView=nil;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(TCM_textStorageLineEndingDidChange:) name:TextStorageLineEndingDidChange object:I_textStorage];

    // maybe put this into DocumentMode Setting
    NSString *bracketString=@"{[()]}";
    I_bracketMatching.numberOfBrackets=3;
    I_bracketMatching.openingBracketsArray=
        (unichar *)malloc(sizeof(unichar)*I_bracketMatching.numberOfBrackets);
    I_bracketMatching.closingBracketsArray=
        (unichar *)malloc(sizeof(unichar)*I_bracketMatching.numberOfBrackets);
    int i;
    for (i=0;i<I_bracketMatching.numberOfBrackets;i++) {
        I_bracketMatching.openingBracketsArray[i]=[bracketString characterAtIndex:i];
        I_bracketMatching.closingBracketsArray[i]=[bracketString characterAtIndex:(I_bracketMatching.numberOfBrackets*2-1)-i];
    }
    I_flags.showMatchingBrackets=YES;
    I_flags.didPauseBecauseOfMarkedText=NO;
    I_flags.hasUTF8BOM = NO;
    I_bracketMatching.matchingBracketPosition=NSNotFound;
    [self setKeepDocumentVersion:NO];
    [self setEditAnyway:NO];
    [self setIsFileWritable:YES];
    I_undoManager = [(UndoManager *)[UndoManager alloc] initWithDocument:self];
    [[[self session] loggingState] setInitialTextStorageDictionaryRepresentation:[self textStorageDictionaryRepresentation]];
    [[[self session] loggingState] handleOperation:[SelectionOperation selectionOperationWithRange:NSMakeRange(0,0) userID:[TCMMMUserManager myUserID]]];

}

- (void)updateViewBecauseOfPreferences:(NSNotification *)aNotification {
    NSEnumerator *wcs = [[self windowControllers] objectEnumerator];
    PlainTextWindowController *controller=nil;
    while ((controller=[wcs nextObject])) {
        [controller synchronizeWindowTitleWithDocumentName];
        [controller refreshDisplay];
    }
}

- (void)printPreferencesDidChange:(NSNotification *)aNotification {
    if ([[aNotification object] isEqualTo:[self documentMode]]) {
        [self setPrintOptions:[[self documentMode] defaultForKey:DocumentModePrintOptionsPreferenceKey]];
    }
}

- (void)applyStylePreferences {
    [self takeStyleSettingsFromDocumentMode];
    SyntaxHighlighter *highlighter=[[self documentMode] syntaxHighlighter];
    if (I_flags.highlightSyntax && highlighter) {
        [highlighter updateStylesInTextStorage:[self textStorage] ofDocument:self];
    } else {
        [I_textStorage addAttributes:[self plainTextAttributes]
                       range:NSMakeRange(0,[I_textStorage length])];
    }
}

- (void)applyStylePreferences:(NSNotification *)aNotification {
    DocumentMode *mode=[self documentMode];
    if ([[aNotification object] isEqual:mode] || 
        ([[aNotification object] isBaseMode] && 
         ([[mode defaultForKey:DocumentModeUseDefaultStylePreferenceKey] boolValue] ||
          [[mode defaultForKey:DocumentModeUseDefaultFontPreferenceKey]  boolValue]))) {
        [self applyStylePreferences];
    }
}

- (void)resizeAccordingToDocumentMode {
    NSEnumerator *controllers=[[self windowControllers] objectEnumerator];
    id controller=nil;
    while ((controller=[controllers nextObject])) {
        if ([controller isKindOfClass:[PlainTextWindowController class]] && ![(PlainTextWindowController *)controller hasManyDocuments]) {
            [(PlainTextWindowController *)controller 
                setSizeByColumns:[[[self documentMode] defaultForKey:DocumentModeColumnsPreferenceKey] intValue] 
                            rows:[[[self documentMode] defaultForKey:DocumentModeRowsPreferenceKey] intValue]];
        }
    }
}

- (void)applyEditPreferences:(NSNotification *)aNotification {
    DocumentMode *mode=[self documentMode];
    if ([[aNotification object] isEqual:mode] || 
        ([[aNotification object] isBaseMode] && 
         ([[mode defaultForKey:DocumentModeUseDefaultEditPreferenceKey] boolValue] ||
          [[mode defaultForKey:DocumentModeUseDefaultViewPreferenceKey] boolValue] ||
          [[mode defaultForKey:DocumentModeUseDefaultFilePreferenceKey] boolValue]))) {
        [self takeEditSettingsFromDocumentMode];
        [self resizeAccordingToDocumentMode];
    }
}


- (void)TCM_sendODBCloseEvent {
    DEBUGLOG(@"FileIOLogDomain", DetailedLogLevel, @"preparing ODB close event");
    DEBUGLOG(@"FileIOLogDomain", DetailedLogLevel, @"ODBParameters: %@", [[self ODBParameters] description]);

    if ([self ODBParameters] == nil || [[self ODBParameters] count] == 0)
        return;

    NSString *name = [self fileName];
    if (name == nil || [name length] == 0)
        return;

    OSErr err;
    NSURL *fileURL = [NSURL fileURLWithPath:name];
    FSRef fileRef;
    CFURLGetFSRef((CFURLRef)fileURL, &fileRef);
    FSSpec fsSpec;
    err = FSGetCatalogInfo(&fileRef, kFSCatInfoNone, NULL, NULL, &fsSpec, NULL);
    if (err == noErr) {
        NSData *signatureData = [[self ODBParameters] objectForKey:@"keyFileSender"];
        if (signatureData != nil) {
            NSAppleEventDescriptor *addressDescriptor = [NSAppleEventDescriptor descriptorWithDescriptorType:typeApplSignature bytes:[signatureData bytes] length:[signatureData length]];
            if (addressDescriptor != nil) {
                NSAppleEventDescriptor *appleEvent = [NSAppleEventDescriptor appleEventWithEventClass:kODBEditorSuite eventID:kAEClosedFile targetDescriptor:addressDescriptor returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID];
                NSAppleEventDescriptor *aliasDescriptor = [NSAppleEventDescriptor descriptorWithDescriptorType:typeFSS bytes:&fsSpec length:sizeof(fsSpec)];
                [appleEvent setParamDescriptor:aliasDescriptor forKeyword:keyDirectObject];
                NSAppleEventDescriptor *tokenDesc = [[self ODBParameters] objectForKey:@"keyFileSenderToken"];
                if (tokenDesc != nil) {
                    [appleEvent setParamDescriptor:tokenDesc forKeyword:keySenderToken];
                }
                if (appleEvent != nil) {
                    DEBUGLOG(@"FileIOLogDomain", DetailedLogLevel, @"Sending apple event");
                    AppleEvent reply;
                    err = AESendMessage ([appleEvent aeDesc], &reply, kAENoReply, kAEDefaultTimeout);
                }
            }
        }
    }
}

- (void)TCM_sendODBModifiedEvent {
    OSErr err;
    DEBUGLOG(@"FileIOLogDomain", DetailedLogLevel, @"preparing ODB modified event");
    DEBUGLOG(@"FileIOLogDomain", DetailedLogLevel, @"ODBParameters: %@", [[self ODBParameters] description]);
    if ([self ODBParameters] == nil || [[self ODBParameters] count] == 0)
        return;

    NSString *fileName = [self fileName];
    if (fileName == nil || [fileName length] == 0)
        return;


    NSURL *fileURL = [NSURL fileURLWithPath:fileName];
    FSRef fileRef;
    CFURLGetFSRef((CFURLRef)fileURL, &fileRef);
    FSSpec fsSpec;
    err = FSGetCatalogInfo(&fileRef, kFSCatInfoNone, NULL, NULL, &fsSpec, NULL);
    NSAppleEventDescriptor *directObjectDesc = nil;
    if (err == noErr) {
        directObjectDesc = [NSAppleEventDescriptor descriptorWithDescriptorType:typeFSS bytes:&fsSpec length:sizeof(fsSpec)];
    } else {
        DEBUGLOG(@"FileIOLogDomain", DetailedLogLevel, @"Failed to create fsspec");
        return;
    }

    if (directObjectDesc != nil) {
        NSData *signatureData = [[self ODBParameters] objectForKey:@"keyFileSender"];
        if (signatureData != nil) {
            NSAppleEventDescriptor *addressDescriptor = [NSAppleEventDescriptor descriptorWithDescriptorType:typeApplSignature bytes:[signatureData bytes] length:[signatureData length]];
            if (addressDescriptor != nil) {
                NSAppleEventDescriptor *appleEvent = [NSAppleEventDescriptor appleEventWithEventClass:kODBEditorSuite eventID:kAEModifiedFile targetDescriptor:addressDescriptor returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID];
                [appleEvent setParamDescriptor:directObjectDesc forKeyword:keyDirectObject];
                NSAppleEventDescriptor *tokenDesc = [[self ODBParameters] objectForKey:@"keyFileSenderToken"];
                if (tokenDesc != nil) {
                    [appleEvent setParamDescriptor:tokenDesc forKeyword:keySenderToken];
                }
                if (appleEvent != nil) {
                    DEBUGLOG(@"FileIOLogDomain", DetailedLogLevel, @"Sending apple event");
                    AppleEvent reply;
                    err = AESendMessage ([appleEvent aeDesc], &reply, kAENoReply, kAEDefaultTimeout);
                }
            }
        }
    } else {
        DEBUGLOG(@"FileIOLogDomain", DetailedLogLevel, @"Unable to generate direct parameter.");
    }
}

- (BOOL)TCM_charIsClosingBracket:(unichar)aPossibleBracket {
    int i;
    for (i=0;i<I_bracketMatching.numberOfBrackets;i++) {
        if (aPossibleBracket==I_bracketMatching.closingBracketsArray[i])
            return YES;
    }
    return NO;
}

- (BOOL)TCM_charIsOpeningBracket:(unichar)aPossibleBracket {
    int i;
    for (i=0;i<I_bracketMatching.numberOfBrackets;i++) {
        if (aPossibleBracket==I_bracketMatching.openingBracketsArray[i])
            return YES;
    }
    return NO;
}

// When inserting characters that character is unparse, hence untyped. Therefore we need to provide a best effort guestimate.
// Currently that is if before and after the current character are invalid states we return NO, else YES.
- (BOOL)TCM_validTypeForBracketBeforeAndAfterIndex:(unsigned)index {
	if (index==0) return YES;
	if (index+1>=[[self textStorage] length]) return YES;
	
	BOOL beforeIsInvalid = (([[[self textStorage] attribute:kSyntaxHighlightingTypeAttributeName atIndex:index-1 effectiveRange:nil] isEqualToString:@"comment"])||([[[self textStorage] attribute:kSyntaxHighlightingTypeAttributeName atIndex:index-1 effectiveRange:nil] isEqualToString:@"string"]));
	BOOL afterIsInvalid = (([[[self textStorage] attribute:kSyntaxHighlightingTypeAttributeName atIndex:index+1 effectiveRange:nil] isEqualToString:@"comment"])||([[[self textStorage] attribute:kSyntaxHighlightingTypeAttributeName atIndex:index+1 effectiveRange:nil] isEqualToString:@"string"]));
	if (beforeIsInvalid && afterIsInvalid) return NO;
	
	return YES;

}

- (BOOL)TCM_validTypeForBracketAtIndex:(unsigned)index {
//	NSLog(@"Index %d = %@",index, ((![[[self textStorage] attribute:kSyntaxHighlightingTypeAttributeName atIndex:index effectiveRange:nil] isEqualToString:@"comment"])&&(![[[self textStorage] attribute:kSyntaxHighlightingTypeAttributeName atIndex:index effectiveRange:nil] isEqualToString:@"string"]))?@"YES":@"NO");
	return ((![[[self textStorage] attribute:kSyntaxHighlightingTypeAttributeName atIndex:index effectiveRange:nil] isEqualToString:@"comment"])&&(![[[self textStorage] attribute:kSyntaxHighlightingTypeAttributeName atIndex:index effectiveRange:nil] isEqualToString:@"string"]));
}

- (BOOL)TCM_charIsBracket:(unichar)aPossibleBracket {
    return ([self TCM_charIsOpeningBracket:aPossibleBracket] ||
            [self TCM_charIsClosingBracket:aPossibleBracket]);
}

- (unichar)TCM_matchingBracketForChar:(unichar)bracket {
    int i;
    for (i=0;i<I_bracketMatching.numberOfBrackets;i++) {
        if (bracket==I_bracketMatching.openingBracketsArray[i])
            return I_bracketMatching.closingBracketsArray[i];
        if (bracket==I_bracketMatching.closingBracketsArray[i])
            return I_bracketMatching.openingBracketsArray[i];
    }
    return (unichar)0;
}


- (void)executeInvalidateLayout:(NSNotification *)aNotification {
    TextStorage *textStorage=(TextStorage *)[self textStorage];
    NSRange wholeRange=NSMakeRange(0,[textStorage length]);
    NSEnumerator *rangeValues=[I_rangesToInvalidate objectEnumerator];
    NSValue *rangeValue=nil;
    [textStorage beginEditing];
    while ((rangeValue=[rangeValues nextObject])) {
        NSRange changeRange=NSIntersectionRange(wholeRange,[rangeValue rangeValue]);
        if (changeRange.length!=0) {
            [textStorage edited:NSTextStorageEditedAttributes range:changeRange changeInLength:0];
        }
    }
    [textStorage endEditing];
    [I_rangesToInvalidate removeAllObjects];
}

- (void)invalidateLayoutForRange:(NSRange)aRange {
    TextStorage *textStorage=(TextStorage *)[self textStorage];
    NSRange wholeRange=NSMakeRange(0,[textStorage length]);
    if (aRange.length==0) {
        if (aRange.location>0) {
            aRange.location-=1;
            aRange.length=1;
        } else {
            if (wholeRange.length>0) {
                aRange.length=1;
            }
        }
    }

    [I_rangesToInvalidate addObject:[NSValue valueWithRange:aRange]];
    [[NSNotificationQueue defaultQueue]
        enqueueNotification:[NSNotification notificationWithName:PlainTextDocumentInvalidateLayoutNotification object:self]
               postingStyle:NSPostASAP
               coalesceMask:NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender
                   forModes:[NSArray arrayWithObject:NSDefaultRunLoopMode]];
}

- (void)updateSymbolTable {

    DocumentMode *mode=[self documentMode];
    [I_symbolArray release];
    I_symbolArray=nil;
    if ([mode hasSymbols]) {
        I_symbolArray = [[mode symbolArrayForTextStorage:[self textStorage]] copy];
		
		// If symbolArrayForTextStorage: return nil the document is not yet ready for symbol recognition.
		if (!I_symbolArray) {
			[self performSelector:@selector(triggerUpdateSymbolTableTimer) withObject:nil afterDelay:0.1];
			return;
		}
		
		
        [I_symbolPopUpMenu release];
        I_symbolPopUpMenu = [NSMenu new];
        [I_symbolPopUpMenuSorted release];
        I_symbolPopUpMenuSorted = [NSMenu new];

        NSEnumerator *symbolTableEntries=[I_symbolArray objectEnumerator];
        NSMenuItem *prototypeMenuItem=[[NSMenuItem alloc] initWithTitle:@""
                                                                 action:@selector(chooseGotoSymbolMenuItem:)
                                                          keyEquivalent:@""];
        [prototypeMenuItem setTarget:nil];
        NSMutableArray *itemsToSort=[NSMutableArray array];

        SymbolTableEntry *entry;
        int i=0;
        NSMenuItem *menuItem;
        while ((entry=[symbolTableEntries nextObject])) {
            if ([entry isSeparator]) {
                [I_symbolPopUpMenu addItem:[NSMenuItem separatorItem]];
            } else {
                menuItem=[prototypeMenuItem copy];
                [menuItem setTag:i];
                [menuItem setImage:[entry image]];
                int fontTraitMask=[entry fontTraitMask];
                NSDictionary *attributes=plainSymbolAttributes;
                if (fontTraitMask) {
                    switch (fontTraitMask) {
                        case (NSBoldFontMask | NSItalicFontMask):
                            attributes=boldItalicSymbolAttributes;
                            break;
                        case NSItalicFontMask :
                            attributes=italicSymbolAttributes;
                            break;
                        case NSBoldFontMask :
                            attributes=boldSymbolAttributes;
                            break;
                    }
                    [menuItem setAttributedTitle:
                        [[[NSAttributedString alloc] initWithString:[entry name] attributes:attributes] autorelease]];
                }
                [menuItem setTitle:[entry name]];
                [menuItem setIndentationLevel:[entry indentationLevel]];
                [I_symbolPopUpMenu addItem:menuItem];
                [itemsToSort addObject:[[menuItem copy] autorelease]];
                [menuItem release];
            }
            i++;
        }
        [prototypeMenuItem release];

        [itemsToSort sortUsingSelector:@selector(compareAlphabetically:)];
        NSEnumerator *menuItems=[itemsToSort objectEnumerator];
        while ((menuItem=[menuItems nextObject])) {
            [I_symbolPopUpMenuSorted addItem:menuItem];
        }
				
    } else {
        I_symbolArray=[NSArray new];
    }
    [[NSNotificationCenter defaultCenter]
        postNotificationName:PlainTextDocumentDidChangeSymbolsNotification
        object:self];
}

#define SYMBOLUPDATEINTERVAL 2.5

- (void)triggerUpdateSymbolTableTimer {
    if ([[self documentMode] hasSymbols]) {
        if ([I_symbolUpdateTimer isValid]) {
            [I_symbolUpdateTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:SYMBOLUPDATEINTERVAL]];
        } else {
            [I_symbolUpdateTimer release];
            I_symbolUpdateTimer=[[NSTimer timerWithTimeInterval:SYMBOLUPDATEINTERVAL
                                                    target:self
                                                  selector:@selector(symbolTimerAction:)
                                                  userInfo:nil repeats:NO] retain];
            [[NSRunLoop currentRunLoop] addTimer:I_symbolUpdateTimer forMode:NSDefaultRunLoopMode]; //(NSString *)kCFRunLoopCommonModes];
        }
    }
}

- (void)symbolTimerAction:(NSTimer *)aTimer {
    [self updateSymbolTable];
}


- (NSMenu *)symbolPopUpMenuForView:(NSTextView *)aTextView sorted:(BOOL)aSorted {
    NSMenu *menu=aSorted?I_symbolPopUpMenuSorted:I_symbolPopUpMenu;
    NSEnumerator *menuItems=[[menu itemArray] objectEnumerator];
    NSMenuItem *item;

    static NSMenu *emptyMenu=nil;
    if (!emptyMenu) {
        emptyMenu = [NSMenu new];
        [emptyMenu addItem:[[[NSMenuItem alloc]
                                initWithTitle:NSLocalizedString(@"<No selected symbol>",
                                                                @"Entry for Symbol Pop Up when no Symbol is found")
                                action:@selector(chooseGotoSymbolMenuItem:)
                                keyEquivalent:@""] autorelease]];
    }
    if ([[menu itemArray] count]) {

        while ((item=[menuItems nextObject])) {
            if (![item isSeparatorItem]) {
                [item setRepresentedObject:aTextView];
            }
        }
        return menu;
    } else {
        return emptyMenu;
    }

}

- (int)selectedSymbolForRange:(NSRange)aRange {
//    if (aRange.length==0) aRange.length=1;
    int count=[I_symbolArray count];
    int nearest=-1;
    while (--count>=0) {
        SymbolTableEntry *entry=[I_symbolArray objectAtIndex:count];
        if (![entry isSeparator]) {
            NSRange symbolRange=[entry range];
            if (TouchingRanges(aRange,symbolRange)) {
                return count;
            }
            if (nearest==-1 && aRange.location > NSMaxRange(symbolRange)) {
                nearest=count;
            }
        }
    }
    return nearest;
}


- (IBAction)chooseGotoSymbolMenuItem:(NSMenuItem *)aMenuItem {
    if ([aMenuItem tag]<[I_symbolArray count]) {
        NSRange symbolRange=[[I_symbolArray objectAtIndex:[aMenuItem tag]] jumpRange];
        NSTextView *textView=[aMenuItem representedObject];
        NSRange wholeRange=NSMakeRange(0,[[self textStorage] length]);
        symbolRange=RangeConfinedToRange(symbolRange,wholeRange);
        [textView setSelectedRange:symbolRange];
        [textView scrollRangeToVisible:symbolRange];
        if ([textView respondsToSelector:@selector(showFindIndicatorForRange:)]) {
            [textView showFindIndicatorForRange:symbolRange];
        } 

        PlainTextWindowController *controller=(PlainTextWindowController *)[[textView window] windowController];
        NSArray *plainTextEditors=[controller plainTextEditors];
        int i=0;
        for (i=0;i<[plainTextEditors count]; i++) {
            if ([[plainTextEditors objectAtIndex:i] textView]==textView) {
                [[plainTextEditors objectAtIndex:i] setFollowUserID:nil];
                break;
            }
        }
    } else {
        NSBeep();
    }
}

#define STACKLIMIT 100
#define BUFFERSIZE 500

- (unsigned int)TCM_positionOfMatchingBracketToPosition:(unsigned int)position {
    NSString *aString = [[self textStorage] string];
    unsigned int result=NSNotFound;
    unichar possibleBracket=[aString characterAtIndex:position];
    BOOL forward=YES;
    if ([self TCM_charIsOpeningBracket:possibleBracket]) {
        forward=YES;
    } else if ([self TCM_charIsClosingBracket:possibleBracket]) {
        forward=NO;
    } else {
        return result;
    }
    // extra block to only be initialized when thing was a bracket
    {
        unichar stack[STACKLIMIT];
        int stackPosition=0;
        NSRange searchRange,bufferRange;
        unichar buffer[BUFFERSIZE];
        int i;
        BOOL stop=NO;

        stack[stackPosition]=[self TCM_matchingBracketForChar:possibleBracket];

        if (forward) {
            searchRange=NSMakeRange(position+1,[aString length]-(position+1));
        } else {
            searchRange=NSMakeRange(0,position);
        }
        while (searchRange.length>0 && !stop) {
            if (searchRange.length<=BUFFERSIZE) {
                bufferRange=searchRange;
            } else {
                if (forward) {
                    bufferRange=NSMakeRange(searchRange.location,BUFFERSIZE);
                } else {
                    bufferRange=NSMakeRange(NSMaxRange(searchRange)-BUFFERSIZE,BUFFERSIZE);
                }
            }
            [aString getCharacters:buffer range:bufferRange];
            // go through the buffer
            if (forward) {
                for (i=0;i<(int)bufferRange.length && !stop;i++) {
                    if ([self TCM_charIsOpeningBracket:buffer[i]]&&[self TCM_validTypeForBracketAtIndex:bufferRange.location+i]) {
                        if (++stackPosition>=STACKLIMIT) {
                            stop=YES;
                        } else {
                            stack[stackPosition]=[self TCM_matchingBracketForChar:buffer[i]];
                        }
                    } else if ([self TCM_charIsClosingBracket:buffer[i]]&&[self TCM_validTypeForBracketAtIndex:bufferRange.location+i]) {
                        if (buffer[i]!=stack[stackPosition]) {
                            stop=YES;
                        } else {
                            if (--stackPosition<0) {
                                result=bufferRange.location+i;
                                stop=YES;
                            }
                        }
                    }
                }
            } else { // backward
                for (i=bufferRange.length-1;i>=0 && !stop;i--) {
                    if ([self TCM_charIsClosingBracket:buffer[i]]&&[self TCM_validTypeForBracketAtIndex:bufferRange.location+i]) {
                       if (++stackPosition>=STACKLIMIT) {
                            stop=YES;
                        } else {
                            stack[stackPosition]=[self TCM_matchingBracketForChar:buffer[i]];
                        }
                    } else if ([self TCM_charIsOpeningBracket:buffer[i]]&&[self TCM_validTypeForBracketAtIndex:bufferRange.location+i]) {
                        if (buffer[i]!=stack[stackPosition]) {
                            NSBeep(); // do it like project builder :-
                            stop=YES;
                        } else {
                            if (--stackPosition<0) {
                                result=bufferRange.location+i;
                                stop=YES;
                            }
                        }
                    }
                }
            }
            if (forward) {
                searchRange.location+=bufferRange.length;
            }
            searchRange.length-=bufferRange.length;
        }
    }
    return result;
}

- (void)TCM_highlightBracketAtPosition:(unsigned)aPosition inTextView:(NSTextView *)aTextView {
    static NSDictionary *mBracketAttributes=nil;
    if (!mBracketAttributes) mBracketAttributes=[[NSDictionary dictionaryWithObject:[[NSColor redColor] highlightWithLevel:0.3]
                                                    forKey:NSBackgroundColorAttributeName] retain];
    unsigned int matchingBracketPosition=[self TCM_positionOfMatchingBracketToPosition:aPosition];
    if (matchingBracketPosition!=NSNotFound) {
        NSLayoutManager *layoutManager=[aTextView layoutManager];
        [layoutManager addTemporaryAttributes:mBracketAttributes
                            forCharacterRange:NSMakeRange(matchingBracketPosition,1)];
        // Force layout
        (void)[layoutManager textContainerForGlyphAtIndex:
                [layoutManager glyphRangeForCharacterRange:NSMakeRange(matchingBracketPosition,1)
                                      actualCharacterRange:NULL].location effectiveRange:NULL];
        [aTextView displayIfNeeded];
        [[aTextView window] flushWindow];
        [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.08]];
        [layoutManager removeTemporaryAttribute:NSBackgroundColorAttributeName
                              forCharacterRange:NSMakeRange(matchingBracketPosition,1)];
    }

}

- (void)TCM_generateNewSession {
    TCMMMSession *oldSession=[self session];
    if (oldSession) {
        [oldSession setDocument:nil];
        [[TCMMMPresenceManager sharedInstance] unregisterSession:[self session]];
    }
    TCMMMSession *newSession=[[(TCMMMSession *)[TCMMMSession alloc] initWithDocument:self] autorelease];
    if (oldSession) {
        NSString *name = [oldSession filename];
        [newSession setFilename:name];
        [self setTemporaryDisplayName:[[self temporaryDisplayName] lastPathComponent]];
        TCMMMLoggingState *oldState = [oldSession loggingState];
        [oldState makeAllParticipantsLeave];
        [newSession setLoggingState:oldState];
    }
    NSArray *contributors=[oldSession contributors];
    if ([contributors count]) {
        [newSession addContributors:contributors];
    }
    [self setSession:newSession];
    [self setShouldChangeChangeCount:YES];
    [[TCMMMPresenceManager sharedInstance] registerSession:[self session]];
    [[self windowControllers] makeObjectsPerformSelector:@selector(synchronizeWindowTitleWithDocumentName)];
}

- (id)init {
    self = [super init];
    if (self) {
        I_flags.shouldChangeExtensionOnModeChange=YES; 
        if ([[DocumentController sharedInstance] isOpeningUntitledDocument]) {
            transientDocument = nil;
        }
        [self TCM_generateNewSession];
        I_textStorage = [TextStorage new];
        [I_textStorage setDelegate:self];
        [self setLineEnding:LineEndingLF];
        [self setDocumentMode:[[DocumentModeManager sharedInstance] modeForNewDocuments]];
        NSStringEncoding encoding = [[[self documentMode] defaultForKey:DocumentModeEncodingPreferenceKey] unsignedIntValue];
        if (encoding < SmallestCustomStringEncoding) {
            [self setFileEncoding:encoding];
        }
        I_flags.isRemotelyEditingTextStorage=NO;
        [self setShowsChangeMarks:[[NSUserDefaults standardUserDefaults] boolForKey:HighlightChangesAlonePreferenceKey] && [[NSUserDefaults standardUserDefaults] boolForKey:HighlightChangesPreferenceKey]];
        [self TCM_initHelper];
        
        OSStatus err = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, kAuthorizationFlagDefaults, &I_authRef);
        if (err != noErr) {
            NSLog(@"Failed to create authRef!");
        }
    }
    return self;
}

- (id)initWithSession:(TCMMMSession *)aSession {
    self = [super init];
    if (self) {
        [self setShouldChangeChangeCount:NO];
        [self setSession:aSession];
        [[TCMMMPresenceManager sharedInstance] registerSession:[self session]];
        I_textStorage = [TextStorage new];
        [I_textStorage setDelegate:self];
        [self setDocumentMode:[[DocumentModeManager sharedInstance] baseMode]];
        I_flags.isRemotelyEditingTextStorage=NO;
        [aSession setDocument:self];
        [self setShowsChangeMarks:[[NSUserDefaults standardUserDefaults] boolForKey:HighlightChangesPreferenceKey]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTempDisplayName:) name:TCMMMSessionDidChangeNotification object:aSession];
        [self TCM_initHelper];
    }
    return self;
}

- (void)updateTempDisplayName:(NSNotification *)aNotification {
    if ([self temporaryDisplayName]) {
        [self willChangeValueForKey:@"displayName"];
        [self setTemporaryDisplayName:[[aNotification object] filename]];
        [self didChangeValueForKey:@"displayName"];
    }
}

- (void)dealloc
{
    if (I_authRef != NULL) {
        (void)AuthorizationFree(I_authRef, kAuthorizationFlagDestroyRights);
        I_authRef = NULL;
    }

    if (transientDocument == self) {
        transientDocument = nil;
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (I_flags.isAnnounced) {
        [[TCMMMPresenceManager sharedInstance] concealSession:[self session]];
    }

    [I_session setDocument:nil];

    if (![I_session isServer]) {
        [I_session leave];
    } else {
        [I_session abandon];
    }
    
    //[I_identifier release];
    [self setPreservedDataFromSEETextFile:nil];
    [I_symbolUpdateTimer release];
    [I_webPreviewDelayedRefreshTimer release];

    [[TCMMMPresenceManager sharedInstance] unregisterSession:[self session]];
    [I_textStorage setDelegate:nil];
    [I_textStorage release];
    [I_webPreviewWindowController setPlainTextDocument:nil];
    [I_webPreviewWindowController release];
    [I_documentProxyWindowController release];
    [I_session release];
    [I_plainTextAttributes release];
    [I_typingAttributes release];
    [I_blockeditAttributes release];
    [I_fonts.plainFont release];
    [I_fonts.boldFont release];
    [I_fonts.italicFont release];
    [I_fonts.boldItalicFont release];
    [I_styleCacheDictionary release];
    [I_defaultParagraphStyle release];
    [I_fileAttributes release];
    [I_ODBParameters release];
    [I_jobDescription release];
    [I_directoryForSavePanel release];
    [I_temporaryDisplayName release];
    [I_symbolArray release];
    [I_symbolPopUpMenu release];
    [I_symbolPopUpMenuSorted release];
    [I_rangesToInvalidate release];
    [I_findAllControllers release];
    [I_lastRegisteredUndoOperation release];
    [I_undoManager release];

    [O_exportSheetController release];
    [O_exportSheet release];
    
    [O_printOptionView release];
    [O_printOptionController release];

    [I_documentMode release];
    [I_documentBackgroundColor release];
    [I_documentForegroundColor release];
    [I_printOptions autorelease];
    [I_scheduledAlertDictionary release];
	
	[self setTemporarySavePanel:nil];
    free(I_bracketMatching.openingBracketsArray);
    free(I_bracketMatching.closingBracketsArray);
    [super dealloc];
}

- (void)setScheduledAlertDictionary:(NSDictionary *)dict
{
    [dict retain];
    [I_scheduledAlertDictionary release];
    I_scheduledAlertDictionary = dict;
}

- (NSDictionary *)scheduledAlertDictionary
{
    return I_scheduledAlertDictionary;
}

- (void)presentAlert:(NSAlert *)alert modalDelegate:(id)delegate didEndSelector:(SEL)didEndSelector contextInfo:(void *)contextInfo
{
    if (alert == nil) return;
    
    NSArray *orderedWindows = [NSApp orderedWindows];
    unsigned minIndex = NSNotFound;
    NSEnumerator *enumerator = [[self windowControllers] objectEnumerator];
    PlainTextWindowController *windowController;
    while ((windowController = [enumerator nextObject])) {
        if ([[windowController document] isEqual:self] && [[windowController window] attachedSheet] == nil) {
            minIndex = MIN(minIndex, [orderedWindows indexOfObjectIdenticalTo:[windowController window]]);
        } 
    }
    
    if (minIndex != NSNotFound) {
        NSWindow *window = [orderedWindows objectAtIndex:minIndex];
        [window makeKeyAndOrderFront:self];
        [alert beginSheetModalForWindow:window
                          modalDelegate:delegate
                         didEndSelector:didEndSelector
                            contextInfo:contextInfo];
    } else {
        // Schedule alert for display
        
        NSEnumerator *enumerator = [[self windowControllers] objectEnumerator];
        PlainTextWindowController *windowController;
        while ((windowController = [enumerator nextObject])) {
            NSTabViewItem *tabViewItem = [windowController tabViewItemForDocument:self];
            if (tabViewItem) [[tabViewItem identifier] setIsAlertScheduled:YES];
        }

        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setObject:alert forKey:@"Alert"];
        if (delegate) [dict setObject:delegate forKey:@"ModalDelegate"];
        if (didEndSelector) {
            NSValue *selectorValue = [NSValue value:&didEndSelector withObjCType:@encode(SEL)];
            [dict setObject:selectorValue forKey:@"DidEndSelector"];
        }
        if (contextInfo) {
            NSValue *contextInfoValue = [NSValue value:&contextInfo withObjCType:@encode(void *)];
            [dict setObject:contextInfoValue forKey:@"ContextInfo"];
        }
        [self setScheduledAlertDictionary:dict];
    }
}

- (void)presentScheduledAlertForWindow:(NSWindow *)window
{
    NSDictionary *dict = [self scheduledAlertDictionary];
    NSAlert *alert = [dict objectForKey:@"Alert"];
    id modalDelegate = [dict objectForKey:@"ModalDelegate"];
    SEL didEndSelector = NULL;
    NSValue *selectorValue = [dict objectForKey:@"DidEndSelector"];
    if (selectorValue) [selectorValue getValue:&didEndSelector];
    void *contextInfo = NULL;
    NSValue *contextInfoValue = [dict objectForKey:@"ContextInfo"];
    if (contextInfoValue) [contextInfoValue getValue:&contextInfo];
    
    [alert beginSheetModalForWindow:window
                      modalDelegate:modalDelegate
                     didEndSelector:didEndSelector
                        contextInfo:contextInfo];
}


#pragma mark -
#pragma mark ### accessors ###

- (void)setSession:(TCMMMSession *)aSession {
    [[NSNotificationCenter defaultCenter] postNotificationName:PlainTextDocumentSessionWillChangeNotification object:self];
    [I_session autorelease];
    I_session = [aSession retain];
    [[NSNotificationCenter defaultCenter] postNotificationName:PlainTextDocumentSessionDidChangeNotification object:self];
}

- (TCMMMSession *)session {
    return I_session;
}

- (NSTextStorage *)textStorage {
    return I_textStorage;
}

- (void)fillScriptsIntoContextMenu:(NSMenu *)aMenu {
    NSArray *itemArray = [[self documentMode] contextMenuItemArray];
    if ([itemArray count]) {
        NSEnumerator *menuItems=[itemArray objectEnumerator];
        NSMenuItem   *menuItem = nil;
        while ((menuItem=[menuItems nextObject])) {
            NSMenuItem *item=[menuItem autoreleasedCopy];
            [aMenu addItem:item];
        }
    }
    itemArray = [[AppController sharedInstance] contextMenuItemArray];
    if ([itemArray count]) {
        NSEnumerator *menuItems=[itemArray objectEnumerator];
        NSMenuItem   *menuItem = nil;
        while ((menuItem=[menuItems nextObject])) {
            NSMenuItem *item=[menuItem autoreleasedCopy];
            [aMenu addItem:item];
        }
    }
}

- (void)adjustModeMenu {
    NSMenu *modeMenu=[[[NSApp mainMenu] itemWithTag:ModeMenuTag] submenu];
    // remove all items that don't belong here anymore
    int index = [modeMenu indexOfItemWithTag:HighlightSyntaxMenuTag];
    index+=1; 
    while (index < [modeMenu numberOfItems]) {
        [modeMenu removeItemAtIndex:index];
    }
    // check if mode has items
    NSArray *itemArray = [[self documentMode] scriptMenuItemArray];
    if ([itemArray count]) {
        [modeMenu addItem:[NSMenuItem separatorItem]];
        NSEnumerator *menuItems=[itemArray objectEnumerator];
        NSMenuItem   *menuItem = nil;
        NSImage *scriptMenuItemIcon=[NSImage imageNamed:@"ScriptMenuItemIcon"];
        while ((menuItem=[menuItems nextObject])) {
            NSMenuItem *item=[menuItem autoreleasedCopy];
            [item setImage:scriptMenuItemIcon];
            [modeMenu addItem:item];
            [item setKeyEquivalent:[menuItem keyEquivalent]];
            [item setKeyEquivalentModifierMask:[menuItem keyEquivalentModifierMask]];
        }
    }
}


- (DocumentMode *)documentMode {
    return I_documentMode;
}

- (void)takeStyleSettingsFromDocumentMode {
    DocumentMode *documentMode=[self documentMode];
    NSDictionary *fontAttributes=[documentMode defaultForKey:DocumentModeFontAttributesPreferenceKey];
    NSFont *newFont=[NSFont fontWithName:[fontAttributes objectForKey:NSFontNameAttribute] size:[[fontAttributes objectForKey:NSFontSizeAttribute] floatValue]];
    if (!newFont) newFont=[NSFont userFixedPitchFontOfSize:[[fontAttributes objectForKey:NSFontSizeAttribute] floatValue]];
    [self setPlainFont:newFont];
    [[self plainTextEditors] makeObjectsPerformSelector:@selector(takeStyleSettingsFromDocument)];
}

- (void)takeEditSettingsFromDocumentMode {
    DocumentMode *documentMode=[self documentMode];
    [self setHighlightsSyntax:[[documentMode defaultForKey:DocumentModeHighlightSyntaxPreferenceKey] boolValue]];
    
    [self setIndentsNewLines:[[documentMode defaultForKey:DocumentModeIndentNewLinesPreferenceKey] boolValue]];
    [self setUsesTabs:[[documentMode defaultForKey:DocumentModeUseTabsPreferenceKey] boolValue]];
    [self setTabWidth:[[documentMode defaultForKey:DocumentModeTabWidthPreferenceKey] intValue]];
    [self setWrapLines:[[documentMode defaultForKey:DocumentModeWrapLinesPreferenceKey] boolValue]];
    [self setWrapMode: [[documentMode defaultForKey:DocumentModeWrapModePreferenceKey] intValue]];
    [self setShowInvisibleCharacters:[[documentMode defaultForKey:DocumentModeShowInvisibleCharactersPreferenceKey] boolValue]];
    [self setShowsGutter:[[documentMode defaultForKey:DocumentModeShowLineNumbersPreferenceKey] intValue]];
    [self setShowsMatchingBrackets:[[documentMode defaultForKey:DocumentModeShowMatchingBracketsPreferenceKey] boolValue]];
    
    NSString *string = [[self textStorage] string];
    unsigned lineEndIndex, contentsEndIndex;
    [string getLineStart:NULL end:&lineEndIndex contentsEnd:&contentsEndIndex forRange:NSMakeRange(0, 0)];
    if (lineEndIndex == contentsEndIndex) {
        [self setLineEnding:[[documentMode defaultForKey:DocumentModeLineEndingPreferenceKey] intValue]];
    }
    
    NSNumber *aFlag=[[documentMode defaults] objectForKey:DocumentModeShowBottomStatusBarPreferenceKey];
    [self setShowsBottomStatusBar:!aFlag || [aFlag boolValue]];
    aFlag=[[documentMode defaults] objectForKey:DocumentModeShowTopStatusBarPreferenceKey];
    [self setShowsTopStatusBar:!aFlag || [aFlag boolValue]];

    [[self windowControllers] makeObjectsPerformSelector:@selector(takeSettingsFromDocument)];
    [[self plainTextEditors] makeObjectsPerformSelector:@selector(takeStyleSettingsFromDocument)];
}

- (void)takeSettingsFromDocumentMode {
    [self takeStyleSettingsFromDocumentMode];
    [self takeEditSettingsFromDocumentMode];
    
    [self setPrintOptions:[[self documentMode] defaultForKey:DocumentModePrintOptionsPreferenceKey]];    
}

- (void)setDocumentMode:(DocumentMode *)aDocumentMode {
    if (aDocumentMode != I_documentMode) {
        [I_documentMode autorelease];
        SyntaxHighlighter *highlighter=[I_documentMode syntaxHighlighter];
        [highlighter cleanUpTextStorage:[self textStorage]];
         I_documentMode = [aDocumentMode retain];
        [self takeSettingsFromDocumentMode];
        [I_textStorage addAttributes:[self plainTextAttributes]
                                   range:NSMakeRange(0,[I_textStorage length])];
        if (I_flags.highlightSyntax) {
            [self highlightSyntaxInRange:NSMakeRange(0,[[self textStorage] length])];
        }
        [self setContinuousSpellCheckingEnabled:[[aDocumentMode defaultForKey:DocumentModeSpellCheckingPreferenceKey] boolValue]];
        [self updateSymbolTable];
        if (I_flags.shouldChangeExtensionOnModeChange) {
            NSArray *recognizedExtensions = [I_documentMode recognizedExtensions];
            if ([recognizedExtensions count]) {
                if ([I_session isServer]) {
                    [I_session setFilename:[self preparedDisplayName]];
                }
                [[self windowControllers] makeObjectsPerformSelector:@selector(synchronizeWindowTitleWithDocumentName)];
            }
        }
        id testDocument=[[[NSApp mainWindow] windowController] document];
        if (testDocument == self || !testDocument) {
            [self adjustModeMenu];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:PlainTextDocumentDidChangeDocumentModeNotification object:self];
    }
}

- (NSMutableDictionary *)printOptions {
    return I_printOptions;
}

- (void)setPrintOptions:(NSDictionary *)aPrintOptions {
    [I_printOptions autorelease];
    I_printOptions=[aPrintOptions mutableCopy];
}

// only because the original implementation updates the changecount
- (void)setPrintInfo:(NSPrintInfo *)aPrintInfo {
    BOOL oldState=I_flags.shouldChangeChangeCount;
    I_flags.shouldChangeChangeCount=NO;
    [super setPrintInfo:aPrintInfo];
    I_flags.shouldChangeChangeCount=oldState;
}

- (unsigned int)fileEncoding {
    return [(TextStorage *)[self textStorage] encoding];
}

- (void)setFileEncoding:(unsigned int)anEncoding {
    [(TextStorage *)[self textStorage] setEncoding:anEncoding];
    [self TCM_sendPlainTextDocumentDidChangeEditStatusNotification];
}

- (void)setFileEncodingUndoable:(unsigned int)anEncoding {
    [[[self documentUndoManager] prepareWithInvocationTarget:self] 
        setFileEncodingUndoable:[self fileEncoding]];
    [self setFileEncoding:anEncoding];
}

//- (NSURL *)autosavedContentsFileURL {
//    NSLog(@"%s %@ %@",__FUNCTION__,[super autosavedContentsFileURL],[BacktracingException backtrace]);
//    return [super autosavedContentsFileURL];
//}

- (NSDictionary *)fileAttributes {
    return I_fileAttributes;
}

- (void)setFileAttributes:(NSDictionary *)attributes {
    [I_fileAttributes autorelease];
    I_fileAttributes = [attributes retain];
}

- (NSDictionary *)ODBParameters {
    return I_ODBParameters;
}

- (void)setODBParameters:(NSDictionary *)aDictionary {
    [I_ODBParameters autorelease];
    I_ODBParameters = [aDictionary retain];
}


- (BOOL)isWaiting {
    return I_flags.isWaiting;
}

- (void)setIsWaiting:(BOOL)aFlag {
    I_flags.isWaiting=aFlag;
    [[self plainTextEditors] makeObjectsPerformSelector:@selector(TCM_updateStatusBar)];
}

- (NSString *)jobDescription {
    return I_jobDescription;
}

- (void)setJobDescription:(NSString *)aString {
    [I_jobDescription autorelease];
    I_jobDescription = [aString copy];
    [[self windowControllers] makeObjectsPerformSelector:@selector(synchronizeWindowTitleWithDocumentName)];
}

- (void)setDirectoryForSavePanel:(NSString *)path {
    [I_directoryForSavePanel autorelease];
    I_directoryForSavePanel = [path copy];
}

- (NSString *)directoryForSavePanel {
    return I_directoryForSavePanel;
}

- (NSString *)temporaryDisplayName {
    return I_temporaryDisplayName;
}

- (void)setTemporaryDisplayName:(NSString *)name {
    [I_temporaryDisplayName autorelease];
    I_temporaryDisplayName = [name copy];
    TCMMMSession *session = [self session];
    if ([session isServer]) {
        [session setFilename:[self preparedDisplayName]];
    }
    [[self windowControllers] makeObjectsPerformSelector:@selector(synchronizeWindowTitleWithDocumentName)];
}

- (BOOL)isAnnounced {
    return I_flags.isAnnounced;
}

- (void)setIsAnnounced:(BOOL)aFlag {
    if ([[self session] isServer]) {
        if (I_flags.isAnnounced!=aFlag) {
            I_flags.isAnnounced=aFlag;
            if (I_flags.isAnnounced) {
                DEBUGLOG(@"Document", AllLogLevel, @"announce");
                [[TCMMMPresenceManager sharedInstance] announceSession:[self session]];
                [[self session] setFilename:[self preparedDisplayName]];
                [[self topmostWindowController] openParticipantsDrawer:self];
                if ([[NSUserDefaults standardUserDefaults] boolForKey:HighlightChangesPreferenceKey]) {
                    NSEnumerator *plainTextEditors=[[self plainTextEditors] objectEnumerator];
                    PlainTextEditor *editor=nil;
                    while ((editor=[plainTextEditors nextObject])) {
                        [editor setShowsChangeMarks:YES];
                    }
                }
            } else {
                DEBUGLOG(@"Document", AllLogLevel, @"conceal");
                TCMMMSession *session=[self session];
                [[TCMMMPresenceManager sharedInstance] concealSession:session];
                if ([session participantCount]<=1 && [[session pendingUsers] count] == 0) {
                    [[self windowControllers] makeObjectsPerformSelector:@selector(closeParticipantsDrawer:) withObject:self];
                }
            }
        }
        // needed for updating of the lock
        [[self windowControllers] makeObjectsPerformSelector:@selector(synchronizeWindowTitleWithDocumentName)];

    }
}

- (IBAction)toggleIsAnnounced:(id)aSender {
    [self setIsAnnounced:![self isAnnounced]];
}

- (IBAction)toggleIsAnnouncedOnAllDocuments:(id)aSender {
    BOOL targetSetting = ![self isAnnounced];
    NSEnumerator *documents = [[[DocumentController sharedInstance] documents] objectEnumerator];
    PlainTextDocument *document = nil;
    while ((document=[documents nextObject])) {
        [document setIsAnnounced:targetSetting];
    }
}

- (IBAction)changePendingUsersAccess:(id)aSender {
    if ([[self session] isServer]) {
        int newState=-1;
        if ([aSender isKindOfClass:[NSPopUpButton class]]) {
            newState=[[aSender selectedItem] tag];
        } else {
            newState=[aSender tag];
        }
        if (newState!=-1) {
            TCMMMSession *session=[self session];
            [session setAccessState:newState];
        }
    }
}

- (IBAction)changePendingUsersAccessOnAllDocuments:(id)aSender {
    NSEnumerator *documents = [[[DocumentController sharedInstance] documents] objectEnumerator];
    PlainTextDocument *document = nil;
    while ((document=[documents nextObject])) {
        [document changePendingUsersAccess:aSender];
    }
}
- (BOOL)isEditable {
    return [[self session] isEditable];
}

- (void)validateEditability {
    BOOL isEditable=[self isEditable];
    NSEnumerator *plainTextEditors=[[self plainTextEditors] objectEnumerator];
    PlainTextEditor *editor=nil;
    while ((editor=[plainTextEditors nextObject])) {
        [[editor textView] setEditable:isEditable];
    }
}

- (BOOL)isRemotelyEditingTextStorage {
    return I_flags.isRemotelyEditingTextStorage;
}

- (void)ensureWebPreview {
    if (!I_webPreviewWindowController) {
        I_webPreviewWindowController=[[WebPreviewWindowController alloc] initWithPlainTextDocument:self];
        [I_webPreviewWindowController window];
    }
}

- (IBAction)showWebPreview:(id)aSender {
    [self ensureWebPreview];
    if (![[I_webPreviewWindowController window] isVisible]) {
        [I_webPreviewWindowController showWindow:self];
        [I_webPreviewWindowController refreshAndEmptyCache:self];
    } else {
        [[I_webPreviewWindowController window] orderFront:self];
    }
}

- (IBAction)prettyPrintXML:(id)aSender {
    NSError *error=nil;
    NSXMLDocument *document = [[NSXMLDocument alloc] initWithXMLString:[[self textStorage] string] options:NSXMLNodePreserveEmptyElements error:&error];
    if (document) {
        NSString *xmlString = [document XMLStringWithOptions:NSXMLNodePrettyPrint|NSXMLNodePreserveEmptyElements];
        [document release];
        if ([self tabWidth] != 4 || [self usesTabs]) {
            OGRegularExpression *spaceMatch = [OGRegularExpression regularExpressionWithString:@"((    )+)<"];
            NSMutableString *string = [[xmlString mutableCopy] autorelease];
            NSString *replacementString = [self usesTabs]?@"\t":[@" " stringByPaddingToLength:[self tabWidth] withString:@" " startingAtIndex:0];
            NSArray *matchArray=[spaceMatch allMatchesInString:xmlString range:NSMakeRange(0,[string length])];
            NSEnumerator *matches = [matchArray reverseObjectEnumerator];
            OGRegularExpressionMatch *match = nil;
            while ((match=[matches nextObject])) {
                NSRange replacementRange = [match rangeOfSubstringAtIndex:1];
                int numberOfReplacements = replacementRange.length / 4;
                while (--numberOfReplacements > 0) {
                    [string replaceCharactersInRange:NSMakeRange(NSMaxRange(replacementRange),0) withString:replacementString];
                }
                [string replaceCharactersInRange:replacementRange withString:replacementString];
            }
            xmlString = (NSString *)string;
        }
        [self performSelector:@selector(setScriptedContents:) withObject:xmlString];
        // [self clearChangeMarks:aSender];
    } else {
        [document release];
        [self presentError:(NSError *)error modalForWindow:[self windowForSheet] delegate:nil didPresentSelector:NULL contextInfo:nil];
    }
}

- (IBAction)refreshWebPreview:(id)aSender {
    if (!I_webPreviewWindowController) {
        [self showWebPreview:self];
    } else {
        [I_webPreviewWindowController refresh:self];
    }
}

#define WEBPREVIEWDELAYEDREFRESHINTERVAL 1.2

- (void)triggerDelayedWebPreviewRefresh {
    if (I_webPreviewWindowController) {
        if ([I_webPreviewDelayedRefreshTimer isValid]) {
            [I_webPreviewDelayedRefreshTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:WEBPREVIEWDELAYEDREFRESHINTERVAL]];
        } else {
            [I_webPreviewDelayedRefreshTimer release];
            I_webPreviewDelayedRefreshTimer=[[NSTimer timerWithTimeInterval:WEBPREVIEWDELAYEDREFRESHINTERVAL
                                                    target:self
                                                  selector:@selector(delayedWebPreviewRefreshAction:)
                                                  userInfo:nil repeats:NO] retain];
            [[NSRunLoop currentRunLoop] addTimer:I_webPreviewDelayedRefreshTimer forMode:NSDefaultRunLoopMode]; //(NSString *)kCFRunLoopCommonModes];
        }
    }
}

- (void)delayedWebPreviewRefreshAction:(NSTimer *)aTimer {
    [self refreshWebPreview:self];
}


- (void)TCM_webPreviewRefreshNotification:(NSNotification *)aNotification {
    if ([I_webPreviewWindowController refreshType] == kWebPreviewRefreshAutomatic) {
        [self refreshWebPreview:self];
    } else if ([I_webPreviewWindowController refreshType] == kWebPreviewRefreshDelayed) {
        [self triggerDelayedWebPreviewRefresh];
    }
}

- (void)TCM_webPreviewOnSaveRefresh {
    if (I_webPreviewWindowController) {
        if ([[I_webPreviewWindowController window] isVisible] &&
            [I_webPreviewWindowController refreshType] == kWebPreviewRefreshOnSave) {
            [I_webPreviewWindowController refreshAndEmptyCache:self];
        }
    }
}


- (IBAction)newView:(id)aSender {
    if (!I_flags.isReceivingContent && [[self windowControllers] count] > 0) {
        PlainTextWindowController *controller = [[PlainTextWindowController alloc] init];
        [[DocumentController sharedInstance] addWindowController:controller];
        [self addWindowController:controller];
        [controller showWindow:aSender];
        [controller release];
        [self TCM_sendPlainTextDocumentDidChangeDisplayNameNotification];
    }
}

- (IBAction)undo:(id)aSender {
    [[self documentUndoManager] undo];
}

- (IBAction)redo:(id)aSender {
    [[self documentUndoManager] redo];
}

- (IBAction)clearChangeMarks:(id)aSender {
    NSTextStorage *textStorage=[self textStorage];
    [textStorage removeAttribute:ChangedByUserIDAttributeName range:NSMakeRange(0,[textStorage length])];
}

- (IBAction)restoreChangeMarks:(id)aSender {
    NSTextStorage *textStorage=[self textStorage];
    NSRange wholeRange=NSMakeRange(0,[textStorage length]);
    if (wholeRange.length) {
        [textStorage beginEditing];
        NSRange searchRange=NSMakeRange(0,0);
        while (NSMaxRange(searchRange)<wholeRange.length) {
            id value=[textStorage attribute:WrittenByUserIDAttributeName atIndex:NSMaxRange(searchRange) 
                   longestEffectiveRange:&searchRange inRange:wholeRange];
            if (value) {
                [textStorage addAttribute:ChangedByUserIDAttributeName value:value range:searchRange];
            }
        }
        [textStorage endEditing];
    }
}

- (IBAction)selectEncoding:(id)aSender {

    NSStringEncoding encoding = [aSender tag];

    DEBUGLOG(@"FileIOLogDomain", DetailedLogLevel, [NSString localizedNameOfStringEncoding:encoding]);

    if ([self fileEncoding] != encoding) {

        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert setMessageText:NSLocalizedString(@"File Encoding", nil)];
        [alert setInformativeText:NSLocalizedString(@"ConvertOrReinterpret", nil)];
        [alert addButtonWithTitle:NSLocalizedString(@"Convert", nil)];
        [alert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
        [alert addButtonWithTitle:NSLocalizedString(@"Reinterpret", nil)];
        [self presentAlert:alert
             modalDelegate:self
            didEndSelector:@selector(selectEncodingAlertDidEnd:returnCode:contextInfo:)
               contextInfo:[[NSDictionary dictionaryWithObjectsAndKeys:
                                                @"SelectEncodingAlert", @"Alert",
                                                [NSNumber numberWithUnsignedInt:encoding], @"Encoding",
                                                nil] retain]];
    }
}

- (void)selectEncodingAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    NSDictionary *alertContext = (NSDictionary *)contextInfo;
    DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel, @"alertDidEnd: %@", [alertContext objectForKey:@"Alert"]);

    TCMMMSession *session=[self session];
    if (!I_flags.isReceivingContent && [session isServer] && [session participantCount]<=1) {
        NSStringEncoding encoding = [[alertContext objectForKey:@"Encoding"] unsignedIntValue];
        if (returnCode == NSAlertFirstButtonReturn) { // convert
            DEBUGLOG(@"FileIOLogDomain", DetailedLogLevel, @"Trying to convert file encoding");
            [[alert window] orderOut:self];
            if (![[I_textStorage string] canBeConvertedToEncoding:encoding]) {
                [[self topmostWindowController] setDocumentDialog:[[[EncodingDoctorDialog alloc] initWithEncoding:encoding] autorelease]];
            
                // didn't work so update bottom status bar to previous state
                [self TCM_sendPlainTextDocumentDidChangeEditStatusNotification];
            } else {
                [self setFileEncodingUndoable:encoding];
                [self updateChangeCount:NSChangeDone];
            }
        }

        if (returnCode == NSAlertSecondButtonReturn) {
          // canceled so update bottom status bar to previous state
          [self TCM_sendPlainTextDocumentDidChangeEditStatusNotification];
        }

        if (returnCode == NSAlertThirdButtonReturn) { // Reinterpret
            DEBUGLOG(@"FileIOLogDomain", DetailedLogLevel, @"Trying to reinterpret file encoding");
            [[alert window] orderOut:self];
            NSData *stringData = [[I_textStorage string] dataUsingEncoding:[self fileEncoding]];
            if ([self fileEncoding] == NSUTF8StringEncoding) {
                BOOL modeWantsUTF8BOM = [[[self documentMode] defaultForKey:DocumentModeUTF8BOMPreferenceKey] boolValue];
                if (I_flags.hasUTF8BOM || modeWantsUTF8BOM) {
                    stringData = [stringData dataPrefixedWithUTF8BOM];
                }
            }
            if (encoding == NSUTF8StringEncoding) {
                if (I_flags.hasUTF8BOM && ![stringData startsWithUTF8BOM]) {
                    I_flags.hasUTF8BOM = NO;
                } else if (!I_flags.hasUTF8BOM && [stringData startsWithUTF8BOM]) {
                    I_flags.hasUTF8BOM = YES;
                }
            }
            NSString *reinterpretedString = [[NSString alloc] initWithData:stringData encoding:encoding];
            if (!reinterpretedString || ([reinterpretedString length] == 0 && [I_textStorage length] > 0)) {
                NSAlert *newAlert = [[[NSAlert alloc] init] autorelease];
                [newAlert setAlertStyle:NSWarningAlertStyle];
                [newAlert setMessageText:NSLocalizedString(@"Error", nil)];
                [newAlert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"Encoding %@ not reinterpretable", nil), [NSString localizedNameOfStringEncoding:encoding]]];
                [newAlert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
                [self presentAlert:newAlert
                     modalDelegate:nil
                    didEndSelector:nil
                       contextInfo:NULL];
                // didn't work so update bottom status bar to previous state
                [self TCM_sendPlainTextDocumentDidChangeEditStatusNotification];
            } else {
                BOOL isEdited = [self isDocumentEdited];
                [[self documentUndoManager] beginUndoGrouping];
                [[self plainTextEditors] makeObjectsPerformSelector:@selector(pushSelectedRanges)];
                [I_textStorage beginEditing];
                [I_textStorage replaceCharactersInRange:NSMakeRange(0, [I_textStorage length]) withString:@""];
                [self setFileEncodingUndoable:encoding];
                [I_textStorage replaceCharactersInRange:NSMakeRange(0, [I_textStorage length]) withString:reinterpretedString];
                [reinterpretedString release];
                if (!isEdited) {
                    [I_textStorage setAttributes:[self plainTextAttributes] range:NSMakeRange(0, [I_textStorage length])];
                } else {
                    [I_textStorage setAttributes:[self typingAttributes] range:NSMakeRange(0, [I_textStorage length])];
                }
                if (I_flags.highlightSyntax) {
                    [self highlightSyntaxInRange:NSMakeRange(0, [I_textStorage length])];
                }
                [I_textStorage endEditing];
                [[self documentUndoManager] endUndoGrouping];
                [[self plainTextEditors] makeObjectsPerformSelector:@selector(popSelectedRanges)];
                if (!isEdited) {
                    [self updateChangeCount:NSChangeCleared];
                }
                [self TCM_validateLineEndings];
            }
        }
    }
}


#pragma mark Overrides of NSDocument Methods to Support MultiDocument Windows

static BOOL PlainTextDocumentIgnoreRemoveWindowController = NO;

- (void)makeWindowControllers {
    BOOL shouldOpenInTab = [[NSUserDefaults standardUserDefaults] boolForKey:OpenNewDocumentInTabKey];
    DocumentController *controller = [DocumentController sharedInstance];
    if ([controller isOpeningUsingAlternateMenuItem]) {
        if (shouldOpenInTab) { // if so we just open one new window
            [controller setIsOpeningUsingAlternateMenuItem:NO];
        }
        shouldOpenInTab = !shouldOpenInTab;
    }
    if (shouldOpenInTab) {
        PlainTextWindowController *controller = [[DocumentController sharedDocumentController] activeWindowController];
        [self addWindowController:controller];
        [[(PlainTextWindowController *)controller tabBar] setHideForSingleTab:![[NSUserDefaults standardUserDefaults] boolForKey:AlwaysShowTabBarKey]];
    } else {
        PlainTextWindowController *controller = [[PlainTextWindowController alloc] init];
        [self addWindowController:controller];
        [[DocumentController sharedInstance] addWindowController:controller];
        [controller release];
    }
}

- (void)addWindowController:(NSWindowController *)windowController 
{
    // -[NSDocument addWindowController:] does something foul: it checks to see if the window controller already has a document, and if so sends that other document a -removeWindowController:windowController message. That's the wrong thing to do (it's -[NSWindowController setDocument:]'s job to worry about that) and interferes with our support for window controllers that display multiple documents. Prevent it.
    PlainTextDocumentIgnoreRemoveWindowController = YES;
    //[windowController addDocument:self];
    [super addWindowController:windowController];
    PlainTextDocumentIgnoreRemoveWindowController = NO;
}

- (void)removeWindowController:(NSWindowController *)windowController
{
    if (!PlainTextDocumentIgnoreRemoveWindowController) {
        [super removeWindowController:windowController];
    }

    if ([[self windowControllers] count] != 0) {
        // if doing always, we delay the dealloc method ad inifitum on quit
        [self TCM_sendPlainTextDocumentDidChangeDisplayNameNotification];
    }
}

- (void)canCloseDocumentWithDelegate:(id)delegate shouldCloseSelector:(SEL)shouldCloseSelector contextInfo:(void *)contextInfo
{
    NSEnumerator *enumerator = [[self windowControllers] objectEnumerator];
    NSWindowController *windowController;
    unsigned count = [[self windowControllers] count];
    unsigned found = 0;
    while ((windowController = [enumerator nextObject])) {
        if ([windowController isKindOfClass:[PlainTextWindowController class]]) {
            found++;
        }
    }
    
    if (count > 1 && count == found) {
        if ([delegate respondsToSelector:shouldCloseSelector]) {
            ((void (*)(id, SEL, id, BOOL, void (*)))objc_msgSend)(delegate, shouldCloseSelector, self, YES, contextInfo);
        }
    } else {
        [super canCloseDocumentWithDelegate:delegate shouldCloseSelector:shouldCloseSelector contextInfo:contextInfo];
    }
}   

- (void)shouldCloseWindowController:(NSWindowController *)windowController delegate:(id)delegate shouldCloseSelector:(SEL)selector contextInfo:(void *)contextInfo 
{
    if ([windowController isKindOfClass:[PlainTextWindowController class]] && [(PlainTextWindowController *)windowController hasManyDocuments]) {
        [(PlainTextWindowController *)windowController closeAllTabs];
    } else {
        // NSWindow invokes this directly; there's nothing we can override in NSWindowController instead.

        // Do the regular NSDocument thing, but take control afterward if it's a multidocument window controller. To do this we have to record the original parameters of this method invocation.
        PlainTextDocumentShouldCloseContext *replacementContext = [[PlainTextDocumentShouldCloseContext alloc] init];
        replacementContext->windowController = (PlainTextWindowController *)windowController;
        replacementContext->originalDelegate = delegate;
        replacementContext->originalSelector = selector;
        replacementContext->originalContext = contextInfo;
        delegate = self;
        selector = @selector(thisDocument:shouldClose:contextInfo:);
        contextInfo = replacementContext;
        
        [super shouldCloseWindowController:windowController delegate:delegate shouldCloseSelector:selector contextInfo:contextInfo];
    }
}


- (void)thisDocument:(NSDocument *)document shouldClose:(BOOL)shouldClose contextInfo:(void *)contextInfo
{
    PlainTextDocumentShouldCloseContext *replacementContext = (PlainTextDocumentShouldCloseContext *)contextInfo;

    // Always tell the original invoker of -shouldCloseWindowController:delegate:shouldCloseSelector:contextInfo: not to close the window controller (it's actually the NSWindow in Tiger and every earlier release). We might not want the window controller to be closed. Even if we want it to be closed, we want to do it by invoking our override of -close, which will always cause the window controller to get a -close message, which is necessary for some cleanup.
    // Sketch 2 is still a work in progress! Using objc_msgSend() like this isn't really considered exemplary.
    objc_msgSend(replacementContext->originalDelegate, replacementContext->originalSelector, document, NO, replacementContext->originalContext);
    if (shouldClose) {
        NSArray *windowControllers = [self windowControllers];
        unsigned int windowControllerCount = [windowControllers count];
        if (windowControllerCount > 1) {
            PlainTextWindowController *windowController = replacementContext->windowController;
            [windowController documentWillClose:self];
            [windowController close];
        } else {
            [self close];
        }
    }   
    [replacementContext release];
}


- (void)close
{
    // The window controller are going to get -close messages of their own when we invoke [super close]. If one of them is a multidocument window controller tell it who the -close message is coming from.
    NSArray *windowControllers = [self windowControllers];
    unsigned int windowControllerCount = [windowControllers count];
    unsigned int index;
    for (index = 0; index < windowControllerCount; index++) {
        NSWindowController *windowController = [windowControllers objectAtIndex:index];
        [(PlainTextWindowController *)windowController documentWillClose:self];
    }
    
    // terminate syntax coloring
    I_flags.highlightSyntax = NO;
    [I_symbolUpdateTimer invalidate];
    [I_webPreviewDelayedRefreshTimer invalidate];
    [self TCM_sendODBCloseEvent];
    if (I_authRef != NULL) {
        (void)AuthorizationFree(I_authRef, kAuthorizationFlagDestroyRights);
        I_authRef = NULL;
    }

    // Do the regular NSDocument thing.
    [super close];
}

#pragma mark -

- (BOOL)isProxyDocument {
    return ((I_documentProxyWindowController != nil) || I_flags.isReceivingContent);
}

- (BOOL)isPendingInvitation {
    return [I_documentProxyWindowController isPendingInvitation];
}

- (void)makeProxyWindowController {
    I_documentProxyWindowController =
        [[DocumentProxyWindowController alloc] initWithSession:[self session]];
    [I_documentProxyWindowController setDocument:self];
}

- (void)killProxyWindowController {
    [I_documentProxyWindowController autorelease];
    I_documentProxyWindowController = nil;
    if ([[self windowControllers] count]==0) {
        TCMMMSession *session=[self session];
        [session setDocument:nil];
        if ([session wasInvited]) {
            [session declineInvitation];
        } else {
            [session cancelJoin];
        }
        [[DocumentController sharedInstance] removeDocument:[[self retain] autorelease]];

    } else {
        PlainTextWindowController *windowController=(PlainTextWindowController *)[[self windowControllers] objectAtIndex:0];
//        if (![windowController hasManyDocuments]) {
            [windowController showWindow:self];
//        }
    }
}

- (void)updateProxyWindow {
    [I_documentProxyWindowController update];
}

- (void)proxyWindowWillClose {
    [self killProxyWindowController];
}

- (DocumentProxyWindowController *)proxyWindowController {
    return I_documentProxyWindowController;
}

- (void)TCM_validateLineEndings {
    DEBUGLOG(@"FileIOLogDomain", AllLogLevel, @"validating line endings");

    NSString *string = [[self textStorage] string];
    unsigned length = [string length];
    unsigned curPos = 0;
    unsigned start, end, contentsEnd;
    unichar CR   = 0x000D;
    unichar LF   = 0x000A;
    unichar LSEP = 0x2028;
    unichar PSEP = 0x2029;
    unsigned countOfCR = 0;
    unsigned countOfLF = 0;
    unsigned countOfCRLF = 0;
    unsigned countOfLSEP = 0;
    unsigned countOfPSEP = 0;
    
    while (curPos < length) {
        [string getLineStart:&start end:&end contentsEnd:&contentsEnd forRange:NSMakeRange(curPos, 0)];
        if (contentsEnd < length) {
            unichar currentChar = [string characterAtIndex:contentsEnd];
            if (currentChar == LF) {
                countOfLF++;
            } else if (currentChar == LSEP) {
                countOfLSEP++;
            } else if (currentChar == PSEP) {
                countOfPSEP++;
            } else if (currentChar == CR) {
                if (contentsEnd < (length - 1) && [string characterAtIndex:contentsEnd + 1] == LF) {
                    countOfCRLF++;
                } else {
                    countOfCR++;
                }
            }
        }
        curPos = end;
    }
    DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel, @"line endings stats -\nLF:   %d\nLSEP: %d\nPSEP: %d\nCR:   %d\nCRLF: %d\n", countOfLF, countOfLSEP, countOfPSEP, countOfCR, countOfCRLF);
    
    NSDictionary *lineEndingStats = [NSDictionary dictionaryWithObjectsAndKeys:
        [NSNumber numberWithUnsignedInt:countOfCR], [NSNumber numberWithUnsignedShort:LineEndingCR],
        [NSNumber numberWithUnsignedInt:countOfLF], [NSNumber numberWithUnsignedShort:LineEndingLF],
        [NSNumber numberWithUnsignedInt:countOfPSEP], [NSNumber numberWithUnsignedShort:LineEndingUnicodeParagraphSeparator],
        [NSNumber numberWithUnsignedInt:countOfLSEP], [NSNumber numberWithUnsignedShort:LineEndingUnicodeLineSeparator],
        [NSNumber numberWithUnsignedInt:countOfCRLF], [NSNumber numberWithUnsignedShort:LineEndingCRLF],
        nil];
    NSArray *sortedLineEndingStatsKeys = [lineEndingStats keysSortedByValueUsingSelector:@selector(compare:)];
    BOOL hasLineEndings = ([[lineEndingStats objectForKey:[sortedLineEndingStatsKeys objectAtIndex:4]] unsignedIntValue] != 0);
    BOOL hasMixedLineEndings = hasLineEndings && ([[lineEndingStats objectForKey:[sortedLineEndingStatsKeys objectAtIndex:3]] unsignedIntValue] != 0);
    if (hasLineEndings) {
        [self setLineEnding:[[sortedLineEndingStatsKeys objectAtIndex:4] unsignedShortValue]];
        if (hasMixedLineEndings) {
            NSString *localizedName;
            switch([[sortedLineEndingStatsKeys objectAtIndex:4] unsignedShortValue]) {
                case LineEndingLF:
                    localizedName = @"LF";
                    break;
                case LineEndingCR:
                    localizedName = @"CR";
                    break;
                case LineEndingCRLF:
                    localizedName = @"CRLF";
                    break;
                case LineEndingUnicodeLineSeparator:
                    localizedName = @"LSEP";
                    break;
                case LineEndingUnicodeParagraphSeparator:
                    localizedName = @"PSEP";
                    break;
                default:
                    localizedName = @"LF";
                    break;
            }
            NSAlert *alert = [[[NSAlert alloc] init] autorelease];
            [alert setAlertStyle:NSWarningAlertStyle];
            [alert setMessageText:[NSString stringWithFormat:NSLocalizedString(@"The file has mixed line endings. Do you want to convert all line endings to %@, the most common line ending in the file?", nil), localizedName]];
            [alert setInformativeText:NSLocalizedString(@"Other applications may not be able to read the file if you don't convert all line endings to the same line ending.", nil)];
            [alert addButtonWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Convert to %@", nil), localizedName]];
            [alert addButtonWithTitle:NSLocalizedString(@"Keep Line Endings", nil)];
            [[[alert buttons] objectAtIndex:0] setKeyEquivalent:@"\r"];
            [self presentAlert:alert
                 modalDelegate:self
                didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
                   contextInfo:[[NSDictionary dictionaryWithObjectsAndKeys:
                                                    @"MixedLineEndingsAlert", @"Alert",
                                                    [sortedLineEndingStatsKeys objectAtIndex:4], @"LineEnding",
                                                    nil] retain]];
        }
    }
}

- (id)handleShowScriptCommand:(NSScriptCommand *)command {
    [self showWindows];
    return nil;
}

- (void)showWindows {    
    BOOL closeTransient = transientDocument && transientDocument != self
                          && NSEqualRects(transientDocumentWindowFrame, [[[transientDocument topmostWindowController] window] frame])
                          && [[[NSUserDefaults standardUserDefaults] objectForKey:OpenDocumentOnStartPreferenceKey] boolValue];

    if (I_documentProxyWindowController) {
        [[I_documentProxyWindowController window] orderFront:self];
    } else {
        PlainTextWindowController *windowController = [self topmostWindowController];
        if (closeTransient) {
            NSWindow *window = [windowController window];
            [window setFrameTopLeftPoint:NSMakePoint(transientDocumentWindowFrame.origin.x, NSMaxY(transientDocumentWindowFrame))];
        }
        [windowController selectTabForDocument:self];
        [[windowController tabBar] updateViewsHack];
        if (closeTransient) [[windowController window] orderFront:self]; // stop cascading
        [windowController showWindow:self];
    }
    
    if (closeTransient && ![self isProxyDocument]) {
        [transientDocument close];
        transientDocument = nil;
    }
    
    if ([[DocumentController sharedInstance] isOpeningUntitledDocument] && [[AppController sharedInstance] lastShouldOpenUntitledFile]) {
        transientDocument = self;
        transientDocumentWindowFrame = [[[transientDocument topmostWindowController] window] frame];
    }
}

- (void)TCM_validateSizeAndLineEndings {
    if ([I_textStorage length] > [[NSUserDefaults standardUserDefaults] integerForKey:@"StringLengthToStopHighlightingAndWrapping"]) {
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
        [alert setAlertStyle:NSInformationalAlertStyle];
        [alert setMessageText:NSLocalizedString(@"Syntax Highlighting and Wrap Lines have been turned off due to the size of the Document.", @"BigFile Message Text")];
        [alert setInformativeText:NSLocalizedString(@"Turning on Syntax Highlighting for very large Documents is not recommended.", @"BigFile Informative Text")];
        [alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
        [self presentAlert:alert
             modalDelegate:self
            didEndSelector:@selector(bigDocumentAlertDidEnd:returnCode:contextInfo:)
               contextInfo:nil];
    } else {
        [self TCM_validateLineEndings];
    }
}

- (void)bigDocumentAlertDidEnd:(NSAlert *)anAlert returnCode:(int)aReturnCode  contextInfo:(void  *)aContextInfo {
    [[anAlert window] orderOut:self];
    [self TCM_validateLineEndings];
}

- (NSWindow *)windowForSheet {
    NSWindow *result=[[self topmostWindowController] window];
    if (!result && I_documentProxyWindowController) {
        result = [I_documentProxyWindowController window];
    }
    return result;
}

- (void)windowControllerWillLoadNib:(NSWindowController *)aController {
    [super windowControllerWillLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
    [super windowControllerDidLoadNib:aController];
    DocumentMode *mode=[self documentMode];
    [(PlainTextWindowController *)aController setSizeByColumns:[[mode defaultForKey:DocumentModeColumnsPreferenceKey] intValue] rows:[[mode defaultForKey:DocumentModeRowsPreferenceKey] intValue]];
}

static CFURLRef CFURLFromAEDescAlias(const AEDesc *theDesc) {
    OSErr err;
    AliasHandle localAlias;
    long length;
    CFURLRef theURLRef;
            /* init result */
    theURLRef = NULL;
            /* get alias */
    length = AEGetDescDataSize(theDesc);
    localAlias = (AliasHandle)NewHandle(length);
    if (localAlias != NULL) {
        err = AEGetDescData(theDesc, *localAlias, length);
        if (err == noErr) {
            FSRef target;
            Boolean wasChanged;
            err = FSResolveAlias(NULL, localAlias, &target, &wasChanged);
            if (err == noErr) {
                theURLRef = CFURLCreateFromFSRef(NULL, &target);
            }
        }
        DisposeHandle((Handle)localAlias);
    }
    return theURLRef;
}

- (void)handleOpenDocumentEvent {
    DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel, @"handleOpenDocumentEvent");
    NSAppleEventDescriptor *eventDesc = [[NSAppleEventManager sharedAppleEventManager] currentAppleEvent];
    if (!([eventDesc eventClass] == kCoreEventClass && [eventDesc eventID] == kAEOpenDocuments)) {
        return;
    }

    DEBUGLOG(@"FileIOLogDomain", DetailedLogLevel, @"%@", [eventDesc description]);

    // Retrieve ODB parameters

    // keyFileSender/typeType
    NSAppleEventDescriptor *fileSenderDesc = [[eventDesc paramDescriptorForKeyword:keyFileSender] coerceToDescriptorType:typeType];

    // keyFileSenderToken/typeWildCard(typeList)
    NSAppleEventDescriptor *senderTokenDesc = nil;
    NSAppleEventDescriptor *senderTokenListDesc = [[eventDesc paramDescriptorForKeyword:keyFileSenderToken] coerceToDescriptorType:typeAEList];
    if (!senderTokenListDesc) {
        DEBUGLOG(@"FileIOLogDomain", DetailedLogLevel, @"odb token is probably not a list");
        senderTokenDesc = [[eventDesc paramDescriptorForKeyword:keyFileSenderToken] coerceToDescriptorType:typeWildCard];
    } else {
        DEBUGLOG(@"FileIOLogDomain", DetailedLogLevel, @"odb tokens were put in a list");

    }
    
    // keyFileCustomPath/
    NSAppleEventDescriptor *customPathDesc = nil;
    NSAppleEventDescriptor *customPathListDesc = [[eventDesc paramDescriptorForKeyword:keyFileCustomPath] coerceToDescriptorType:typeAEList];
    if (!customPathListDesc) {
        DEBUGLOG(@"FileIOLogDomain", DetailedLogLevel, @"odb custom path is probably not a list");
        customPathDesc = [eventDesc paramDescriptorForKeyword:keyFileCustomPath];
    } else {
        DEBUGLOG(@"FileIOLogDomain", DetailedLogLevel, @"odb custom paths were put in a list");

    }

    // look for AEPropData appended by LaunchServices
    NSAppleEventDescriptor *propDataAEDesc = [[eventDesc paramDescriptorForKeyword:keyAEPropData] coerceToDescriptorType:typeWildCard];
    if (propDataAEDesc) {
        if (fileSenderDesc == nil) {
            fileSenderDesc = [[propDataAEDesc paramDescriptorForKeyword:keyFileSender] coerceToDescriptorType:typeType];
        }
        if (senderTokenListDesc == nil && senderTokenDesc == nil) {
            senderTokenDesc = [[propDataAEDesc paramDescriptorForKeyword:keyFileSenderToken] coerceToDescriptorType:typeWildCard];
        }
    }
    
    // coerce the document list into a list of CFURLRefs
    NSAppleEventDescriptor *aliasesDesc = [[eventDesc descriptorForKeyword:keyDirectObject] coerceToDescriptorType:typeAEList];
    int numberOfItems = [aliasesDesc numberOfItems];
    int i;
    for (i = 1; i <= numberOfItems; i++) {
        NSAppleEventDescriptor *aliasDesc = [[aliasesDesc descriptorAtIndex:i] coerceToDescriptorType:typeAlias];
        if (aliasDesc) {
            DEBUGLOG(@"FileIOLogDomain", DetailedLogLevel, @"alias: %@", [aliasDesc description]);
            NSURL *fileURL = (NSURL *)CFURLFromAEDescAlias([aliasDesc aeDesc]);
            NSString *filePath = [[fileURL path] stringByStandardizingPath];
            if ([filePath isEqualToString:[[self fileName] stringByStandardizingPath]]) {

                // selection may be included in Xcode event
                NSAppleEventDescriptor *selectionDesc = [[eventDesc paramDescriptorForKeyword:keyAEPosition] coerceToDescriptorType:typeChar];
                if (selectionDesc) {
                    struct SelectionRange *selectionRange = nil;
                    selectionRange = (struct SelectionRange *)[[selectionDesc data] bytes];
                    DEBUGLOG(@"FileIOLogDomain", DetailedLogLevel, @"lineNum: %d\nstartRange: %d\nendRange: %d", selectionRange->lineNum, selectionRange->startRange, selectionRange->endRange);
                    if (selectionRange->lineNum < 0) {
                        DEBUGLOG(@"FileIOLogDomain", DetailedLogLevel, @"selectRange");
                        [self selectRange:NSMakeRange(selectionRange->startRange, selectionRange->endRange - selectionRange->startRange)];
                    } else {
                        DEBUGLOG(@"FileIOLogDomain", DetailedLogLevel, @"gotoLine");
                        [self gotoLine:selectionRange->lineNum + 1 orderFront:NO];
                    }
                }

                // save ODB parameters in case of ODB event
                NSMutableDictionary *ODBParameters = [NSMutableDictionary dictionary];
                if (fileSenderDesc) {
                    [ODBParameters setObject:[fileSenderDesc data] forKey:@"keyFileSender"];
                }

                if (customPathListDesc) {
                    NSAppleEventDescriptor *customPathDesc = [customPathListDesc descriptorAtIndex:i];
                    if (customPathDesc) {
                        [ODBParameters setObject:[customPathDesc stringValue] forKey:@"keyFileCustomPath"];
                    }
                } else if (customPathDesc) {
                    [ODBParameters setObject:[customPathDesc stringValue] forKey:@"keyFileCustomPath"];
                }
                
                if (senderTokenListDesc) {
                    NSAppleEventDescriptor *tokenDesc = [senderTokenListDesc descriptorAtIndex:i];
                    if (tokenDesc) {
                        DEBUGLOG(@"FileIOLogDomain", DetailedLogLevel, @"use item in odb list: %d", i);
                        [ODBParameters setObject:tokenDesc forKey:@"keyFileSenderToken"];
                    } else {
                        DEBUGLOG(@"FileIOLogDomain", DetailedLogLevel, @"trying first item in odb token list");
                        tokenDesc = [senderTokenListDesc descriptorAtIndex:1];
                        if (tokenDesc) {
                            [ODBParameters setObject:tokenDesc forKey:@"keyFileSenderToken"];
                        } else {
                            DEBUGLOG(@"FileIOLogDomain", DetailedLogLevel, @"first one in the odb token list didn't work");
                        }
                    }
                } else if (senderTokenDesc) {
                    [ODBParameters setObject:senderTokenDesc forKey:@"keyFileSenderToken"];
                }

                DEBUGLOG(@"FileIOLogDomain", DetailedLogLevel, @"retrieved ODB parameters: %@", [ODBParameters description]);
                [self setODBParameters:ODBParameters];
            }
            [fileURL release];
        }
    }
    [[self windowControllers] makeObjectsPerformSelector:@selector(synchronizeWindowTitleWithDocumentName)];
}

- (void)runModalSavePanelForSaveOperation:(NSSaveOperationType)saveOperation delegate:(id)delegate didSaveSelector:(SEL)didSaveSelector contextInfo:(void *)contextInfo {
    I_lastSaveOperation = saveOperation;
    [super runModalSavePanelForSaveOperation:saveOperation delegate:delegate didSaveSelector:didSaveSelector contextInfo:contextInfo];
}

- (BOOL)shouldRunSavePanelWithAccessoryView {
	
    return YES;
}

#pragma mark -
#pragma mark ### Export ###

- (IBAction)exportDocument:(id)aSender {
    /*  Sheet with options
        then sheet with save panel
        finish
    */
    if (!O_exportSheet)
        [NSBundle loadNibNamed: @"Export" owner: self];
        
    [O_exportSheetController setContent:[[[self documentMode] defaults] objectForKey:DocumentModeExportPreferenceKey]];
    [NSApp beginSheet: O_exportSheet
            modalForWindow: [self windowForSheet]
            modalDelegate:  self
            didEndSelector: @selector(continueExport:returnCode:contextInfo:)
            contextInfo:    nil];

}

- (IBAction)cancelExport:(id)aSender {
    [NSApp endSheet:O_exportSheet returnCode:NSCancelButton];
}

- (IBAction)continueExport:(id)aSender {
    [NSApp endSheet:O_exportSheet returnCode:NSOKButton];
}

- (void)continueExport:(NSWindow *)aSheet returnCode:(int)aReturnCode contextInfo:(void *)aContextInfo {
    [aSheet orderOut:self];
    if (aReturnCode == NSOKButton) {
        NSSavePanel *savePanel=[NSSavePanel savePanel];
        [savePanel setPrompt:NSLocalizedString(@"ExportPrompt",@"Text on the active SavePanel Button in the export sheet")];
        [savePanel setCanCreateDirectories:YES];
        [savePanel setExtensionHidden:NO];
        [savePanel setAllowsOtherFileTypes:YES];
        [savePanel setTreatsFilePackagesAsDirectories:YES];
        [savePanel setRequiredFileType:@"html"];
        [savePanel beginSheetForDirectory:nil 
            file:[[[[self displayName] lastPathComponent] stringByDeletingPathExtension] stringByAppendingPathExtension:@"html"] 
            modalForWindow:[self windowForSheet] 
            modalDelegate:self 
            didEndSelector:@selector(exportPanelDidEnd:returnCode:contextInfo:) contextInfo:nil];
    }
}

- (void)exportPanelDidEnd:(NSSavePanel *)aPanel returnCode:(int)aReturnCode contextInfo:(void *)aContextInfo {
    if (aReturnCode==NSOKButton) {
        NSDictionary *htmlOptions=[[[[self documentMode] defaults] objectForKey:DocumentModeExportPreferenceKey] objectForKey:DocumentModeExportHTMLPreferenceKey];
        TextStorage *textStorage = (TextStorage *)I_textStorage;
        
        if ([[htmlOptions objectForKey:DocumentModeHTMLExportHighlightSyntaxPreferenceKey] boolValue]) {
            SyntaxHighlighter *highlighter=[I_documentMode syntaxHighlighter];
            if (highlighter)
                while (![highlighter colorizeDirtyRanges:textStorage ofDocument:self]);
        } else {
            textStorage = [[TextStorage new] autorelease];
            [textStorage setAttributedString:I_textStorage];
            [[I_documentMode syntaxHighlighter] cleanUpTextStorage:textStorage];
            [textStorage  addAttributes:[self plainTextAttributes]
                                  range:NSMakeRange(0,[textStorage length])];
        }

        BOOL shouldSaveImages=[[htmlOptions objectForKey:DocumentModeHTMLExportShowParticipantsPreferenceKey] boolValue] &&
                              [[htmlOptions objectForKey:DocumentModeHTMLExportShowUserImagesPreferenceKey] boolValue];
        
        static NSDictionary *baseAttributeMapping;
        if (baseAttributeMapping==nil) {
            baseAttributeMapping=[NSDictionary dictionaryWithObjectsAndKeys:
                                [NSDictionary dictionaryWithObjectsAndKeys:
                                    @"<strong>",@"openTag",
                                    @"</strong>",@"closeTag",nil], @"Bold",
                                [NSDictionary dictionaryWithObjectsAndKeys:
                                    @"<em>",@"openTag",
                                    @"</em>",@"closeTag",nil], @"Italic",
                                [NSDictionary dictionaryWithObjectsAndKeys:
                                    @"<span style=\"color:%@;\">",@"openTag",
                                    @"</span>",@"closeTag",nil], @"ForegroundColor",
                                [NSDictionary dictionaryWithObjectsAndKeys:
                                    @"<span class=\"%@\">",@"openTag",
                                    @"</span>",@"closeTag",nil], @"ChangedByShortUserID",
                                [NSDictionary dictionaryWithObjectsAndKeys:
                                    @"<a title=\"%@\">",@"openTag",
                                    @"</a>",@"closeTag",nil], @"WrittenBy",
                                nil];
            [baseAttributeMapping retain];
        }
    
        NSString *htmlFile=[aPanel filename];
        NSString *imageDirectory=@"";
        NSString *imageDirectoryPrefix=@"";
        if (shouldSaveImages) {
            NSFileManager *fileManager=[NSFileManager defaultManager];
            imageDirectoryPrefix=[[[htmlFile lastPathComponent] stringByDeletingPathExtension] stringByAppendingString:@"_images"];
            imageDirectory=[[htmlFile stringByDeletingLastPathComponent] stringByAppendingPathComponent:imageDirectoryPrefix];
            BOOL isDir = NO;
            if (([fileManager fileExistsAtPath:imageDirectory isDirectory:&isDir] && isDir) ||
                 [fileManager createDirectoryAtPath:imageDirectory attributes:nil]) {
                imageDirectoryPrefix = [imageDirectoryPrefix stringByAppendingString:@"/"];
            } else {
                imageDirectory = [htmlFile stringByDeletingLastPathComponent];
                imageDirectoryPrefix = @"";
            }
        }
        
        TCMMMUserManager *userManager=[TCMMMUserManager sharedInstance];
        NSMutableString *metaHeaders=[NSMutableString string];
        NSCalendarDate *now=[NSCalendarDate calendarDate];
        NSString *metaFormatString=@"<meta name=\"%@\" content=\"%@\" />\n";
        [metaHeaders appendFormat:metaFormatString,@"last-modified",[now rfc1123Representation]];
        [metaHeaders appendFormat:metaFormatString,@"DC.Date",[now descriptionWithCalendarFormat:@"%Y-%m-%d"]];
        [metaHeaders appendFormat:metaFormatString,@"DC.Creator",[[[userManager me] name] stringByReplacingEntitiesForUTF8:NO]];
        
      
        NSMutableSet *shortContributorIDs=[[NSMutableSet new] autorelease];
        
        // Load Templates
        NSString *templateDirectory=[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"HTMLExport"];
        NSString *documentBase=[[[NSString alloc] initWithData:[NSData dataWithContentsOfFile:[templateDirectory stringByAppendingPathComponent:@"Base.html"]] 
                                        encoding:NSUTF8StringEncoding] autorelease];
        NSString *styleSheetBase=[[[NSString alloc] initWithData:[NSData dataWithContentsOfFile:[templateDirectory stringByAppendingPathComponent:@"Base.css"]] 
                                        encoding:NSUTF8StringEncoding] autorelease];
        NSMutableString *styleSheet=[NSMutableString stringWithFormat:styleSheetBase];
        
        NSValueTransformer *hueTrans=[NSValueTransformer valueTransformerForName:@"HueToColor"];
    
        // ShortID users
        BOOL colorConflict=NO;
        NSMutableSet *userColors=[NSMutableSet new];
        NSMutableArray *contributorDictionaries=[NSMutableArray array];
        NSMutableArray *lurkerDictionaries=[NSMutableArray array];
        NSMutableDictionary *contributorDictionary=[NSMutableDictionary dictionary];
        NSSet *contributorIDs=[self userIDsOfContributors];
        NSEnumerator *contributorEnumerator=[[[self session] contributors] objectEnumerator];
        TCMMMUser *contributor=nil;
        NSCharacterSet *validCharacters=[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"];
        while ((contributor=[contributorEnumerator nextObject])) {
            [metaHeaders appendFormat:metaFormatString,@"DC.Contributor",[[contributor name] stringByReplacingEntitiesForUTF8:YES]];

            NSScanner *scanner=[NSScanner scannerWithString:[contributor name]];
            [scanner setCharactersToBeSkipped:[validCharacters invertedSet]];
            NSMutableString *IDBasis=[NSMutableString string];
            while (![scanner isAtEnd]) {
                NSString *scannedString;
                if ([scanner scanCharactersFromSet:validCharacters intoString:&scannedString]) {
                    [IDBasis appendString:scannedString];
                }
            }
            if ([IDBasis length]==0) {
                [IDBasis appendString:@"u"];
            }
            NSString *IDString=IDBasis;
            int i;
            for (i=1;[shortContributorIDs containsObject:IDString];i++) {
                IDString = [NSString stringWithFormat:@"%@%d",IDBasis,i];
            }
            [shortContributorIDs addObject:IDString];
            if (shouldSaveImages) {
                [[[contributor properties] objectForKey:@"ImageAsPNG"] writeToFile:[imageDirectory stringByAppendingPathComponent:[IDString stringByAppendingPathExtension:@"png"]] atomically:YES];
            }
            NSDictionary *dictionary=[NSDictionary dictionaryWithObjectsAndKeys:contributor,@"User",IDString,@"ShortID",nil];
            if ([contributorIDs containsObject:[contributor userID]]) {
                [contributorDictionary   setObject:dictionary forKey:[contributor userID]];
                [contributorDictionaries addObject:dictionary];
                if ([userColors containsObject:[hueTrans reverseTransformedValue:[contributor changeColor]]]) {
                    colorConflict=YES;
                }
                [userColors addObject:[hueTrans reverseTransformedValue:[contributor changeColor]]];
            } else {
                [lurkerDictionaries addObject:dictionary];
            }
        }
    
        NSSortDescriptor *nameDescriptor=[[[NSSortDescriptor alloc] initWithKey:@"User.name" 
                  ascending:YES
                  selector:@selector(caseInsensitiveCompare:)] autorelease];
        [contributorDictionaries sortUsingDescriptors:[NSArray arrayWithObject:nameDescriptor]];
        [lurkerDictionaries      sortUsingDescriptors:[NSArray arrayWithObject:nameDescriptor]];
    
        NSEnumerator *contributorDictionaryEnumerator=[contributorDictionaries objectEnumerator];
        NSDictionary *contributorDict=nil;
        int i=0;
    
        while ((contributorDict=[contributorDictionaryEnumerator nextObject])) {
            NSColor *color=colorConflict?
                    [hueTrans transformedValue:[NSNumber numberWithFloat:(float)i/[contributorDictionaries count]*100.]]:
                    [[contributorDict objectForKey:@"User"] changeColor];
            
            NSColor *userColor=[[self documentBackgroundColor] blendedColorWithFraction:[[NSUserDefaults standardUserDefaults] floatForKey:ChangesSaturationPreferenceKey]/100.
                                 ofColor:color];
            [styleSheet appendFormat:@".%@ {\n    background-color: %@;\n}\n\n",[contributorDict objectForKey:@"ShortID"],[userColor HTMLString]];
            i++;
        }
        
        // prepare DisplayName
        NSString *displayName=[[self displayName] stringByReplacingEntitiesForUTF8:YES];
        
        // modify TextStorage
        NSRange wholeRange=NSMakeRange(0,[[self textStorage] length]);
        NSMutableAttributedString *attributedStringForXHTML=[(TextStorage *)textStorage attributedStringForXHTMLExportWithRange:wholeRange foregroundColor:[self documentForegroundColor] backgroundColor:[self documentBackgroundColor]];
        
        unsigned index=0;
        do {
            NSRange foundRange;
            NSString *authorID=[attributedStringForXHTML attribute:@"ChangedByUserID" atIndex:index 
                                 longestEffectiveRange:&foundRange inRange:wholeRange];
            index=NSMaxRange(foundRange);
            if (authorID) {
                [attributedStringForXHTML addAttribute:@"ChangedByShortUserID" value:[[contributorDictionary objectForKey:authorID] objectForKey:@"ShortID"] range:foundRange];
            }
        } while (index<NSMaxRange(wholeRange));
            
        // Prepare Legend
        NSMutableString *legend=[NSMutableString string];
        int tableSpan=1;
        BOOL shouldShowAIMAndEmail=[[htmlOptions objectForKey:DocumentModeHTMLExportShowAIMAndEmailPreferenceKey] boolValue];
        if (shouldSaveImages) tableSpan++;
        if (shouldShowAIMAndEmail) tableSpan++;  
        // Contriburtors and lurkers as Table
        // lurkers as Table
        if ([[htmlOptions objectForKey:DocumentModeHTMLExportShowParticipantsPreferenceKey] boolValue]) {
            [legend appendString:@"<table>"];
            if ([contributorDictionaries count]) {
                NSString *contributorForegroundColor=@"";
                if (![[self documentForegroundColor] isDark]) {
                    contributorForegroundColor=[NSString stringWithFormat:@" style=\"color:%@;\"",[[self documentForegroundColor] HTMLString]];
                }
                [legend appendFormat:@"<tr><th colspan=\"%d\">%@</th></tr>\n",tableSpan,NSLocalizedString(@"Contributors",@"Title for Contributors in Export and Print")];
                NSEnumerator *contributorDictionaryEnumerator=[contributorDictionaries objectEnumerator];
                NSDictionary *contributorDict=nil;
                while ((contributorDict=[contributorDictionaryEnumerator nextObject])) {
                    NSString *name=[[contributorDict valueForKeyPath:@"User.name"] stringByReplacingEntitiesForUTF8:YES];
                    NSString *shortID=[contributorDict valueForKeyPath:@"ShortID"];
                    NSString *aim=[[contributorDict valueForKeyPath:@"User.properties.AIM"] stringByReplacingEntitiesForUTF8:YES];
                    NSString *email=[[contributorDict valueForKeyPath:@"User.properties.Email"] stringByReplacingEntitiesForUTF8:YES];
                    [legend appendFormat:@"<tr>",shortID];
                    if (shouldSaveImages) {
                        [legend appendFormat:@"<th><img src=\"%@%@.png\" width=\"32\" height=\"32\" alt=\"%@\"/></th>",imageDirectoryPrefix,shortID,name, name];
                    }
                    [legend appendFormat:@"<td class=\"ContributorName %@\"%@>%@</td>",shortID,contributorForegroundColor,name];
                    if (shouldShowAIMAndEmail) {
                        [legend appendString:@"<td>"];
                        if ([aim length]) {
                            [legend appendFormat:@"%@ <a href=\"aim:goim?screenname=%@\">%@</a>",NSLocalizedString(@"PrintExportLegendAIMLabel",@"Label for AIM in legend in Print and Export"),aim,aim];
                        }
                        [legend appendString:@"<br />"];
                        if ([email length]) {
                            [legend appendFormat:@"%@ <a href=\"mailto:%@\">%@</a>",NSLocalizedString(@"PrintExportLegendEmailLabel",@"Label for Email in legend in Print and Export"),email,email];
                        }
                        [legend appendString:@"</td>"];
                    }
                    [legend appendString:@"</tr>\n"];
                }
                
            }
            if ([lurkerDictionaries count] && [[htmlOptions objectForKey:DocumentModeHTMLExportShowVisitorsPreferenceKey] boolValue]) {
                [legend appendFormat:@"<tr><th colspan=\"%d\">%@</th></tr>\n",tableSpan,NSLocalizedString(@"Visitors",@"Title for Visitors in Export and Print")];
                NSEnumerator *lurkers=[lurkerDictionaries objectEnumerator];
                NSDictionary *lurker=nil;
                int alternateFlag=0;
                while ((lurker=[lurkers nextObject])) {
                    NSString *name   =[[lurker valueForKeyPath:@"User.name"] stringByReplacingEntitiesForUTF8:YES];
                    NSString *shortID= [lurker valueForKeyPath:@"ShortID"];
                    NSString *aim    =[[lurker valueForKeyPath:@"User.properties.AIM"] stringByReplacingEntitiesForUTF8:YES];
                    NSString *email  =[[lurker valueForKeyPath:@"User.properties.Email"] stringByReplacingEntitiesForUTF8:YES];
                    [legend appendFormat:@"<tr%@>",alternateFlag?@" class=\"Alternate\"":@""];
                    if (shouldSaveImages) {
                        [legend appendFormat:@"<th><img src=\"%@%@.png\" width=\"32\" height=\"32\" alt=\"%@\"/></th>",imageDirectoryPrefix,shortID,name, name];
                    }
                    [legend appendFormat:@"<td class=\"VisitorName\">%@</td>",name];
                    if (shouldShowAIMAndEmail) {
                        [legend appendString:@"<td>"];
                        if ([aim length]) {
                            [legend appendFormat:@"%@ <a href=\"aim:goim?screenname=%@\">%@</a>",NSLocalizedString(@"PrintExportLegendAIMLabel",@"Label for AIM in legend in Print and Export"),aim,aim];
                        }
                        [legend appendString:@"<br />"];
                        if ([email length]) {
                            [legend appendFormat:@"%@ <a href=\"mailto:%@\">%@</a>",NSLocalizedString(@"PrintExportLegendEmailLabel",@"Label for Email in legend in Print and Export"),email,email];
                        }
                        [legend appendString:@"</td>"];
                    }
                    [legend appendString:@"</tr>\n"];
                    alternateFlag=1-alternateFlag;
                }
            }
            [legend appendString:@"</table>\n"];
        }  
          
        // Prepare Content    
        NSMutableString *content=[NSMutableString string];
        NSUserDefaults *standardUserDefaults=[NSUserDefaults standardUserDefaults];
        if ([[htmlOptions objectForKey:DocumentModeHTMLExportAddCurrentDatePreferenceKey] boolValue]) {
            [content appendFormat:@"<p>%@</p>",[[NSCalendarDate calendarDate] descriptionWithCalendarFormat:[standardUserDefaults objectForKey:NSDateFormatString] locale:(id)standardUserDefaults]];
        }
        NSString *fontString=@"";
        if ([[self fontWithTrait:0] isFixedPitch] || 
            [@"Monaco" isEqualToString:[[self fontWithTrait:0] fontName]]) {
            fontString=@"font-size:small; font-family:monospace; ";
        } 
        [attributedStringForXHTML detab:YES inRange:wholeRange tabWidth:[self tabWidth] askingTextView:nil];
        BOOL wrapsLines=[self wrapLines];
        NSString *topLevelTag=wrapsLines?@"div":@"pre";
        if (wrapsLines) {
            [attributedStringForXHTML makeLeadingWhitespaceNonBreaking];
        }
        NSMutableDictionary *mapping=[[baseAttributeMapping mutableCopy] autorelease];
        if (![[htmlOptions objectForKey:DocumentModeHTMLExportWrittenByHoversPreferenceKey] boolValue]) {
            [mapping removeObjectForKey:@"WrittenBy"];
        }
        if (![[htmlOptions objectForKey:DocumentModeHTMLExportShowChangeMarksPreferenceKey] boolValue]) {
            [mapping removeObjectForKey:@"ChangedByShortUserID"];
        }
        NSMutableString *innerContent=[attributedStringForXHTML XHTMLStringWithAttributeMapping:mapping forUTF8:YES];
        if (wrapsLines) {
            [innerContent addBRs];
        }
        [content appendFormat:@"<%@ style=\"text-align:left;color:%@; background-color:%@; border:solid black 1px; padding:0.5em 1em 0.5em 1em; overflow:auto;%@\">",topLevelTag, [[self documentForegroundColor] HTMLString],[[self documentBackgroundColor] HTMLString],fontString];
        [content appendString:innerContent];
        [content appendFormat:@"</%@>",topLevelTag];
    
    
        // finish creation :-)    
        NSString *result=[NSString stringWithFormat:documentBase,displayName,styleSheet,legend,content,metaHeaders];
        [[result dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO] writeToFile:htmlFile atomically:YES];
        if (!I_flags.highlightSyntax && 
            [[htmlOptions objectForKey:DocumentModeHTMLExportHighlightSyntaxPreferenceKey] boolValue]) {
            [self setHighlightsSyntax:YES];
            [self setHighlightsSyntax:NO];
        }
    }
}

#pragma mark -
#pragma mark ### Save/Open Panel loading ###

- (IBAction)goIntoBundles:(id)sender {
    BOOL flag = ([sender state] == NSOffState) ? NO : YES;
    [I_savePanel setTreatsFilePackagesAsDirectories:flag];
    [[NSUserDefaults standardUserDefaults] setBool:flag forKey:@"GoIntoBundlesPrefKey"];
}

- (IBAction)showHiddenFiles:(id)sender {
    BOOL flag = ([sender state] == NSOffState) ? NO : YES;
    if ([I_savePanel canShowHiddenFiles]) {
        [I_savePanel setInternalShowsHiddenFiles:flag];
    }
    [[NSUserDefaults standardUserDefaults] setBool:flag forKey:@"ShowsHiddenFiles"];    
}

- (NSString *)panel:(id)sender userEnteredFilename:(NSString *)filename confirmed:(BOOL)okFlag
{
    if (okFlag) {
        NSString *panelFileName = [sender filename];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
        BOOL isDir;
        if ([fileManager fileExistsAtPath:panelFileName isDirectory:&isDir] && isDir && ![workspace isFilePackageAtPath:panelFileName]) {
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setAlertStyle:NSInformationalAlertStyle];
            [alert setMessageText:[NSString stringWithFormat:NSLocalizedString(@"The document can not be saved with the name \"%@\" because a folder with the same name already exists.", nil), filename]];
            [alert setInformativeText:NSLocalizedString(@"Try choosing a different name for the document.", nil)];
            [alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
            (void)[alert runModal];
            [[alert window] orderOut:self];
            [alert release];
            return nil;
        }
    }
    
    return filename;
}

- (void)setTemporarySavePanel:(NSSavePanel *)aPanel {
	if (aPanel != I_savePanel) {
		if (I_savePanel && [I_savePanel delegate] == self) {
			[I_savePanel setDelegate:nil];
		}
		[I_savePanel autorelease];
		 I_savePanel = [aPanel retain];
	}
}

- (void) _savePanelWasPresented:(id)aPanel withResult:(int)aResult inContext:(void*) aContext; {
	[I_savePanel setDelegate:nil];
	if (aResult == NSCancelButton) {	
		[self setTemporarySavePanel:nil];
	}
	[super _savePanelWasPresented:aPanel withResult:aResult inContext:aContext];
}
    
- (BOOL)prepareSavePanel:(NSSavePanel *)savePanel {
	
    if (![NSBundle loadNibNamed:@"SavePanelAccessory" owner:self])  {
        NSLog(@"Failed to load SavePanelAccessory.nib");
        return NO;
    }
    
    BOOL isGoingIntoBundles = [[NSUserDefaults standardUserDefaults] boolForKey:@"GoIntoBundlesPrefKey"];
    [savePanel setTreatsFilePackagesAsDirectories:isGoingIntoBundles];
    
    BOOL showsHiddenFiles = [[NSUserDefaults standardUserDefaults] boolForKey:@"ShowsHiddenFiles"];
    if ([savePanel canShowHiddenFiles]) {
        [savePanel setInternalShowsHiddenFiles:showsHiddenFiles];
    }    

    [savePanel setExtensionHidden:NO];
    [savePanel performSelector:@selector(setExtensionHidden:) withObject:nil afterDelay:0.0];
    [savePanel setCanSelectHiddenExtension:NO];

    [self setTemporarySavePanel:savePanel];
    [savePanel setDelegate:self];

    if (![self fileName] && [self directoryForSavePanel]) {
        [savePanel setDirectory:[self directoryForSavePanel]];
    }

    if (I_lastSaveOperation == NSSaveToOperation) {
        NSArray *encodings = [[EncodingManager sharedInstance] enabledEncodings];
        NSMutableArray *lossyEncodings = [NSMutableArray array];
        unsigned int i;
        for (i = 0; i < [encodings count]; i++) {
            if (![[I_textStorage string] canBeConvertedToEncoding:[[encodings objectAtIndex:i] unsignedIntValue]]) {
                [lossyEncodings addObject:[encodings objectAtIndex:i]];
            }
        }
        [[EncodingManager sharedInstance] registerEncoding:[self fileEncoding]];
        [O_encodingPopUpButton setEncoding:[self fileEncoding] defaultEntry:NO modeEntry:NO lossyEncodings:lossyEncodings];
        
        [O_savePanelAccessoryFileFormatMatrix selectCellWithTag:I_flags.isSEEText?1:0];

        [savePanel setAccessoryView:O_savePanelAccessoryView];
        [O_goIntoBundlesCheckbox setState:isGoingIntoBundles ? NSOnState : NSOffState];
        if ([savePanel canShowHiddenFiles]) {
            [O_showHiddenFilesCheckbox setState:showsHiddenFiles ? NSOnState : NSOffState];
        } else {
            [O_showHiddenFilesCheckbox setHidden:YES];
        }
    } else {
        [savePanel setAccessoryView:O_savePanelAccessoryView2];
        [O_goIntoBundlesCheckbox2 setState:isGoingIntoBundles ? NSOnState : NSOffState];
        if ([savePanel canShowHiddenFiles]) {
            [O_showHiddenFilesCheckbox2 setState:showsHiddenFiles ? NSOnState : NSOffState];
        } else {
            [O_showHiddenFilesCheckbox2 setHidden:YES];
        }
        [O_savePanelAccessoryFileFormatMatrix2 selectCellWithTag:I_flags.isSEEText?1:0];
    }
	
    [O_savePanelAccessoryView release];
    O_savePanelAccessoryView = nil;
    
    [O_savePanelAccessoryView2 release];
    O_savePanelAccessoryView2 = nil;
	

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(savePanelDidBecomeKey:) name:NSWindowDidBecomeKeyNotification object:savePanel];
    return YES;
}

- (void)savePanelDidBecomeKey:(NSNotification *)aNotification {
	[[aNotification object] TCM_selectFilenameWithoutExtension];
    [[NSNotificationCenter defaultCenter] removeObserver:self  name:NSWindowDidBecomeKeyNotification object:[aNotification object]];
}

- (IBAction)selectFileFormat:(id)aSender {
    NSSavePanel *panel = (NSSavePanel *)[aSender window];
    NSString *seeTextExtension = [[[DocumentController sharedInstance] fileExtensionsFromType:@"SEETextType"] lastObject];
    if ([[aSender selectedCell] tag]==1) {
        [panel setRequiredFileType:seeTextExtension];
    } else {
        [panel setRequiredFileType:nil];
        NSTextField *nameField = [panel valueForKey:@"_nameField"];
        if (nameField && [nameField isKindOfClass:[NSTextField class]]) {
            NSString *name = [nameField stringValue];
            if ([[name pathExtension] isEqualToString:seeTextExtension]) {
                [nameField setStringValue:[name stringByDeletingPathExtension]];
            }
        }
    }
    [panel setExtensionHidden:NO];
    [panel TCM_selectFilenameWithoutExtension];
}


- (void)saveDocumentWithDelegate:(id)delegate didSaveSelector:(SEL)didSaveSelector contextInfo:(void *)contextInfo {
    if ([self TCM_validateDocument]) {
        [super saveDocumentWithDelegate:delegate didSaveSelector:didSaveSelector contextInfo:contextInfo];
    }
}

- (void)setPreservedDataFromSEETextFile:(NSArray *)aPreservedData {
    [I_preservedDataFromSEETextFile autorelease];
     I_preservedDataFromSEETextFile=[aPreservedData retain];
}

- (NSArray *)preservedDataFromSEETextFile {
    return I_preservedDataFromSEETextFile;
}

- (IBAction)playbackLoggingState:(id)aSender {
    TCMMMLoggingState *ls = [[self session] loggingState];
    NSArray *loggedOperations = [ls loggedOperations];
    unsigned opCount = [loggedOperations count];

    TextStorage *textStorage=(TextStorage *)[self textStorage];
    [textStorage setContentByDictionaryRepresentation:[ls initialTextStorageDictionaryRepresentation]];
    NSRange wholeRange=NSMakeRange(0,[textStorage length]);
    [textStorage addAttributes:[self plainTextAttributes] range:wholeRange];
    [textStorage addAttribute:NSParagraphStyleAttributeName value:[self defaultParagraphStyle] range:wholeRange];

    NSView *viewToUpdate = [[[self plainTextEditors] lastObject] editorView];
    [viewToUpdate display];
    
    unsigned i = 0;
    for (i=0;i<opCount;i++) {
        [self handleOperation:[[loggedOperations objectAtIndex:i] operation]];
        [viewToUpdate display];
    }
}

- (BOOL)isDocumentEdited {
    if (I_flags.isAutosavingForRestart) {
        return YES;
    } else {
        return [super isDocumentEdited];
    }
}

- (BOOL)hasUnautosavedChanges {
    if (I_flags.isAutosavingForRestart) {
        return YES;
    } else {
        return [super hasUnautosavedChanges];
    }
}

- (void)autosaveForRestart {
    I_flags.isAutosavingForRestart = YES;
    [self autosaveDocumentWithDelegate:nil didAutosaveSelector:NULL contextInfo:NULL];
    I_flags.isAutosavingForRestart = NO;
}

- (void)setAutosavedContentsFileURL:(NSURL *)anURL {
    NSURL *URLToDelete = nil;
    if (!anURL) {
        URLToDelete = [self autosavedContentsFileURL];
    }
    [super setAutosavedContentsFileURL:anURL];
    if (URLToDelete) {
        NSFileManager *fm = [NSFileManager defaultManager];
        if ([fm fileExistsAtPath:[URLToDelete path]]) {
            [fm removeFileAtPath:[URLToDelete path] handler:nil];
        }
    }
}

- (void)autosaveDocumentWithDelegate:(id)delegate didAutosaveSelector:(SEL)didAutosaveSelector contextInfo:(void *)aContext {
    // autosave to @"~/Library/Autosave Information/UUID.seetext"
    NSURL *autosaveURL = [self autosavedContentsFileURL];
    if ([self isDocumentEdited]) { 
        if (!autosaveURL) autosaveURL = [NSURL fileURLWithPath:[[NSString stringWithFormat:@"~/Library/Autosave Information/%@.seetext", [NSString UUIDString]] stringByStandardizingPath]];
        if (autosaveURL) [self setAutosavedContentsFileURL:autosaveURL];
        [super autosaveDocumentWithDelegate:delegate didAutosaveSelector:didAutosaveSelector contextInfo:aContext];
    } else if (autosaveURL) {
        [self setAutosavedContentsFileURL:nil];
    }
}

- (void)saveToURL:(NSURL *)anAbsoluteURL ofType:(NSString *)aType forSaveOperation:(NSSaveOperationType)saveOperation delegate:(id)delegate didSaveSelector:(SEL)didSaveSelector contextInfo:(void *)aContextInfo {
    BOOL didShowPanel=NO;
    if (saveOperation != NSAutosaveOperation) {
        didShowPanel = (I_savePanel)?YES:NO;
		[self setTemporarySavePanel:nil];
    }
    
    if (anAbsoluteURL) {
        if (I_flags.shouldSelectModeOnSave && (saveOperation != NSAutosaveOperation)) {
            DocumentMode *mode = [[DocumentModeManager sharedInstance] documentModeForPath:[anAbsoluteURL path] withContentString:[[self textStorage] string]];
			
            if (![mode isBaseMode]) {
                [self setDocumentMode:mode];
            }
            I_flags.shouldSelectModeOnSave=NO;
        }
        // we have saved, so no more extension changing
        if (I_flags.shouldChangeExtensionOnModeChange && (saveOperation != NSAutosaveOperation)) {
            I_flags.shouldChangeExtensionOnModeChange=NO;
        }

        if (saveOperation == NSSaveToOperation) {
            I_encodingFromLastRunSaveToOperation = [[O_encodingPopUpButton selectedItem] tag];
            if ([[O_savePanelAccessoryFileFormatMatrix selectedCell] tag] == 1) {
                aType = @"SEETextType";
             } else {
                aType = @"PlainTextType";
            }
         } else if (didShowPanel) {
            if ([[O_savePanelAccessoryFileFormatMatrix2 selectedCell] tag] == 1) {
                aType = @"SEETextType";
                I_flags.isSEEText = YES;
            } else {
                aType = @"PlainTextType";
                I_flags.isSEEText = NO;
            }
         }
    }
    if ([aType isEqualToString:@"SEETextType"]) {
        NSString *seeTextExtension = [[[DocumentController sharedInstance] fileExtensionsFromType:aType] lastObject];
        if (![[[anAbsoluteURL path] pathExtension] isEqualToString:seeTextExtension]) {
            anAbsoluteURL = [NSURL fileURLWithPath:[[anAbsoluteURL path] stringByAppendingPathExtension:seeTextExtension]];
        }
    }

    [super saveToURL:anAbsoluteURL ofType:aType forSaveOperation:saveOperation delegate:delegate didSaveSelector:didSaveSelector contextInfo:aContextInfo];
}

- (NSData *)dataOfType:(NSString *)aType error:(NSError **)outError{

    if ([aType isEqualToString:@"PlainTextType"] || [aType isEqualToString:@"SubEthaEditSyntaxStyle"]) {
        NSData *data;
        if (I_lastSaveOperation == NSSaveToOperation) {
            DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel, @"Save a copy using encoding: %@", [NSString localizedNameOfStringEncoding:I_encodingFromLastRunSaveToOperation]);
            [[EncodingManager sharedInstance] unregisterEncoding:I_encodingFromLastRunSaveToOperation];
            data = [[I_textStorage string] dataUsingEncoding:I_encodingFromLastRunSaveToOperation allowLossyConversion:YES];
        } else {
            DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel, @"Save using encoding: %@", [NSString localizedNameOfStringEncoding:[self fileEncoding]]);
            data = [[I_textStorage string] dataUsingEncoding:[self fileEncoding] allowLossyConversion:YES];
        }
        
        BOOL modeWantsUTF8BOM = [[[self documentMode] defaultForKey:DocumentModeUTF8BOMPreferenceKey] boolValue];
        DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel, @"modeWantsUTF8BOM: %d, hasUTF8BOM: %d", modeWantsUTF8BOM, I_flags.hasUTF8BOM);
        BOOL useUTF8Encoding = ((I_lastSaveOperation == NSSaveToOperation) && (I_encodingFromLastRunSaveToOperation == NSUTF8StringEncoding)) || ((I_lastSaveOperation != NSSaveToOperation) && ([self fileEncoding] == NSUTF8StringEncoding));

        if ((I_flags.hasUTF8BOM || modeWantsUTF8BOM) && useUTF8Encoding) {
            return [data dataPrefixedWithUTF8BOM];
        } else {
            return data;
        }
    }

    if (outError) *outError = [NSError errorWithDomain:@"SEEDomain" code:42 userInfo:
        [NSDictionary dictionaryWithObjectsAndKeys:
            [NSString stringWithFormat:@"Could not create data for Filetype: %@",aType],NSLocalizedDescriptionKey,
            nil
        ]
    ];
    return nil;
}

- (BOOL)revertToContentsOfURL:(NSURL *)anURL ofType:(NSString *)type error:(NSError **)outError {
    [[self plainTextEditors] makeObjectsPerformSelector:@selector(pushSelectedRanges)];
    BOOL success = [super revertToContentsOfURL:anURL ofType:type error:outError];
    if (success) {
        [self setFileName:[anURL path]];
    }
    [[self plainTextEditors] makeObjectsPerformSelector:@selector(popSelectedRanges)];
    return success;
}

- (NSDictionary *)TCM_propertiesOfCurrentSeeEvent {
    DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel, @"propertiesOfCurrentSeeEvent");
    NSAppleEventDescriptor *eventDesc = [[NSAppleEventManager sharedAppleEventManager] currentAppleEvent];
    if (!([eventDesc eventClass] == 'Hdra' && [eventDesc eventID] == 'See ')) {
        return nil;
    }
    
    DEBUGLOG(@"FileIOLogDomain", DetailedLogLevel, @"%@", [eventDesc description]);
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    NSString *IANACharSetName = [[eventDesc descriptorForKeyword:'Enc '] stringValue];
    if (IANACharSetName) {
        [parameters setObject:IANACharSetName forKey:@"IANACharSetName"];
        
    }
    NSString *modeName = [[eventDesc descriptorForKeyword:'Mode'] stringValue];
    if (modeName) {
        [parameters setObject:modeName forKey:@"ModeName"];
    }
    
    return parameters;
}

- (NSData *)TCM_dataWithContentsOfFileReadUsingAuthorizedHelper:(NSString *)fileName {
    OSStatus err = noErr;
    CFURLRef tool = NULL;
    NSDictionary *request = nil;
    NSDictionary *response = nil;
    NSData *fileData = nil;


    const char *kRightName = "de.codingmonkeys.SubEthaEdit.file.readwritecreate";
    static const AuthorizationFlags kAuthFlags = kAuthorizationFlagDefaults 
                                               | kAuthorizationFlagInteractionAllowed
                                               | kAuthorizationFlagExtendRights
                                               | kAuthorizationFlagPreAuthorize;
    AuthorizationItem   right  = { kRightName, 0, NULL, 0 };
    AuthorizationRights rights = { 1, &right };

    err = AuthorizationCopyRights(I_authRef, &rights, kAuthorizationEmptyEnvironment, kAuthFlags, NULL);
    
    if (err == noErr) {
        err = MoreSecCopyHelperToolURLAndCheckBundled(
            CFBundleGetMainBundle(), 
            CFSTR("SubEthaEditHelperToolTemplate"), 
            kApplicationSupportFolderType, 
            CFSTR("SubEthaEdit"), 
            CFSTR("SubEthaEditHelperTool"), 
            &tool);

        // If the home directory is on an volume that doesn't support 
        // setuid root helper tools, ask the user whether they want to use 
        // a temporary tool.
        
        if (err == kMoreSecFolderInappropriateErr) {
            err = MoreSecCopyHelperToolURLAndCheckBundled(
                CFBundleGetMainBundle(), 
                CFSTR("SubEthaEditHelperToolTemplate"), 
                kTemporaryFolderType, 
                CFSTR("SubEthaEdit"), 
                CFSTR("SubEthaEditHelperTool"), 
                &tool);
        }
    }
    
    // Create the request dictionary for a file descriptor

    if (err == noErr) {
        request = [NSDictionary dictionaryWithObjectsAndKeys:
                            @"GetReadOnlyFileDescriptor", @"CommandName",
                            fileName, @"FileName",
                            nil];
    }

    // Go go gadget helper tool!

    if (err == noErr) {
        err = MoreSecExecuteRequestInHelperTool(tool, I_authRef, (CFDictionaryRef)request, (CFDictionaryRef *)(&response));
    }
    
    // Extract information from the response.

    if (err == noErr) {
        DEBUGLOG(@"FileIOLogDomain", AllLogLevel, @"response: %@", response);

        err = MoreSecGetErrorFromResponse((CFDictionaryRef)response);
        if (err == noErr) {
            NSArray *descArray;
            int descIndex;
            int descCount;
            
            descArray = [response objectForKey:(NSString *)kMoreSecFileDescriptorsKey];
            descCount = [descArray count];
            for (descIndex = 0; descIndex < descCount; descIndex++) {
                NSNumber *thisDescNum;
                int thisDesc;
                
                thisDescNum = [descArray objectAtIndex:descIndex];
                thisDesc = [thisDescNum intValue];
                fcntl(thisDesc, F_GETFD, 0);
                
                NSFileHandle *fileHandle = [[NSFileHandle alloc] initWithFileDescriptor:thisDesc closeOnDealloc:YES];
                fileData = [fileHandle readDataToEndOfFile];
                [fileHandle release];
            }
        }
    }
    
    // Clean up after call of helper tool
        
    if (response) {
        [response release];
        response = nil;
    }
    
    CFQRelease(tool);
    
    if (err == noErr) {
        return fileData;
    } else {
        return nil;
    }
}


/*
  So what happens when loading a File?
  
  - we try to load the data - if we can't we use root to do it
  
  - then we try to determine the mode if this wasn't a revert
  
  - if we have data we try to load it into the textstorage using these methods to determine the encoding:
    - if the file starts with an UTF8BOM then UTF8 is used as encoding
    - first we look for css or html/xml encoding information - if there is one this is tried first
    - after that we try to guess using the UniversalDetector 
    - if an encoding is set in the properties we try this one
    - then we look into the encoding settings of the chosen mode - if it is not automatic we try this encoding
    - after that we try loading without a set encoding, thus using system encoding
    - after that (because dom is paranoid) we try loading using MacOS Roman encoding, because system encoding might change someday to something that cannot load every file

*/

- (BOOL)readSEETextFromURL:(NSURL *)anURL properties:(NSDictionary *)aProperties wasAutosave:(BOOL *)wasAutosave error:(NSError **)outError {
    NSData *fileData = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:[[anURL path] stringByAppendingPathComponent:@"collaborationdata.bencoded"]] options:0 error:outError];
    if (!fileData) {
        I_flags.isReadingFile = NO;
        return NO;
    }
    // in the top level of the file there is an bencoded array
    // the elements of the array will be merged into a Dictionary that actually holds the data
    // the purpose of this is so there can be compressed and uncompressed data in it
    // currently 2 types are supported
    // - a Number - this number indicates the fileformatversion which the saving app new about.
    // - an Array with exactly one entry which is a dictionary with uncompressed content
    // - an Array with exactly 2 entries which is a length followed by an compressed content dictionary
    // - everthing else will be ignored but preserved so we have potential upward compatibility
    
    int headerLength = [@"SEEText" length];
    NSArray *topLevelArray = TCM_BdecodedObjectWithData([fileData subdataWithRange:NSMakeRange(headerLength,[fileData length]-headerLength)]);
    int fileversion=0;
    NSMutableArray *preservedData = [NSMutableArray array];
    NSMutableDictionary *dictRep = [NSMutableDictionary dictionary];
    NSEnumerator *elements = [topLevelArray objectEnumerator];
    id element = [elements nextObject];
    if (element) fileversion = [element unsignedIntValue];
    while ((element=[elements nextObject])) {
        if ([element isKindOfClass:[NSArray class]] && [element count]==1 && [[element objectAtIndex:0] isKindOfClass:[NSDictionary class]]) {
            [dictRep addEntriesFromDictionary:[element objectAtIndex:0]];
        } else if ([element isKindOfClass:[NSArray class]] && [element count]==2) {
            NSDictionary *dict = TCM_BdecodedObjectWithData([NSData dataWithArrayOfCompressedData:element]);
            if (dict && [dict isKindOfClass:[NSDictionary class]]) {
                [dictRep addEntriesFromDictionary:dict];
            }
        } else {
            [preservedData addObject:element];
        }
    }
    [self setPreservedDataFromSEETextFile:preservedData];
    I_flags.isSEEText = YES;
    // load users
    TCMMMUserManager *um = [TCMMMUserManager sharedInstance];
    NSEnumerator *userdicts = [[dictRep objectForKey:@"Contributors"] objectEnumerator];
    NSDictionary *userdict = nil;
    NSMutableArray *contributors = [NSMutableArray array];
    while ((userdict = [userdicts nextObject])) {
        TCMMMUser *user = [TCMMMUser userWithDictionaryRepresentation:userdict];
        [um addUser:user];
        [contributors addObject:user];
    }
    [[self session] addContributors:contributors];
    // load text into dictionary
    NSMutableDictionary *storageRep = [dictRep objectForKey:@"TextStorage"];
    NSString *string = [NSString stringWithContentsOfURL:[NSURL fileURLWithPath:[[anURL path] stringByAppendingPathComponent:@"plain.txt"]]  encoding:(NSStringEncoding)[[storageRep objectForKey:@"Encoding"] unsignedIntValue] error:outError];
    if (!string) return NO;
    [storageRep setObject:string forKey:@"String"];
    [self setContentByDictionaryRepresentation:dictRep];
    [self takeSettingsFromDocumentState:[dictRep objectForKey:@"DocumentState"]];
    if ([dictRep objectForKey:@"LoggingState"]) {
        TCMMMLoggingState *logState=[[[TCMMMLoggingState alloc] initWithDictionaryRepresentation:[dictRep objectForKey:@"LoggingState"]] autorelease];
        if (logState) {
            [[self session] setLoggingState:logState];
        }
    }
    if ([dictRep objectForKey:@"AutosaveInformation"]) {
        [self setFileType:[[dictRep objectForKey:@"AutosaveInformation"] objectForKey:@"fileType"]];
        BOOL hadChanges = [[[dictRep objectForKey:@"AutosaveInformation"] objectForKey:@"hadChanges"] boolValue];
        if (!hadChanges) {
            [self performSelector:@selector(clearChangeCount) withObject:nil afterDelay:0.0];
            [self performSelector:@selector(setAutosavedContentsFileURL:) withObject:nil afterDelay:0.0];
        }
        I_flags.isSEEText = [[self fileType] isEqualToString:@"SEETextType"];
        if (wasAutosave) *wasAutosave = YES;
    }
    return YES;
}

- (BOOL)TCM_readFromURL:(NSURL *)anURL ofType:(NSString *)docType properties:(NSDictionary *)aProperties error:(NSError **)outError {
	if (outError) {*outError = nil;}
	if (!anURL) {
		return NO;
	}
    NSString *fileName = [anURL path];
    DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel, @"readFromURL:%@ ofType:%@ properties: %@", anURL, docType, aProperties);

    #ifndef TCM_NO_DEBUG
        if (!_readFromURLDebugInformation) _readFromURLDebugInformation = [NSMutableString new];
        [_readFromURLDebugInformation appendFormat:@"%s %@ %@\n",__FUNCTION__, docType,aProperties];
    #endif

    I_flags.shouldChangeExtensionOnModeChange = NO;
    I_flags.shouldSelectModeOnSave = NO;
    I_flags.isReadingFile = YES;

    if (![docType isEqualToString:@"PlainTextType"] && ![docType isEqualToString:@"SubEthaEditSyntaxStyle"] && ![docType isEqualToString:@"SEETextType"]) {
        if (outError) *outError = [NSError errorWithDomain:@"SEEDomain" code:42 userInfo:
            [NSDictionary dictionaryWithObjectsAndKeys:
                fileName,NSFilePathErrorKey,
                [NSString stringWithFormat:@"Filetype: %@ not (yet) supported.",docType],NSLocalizedDescriptionKey,
                nil
            ]
        ];
        DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel, @"filetype not supported %@",*outError);
        I_flags.isReadingFile = NO;
        return NO;
    }

    BOOL isDir, fileExists;
    fileExists = [[NSFileManager defaultManager] fileExistsAtPath:fileName isDirectory:&isDir];
    if (fileExists && !isDir && [docType isEqualToString:@"SEETextType"]) {
        docType = @"PlainTextType";
        [self performSelector:@selector(setFileType:) withObject:docType afterDelay:0.];
    }
    if (!fileExists || isDir && ![docType isEqualToString:@"SEETextType"]) {
        // generate the correct error
        [NSData dataWithContentsOfURL:anURL options:0 error:outError];
        DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel, @"file doesn't exist %@",*outError);
        I_flags.isReadingFile = NO;
        return NO;
    }

    NSTextStorage *textStorage = [self textStorage];
    BOOL isReverting = ([textStorage length] != 0);

    BOOL wasAutosaved = NO;

    if ([docType isEqualToString:@"SEETextType"]) {
        BOOL result = [self readSEETextFromURL:anURL properties:aProperties wasAutosave:&wasAutosaved error:outError];
        if (!result) {
            I_flags.isReadingFile = NO;
            return result;
        }
        if (wasAutosaved) fileName = [self fileName];
    } else {
    
        BOOL isDocumentFromOpenPanel = [(DocumentController *)[NSDocumentController sharedDocumentController] isDocumentFromLastRunOpenPanel:self];
        DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel, @"Document opened via open panel: %@", isDocumentFromOpenPanel ? @"YES" : @"NO");

        // load the data of the file
        BOOL isReadable = [[NSFileManager defaultManager] isReadableFileAtPath:fileName];
        
        //NSString *extension = [[fileName pathExtension] lowercaseString];
        
        NSData *fileData = nil;
        if (!isReadable) {
            DEBUGLOG(@"FileIOLogDomain", AllLogLevel, @"We need root power!");
            fileData = [self TCM_dataWithContentsOfFileReadUsingAuthorizedHelper:fileName];
            if (fileData == nil) {
                // generate the correct error
                [NSData dataWithContentsOfURL:anURL options:0 error:outError];
                DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel, @"file is not readable %@",*outError);
                I_flags.isReadingFile = NO;
                return NO;
            }
        } else {
            fileData = [NSData dataWithContentsOfURL:anURL options:0 error:outError];
        }
                
        DEBUGLOG(@"FileIOLogDomain", AllLogLevel, @"Data of size: %d bytes read", [fileData length]);


    #ifndef TCM_NO_DEBUG
        [_readFromURLDebugInformation appendFormat:@"was Readable:%d didLoadBytesOfData:%d\n",isReadable,fileData?[fileData length]:-1];
    #endif

    
        // Determine mode
        // How things should work:
        // - if we are reverting we stay in the mode we are
        // - If the user chose a mode explicidly in the open panel or via the see tool (in aProperties) it is taken
        // - Otherwise automatic mode recognition will take place
        
        DocumentMode *mode = nil;
        
        if (isReverting) {
            mode = [self documentMode];
        } else {
            if ([aProperties objectForKey:@"mode"]) {
                NSString *modeName = [aProperties objectForKey:@"mode"];
                mode = [[DocumentModeManager sharedInstance] documentModeForName:modeName];
            } else if (isDocumentFromOpenPanel) {
                NSString *identifier = [(DocumentController *)[NSDocumentController sharedDocumentController] modeIdentifierFromLastRunOpenPanel];
                if (![identifier isEqualToString:AUTOMATICMODEIDENTIFIER]) {
                    mode = [[DocumentModeManager sharedInstance] documentModeForIdentifier:identifier];
                }
            }
        }

        if (!mode) { // that means automatic mode detection
            DEBUGLOG(@"FileIOLogDomain", AllLogLevel, @"Automatic mode detection starting");

            mode = [[DocumentModeManager sharedInstance] documentModeForPath:fileName withContentData:fileData];
        } 
        DEBUGLOG(@"FileIOLogDomain", AllLogLevel, @"Mode will be: %@",[mode documentModeIdentifier]);
    
        // Determine encoding
        BOOL encodingWasChosenExplicidly = NO;
        NSStringEncoding encoding = NoStringEncoding;
        if ([aProperties objectForKey:@"encoding"]) {
            NSString *IANACharSetName = [aProperties objectForKey:@"encoding"];
            if (IANACharSetName) {
                CFStringEncoding cfEncoding = CFStringConvertIANACharSetNameToEncoding((CFStringRef)IANACharSetName);
                if (cfEncoding != kCFStringEncodingInvalidId) {
                    encodingWasChosenExplicidly = YES;
                    encoding = CFStringConvertEncodingToNSStringEncoding(cfEncoding);
                } else {
                    DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel, @"IANACharSetName invalid: %@", IANACharSetName);
                }
            }
        } 
        
        if (encoding == NoStringEncoding) {
            if (isDocumentFromOpenPanel) {
                DocumentController *documentController = (DocumentController *)[NSDocumentController sharedDocumentController];
                encoding = [documentController encodingFromLastRunOpenPanel];
                if (encoding == ModeStringEncoding) {
                    encoding = [[mode defaultForKey:DocumentModeEncodingPreferenceKey] unsignedIntValue];
                } else if (encoding != NoStringEncoding) {
                    encodingWasChosenExplicidly = YES;
                }
            }
        }
        
        if (encoding == NoStringEncoding) {
            encoding = [[mode defaultForKey:DocumentModeEncodingPreferenceKey] unsignedIntValue];
        }
        
        NSDictionary *docAttrs = nil;
        NSMutableDictionary *options = [NSMutableDictionary dictionary];
        [options setObject:NSPlainTextDocumentType forKey:@"DocumentType"];
        
        [textStorage beginEditing];     
        [[textStorage mutableString] setString:@""]; // Empty the document
        
        BOOL success = NO;
        
        if (encodingWasChosenExplicidly) {
            DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel, @"The user did choose an explicid encoding (via open panel or seetool): %@",CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(encoding)));
            [options setObject:[NSNumber numberWithUnsignedInt:encoding] forKey:@"CharacterEncoding"];
            success = [textStorage readFromData:fileData options:options documentAttributes:&docAttrs error:outError];
        }

//        NSArray *xattrKeys = [UKXattrMetadataStore allKeysAtPath:[anURL path] traverseLink:YES];
//        NSLog(@"%s xattrKeys:%@",__FUNCTION__,xattrKeys);
        if (!success) {
            NSString *encodingXattrKey = @"com.apple.TextEncoding";
            NSString *xattrEncoding = [UKXattrMetadataStore stringForKey:encodingXattrKey atPath:[anURL path] traverseLink:YES];
            if (xattrEncoding) {
                NSArray *elements = [xattrEncoding componentsSeparatedByString:@";"];
                NSStringEncoding xEncoding = NoStringEncoding;
                if ([elements count] > 0) {
                    // test first part if its an IANA encoding
                    NSString *ianaEncodingString = [elements objectAtIndex:0];
                    if ([ianaEncodingString length]>0) {
                        CFStringEncoding cfEncoding = CFStringConvertIANACharSetNameToEncoding((CFStringRef)ianaEncodingString);
                        if (cfEncoding != kCFStringEncodingInvalidId) {
                            xEncoding = CFStringConvertEncodingToNSStringEncoding(cfEncoding);
                        }
                    }
                    if (xEncoding == NoStringEncoding && [elements count]>1) {
                        NSScanner *scanner = [NSScanner scannerWithString:[elements objectAtIndex:1]];
                        int scannedCFEncoding = 0;
                        if ([scanner scanInt:&scannedCFEncoding]) {
                            xEncoding = CFStringConvertEncodingToNSStringEncoding(scannedCFEncoding);
                        }
                    }
                    
                    if (xEncoding != NoStringEncoding) {
                        DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel, @"We found an encoding in the xattrs! %@",CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(xEncoding)));
                        [options setObject:[NSNumber numberWithUnsignedInt:xEncoding] forKey:@"CharacterEncoding"];
                        success = [textStorage readFromData:fileData options:options documentAttributes:&docAttrs error:outError];
                    }
                    
                }
            }
        }

        if (!success && [fileData startsWithUTF8BOM]) {
            DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel, @"We found a UTF-8 BOM!");
            I_flags.hasUTF8BOM = YES;
            [options setObject:[NSNumber numberWithUnsignedInt:NSUTF8StringEncoding] forKey:@"CharacterEncoding"];
            success = [textStorage readFromData:fileData options:options documentAttributes:&docAttrs error:outError];
    #ifndef TCM_NO_DEBUG
        [_readFromURLDebugInformation appendFormat:@"-> Found UTF8BOM:\n success:%d readWithOptions:%@ docAttributes:%@ error:%@\n",success,[options description],[docAttrs description],(success?nil:*outError)];
    #endif
        }
        

        if ( !success ) {
            DEBUGLOG(@"FileIOLogDomain", AllLogLevel, @"Checking for encoding/charset setting from html/xml/css");
            // checking if we can guess the correct encoding based on the charset inside the doc - check only the first 4k to avoid finding encoding settings in strings later on in the file (my counter example is a php file that writes out an email with html content that has another encoding than my php file - this is an actual example ;) )
            unsigned dataLength = MIN([fileData length],4096);
            NSString	*fileContent = [[[NSString alloc] initWithBytesNoCopy:(void *)[fileData bytes] length:dataLength encoding:NSMacOSRomanStringEncoding freeWhenDone:NO] autorelease];
            BOOL		foundEncoding = NO;
            
            if ( [[mode documentModeIdentifier] isEqualToString:@"SEEMode.CSS"] ) {
                //check for css encoding
                foundEncoding = [fileContent findIANAEncodingUsingExpression:@"@charset.*?\"(.*?)\"" encoding:&encoding];
            } else {
                // check for html charset in all other documents
                foundEncoding = [fileContent findIANAEncodingUsingExpression:@"<meta.*?charset=(.*?)\"" encoding:&encoding];
            }
            
            if ( foundEncoding ) {
                [options setObject:[NSNumber numberWithUnsignedInt:encoding] forKey:NSCharacterEncodingDocumentOption];
                success = [textStorage readFromData:fileData options:options documentAttributes:&docAttrs error:outError];
                if (success) [[EncodingManager sharedInstance] activateEncoding:encoding];
    #ifndef TCM_NO_DEBUG
        [_readFromURLDebugInformation appendFormat:@"--> 2. Step - reading encoding/charset setting from html/xml/css:\n success:%d readWithOptions:%@ docAttributes:%@ error:%@\n",success,[options description],[docAttrs description],(success?nil:*outError)];
    #endif
            }
        }

        if (!success) {
            DEBUGLOG(@"FileIOLogDomain", AllLogLevel, @"Checking with universal detector");
        // Panic checked for this too - but i actually don't know if this ever would happen when NSPlainTextDocumentType was set 
        //            ( [docAttrs objectForKey:NSConvertedDocumentAttribute] && 
        //             [[docAttrs objectForKey:NSConvertedDocumentAttribute] intValue])) {
            float   confidence = 0.0;
            NSStringEncoding udEncoding=NSUTF8StringEncoding;
            
            // guess encoding based on character sniffing
            UniversalDetector   *detector = [UniversalDetector detector];
            int maxLength = [[NSUserDefaults standardUserDefaults] integerForKey:@"ByteLengthToUseForModeRecognitionAndEncodingGuessing"];
            NSData *checkData = fileData;
            if ([fileData length] > maxLength) {
                checkData = [[NSData alloc] initWithBytes:(void *)[fileData bytes] length:maxLength];
            }
            [detector analyzeData:checkData];
            udEncoding = [detector encoding];
            confidence = [detector confidence];
            if ([fileData length] > maxLength) {
                [checkData release];
            }
    #ifndef TCM_NO_DEBUG
        [_readFromURLDebugInformation appendFormat:@"UniversalDetector:\n confidence:%1.3f encoding:%@\n",confidence,CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(udEncoding))];
    #endif
            // if the encoder detected NSWindowsCP1250StringEncoding then it's probably not very relevant because most files that are not koi8r or some other main different beast come out as NSWindowsCP1250StringEncoding
            // so what we do here is to use the encoding set by the mode - if it was set
            if ( udEncoding > 0 && confidence > 0.0 && 
                 !(udEncoding == NSWindowsCP1250StringEncoding && encoding != NoStringEncoding)) {
                // lookup found something meaningful, so try to use it
                [options setObject:[NSNumber numberWithUnsignedInt:udEncoding] forKey:NSCharacterEncodingDocumentOption];
                success = [textStorage readFromData:fileData options:options documentAttributes:&docAttrs error:outError];
                if (success) [[EncodingManager sharedInstance] activateEncoding:udEncoding];
    #ifndef TCM_NO_DEBUG
        [_readFromURLDebugInformation appendFormat:@"---> 3. Step - using UniversalDetector:\n success:%d confidence:%1.3f encoding:%@ readWithOptions:%@ docAttributes:%@ error:%@\n",success,confidence,CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(udEncoding)) ,[options description],[docAttrs description],(success?nil:*outError)];
    #endif
            }
        }

        // only try here if we have a clue (= fixed encoding set by the mode) about the encoding
        if (!success && encoding != NoStringEncoding && encoding < SmallestCustomStringEncoding) {
            DEBUGLOG(@"FileIOLogDomain", AllLogLevel, @"Checking with encoding set by mode");
            [options setObject:[NSNumber numberWithUnsignedInt:encoding] forKey:@"CharacterEncoding"];
            success = [textStorage readFromData:fileData options:options documentAttributes:&docAttrs error:outError];
    #ifndef TCM_NO_DEBUG
        [_readFromURLDebugInformation appendFormat:@"-> Mode Encoding Step:\n success:%d readWithOptions:%@ docAttributes:%@ error:%@\n",success,[options description],[docAttrs description],(success?nil:*outError)];
    #endif
        }
            
        if ( !success ) {
            DEBUGLOG(@"FileIOLogDomain", AllLogLevel, @"Checking with system encoding");

            //all guess attempts failed, try system encoding
            [options removeObjectForKey:NSCharacterEncodingDocumentOption];
            success = [textStorage readFromData:fileData options:options documentAttributes:&docAttrs error:outError];
    #ifndef TCM_NO_DEBUG
        [_readFromURLDebugInformation appendFormat:@"----> 4. Step - using system encoding by not specifying an encoding:\n success:%d readWithOptions:%@ docAttributes:%@ error:%@\n",success,[options description],[docAttrs description],(success?nil:*outError)];
    #endif
        }
        
        if ( !success ) {
            DEBUGLOG(@"FileIOLogDomain", AllLogLevel, @"Checking with Mac OS Roman as last resort");
            //even system failed, try Mac OS Roman system encoding
            [options setObject:[NSNumber numberWithUnsignedInt:NSMacOSRomanStringEncoding] forKey:NSCharacterEncodingDocumentOption];
            success = [textStorage readFromData:fileData options:options documentAttributes:&docAttrs error:outError];
    #ifndef TCM_NO_DEBUG
        [_readFromURLDebugInformation appendFormat:@"-----> 5. Step - using mac os roman encoding:\n success:%d readWithOptions:%@ docAttributes:%@ error:%@\n",success,[options description],[docAttrs description],(success?nil:*outError)];
    #endif
        }
    
        [self setFileEncoding:[[docAttrs objectForKey:@"CharacterEncoding"] unsignedIntValue]];


        DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel, @"Encoding guessing information summary: %@", _readFromURLDebugInformation);
        DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel, @"Read successful? %@", success ? @"YES" : @"NO");
        DEBUGLOG(@"FileIOLogDomain", DetailedLogLevel, @"documentAttributes: %@", [docAttrs description]);

        [self setDocumentMode:mode];
        if ([I_textStorage length] > [[NSUserDefaults standardUserDefaults] integerForKey:@"StringLengthToStopHighlightingAndWrapping"]) {
            [self setHighlightsSyntax:NO];
            [self setWrapLines:NO];
        }
        [self performSelector:@selector(TCM_validateSizeAndLineEndings) withObject:nil afterDelay:0.0f];
        [textStorage endEditing];     

    } // end of part where the file wasn't SEEText

    DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel, @"fileEncoding: %@", [NSString localizedNameOfStringEncoding:[self fileEncoding]]);

    [self setKeepDocumentVersion:NO];
    NSDictionary *fattrs = [[NSFileManager defaultManager] fileAttributesAtPath:fileName traverseLink:YES];
    [self setFileAttributes:fattrs];
    BOOL isWritable = [[NSFileManager defaultManager] isWritableFileAtPath:fileName] || wasAutosaved;
    DEBUGLOG(@"FileIOLogDomain", DetailedLogLevel, @"isWritable: %@", isWritable ? @"YES" : @"NO");
    [self setIsFileWritable:isWritable];


    unsigned int wholeLength = [I_textStorage length];
    [I_textStorage addAttributes:[self plainTextAttributes]
                           range:NSMakeRange(0, wholeLength)];

    [self updateChangeCount:NSChangeCleared];
    

    if (!isReverting && ![docType isEqualToString:@"SEETextType"]) {
        // clear the logging state
        if ([I_textStorage length] > [[NSUserDefaults standardUserDefaults] integerForKey:@"ByteLengthToUseForModeRecognitionAndEncodingGuessing"]) {
        // if the file is to big no logging state to save space
            [[self session] setLoggingState:nil];
        } else {
             [[self session] setLoggingState:[[TCMMMLoggingState new] autorelease]];
            [[[self session] loggingState] setInitialTextStorageDictionaryRepresentation:[self textStorageDictionaryRepresentation]];
        }
    }
    if (!isReverting) {
        [[[self session] loggingState] handleOperation:[SelectionOperation selectionOperationWithRange:NSMakeRange(0,0) userID:[TCMMMUserManager myUserID]]];
    }

    I_flags.isReadingFile = NO;

    return YES;
}

- (BOOL)readFromURL:(NSURL *)anURL ofType:(NSString *)docType error:(NSError **)outError {
    NSDictionary *properties = [[DocumentController sharedDocumentController] propertiesForOpenedFile:[anURL path]];
    return [self TCM_readFromURL:anURL ofType:docType properties:properties error:outError];
}

- (BOOL)writeMetaDataToURL:(NSURL *)absoluteURL error:(NSError **)outError {
    NSXMLElement *rootElement = [NSXMLNode elementWithName:@"seemetadata"];
    [rootElement addChild:[NSXMLNode elementWithName:@"charset" stringValue:[self encoding]]];
    [rootElement addChild:[NSXMLNode elementWithName:@"mode" stringValue:[[self documentMode] documentModeIdentifier]]];
    
    
    TCMMMUserManager *um = [TCMMMUserManager sharedInstance];
    TCMMMLoggingState *ls = [[self session] loggingState];
    TCMMMLoggedOperation *lop = NULL;
    if ([[ls loggedOperations] count]>0) {
        lop = [[ls loggedOperations] objectAtIndex:0];
        NSXMLElement *element = [NSXMLNode elementWithName:@"firstactivity" stringValue:[[lop date] rfc1123Representation]];
        TCMMMUser *user = [um userForUserID:[[lop operation] userID]];
        if (user) [element addAttribute:[NSXMLNode attributeWithName:@"name" stringValue:[user name]]];
        [rootElement addChild:element];
    }
    
    lop = [[ls loggedOperations] lastObject];
    if (lop) {
        NSXMLElement *element = [NSXMLNode elementWithName:@"lastactivity" stringValue:[[lop date] rfc1123Representation]];
        TCMMMUser *user = [um userForUserID:[[lop operation] userID]];
        if (user) [element addAttribute:[NSXMLNode attributeWithName:@"name" stringValue:[user name]]];
        [rootElement addChild:element];
    }
    
    NSMutableArray *contributorArray = [NSMutableArray array];
    NSEnumerator *userIDs = [[self allUserIDs] objectEnumerator];
    NSString *userID = nil;
    while ((userID = [userIDs nextObject])) {
        TCMMMUser *user = [um userForUserID:userID];
        if (user) {
            [contributorArray addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:user,@"user",[ls statisicsEntryForUserID:userID],@"stat",nil]];
        }
    }
    [contributorArray sortUsingDescriptors:[NSArray arrayWithObjects:[[[NSSortDescriptor alloc] initWithKey:@"stat.dateOfLastActivity" ascending:NO] autorelease],[[[NSSortDescriptor alloc] initWithKey:@"user.name" ascending:YES] autorelease],nil]];
    
    NSXMLElement *contributorsElement = [NSXMLNode elementWithName:@"contributors"];
    [rootElement addChild:contributorsElement];
    NSEnumerator *contributors = [contributorArray objectEnumerator];
    NSDictionary *contributorEntry = nil;
    while ((contributorEntry = [contributors nextObject])) {
        NSXMLElement *element = [NSXMLNode elementWithName:@"contributor"];
        TCMMMUser *contributor = [contributorEntry objectForKey:@"user"];
        [element addAttribute:[NSXMLNode attributeWithName:@"name" stringValue:[contributor name]]];
        if ([contributor email]) [element addAttribute:[NSXMLNode attributeWithName:@"email" stringValue:[contributor email]]];
        if ([contributor aim])   [element addAttribute:[NSXMLNode attributeWithName:@"aim"   stringValue:[contributor aim]]];
        TCMMMLogStatisticsEntry *stat = [contributorEntry objectForKey:@"stat"];
        if (stat) {
            [element addAttribute:[NSXMLNode attributeWithName:@"lastactivity" stringValue:[[stat dateOfLastActivity] rfc1123Representation]]];
            [element addAttribute:[NSXMLNode attributeWithName:@"deletions"  stringValue:[NSString stringWithFormat:@"%u",[stat deletedCharacters]]]];
            [element addAttribute:[NSXMLNode attributeWithName:@"insertions" stringValue:[NSString stringWithFormat:@"%u",[stat insertedCharacters]]]];
            [element addAttribute:[NSXMLNode attributeWithName:@"selections" stringValue:[NSString stringWithFormat:@"%u",[stat selectedCharacters]]]];
        }
        [contributorsElement addChild:element];
    }
    NSXMLDocument *document = [NSXMLDocument documentWithRootElement:rootElement];
    [document setCharacterEncoding:(NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding))];
    return [[document XMLDataWithOptions:NSXMLNodePrettyPrint|NSXMLNodePreserveEmptyElements] writeToURL:absoluteURL options:0 error:outError];
}

- (NSString *)autosavingFileType {
    return @"SEETextType";
}

- (BOOL)writeToURL:(NSURL *)absoluteURL ofType:(NSString *)inTypeName forSaveOperation:(NSSaveOperationType)saveOperation originalContentsURL:(NSURL *)originalContentsURL error:(NSError **)outError {
//-timelog    NSDate *startDate = [NSDate date];
//-timelog    NSLog(@"%s %@ %@ %d %@",__FUNCTION__, absoluteURL, inTypeName, saveOperation,originalContentsURL);
    DEBUGLOG(@"FileIOLogDomain", AllLogLevel, @"write to:%@ type:%@ saveOperation:%d originalURL:%@", absoluteURL, inTypeName, saveOperation,originalContentsURL);
    if ([inTypeName isEqualToString:@"PlainTextType"]) {
        BOOL modeWantsUTF8BOM = [[[self documentMode] defaultForKey:DocumentModeUTF8BOMPreferenceKey] boolValue];
        DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel, @"modeWantsUTF8BOM: %d, hasUTF8BOM: %d", modeWantsUTF8BOM, I_flags.hasUTF8BOM);
        BOOL useUTF8Encoding = ((I_lastSaveOperation == NSSaveToOperation) && (I_encodingFromLastRunSaveToOperation == NSUTF8StringEncoding)) || ((I_lastSaveOperation != NSSaveToOperation) && ([self fileEncoding] == NSUTF8StringEncoding));
        if ((I_flags.hasUTF8BOM || modeWantsUTF8BOM) && useUTF8Encoding) {
            NSData *data = [[[self textStorage] string] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
            return [[data dataPrefixedWithUTF8BOM] writeToURL:absoluteURL options:0 error:outError];
        } else {
            // let us write using NSStrings write methods so the encoding is added to the extended attributes
            return [[[self textStorage] string] writeToURL:absoluteURL atomically:NO encoding:[self fileEncoding] error:outError];
        }
    } else if ([inTypeName isEqualToString:@"SEETextType"]) {
        NSString *packagePath = [absoluteURL path];
        NSFileManager *fm =[NSFileManager defaultManager];
        if ([fm createDirectoryAtPath:packagePath attributes:nil]) {
            BOOL success = YES;

            // mark it as package
            NSString *contentsPath = [packagePath stringByAppendingPathComponent:@"Contents"];
            success = [fm createDirectoryAtPath:contentsPath attributes:nil];
            if (success) success = [[@"????????" dataUsingEncoding:NSUTF8StringEncoding] writeToURL:[NSURL fileURLWithPath:[contentsPath stringByAppendingPathComponent:@"PkgInfo"]] options:0 error:outError];
            
            NSMutableData *data=[NSMutableData dataWithData:[@"SEEText" dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:NO]];
            NSMutableArray *dataArray = [NSMutableArray arrayWithObject:[NSNumber numberWithInt:1]]; 
            // so this is version 1 of the file format...
            // combine data
            NSMutableDictionary *compressedDict = [NSMutableDictionary dictionary];
            NSMutableDictionary *directDict = [NSMutableDictionary dictionary];
            // collect users - uncompressed because compressing pngs again doesn't help...
//-timelog            NSDate *intermediateDate = [NSDate date];
            [directDict setObject:[[self session] contributersAsDictionaryRepresentation] forKey:@"Contributors"];
//-timelog            NSLog(@"%s conributors entry creating took: %fs",__FUNCTION__,[intermediateDate timeIntervalSinceNow]*-1.);
            // get text storage and document settings
//-timelog            intermediateDate = [NSDate date];
            NSMutableDictionary *textStorageRep = [[[self textStorageDictionaryRepresentation] mutableCopy] autorelease];
            [textStorageRep removeObjectForKey:@"String"];
            [compressedDict setObject:textStorageRep forKey:@"TextStorage"];
//-timelog            NSLog(@"%s textstorage entry creating took: %fs",__FUNCTION__,[intermediateDate timeIntervalSinceNow]*-1.);
//-timelog            intermediateDate = [NSDate date];
            if ([[self session] loggingState]) {
                [compressedDict setObject:[[[self session] loggingState] dictionaryRepresentationForSaving] forKey:@"LoggingState"];
            }
//-timelog            NSLog(@"%s loggingState dictionary entry creating took: %fs",__FUNCTION__,[intermediateDate timeIntervalSinceNow]*-1.);
            [compressedDict setObject:[self documentState] forKey:@"DocumentState"];
            if (saveOperation == NSAutosaveOperation) {
//				NSLog(@"%s write to:%@ type:%@ saveOperation:%d originalURL:%@",__FUNCTION__, absoluteURL, inTypeName, saveOperation,originalContentsURL);
                NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                    [self fileType],@"fileType",
                    [NSNumber numberWithBool:[super isDocumentEdited]],@"hadChanges",
                    [[self fileURL] absoluteString],@"fileURL",nil];
                [compressedDict setObject:dictionary forKey:@"AutosaveInformation"];
            }
    
            // add direct and compressed data to the top level array
//-timelog            intermediateDate = [NSDate date];
            [dataArray addObject:[NSArray arrayWithObject:directDict]];
//-timelog            NSDate *tempDate = [NSDate date];
            NSData *bencodedDataToBeCompressed = TCM_BencodedObject(compressedDict);
//-timelog            NSLog(@"generating bencodedDataToBeCompressed took %fs",[tempDate timeIntervalSinceNow]*-1.);
//-timelog            tempDate = [NSDate date];
            NSArray *compressedArray = [bencodedDataToBeCompressed arrayOfCompressedDataWithLevel:Z_DEFAULT_COMPRESSION];
            if (!compressedArray) {
                if (outError) {
                    *outError = [NSError errorWithDomain:@"ZLIBDomain" code:-5 userInfo:nil];
                }
                return NO;
            }
//-timelog            NSLog(@"compressing the array took %fs",[tempDate timeIntervalSinceNow]*-1.);
            [dataArray addObject:compressedArray];
            if ([self preservedDataFromSEETextFile]) {
                [dataArray addObjectsFromArray:[self preservedDataFromSEETextFile]];
            }
//-timelog            tempDate = [NSDate date];
            [data appendData:TCM_BencodedObject(dataArray)];
//-timelog            NSLog(@"bencoding the final dictionary took %fs",[tempDate timeIntervalSinceNow]*-1.);
//-timelog            NSLog(@"%s bencoding and compressing took: %fs",__FUNCTION__,[intermediateDate timeIntervalSinceNow]*-1.);
            
            if (success) success = [data writeToURL:[NSURL fileURLWithPath:[packagePath stringByAppendingPathComponent:@"collaborationdata.bencoded"]] options:0 error:outError];
            if (success) success = [[[self textStorage] string] writeToURL:[NSURL fileURLWithPath:[packagePath stringByAppendingPathComponent:@"plain.txt"]] atomically:NO encoding:[self fileEncoding] error:outError];
            if (success) success = [self writeMetaDataToURL:[NSURL fileURLWithPath:[packagePath stringByAppendingPathComponent:@"metadata.xml"]] error:outError];
            
            if (saveOperation != NSAutosaveOperation) {
                NSString *quicklookPath = [packagePath stringByAppendingPathComponent:@"QuickLook"];
                if (success) success = [fm createDirectoryAtPath:quicklookPath attributes:nil];
                if (success) {
                    NSURL *thumbnailURL = [NSURL fileURLWithPath:[quicklookPath stringByAppendingPathComponent:@"Thumbnail.jpg"]];
                    NSData *jpegData = [[self thumbnailBitmapRepresentation] representationUsingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:0.90],NSImageCompressionFactor,nil]];
                    success = [jpegData writeToURL:thumbnailURL options:0 error:outError];
                    if (success && [[NSUserDefaults standardUserDefaults] boolForKey:@"SaveSeeTextPreview"]) {
                        NSView *printView = [self printableView];
                        NSPrintInfo *printInfo = [[[self printInfo] copy] autorelease];
                        [printInfo setJobDisposition:NSPrintSaveJob];
                        NSMutableDictionary *printDict = [printInfo dictionary];
                        NSString *pdfPath = [quicklookPath stringByAppendingPathComponent:@"Preview.pdf"];
                        [printDict setObject:pdfPath forKey:NSPrintSavePath];
                        NSDictionary *savedPrintOptions = [[self printOptions] copy];
                        printDict = [self printOptions];
                        [printDict setObject:[NSNumber numberWithBool:YES]  forKey:@"SEEParticipants"];
                        [printDict setObject:[NSNumber numberWithBool:YES]  forKey:@"SEEParticipantImages"];
                        [printDict setObject:[NSNumber numberWithBool:YES]  forKey:@"SEEParticipantsAIMAndEmail"];
                        [printDict setObject:[NSNumber numberWithBool:YES]  forKey:@"SEEParticipantsVisitors"];
                        [printDict setObject:[NSNumber numberWithBool:YES]  forKey:@"SEEColorizeChangeMarks"];
                        [printDict setObject:[NSNumber numberWithBool:YES]  forKey:@"SEEAnnotateChangeMarks"];
                        [printDict setObject:[NSNumber numberWithBool:NO]   forKey:@"SEEColorizeWrittenBy"];
                        [printDict setObject:[NSNumber numberWithBool:YES]  forKey:@"SEEAnnotateWrittenBy"];
                        [printDict setObject:[NSNumber numberWithBool:YES]  forKey:@"SEEWhiteBackground"];
                        [printDict setObject:[NSNumber numberWithBool:NO]   forKey:@"SEEUseCustomFont"];
                        [printDict setObject:[NSNumber numberWithBool:NO]   forKey:@"SEELineNumbers"];
                        [printDict setObject:[NSNumber numberWithBool:YES]  forKey:@"SEEPageHeader"];
                        [printDict setObject:[NSNumber numberWithBool:YES]  forKey:@"SEEPageHeaderFilename"];
                        [printDict setObject:[NSNumber numberWithBool:NO]   forKey:@"SEEPageHeaderFullPath"];
                        [printDict setObject:[NSNumber numberWithBool:YES]  forKey:@"SEEPageHeaderCurrentDate"];
                        [printDict setObject:[NSNumber numberWithFloat:8.0] forKey:@"SEEResizeDocumentFontTo"];
                        NSPrintOperation *op = [NSPrintOperation printOperationWithView:printView printInfo:printInfo];
                        [op setShowPanels:NO];
                        [self runModalPrintOperation:op
                                            delegate:nil
                                      didRunSelector:NULL
                                         contextInfo:nil];
                        [[self printOptions] addEntriesFromDictionary:savedPrintOptions];
                    }
                }
            }

            if (success) {
                // save .svn and .cvs directories for versioning
                NSString *originalPath = [originalContentsURL path];
                if (originalPath) {
                    BOOL isDirectory = NO;
                    if ([fm fileExistsAtPath:originalPath isDirectory:&isDirectory] && isDirectory) {
                        NSString *scms[] = {@".svn",@".cvs"};
                        NSString *subpaths[] = {@"",@"Contents",@"QuickLook"};
                        int spIndex = 0;
                        for (spIndex = 0;spIndex<3;spIndex++) {
                            NSString *subPath = subpaths[spIndex];
                            int scmIndex = 0;
                            for (scmIndex=0;scmIndex<2;scmIndex++) {
                                subPath = [subPath stringByAppendingPathComponent:scms[scmIndex]];
                                NSString *sourcePath = [originalPath stringByAppendingPathComponent:subPath];
                                NSString *targetPath = [packagePath stringByAppendingPathComponent:subPath];
                                if ([fm fileExistsAtPath:sourcePath]) {
                                    // make sure target directory exists (important for autosave)
                                    if (![fm fileExistsAtPath:[targetPath stringByDeletingLastPathComponent]]) {
                                        [fm createDirectoryAtPath:[targetPath stringByDeletingLastPathComponent] attributes:nil];
                                    }
                                    // copy the file afterwards
                                    [fm copyPath:sourcePath toPath:targetPath handler:nil];
                                }
                            }
                        }
                    }
                }
            }

//-timelog            NSLog(@"%s Save took: %fs",__FUNCTION__, -1.*[startDate timeIntervalSinceNow]);

            
            if (success) {
                return YES;
            } else {
                [fm removeFileAtPath:packagePath handler:nil];
                if (outError && !*outError) {
                    return [[NSData data] writeToURL:[NSURL fileURLWithPath:@"/asdfaoinefqwef/asdofinasdfpoie/aspdoifnaspdfo/asdofinapsodifn"] options:0 error:outError];
                } else {
                    return NO;
                }
            }
        } else {
            // let us generate some generic error from nsdata
            if (outError && !*outError) {
                return [[NSData data] writeToURL:[NSURL fileURLWithPath:@"/asdfaoinefqwef/asdofinasdfpoie/aspdoifnaspdfo/asdofinapsodifn"] options:0 error:outError];
            } else {
                return NO;
            }
        }
	} else {
        return [super writeToURL:absoluteURL ofType:inTypeName forSaveOperation:saveOperation originalContentsURL:originalContentsURL error:outError];
    }   
}

- (NSDictionary *)fileAttributesToWriteToURL:(NSURL *)absoluteURL ofType:(NSString *)documentTypeName forSaveOperation:(NSSaveOperationType)saveOperationType originalContentsURL:(NSURL *)absoluteOriginalContentsURL error:(NSError **)outError {

    if ([documentTypeName isEqualToString:@"SEETextType"]) {
        return [NSDictionary dictionary];
    }

    DEBUGLOG(@"FileIOLogDomain", AllLogLevel, @"fileAttributesToWriteToURL: %@ previousURL:%@", absoluteURL,absoluteOriginalContentsURL);
    
    // Preserve HFS Type and Creator code
    if ([self fileName] && [self fileType]) {
        DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel, @"Preserve HFS Type and Creator Code");
        NSMutableDictionary *newAttributes = [[[super
        fileAttributesToWriteToURL:absoluteURL ofType:documentTypeName forSaveOperation:saveOperationType originalContentsURL:absoluteOriginalContentsURL error:outError] mutableCopy] autorelease];
        NSDictionary *attributes = [self fileAttributes];
        if (attributes != nil) {
            if ([attributes objectForKey:NSFileHFSTypeCode]) [newAttributes setObject:[attributes objectForKey:NSFileHFSTypeCode] forKey:NSFileHFSTypeCode];
            if ([attributes objectForKey:NSFileHFSCreatorCode]) [newAttributes setObject:[attributes objectForKey:NSFileHFSCreatorCode] forKey:NSFileHFSCreatorCode];
        } else {
            DEBUGLOG(@"FileIOLogDomain", DetailedLogLevel, @"File is not new, but no fileAttributes are set.");
        }
        return newAttributes;
    }


    // Otherwise set HFS Type and Creator code with values from bundle
    DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel, @"Save our HFS Type and Creator Code");

    NSDictionary *infoPlist = [[NSBundle mainBundle] infoDictionary];
    NSString *creatorCodeString;
    NSArray *documentTypes;
    NSNumber *typeCode, *creatorCode;
    NSMutableDictionary *newAttributes;

    typeCode = creatorCode = nil;

    // First, set creatorCode to the HFS creator code for the application,
    // if it exists.
    creatorCodeString = [infoPlist objectForKey:@"CFBundleSignature"];
    if (creatorCodeString) {
        creatorCode = [NSNumber numberWithUnsignedLong:NSHFSTypeCodeFromFileType([NSString stringWithFormat:@"'%@'", creatorCodeString])];
    }

    // Then, find the matching Info.plist dictionary entry for this type.
    // Use the first associated HFS type code, if any exist.
    documentTypes = [infoPlist objectForKey:@"CFBundleDocumentTypes"];
    if (documentTypes) {
        int i, count = [documentTypes count];

        for(i = 0; i < count; i++) {
            NSString *type = [[documentTypes objectAtIndex:i] objectForKey:@"CFBundleTypeName"];
            if (type && [type isEqualToString:documentTypeName]) {
                NSArray *typeCodeStrings = [[documentTypes objectAtIndex:i] objectForKey:@"CFBundleTypeOSTypes"];
                if (typeCodeStrings) {
                    NSString *firstTypeCodeString = [typeCodeStrings objectAtIndex:0];
                    if (firstTypeCodeString) {
                        typeCode = [NSNumber numberWithUnsignedLong:NSHFSTypeCodeFromFileType([NSString stringWithFormat:@"'%@'",firstTypeCodeString])];
                    }
                }
                break;
            }
        }
    }

    // Add the type and/or creator to the dictionary if they exist.
    newAttributes = [[[super
        fileAttributesToWriteToURL:absoluteURL ofType:documentTypeName forSaveOperation:saveOperationType originalContentsURL:absoluteOriginalContentsURL error:outError] mutableCopy] autorelease];
    if (typeCode)
        [newAttributes setObject:typeCode forKey:NSFileHFSTypeCode];
    if (creatorCode)
        [newAttributes setObject:creatorCode forKey:NSFileHFSCreatorCode];

    // Set group owner to primary gid of current user.
    struct passwd *pwdInfo = getpwnam([NSUserName() UTF8String]);
    if (pwdInfo) {
    
        [newAttributes setObject:[NSString stringWithUTF8String:group_from_gid(pwdInfo->pw_gid, 0)]
                          forKey:NSFileGroupOwnerAccountName];
        [newAttributes setObject:[NSNumber numberWithUnsignedLong:pwdInfo->pw_gid]
                          forKey:NSFileGroupOwnerAccountID];
    }
    [self setFileAttributes:newAttributes];
    return newAttributes;
}

- (BOOL)TCM_writeUsingAuthorizedHelperToURL:(NSURL *)anAbsoluteURL ofType:(NSString *)docType saveOperation:(NSSaveOperationType)saveOperationType error:(NSError **)outError {
    NSString *fullDocumentPath = [anAbsoluteURL path];
    OSStatus err = noErr;
    CFURLRef tool = NULL;
    NSDictionary *request = nil;
    NSDictionary *response = nil;
    NSString *intermediateFileName = tempFileName(fullDocumentPath);


    const char *kRightName = "de.codingmonkeys.SubEthaEdit.file.readwritecreate";
    static const AuthorizationFlags kAuthFlags = kAuthorizationFlagDefaults 
                                               | kAuthorizationFlagInteractionAllowed
                                               | kAuthorizationFlagExtendRights
                                               | kAuthorizationFlagPreAuthorize;
    AuthorizationItem   right  = { kRightName, 0, NULL, 0 };
    AuthorizationRights rights = { 1, &right };
        
    err = AuthorizationCopyRights(I_authRef, &rights, kAuthorizationEmptyEnvironment, kAuthFlags, NULL);
    
    if (err == noErr) {
        err = MoreSecCopyHelperToolURLAndCheckBundled(
            CFBundleGetMainBundle(), 
            CFSTR("SubEthaEditHelperToolTemplate"), 
            kApplicationSupportFolderType, 
            CFSTR("SubEthaEdit"), 
            CFSTR("SubEthaEditHelperTool"), 
            &tool);

        // If the home directory is on an volume that doesn't support 
        // setuid root helper tools, ask the user whether they want to use 
        // a temporary tool.
        
        if (err == kMoreSecFolderInappropriateErr) {
            err = MoreSecCopyHelperToolURLAndCheckBundled(
                CFBundleGetMainBundle(), 
                CFSTR("SubEthaEditHelperToolTemplate"), 
                kTemporaryFolderType, 
                CFSTR("SubEthaEdit"), 
                CFSTR("SubEthaEditHelperTool"), 
                &tool);
        }
    }
        
    // ---
    
    if (err == noErr) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSDictionary *fileAttributes = [fileManager fileAttributesAtPath:fullDocumentPath traverseLink:YES];
        unsigned long fileReferenceCount = [[fileAttributes objectForKey:NSFileReferenceCount] unsignedLongValue];
        if (fileReferenceCount > 1) {
        
            if (err == noErr) {
                request = [NSDictionary dictionaryWithObjectsAndKeys:
                                    @"GetFileDescriptor", @"CommandName",
                                    fullDocumentPath, @"FileName",
                                    fullDocumentPath, @"ActualFileName",
                                    nil];
            }

            if (err == noErr) {
                err = MoreSecExecuteRequestInHelperTool(tool, I_authRef, (CFDictionaryRef)request, (CFDictionaryRef *)(&response));
            }
            
            if (err == noErr) {
                DEBUGLOG(@"FileIOLogDomain", AllLogLevel, @"response: %@", response);

                err = MoreSecGetErrorFromResponse((CFDictionaryRef)response);
                if (err == noErr) {
                    NSArray *descArray;
                    int descIndex;
                    int descCount;
                    
                    descArray = [response objectForKey:(NSString *)kMoreSecFileDescriptorsKey];
                    descCount = [descArray count];
                    for (descIndex = 0; descIndex < descCount; descIndex++) {
                        NSNumber *thisDescNum;
                        int thisDesc;
                        
                        thisDescNum = [descArray objectAtIndex:descIndex];
                        thisDesc = [thisDescNum intValue];
                        fcntl(thisDesc, F_GETFD, 0);
                        
                        NSFileHandle *fileHandle = [[NSFileHandle alloc] initWithFileDescriptor:thisDesc closeOnDealloc:YES];
                        NSError *error=nil;
                        NSData *data = [self dataOfType:docType error:&error];
                        if (!data) {
                            DEBUGLOG(@"FileIOLogDomain", AllLogLevel, @"dataOfType returned error: %@", error);
                        }
                        @try {
                            [fileHandle writeData:data];
                        }
                        @catch (id exception) {
                            DEBUGLOG(@"FileIOLogDomain", AllLogLevel, @"writeData throws exception: %@", exception);
                            err = writErr;
                        }
                        [fileHandle release];
                    }
                }
            }
            
            if (response) {
                [response release];
                response = nil;
            }


            CFQRelease(tool);
            
            if (err == noErr) {
                return YES;
            } else {
                *outError = [NSError errorWithDomain:@"MoreSec" code:err userInfo:nil];
                return NO;
            }
        }
    }
              
    // ---
        
    // Create the request dictionary for a file descriptor

    if (err == noErr) {
        request = [NSDictionary dictionaryWithObjectsAndKeys:
                            @"GetFileDescriptor", @"CommandName",
                            intermediateFileName, @"FileName",
                            fullDocumentPath, @"ActualFileName",
                            nil];
    }

    // Go go gadget helper tool!

    if (err == noErr) {
        err = MoreSecExecuteRequestInHelperTool(tool, I_authRef, (CFDictionaryRef)request, (CFDictionaryRef *)(&response));
    }
    
    // Extract information from the response.

    if (err == noErr) {
        DEBUGLOG(@"FileIOLogDomain", AllLogLevel, @"response: %@", response);

        err = MoreSecGetErrorFromResponse((CFDictionaryRef)response);
        if (err == noErr) {
            NSArray *descArray;
            int descIndex;
            int descCount;
            
            descArray = [response objectForKey:(NSString *)kMoreSecFileDescriptorsKey];
            descCount = [descArray count];
            for (descIndex = 0; descIndex < descCount; descIndex++) {
                NSNumber *thisDescNum;
                int thisDesc;
                
                thisDescNum = [descArray objectAtIndex:descIndex];
                thisDesc = [thisDescNum intValue];
                fcntl(thisDesc, F_GETFD, 0);
                
                NSFileHandle *fileHandle = [[NSFileHandle alloc] initWithFileDescriptor:thisDesc closeOnDealloc:YES];
                NSError *error=nil;
                NSData *data = [self dataOfType:docType error:&error];
                if (!data) {
                    DEBUGLOG(@"FileIOLogDomain", AllLogLevel, @"dataOfType returned error: %@", error);
                }
                @try {
                    [fileHandle writeData:data];
                }
                @catch (id exception) {
                    DEBUGLOG(@"FileIOLogDomain", AllLogLevel, @"writeData throws exception: %@", exception);
                    err = writErr;
                }
                [fileHandle release];
            }
        }
    }
    
    // Clean up after first call of helper tool
        
    if (response) {
        [response release];
        response = nil;
    }


    // Create the request dictionary for exchanging file contents

    if (err == noErr) {
        NSMutableDictionary *attrs = [[[self fileAttributesToWriteToFile:fullDocumentPath ofType:docType saveOperation:saveOperationType] mutableCopy] autorelease];
        if (![attrs objectForKey:NSFilePosixPermissions]) {
            [attrs setObject:[NSNumber numberWithUnsignedShort:S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH] forKey:NSFilePosixPermissions];
        }
        request = [NSDictionary dictionaryWithObjectsAndKeys:
                            @"ExchangeFileContents", @"CommandName",
                            fullDocumentPath, @"ActualFileName",
                            intermediateFileName, @"IntermediateFileName",
                            attrs, @"Attributes",
                            nil];
    }

    // Go go gadget helper tool!

    if (err == noErr) {
        err = MoreSecExecuteRequestInHelperTool(tool, I_authRef, (CFDictionaryRef)request, (CFDictionaryRef *)(&response));
    }
    
    // Extract information from the response.
    
    if (err == noErr) {
        DEBUGLOG(@"FileIOLogDomain", AllLogLevel, @"response: %@", response);

        err = MoreSecGetErrorFromResponse((CFDictionaryRef)response);
        if (err == noErr) {
        }
    }
    
    // Clean up after second call of helper tool.
    if (response) {
        [response release];
    }


    CFQRelease(tool);
    
    if (err == noErr) {
        return YES;
    } else {
        *outError = [NSError errorWithDomain:@"MoreSec" code:err userInfo:nil];
        return NO;
    }
}

- (BOOL)writeSafelyToURL:(NSURL*)anAbsoluteURL ofType:(NSString *)docType forSaveOperation:(NSSaveOperationType)saveOperationType error:(NSError **)outError {
    NSString *fullDocumentPath = [anAbsoluteURL path];
    DEBUGLOG(@"FileIOLogDomain", DetailedLogLevel, @"writeSavelyToURL: %@", anAbsoluteURL);
    BOOL hasBeenWritten = [super writeSafelyToURL:anAbsoluteURL ofType:docType forSaveOperation:saveOperationType error:outError];
    if (!hasBeenWritten) {
        DEBUGLOG(@"FileIOLogDomain", AllLogLevel, @"Failed to write using writeSafelyToURL: %@",*outError);
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSDictionary *fileAttributes = [fileManager fileAttributesAtPath:fullDocumentPath traverseLink:YES];
        unsigned long fileReferenceCount = [[fileAttributes objectForKey:NSFileReferenceCount] unsignedLongValue];
        BOOL isFileWritable = [fileManager isWritableFileAtPath:fullDocumentPath];
        if (fileReferenceCount > 1 && isFileWritable) {            
            char cFullDocumentPath[MAXPATHLEN+1];
            if ([(NSString *)fullDocumentPath getFileSystemRepresentation:cFullDocumentPath maxLength:MAXPATHLEN]) {
                int fd = open(cFullDocumentPath, O_WRONLY | O_TRUNC, S_IRUSR | S_IWUSR);
                if (fd) {
                    NSFileHandle *fileHandle = [[NSFileHandle alloc] initWithFileDescriptor:fd closeOnDealloc:YES];
                    NSData *data = [self dataOfType:docType error:outError];
                    if (!data) {
                        DEBUGLOG(@"FileIOLogDomain", AllLogLevel, @"dataOfType returned error: %@", *outError);
                    }
                    @try {
                        [fileHandle writeData:data];
                        hasBeenWritten = YES;
                    }
                    @catch (id exception) {
                        DEBUGLOG(@"FileIOLogDomain", AllLogLevel, @"writeData throws exception: %@", exception);
                    }
                    [fileHandle release];
                }
            }
        }
        
        if (!hasBeenWritten) {
            BOOL isDirWritable = [fileManager isWritableFileAtPath:[fullDocumentPath stringByDeletingLastPathComponent]];
            BOOL isFileDeletable = [fileManager isDeletableFileAtPath:fullDocumentPath];
            if (isDirWritable && isFileDeletable) {
                NSAlert *alert = [[[NSAlert alloc] init] autorelease];
                [alert setAlertStyle:NSWarningAlertStyle];
                [alert setMessageText:NSLocalizedString(@"Save", nil)];
                [alert setInformativeText:NSLocalizedString(@"SaveDialogInformativeText: Save or Replace", @"Informative text in a save dialog, because of permissions issues the user has the choice to save using administrator permissions or replace the file")];
                [alert addButtonWithTitle:NSLocalizedString(@"Save", nil)];
                [alert addButtonWithTitle:NSLocalizedString(@"Replace", nil)];
                [alert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
                int returnCode = [alert runModal];
                [[alert window] orderOut:self];

                if (returnCode == NSAlertFirstButtonReturn) {
                    DEBUGLOG(@"FileIOLogDomain", AllLogLevel, @"We need root power!");
                    hasBeenWritten = [self TCM_writeUsingAuthorizedHelperToURL:anAbsoluteURL ofType:docType saveOperation:saveOperationType error:outError];
                } else if (returnCode == NSAlertSecondButtonReturn) {
                    NSFileManager *fileManager = [NSFileManager defaultManager];
                    NSString *tempFilePath = tempFileName(fullDocumentPath);
                    hasBeenWritten = [self writeToURL:[NSURL fileURLWithPath:tempFilePath] ofType:docType forSaveOperation:saveOperationType originalContentsURL:nil error:outError];
                    if (hasBeenWritten) {
                        BOOL result = [fileManager removeFileAtPath:fullDocumentPath handler:nil];
                        if (result) {
                            hasBeenWritten = [fileManager movePath:tempFilePath toPath:fullDocumentPath handler:nil];
                            if (hasBeenWritten) {
                                NSDictionary *fattrs = [self fileAttributesToWriteToFile:fullDocumentPath ofType:docType saveOperation:saveOperationType];
                                (void)[fileManager changeFileAttributes:fattrs atPath:fullDocumentPath];
                            } else {
                                NSAlert *newAlert = [[[NSAlert alloc] init] autorelease];
                                [newAlert setAlertStyle:NSWarningAlertStyle];
                                [newAlert setMessageText:NSLocalizedString(@"Save", nil)];
                                [newAlert setInformativeText:NSLocalizedString(@"AlertInformativeText: Replace failed", @"Informative text in an alert which tells the you user that replacing the file failed")];
                                [newAlert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
                                [self presentAlert:newAlert
                                     modalDelegate:nil
                                    didEndSelector:nil
                                       contextInfo:NULL];
                            }
                        } else {
                            (void)[fileManager removeFileAtPath:tempFilePath handler:nil];
                            NSAlert *newAlert = [[[NSAlert alloc] init] autorelease];
                            [newAlert setAlertStyle:NSWarningAlertStyle];
                            [newAlert setMessageText:NSLocalizedString(@"Save", nil)];
                            [newAlert setInformativeText:NSLocalizedString(@"AlertInformativeText: Error occurred during replace", @"Informative text in an alert which tells the user that an error prevented the replace")];
                            [newAlert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
                            [self presentAlert:newAlert
                                 modalDelegate:nil
                                didEndSelector:nil
                                   contextInfo:NULL];

                        }
                    }
                }
            } else {
                DEBUGLOG(@"FileIOLogDomain", AllLogLevel, @"We need root power!");
                hasBeenWritten = [self TCM_writeUsingAuthorizedHelperToURL:anAbsoluteURL ofType:docType saveOperation:saveOperationType error:outError];
            }
        }
     }

    if (hasBeenWritten) {
        if (saveOperationType == NSSaveOperation) {
            [self TCM_sendODBModifiedEvent];
            [self setKeepDocumentVersion:NO];
        } else if (saveOperationType == NSSaveAsOperation) {
            if ([fullDocumentPath isEqualToString:[self fileName]]) {
                [self TCM_sendODBModifiedEvent];
            } else {
                [self setODBParameters:nil];
            }
            [self setShouldChangeChangeCount:YES];
        }
        [self TCM_webPreviewOnSaveRefresh];
        [self setTemporaryDisplayName:nil];
    }
    
    if (saveOperationType != NSSaveToOperation && saveOperationType != NSAutosaveOperation) {
        NSDictionary *fattrs = [[NSFileManager defaultManager] fileAttributesAtPath:fullDocumentPath traverseLink:YES];
        [self setFileAttributes:fattrs];
        [self setIsFileWritable:[[NSFileManager defaultManager] isWritableFileAtPath:fullDocumentPath] || hasBeenWritten];
    }

    if (hasBeenWritten) {
        [[NSNotificationQueue defaultQueue]
        enqueueNotification:[NSNotification notificationWithName:PlainTextDocumentDidSaveNotification object:self]
               postingStyle:NSPostWhenIdle
               coalesceMask:NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender
                   forModes:[NSArray arrayWithObject:NSDefaultRunLoopMode]];
    }

    return hasBeenWritten;
}

- (BOOL)TCM_validateDocument {
    NSString *fileName = [self fileName];
    DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel, @"Validate document: %@", fileName);

    NSDictionary *fattrs = [[NSFileManager defaultManager] fileAttributesAtPath:fileName traverseLink:YES];
    if ([[fattrs fileModificationDate] compare:[[self fileAttributes] fileModificationDate]] != NSOrderedSame) {
        DEBUGLOG(@"FileIOLogDomain", DetailedLogLevel, @"Document has been changed externally");
        if ([self keepDocumentVersion]) {
            DEBUGLOG(@"FileIOLogDomain", DetailedLogLevel, @"Keep document version");
            return YES;
        }
                
        if ([self isDocumentEdited]) {
            NSAlert *alert = [[[NSAlert alloc] init] autorelease];
            [alert setAlertStyle:NSWarningAlertStyle];
            [alert setMessageText:NSLocalizedString(@"The file has been modified by another application. Do you want to keep the changes made in SubEthaEdit?", nil)];
            [alert setInformativeText:NSLocalizedString(@"If you revert the file to the version on disk the changes you made in SubEthaEdit will be lost.", nil)];
            [alert addButtonWithTitle:NSLocalizedString(@"Keep Changes", nil)];
            [alert addButtonWithTitle:NSLocalizedString(@"Revert", nil)];
            [[[alert buttons] objectAtIndex:0] setKeyEquivalent:@"\r"];
            [self presentAlert:alert
                 modalDelegate:self
                didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
                   contextInfo:[[NSDictionary dictionaryWithObjectsAndKeys:
                                                    @"DocumentChangedExternallyAlert", @"Alert",
                                                    nil] retain]];

            return NO;
        } else {
            NSAlert *alert = [[[NSAlert alloc] init] autorelease];
            [alert setAlertStyle:NSWarningAlertStyle];
            [alert setMessageText:NSLocalizedString(@"The document's file has been modified by another application. Do you want to revert the document?", nil)];
            [alert setInformativeText:NSLocalizedString(@"If you revert the document to the version on disk the document's content will be replaced with the content of the file.", nil)];
            [alert addButtonWithTitle:NSLocalizedString(@"Revert Document", nil)];
            [alert addButtonWithTitle:NSLocalizedString(@"Don't Revert Document", nil)];
            [[[alert buttons] objectAtIndex:0] setKeyEquivalent:@"\r"];
            [self presentAlert:alert
                 modalDelegate:self
                didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
                   contextInfo:[[NSDictionary dictionaryWithObjectsAndKeys:
                                                    @"DocumentChangedExternallyNoModificationsAlert", @"Alert",
                                                    nil] retain]];

            return NO;
        }
    }

    return YES;
}

#pragma mark -


- (BOOL)validateMenuItem:(NSMenuItem *)anItem {
    SEL selector=[anItem action];
    if (selector==@selector(toggleSyntaxHighlighting:)) {
        [anItem setState:(I_flags.highlightSyntax?NSOnState:NSOffState)];
        return ![self isProxyDocument];
    } else if (selector == @selector(chooseLineEndings:)) {
        if ([self lineEnding] == [anItem tag]) {
            [anItem setState:NSOnState];
        } else {
            [anItem setState:NSOffState];
        }
    } else if (selector == @selector(convertLineEndings:)) {
        NSStringEncoding encoding=[self fileEncoding];
        return (![self isProxyDocument] &&
                ([anItem tag]<LineEndingUnicodeLineSeparator ||
                encoding==NSUnicodeStringEncoding ||
                encoding==NSUTF8StringEncoding ||
                encoding==NSNonLossyASCIIStringEncoding));
    } else if (selector == @selector(selectEncoding:)) {
        if ([self fileEncoding] == (unsigned int)[anItem tag]) {
            [anItem setState:NSOnState];
        } else {
            [anItem setState:NSOffState];
        }
        TCMMMSession *session=[self session];
        return (![self isProxyDocument] && [session isServer] && [session participantCount]<=1);
    } else if (selector == @selector(chooseMode:)) {
        DocumentModeManager *modeManager=[DocumentModeManager sharedInstance];
        NSString *identifier=[modeManager documentModeIdentifierForTag:[anItem tag]];
        if (identifier && [[[self documentMode] documentModeIdentifier] isEqualToString:identifier]) {
            [anItem setState:NSOnState];
        } else {
            [anItem setState:NSOffState];
        }
        return ![self isProxyDocument];
    } else if (selector == @selector(toggleUsesTabs:)) {
        [anItem setState:(I_flags.usesTabs?NSOnState:NSOffState)];
        return ![self isProxyDocument];
    } else if (selector == @selector(selectWrapMode:)) {
        [anItem setState:(I_flags.wrapMode==[anItem tag]?NSOnState:NSOffState)];
        return ![self isProxyDocument];
    } else if (selector == @selector(toggleIndentNewLines:)) {
        [anItem setState:(I_flags.indentNewLines?NSOnState:NSOffState)];
        return ![self isProxyDocument];
    } else if (selector == @selector(changeTabWidth:)) {
        [anItem setState:(I_tabWidth==[[anItem title]intValue]?NSOnState:NSOffState)];
        return ![self isProxyDocument];
    } else if (selector == @selector(changePendingUsersAccess:)) {
        TCMMMSession *session=[self session];
        [anItem setState:([anItem tag]==[session accessState])?NSOnState:NSOffState];
        return [session isServer];
    } else if (selector == @selector(toggleIsAnnounced:)) {
        [anItem setTitle:[self isAnnounced]?
                         NSLocalizedString(@"Conceal",@"Menu/Toolbar Title for concealing the Document"):
                         NSLocalizedString(@"Announce",@"Menu/Toolbar Title for announcing the Document")];
        return [[self session] isServer];
    } else if (selector == @selector(toggleIsAnnouncedOnAllDocuments:)) {
        [anItem setTitle:[self isAnnounced]?
                         NSLocalizedString(@"Conceal All",@"Menu/Toolbar Title for concealing all Documents"):
                         NSLocalizedString(@"Announce All",@"Menu/Toolbar Title for announcing all Documents")];
        return YES;
    } else if (selector == @selector(saveDocument:)) {
        return ![self isProxyDocument];
    } else if (selector == @selector(saveDocumentAs:)) {
        return ![self isProxyDocument];
    } else if (selector == @selector(saveDocumentTo:)) {
        return ![self isProxyDocument];
    } else if (selector == @selector(printDocument:)) {
        return ![self isProxyDocument];
    } else if (selector == @selector(runPageLayout:)) {
        return ![self isProxyDocument];
    } else if (selector == @selector(showWebPreview:)) {
        return ![self isProxyDocument];
    } else if (selector == @selector(newView:)) {
        return ![self isProxyDocument];
    } else if (selector == @selector(refreshWebPreview:)) {
        return ![self isProxyDocument];
    } else if (selector == @selector(clearChangeMarks:) || selector == @selector(restoreChangeMarks:)) {
        return ![self isProxyDocument];
    }

//    if (selector==@selector(undo:)) {
//        return [[self documentUndoManager] canUndo];
//    } else if (selector==@selector(redo:)) {
//        return [[self documentUndoManager] canRedo];
//    }

    return [super validateMenuItem:anItem];
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)toolbarItem {
    NSString *itemIdentifier = [toolbarItem itemIdentifier];

    if ([itemIdentifier isEqualToString:ToggleAnnouncementToolbarItemIdentifier]) {
        BOOL isAnnounced=[self isAnnounced];
        [toolbarItem setImage:isAnnounced
                              ?[NSImage imageNamed: @"Conceal"]
                              :[NSImage imageNamed: @"Announce"]];
        [toolbarItem setLabel:isAnnounced?
                         NSLocalizedString(@"Conceal",@"Menu/Toolbar Title for concealing the Document"):
                         NSLocalizedString(@"Announce",@"Menu/Toolbar Title for announcing the Document")];
        return [[self session] isServer];
    }

    return YES;
}

- (NSString *)lineEndingString {
    return I_lineEndingString;
}

- (LineEnding)lineEnding {
    return [(TextStorage *)[self textStorage] lineEnding];
}

// http://developer.apple.com/documentation/Carbon/Conceptual/ATSUI_Concepts/atsui_chap4/chapter_4_section_5.html

- (void)setLineEnding:(LineEnding)newLineEnding {
    [(TextStorage *)[self textStorage] setLineEnding:newLineEnding];
    I_lineEndingString = [NSString lineEndingStringForLineEnding:newLineEnding];
    [self TCM_sendPlainTextDocumentDidChangeEditStatusNotification];
}

- (void)setLineEndingUndoable:(LineEnding)lineEnding {
    [[self documentUndoManager] beginUndoGrouping];
    [[[self documentUndoManager] prepareWithInvocationTarget:self] setLineEndingUndoable:[self lineEnding]];
    [[self documentUndoManager] endUndoGrouping];
    [self setLineEnding:lineEnding];
}

- (IBAction)chooseLineEndings:(id)aSender {
    [self setLineEndingUndoable:[aSender tag]];
}

- (void)convertLineEndingsToLineEnding:(LineEnding)lineEnding {

    if (![self isFileWritable] && ![self editAnyway]) {
        NSMethodSignature *signature = [self methodSignatureForSelector:@selector(convertLineEndingsToLineEnding:)];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation setTarget:self];
        [invocation setSelector:@selector(convertLineEndingsToLineEnding:)];
        [invocation setArgument:&lineEnding atIndex:2];
        NSDictionary *contextInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                                    @"EditAnywayAlert", @"Alert",
                                                    invocation, @"Invocation",
                                                    nil];

        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert setMessageText:NSLocalizedString(@"Warning", nil)];
        [alert setInformativeText:NSLocalizedString(@"File is read-only", nil)];
        [alert addButtonWithTitle:NSLocalizedString(@"Edit anyway", nil)];
        [alert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
        [[[alert buttons] objectAtIndex:0] setKeyEquivalent:@"\r"];
        [self presentAlert:alert
             modalDelegate:self
            didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
               contextInfo:[contextInfo retain]];
    } else {
        TextStorage *textStorage=(TextStorage *)[self textStorage];
        [textStorage beginEditing];
        [textStorage setShouldWatchLineEndings:NO];

        [self setLineEnding:lineEnding];
        [[self documentUndoManager] beginUndoGrouping];
        [[textStorage mutableString] convertLineEndingsToLineEndingString:[self lineEndingString]];
        [[self documentUndoManager] endUndoGrouping];

        [textStorage setShouldWatchLineEndings:YES];
        [textStorage setHasMixedLineEndings:NO];
        [textStorage endEditing];
    }
}

- (IBAction)convertLineEndings:(id)aSender {
    [self convertLineEndingsToLineEnding:[aSender tag]];
}

- (NSRange)rangeOfPrevious:(BOOL)aPrevious symbolForRange:(NSRange)aRange {
    if ([[self documentMode] hasSymbols] && [I_symbolArray count]) {
        int position=[self selectedSymbolForRange:aRange];
        if (aPrevious) {
            if (position==-1) return NSMakeRange(NSNotFound,0);
            NSRange symbolRange=[[I_symbolArray objectAtIndex:position] jumpRange];
            if (DisjointRanges(aRange,symbolRange) && symbolRange.location<aRange.location) {
                return symbolRange;
            } else {
                while (position-->0) {
                    SymbolTableEntry *entry=[I_symbolArray objectAtIndex:position];
                    if (![entry isSeparator]) {
                        return [entry jumpRange];
                    }
                }
            }
        } else {
            if (position==-1) position=0;
            while (position<[I_symbolArray count]) {
                SymbolTableEntry *entry=[I_symbolArray objectAtIndex:position];
                if (![entry isSeparator]) {
                    NSRange symbolRange=[[I_symbolArray objectAtIndex:position] jumpRange];
                    if (DisjointRanges(aRange,symbolRange) && NSMaxRange(symbolRange)>NSMaxRange(aRange)) {
                        return symbolRange;
                    }
                }
                position++;
            }
        }
    }
    return NSMakeRange(NSNotFound,0);
}

- (NSRange)rangeOfPrevious:(BOOL)aPrevious changeForRange:(NSRange)aRange {
    NSRange searchRange;
    TextStorage *textStorage=(TextStorage *)[self textStorage];
    NSString *userID=nil;
    unsigned position;
    NSRange fullRange=NSMakeRange(0,[textStorage length]);
    if (aRange.location>=fullRange.length) {
        if (aRange.location>0) aRange.location-=1;
        else return NSMakeRange(NSNotFound,0);
    }
    userID=[textStorage attribute:ChangedByUserIDAttributeName atIndex:aRange.location longestEffectiveRange:&searchRange inRange:fullRange];
    userID=nil;
    while (!userID) {
        if (aPrevious) {
            if (searchRange.location==0) {
                return NSMakeRange(NSNotFound,0);
            }
            position=searchRange.location-1;
        } else {
            position=NSMaxRange(searchRange);
            if (position>=fullRange.length) {
                return NSMakeRange(NSNotFound,0);
            }
        }
        userID = [textStorage attribute:ChangedByUserIDAttributeName
                                atIndex:position
                  longestEffectiveRange:&searchRange
                                inRange:fullRange];
    }

    return searchRange;
}


/*"A font trait mask of 0 returns the plain font, otherwise use NSBoldFontMask, NSItalicFontMask"*/
- (NSFont *)fontWithTrait:(NSFontTraitMask)aFontTrait {
    if ((aFontTrait & NSBoldFontMask) && (aFontTrait & NSItalicFontMask)) {
        return I_fonts.boldItalicFont;
    } else if (aFontTrait & NSItalicFontMask) {
        return I_fonts.italicFont;
    } else if (aFontTrait & NSBoldFontMask) {
        return I_fonts.boldFont;
    } else {
        return I_fonts.plainFont;
    }
}

- (void)setPlainFont:(NSFont *)aFont {
    [I_styleCacheDictionary autorelease];
    I_styleCacheDictionary = [NSMutableDictionary new];
    BOOL useDefaultStyle=[[[self documentMode] defaultForKey:DocumentModeUseDefaultStylePreferenceKey] boolValue];
    BOOL darkBackground=[[[self documentMode] defaultForKey:DocumentModeBackgroundColorIsDarkPreferenceKey] boolValue];
    NSDictionary *syntaxStyle=[useDefaultStyle?[[DocumentModeManager baseMode] syntaxStyle]:[[self documentMode] syntaxStyle] styleForKey:SyntaxStyleBaseIdentifier];
    [self setDocumentBackgroundColor:[syntaxStyle objectForKey:darkBackground?@"inverted-background-color":@"background-color"]];
    [self setDocumentForegroundColor:[syntaxStyle objectForKey:darkBackground?@"inverted-color":@"color"]];
    [I_fonts.plainFont autorelease];
    I_fonts.plainFont = [aFont copy];
    [self TCM_styleFonts];
    [self TCM_invalidateTextAttributes];
    [self TCM_invalidateDefaultParagraphStyle];
    [[self plainTextEditors] makeObjectsPerformSelector:@selector(adjustDisplayOfPageGuide)];
}

- (NSDictionary *)styleAttributesForStyleID:(NSString *)aStyleID {
    NSDictionary *result=[I_styleCacheDictionary objectForKey:aStyleID];
    if (!result) {
        DocumentMode *documentMode=[self documentMode];
        BOOL darkBackground=[[documentMode defaultForKey:DocumentModeBackgroundColorIsDarkPreferenceKey] boolValue];
        NSDictionary *style=nil;
        if ([aStyleID isEqualToString:SyntaxStyleBaseIdentifier] && 
            [[documentMode defaultForKey:DocumentModeUseDefaultStylePreferenceKey] boolValue]) {
            style=[[[DocumentModeManager baseMode] syntaxStyle] styleForKey:aStyleID];
        } else {
            style=[[documentMode syntaxStyle] styleForKey:aStyleID];
        }
        NSFontTraitMask traits=[[style objectForKey:@"font-trait"] unsignedIntValue];
        NSFont *font=[self fontWithTrait:traits];
        BOOL synthesise=[[NSUserDefaults standardUserDefaults] boolForKey:SynthesiseFontsPreferenceKey];
        float obliquenessFactor=0.;
        if (synthesise && (traits & NSItalicFontMask) && !([[NSFontManager sharedFontManager] traitsOfFont:font] & NSItalicFontMask)) {
            obliquenessFactor=.2;
        }
        float strokeWidth=.0;
        if (synthesise && (traits & NSBoldFontMask) && !([[NSFontManager sharedFontManager] traitsOfFont:font] & NSBoldFontMask)) {
            strokeWidth=darkBackground?-9.:-3.;
        }
        NSColor *foregroundColor=[style objectForKey:darkBackground?@"inverted-color":@"color"];
        result=[NSDictionary dictionaryWithObjectsAndKeys:font,NSFontAttributeName,
            foregroundColor,NSForegroundColorAttributeName,
            aStyleID,@"styleID",
            [NSNumber numberWithFloat:obliquenessFactor],NSObliquenessAttributeName,
            [NSNumber numberWithFloat:strokeWidth],NSStrokeWidthAttributeName,
            nil];
        [I_styleCacheDictionary setObject:result forKey:aStyleID];
    }
    return result;
}

- (NSDictionary *)typingAttributes {
    if (!I_typingAttributes) {
        NSMutableDictionary *attributes=[[self plainTextAttributes] mutableCopy];
        NSString *myUserID=[TCMMMUserManager myUserID];
        [attributes setObject:myUserID forKey:WrittenByUserIDAttributeName];
        [attributes setObject:myUserID forKey:ChangedByUserIDAttributeName];
        I_typingAttributes=(NSDictionary *)attributes;
    }
    return I_typingAttributes;
}

- (NSDictionary *)plainTextAttributes {
    if (!I_plainTextAttributes) {
        NSMutableDictionary *attributes=[NSMutableDictionary new];
        [attributes addEntriesFromDictionary:[self styleAttributesForStyleID:SyntaxStyleBaseIdentifier]];
        [attributes setObject:[NSNumber numberWithInt:0]
                       forKey:NSLigatureAttributeName];
        [attributes setObject:[self defaultParagraphStyle]
                       forKey:NSParagraphStyleAttributeName];
        I_plainTextAttributes=attributes;
    }
    return I_plainTextAttributes;

}

- (NSColor *)documentForegroundColor {
    return I_documentForegroundColor;
}

- (void)setDocumentForegroundColor:(NSColor *)aColor {
    [I_documentForegroundColor autorelease];
    I_documentForegroundColor=[aColor retain];
    [self TCM_invalidateDefaultParagraphStyle];
}


- (NSColor *)documentBackgroundColor {
    return I_documentBackgroundColor;
}

- (void)setDocumentBackgroundColor:(NSColor *)aColor {
    [I_documentBackgroundColor autorelease];
    I_documentBackgroundColor=[aColor retain];
    NSEnumerator *editors=[[self plainTextEditors] objectEnumerator];
    PlainTextEditor *editor=nil;
    while ((editor=[editors nextObject])) {
        [[editor textView] setBackgroundColor:aColor];
    }
}
/*"This method returns the blockeditTextAttributes that the textview uses. If you make background colors customizeable you want to change these too"*/
- (NSDictionary *)blockeditAttributes {
    if (!I_blockeditAttributes) {
        float backgroundBrightness=[[[self documentBackgroundColor] colorUsingColorSpaceName:NSCalibratedRGBColorSpace] brightnessComponent];
;
        if (backgroundBrightness>.5) backgroundBrightness-=.1;
        else backgroundBrightness+=.1;
        NSColor *blockeditColor=[NSColor colorWithCalibratedWhite:backgroundBrightness alpha:1.];
        I_blockeditAttributes=[[NSDictionary dictionaryWithObjectsAndKeys:
                            blockeditColor,NSBackgroundColorAttributeName,
                            BlockeditAttributeValue,BlockeditAttributeName,
                            nil] retain];
    }
    return I_blockeditAttributes;
}


- (NSParagraphStyle *)defaultParagraphStyle {
    static NSLayoutManager *sLayoutManager = nil;
    if (!sLayoutManager) {
        sLayoutManager=[NSLayoutManager new];
    }
    if (!I_defaultParagraphStyle) {
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        [paragraphStyle setTabStops:[NSArray array]];
        NSFont *font=[sLayoutManager substituteFontForFont:[self fontWithTrait:nil]];
        float charWidth = [font widthOfString:@" "];
        if (charWidth<=0) {
            charWidth=[font maximumAdvancement].width;
        }
        [paragraphStyle setLineBreakMode:I_flags.wrapMode==DocumentModeWrapModeCharacters?NSLineBreakByCharWrapping:NSLineBreakByWordWrapping];
        [paragraphStyle setDefaultTabInterval:charWidth*I_tabWidth];
        [paragraphStyle addTabStop:[[[NSTextTab alloc] initWithType:NSLeftTabStopType location:charWidth*I_tabWidth] autorelease]];

        I_defaultParagraphStyle = [paragraphStyle copy];
        [paragraphStyle release];
        [[self textStorage] addAttribute:NSParagraphStyleAttributeName value:I_defaultParagraphStyle range:NSMakeRange(0,[[self textStorage] length])];
    }
    return I_defaultParagraphStyle;
}


- (void)TCM_invalidateDefaultParagraphStyle {
    [I_defaultParagraphStyle autorelease];
     I_defaultParagraphStyle=nil;
    [I_plainTextAttributes autorelease];
     I_plainTextAttributes=nil;
    [I_typingAttributes release];
     I_typingAttributes=nil;
    [I_styleCacheDictionary removeAllObjects];
    [[NSNotificationQueue defaultQueue]
        enqueueNotification:[NSNotification notificationWithName:PlainTextDocumentDefaultParagraphStyleDidChangeNotification object:self]
               postingStyle:NSPostWhenIdle
               coalesceMask:NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender
                   forModes:[NSArray arrayWithObject:NSDefaultRunLoopMode]];
}

- (void)TCM_invalidateTextAttributes {
    [I_plainTextAttributes release];
     I_plainTextAttributes=nil;
    [I_typingAttributes release];
     I_typingAttributes=nil;
    [I_blockeditAttributes release];
     I_blockeditAttributes=nil;
    [I_styleCacheDictionary removeAllObjects];
    NSRange wholeRange=NSMakeRange(0,[[self textStorage] length]);
    [I_textStorage addAttributes:[self plainTextAttributes]
                           range:wholeRange];
    if (I_flags.highlightSyntax) {
        [self highlightSyntaxInRange:wholeRange];
    }
}

- (PlainTextWindowController *)topmostWindowController {
    NSEnumerator *orderedWindowEnumerator=[[NSApp orderedWindows] objectEnumerator];
    NSWindow *window;
    PlainTextWindowController *result=nil;
    while ((window=[orderedWindowEnumerator nextObject])) {
        if ([[window windowController] document]==self && [[window windowController] isKindOfClass:[PlainTextWindowController class]]) {
            result=[window windowController];
            break;
        }
    }
    if (!result) result=[[self windowControllers] objectAtIndex:0];
    return result;
}


- (void)gotoLine:(unsigned)aLine {
    [self gotoLine:aLine orderFront:NO];
}

- (void)gotoLine:(unsigned)aLine orderFront:(BOOL)aFlag {
    PlainTextWindowController *windowController=[self topmostWindowController];
    [windowController selectTabForDocument:self];
    [windowController gotoLine:aLine];
    if (aFlag) [[windowController window] makeKeyAndOrderFront:self];
}

- (void)selectRange:(NSRange)aRange {
    PlainTextWindowController *windowController=[self topmostWindowController];
    [windowController selectTabForDocument:self];
    [windowController selectRange:aRange];
	NSTextView *textView = [[windowController activePlainTextEditor] textView];
	if ([textView respondsToSelector:@selector(showFindIndicatorForRange:)]) {
		[textView showFindIndicatorForRange:aRange];
	} 
    [[windowController window] makeKeyAndOrderFront:self];
}

- (void)selectRangeInBackground:(NSRange)aRange {
    PlainTextWindowController *windowController=[self topmostWindowController];
    [windowController selectTabForDocument:self];
    [windowController selectRange:aRange];
	NSTextView *textView = [[windowController activePlainTextEditor] textView];
	if ([textView respondsToSelector:@selector(showFindIndicatorForRange:)]) {
		[textView showFindIndicatorForRange:aRange];
	} 
}

- (void)addFindAllController:(FindAllController *)aController
{
    [aController setDocument:self];
    if (I_findAllControllers) [I_findAllControllers addObject:aController];
}

- (void)removeFindAllController:(FindAllController *)aController
{
    if (I_findAllControllers) [I_findAllControllers removeObject:aController];
}

- (NSURL *)documentURL {
    if (![[self session] isServer]) {
        return nil;
    }

    NSMutableString *address = [[[NSMutableString alloc] init] autorelease];
    [address appendFormat:@"%@:", @"see"];

    NSString *hostAddress = nil;
    NSHost *currentHost = [NSHost currentHost];
    NSEnumerator *enumerator = [[currentHost addresses] objectEnumerator];
    while ((hostAddress = [enumerator nextObject])) {
        if ([hostAddress hasPrefix:@"::1"] ||
            [hostAddress hasPrefix:@"fe80"] ||
            [hostAddress hasPrefix:@"fd"] ||
            [hostAddress hasPrefix:@"127.0.0.1"] ||
            [hostAddress hasPrefix:@"10."] ||
            [hostAddress hasPrefix:@"192.168."] ||
            [hostAddress hasPrefix:@"169.254."] ||
            [hostAddress hasPrefix:@"172.16."] ||
            [hostAddress hasPrefix:@"172.17."] ||
            [hostAddress hasPrefix:@"172.18."] ||
            [hostAddress hasPrefix:@"172.19."] ||
            [hostAddress hasPrefix:@"172.20."] ||
            [hostAddress hasPrefix:@"172.21."] ||
            [hostAddress hasPrefix:@"172.22."] ||
            [hostAddress hasPrefix:@"172.23."] ||
            [hostAddress hasPrefix:@"172.24."] ||
            [hostAddress hasPrefix:@"172.25."] ||
            [hostAddress hasPrefix:@"172.26."] ||
            [hostAddress hasPrefix:@"172.27."] ||
            [hostAddress hasPrefix:@"172.28."] ||
            [hostAddress hasPrefix:@"172.29."] ||
            [hostAddress hasPrefix:@"172.30."] ||
            [hostAddress hasPrefix:@"172.31."]) {
            
            hostAddress = nil;
        } else {
            break;
        }
    }
    
    if (hostAddress == nil) {
        CFStringRef localHostName = SCDynamicStoreCopyLocalHostName(NULL);
        if (localHostName) {
            hostAddress = [NSString stringWithFormat:@"%@.local", (NSString *)localHostName];
            CFRelease(localHostName); // CFRelease(NULL) is not a good idea and crashes
        } else {
            hostAddress = @"hasnoaddress.local";
        }
    } else {
        NSCharacterSet *ipv6set = [NSCharacterSet characterSetWithCharactersInString:@"1234567890abcdef:"];
        NSScanner *ipv6scanner = [NSScanner scannerWithString:hostAddress];
        NSString *scannedString = nil;
        if ([ipv6scanner scanCharactersFromSet:ipv6set intoString:&scannedString]) {
            if ([scannedString length] == [hostAddress length]) {
                hostAddress = [NSString stringWithFormat:@"[%@]",scannedString];
            } else if ([hostAddress length] > [scannedString length]+1 && [hostAddress characterAtIndex:[scannedString length]] == '%') {
                hostAddress = [NSString stringWithFormat:@"[%@%%25%@]",scannedString,[hostAddress substringFromIndex:[scannedString length]+1]];
            }
        }
    }

    [address appendFormat:@"//%@", hostAddress];

    int port = [[TCMMMBEEPSessionManager sharedInstance] listeningPort];
    if (port != SUBETHAEDIT_DEFAULT_PORT) {
        [address appendFormat:@":%d", port];
    }
    
    NSString *title = [[self fileName] lastPathComponent];
    if (title == nil) {
        title = [self displayName];
    }
    NSString *escapedTitle = (NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)title, NULL, CFSTR("/;=?"), kCFStringEncodingUTF8);
    DEBUGLOG(@"InternetLogDomain", DetailedLogLevel, @"escapedTitle: %@", escapedTitle);
    if (escapedTitle != nil) {
        [escapedTitle autorelease];
        [address appendFormat:@"/%@", escapedTitle];
    }

    NSString *documentId = [[self session] sessionID];
    NSString *escapedDocumentId = (NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)documentId, NULL, CFSTR(";/?:@&=+,$"), kCFStringEncodingUTF8);
    DEBUGLOG(@"InternetLogDomain", DetailedLogLevel, @"escapedDocumentId: %@", escapedDocumentId);
    if (escapedDocumentId != nil) {
        [escapedDocumentId autorelease];
        [address appendFormat:@"?%@=%@", @"documentID", escapedDocumentId];
    }

    DEBUGLOG(@"InternetLogLevel", DetailedLogLevel, @"address: %@", address);
    if (address != nil && [address length] > 0) {
        NSURL *url = [NSURL URLWithString:address];
        DEBUGLOG(@"InternetLogDomain", DetailedLogLevel, @"url: %@", [url description]);
        return url;
    }

    return nil;
}

#pragma mark -

- (NSString *)preparedDisplayName {
    NSArray *pathComponents = nil;
    if ([self fileName]) {
        pathComponents = [[self fileName] pathComponents];
    } else if ([self temporaryDisplayName]) {
        pathComponents = [[self temporaryDisplayName] pathComponents];
    } 
    
    if (pathComponents) {
        int count = [pathComponents count];
        if (count==1) return [pathComponents lastObject];
        NSMutableString *result = [NSMutableString string];
        int i = count;
        int pathComponentsToShow = [[NSUserDefaults standardUserDefaults] integerForKey:AdditionalShownPathComponentsPreferenceKey] + 1;
        for (i = count-1; i >= 1 && i > count-pathComponentsToShow-1; i--) {
            if (i != count-1) {
                [result insertString:@"/" atIndex:0];
            }
            [result insertString:[pathComponents objectAtIndex:i] atIndex:0];
        }
        if (pathComponentsToShow>1 && i<1 && [[pathComponents objectAtIndex:0] isEqualToString:@"/"]) {
            [result insertString:@"/" atIndex:0];
        }
        return result;
    } else {
        return [self displayName];
    }
}

- (NSString *)displayName {
    if ([self temporaryDisplayName] && ![self fileName]) {
        return [[self temporaryDisplayName] lastPathComponent];
    }
    
    if (I_flags.shouldChangeExtensionOnModeChange) {
        NSArray *recognizedExtensions = [I_documentMode recognizedExtensions];
        if ([recognizedExtensions count]) {
            return [[super displayName] stringByAppendingPathExtension:[recognizedExtensions objectAtIndex:0]];
        }
    } 
    return [super displayName];
}

- (void)setDisplayName:(NSString *)aDisplayName {
    if (![self fileName]) {
        [self setTemporaryDisplayName:aDisplayName];
    } else {
        [self setFileName:[[[self fileName] stringByDeletingLastPathComponent] stringByAppendingPathComponent:aDisplayName]];
    }
}

#pragma mark -
#pragma mark ### Printing ###

static NSString *S_measurementUnits;

- (NSTextView *)printableView {
    // make sure everything is colored if it should be
    MultiPagePrintView *printView=[[MultiPagePrintView alloc] initWithFrame:NSMakeRect(0.,0.,100.,100.) document:self];

    return [printView autorelease];
}

- (void)printShowingPrintPanel:(BOOL)showPanels {
    // Obtain a custom view that will be printed
    NSView *printView = [self printableView];

    if (!O_printOptionView) {
        [NSBundle loadNibNamed:@"PrintOptions" owner:self];
        if (!S_measurementUnits) {
            S_measurementUnits=[[[NSUserDefaults standardUserDefaults] stringForKey:@"AppleMeasurementUnits"] retain];
        }
        NSString *labelText=NSLocalizedString(([NSString stringWithFormat:@"Label%@",S_measurementUnits]),@"Centimeters or Inches, short label string for them");
        int i=996;
        for (i=996;i<1000;i++) {
            [[O_printOptionView viewWithTag:i] setStringValue:labelText];
        }
    }

    // Construct the print operation and setup Print panel
    NSPrintOperation *op = [NSPrintOperation printOperationWithView:printView printInfo:[self printInfo]];
    [op setShowPanels:showPanels];

    if (showPanels) {
        // Add accessory view, if needed
        [op setAccessoryView:O_printOptionView];
        [O_printOptionController setContent:[self printOptions]];
    }
    I_printOperationIsRunning=YES;
    // Run operation, which shows the Print panel if showPanels was YES
    [self runModalPrintOperation:op
                        delegate:self
                  didRunSelector:@selector(documentDidRunModalPrintOperation:success:contextInfo:)
                     contextInfo:[op retain]];
}

- (void)documentDidRunModalPrintOperation:(NSDocument *)document success:(BOOL)success contextInfo:(void *)contextInfo {
    I_printOperationIsRunning=NO;
    NSPrintOperation *op=(NSPrintOperation *)contextInfo;
    if (success) {
        [self setPrintInfo:[[NSPrintOperation currentOperation] printInfo]];
    }
    [O_printOptionController setContent:[NSMutableDictionary dictionary]];
    [op autorelease];
}

- (IBAction)changeFontViaPanel:(id)sender {
    NSDictionary *fontAttributes=[[O_printOptionController content] valueForKeyPath:@"dictionary.SEEFontAttributes"];
    NSFont *newFont=[NSFont fontWithName:[fontAttributes objectForKey:NSFontNameAttribute] size:[[fontAttributes objectForKey:NSFontSizeAttribute] floatValue]];
    if (!newFont) newFont=[NSFont userFixedPitchFontOfSize:[[fontAttributes objectForKey:NSFontSizeAttribute] floatValue]];
    
    [[NSFontManager sharedFontManager] 
        setSelectedFont:newFont 
             isMultiple:NO];
    [[NSFontManager sharedFontManager] orderFrontFontPanel:self];
}

- (void)changeFont:(id)aSender {
    NSFont *newFont = [aSender convertFont:I_fonts.plainFont];
    if (I_printOperationIsRunning) {
        NSMutableDictionary *dict=[NSMutableDictionary dictionary];
        [dict setObject:[newFont fontName] 
                 forKey:NSFontNameAttribute];
        [dict setObject:[NSNumber numberWithFloat:[newFont pointSize]] 
                 forKey:NSFontSizeAttribute];
        [[O_printOptionController content] setValue:dict forKeyPath:@"SEEFontAttributes"];
    } else {
        [self setPlainFont:newFont];
    }
}


#pragma mark -
- (UndoManager *)documentUndoManager {
    return I_undoManager;
}

#pragma mark -
#pragma mark ### Flag Accessors ###

- (BOOL)isHandlingUndoManually {
    return I_flags.isHandlingUndoManually;
}

- (void)setIsHandlingUndoManually:(BOOL)aFlag {
    I_flags.isHandlingUndoManually=aFlag;
}

- (BOOL)shouldChangeChangeCount {
    return I_flags.shouldChangeChangeCount;
}

- (void)setShouldChangeChangeCount:(BOOL)aFlag {
    if (aFlag!=I_flags.shouldChangeChangeCount) {
        I_flags.shouldChangeChangeCount=aFlag;
        [[self windowControllers] makeObjectsPerformSelector:@selector(synchronizeWindowTitleWithDocumentName)];
    }
}

// wrapline setting is only for book keeping - editor scope
- (BOOL)showInvisibleCharacters {
    return I_flags.showInvisibleCharacters;
}

- (void)setShowInvisibleCharacters:(BOOL)aFlag {
    I_flags.showInvisibleCharacters=aFlag;
}


// wrapline setting is only for book keeping - editor scope
- (BOOL)wrapLines {
    return I_flags.wrapLines;
}

- (void)setWrapLines:(BOOL)aFlag {
    if (I_flags.wrapLines!=aFlag) {
        I_flags.wrapLines=aFlag;
        [self TCM_sendPlainTextDocumentDidChangeEditStatusNotification];
    }
}

- (int)wrapMode {
    return I_flags.wrapMode;
}

- (IBAction)toggleWrapMode:(id)aSender {
  if (!(I_flags.wrapLines)) {
    [self setWrapMode:DocumentModeWrapModeWords];
    [self setWrapLines:YES];
  } else if (I_flags.wrapMode==DocumentModeWrapModeWords) {
    [self setWrapMode:DocumentModeWrapModeCharacters];
  } else {
    [self setWrapLines:NO];
  }
}

- (void)setWrapMode:(int)newMode {
    if (I_flags.wrapMode!=newMode) {
        I_flags.wrapMode=newMode;
        [self TCM_invalidateDefaultParagraphStyle];
        [self TCM_sendPlainTextDocumentDidChangeEditStatusNotification];
    }
}

- (void)setUsesTabs:(BOOL)aFlag {
    if (I_flags.usesTabs!=aFlag) {
        I_flags.usesTabs=aFlag;
        [self TCM_sendPlainTextDocumentDidChangeEditStatusNotification];
    }
}

- (BOOL)usesTabs {
    return I_flags.usesTabs;
}

- (int)tabWidth {
    return I_tabWidth;
}

- (void)setTabWidth:(int)aTabWidth {
    I_tabWidth=aTabWidth;
    if (I_tabWidth<1) {
        I_tabWidth=1;
    }
    [self TCM_invalidateDefaultParagraphStyle];
    [self TCM_sendPlainTextDocumentDidChangeEditStatusNotification];
}

- (BOOL)showsGutter {
    return I_flags.showGutter;
}

- (void)setShowsGutter:(BOOL)aFlag {
    I_flags.showGutter=aFlag;
}

- (BOOL)showsMatchingBrackets {
    return I_flags.showMatchingBrackets;
}
- (void)setShowsMatchingBrackets:(BOOL)aFlag {
    I_flags.showMatchingBrackets = aFlag;
}

- (BOOL)showsChangeMarks {
    return I_flags.showsChangeMarks;
}

- (void)setPlainTextEditorsShowChangeMarksOnInvitation
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:HighlightChangesPreferenceKey]) {
        NSEnumerator *plainTextEditors = [[self plainTextEditors] objectEnumerator];
        PlainTextEditor *editor = nil;
        while ((editor = [plainTextEditors nextObject])) {
            [editor setShowsChangeMarks:YES];
        }
    }
}

- (void)setShowsChangeMarks:(BOOL)aFlag {
    I_flags.showsChangeMarks=aFlag;
}

- (BOOL)indentsNewLines {
    return I_flags.indentNewLines;
}
- (void)setIndentsNewLines:(BOOL)aFlag {
    I_flags.indentNewLines=aFlag;
}

- (BOOL)showsTopStatusBar {
    return I_flags.showsTopStatusBar;
}
- (void)setShowsTopStatusBar:(BOOL)aFlag {
    I_flags.showsTopStatusBar=aFlag;
    DocumentMode *mode=[self documentMode];
    NSMutableDictionary *defaults=[mode defaults];
    [defaults setObject:[NSNumber numberWithBool:aFlag] forKey:DocumentModeShowTopStatusBarPreferenceKey];
}

- (BOOL)showsBottomStatusBar {
    return I_flags.showsBottomStatusBar;
}
- (void)setShowsBottomStatusBar:(BOOL)aFlag {
    I_flags.showsBottomStatusBar=aFlag;
    DocumentMode *mode=[self documentMode];
    NSMutableDictionary *defaults=[mode defaults];
    [defaults setObject:[NSNumber numberWithBool:aFlag] forKey:DocumentModeShowBottomStatusBarPreferenceKey];
}

- (BOOL)keepDocumentVersion {
    return I_flags.keepDocumentVersion;
}

- (void)setKeepDocumentVersion:(BOOL)aFlag {
    I_flags.keepDocumentVersion = aFlag;
}

- (BOOL)isFileWritable {
    return I_flags.isFileWritable;
}

- (void)setIsFileWritable:(BOOL)aFlag {
    I_flags.isFileWritable = aFlag;
}

- (BOOL)editAnyway {
    return I_flags.editAnyway;
}

- (void)setEditAnyway:(BOOL)aFlag {
    I_flags.editAnyway = aFlag;
}

- (BOOL)isContinuousSpellCheckingEnabled {
    return I_flags.isContinuousSpellCheckingEnabled;
}
- (void)setContinuousSpellCheckingEnabled:(BOOL)aFlag {
    if (aFlag!=I_flags.isContinuousSpellCheckingEnabled) {
        I_flags.isContinuousSpellCheckingEnabled=aFlag;
        [[[self documentMode] defaults] setObject:[NSNumber numberWithBool:aFlag] forKey:DocumentModeSpellCheckingPreferenceKey];
    }
}

- (BOOL)isReceivingContent {
    return I_flags.isReceivingContent;
}

- (void)setShouldSelectModeOnSave:(BOOL)aFlag {
    I_flags.shouldSelectModeOnSave = aFlag;
}

- (BOOL)shouldSelectModeOnSave {
    return I_flags.shouldSelectModeOnSave;
}

- (void)setShouldChangeExtensionOnModeChange:(BOOL)aFlag {
    I_flags.shouldChangeExtensionOnModeChange = aFlag;
}

- (BOOL)shouldChangeExtensionOnModeChange {
    return I_flags.shouldChangeExtensionOnModeChange;
}

#pragma mark -

- (void)alertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    NSDictionary *alertContext = (NSDictionary *)contextInfo;
    NSString *alertIdentifier = [alertContext objectForKey:@"Alert"];
    DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel, @"alertDidEnd: %@", alertIdentifier);

    if ([alertIdentifier isEqualToString:@"ShouldPromoteAlert"]) {
        NSTextView *textView = [alertContext objectForKey:@"TextView"];
        NSString *replacementString = [alertContext objectForKey:@"ReplacementString"];
        if (returnCode == NSAlertThirdButtonReturn) {
            [self setFileEncodingUndoable:NSUnicodeStringEncoding];
            if (replacementString) [textView insertText:replacementString];
        } else if (returnCode == NSAlertSecondButtonReturn) {
            [self setFileEncodingUndoable:NSUTF8StringEncoding];
            if (replacementString) [textView insertText:replacementString];
        } else if (returnCode == NSAlertFirstButtonReturn) {
            NSData *lossyData = [replacementString dataUsingEncoding:[self fileEncoding] allowLossyConversion:YES];
            if (lossyData) [textView insertText:[NSString stringWithData:lossyData encoding:[self fileEncoding]]];
        }
    } else if ([alertIdentifier isEqualToString:@"DocumentChangedExternallyAlert"]) {
        if (returnCode == NSAlertFirstButtonReturn) {
            [self setKeepDocumentVersion:YES];
            [self updateChangeCount:NSChangeDone];
        } else if (returnCode == NSAlertSecondButtonReturn) {
            DEBUGLOG(@"FileIOLogDomain", DetailedLogLevel, @"Revert document");
            NSError *error = nil;
            BOOL successful = [self revertToContentsOfURL:[self fileURL] ofType:[self fileType] error:&error];
            if (successful) {
                [self updateChangeCount:NSChangeCleared];
            } else {
                [self presentError:error];
            }
        }
    } else if ([alertIdentifier isEqualToString:@"DocumentChangedExternallyNoModificationsAlert"]) {
        if (returnCode == NSAlertFirstButtonReturn) {
            DEBUGLOG(@"FileIOLogDomain", DetailedLogLevel, @"Revert document");
            NSError *error = nil;
            BOOL successful = [self revertToContentsOfURL:[self fileURL] ofType:[self fileType] error:&error];
            if (successful) {
                [self updateChangeCount:NSChangeCleared];
            } else {
                [self presentError:error];
            }
        } else if (returnCode == NSAlertSecondButtonReturn) {
            [self setKeepDocumentVersion:YES];
        }
    } else if ([alertIdentifier isEqualToString:@"EditAnywayAlert"]) {
        if (returnCode == NSAlertFirstButtonReturn) {
            [self setEditAnyway:YES];
            NSInvocation *invocation = [alertContext objectForKey:@"Invocation"];
            if (invocation) {
                [invocation invoke];
            } else {
                NSTextView *textView = [alertContext objectForKey:@"TextView"];
                [textView insertText:[alertContext objectForKey:@"ReplacementString"]];
            }
        }
    } else if ([alertIdentifier isEqualToString:@"MixedLineEndingsAlert"]) {
        LineEnding lineEnding = [[alertContext objectForKey:@"LineEnding"] unsignedShortValue];
        if (returnCode == NSAlertFirstButtonReturn) {
            [[alert window] orderOut:self];
            [self convertLineEndingsToLineEnding:lineEnding];
        } else if (returnCode == NSAlertSecondButtonReturn) {
            [self setLineEnding:lineEnding];
        }
    } else if ([alertIdentifier isEqualToString:@"PasteWrongLineEndingsAlert"]) {
        NSTextView *textView = [alertContext objectForKey:@"TextView"];
        NSString *replacementString = [alertContext objectForKey:@"ReplacementString"];
        if (returnCode == NSAlertFirstButtonReturn) {
            [[alert window] orderOut:self];
            NSMutableString *mutableString = [[NSMutableString alloc] initWithString:replacementString];
            [mutableString convertLineEndingsToLineEndingString:[self lineEndingString]];
            [textView insertText:mutableString];
            [mutableString release];
        } else if (returnCode == NSAlertSecondButtonReturn) {
            [textView insertText:replacementString];
        }
    }

    [alertContext autorelease];
}

- (void)applicationDidBecomeActive:(NSNotification *)aNotification {
    DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel, @"applicationDidBecomeActive: %@", [self fileName]);
    if (![self fileName]) {
        return;
    }

    (void)[self TCM_validateDocument];
}

- (void)clearChangeCount {
    [self updateChangeCount:NSChangeCleared];
}

- (void)updateChangeCount:(NSDocumentChangeType)changeType {
    if (transientDocument == self) {
        transientDocument = nil;
    }
    
    if (changeType==NSChangeCleared || I_flags.shouldChangeChangeCount) {
        [super updateChangeCount:changeType];
    }
    
    NSEnumerator *enumerator = [[self windowControllers] objectEnumerator];
    id windowController;
    while ((windowController = [enumerator nextObject])) {
        if ([windowController isKindOfClass:[PlainTextWindowController class]]) {
            [(PlainTextWindowController *)windowController documentUpdatedChangeCount:self];
        }
    }
}

- (void)setIsDocumentEdited:(BOOL)aFlag {
    if ([self isDocumentEdited]) {
        if (aFlag == NO) {
            [self updateChangeCount:NSChangeCleared];
        }
    } else {
        if (aFlag == YES) {
             [self updateChangeCount:NSChangeDone];
        }
    }
}

#pragma mark -
#pragma mark ### Syntax Highlighting ###

- (IBAction)selectWrapMode:(id)aSender {
    [self setWrapMode:[aSender tag]];
}

- (IBAction)toggleUsesTabs:(id)aSender {
    [self setUsesTabs:![self usesTabs]];
}

- (IBAction)toggleIndentNewLines:(id)aSender {
    I_flags.indentNewLines=!I_flags.indentNewLines;
}

- (IBAction)changeTabWidth:(id)aSender {
    [self setTabWidth:[[aSender title] intValue]];
}

- (IBAction)chooseMode:(id)aSender {
    DocumentModeManager *modeManager=[DocumentModeManager sharedInstance];
    NSString *identifier=[modeManager documentModeIdentifierForTag:[aSender tag]];
    if (identifier) {
        DocumentMode *newMode=[modeManager documentModeForIdentifier:identifier];
        [self setDocumentMode:newMode];
        I_flags.shouldSelectModeOnSave=NO;
    }
}

- (void)setHighlightsSyntax:(BOOL)aFlag {
    if (I_flags.highlightSyntax != aFlag) {
        I_flags.highlightSyntax = aFlag;
        if (I_flags.highlightSyntax) {
            [self highlightSyntaxInRange:NSMakeRange(0,[I_textStorage length])];
        } else {
            [[I_documentMode syntaxHighlighter] cleanUpTextStorage:I_textStorage];
            [I_textStorage addAttributes:[self plainTextAttributes]
                                   range:NSMakeRange(0,[I_textStorage length])];
        }
    }
}

- (BOOL)highlightsSyntax {
    return I_flags.highlightSyntax;
}

- (IBAction)toggleSyntaxHighlighting:(id)aSender {
    [self setHighlightsSyntax:![self highlightsSyntax]];
}

- (void)highlightSyntaxInRange:(NSRange)aRange {
    if (I_flags.highlightSyntax) {
        NSRange range=NSIntersectionRange(aRange,NSMakeRange(0,[I_textStorage length]));
        if (range.length>0) {
            [I_textStorage removeAttribute:kSyntaxHighlightingIsCorrectAttributeName range:range];
            [[NSNotificationQueue defaultQueue]
                enqueueNotification:[NSNotification notificationWithName:PlainTextDocumentSyntaxColorizeNotification object:self]
                       postingStyle:NSPostWhenIdle
                       coalesceMask:NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender
                           forModes:[NSArray arrayWithObject:NSDefaultRunLoopMode]];
        }
    }
}

- (void)performHighlightSyntax {
    if (!I_flags.isPerformingSyntaxHighlighting && I_flags.highlightSyntax &&
        [I_documentMode syntaxHighlighter]!=nil) {
        // do relaxed slow highlighting if not the front window
        // the highlighter takes up to 0.3 seconds so schedule the highlighting for background windows
        // corresponding to that but no longer than 3 seconds
        float delay = MIN(3.,[[[DocumentController sharedInstance] documents] count]*0.3);
        if ([[[NSApp mainWindow] windowController] document] == self) {
            delay = 0.0;
            if (!I_flags.textDidChangeSinceLastSyntaxHighlighting) {
                // if we don't have a recent change take our time (but still be as quick as 2.6.5
                delay = 0.3;
            }
        }
        [self performSelector:@selector(highlightSyntaxLoop) withObject:nil afterDelay:delay];
        I_flags.isPerformingSyntaxHighlighting=YES;
    }
}

- (void)highlightSyntaxLoop {
    I_flags.isPerformingSyntaxHighlighting=NO;
    if (I_flags.highlightSyntax) {
        SyntaxHighlighter *highlighter=[I_documentMode syntaxHighlighter];
        if (highlighter) {
            if (!I_flags.syntaxHighlightingIsSuspended) {
                if (![highlighter colorizeDirtyRanges:I_textStorage ofDocument:self]) {
                    I_flags.textDidChangeSinceLastSyntaxHighlighting = NO;
                    [self performHighlightSyntax];
                }
            } else {
                [self performHighlightSyntax];
            }
        }
    }
	[self triggerUpdateSymbolTableTimer];
}

#pragma mark -
#pragma mark ### Session Interaction ###

- (NSSet *)userIDsOfContributors {
    NSMutableSet *result=[NSMutableSet set];
    NSTextStorage *textStorage=[self textStorage];
    id userID=nil;
    NSRange attributeRange=NSMakeRange(0,0);
    while (NSMaxRange(attributeRange)<[textStorage length]) {
        userID=[textStorage attribute:WrittenByUserIDAttributeName atIndex:NSMaxRange(attributeRange) effectiveRange:&attributeRange];
        if (userID) [result addObject:userID];
    }
    return result;
}

- (NSSet *)allUserIDs {
    NSMutableSet *result = [[[self userIDsOfContributors] mutableCopy] autorelease];
    [result unionSet:[[[self session] loggingState] participantIDs]];
    return result;
}


- (void)sendInitialUserStateViaMMState:(TCMMMState *)aState {
    TCMMMSession *session=[self session];
    NSString *sessionID=[session sessionID];
    NSEnumerator *writingParticipants=[[[session participants] objectForKey:@"ReadWrite"] objectEnumerator];
    TCMMMUser *user=nil;
    while ((user=[writingParticipants nextObject])) {
        SelectionOperation *selectionOperation=[[user propertiesForSessionID:sessionID] objectForKey:@"SelectionOperation"];
        if (selectionOperation) {
            [aState handleOperation:selectionOperation];
        }
    }

    [aState handleOperation:[SelectionOperation selectionOperationWithRange:[[[[self topmostWindowController] activePlainTextEditorForDocument:self] textView] selectedRange] userID:[TCMMMUserManager myUserID]]];
}

- (void)sessionDidDenyJoinRequest:(TCMMMSession *)aSession {
    [I_documentProxyWindowController joinRequestWasDenied];
}

- (void)sessionDidAcceptJoinRequest:(TCMMMSession *)aSession {
}

- (void)sessionDidReceiveKick:(TCMMMSession *)aSession {
    [self TCM_generateNewSession];
    
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setAlertStyle:NSInformationalAlertStyle];
    [alert setMessageText:NSLocalizedString(@"Kicked", @"Kick title in Sheet")];
    [alert setInformativeText:NSLocalizedString(@"KickedInfo", @"Kick info in Sheet")];
    [alert addButtonWithTitle:NSLocalizedString(@"OK", @"Ok in sheet")];
    [self presentAlert:alert modalDelegate:nil didEndSelector:NULL contextInfo:nil];
}

- (void)sessionDidLeave:(TCMMMSession *)aSession {
    [self TCM_generateNewSession];
    
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setAlertStyle:NSInformationalAlertStyle];
    [alert setMessageText:NSLocalizedString(@"ProblemLeave", @"ProblemLeave title in Sheet")];
    [alert setInformativeText:NSLocalizedString(@"ProblemLeaveInfo", @"ProblemLeaveInfo info in Sheet")];
    [alert addButtonWithTitle:NSLocalizedString(@"OK", @"Ok in sheet")];
    [self presentAlert:alert modalDelegate:nil didEndSelector:NULL contextInfo:nil];
}


- (void)sessionDidCancelInvitation:(TCMMMSession *)aSession {
    [I_documentProxyWindowController invitationWasCanceled];
}

- (void)sessionDidReceiveClose:(TCMMMSession *)aSession {
    [self TCM_generateNewSession];

    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setAlertStyle:NSInformationalAlertStyle];
    [alert setMessageText:NSLocalizedString(@"Closed", @"Server Closed Document title in Sheet")];
    [alert setInformativeText:NSLocalizedString(@"ClosedInfo", @"Server Closed Document info in Sheet")];
    [alert addButtonWithTitle:NSLocalizedString(@"OK", @"Ok in sheet")];
    if ([self isProxyDocument]) {
        [self sessionDidLoseConnection:aSession];
    } else {
        [self presentAlert:alert modalDelegate:nil didEndSelector:NULL contextInfo:nil];
    }
}

- (void)sessionDidLoseConnection:(TCMMMSession *)aSession {
    if ([[self windowControllers] count]>0) {
        [self TCM_generateNewSession];
        if (I_flags.isReceivingContent) {
            PlainTextWindowController *controller=[[self windowControllers] objectAtIndex:0];
            [controller documentDidLoseConnection:self];
        } else {
            NSAlert *alert = [[[NSAlert alloc] init] autorelease];
            [alert setAlertStyle:NSInformationalAlertStyle];
            [alert setMessageText:NSLocalizedString(@"LostConnection", @"LostConnection title in Sheet")];
            [alert setInformativeText:NSLocalizedString(@"LostConnectionInfo", @"LostConnection info in Sheet")];
            [alert addButtonWithTitle:NSLocalizedString(@"OK", @"Ok in sheet")];
            [self presentAlert:alert
                 modalDelegate:nil
                didEndSelector:NULL
                   contextInfo:nil];
        }
    } else if (I_documentProxyWindowController) {
        [I_documentProxyWindowController didLoseConnection];
    }
}

- (void)takeSettingsFromSessionInformation:(NSDictionary *)aSessionInformation {
    DocumentModeManager *manager=[DocumentModeManager sharedInstance];
    DocumentMode *mode=[manager documentModeForIdentifier:[aSessionInformation objectForKey:@"DocumentMode"]];
    if (!mode) {
		mode = [[DocumentModeManager sharedInstance] documentModeForPath:[[self session] filename] withContentString:[[self textStorage] string]];
    }
    [self setDocumentMode:mode];
    [self setLineEnding:[[aSessionInformation objectForKey:DocumentModeLineEndingPreferenceKey] intValue]];
    [self setTabWidth:[[aSessionInformation objectForKey:DocumentModeTabWidthPreferenceKey] intValue]];
    [self setUsesTabs:[[aSessionInformation objectForKey:DocumentModeUseTabsPreferenceKey] boolValue]];
    [self setWrapLines:[[aSessionInformation objectForKey:DocumentModeWrapLinesPreferenceKey] boolValue]];
    [self setWrapMode:[[aSessionInformation objectForKey:DocumentModeWrapModePreferenceKey] intValue]];
    if ([aSessionInformation objectForKey:@"FileType"]) {
        [self setFileType:[aSessionInformation objectForKey:@"FileType"]];
    }
}

- (void)session:(TCMMMSession *)aSession didReceiveSessionInformation:(NSDictionary *)aSessionInformation {
    [self takeSettingsFromSessionInformation:aSessionInformation];

    //[self setFileName:[aSession filename]];
    [self setTemporaryDisplayName:[aSession filename]];

    // this is slightly modified make window controllers code ...
    [self makeWindowControllers]; 
    PlainTextWindowController *windowController=[[self windowControllers] lastObject];
    
    [[windowController tabBar] updateViewsHack];
    I_flags.isReceivingContent=YES;
    [windowController document:self isReceivingContent:YES];
    
    BOOL closeTransient = transientDocument 
                          && NSEqualRects(transientDocumentWindowFrame, [[[transientDocument topmostWindowController] window] frame])
                          && [[[NSUserDefaults standardUserDefaults] objectForKey:OpenDocumentOnStartPreferenceKey] boolValue];

    if (closeTransient) {
         NSWindow *window = [[self topmostWindowController] window];
        [window setFrameTopLeftPoint:NSMakePoint(transientDocumentWindowFrame.origin.x, NSMaxY(transientDocumentWindowFrame))];
        [transientDocument close];
    } else if (![[windowController window] isVisible]) {
        [windowController cascadeWindow];
    }
    [I_documentProxyWindowController dissolveToWindow:[windowController window]];
    
    if (closeTransient) {
        transientDocument = nil;
    }
}

- (NSDictionary *)sessionInformation {
    NSMutableDictionary *result=[NSMutableDictionary dictionary];
    [result setObject:[[self documentMode] documentModeIdentifier] forKey:@"DocumentMode"];

//    DocumentModeLineEndingPreferenceKey = @"LineEnding";
//    DocumentModeTabWidthPreferenceKey   = @"TabWidth";
//    DocumentModeUseTabsPreferenceKey    = @"UseTabs";
//    DocumentModeWrapLinesPreferenceKey  = @"WrapLines";
//    DocumentModeWrapModePreferenceKey   = @"WrapMode";

    [result setObject:[NSNumber numberWithUnsignedInt:[self lineEnding]]
            forKey:DocumentModeLineEndingPreferenceKey];
    [result setObject:[NSNumber numberWithInt:[self tabWidth]]
            forKey:DocumentModeTabWidthPreferenceKey];
    [result setObject:[NSNumber numberWithBool:[self usesTabs]]
            forKey:DocumentModeUseTabsPreferenceKey];
    [result setObject:[NSNumber numberWithBool:[self wrapLines]]
            forKey:DocumentModeWrapLinesPreferenceKey];
    [result setObject:[NSNumber numberWithInt:[self wrapMode]]
            forKey:DocumentModeWrapModePreferenceKey];
    [result setObject:[self fileType]
            forKey:@"FileType"];
    return result;
}



- (NSDictionary *)documentState {
    NSMutableDictionary *result = [[self sessionInformation] mutableCopy];
    [result removeObjectForKey:@"FileType"]; // don't save the filetype in a seetext
    [result setObject:[NSNumber numberWithBool:[self showsChangeMarks]]
               forKey:HighlightChangesPreferenceKey];
    [result setObject:[NSNumber numberWithBool:[self showsGutter]]
               forKey:DocumentModeShowLineNumbersPreferenceKey];
    [result setObject:[NSNumber numberWithBool:[self showInvisibleCharacters]]
               forKey:DocumentModeShowInvisibleCharactersPreferenceKey];
    [result setObject:[NSNumber numberWithBool:[self highlightsSyntax]]
               forKey:DocumentModeHighlightSyntaxPreferenceKey];
    
    return result;
}

- (void)takeSettingsFromDocumentState:(NSDictionary *)aDocumentState {
    [self takeSettingsFromSessionInformation:aDocumentState];
    
    id value = nil;
    value = [aDocumentState objectForKey:HighlightChangesPreferenceKey];
    if (value) [self setValue:value forKey:@"showsChangeMarks"];
    value = [aDocumentState objectForKey:DocumentModeShowLineNumbersPreferenceKey];
    if (value) [self setValue:value forKey:@"showsGutter"];
    value = [aDocumentState objectForKey:DocumentModeShowInvisibleCharactersPreferenceKey];
    if (value) [self setValue:value forKey:@"showInvisibleCharacters"];
    value = [aDocumentState objectForKey:DocumentModeHighlightSyntaxPreferenceKey];
    if (value) [self setValue:value forKey:@"highlightsSyntax"];
    value = [aDocumentState objectForKey:DocumentModeLineEndingPreferenceKey];
    if (value) [self setValue:value forKey:@"lineEnding"];
    
}

- (void)setFileName:(NSString *)fileName {
    [super setFileName:fileName];
    TCMMMSession *session=[self session];
    if ([session isServer]) {
        [session setFilename:[self preparedDisplayName]];
    }
}

- (NSDictionary *)textStorageDictionaryRepresentation
{
    return [(TextStorage *)[self textStorage] dictionaryRepresentation];
}

- (void)setContentByDictionaryRepresentation:(NSDictionary *)aRepresentation {
    I_flags.isRemotelyEditingTextStorage=YES;
    TextStorage *textStorage=(TextStorage *)[self textStorage];
    [textStorage setContentByDictionaryRepresentation:[aRepresentation objectForKey:@"TextStorage"]];
    NSRange wholeRange=NSMakeRange(0,[textStorage length]);
    [textStorage addAttributes:[self plainTextAttributes] range:wholeRange];
    [textStorage addAttribute:NSParagraphStyleAttributeName value:[self defaultParagraphStyle] range:wholeRange];
    I_flags.isRemotelyEditingTextStorage=NO;
    [self TCM_sendPlainTextDocumentDidChangeEditStatusNotification];
    [self updateChangeCount:NSChangeCleared];
    I_flags.shouldSelectModeOnSave=NO;
    I_flags.shouldChangeExtensionOnModeChange=NO;
}

- (void)session:(TCMMMSession *)aSession didReceiveContent:(NSDictionary *)aContent {
    if ([[self windowControllers] count]>0) {
        [self setContentByDictionaryRepresentation:aContent];
        I_flags.isReceivingContent = NO;
        PlainTextWindowController *windowController=(PlainTextWindowController *)[[self windowControllers] objectAtIndex:0];
        [windowController document:self isReceivingContent:NO];
    }
    I_flags.isReceivingContent = NO;
}


- (NSEnumerator *)matchEnumeratorForAutocompleteString:(NSString *)aPartialWord {

    static OGRegularExpression *escapingExpression = nil;
    if (!escapingExpression) {
        escapingExpression = [[OGRegularExpression alloc] initWithString:@"[\\-\\[\\]^]" options:OgreFindNotEmptyOption];
    }

    NSString *escapedString = [aPartialWord stringByReplacingRegularExpressionOperators];
    NSString *autocompleteTokenString = [[[self documentMode] syntaxDefinition] autocompleteTokenString];
    NSString *autocompleteSetString         = @"\\w";
    NSString *autocompleteInverseSetString  = @"\\W";
    if (autocompleteTokenString) {
        autocompleteTokenString = [escapingExpression replaceAllMatchesInString:autocompleteTokenString withString:@"\\\\\\0" options:OgreNoneOption];
        autocompleteSetString        = [NSString stringWithFormat:@"[%@]",autocompleteTokenString];
        autocompleteInverseSetString = [NSString stringWithFormat:@"[^%@]",autocompleteTokenString];
    }
    NSString *regExString = [NSString stringWithFormat:@"(?<=%@|^)%@%@+",autocompleteInverseSetString,escapedString,autocompleteSetString];
    OGRegularExpression *findExpression=[[[OGRegularExpression alloc] initWithString:regExString options:OgreFindNotEmptyOption] autorelease];
    return [findExpression matchEnumeratorInString:[[self textStorage] string]];
}


- (void)changeSelectionOfUserWithID:(NSString *)aUserID toRange:(NSRange)aRange {
    TCMMMUser *user=[[TCMMMUserManager sharedInstance] userForUserID:aUserID];
    NSMutableDictionary *properties=[user propertiesForSessionID:[[self session] sessionID]];
    if (!properties) {
        //NSLog(@"Tried to change selection of user for session in which he isnt");
    } else {
        SelectionOperation *selectionOperation=[properties objectForKey:@"SelectionOperation"];
        if (selectionOperation) {
            [self invalidateLayoutForRange:[selectionOperation selectedRange]];
            [selectionOperation setSelectedRange:aRange];
        } else {
            [properties setObject:[SelectionOperation selectionOperationWithRange:aRange userID:aUserID] forKey:@"SelectionOperation"];
        }
        [self invalidateLayoutForRange:aRange];
    }
    [[NSNotificationQueue defaultQueue]
    enqueueNotification:[NSNotification notificationWithName:PlainTextDocumentUserDidChangeSelectionNotification object:self userInfo:[NSDictionary dictionaryWithObject:user forKey:@"User"]]
           postingStyle:NSPostWhenIdle
           coalesceMask:0
               forModes:[NSArray arrayWithObject:NSDefaultRunLoopMode]];

    [self TCM_sendPlainTextDocumentParticipantsDataDidChangeNotification];
}


- (NSArray *)plainTextEditors {
    NSMutableArray *result = [NSMutableArray array];
    NSEnumerator *windowControllers = [[self windowControllers] objectEnumerator];
    PlainTextWindowController *windowController;
    while ((windowController = [windowControllers nextObject])) {
        [result addObjectsFromArray:[windowController plainTextEditorsForDocument:self]];
    }
    return result;
}

- (BOOL)handleOperation:(TCMMMOperation *)aOperation {
    if ([[aOperation operationID] isEqualToString:[TextOperation operationID]]) {
        TextOperation *operation=(TextOperation *)aOperation;
        NSTextStorage *textStorage=[self textStorage];
    
        // check validity of operation
        if (NSMaxRange([operation affectedCharRange])>[textStorage length]) {
            NSLog(@"User tried to change text outside the document bounds:%@ %@",operation,[[TCMMMUserManager sharedInstance] userForUserID:[operation userID]]);
            return NO;
        }
    
        // gather selections from all textviews and transform them
        NSArray *editors=[self plainTextEditors];
        I_flags.isRemotelyEditingTextStorage=![[aOperation userID] isEqualToString:[TCMMMUserManager myUserID]];
        NSMutableArray   *oldSelections=[NSMutableArray array];
        if (I_flags.isRemotelyEditingTextStorage) {
            NSEnumerator *editorEnumerator=[editors objectEnumerator];
            PlainTextEditor *editor=nil;
            while ((editor=[editorEnumerator nextObject])) {
                [oldSelections addObject:[SelectionOperation selectionOperationWithRange:[[editor textView] selectedRange] userID:@"doesn't matter"]];
            }
        }

        [textStorage beginEditing];
        NSRange newRange=NSMakeRange([operation affectedCharRange].location,
                                     [[operation replacementString] length]);
        [textStorage replaceCharactersInRange:[operation affectedCharRange]
                                   withString:[operation replacementString]];
        [textStorage addAttribute:WrittenByUserIDAttributeName value:[operation userID]
                            range:newRange];
        [textStorage addAttribute:ChangedByUserIDAttributeName value:[operation userID]
                            range:newRange];
        [textStorage addAttributes:[self plainTextAttributes] range:newRange];
        [textStorage endEditing];


        if (I_flags.isRemotelyEditingTextStorage) {
            // set selection of all textviews
            TCMMMTransformator *transformator=[TCMMMTransformator sharedInstance];
            int index=0;
            for (index=0;index<(int)[editors count];index++) {
                SelectionOperation *selectionOperation = [oldSelections objectAtIndex:index];
                [transformator transformOperation:selectionOperation serverOperation:aOperation];
                PlainTextEditor *editor = [editors objectAtIndex:index];
                [[editor textView] setSelectedRange:[selectionOperation selectedRange]];
            }
        }

        if (I_flags.isRemotelyEditingTextStorage) {
            [[self documentUndoManager] transformStacksWithOperation:operation];
        }
        I_flags.isRemotelyEditingTextStorage=NO;
    } else if ([[aOperation operationID] isEqualToString:[SelectionOperation operationID]]){
        [self changeSelectionOfUserWithID:[aOperation userID]
              toRange:[(SelectionOperation *)aOperation selectedRange]];
    }
    return YES;
}

#pragma mark -
#pragma mark ### TextStorage Delegate Methods ###
- (void)textStorage:(NSTextStorage *)aTextStorage willReplaceCharactersInRange:(NSRange)aRange withString:(NSString *)aString {
//    NSLog(@"textStorage:%@ willReplaceCharactersInRange:%@ withString:%@",aTextStorage,NSStringFromRange(aRange),aString);
    if (!I_flags.isRemotelyEditingTextStorage && !I_flags.isReadingFile && !I_flags.isHandlingUndoManually) {
        TextOperation *operation=[TextOperation textOperationWithAffectedCharRange:aRange replacementString:aString userID:(NSString *)[TCMMMUserManager myUserID]];
        UndoManager *undoManager=[self documentUndoManager];
        BOOL shouldGroup=YES;
        if (![undoManager isRedoing] && ![undoManager isUndoing]) {
            shouldGroup=[operation shouldBeGroupedWithTextOperation:I_lastRegisteredUndoOperation];
        }
        [undoManager registerUndoChangeTextInRange:NSMakeRange(aRange.location,[aString length])
                     replacementString:[[aTextStorage string] substringWithRange:aRange] shouldGroupWithPriorOperation:shouldGroup];
        [I_lastRegisteredUndoOperation release];
        I_lastRegisteredUndoOperation = [operation retain];
    }
}

- (void)textStorage:(NSTextStorage *)aTextStorage didReplaceCharactersInRange:(NSRange)aRange withString:(NSString *)aString {
//    NSLog(@"textStorage:%@ didReplaceCharactersInRange:%@ withString:%@\n\n%d==%d?",aTextStorage,NSStringFromRange(aRange),aString, [aTextStorage length], [aString length]);
    TextOperation *textOp=[TextOperation textOperationWithAffectedCharRange:aRange replacementString:aString userID:[TCMMMUserManager myUserID]];
    if (!I_flags.isRemotelyEditingTextStorage) {
        [[self session] documentDidApplyOperation:textOp];
    } 
    
    if ([aTextStorage length]==[aString length]) {
        [aTextStorage addAttributes:[self plainTextAttributes] range:NSMakeRange(0,[aString length])];
    }

    if (I_flags.highlightSyntax) {
        if ([aString length]) {
            NSRange range=NSMakeRange(aRange.location,[aString length]);
            [self highlightSyntaxInRange:range];
        } else {
            unsigned length=[aTextStorage length];
            NSRange range=NSMakeRange(aRange.location!=0?aRange.location-1:aRange.location,length>=2?2:1);
            if (length>=NSMaxRange(range)) {
                [aTextStorage removeAttribute:kSyntaxHighlightingIsCorrectAttributeName range:range];
            }
            [self highlightSyntaxInRange:range];
        }
    }

    UndoManager *undoManager=[self documentUndoManager];
    if (![undoManager isUndoing]) {
//        NSLog(@"ChangeDone");
        [self updateChangeCount:NSChangeDone];
        if (I_flags.showMatchingBrackets && ![undoManager isRedoing] &&
            !I_flags.isRemotelyEditingTextStorage &&
    //        !I_blockedit.isBlockediting && !I_blockedit.didBlockedit &&
            [aString length]==1 &&
            [self TCM_charIsBracket:[aString characterAtIndex:0]] && [self TCM_validTypeForBracketBeforeAndAfterIndex:aRange.location]) {
            I_bracketMatching.matchingBracketPosition=aRange.location;
        }
    } else {
        [self updateChangeCount:NSChangeUndone];
    }
    I_flags.textDidChangeSinceLastSyntaxHighlighting=YES;
    [self triggerUpdateSymbolTableTimer];

// transform all selectedRanges
    TCMMMSession *session=[self session];
    NSString *sessionID=[session sessionID];
    NSEnumerator *participants=[[[session participants] objectForKey:@"ReadWrite"] objectEnumerator];
    BOOL didChangeAParticipant=NO;
    TCMMMUser *user=nil;
    TCMMMTransformator *transformator=[TCMMMTransformator sharedInstance];
    while ((user=[participants nextObject])) {
        SelectionOperation *selectionOperation=[[user propertiesForSessionID:sessionID] objectForKey:@"SelectionOperation"];
        if (selectionOperation) {
            NSRange oldRange=[selectionOperation selectedRange];
            [transformator transformOperation:selectionOperation serverOperation:textOp];
            if (!NSEqualRanges(oldRange,[selectionOperation selectedRange])) {
//                [self invalidateLayoutForRange:oldRange];
                if (TouchingRanges([selectionOperation selectedRange], 
                    [[aTextStorage string] lineRangeForRange:NSMakeRange([textOp affectedCharRange].location,
                                    [[textOp replacementString] length])])) {
                    [self invalidateLayoutForRange:[selectionOperation selectedRange]];
                }
                didChangeAParticipant=YES;
            }
        }
    }
    if (didChangeAParticipant) {
        [self TCM_sendPlainTextDocumentParticipantsDataDidChangeNotification];
    }

// transform SymbolTable if there
    NSEnumerator *entries=[I_symbolArray objectEnumerator];
    SymbolTableEntry *entry=nil;
    while ((entry=[entries nextObject])) {
        if (![entry isSeparator]) {
            [transformator transformOperation:[entry jumpRangeSelectionOperation] serverOperation:textOp];
            [transformator transformOperation:[entry rangeSelectionOperation] serverOperation:textOp];
        }
    }


// transform FindAllTables if there
    NSEnumerator *findAllWindows = [I_findAllControllers objectEnumerator];
    FindAllController *findAllWindow = nil;
    while ((findAllWindow = [findAllWindows nextObject])) {
        NSEnumerator *operations = [[findAllWindow arrangedObjects] objectEnumerator];
        NSDictionary *dictionary = nil;
        while ((dictionary = [operations nextObject])) {
            TCMMMOperation *operation = [dictionary objectForKey:@"selectionOperation"];
            [transformator transformOperation:operation serverOperation:textOp];
        }
    }

// transform EncodingDoctorTables if there
    NSArray *windowControllers = [self windowControllers];
    int i=[windowControllers count];
    while (--i>=0) {
        id dialog = [[windowControllers objectAtIndex:i] documentDialog];
        if ([dialog respondsToSelector:@selector(takeNoteOfOperation:transformator:)]) {
            [dialog takeNoteOfOperation:textOp transformator:transformator];
        }
    }



// WebPreview
    if (I_webPreviewWindowController &&
        [[I_webPreviewWindowController window] isVisible] &&
        ([I_webPreviewWindowController refreshType]==kWebPreviewRefreshAutomatic ||
         [I_webPreviewWindowController refreshType]==kWebPreviewRefreshDelayed)) {
        [[NSNotificationQueue defaultQueue]
    enqueueNotification:[NSNotification notificationWithName:PlainTextDocumentRefreshWebPreviewNotification object:self]
           postingStyle:NSPostWhenIdle
           coalesceMask:NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender
               forModes:[NSArray arrayWithObject:NSDefaultRunLoopMode]];

    }
    [[NSNotificationQueue defaultQueue]
    enqueueNotification:[NSNotification notificationWithName:PlainTextDocumentDidChangeTextStorageNotification object:self]
           postingStyle:NSPostWhenIdle
           coalesceMask:NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender
               forModes:[NSArray arrayWithObject:NSDefaultRunLoopMode]];
}

- (NSDictionary *)blockeditAttributesForTextStorage:(TextStorage *)aTextStorage {
    return [self blockeditAttributes];
}

- (void)textStorageDidStartBlockedit:(TextStorage *)aTextStorage {
    [[self plainTextEditors] makeObjectsPerformSelector:@selector(TCM_updateStatusBar)];
}

- (void)textStorageDidStopBlockedit:(TextStorage *)aTextStorage {
    [[self plainTextEditors] makeObjectsPerformSelector:@selector(TCM_updateStatusBar)];
}

#pragma mark -

- (void)userWillLeaveSession:(NSNotification *)aNotification {
    NSString *sessionID=[[self session] sessionID];
    if ([sessionID isEqualToString:[[aNotification userInfo] objectForKey:@"SessionID"]]) {
        [[NSNotificationQueue defaultQueue]
        enqueueNotification:[NSNotification notificationWithName:PlainTextDocumentUserDidChangeSelectionNotification object:self userInfo:[NSDictionary dictionaryWithObject:[aNotification object] forKey:@"User"]]
               postingStyle:NSPostWhenIdle
               coalesceMask:0
                   forModes:[NSArray arrayWithObject:NSDefaultRunLoopMode]];

    }
}

#pragma mark -
#pragma mark ### TextView Notifications / Extended Delegate ###

- (BOOL)textView:(NSTextView *)aTextView doCommandBySelector:(SEL)aSelector {
//    NSLog(@"TextDocument textView doCommandBySelector:%@",NSStringFromSelector(aSelector));
    NSRange affectedRange=[aTextView rangeForUserTextChange];
    NSRange selectedRange=[aTextView selectedRange];
    if (aSelector==@selector(cancel:)) {
        TextStorage *textStorage=(TextStorage *)[self textStorage];
        if ([textStorage hasBlockeditRanges]) {
            [textStorage stopBlockedit];
            return YES;
        }
    } else if ([aTextView isEditable]) {
        if (aSelector==@selector(deleteBackward:)) {
            //NSLog(@"AffectedRange=%d,%d",affectedRange.location,affectedRange.length);
            if (affectedRange.length==0 && affectedRange.location>0) {
                if (!I_flags.usesTabs) {
                    // when we have a tab we have to find the last linebreak
                    NSString *string=[[self textStorage] string];
                    NSRange lineRange=[string lineRangeForRange:affectedRange];
                    unsigned firstCharacter=0;
                    int position=affectedRange.location;
                    while (position-->lineRange.location) {
                        if (!firstCharacter && [string characterAtIndex:position]!=[@"\t" characterAtIndex:0] &&
                                               [string characterAtIndex:position]!=[@" " characterAtIndex:0]) {
                            firstCharacter=position+1;
                            break;
                        }
                    }
                    position=lineRange.location;
                    //NSLog(@"last linebreak, firstcharacter=%d,%d",position,firstCharacter);
                    if (firstCharacter==affectedRange.location
                        || affectedRange.location==lineRange.location
                        || firstCharacter) {
                        return NO;
                    }
                    int toDelete=(affectedRange.location-lineRange.location)%I_tabWidth;
                    if (toDelete==0) {
                        toDelete=I_tabWidth;
                    }
                    NSRange deleteRange;
                    deleteRange.location=affectedRange.location-toDelete;
                    deleteRange.length  =affectedRange.location-deleteRange.location;
                    if ([aTextView shouldChangeTextInRange:deleteRange replacementString:@""]) {
                        [[aTextView textStorage] replaceCharactersInRange:deleteRange withString:@""];
                        [aTextView didChangeText];
                    }
                    return YES;
                }
            }
        } else if (aSelector==@selector(insertNewline:)) {
            NSString *indentString=nil;
            if (I_flags.indentNewLines) {
                // when we have a newline, we have to find the last linebreak
                NSString    *string=[[self textStorage] string];
                NSRange indentRange=[string lineRangeForRange:affectedRange];
                indentRange = [string rangeOfLeadingWhitespaceStartingAt:indentRange.location];
                if (NSMaxRange(indentRange)>affectedRange.location) {
                    indentRange.length-=NSMaxRange(indentRange)-affectedRange.location;
                }
                if (indentRange.length) {
                    indentString=[string substringWithRange:indentRange];
                }
            }
            if (indentString) {
                [aTextView insertText:[NSString stringWithFormat:@"%@%@",[self lineEndingString],indentString]];
            } else {
                [aTextView insertText:[self lineEndingString]];
            }
            return YES;

        } else if (aSelector==@selector(insertTab:) && !I_flags.usesTabs) {
            // when we have a tab we have to find the last linebreak
            NSRange lineRange=[[[self textStorage] string] lineRangeForRange:affectedRange];
            NSString *replacementString=[@" " stringByPaddingToLength:I_tabWidth-((affectedRange.location-lineRange.location)%I_tabWidth)
                                                           withString:@" " startingAtIndex:0];
            [aTextView insertText:replacementString];
            return YES;
        } else if ((aSelector==@selector(moveLeft:)    || aSelector==@selector(moveRight:) || 
                    aSelector==@selector(moveForward:) || aSelector==@selector(moveBackward:)) &&
                    I_flags.showMatchingBrackets) {
            unsigned int position=0;
            if (aSelector==@selector(moveLeft:) || aSelector==@selector(moveBackward:)) {
                position=selectedRange.location-1;
            } else {
                position=NSMaxRange(selectedRange);
            }
            NSString *string=[[self textStorage] string];
            if (position>=0 && position<[string length] &&
                [self TCM_charIsBracket:[string characterAtIndex:position]] && [self TCM_validTypeForBracketAtIndex:position]) {
                [self TCM_highlightBracketAtPosition:position inTextView:aTextView];
            }
        }
    }
//    _flags.controlBlockedit=YES;
    return NO;
}

- (NSRange)textView:(NSTextView *)aTextView
           willChangeSelectionFromCharacterRange:(NSRange)aOldSelectedCharRange
                                toCharacterRange:(NSRange)aNewSelectedCharRange {
    TextStorage *textStorage = (TextStorage *)[aTextView textStorage];
    if (![textStorage isBlockediting] && [textStorage hasBlockeditRanges] && !I_flags.isRemotelyEditingTextStorage && ![[self documentUndoManager] isPerformingGroup]) {
        if ([textStorage length]==0) {
            [textStorage stopBlockedit];
        } else {
            unsigned positionToCheck=aOldSelectedCharRange.location;
            if (positionToCheck<[textStorage length] && positionToCheck!=0) {
                if (positionToCheck>=[textStorage length]) positionToCheck--;
                NSDictionary *attributes=[textStorage attributesAtIndex:positionToCheck effectiveRange:NULL];
                if ([attributes objectForKey:BlockeditAttributeName]) {
                    positionToCheck=aNewSelectedCharRange.location;
                    if (positionToCheck<[textStorage length] && positionToCheck!=0) {
                        if (positionToCheck>=[textStorage length]) positionToCheck--;
                        attributes=[textStorage attributesAtIndex:positionToCheck effectiveRange:NULL];
                        if (![attributes objectForKey:BlockeditAttributeName]) {
                            [textStorage stopBlockedit];
                        }
                    }
                }
            }
        }
    }

    if (([[NSApp currentEvent] type] == NSLeftMouseUp) &&
        ([[NSApp currentEvent] clickCount] == 2)) {

        NSLayoutManager *layoutManager=[aTextView layoutManager];
        NSPoint point = [aTextView convertPoint:[[NSApp currentEvent] locationInWindow] fromView:nil];
        point.x -= [aTextView textContainerOrigin].x;
        point.y -= [aTextView textContainerOrigin].y;
        unsigned glyphIndex=[layoutManager glyphIndexForPoint:point
                                              inTextContainer:[aTextView textContainer]];
        NSRect    glyphRect=[layoutManager boundingRectForGlyphRange:NSMakeRange(glyphIndex, 1)
                                                     inTextContainer:[aTextView textContainer]];
        if (NSPointInRect(point, glyphRect)) {
            // Convert the glyph index to a character index
            unsigned charIndex=[layoutManager characterIndexForGlyphAtIndex:glyphIndex];
            NSString *string=[[self textStorage] string];
            if ([self TCM_charIsBracket:[string characterAtIndex:charIndex]] && [self TCM_validTypeForBracketAtIndex:charIndex]) {
                unsigned matchingPosition=[self TCM_positionOfMatchingBracketToPosition:charIndex];
                if (matchingPosition!=NSNotFound) {
                   aNewSelectedCharRange = NSUnionRange(NSMakeRange(charIndex,1),
                                                        NSMakeRange(matchingPosition,1));
                }
            }
        }
    }

    return aNewSelectedCharRange;
}


- (void)textViewDidChangeSelection:(NSNotification *)aNotification {
    if (!I_flags.isRemotelyEditingTextStorage) {
        NSTextView *textView=(NSTextView *)[aNotification object];
        NSRange selectedRange = [textView selectedRange];
        SelectionOperation *selOp = [SelectionOperation selectionOperationWithRange:selectedRange userID:[TCMMMUserManager myUserID]];
        [[self session] documentDidApplyOperation:selOp];
        [self TCM_sendPlainTextDocumentParticipantsDataDidChangeNotification];
    }
}

- (BOOL)textView:(NSTextView *)aTextView shouldChangeTextInRange:(NSRange)aAffectedCharRange replacementString:(NSString *)aReplacementString {

    TextStorage *textStorage=(TextStorage *)[aTextView textStorage];
    if ([aTextView hasMarkedText] && !I_flags.didPauseBecauseOfMarkedText) {
        //NSLog(@"paused because of marked...");
        I_flags.didPauseBecauseOfMarkedText=YES;
        [[self session] pauseProcessing];
    }

    UndoManager *undoManager=[self documentUndoManager];
    if ([textStorage hasBlockeditRanges] && ![textStorage isBlockediting] &&
        ![undoManager isRedoing] && ![undoManager isUndoing] && [textStorage length]>0) {
        if ([[NSApp currentEvent] type]==NSLeftMouseUp) {
            NSBeep();
            return NO;
        }
        static NSMutableCharacterSet *lineEndingSet=nil;
        if (!lineEndingSet) {
            unichar seps[2];
            seps[0]=0x2028;
            seps[1]=0x2029;
            NSString *unicodeLSEP=[NSString stringWithCharacters:seps   length:1];
            NSString *unicodePSEP=[NSString stringWithCharacters:seps+1 length:1];
            lineEndingSet=[[NSMutableCharacterSet characterSetWithCharactersInString:[NSString stringWithFormat:@"\n\r%@%@",unicodeLSEP,unicodePSEP]] retain];
        }

        NSRange wholeRange=NSMakeRange(0,[textStorage length]);
        NSString *string=[textStorage string];
        id value=[textStorage attribute:BlockeditAttributeName
                    atIndex:(aAffectedCharRange.location < wholeRange.length)?
                            aAffectedCharRange.location : wholeRange.length-1
                    longestEffectiveRange:nil inRange:wholeRange];
        if (value) {
            NSRange foundRange=[string rangeOfCharacterFromSet:lineEndingSet options:0 range:aAffectedCharRange];
            if (foundRange.location!=NSNotFound) {
                NSBeep();
                return NO;
            }
            foundRange=[aReplacementString rangeOfCharacterFromSet:lineEndingSet];
            if (foundRange.location!=NSNotFound) {
                NSBeep();
                return NO;
            }

            if (![textStorage didBlockedit]) {
                [[self documentUndoManager] beginUndoGrouping];

                int tabWidth=[self tabWidth];
                NSRange lineRange=[string lineRangeForRange:aAffectedCharRange];
                unsigned locationLength=[string
                    detabbedLengthForRange:NSMakeRange(lineRange.location,aAffectedCharRange.location-lineRange.location)
                                  tabWidth:tabWidth];
                unsigned length=[string
                    detabbedLengthForRange:NSMakeRange(lineRange.location,NSMaxRange(aAffectedCharRange)-lineRange.location)
                                  tabWidth:tabWidth];
        //        lineRange.location=_flags.didBlockeditRange.location-lineRange.location;
                [textStorage setDidBlockedit:YES];
                [textStorage setDidBlockeditRange:aAffectedCharRange];
                [textStorage setDidBlockeditLineRange:NSMakeRange(locationLength,length-locationLength)];
                I_blockeditTextView=aTextView;
            }
        } else {
            [textStorage stopBlockedit];
        }

    }

    return YES;
}

- (void)textDidChange:(NSNotification *)aNotification {
    NSTextView *textView=[aNotification object];
    if (I_flags.didPauseBecauseOfMarkedText && textView && ![textView hasMarkedText]) {
        //NSLog(@"started because of marked... in did change");
        I_flags.didPauseBecauseOfMarkedText=NO;
        [[self session] startProcessing];
//        DEBUGLOG(@"MillionMonkeysDomain",AlwaysLogLevel,@"start");
    }


    TextStorage *textStorage = (TextStorage *) [textView textStorage];
    // take care for blockedit

    if (![textStorage didBlockedit]) {
        if (I_bracketMatching.matchingBracketPosition!=NSNotFound) {
            [self TCM_highlightBracketAtPosition:I_bracketMatching.matchingBracketPosition inTextView:textView];
            I_bracketMatching.matchingBracketPosition=NSNotFound;
        }
    }
    
    if ([textStorage didBlockedit] && ![textStorage isBlockediting] && ![textView hasMarkedText]) {
        [textStorage beginEditing];
        NSRange lineRange=[textStorage didBlockeditLineRange];
        NSRange selectedRange=[textView selectedRange];
        NSRange didBlockeditRange=[textStorage didBlockeditRange];
        NSString *replacementString=[[textStorage string]
                                        substringWithRange:NSMakeRange(didBlockeditRange.location,
                                                                       selectedRange.location-didBlockeditRange.location)];
        NSRange wholeRange=NSMakeRange(0,[textStorage length]);
        NSRange blockeditRange=NSMakeRange(wholeRange.length,0);
        NSRange newSelectedRange=NSMakeRange(NSNotFound,0);
        int lengthChange=0;
        NSRange tempRange;
        while (blockeditRange.location!=0) {
            id value=[textStorage attribute:BlockeditAttributeName atIndex:blockeditRange.location-1
                              longestEffectiveRange:&blockeditRange inRange:wholeRange];

            if (value) {
                if ((!DisjointRanges(blockeditRange,selectedRange) ||
                           selectedRange.location==blockeditRange.location ||
                       NSMaxRange(blockeditRange)==selectedRange.location)) {
                    [textStorage setIsBlockediting:YES];
                    NSRange lineRangeToExclude=[[textStorage string] lineRangeForRange:NSMakeRange(selectedRange.location,0)];
                    if (NSMaxRange(blockeditRange)>NSMaxRange(lineRangeToExclude)) {
                        [textStorage blockChangeTextInRange:lineRange
                                          replacementString:replacementString
                                             paragraphRange:NSMakeRange(NSMaxRange(lineRangeToExclude),
                                                                 NSMaxRange(blockeditRange)-NSMaxRange(lineRangeToExclude))
                                                 inTextView:textView
                                                   tabWidth:[self tabWidth] useTabs:[self usesTabs]];
//                        NSLog(@"Edited Block after");
                    }
                    newSelectedRange=[textView selectedRange];
                    if (blockeditRange.location<lineRangeToExclude.location) {
                        NSRange otherRange;
                        tempRange=
                        [textStorage blockChangeTextInRange:lineRange
                                          replacementString:replacementString
                                             paragraphRange:(otherRange=NSMakeRange(blockeditRange.location,
                                                                 lineRangeToExclude.location-blockeditRange.location))
                                                 inTextView:textView
                                                   tabWidth:[self tabWidth] useTabs:[self usesTabs]];
//                        NSLog(@"Edited Block before");
                        lengthChange+=tempRange.length-otherRange.length;
                    }
                    [textStorage setIsBlockediting:NO];
                } else {
                    [textStorage setIsBlockediting:YES];
                    tempRange=
                    [textStorage blockChangeTextInRange:lineRange
                                      replacementString:replacementString
                                         paragraphRange:blockeditRange
                                             inTextView:textView
                                               tabWidth:[self tabWidth] useTabs:[self usesTabs]];
    //                        NSLog(@"Edited Block");
                    if (newSelectedRange.location!=NSNotFound) {
                        lengthChange+=tempRange.length-blockeditRange.length;
                    }
                    [textStorage setIsBlockediting:NO];
                }
            }
        }
        [textStorage setDidBlockedit:NO];
        I_blockeditTextView=nil;
        [[self documentUndoManager] endUndoGrouping];
        [textStorage endEditing];
        newSelectedRange.location+=lengthChange;
        if (!NSEqualRanges(newSelectedRange,[textView selectedRange]) && newSelectedRange.location!=NSNotFound) {
            [textView setSelectedRange:newSelectedRange];
        }
    }
}

- (NSBitmapImageRep *)thumbnailBitmapRepresentation {
    // generate Texts 
    LayoutManager *layoutManager = [LayoutManager new];
    [[self textStorage] addLayoutManager:layoutManager];
    NSRect frame = NSMakeRect(0.,0.,512.,640.);
    NSSize textContainerInset = NSMakeSize(20.,20.);
    NSTextContainer *textContainer = [[NSTextContainer alloc] initWithContainerSize:NSMakeSize(frame.size.width - textContainerInset.width*2,frame.size.height - textContainerInset.height*2)];
    [textContainer setWidthTracksTextView:YES];
    TextView *textView = [[TextView alloc] initWithFrame:frame textContainer:textContainer];
    [textView setTextContainerInset:textContainerInset];
    [textView setMaxSize:[textView frame].size];
    [textView setBackgroundColor:[self documentBackgroundColor]];
    [layoutManager setShowsChangeMarks:YES];
    [layoutManager addTextContainer:textContainer];
    NSRange wholeRange = NSMakeRange(0,[[self textStorage] length]);
    [layoutManager invalidateLayoutForCharacterRange:wholeRange isSoft:NO actualCharacterRange:NULL];
    [textView setNeedsDisplay:YES];
    
//    NSImage *imageContext = [NSImage clearedImageWithSize:frame.size];
//    [imageContext setFlipped:YES];
//    [imageContext lockFocus];
//    [textView drawRect:frame];
//    [imageContext unlockFocus];
    
    
    NSRect rectToCache = [textView frame];
    NSBitmapImageRep *rep = [textView bitmapImageRepForCachingDisplayInRect:rectToCache];
    [textView cacheDisplayInRect:[textView frame] toBitmapImageRep:rep];

//    NSBitmapImageRep *rep = [NSBitmapImageRep imageRepWithData:[imageContext TIFFRepresentation]] ;
    NSPasteboard *pb=[NSPasteboard generalPasteboard];
    [pb declareTypes:[NSArray arrayWithObject:NSTIFFPboardType] owner:self];
    [pb setData:[rep TIFFRepresentation] forType:NSTIFFPboardType];
    [textContainer release];
    [layoutManager release];
    [textView release];
    return rep;
}


@end

#pragma mark -

@implementation PlainTextDocument (PlainTextDocumentScriptingAdditions)

- (void)handleBeginUndoGroupCommand:(NSScriptCommand *)command {
    [[self documentUndoManager] beginUndoGrouping];
}

- (void)handleEndUndoGroupCommand:(NSScriptCommand *)command {
    [[self documentUndoManager] endUndoGrouping];
}


- (void)handleClearChangeMarksCommand:(NSScriptCommand *)command {
    [self clearChangeMarks:self];
}

- (void)handleShowWebPreviewCommand:(NSScriptCommand *)command {
    [self showWebPreview:self];
    if ([[I_webPreviewWindowController window] isVisible]) [self refreshWebPreview:self];
}

- (void)replaceTextInRange:(NSRange)aRange withString:(NSString *)aString {
    // NSLog(@"%s",__FUNCTION__);
    // Check for valid encoding
    if (![aString canBeConvertedToEncoding:[self fileEncoding]]) {
        return;
    }
    
    // Normalize line endings
    NSMutableString *mutableString = [aString mutableCopy];
    [mutableString convertLineEndingsToLineEndingString:[self lineEndingString]];

    NSTextStorage *textStorage = [self textStorage];
    [textStorage replaceCharactersInRange:aRange withString:mutableString];
    if ([mutableString length] > 0) {
        [textStorage addAttributes:[self typingAttributes] 
                             range:NSMakeRange(aRange.location, [mutableString length])];
    }
    
    [mutableString release];
    
    if (I_flags.highlightSyntax) {
        [self highlightSyntaxInRange:NSMakeRange(0, [I_textStorage length])];
    }

}

- (NSNumber *)uniqueID {
    return [NSNumber numberWithUnsignedInt:(unsigned int)self];
}

- (id)objectSpecifier {
    NSScriptClassDescription *containerClassDesc = (NSScriptClassDescription *)[NSScriptClassDescription classDescriptionForClass:[NSApp class]];

    return [[[NSUniqueIDSpecifier alloc] initWithContainerClassDescription:containerClassDesc
                                                        containerSpecifier:nil
                                                                       key:@"orderedDocuments"
                                                                  uniqueID:[self uniqueID]] autorelease];
}

- (NSString *)encoding {
    CFStringEncoding cfEncoding = CFStringConvertNSStringEncodingToEncoding([self fileEncoding]);
    if (cfEncoding != kCFStringEncodingInvalidId) {
        CFStringRef IANAName = CFStringConvertEncodingToIANACharSetName(cfEncoding);
        if (IANAName) {
            return (NSString *)IANAName;
        }
    }
    
    NSScriptCommand *command = [NSScriptCommand currentCommand];
    [command setScriptErrorNumber:1];
    [command setScriptErrorString:@"Couldn't determine encoding of document."];
    return nil;
}

- (void)setEncoding:(NSString *)name {
    //NSLog(@"setting encoding (AppleScript)");
    CFStringEncoding cfEncoding = CFStringConvertIANACharSetNameToEncoding((CFStringRef)name);
    if (cfEncoding != kCFStringEncodingInvalidId) {
        NSStringEncoding encoding = CFStringConvertEncodingToNSStringEncoding(cfEncoding);
        if ([[I_textStorage string] canBeConvertedToEncoding:encoding]) {
            [self setFileEncoding:encoding];
            [self updateChangeCount:NSChangeDone];             
        } else {
            NSScriptCommand *command = [NSScriptCommand currentCommand];
            [command setScriptErrorNumber:2];
            [command setScriptErrorString:@"The text can not be represented in the given encoding."]; 
        }
    } else {
        NSScriptCommand *command = [NSScriptCommand currentCommand];
        [command setScriptErrorNumber:2];
        [command setScriptErrorString:@"Unknown encoding."];        
    }
}

// Deprecated, but needed for compatibility with see tool.
- (NSString *)mode {
    return [[self documentMode] documentModeIdentifier];
}

// Deprecated, but needed for compatibility with see tool and older scripts.
- (void)setMode:(NSString *)identifier {
    DocumentMode *mode = [[DocumentModeManager sharedInstance] documentModeForName:identifier];
    if (mode) {
        [self setDocumentMode:mode];
    } else {
        NSScriptCommand *command = [NSScriptCommand currentCommand];
        [command setScriptErrorNumber:2];
        [command setScriptErrorString:@"Couldn't find specified mode."];    
    }
}

- (AccessOptions)accessOption {
    TCMMMSessionAccessState state = [[self session] accessState];
    if (state == TCMMMSessionAccessLockedState) {
        return kAccessOptionLocked;
    } else if (state == TCMMMSessionAccessReadOnlyState) {
        return kAccessOptionReadOnly;
    } else if (state == TCMMMSessionAccessReadWriteState) {
        return kAccessOptionReadWrite;
    }
    
    return 0;
}

- (void)setAccessOption:(AccessOptions)option {
    TCMMMSession *session = [self session];
    if (![session isServer]) {
        return;    
    }
    
    if (option == kAccessOptionLocked) {
        [session setAccessState:TCMMMSessionAccessLockedState];
    } else if (option == kAccessOptionReadOnly) {
        [session setAccessState:TCMMMSessionAccessReadOnlyState];
    } else if (option == kAccessOptionReadWrite) {
        [session setAccessState:TCMMMSessionAccessReadWriteState];
    } else {
        NSScriptCommand *command = [NSScriptCommand currentCommand];
        [command setScriptErrorNumber:1];
        [command setScriptErrorString:@"Unknown access option."];     
    }
}

- (NSString *)announcementURL {
    if ([self isAnnounced]) {
        return [[self documentURL] absoluteString];
    }
    
    return nil;
}

- (NSString *)scriptedContents
{
    return [I_textStorage string];
}

- (void)setScriptedContents:(id)value {
    [self replaceTextInRange:NSMakeRange(0,[I_textStorage length]) withString:value];
}

- (TextStorage *)scriptedPlainContents {
    return (TextStorage *)I_textStorage;
}

- (void)setScriptedPlainContents:(id)value {
    if ([value isKindOfClass:[NSString class]]) {
        [self replaceTextInRange:NSMakeRange(0, [I_textStorage length]) withString:value];
    }
}

- (id)coerceValueForScriptDocumentMode:(id)value {
    if ([value isKindOfClass:[DocumentMode class]]) {
        return value;
    } else if ([value isKindOfClass:[NSString class]]) {
        DocumentMode *mode = [[DocumentModeManager sharedInstance] documentModeForName:value];
        if (mode) {
            return mode;
        } else {
            NSScriptCommand *command = [NSScriptCommand currentCommand];
            [command setScriptErrorNumber:2];
            [command setScriptErrorString:@"Couldn't find specified mode."];
            return nil;
        }
    } else {
        return [[NSScriptCoercionHandler sharedCoercionHandler] coerceValue:value toClass:[DocumentMode class]];
    }
}

- (void)setScriptDocumentMode:(id)value {
	// because the make new document with properties {} variant doesn't coerce the parameters given correctly in leopard
	id modeValue = [self coerceValue:value forKey:@"scriptDocumentMode"];
	if (modeValue) {
		[self setDocumentMode:modeValue];
	}
}

- (id)scriptDocumentMode {
	return [self documentMode];
}


- (id)scriptSelection {
    if ([self isProxyDocument]) return nil;
    return [[[self topmostWindowController] activePlainTextEditorForDocument:self] scriptSelection];
}

- (void)setScriptSelection:(id)aSelection {
    if ([self isProxyDocument]) return;
    [[[self topmostWindowController] activePlainTextEditorForDocument:self] setScriptSelection:aSelection];
}

- (NSArray *)orderedWindows {
    NSMutableArray *orderedWindows = [NSMutableArray array];
    NSEnumerator *windowsEnumerator = [[NSApp orderedWindows] objectEnumerator];
    NSWindow *window;
    while ((window = [windowsEnumerator nextObject])) {
        if (![self isProxyDocument] &&
            [[window windowController] respondsToSelector:@selector(documents)] &&
            [[[window windowController] documents] containsObject:self]) {
            [orderedWindows addObject:window];
        }
    }
    return orderedWindows;
}

- (NSString *)scriptedWebPreviewBaseURL {
    [self ensureWebPreview];
    return [[I_webPreviewWindowController baseURL] absoluteString];
}

- (void)setScriptedWebPreviewBaseURL:(NSString *)aString {
    [self ensureWebPreview];
    [I_webPreviewWindowController setBaseURL:[NSURL URLWithString:aString]];
    if ([[I_webPreviewWindowController window] isVisible]) [self refreshWebPreview:self];
}

- (void)scriptWrapperWillRunScriptNotification:(NSNotification *)aNotification {
    [[self session] pauseProcessing];
    I_flags.syntaxHighlightingIsSuspended = YES;
}

- (void)scriptWrapperDidRunScriptNotification:(NSNotification *)aNotification {
    I_flags.syntaxHighlightingIsSuspended = NO;
    [[self session] startProcessing];
}

#ifndef TCM_NO_DEBUG

- (void)createThumbnail:(id)aSender {
    NSTextView *myTextView = [[[self topmostWindowController] activePlainTextEditorForDocument:self] textView];
    [myTextView setDrawsBackground:NO];
    NSRect rectToCache = [myTextView frame];
    NSBitmapImageRep *rep = [myTextView bitmapImageRepForCachingDisplayInRect:rectToCache];
    [myTextView cacheDisplayInRect:[myTextView frame] toBitmapImageRep:rep];
    NSPasteboard *pb=[NSPasteboard generalPasteboard];
    [pb declareTypes:[NSArray arrayWithObject:NSTIFFPboardType] owner:self];
    [pb setData:[rep TIFFRepresentation] forType:NSTIFFPboardType];
    [myTextView setDrawsBackground:YES];
}

#endif



@end
