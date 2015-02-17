//
//  PlainTextDocument.m
//  SubEthaEdit
//
//  Created by Martin Ott on Tue Feb 24 2004.
//  Copyright (c) 2004-2007 TheCodingMonkeys. All rights reserved.
// 

#import <SystemConfiguration/SystemConfiguration.h>
#import <objc/objc-runtime.h>			// for objc_msgSend

#import <PSMTabBarControl/PSMTabBarControl.h>
#import "TCMMillionMonkeys/TCMMillionMonkeys.h"
#import "PlainTextEditor.h"
#import "SEEConnectionManager.h"
#import "SEEDocumentController.h"
#import "PlainTextDocument.h"
#import "PlainTextWindowController.h"
#import "PlainTextWindowControllerTabContext.h"
#import "SEEWebPreviewViewController.h"
#import "DocumentProxyWindowController.h"
#import "UndoManager.h"
#import "TCMMMUserSEEAdditions.h"
#import "AppController.h"
#import "SEESavePanelAccessoryViewController.h"
#import "SEEEncodingDoctorDialogViewController.h"
#import "NSMutableAttributedStringSEEAdditions.h"
#import "NSErrorTCMAdditions.h"
#import "FontForwardingTextField.h"
#import "SEEAuthenticatedSaveMissingScriptRecoveryAttempter.h"

#import "DocumentModeManager.h"
#import "DocumentMode.h"
#import "SyntaxHighlighter.h"
#import "SymbolTableEntry.h"

#import "FoldableTextStorage.h"
#import "FullTextStorage.h"
#import "LayoutManager.h"
#import "SEETextView.h"
#import "EncodingManager.h"
#import "TextOperation.h"
#import "SelectionOperation.h"
#import "ODBEditorSuite.h"
#import "GeneralPreferences.h"

#import "FindAllController.h"

#import "MultiPagePrintView.h"
#import "SEEPrintOptionsViewController.h"
#import "SEEScopedBookmarkManager.h"

//#import "MoreUNIX.h"
//#import "MoreSecurity.h"
//#import "MoreCFQ.h"
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

#import "UKXattrMetadataStore.h"

#import <UniversalDetector/UniversalDetector.h>

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
NSString * const PlainTextDocumentDidSaveShouldReloadWebPreviewNotification =
@"PlainTextDocumentDidSaveShouldReloadWebPreviewNotification";
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


@interface PlainTextDocument ()
- (NSView *)printableView;
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

@property (nonatomic, strong) TCMBracketSettings *bracketSettings;
@property (nonatomic, strong) NSSavePanel *currentSavePanel;
@property (nonatomic, strong) NSArray *preservedDataFromSEETextFile;

@end

#pragma mark -

static NSDictionary *plainSymbolAttributes=nil, *italicSymbolAttributes=nil, *boldSymbolAttributes=nil, *boldItalicSymbolAttributes=nil;



@implementation PlainTextDocument

+ (void)initialize {
	if (self == [PlainTextDocument class]) 
	{
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
}

+ (BOOL)canConcurrentlyReadDocumentsOfType:(NSString *)aTypeName {
	return NO;
}

+ (PlainTextDocument *)transientDocument {
#if __has_feature(objc_arc)
#warning transient documents will lead to retain cycles with ARC!
#endif
	return transientDocument;
}

//+ (BOOL)preservesVersions {
//	return YES;
//}

- (void)setFileType:(NSString *)aString {
    [self willChangeValueForKey:@"documentIcon"];
    I_flags.isSEEText = UTTypeConformsTo((CFStringRef)aString, (CFStringRef)kSEETypeSEEText);
    [super setFileType:aString];
    [self didChangeValueForKey:@"documentIcon"];
}

- (NSImage *)documentIcon {
    if (UTTypeConformsTo((CFStringRef)[self fileType], (CFStringRef)kSEETypeSEEText)) {
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
     I_lineEndingString = [NSString lineEndingStringForLineEnding:[(FoldableTextStorage *)[self textStorage] lineEnding]];
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
    [I_boldFont autorelease];
    [I_italicFont autorelease];
    [I_boldItalicFont autorelease];
    NSFontManager *manager=[NSFontManager sharedFontManager];
    I_boldFont       = [[manager convertFont:I_plainFont toHaveTrait:NSBoldFontMask] retain];
    I_italicFont     = [[manager convertFont:I_plainFont toHaveTrait:NSItalicFontMask] retain];
    I_boldItalicFont = [[manager convertFont:I_boldFont  toHaveTrait:NSItalicFontMask] retain];
}

- (void)TCM_initHelper {
	self.persistentDocumentScopedBookmarkURLs = [NSMutableArray array];
    I_flags.isAutosavingForStateRestore=NO;
    I_flags.isHandlingUndoManually=NO;
    I_flags.shouldSelectModeOnSave=YES;
    [self setUndoManager:nil];
    I_rangesToInvalidate = [NSMutableArray new];
    I_findAllControllers = [NSMutableArray new];
    NSNotificationCenter *center=[NSNotificationCenter defaultCenter];
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
    [center addObserver:self selector:@selector(applyStylePreferences:) name:DocumentModeApplyStylePreferencesNotification object:nil];
    [center addObserver:self selector:@selector(applyEditPreferences:) name:DocumentModeApplyEditPreferencesNotification object:nil];
    [center addObserver:self selector:@selector(scriptWrapperWillRunScriptNotification:) name:ScriptWrapperWillRunScriptNotification object:nil];
    [center addObserver:self selector:@selector(scriptWrapperDidRunScriptNotification:) name:ScriptWrapperDidRunScriptNotification object:nil];

	[center addObserver:self selector:@selector(documentModeListChanged:) 
	  name:@"DocumentModeListChanged" object:nil];
	[center addObserver:self selector:@selector(styleSheetsDidChange:)
				   name:@"StyleSheetsDidChange" object:nil];

    I_blockeditTextView=nil;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(TCM_textStorageLineEndingDidChange:) name:TextStorageLineEndingDidChange object:I_textStorage];

	self.bracketSettings = ({
		TCMBracketSettings *settings = [[[TCMBracketSettings alloc] initWithBracketString:@"{[()]}"] autorelease];
		settings.attributeNameToDisregard = kSyntaxHighlightingTypeAttributeName;
		settings.attributeValuesToDisregard = @[kSyntaxHighlightingTypeComment, kSyntaxHighlightingTypeString];
		settings;
	});
	_currentBracketMatchingBracketPosition = NSNotFound;
    I_flags.showMatchingBrackets=YES;
    I_flags.didPauseBecauseOfMarkedText=NO;
    I_flags.hasUTF8BOM = NO;

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

- (void)styleSheetsDidChange:(NSNotification *)aNotification {
	[self applyStylePreferences];
}

- (void)applyStylePreferences {
    [self takeStyleSettingsFromDocumentMode];
	[I_textStorage addAttributes:[self plainTextAttributes]
				   range:I_textStorage.TCM_fullLengthRange];
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
        if ([controller isKindOfClass:[PlainTextWindowController class]] && ![(PlainTextWindowController *)controller hasManyDocuments])
		{
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

    NSString *name = [[self fileURL] path];
    if (name == nil || [name length] == 0)
        return;

//    OSErr err;
    NSURL *fileURL = [NSURL fileURLWithPath:name];
	NSData *fileURLBookmarkData = [fileURL bookmarkDataWithOptions:NSURLBookmarkCreationSuitableForBookmarkFile includingResourceValuesForKeys:nil relativeToURL:nil error:nil];
//    FSRef fileRef;
//    CFURLGetFSRef((CFURLRef)fileURL, &fileRef);
//    FSSpec fsSpec;
//    err = FSGetCatalogInfo(&fileRef, kFSCatInfoNone, NULL, NULL, &fsSpec, NULL);
//    if (err == noErr) {
	if (fileURLBookmarkData) {
        NSData *signatureData = [[self ODBParameters] objectForKey:@"keyFileSender"];
        if (signatureData != nil) {
            NSAppleEventDescriptor *addressDescriptor = [NSAppleEventDescriptor descriptorWithDescriptorType:typeApplSignature bytes:[signatureData bytes] length:[signatureData length]];
            if (addressDescriptor != nil) {
                NSAppleEventDescriptor *appleEvent = [NSAppleEventDescriptor appleEventWithEventClass:kODBEditorSuite eventID:kAEClosedFile targetDescriptor:addressDescriptor returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID];
				NSAppleEventDescriptor *aliasDescriptor = [NSAppleEventDescriptor descriptorWithDescriptorType:typeBookmarkData bytes:&fileURLBookmarkData length:sizeof(fileURLBookmarkData)];
//#if defined(__LP64__)
//				NSAppleEventDescriptor *aliasDescriptor = [NSAppleEventDescriptor descriptorWithDescriptorType:typeFSRef bytes:&fileRef length:sizeof(fileRef)];
//#else
//				NSAppleEventDescriptor *aliasDescriptor = [NSAppleEventDescriptor descriptorWithDescriptorType:typeFSS bytes:&fsSpec length:sizeof(fsSpec)];
//#endif //defined(__LP64__)
                [appleEvent setParamDescriptor:aliasDescriptor forKeyword:keyDirectObject];
                NSAppleEventDescriptor *tokenDesc = [[self ODBParameters] objectForKey:@"keyFileSenderToken"];
                if (tokenDesc != nil) {
                    [appleEvent setParamDescriptor:tokenDesc forKeyword:keySenderToken];
                }
                if (appleEvent != nil) {
                    DEBUGLOG(@"FileIOLogDomain", DetailedLogLevel, @"Sending apple event");
                    AppleEvent reply;
                    //err = 
                    AESendMessage ([appleEvent aeDesc], &reply, kAENoReply, kAEDefaultTimeout);
                }
            }
        }
    }
}

- (void)TCM_sendODBModifiedEvent {
//    OSErr err;
    DEBUGLOG(@"FileIOLogDomain", DetailedLogLevel, @"preparing ODB modified event");
    DEBUGLOG(@"FileIOLogDomain", DetailedLogLevel, @"ODBParameters: %@", [[self ODBParameters] description]);
    if ([self ODBParameters] == nil || [[self ODBParameters] count] == 0)
        return;

    NSString *fileName = [[self fileURL] path];
    if (fileName == nil || [fileName length] == 0)
        return;


    NSURL *fileURL = [NSURL fileURLWithPath:fileName];
	NSData *fileURLBookmarkData = [fileURL bookmarkDataWithOptions:NSURLBookmarkCreationSuitableForBookmarkFile includingResourceValuesForKeys:nil relativeToURL:nil error:nil];
//    FSRef fileRef;
//    CFURLGetFSRef((CFURLRef)fileURL, &fileRef);
//    FSSpec fsSpec;
//    err = FSGetCatalogInfo(&fileRef, kFSCatInfoNone, NULL, NULL, &fsSpec, NULL);
    NSAppleEventDescriptor *directObjectDesc = nil;
//    if (err == noErr) {
//#if defined(__LP64__)
//		directObjectDesc = [NSAppleEventDescriptor descriptorWithDescriptorType:typeFSRef bytes:&fileRef length:sizeof(fileRef)];
//#else
//		directObjectDesc = [NSAppleEventDescriptor descriptorWithDescriptorType:typeFSS bytes:&fsSpec length:sizeof(fsSpec)];
//#endif //defined(__LP64__)
//    } else {
//        DEBUGLOG(@"FileIOLogDomain", DetailedLogLevel, @"Failed to create fsspec");
//        return;
//    }

	if (fileURLBookmarkData) {
		directObjectDesc = [NSAppleEventDescriptor descriptorWithDescriptorType:typeBookmarkData bytes:&fileURLBookmarkData length:sizeof(fileURLBookmarkData)];
	} else {
        DEBUGLOG(@"FileIOLogDomain", DetailedLogLevel, @"Failed to create URL Bookmark data");
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
                    //err = 
                    AESendMessage ([appleEvent aeDesc], &reply, kAENoReply, kAEDefaultTimeout);
                }
            }
        }
    } else {
        DEBUGLOG(@"FileIOLogDomain", DetailedLogLevel, @"Unable to generate direct parameter.");
    }
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

- (void)executeInvalidateLayout:(NSNotification *)aNotification {
    FoldableTextStorage *textStorage=(FoldableTextStorage *)[self textStorage];
    NSRange wholeRange=NSMakeRange(0,[textStorage length]);
    NSValue *rangeValue=nil;
    [textStorage beginEditing];
    for (rangeValue in I_rangesToInvalidate) {
    	NSRange changeRange=[textStorage foldedRangeForFullRange:[rangeValue rangeValue]];
        changeRange=NSIntersectionRange(wholeRange,changeRange);
        if (changeRange.length!=0) {
            [textStorage edited:NSTextStorageEditedAttributes range:changeRange changeInLength:0];
        }
    }
    [textStorage endEditing];
    [I_rangesToInvalidate removeAllObjects];
	// update bottom status bars as this might change the width if wrap is of
	if (!self.wrapLines) {
		[[self plainTextEditors] makeObjectsPerformSelector:@selector(TCM_updateBottomStatusBar)];
	}
}

// this is invalidating textRanges for the fullTextStorage
- (void)invalidateLayoutForRange:(NSRange)aRange {
    FoldableTextStorage *textStorage=(FoldableTextStorage *)[self textStorage];
    NSRange wholeRange=NSMakeRange(0,[[textStorage fullTextStorage] length]);
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
               postingStyle:NSPostWhenIdle
               coalesceMask:NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender
                   forModes:[NSArray arrayWithObject:NSDefaultRunLoopMode]];
}

- (void)updateSymbolTable {

    DocumentMode *mode=[self documentMode];
    [I_symbolArray release];
    I_symbolArray=nil;
    if ([mode hasSymbols]) {
        I_symbolArray = [[mode symbolArrayForTextStorage:[(FoldableTextStorage *)[self textStorage] fullTextStorage]] copy];
		
		// If symbolArrayForTextStorage: return nil the document is not yet ready for symbol recognition.
		if (!I_symbolArray) {
			[self performSelector:@selector(triggerUpdateSymbolTableTimer) withObject:nil afterDelay:0.1];
			return;
		}
		
		
        [I_symbolPopUpMenu release];
        I_symbolPopUpMenu = [NSMenu new];
        [I_symbolPopUpMenuSorted release];
        I_symbolPopUpMenuSorted = [NSMenu new];

        NSMenuItem *prototypeMenuItem=[[NSMenuItem alloc] initWithTitle:@""
                                                                 action:@selector(chooseGotoSymbolMenuItem:)
                                                          keyEquivalent:@""];
        [prototypeMenuItem setTarget:nil];
        NSMutableArray *itemsToSort=[NSMutableArray array];

        SymbolTableEntry *entry;
        int i=0;
        NSMenuItem *menuItem;
        for (entry in I_symbolArray) {
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
        for (menuItem in itemsToSort) {
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

// range is in fulltextstorage
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
        SEETextView *textView=[aMenuItem representedObject];
        PlainTextEditor *editor = [textView editor];
		[editor selectRange:symbolRange];
		[editor setFollowUserID:nil];
		
    } else {
        NSBeep();
    }
}

- (void)TCM_highlightBracketAtPosition:(unsigned)aPosition inTextView:(NSTextView *)aTextView {
    static NSDictionary *mBracketAttributes=nil;
    if (!mBracketAttributes) mBracketAttributes=[[NSDictionary dictionaryWithObject:[[NSColor redColor] highlightWithLevel:0.3]
                                                    forKey:NSBackgroundColorAttributeName] retain];
	NSTextStorage *textStorage = [[self textStorage] fullTextStorage];
    NSUInteger matchingBracketPosition=[textStorage TCM_positionOfMatchingBracketToPosition:aPosition bracketSettings:self.bracketSettings];
    if (matchingBracketPosition!=NSNotFound) {
		NSRange highlightRange = NSMakeRange(matchingBracketPosition, 1);
		highlightRange = [self.textStorage foldedRangeForFullRange:highlightRange];
		[aTextView showFindIndicatorForRange:highlightRange];
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

		if ([[SEEDocumentController sharedInstance] isOpeningUntitledDocument]) {
			
			PlainTextWindowController *windowController = transientDocument.windowControllers.firstObject;
			windowController.window.restorable = YES;

			transientDocument = nil;
			transientDocumentWindowFrame = NSZeroRect;
		}
		
        [self TCM_generateNewSession];
        I_textStorage = [FoldableTextStorage new];
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
    }
    return self;
}

- (id)initWithSession:(TCMMMSession *)aSession {
    self = [super init];
    if (self) {
        [self setShouldChangeChangeCount:NO];
        [self setSession:aSession];
        [[TCMMMPresenceManager sharedInstance] registerSession:[self session]];
        I_textStorage = [FoldableTextStorage new];
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
	if (transientDocument == self) {
		transientDocument = nil;
		transientDocumentWindowFrame = NSZeroRect;
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
    self.preservedDataFromSEETextFile = nil;

    [I_symbolUpdateTimer release];
    [I_webPreviewDelayedRefreshTimer release];

    [[TCMMMPresenceManager sharedInstance] unregisterSession:[self session]];
    [I_textStorage setDelegate:nil];
    [I_textStorage release];
    [I_documentProxyWindowController release];
    [I_session release];
    [I_plainTextAttributes release];
    [I_typingAttributes release];
	[I_blockeditAttributes release];
    [I_plainFont release];
    [I_boldFont release];
    [I_italicFont release];
    [I_boldItalicFont release];
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

	self.O_exportSheet = nil;
	self.O_exportSheetController = nil;

    [I_documentMode release];
    [I_documentBackgroundColor release];
    [I_documentForegroundColor release];
    [I_printOptions autorelease];
    [I_scheduledAlertDictionary release];

	self.currentSavePanel = nil;

    [I_currentTextOperation release];
    
    [I_stateDictionaryFromLoading release];
     I_stateDictionaryFromLoading = nil;
    
    [I_lastTextShouldChangeReplacementString release];
     I_lastTextShouldChangeReplacementString = nil;
//    NSLog(@"%s",__FUNCTION__);
	
	self.bracketSettings = nil;
	
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
    NSUInteger minIndex = NSNotFound;
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


#pragma mark - Encoding

- (BOOL)canBeConvertedToEncoding:(NSStringEncoding)encoding
{
    return [[[I_textStorage fullTextStorage] string] canBeConvertedToEncoding:encoding];
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

- (FoldableTextStorage *)textStorage {
    return I_textStorage;
}

- (void)fillScriptsIntoContextMenu:(NSMenu *)aMenu {
    NSArray *itemArray = [[self documentMode] contextMenuItemArray];
    BOOL addSeparator = NO;
    if ([itemArray count]) {
        NSMenuItem   *menuItem = nil;
        for (menuItem in itemArray) {
            NSMenuItem *item=[menuItem autoreleasedCopy];
            [aMenu addItem:item];
        }
        addSeparator = YES;
    }
    itemArray = [[AppController sharedInstance] contextMenuItemArray];
    if ([itemArray count]) {
    	if (addSeparator) {
    		[aMenu addItem:[NSMenuItem separatorItem]];
    	}
        NSMenuItem   *menuItem = nil;
        for (menuItem in itemArray) {
            NSMenuItem *item=[menuItem autoreleasedCopy];
            [aMenu addItem:item];
        }
    }
}

- (void)adjustModeMenu {
	if (![NSThread isMainThread]) {
		[self performSelectorOnMainThread:@selector(adjustModeMenu) withObject:nil waitUntilDone:NO];
	} else {
		NSMenu *modeMenu=[[[NSApp mainMenu] itemWithTag:ModeMenuTag] submenu];
		// remove all items that don't belong here anymore
		int index = [modeMenu indexOfItemWithTag:ReloadModesMenuItemTag];
		index+=1; 
		while (index < [modeMenu numberOfItems]) {
			[modeMenu removeItemAtIndex:index];
		}
		// check if mode has items
		NSArray *itemArray = [[self documentMode] scriptMenuItemArray];
		if ([itemArray count]) {
			[modeMenu addItem:[NSMenuItem separatorItem]];
			NSMenuItem   *menuItem = nil;
			NSImage *scriptMenuItemIcon=[NSImage imageNamed:@"ScriptMenuItemIcon"];
			for (menuItem in itemArray) {
				NSMenuItem *item=[menuItem autoreleasedCopy];
				[item setImage:scriptMenuItemIcon];
				[modeMenu addItem:item];
				[item setKeyEquivalent:[menuItem keyEquivalent]];
				[item setKeyEquivalentModifierMask:[menuItem keyEquivalentModifierMask]];
			}
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
    NSUInteger lineEndIndex, contentsEndIndex;
    [string getLineStart:NULL end:&lineEndIndex contentsEnd:&contentsEndIndex forRange:NSMakeRange(0, 0)];
    if (lineEndIndex == contentsEndIndex) {
        [self setLineEnding:[[documentMode defaultForKey:DocumentModeLineEndingPreferenceKey] intValue]];
    }
    
    NSNumber *aFlag=[[documentMode defaults] objectForKey:DocumentModeShowBottomStatusBarPreferenceKey];
    [self setShowsBottomStatusBar:!aFlag || [aFlag boolValue]];
    aFlag=[[documentMode defaults] objectForKey:DocumentModeShowTopStatusBarPreferenceKey];
    [self setShowsTopStatusBar:!aFlag || [aFlag boolValue]];

	[self.bracketSettings setBracketString:documentMode.bracketMatchingBracketString];
	
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
        FullTextStorage *fullTextStorage = [I_textStorage fullTextStorage];
        [highlighter cleanUpTextStorage:fullTextStorage];
         I_documentMode = [aDocumentMode retain];
        [self takeSettingsFromDocumentMode];
        [fullTextStorage addAttributes:[self plainTextAttributes]
                                   range:NSMakeRange(0,[fullTextStorage length])];
        if (I_flags.highlightSyntax) {
            [self highlightSyntaxInRange:NSMakeRange(0,[fullTextStorage length])];
        }
        [self setContinuousSpellCheckingEnabled:[[aDocumentMode defaultForKey:DocumentModeSpellCheckingPreferenceKey] boolValue]];
        [self updateSymbolTable];
        if (I_flags.shouldChangeExtensionOnModeChange) {
            NSArray *recognizedExtensions = [I_documentMode recognizedExtensions];
            if ([recognizedExtensions count]) {
				NSString *fileExtension = recognizedExtensions.firstObject;
				if (fileExtension) {
					NSString *fileType = (NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (CFStringRef)fileExtension, nil);
					self.fileType = [fileType autorelease];
				} else {
					self.fileType = (NSString *)kUTTypeText;
				}

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
		[self invalidateRestorableState];
    }
}

- (void)documentModeListChanged:(NSNotification *)aNotification {
	DocumentMode *oldMode = [self documentMode];
	DocumentMode *newMode = [[DocumentModeManager sharedInstance] documentModeForIdentifier:[oldMode documentModeIdentifier]];
	// just set the document mode - if the object hasn't changed the setter takes care of it
	[self setDocumentMode:newMode];
}

- (NSMutableDictionary *)printOptions {
    return I_printOptions;
}

- (void)setPrintOptions:(NSMutableDictionary *)aPrintOptions {
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

- (IBAction)changeFont:(id)aSender {
    NSFont *newFont = [aSender convertFont:I_plainFont];
    [self setPlainFont:newFont];
	[self invalidateRestorableState];
}
    
    
- (NSStringEncoding)fileEncoding {
    return [(FoldableTextStorage *)[self textStorage] encoding];
}

- (void)setFileEncoding:(NSStringEncoding)anEncoding {
    [(FoldableTextStorage *)[self textStorage] setEncoding:anEncoding];
    [self TCM_sendPlainTextDocumentDidChangeEditStatusNotification];
	[self invalidateRestorableState];
}

- (void)setFileEncodingUndoable:(NSUInteger)anEncoding {
    [[[self documentUndoManager] prepareWithInvocationTarget:self] 
        setFileEncodingUndoable:[self fileEncoding]];
    [self setFileEncoding:anEncoding];
	[self invalidateRestorableState];
}

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

    [[self plainTextEditors] makeObjectsPerformSelector:@selector(updateViews)];
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
	[self invalidateRestorableState];
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
                [[self topmostWindowController] openParticipantsOverlayForDocument:self];
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
                if ([session participantCount] <= 1 && [[session pendingUsers] count] == 0 && [self.session openInvitationCount] == 0) {
                    [[self windowControllers] makeObjectsPerformSelector:@selector(closeParticipantsOverlay:) withObject:self];
                }
            }
			[[self plainTextEditors] makeObjectsPerformSelector:@selector(updateViews)];
        }
        // needed for updating of the lock
        [[self windowControllers] makeObjectsPerformSelector:@selector(synchronizeWindowTitleWithDocumentName)];

    }
}

- (IBAction)toggleIsAnnounced:(id)aSender {
	if (self.session.isServer) {
		if (!self.isAnnounced &&
			[TCMMMPresenceManager sharedInstance].isCurrentlyReallyInvisible) {
			NSAlert *alert = [[[NSAlert alloc] init] autorelease];
			[alert setAlertStyle:NSWarningAlertStyle];
			[alert setMessageText:NSLocalizedString(@"ANNOUNCE_WILL_MAKE_VISIBLE_MESSAGE", nil)];
			[alert setInformativeText:NSLocalizedString(@"ANNOUNCE_WILL_MAKE_VISIBLE_INFORMATIVE_TEXT", nil)];
			[alert addButtonWithTitle:NSLocalizedString(@"ANNOUNCE_WILL_MAKE_VISIBLE_ACTION_TITLE", nil)];
			[alert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
			[self presentAlert:alert
				 modalDelegate:self
				didEndSelector:@selector(announceAndBecomeVisibleAlertDidEnd:returnCode:contextInfo:)
				   contextInfo:nil];
			if ([aSender isKindOfClass:[NSButton class]]) { // toggle back the state of the button if it was a button
				[aSender setState:[aSender state] == NSOnState ? NSOffState : NSOnState];
			}
		} else {
			[self setIsAnnounced:![self isAnnounced]];
		}
	}
}

- (void)announceAndBecomeVisibleAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	if (returnCode == NSAlertFirstButtonReturn) {
		[self setIsAnnounced:YES];
	}
}

- (IBAction)toggleIsAnnouncedOnAllDocuments:(id)aSender {
    BOOL targetSetting = ![self isAnnounced];
    NSEnumerator *documents = [[[SEEDocumentController sharedInstance] documents] objectEnumerator];
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
    NSEnumerator *documents = [[[SEEDocumentController sharedInstance] documents] objectEnumerator];
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

- (void)setContentUsingXMLDocument:(NSXMLDocument *)inDocument {
	NSString *xmlString = [inDocument XMLStringWithOptions:NSXMLNodePrettyPrint|NSXMLNodePreserveEmptyElements];
	if ([self tabWidth] != 4 || [self usesTabs]) {
		OGRegularExpression *spaceMatch = [OGRegularExpression regularExpressionWithString:@"^((    )+)<"];
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
}

- (IBAction)prettyPrintXML:(id)aSender {
    NSError *error=nil;
    NSXMLDocument *document = [[[NSXMLDocument alloc] initWithXMLString:[[(FoldableTextStorage *)[self textStorage] fullTextStorage] string] options:NSXMLNodePreserveEmptyElements|NSXMLNodePreserveCDATA error:&error] autorelease];
    if (document) {
    	[self setContentUsingXMLDocument:document];
    } else {
        [self presentError:(NSError *)error modalForWindow:[self windowForSheet] delegate:nil didPresentSelector:NULL contextInfo:nil];
    }
}

- (IBAction)prettyPrintHTML:(id)aSender {
    NSError *error=nil;
    NSXMLDocument *document = [[[NSXMLDocument alloc] initWithXMLString:[[(FoldableTextStorage *)[self textStorage] fullTextStorage] string] options:NSXMLDocumentTidyHTML|NSXMLNodePreserveEmptyElements|NSXMLNodePreserveAttributeOrder|NSXMLNodePreserveEntities error:&error] autorelease];
    if (document) {
    	[self setContentUsingXMLDocument:document];
    } else {
        [self presentError:(NSError *)error modalForWindow:[self windowForSheet] delegate:nil didPresentSelector:NULL contextInfo:nil];
    }
}

- (IBAction)newView:(id)aSender {
    if (!I_flags.isReceivingContent && [[self windowControllers] count] > 0) {
        PlainTextWindowController *controller = [[PlainTextWindowController alloc] init];
        [[SEEDocumentController sharedInstance] addWindowController:controller];
        [self addWindowController:controller];
        [controller showWindow:aSender];
        [controller release];
        [self TCM_sendPlainTextDocumentDidChangeDisplayNameNotification];
    }
}

- (NSUndoManager *)TCM_undoManagerToUse {
	NSUndoManager *result = (NSUndoManager *)self.documentUndoManager;
	id myTextView = [[self activePlainTextEditor] textView];
	id firstResponder = [[myTextView window] firstResponder];
	if ( myTextView && firstResponder &&
		[firstResponder isKindOfClass:[NSTextView class]] &&
		![firstResponder isKindOfClass:[myTextView class]]) {
		result = [firstResponder undoManager];
	}
	return result;
}

- (IBAction)undo:(id)aSender {
	[[self TCM_undoManagerToUse] undo];
}

- (IBAction)redo:(id)aSender {
	[[self TCM_undoManagerToUse] redo];
}

- (IBAction)clearChangeMarks:(id)aSender {
    NSTextStorage *textStorage=[(FoldableTextStorage *)[self textStorage] fullTextStorage];
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

    DEBUGLOG(@"FileIOLogDomain", DetailedLogLevel, @"%@",[NSString localizedNameOfStringEncoding:encoding]);

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
                                                [NSNumber numberWithUnsignedInteger:encoding], @"Encoding",
                                                nil] retain]];
    }
}

- (void)selectEncodingAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    NSDictionary *alertContext = (NSDictionary *)contextInfo;
    DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel, @"alertDidEnd: %@", [alertContext objectForKey:@"Alert"]);

    TCMMMSession *session=[self session];
    if (!I_flags.isReceivingContent && [session isServer] && [session participantCount]<=1) {
        NSStringEncoding encoding = [[alertContext objectForKey:@"Encoding"] unsignedIntegerValue];
        if (returnCode == NSAlertFirstButtonReturn) { // convert
            DEBUGLOG(@"FileIOLogDomain", DetailedLogLevel, @"Trying to convert file encoding");
            [[alert window] orderOut:self];
            if (![[[I_textStorage fullTextStorage] string] canBeConvertedToEncoding:encoding]) {
                [[self topmostWindowController] setDocumentDialog:[[[SEEEncodingDoctorDialogViewController alloc] initWithEncoding:encoding] autorelease]];
            
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
            NSData *stringData = [[[I_textStorage fullTextStorage] string] dataUsingEncoding:[self fileEncoding]];
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
            NSString *reinterpretedString = [[[NSString alloc] initWithData:stringData encoding:encoding] autorelease];
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

				if (!isEdited)
				{
                    [I_textStorage setAttributes:[self plainTextAttributes] range:NSMakeRange(0, [I_textStorage length])];
                } else {
                    [I_textStorage setAttributes:[self typingAttributes] range:NSMakeRange(0, [I_textStorage length])];
                }
                if (I_flags.highlightSyntax) {
                    [self highlightSyntaxInRange:NSMakeRange(0, [[I_textStorage fullTextStorage] length])];
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


#pragma mark - Restorable State

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
	[super encodeRestorableStateWithCoder:coder];

	// saving doument display name if document is not saved yet
	if (self.fileURL == nil) {
		[coder encodeObject:super.displayName forKey:@"SEEPlainTextDocumentDisplayName"]; // need to encode super.display name because self.displayname has sideeffects
		[coder encodeObject:self.temporaryDisplayName forKey:@"SEEPlainTextDocumentTemporaryDisplayName"];
	}

	[coder encodeBool:I_flags.shouldChangeExtensionOnModeChange forKey:@"SEEPlainTextDocumentShouldUpdateExtensionOnModeChange"];

	// store document mode.
	DocumentMode *documentMode = self.documentMode;
	if (documentMode) {
		NSString *documentModeIdentifier = documentMode.documentModeIdentifier;
		[coder encodeObject:documentModeIdentifier forKey:@"SEEPlainTextDocumentSelectedModeIdentifier"];
	}

	NSStringEncoding documentEncoding = self.fileEncoding;
	[coder encodeObject:@(documentEncoding) forKey:@"SEEPlainTextDocumentFileEncoding"];

	[coder encodeBool:self.usesTabs forKey:@"SEEPlainTextDocumentUsesTabs"];
	[coder encodeBool:self.wrapMode forKey:@"SEEPlainTextDocumentWrapMode"];
	[coder encodeBool:self.wrapLines forKey:@"SEEPlainTextDocumentWrapLines"];
	[coder encodeBool:self.showsGutter forKey:@"SEEPlainTextDocumentShowsGutter"];
	[coder encodeBool:self.showInvisibleCharacters forKey:@"SEEPlainTextDocumentShowInvisibleCharacters"];
	[coder encodeBool:self.showsChangeMarks forKey:@"SEEPlainTextDocumentShowsChangeMarks"];
	[coder encodeBool:self.isContinuousSpellCheckingEnabled forKey:@"SEEPlainTextDocumentContinuousSpellCheckingEnabled"];
//	[coder encodeBool:self.showsTopStatusBar forKey:@"SEEPlainTextDocumentShowsTopStatusBar"];
//	[coder encodeBool:self.showsBottomStatusBar forKey:@"SEEPlainTextDocumentShowsBottomStatusBar"];

	[coder encodeObject:I_plainFont.fontDescriptor.fontAttributes forKey:@"SEEPlainTextDocumentPlainFont"];
}

- (void)restoreStateWithCoder:(NSCoder *)coder {
	[super restoreStateWithCoder:coder];

	// needs to be restored first, because setting the mode will update filetype if this is true.
	I_flags.shouldChangeExtensionOnModeChange = [coder decodeBoolForKey:@"SEEPlainTextDocumentShouldUpdateExtensionOnModeChange"];

	// restoring document mode
	NSString *documentModeIdentifier = [coder decodeObjectForKey:@"SEEPlainTextDocumentSelectedModeIdentifier"];
	if (documentModeIdentifier) {
		DocumentMode *documentMode = [[DocumentModeManager sharedInstance] documentModeForIdentifier:documentModeIdentifier];
		self.documentMode = documentMode;
	}
	
	// restore document string encoding
	NSStringEncoding documentEncoding = [[coder decodeObjectForKey:@"SEEPlainTextDocumentFileEncoding"] unsignedIntegerValue];
	self.fileEncoding = documentEncoding;

	// restoring untitled document name
	if (self.fileURL == nil) {
		super.displayName = [coder decodeObjectForKey:@"SEEPlainTextDocumentDisplayName"]; // need to decode super.display name because self.displayname has sideeffects
		self.temporaryDisplayName = [coder decodeObjectForKey:@"SEEPlainTextDocumentTemporaryDisplayName"];
	}

	if ([coder containsValueForKey:@"SEEPlainTextDocumentUsesTabs"])
		self.usesTabs = [coder decodeBoolForKey:@"SEEPlainTextDocumentUsesTabs"];
	if ([coder containsValueForKey:@"SEEPlainTextDocumentWrapMode"])
		self.wrapMode = [coder decodeBoolForKey:@"SEEPlainTextDocumentWrapMode"];
	if ([coder containsValueForKey:@"SEEPlainTextDocumentWrapLines"])
		self.wrapLines = [coder decodeBoolForKey:@"SEEPlainTextDocumentWrapLines"];
	if ([coder containsValueForKey:@"SEEPlainTextDocumentShowsGutter"])
		self.showsGutter = [coder decodeBoolForKey:@"SEEPlainTextDocumentShowsGutter"];
	if ([coder containsValueForKey:@"SEEPlainTextDocumentShowInvisibleCharacters"])
		self.showInvisibleCharacters = [coder decodeBoolForKey:@"SEEPlainTextDocumentShowInvisibleCharacters"];
	if ([coder containsValueForKey:@"SEEPlainTextDocumentShowsChangeMarks"])
		self.showsChangeMarks = [coder decodeBoolForKey:@"SEEPlainTextDocumentShowsChangeMarks"];
	if ([coder containsValueForKey:@"SEEPlainTextDocumentContinuousSpellCheckingEnabled"])
		self.continuousSpellCheckingEnabled = [coder decodeBoolForKey:@"SEEPlainTextDocumentContinuousSpellCheckingEnabled"];
//	if ([coder containsValueForKey:@"SEEPlainTextDocumentShowsTopStatusBar"])
//		self.showsTopStatusBar = [coder decodeBoolForKey:@"SEEPlainTextDocumentShowsTopStatusBar"];
//	if ([coder containsValueForKey:@"SEEPlainTextDocumentShowsBottomStatusBar"])
//		self.showsBottomStatusBar = [coder decodeBoolForKey:@"SEEPlainTextDocumentShowsBottomStatusBar"];

	if ([coder containsValueForKey:@"SEEPlainTextDocumentPlainFont"]) {
		NSDictionary *fontAttributes = [coder decodeObjectForKey:@"SEEPlainTextDocumentPlainFont"];
		NSFontDescriptor *fontDescriptor = [NSFontDescriptor fontDescriptorWithFontAttributes:fontAttributes];
		NSFont *font = [NSFont fontWithDescriptor:fontDescriptor size:0.0];
		[self setPlainFont:font];
	}

	[[self windowControllers] makeObjectsPerformSelector:@selector(takeSettingsFromDocument)];
}


#pragma mark - Overrides of NSDocument Methods to Support MultiDocument Windows

static BOOL PlainTextDocumentIgnoreRemoveWindowController = NO;

- (void)makeWindowControllers {
    BOOL shouldOpenInTab = NO;
	NSWindowController *tabWindowController = nil;

	SEEDocumentCreationFlags *creationFlags = self.attachedCreationFlags;
	if (creationFlags) {
		shouldOpenInTab = creationFlags.openInTab;
		if (creationFlags.isAlternateAction) {
			shouldOpenInTab = !shouldOpenInTab;
		}
	} else {
		shouldOpenInTab = [[NSUserDefaults standardUserDefaults] boolForKey:kSEEDefaultsKeyOpenNewDocumentInTab];
	}

	if (shouldOpenInTab) {
		tabWindowController = creationFlags.tabWindow.windowController;
		if (!tabWindowController) {
			tabWindowController = [[SEEDocumentController sharedDocumentController] activeWindowController];
		}
	}

	BOOL closeTransientDocument = transientDocument && transientDocument != self
	&& NSEqualRects(transientDocumentWindowFrame, [[[transientDocument topmostWindowController] window] frame])
	&& [[[NSUserDefaults standardUserDefaults] objectForKey:OpenUntitledDocumentOnStartupPreferenceKey] boolValue];
	
	PlainTextWindowController *windowController = nil;
    if (shouldOpenInTab) {
        windowController = (PlainTextWindowController *)tabWindowController;
        [self addWindowController:windowController];
        [[windowController tabBar] setHideForSingleTab:![[NSUserDefaults standardUserDefaults] boolForKey:kSEEDefaultsKeyAlwaysShowTabBar]];
		
		if (closeTransientDocument && ![self isProxyDocument]) {
			[transientDocument close];
			transientDocument = nil;
			transientDocumentWindowFrame = NSZeroRect;
			
			PlainTextWindowController *windowController = self.windowControllers.firstObject;
			windowController.window.restorable = YES;
		}

    } else {
        windowController = [[PlainTextWindowController alloc] init];
        [self addWindowController:windowController];
        [[SEEDocumentController sharedInstance] addWindowController:windowController];
        [windowController release];
    }

	// reset document creation flags
	self.attachedCreationFlags = nil;
    
	if (I_stateDictionaryFromLoading) {
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		if ([defaults boolForKey:DocumentStateSaveAndLoadWindowPositionKey]) {
			if (![windowController hasManyDocuments]) {
				NSDictionary *windowFrameDict = [I_stateDictionaryFromLoading objectForKey:@"p"];
				if ([windowFrameDict isKindOfClass:[NSDictionary class]]) {
					NSRect windowFrameRect = NSZeroRect;
					windowFrameRect.origin.x = [[windowFrameDict objectForKey:@"x"] doubleValue];
					windowFrameRect.origin.y = [[windowFrameDict objectForKey:@"y"] doubleValue];
					windowFrameRect.size.height = [[windowFrameDict objectForKey:@"h"] doubleValue];
					windowFrameRect.size.width  = [[windowFrameDict objectForKey:@"w"] doubleValue];
					NSSize minSize = [[windowController window] minSize];
					if (windowFrameRect.size.height >= minSize.height && windowFrameRect.size.width >= minSize.width) {
						[windowController setWindowFrame:windowFrameRect constrainedToScreen:nil display:YES];
					}
					
					if (closeTransientDocument && ![self isProxyDocument]) {
						[transientDocument close];
						transientDocument = nil;
						transientDocumentWindowFrame = NSZeroRect;
						
						PlainTextWindowController *windowController = self.windowControllers.firstObject;
						windowController.window.restorable = YES;
					}
				}
			}
		}
		
		if ([defaults boolForKey:DocumentStateSaveAndLoadSelectionKey]) {
			NSDictionary *selectionDict = [I_stateDictionaryFromLoading objectForKey:@"s"];
			if ([selectionDict isKindOfClass:[NSDictionary class]]) {
				NSRange selectionRange = NSMakeRange([[selectionDict objectForKey:@"p"] intValue],[[selectionDict objectForKey:@"l"] intValue]);
				[[self activePlainTextEditor] selectRangeInBackgroundWithoutIndication:selectionRange expandIfFolded:NO];
			}
		}
       	
    	[I_stateDictionaryFromLoading release];
    	 I_stateDictionaryFromLoading = nil;
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

- (void)setKeepUndoManagerOnZeroWindowControllers:(BOOL)aFlag {
	I_flags.keepUndoManagerOnZeroWindowControllers = aFlag;
}
- (BOOL)keepUndoManagerOnZeroWindowControllers {
	return I_flags.keepUndoManagerOnZeroWindowControllers;
}

- (void)removeWindowController:(NSWindowController *)windowController
{
    if (!PlainTextDocumentIgnoreRemoveWindowController) {
        [super removeWindowController:windowController];
    }

    if ([[self windowControllers] count] != 0) {
        // if doing always, we delay the dealloc method ad inifitum on quit
        [self TCM_sendPlainTextDocumentDidChangeDisplayNameNotification];
    } else if (!I_flags.keepUndoManagerOnZeroWindowControllers) {
    	// let us release our undo manager to break that retain cycle caused by the invocations retaining us
    	[I_undoManager release];
    	I_undoManager = nil;
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
    for (NSWindowController *windowController in windowControllers) {
        [(PlainTextWindowController *)windowController documentWillClose:self];
    }
	
	for (FindAllController *findAllController in [[I_findAllControllers copy] autorelease]) {
		[findAllController close];
	}
    [I_findAllControllers removeAllObjects];

	if (I_documentProxyWindowController) {
		[self proxyWindowWillClose];
	}

    // terminate syntax coloring
    I_flags.highlightSyntax = NO;
    [I_symbolUpdateTimer invalidate];
    [I_webPreviewDelayedRefreshTimer invalidate];
    [self TCM_sendODBCloseEvent];

    // Do the regular NSDocument thing.
    if (!I_flags.isPreparedForTermination) {
        [super close];
    }
}


#pragma mark - Proxy Window

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
        [[SEEDocumentController sharedInstance] removeDocument:[[self retain] autorelease]];

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


#pragma mark -

- (void)TCM_validateLineEndings {
    DEBUGLOG(@"FileIOLogDomain", AllLogLevel, @"validating line endings");

    NSString *string = [[self textStorage] string];
    NSUInteger length = [string length];
    NSUInteger curPos = 0;
    NSUInteger start, end, contentsEnd;
    unichar CR   = 0x000D;
    unichar LF   = 0x000A;
    unichar LSEP = 0x2028;
    unichar PSEP = 0x2029;
    NSUInteger countOfCR = 0;
    NSUInteger countOfLF = 0;
    NSUInteger countOfCRLF = 0;
    NSUInteger countOfLSEP = 0;
    NSUInteger countOfPSEP = 0;
    
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
    DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel, @"line endings stats -\nLF:   %lu\nLSEP: %lu\nPSEP: %lu\nCR:   %lu\nCRLF: %lu\n", (unsigned long)countOfLF, (unsigned long)countOfLSEP, (unsigned long)countOfPSEP, (unsigned long)countOfCR, (unsigned long)countOfCRLF);
    
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
            [[I_textStorage fullTextStorage] setHasMixedLineEndings:YES];
        	[self performSelector:@selector(showLineEndingAlert:) withObject:[NSDictionary dictionaryWithObjectsAndKeys:
        		localizedName,
        		@"localizedName",
        		[NSDictionary dictionaryWithObjectsAndKeys:
        			@"MixedLineEndingsAlert", @"Alert",
                    [sortedLineEndingStatsKeys objectAtIndex:4], @"LineEnding",
                 	nil],
                @"contextInfo",nil] afterDelay:0.0]; // delay this alert so we can call this method even if we didn't show the window yet
        }
    }
}

- (void)showLineEndingAlert:(NSDictionary *)anOptionDictionary {
	NSString *localizedName = [anOptionDictionary objectForKey:@"localizedName"];
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
		   contextInfo:[[anOptionDictionary objectForKey:@"contextInfo"] retain]];
}

- (id)handleShowScriptCommand:(NSScriptCommand *)command {
    [self showWindows];
    return nil;
}

- (void)showWindows {
	// now the transient window only is closed if now position data was found in the file to load - otherwise it happens in makewindowcontrollers
	BOOL closeTransientDocument = transientDocument && transientDocument != self
	&& NSEqualRects(transientDocumentWindowFrame, [[[transientDocument topmostWindowController] window] frame])
	&& [[[NSUserDefaults standardUserDefaults] objectForKey:OpenDocumentOnStartPreferenceKey] boolValue];
	
    if (I_documentProxyWindowController) {
        [[I_documentProxyWindowController window] orderFront:self];
    } else {
        PlainTextWindowController *windowController = [self topmostWindowController];
		if (closeTransientDocument) {
			NSWindow *window = [windowController window];
			[window setFrameTopLeftPoint:NSMakePoint(transientDocumentWindowFrame.origin.x, NSMaxY(transientDocumentWindowFrame))];
		}
        [windowController selectTabForDocument:self];

		if (closeTransientDocument) {
			[[windowController window] orderFront:self]; // stop cascading
		}
		
		[windowController showWindow:self];
    }
	
	
	if (closeTransientDocument && ![self isProxyDocument]) {
		[transientDocument close];
		transientDocument = nil;
		transientDocumentWindowFrame = NSZeroRect;
		
		PlainTextWindowController *windowController = self.windowControllers.firstObject;
		windowController.window.restorable = YES;
	}
	
	if ([[SEEDocumentController sharedInstance] isOpeningUntitledDocument] &&
		[[AppController sharedInstance] lastShouldOpenUntitledFile]) {
		transientDocument = self;
		transientDocumentWindowFrame = [[[transientDocument topmostWindowController] window] frame];

		PlainTextWindowController *windowController = self.windowControllers.firstObject;
		windowController.window.restorable = NO;

		[AppController sharedInstance].lastShouldOpenUntitledFile = NO;
	}
}

- (void)TCM_validateSize {
    if ([I_textStorage length] > [[NSUserDefaults standardUserDefaults] integerForKey:@"StringLengthToStopHighlightingAndWrapping"]) {
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
        [alert setAlertStyle:NSInformationalAlertStyle];
        [alert setMessageText:NSLocalizedString(@"Syntax Highlighting and Wrap Lines have been turned off due to the size of the Document.", @"BigFile Message Text")];
        [alert setInformativeText:NSLocalizedString(@"Turning on syntax highlighting for very large documents is not recommended.", @"BigFile Informative Text")];
        [alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
        [self presentAlert:alert
             modalDelegate:self
            didEndSelector:@selector(bigDocumentAlertDidEnd:returnCode:contextInfo:)
               contextInfo:nil];
    }
}

- (void)bigDocumentAlertDidEnd:(NSAlert *)anAlert returnCode:(int)aReturnCode  contextInfo:(void  *)aContextInfo {
    [[anAlert window] orderOut:self];
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


#pragma pack(push, 2)
struct SelectionRange
{
    int16_t unused1; // 0 (not used)
    int16_t lineNum; // line to select (<0 to specify range)
    int32_t startRange; // start of selection range (if line < 0)
    int32_t endRange; // end of selection range (if line < 0)
    int32_t unused2; // 0 (not used)
    int32_t theDate; // modification date/time
};
#pragma pack(pop)


- (void)handleOpenDocumentEvent:(NSAppleEventDescriptor *)eventDesc {
    DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel, @"handleOpenDocumentEvent");
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
    NSAppleEventDescriptor *bookmarksDescription = [[eventDesc descriptorForKeyword:keyDirectObject] coerceToDescriptorType:typeAEList];
    int numberOfItems = [bookmarksDescription numberOfItems];
    for (int i = 1; i <= numberOfItems; i++) {
        NSAppleEventDescriptor *bookmarkDataDesc = [[bookmarksDescription descriptorAtIndex:i] coerceToDescriptorType:typeBookmarkData];
        if (bookmarkDataDesc) {
            DEBUGLOG(@"FileIOLogDomain", DetailedLogLevel, @"bookmarkData: %@", [bookmarkDataDesc description]);
            NSURL *fileURL = [NSURL URLByResolvingBookmarkData:[bookmarkDataDesc data] options:0 relativeToURL:nil bookmarkDataIsStale:nil error:nil];
            NSString *filePath = [[fileURL path] stringByStandardizingPath];
            if ([filePath isEqualToString:[[[self fileURL] path] stringByStandardizingPath]]) {

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
                        [self gotoLine:selectionRange->lineNum + 1];
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
        }
    }
    [[self windowControllers] makeObjectsPerformSelector:@selector(synchronizeWindowTitleWithDocumentName)];
}

#pragma mark -
#pragma mark ### Export ###

- (IBAction)exportDocument:(id)aSender {
    /*  Sheet with options
        then sheet with save panel
        finish
    */
    if (! self.O_exportSheet) {
		// there are strong outlets to every top level nib object, so no additional array is needed to hold them.
		[[NSBundle mainBundle] loadNibNamed:@"Export" owner:self topLevelObjects:nil];
	}

    [self.O_exportSheetController setContent:[[[self documentMode] defaults] objectForKey:DocumentModeExportPreferenceKey]];
    [NSApp beginSheet: self.O_exportSheet
            modalForWindow: [self windowForSheet]
            modalDelegate:  self
            didEndSelector: @selector(continueExport:returnCode:contextInfo:)
            contextInfo:    nil];

}

- (IBAction)cancelExport:(id)aSender {
    [NSApp endSheet:self.O_exportSheet returnCode:NSCancelButton];
}

- (IBAction)continueExport:(id)aSender {
    [NSApp endSheet:self.O_exportSheet returnCode:NSOKButton];
}

- (void)continueExport:(NSWindow *)aSheet returnCode:(int)aReturnCode contextInfo:(void *)aContextInfo {
    [aSheet orderOut:self];
    if (aReturnCode == NSOKButton) {
        NSSavePanel *savePanel=[NSSavePanel savePanel];
        [savePanel setPrompt:NSLocalizedString(@"ExportPrompt",@"Text on the active SavePanel Button in the export sheet")];
        [savePanel setCanCreateDirectories:YES];
        [savePanel setCanSelectHiddenExtension:NO];
        [savePanel setAllowsOtherFileTypes:YES];
        [savePanel setTreatsFilePackagesAsDirectories:YES];
		[savePanel setAllowedFileTypes:@[@"html"]];
		[savePanel setNameFieldStringValue:[[[[self displayName] lastPathComponent] stringByDeletingPathExtension] stringByAppendingPathExtension:@"html"]];

		[savePanel beginSheetModalForWindow:[self windowForSheet] completionHandler:^(NSInteger result) {
			if (result == NSFileHandlingPanelOKButton) {
				NSDictionary *htmlOptions=[[[[self documentMode] defaults] objectForKey:DocumentModeExportPreferenceKey] objectForKey:DocumentModeExportHTMLPreferenceKey];
				FoldableTextStorage *textStorage = (FoldableTextStorage *)I_textStorage;

				if ([[htmlOptions objectForKey:DocumentModeHTMLExportHighlightSyntaxPreferenceKey] boolValue]) {
					SyntaxHighlighter *highlighter=[I_documentMode syntaxHighlighter];
					if (highlighter)
						while (![highlighter colorizeDirtyRanges:textStorage ofDocument:self]);
				} else {
					textStorage = [[FoldableTextStorage new] autorelease];
					[textStorage setAttributedString:I_textStorage];
					[[I_documentMode syntaxHighlighter] cleanUpTextStorage:textStorage];
					[textStorage  addAttributes:[self plainTextAttributes]
										  range:NSMakeRange(0,[textStorage length])];
				}

				BOOL shouldSaveImages=[[htmlOptions objectForKey:DocumentModeHTMLExportShowParticipantsPreferenceKey] boolValue] &&
				[[htmlOptions objectForKey:DocumentModeHTMLExportShowUserImagesPreferenceKey] boolValue];

				static NSDictionary *baseAttributeMapping = nil;
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

				NSString *htmlFile=[[savePanel URL] path];
				NSString *imageDirectory=@"";
				NSString *imageDirectoryPrefix=@"";
				if (shouldSaveImages) {
					NSFileManager *fileManager=[NSFileManager defaultManager];
					imageDirectoryPrefix=[[[htmlFile lastPathComponent] stringByDeletingPathExtension] stringByAppendingString:@"_images"];
					imageDirectory=[[htmlFile stringByDeletingLastPathComponent] stringByAppendingPathComponent:imageDirectoryPrefix];
					BOOL isDir = NO;
					if (([fileManager fileExistsAtPath:imageDirectory isDirectory:&isDir] && isDir) ||
						[fileManager createDirectoryAtPath:imageDirectory withIntermediateDirectories:YES attributes:nil error:nil]) {
						imageDirectoryPrefix = [imageDirectoryPrefix stringByAppendingString:@"/"];
					} else {
						imageDirectory = [htmlFile stringByDeletingLastPathComponent];
						imageDirectoryPrefix = @"";
					}
				}

				TCMMMUserManager *userManager=[TCMMMUserManager sharedInstance];
				NSMutableString *metaHeaders=[NSMutableString string];
				NSDate *now=[NSDate date];
				NSString *metaFormatString=@"<meta name=\"%@\" content=\"%@\" />\n";
				[metaHeaders appendFormat:metaFormatString,@"last-modified",[now rfc1123DateTimeString]];
				[metaHeaders appendFormat:metaFormatString,@"DC.Date",[now W3CDTFLongDateString]];
				[metaHeaders appendFormat:metaFormatString,@"DC.Creator",[[[userManager me] name] stringByReplacingEntitiesForUTF8:NO]];


				NSMutableSet *shortContributorIDs=[[NSMutableSet new] autorelease];

				// Load Templates
				NSString *templateDirectory=[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"HTMLExport"];
				NSString *documentBase=[[[NSString alloc] initWithData:[NSData dataWithContentsOfFile:[templateDirectory stringByAppendingPathComponent:@"Base.html"]]
															  encoding:NSUTF8StringEncoding] autorelease];
				NSString *styleSheetBase=[[[NSString alloc] initWithData:[NSData dataWithContentsOfFile:[templateDirectory stringByAppendingPathComponent:@"Base.css"]]
																encoding:NSUTF8StringEncoding] autorelease];
				NSMutableString *styleSheet=[NSMutableString stringWithString:styleSheetBase];

				NSValueTransformer *hueTrans=[NSValueTransformer valueTransformerForName:@"HueToColor"];

				// ShortID users
				BOOL colorConflict=NO;
				NSMutableSet *userColors=[NSMutableSet set];
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
						NSString *imageSavePath = [imageDirectory stringByAppendingPathComponent:[IDString stringByAppendingPathExtension:@"png"]];
						NSURL *imageSaveURL = [NSURL URLWithString:imageSavePath];
						[contributor writeImageToUrl:imageSaveURL];
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
						NSDictionary *contributorDict=nil;
						for (contributorDict in contributorDictionaries) {
							NSString *name=[[contributorDict valueForKeyPath:@"User.name"] stringByReplacingEntitiesForUTF8:YES];
							NSString *shortID=[contributorDict valueForKeyPath:@"ShortID"];
							NSString *aim=[[contributorDict valueForKeyPath:@"User.properties.AIM"] stringByReplacingEntitiesForUTF8:YES];
							NSString *email=[[contributorDict valueForKeyPath:@"User.properties.Email"] stringByReplacingEntitiesForUTF8:YES];
							[legend appendFormat:@"<tr>", nil];
							if (shouldSaveImages) {
								[legend appendFormat:@"<th><img src=\"%@%@.png\" width=\"32\" height=\"32\" alt=\"%@\"/></th>", imageDirectoryPrefix, name, name];
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
						NSDictionary *lurker=nil;
						int alternateFlag=0;
						for (lurker in lurkerDictionaries) {
							NSString *name   =[[lurker valueForKeyPath:@"User.name"] stringByReplacingEntitiesForUTF8:YES];
							//                    NSString *shortID= [lurker valueForKeyPath:@"ShortID"];
							NSString *aim    =[[lurker valueForKeyPath:@"User.properties.AIM"] stringByReplacingEntitiesForUTF8:YES];
							NSString *email  =[[lurker valueForKeyPath:@"User.properties.Email"] stringByReplacingEntitiesForUTF8:YES];
							[legend appendFormat:@"<tr%@>",alternateFlag?@" class=\"Alternate\"":@""];
							if (shouldSaveImages) {
								[legend appendFormat:@"<th><img src=\"%@%@.png\" width=\"32\" height=\"32\" alt=\"%@\"/></th>",imageDirectoryPrefix, name, name];
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
				if ([[htmlOptions objectForKey:DocumentModeHTMLExportAddCurrentDatePreferenceKey] boolValue]) {
					NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init]  autorelease];
					[dateFormatter setDateStyle:NSDateFormatterFullStyle];
					[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
					[content appendFormat:@"<p>%@</p>", [dateFormatter stringFromDate:[NSDate date]]];
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
		}];
	}
}

#pragma mark -
#pragma mark ### Save/Open Panel loading ###

- (void)TCM_ensureFileTypeDataOrSEEText {
	if (![self.fileType isEqualTo:kSEETypeSEEText] &&
		![self.fileType isEqualTo:(NSString *)kUTTypeData]) {
		// this neeeds to be data so the open panel doesn't strip our extensions
		self.fileType = (NSString *)kUTTypeData;
	}
}

- (void)saveDocumentWithDelegate:(id)delegate didSaveSelector:(SEL)didSaveSelector contextInfo:(void *)contextInfo {
    if ([self TCM_validateDocument]) {
		[self TCM_ensureFileTypeDataOrSEEText];
        [super saveDocumentWithDelegate:delegate didSaveSelector:didSaveSelector contextInfo:contextInfo];
    }
}

- (void)runModalSavePanelForSaveOperation:(NSSaveOperationType)saveOperation delegate:(id)delegate didSaveSelector:(SEL)didSaveSelector contextInfo:(void *)contextInfo {
    I_lastSaveOperation = saveOperation;
	if (I_flags.shouldSelectModeOnSave && (saveOperation != NSAutosaveElsewhereOperation)) {
		DocumentMode *mode = [[DocumentModeManager sharedInstance] documentModeForPath:nil withContentString:[[self textStorage] string]];

		if (![mode isBaseMode]) {
			[self setDocumentMode:mode];
		}
	}
    [super runModalSavePanelForSaveOperation:saveOperation delegate:delegate didSaveSelector:didSaveSelector contextInfo:contextInfo];
}

- (BOOL)shouldRunSavePanelWithAccessoryView {
	// we want to add our own accessory view in prepare save panel
    return NO;
}

const void *SEESavePanelAssociationKey = &SEESavePanelAssociationKey;

- (BOOL)prepareSavePanel:(NSSavePanel *)savePanel {
    if (![self fileURL] && [self directoryForSavePanel]) {
        [savePanel setDirectoryURL:[NSURL fileURLWithPath:[self directoryForSavePanel]]];
    }

	SEESavePanelAccessoryViewController *viewController = [SEESavePanelAccessoryViewController prepareSavePanel:savePanel withSaveOperation:I_lastSaveOperation forDocument:self];
	objc_setAssociatedObject(savePanel, SEESavePanelAssociationKey, viewController, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

	self.currentSavePanel = savePanel;
    return (viewController != nil);
}

- (IBAction)playbackLoggingState:(id)aSender {
    TCMMMLoggingState *ls = [[self session] loggingState];
    NSArray *loggedOperations = [ls loggedOperations];

    FoldableTextStorage *textStorage=(FoldableTextStorage *)[self textStorage];
    [textStorage setContentByDictionaryRepresentation:[ls initialTextStorageDictionaryRepresentation]];
    NSRange wholeRange=NSMakeRange(0,[textStorage length]);
    [textStorage addAttributes:[self plainTextAttributes] range:wholeRange];
    [textStorage addAttribute:NSParagraphStyleAttributeName value:[self defaultParagraphStyle] range:wholeRange];

    NSView *viewToUpdate = [[[self plainTextEditors] lastObject] editorView];
    [viewToUpdate display];
    
    for (id loopItem in loggedOperations) {
        [self handleOperation:[loopItem operation]];
        [viewToUpdate display];
    }
}

- (IBAction)reversePlaybackLoggingState:(id)aSender {
    TCMMMLoggingState *ls = [[self session] loggingState];
    NSArray *loggedOperations = [ls loggedOperations];
    unsigned opCount = [loggedOperations count];

    NSTextView *viewToUpdate = [[[self plainTextEditors] lastObject] textView];
    [viewToUpdate display];
    
    long i = 0;
	NSMutableAttributedString *attributedStringToInsert = [NSMutableAttributedString new];
    for (i=opCount-1;i>=0;--i) {
		TCMMMLoggedOperation *operation = [loggedOperations objectAtIndex:i];
		id innerOperation = [operation operation];
		if ([innerOperation isKindOfClass:[TextOperation class]]) {
			NSRange affectedRange = NSMakeRange([innerOperation affectedCharRange].location,[innerOperation replacementString].length);
	        if ([operation replacedAttributedStringDictionaryRepresentation]) {
				[attributedStringToInsert setContentByDictionaryRepresentation:[operation replacedAttributedStringDictionaryRepresentation]];
	        } else {
        		[attributedStringToInsert replaceCharactersInRange:NSMakeRange(0,[attributedStringToInsert length]) withString:@""];
	        }
	        [I_textStorage replaceCharactersInRange:affectedRange withAttributedString:attributedStringToInsert];
	        [viewToUpdate scrollRangeToVisible:[innerOperation affectedCharRange]];
	        [[viewToUpdate enclosingScrollView] display];
		}
    }
    [attributedStringToInsert release];
}

- (BOOL)isDocumentEdited {
	BOOL result = NO;
	if (I_flags.isPreparedForTermination) {
		result = NO;
	} else if (I_flags.isAutosavingForStateRestore) {
        result =  YES;
    } else {
        result =  [super isDocumentEdited];
    }
	return result;
}

- (BOOL)hasUnautosavedChanges {
	BOOL result = NO;
	if (I_flags.isAutosavingForStateRestore) {
		result =  YES;
    } else {
        result = [super hasUnautosavedChanges];
    }
	return result;
}

- (void)autosaveForStateRestore {
	I_flags.isAutosavingForStateRestore = YES;
	[self performActivityWithSynchronousWaiting:YES usingBlock:^(void (^activityCompletionHandler)(void)) {
		[self autosaveWithImplicitCancellability:NO completionHandler:^(NSError *error) {
            if (activityCompletionHandler) {
                activityCompletionHandler();
            }
		}];

		[self performSynchronousFileAccessUsingBlock:^{
			I_flags.isAutosavingForStateRestore = NO;
		}];
	}];
}

- (void)saveToURL:(NSURL *)anAbsoluteURL ofType:(NSString *)aType forSaveOperation:(NSSaveOperationType)saveOperation delegate:(id)delegate didSaveSelector:(SEL)didSaveSelector contextInfo:(void *)aContextInfo {
    BOOL didShowPanel = NO;
    if (saveOperation != NSAutosaveElsewhereOperation) {
        didShowPanel = (self.currentSavePanel)?YES:NO;
    }
    
    if (anAbsoluteURL) {
        if (I_flags.shouldSelectModeOnSave && (saveOperation != NSAutosaveElsewhereOperation)) {
            DocumentMode *mode = [[DocumentModeManager sharedInstance] documentModeForPath:[anAbsoluteURL path] withContentString:[[self textStorage] string]];

            if (![mode isBaseMode]) {
                [self setDocumentMode:mode];
            }
            I_flags.shouldSelectModeOnSave=NO;
        }
        // we have saved, so no more extension changing
        if (I_flags.shouldChangeExtensionOnModeChange && (saveOperation != NSAutosaveElsewhereOperation)) {
            I_flags.shouldChangeExtensionOnModeChange=NO;
        }

		SEESavePanelAccessoryViewController *accessoryViewController = objc_getAssociatedObject(self.currentSavePanel, SEESavePanelAssociationKey);

        if (saveOperation == NSSaveToOperation) {
            I_encodingFromLastRunSaveToOperation = [[accessoryViewController.encodingPopUpButtonOutlet selectedItem] tag];
            if ([[accessoryViewController.savePanelAccessoryFileFormatMatrixOutlet selectedCell] tag] == 1) {
                aType = kSEETypeSEEText;
			} else {
				if ([aType isEqualToString:kSEETypeSEEText] ||
					[aType isEqualToString:kSEETypeSEEMode]) {
					NSString *extension = [anAbsoluteURL pathExtension];
					if (extension.length > 0) {
						aType = extension;
					} else {
						aType = (NSString *)kUTTypeText;
					}
				}
            }
		} else if (didShowPanel) {
            if ([[accessoryViewController.savePanelAccessoryFileFormatMatrixOutlet selectedCell] tag] == 1) {
                aType = kSEETypeSEEText;
                I_flags.isSEEText = YES;
            } else {
				if ([aType isEqualToString:kSEETypeSEEText] ||
					[aType isEqualToString:kSEETypeSEEMode]) {
					NSString *extension = [anAbsoluteURL pathExtension];
					if (extension.length > 0) {
						aType = extension;
					} else {
						aType = (NSString *)kUTTypeText;
					}
				}
                I_flags.isSEEText = NO;
            }
		}
    }
    if (UTTypeConformsTo((CFStringRef)aType, (CFStringRef)kSEETypeSEEText)) {
        NSString *seeTextExtension = [self fileNameExtensionForType:aType saveOperation:NSSaveOperation];
        if (![[[anAbsoluteURL path] pathExtension] isEqualToString:seeTextExtension]) {
            anAbsoluteURL = [NSURL fileURLWithPath:[[anAbsoluteURL path] stringByAppendingPathExtension:seeTextExtension]];
        }
    }

    [super saveToURL:anAbsoluteURL ofType:aType forSaveOperation:saveOperation delegate:delegate didSaveSelector:didSaveSelector contextInfo:aContextInfo];
	self.currentSavePanel = nil;
}


#pragma mark - Reading

- (BOOL)revertToContentsOfURL:(NSURL *)anURL ofType:(NSString *)type error:(NSError **)outError {
    [[self plainTextEditors] makeObjectsPerformSelector:@selector(pushSelectedRanges)];
    BOOL success = [super revertToContentsOfURL:anURL ofType:type error:outError];
    if (success) {
        [self setFileURL:anURL];
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
    // - a Number - this number indicates the fileformatversion which the saving app knew about.
    // - an Array with exactly one entry which is a dictionary with uncompressed content
    // - an Array with exactly 2 entries which is a length followed by an compressed content dictionary
    // - everthing else will be ignored but preserved so we have potential upward compatibility
    
    NSUInteger headerLength = [(NSString*)@"SEEText" length];
    NSArray *topLevelArray = TCM_BdecodedObjectWithData([fileData subdataWithRange:NSMakeRange(headerLength,[fileData length]-headerLength)]);
    int fileversion=0;
    NSMutableArray *preservedData = [NSMutableArray array];
    NSMutableDictionary *dictRep = [NSMutableDictionary dictionary];
    NSEnumerator *elements = [topLevelArray objectEnumerator];
    id element = [elements nextObject];
    if (element) fileversion = [element unsignedIntValue];
#pragma unused (fileversion)

    while ((element=[elements nextObject])) {
        if ([element isKindOfClass:[NSArray class]] && [(NSArray*)element count]==1 && [[element objectAtIndex:0] isKindOfClass:[NSDictionary class]]) {
            [dictRep addEntriesFromDictionary:[element objectAtIndex:0]];
        } else if ([element isKindOfClass:[NSArray class]] && [(NSArray*)element count]==2) {
            NSDictionary *dict = TCM_BdecodedObjectWithData([NSData dataWithArrayOfCompressedData:element]);
            if (dict && [dict isKindOfClass:[NSDictionary class]]) {
                [dictRep addEntriesFromDictionary:dict];
            }
        } else {
            [preservedData addObject:element];
        }
    }
    self.preservedDataFromSEETextFile = preservedData;
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
    NSString *string = [NSString stringWithContentsOfURL:[NSURL fileURLWithPath:[[anURL path] stringByAppendingPathComponent:@"plain.txt"]]  encoding:[dictRep objectForKey:@"AutosaveInformation"] ? NSUTF8StringEncoding : (NSStringEncoding)[[storageRep objectForKey:@"Encoding"] unsignedIntValue] error:outError];
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
        }
        I_flags.isSEEText = UTTypeConformsTo((CFStringRef)[self fileType], (CFStringRef)kSEETypeSEEText);
        if (wasAutosave) *wasAutosave = YES;
    }
	if (I_stateDictionaryFromLoading) { // was set in takeSettingsFromDocumentState: because of symmetry - is code that also is in the non-seetext part of the calling method
		
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		if ([defaults boolForKey:DocumentStateSaveAndLoadTabSettingKey]) {
			NSDictionary *tabSettings = [I_stateDictionaryFromLoading objectForKey:@"t"];
			if ([tabSettings isKindOfClass:[NSDictionary class]]) {
				id value = [tabSettings objectForKey:@"u"];
				if ([value isKindOfClass:[NSNumber class]]) {
					[self setUsesTabs:[value boolValue]];
				}
				value = [tabSettings objectForKey:@"w"];
				if ([value isKindOfClass:[NSNumber class]]) {
					[self setTabWidth:[value intValue]];
				}
			}
		}
	}

    return YES;
}

- (BOOL)TCM_readFromURL:(NSURL *)anURL ofType:(NSString *)docType properties:(NSDictionary *)aProperties error:(NSError **)outError {
	if (outError) {*outError = nil;}
	if (!anURL) {
		return NO;
	}
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *fileName = [anURL path];
    DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel, @"readFromURL:%@ ofType:%@ properties: %@", anURL, docType, aProperties);

    #ifndef TCM_NO_DEBUG
        if (!_readFromURLDebugInformation) _readFromURLDebugInformation = [NSMutableString new];
        [_readFromURLDebugInformation appendFormat:@"%s %@ %@\n",__FUNCTION__, docType,aProperties];
    #endif

    I_flags.shouldChangeExtensionOnModeChange = NO;
    I_flags.shouldSelectModeOnSave = NO;
    I_flags.isReadingFile = YES;

	BOOL openingFileSupported = NO;
	for (NSString *uti in [[self class] readableTypes]) {
		if (UTTypeConformsTo((CFStringRef)docType, (CFStringRef)uti)) {
			openingFileSupported = YES;
			break;
		}
	}

    if (! openingFileSupported) {
        if (outError) *outError = [NSError errorWithDomain:@"SEEDomain" code:42 userInfo:
            [NSDictionary dictionaryWithObjectsAndKeys:
                fileName,NSFilePathErrorKey,
                [NSString stringWithFormat:@"Filetype: %@ not (yet) supported.",docType],NSLocalizedDescriptionKey,
                nil
            ]
        ];
        DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel, @"filetype not supported %@",outError?*outError:@"");
        I_flags.isReadingFile = NO;
        return NO;
    }

    BOOL isDir, fileExists;
    fileExists = [[NSFileManager defaultManager] fileExistsAtPath:fileName isDirectory:&isDir];
    if (fileExists && !isDir && UTTypeConformsTo((CFStringRef)docType, (CFStringRef)kSEETypeSEEText)) {
		NSString *fileExtension = [fileName pathExtension];

		if (fileExtension) {
		NSString *fileType = (NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (CFStringRef)fileExtension, nil);
			[self performSelector:@selector(setFileType:) withObject:[fileType autorelease] afterDelay:0.];
		} else {
			[self performSelector:@selector(setFileType:) withObject:(NSString *)kUTTypeText afterDelay:0.];
		}
    }
    if (!fileExists || (isDir && !UTTypeConformsTo((CFStringRef)docType, (CFStringRef)kSEETypeSEEText))) {
        // generate the correct error
        [NSData dataWithContentsOfURL:anURL options:0 error:outError];
        DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel, @"file doesn't exist %@",outError?*outError:nil);
        I_flags.isReadingFile = NO;
        return NO;
    }

    FullTextStorage *textStorage = (FullTextStorage *)[I_textStorage fullTextStorage];
    [textStorage setShouldWatchLineEndings:NO];


    BOOL isReverting = ([textStorage length] != 0);
    BOOL wasAutosaved = NO;
    NSAttributedString *undoString = nil;
    if (isReverting) {
        undoString = [textStorage attributedSubstringFromRange:NSMakeRange(0,[textStorage length])];
    }


    if (UTTypeConformsTo((CFStringRef)docType, (CFStringRef)kSEETypeSEEText)) {
        BOOL result = [self readSEETextFromURL:anURL properties:aProperties wasAutosave:&wasAutosaved error:outError];
        if (!result) {
            I_flags.isReadingFile = NO;
            return result;
        }
        if (wasAutosaved) fileName = self.fileURL.path;
    } else {
    
        BOOL isDocumentFromOpenPanel = [(SEEDocumentController *)[NSDocumentController sharedDocumentController] isDocumentFromLastRunOpenPanel:self];
        DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel, @"Document opened via open panel: %@", isDocumentFromOpenPanel ? @"YES" : @"NO");

        // load the data of the file
        BOOL isReadable = [[NSFileManager defaultManager] isReadableFileAtPath:fileName];
        
        //NSString *extension = [[fileName pathExtension] lowercaseString];
        
        NSData *fileData = nil;
        if (!isReadable) {
//            DEBUGLOG(@"FileIOLogDomain", AllLogLevel, @"We need root power!");
//            fileData = [self TCM_dataWithContentsOfFileReadUsingAuthorizedHelper:fileName];
//            if (fileData == nil) {
//                // generate the correct error
                [NSData dataWithContentsOfURL:anURL options:0 error:outError];
                DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel, @"file is not readable %@",*outError);
                I_flags.isReadingFile = NO;
                return NO;
//            }
        } else {
            fileData = [NSData dataWithContentsOfURL:anURL options:NSMappedRead error:outError];
			I_flags.hasUTF8BOM = [fileData startsWithUTF8BOM]; // set the flag here
        }
                
        DEBUGLOG(@"FileIOLogDomain", AllLogLevel, @"Data of size: %lu bytes read", (unsigned long)[fileData length]);

		// check extended attributes for state
		NSData *stateData = [UKXattrMetadataStore dataForKey:@"de.codingmonkeys.seestate" atPath:fileName traverseLink:YES];
		id stateDictionary = TCM_BdecodedObjectWithData(stateData);
//		NSLog(@"%s %@",__FUNCTION__,stateDictionary);
		if ([stateDictionary isKindOfClass:[NSDictionary class]]) {
			I_stateDictionaryFromLoading = [stateDictionary retain];
//			NSLog(@"%s %@",__FUNCTION__,stateDictionary);
		}
	


    #ifndef TCM_NO_DEBUG
        [_readFromURLDebugInformation appendFormat:@"was Readable:%d didLoadBytesOfData:%lu\n",isReadable,[fileData length]];
    #endif

    
        // Determine mode
        // How things should work:
        // - if we are reverting we stay in the mode we are
        // - If the user chose a mode explicidly in the open panel or via the see tool (in aProperties) it is taken
        // - if a mode is found in the state dictionary, it is used if found
        // - Otherwise automatic mode recognition will take place
        
        DocumentMode *mode = nil;
        
        if (isReverting) {
            mode = [self documentMode];
        } else {
            if ([aProperties objectForKey:@"mode"]) {
                NSString *modeName = [aProperties objectForKey:@"mode"];
                mode = [[DocumentModeManager sharedInstance] documentModeForName:modeName];
            } else if (isDocumentFromOpenPanel) {
                NSString *identifier = [(SEEDocumentController *)[NSDocumentController sharedDocumentController] modeIdentifierFromLastRunOpenPanel];
                if (![identifier isEqualToString:AUTOMATICMODEIDENTIFIER]) {
                    mode = [[DocumentModeManager sharedInstance] documentModeForIdentifier:identifier];
                }
            } else if ([defaults boolForKey:DocumentStateSaveAndLoadDocumentModeKey] && [I_stateDictionaryFromLoading objectForKey:@"m"]) {
            	mode = [[DocumentModeManager sharedInstance] documentModeForIdentifier:[I_stateDictionaryFromLoading objectForKey:@"m"]];
            	// if default mode is found, don't use it
            	if ([mode isBaseMode]) {
            		mode = nil;
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
                SEEDocumentController *documentController = (SEEDocumentController *)[NSDocumentController sharedDocumentController];
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
        
//        NSDictionary *docAttrs = nil;
        NSMutableDictionary *options = [NSMutableDictionary dictionary];
        [options setObject:NSPlainTextDocumentType forKey:@"DocumentType"];
        
        [textStorage beginEditing];     
        [[textStorage mutableString] setString:@""]; // Empty the document
        
        BOOL success = NO;
        
        if (encodingWasChosenExplicidly) {
            DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel, @"The user did choose an explicid encoding (via open panel or seetool): %@",CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(encoding)));
            [options setObject:[NSNumber numberWithUnsignedInt:encoding] forKey:@"CharacterEncoding"];
            success = [textStorage readFromData:fileData encoding:encoding];
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
                        success = [textStorage readFromData:fileData encoding:xEncoding];
                    }
                    
                }
            }
        }

        if (!success && [fileData startsWithUTF8BOM]) {
            DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel, @"We found a UTF-8 BOM!");
            [options setObject:[NSNumber numberWithUnsignedInt:NSUTF8StringEncoding] forKey:@"CharacterEncoding"];
            success = [textStorage readFromData:fileData encoding:NSUTF8StringEncoding];
    #ifndef TCM_NO_DEBUG
        [_readFromURLDebugInformation appendFormat:@"-> Found UTF8BOM:\n success:%d readWithOptions:%@ docAttributes:%@ error:%@\n",success,[options description],nil,(success?nil:*outError)];
    #endif
        }
        

        if ( !success ) {
            DEBUGLOG(@"FileIOLogDomain", AllLogLevel, @"Checking for encoding/charset setting from html/xml/css");
            // checking if we can guess the correct encoding based on the charset inside the doc - check only the first 4k to avoid finding encoding settings in strings later on in the file (my counter example is a php file that writes out an email with html content that has another encoding than my php file - this is an actual example ;) )
            unsigned dataLength = MIN([fileData length],4096);
            NSString	*fileContent = [[NSString alloc] initWithBytesNoCopy:(void *)[fileData bytes] length:dataLength encoding:NSMacOSRomanStringEncoding freeWhenDone:NO];
            BOOL		foundEncoding = NO;
            
            if ( [[mode documentModeIdentifier] isEqualToString:@"SEEMode.CSS"] ) {
                //check for css encoding
                foundEncoding = [fileContent findIANAEncodingUsingExpression:@"@charset.*?\"(.*?)\"" encoding:&encoding];
            } else {
                // check for html charset in all other documents
                foundEncoding = [fileContent findIANAEncodingUsingExpression:@"<meta.*?charset=(.*?)\"" encoding:&encoding];
            }
            [fileContent release];
            
            if ( foundEncoding ) {
                [options setObject:[NSNumber numberWithUnsignedInt:encoding] forKey:NSCharacterEncodingDocumentOption];
                success = [textStorage readFromData:fileData encoding:encoding];
                if (success) [[EncodingManager sharedInstance] activateEncoding:encoding];
    #ifndef TCM_NO_DEBUG
        [_readFromURLDebugInformation appendFormat:@"--> 2. Step - reading encoding/charset setting from html/xml/css:\n success:%d readWithOptions:%@ docAttributes:%@ error:%@\n iana-encoding-name:%@",success,[options description],nil,(success?nil:*outError),CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(encoding))];
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
            UniversalDetector   *detector = [[[UniversalDetector alloc] init] autorelease];
            int maxLength = [defaults integerForKey:@"ByteLengthToUseForModeRecognitionAndEncodingGuessing"];
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
                success = [textStorage readFromData:fileData encoding:udEncoding];
                if (success) [[EncodingManager sharedInstance] activateEncoding:udEncoding];
    #ifndef TCM_NO_DEBUG
        [_readFromURLDebugInformation appendFormat:@"---> 3. Step - using UniversalDetector:\n success:%d confidence:%1.3f encoding:%@ readWithOptions:%@ docAttributes:%@ error:%@\n",success,confidence,CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(udEncoding)) ,[options description],nil,(success?nil:*outError)];
    #endif
            }
        }

        // only try here if we have a clue (= fixed encoding set by the mode) about the encoding
        if (!success && encoding != NoStringEncoding && encoding < SmallestCustomStringEncoding) {
            DEBUGLOG(@"FileIOLogDomain", AllLogLevel, @"Checking with encoding set by mode");
            [options setObject:[NSNumber numberWithUnsignedInt:encoding] forKey:@"CharacterEncoding"];
            success = [textStorage readFromData:fileData encoding:encoding];
    #ifndef TCM_NO_DEBUG
        [_readFromURLDebugInformation appendFormat:@"-> Mode Encoding Step:\n success:%d readWithOptions:%@ docAttributes:%@ error:%@\n",success,[options description],nil,(success?nil:*outError)];
    #endif
        }
                    
        if ( !success ) {
            DEBUGLOG(@"FileIOLogDomain", AllLogLevel, @"Checking with Mac OS Roman as last resort");
            //even system failed, try Mac OS Roman system encoding
            [options setObject:[NSNumber numberWithUnsignedInt:NSMacOSRomanStringEncoding] forKey:NSCharacterEncodingDocumentOption];
            success = [textStorage readFromData:fileData encoding:NSMacOSRomanStringEncoding];
    #ifndef TCM_NO_DEBUG
			[_readFromURLDebugInformation appendFormat:@"-----> 5. Step - using mac os roman encoding:\n success:%d readWithOptions:%@ docAttributes:%@ error:%@\n",success,[options description],nil,(success?nil:outError?*outError:nil)];
    #endif
        }
    
        [self setFileEncoding:[[options objectForKey:@"CharacterEncoding"] unsignedIntValue]];

		if ( [[options objectForKey:NSCharacterEncodingDocumentOption] unsignedIntValue] == NSUTF8StringEncoding )
			I_flags.hasUTF8BOM = [fileData startsWithUTF8BOM];

        DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel, @"Encoding guessing information summary: %@", _readFromURLDebugInformation);
        DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel, @"Read successful? %@", success ? @"YES" : @"NO");

        [self setDocumentMode:mode];
        if ([I_textStorage length] > [defaults integerForKey:@"StringLengthToStopHighlightingAndWrapping"]) {
            [self setHighlightsSyntax:NO];
            [self setWrapLines:NO];
        }

        [self performSelector:@selector(TCM_validateSize) withObject:nil afterDelay:0.0f];

		if (I_stateDictionaryFromLoading) {
			
			NSNumber *value = [I_stateDictionaryFromLoading objectForKey:@"g"];
			if ([value isKindOfClass:[NSNumber class]]) {
				[self setShowsGutter:[value boolValue]];
			}
			
			
			if ([defaults boolForKey:DocumentStateSaveAndLoadWrapSettingKey]) {
				value = [I_stateDictionaryFromLoading objectForKey:@"w"];
				if ([value isKindOfClass:[NSNumber class]]) {
					int wrapValue = [value intValue];
					[self setWrapLines:wrapValue];
					if (wrapValue) {
						[self setWrapMode:wrapValue == 2 ? DocumentModeWrapModeCharacters : 1];
					}
				}			
			}
			
			if ([defaults boolForKey:DocumentStateSaveAndLoadTabSettingKey]) {
				NSDictionary *tabSettings = [I_stateDictionaryFromLoading objectForKey:@"t"];
				if ([tabSettings isKindOfClass:[NSDictionary class]]) {
					value = [tabSettings objectForKey:@"u"];
					if ([value isKindOfClass:[NSNumber class]]) {
						[self setUsesTabs:[value boolValue]];
					}
					value = [tabSettings objectForKey:@"w"];
					if ([value isKindOfClass:[NSNumber class]]) {
						[self setTabWidth:[value intValue]];
					}
				}
			}
			
			if ([defaults boolForKey:DocumentStateSaveAndLoadFoldingStateKey]) {
				unsigned int characterLength = [[I_stateDictionaryFromLoading objectForKey:@"l"] unsignedIntValue];
				BOOL sameLength = (characterLength == [[I_textStorage fullTextStorage] length]);
				if (sameLength){
		//			NSLog(@"%s was same Length",__FUNCTION__);
					NSData *foldingData = [I_stateDictionaryFromLoading objectForKey:@"f"];
					if (foldingData) {
						[I_textStorage foldAccordingToDataRepresentation:foldingData];
					}
				}
			}
		}

        [textStorage endEditing];

        NSNumber *lineEndingNumber = [I_stateDictionaryFromLoading objectForKey:@"e"];
        if (lineEndingNumber) {
        	[self setLineEnding:[lineEndingNumber intValue]];
        } else {
	        [self TCM_validateLineEndings];
	    }
    } // end of part where the file wasn't SEEText

	[SEEDocumentController sharedInstance].documentListWindow.restorable = YES;
	
    DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel, @"fileEncoding: %@", [NSString localizedNameOfStringEncoding:[self fileEncoding]]);

    [self setKeepDocumentVersion:NO];
    NSDictionary *fattrs = [[NSFileManager defaultManager] attributesOfItemAtPath:fileName error:nil];
    [self setFileAttributes:fattrs];
    BOOL isWritable = [[NSFileManager defaultManager] isWritableFileAtPath:fileName] || wasAutosaved;
    DEBUGLOG(@"FileIOLogDomain", DetailedLogLevel, @"isWritable: %@", isWritable ? @"YES" : @"NO");
    [self setIsFileWritable:isWritable];

/*
    NSUInteger wholeLength = [I_textStorage length];
    [I_textStorage addAttributes:[self plainTextAttributes]
                           range:NSMakeRange(0, wholeLength)];
*/
    [self updateChangeCount:NSChangeCleared];
    
    if (isReverting) {
        [[self documentUndoManager] beginUndoGrouping];
        [[[self documentUndoManager] prepareWithInvocationTarget:self] setAttributedStringUndoable:undoString];
        [[self documentUndoManager] endUndoGrouping];
    }
    
    if (!isReverting && !UTTypeConformsTo((CFStringRef)docType, (CFStringRef)kSEETypeSEEText)) {
        // clear the logging state
        if ([I_textStorage length] > [defaults integerForKey:@"ByteLengthToUseForModeRecognitionAndEncodingGuessing"]) {
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

    [(FullTextStorage *)textStorage setShouldWatchLineEndings:YES];
    I_flags.isReadingFile = NO;

	// do a first round of syntax highlighting
	[self highlightSyntaxLoop];

    return YES;
}

- (BOOL)readFromURL:(NSURL *)anURL ofType:(NSString *)docType error:(NSError **)outError {
    NSDictionary *properties = [[SEEDocumentController sharedDocumentController] propertiesForOpenedFile:[anURL path]];
    return [self TCM_readFromURL:anURL ofType:docType properties:properties error:outError];
}

#pragma mark - Saving

- (void) saveToURL:(NSURL *)url ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation completionHandler:(void (^)(NSError *))completionHandler
{
	NSURL *originalFileURL = self.fileURL;

	// because cocoa stores autosave information relative to its opened file and this fails in an sandbox enviroment
	// the saving URL is modified here. It's saving its contents to the autosave folder
	// I think this should be standard behaviour with sandbox and window restore if autosave in place is disabled.
	if (saveOperation == NSAutosaveElsewhereOperation && originalFileURL != nil) {
		if (self.autosavedContentsFileURL == nil) { // not yet autosaved in this session?
			NSURL *autosaveLocationURL = [[NSFileManager defaultManager] URLForDirectory:NSAutosavedInformationDirectory inDomain:NSUserDomainMask appropriateForURL:originalFileURL create:YES error:nil];
			url = [autosaveLocationURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%@_%@", [NSString UUIDString], url.lastPathComponent]];
		}
	}

	[super saveToURL:url ofType:typeName forSaveOperation:saveOperation completionHandler:^(NSError *error){
		__block NSError *authenticationError = nil;
		__block BOOL hasBeenWritten = (error == nil);

		[self continueActivityUsingBlock:^{
			NSError *fileSavingError = error;

			if (saveOperation != NSAutosaveElsewhereOperation) {
				[self performActivityWithSynchronousWaiting:YES usingBlock:^(void (^activityCompletionHandler)(void)) {
					if ([error.domain isEqualToString:@"SEEDocumentSavingDomain"] && error.code == 0x0FF) {
						hasBeenWritten = [self writeUsingAuthenticationToURL:url ofType:typeName saveOperation:saveOperation error:&authenticationError];
						[authenticationError retain];
						activityCompletionHandler();
					} else {
						activityCompletionHandler();
					}
				}];
			}

			if (hasBeenWritten) {
				fileSavingError = nil;

				if (saveOperation == NSSaveOperation) {
					[self TCM_sendODBModifiedEvent];
					[self setKeepDocumentVersion:NO];
				} else if (saveOperation == NSSaveAsOperation) {
					if ([url isEqualTo:originalFileURL]) {
						// trigger ODB event if original file gets overwritten
						[self TCM_sendODBModifiedEvent];
					} else {
						[self setODBParameters:nil];
					}
					[self setShouldChangeChangeCount:YES];
				}

				if (saveOperation != NSSaveToOperation && saveOperation != NSAutosaveElsewhereOperation) {
					[self setTemporaryDisplayName:nil];
					[[NSNotificationCenter defaultCenter] postNotificationName:PlainTextDocumentDidSaveShouldReloadWebPreviewNotification object:self];
				}
			}

			if (saveOperation != NSSaveToOperation && saveOperation != NSAutosaveElsewhereOperation) {
				NSDictionary *fattrs = [[NSFileManager defaultManager] attributesOfItemAtPath:url.path error:NULL];
				[self setFileAttributes:fattrs];
				[self setIsFileWritable:hasBeenWritten];
			}

			if (hasBeenWritten) {
				[[NSNotificationQueue defaultQueue]
				 enqueueNotification:[NSNotification notificationWithName:PlainTextDocumentDidSaveNotification object:self]
				 postingStyle:NSPostWhenIdle
				 coalesceMask:NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender
				 forModes:[NSArray arrayWithObject:NSDefaultRunLoopMode]];
			} else {
				if (authenticationError) {
					fileSavingError = [authenticationError autorelease];
				}
			}

			if (completionHandler) {
				completionHandler(fileSavingError);
			}
		}];
	}];
}


- (BOOL)writeMetaDataToURL:(NSURL *)absoluteURL error:(NSError **)outError {
    NSXMLElement *rootElement = [NSXMLNode elementWithName:@"seemetadata"];
    [rootElement addChild:[NSXMLNode elementWithName:@"charset" stringValue:[self encoding]]];
    [rootElement addChild:[NSXMLNode elementWithName:@"mode" stringValue:[[self documentMode] documentModeIdentifier]]];
    
    
    TCMMMUserManager *um = [TCMMMUserManager sharedInstance];
    TCMMMLoggingState *ls = [[self session] loggingState];
    TCMMMLoggedOperation *lop = nil;
    if ([[ls loggedOperations] count]>0) {
        lop = [[ls loggedOperations] objectAtIndex:0];
        NSXMLElement *element = [NSXMLNode elementWithName:@"firstactivity" stringValue:[[lop date] rfc1123DateTimeString]];
        TCMMMUser *user = [um userForUserID:[[lop operation] userID]];
        if (user) [element addAttribute:[NSXMLNode attributeWithName:@"name" stringValue:[user name]]];
        [rootElement addChild:element];
    }
    
    lop = [[ls loggedOperations] lastObject];
    if (lop) {
        NSXMLElement *element = [NSXMLNode elementWithName:@"lastactivity" stringValue:[[lop date] rfc1123DateTimeString]];
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
    NSDictionary *contributorEntry = nil;
    for (contributorEntry in contributorArray) {
        NSXMLElement *element = [NSXMLNode elementWithName:@"contributor"];
        TCMMMUser *contributor = [contributorEntry objectForKey:@"user"];
        [element addAttribute:[NSXMLNode attributeWithName:@"name" stringValue:[contributor name]]];
        if ([contributor email]) [element addAttribute:[NSXMLNode attributeWithName:@"email" stringValue:[contributor email]]];
        if ([contributor aim])   [element addAttribute:[NSXMLNode attributeWithName:@"aim"   stringValue:[contributor aim]]];
        TCMMMLogStatisticsEntry *stat = [contributorEntry objectForKey:@"stat"];
        if (stat) {
            [element addAttribute:[NSXMLNode attributeWithName:@"lastactivity" stringValue:[[stat dateOfLastActivity] rfc1123DateTimeString]]];
            [element addAttribute:[NSXMLNode attributeWithName:@"deletions"  stringValue:[NSString stringWithFormat:@"%lu",[stat deletedCharacters]]]];
            [element addAttribute:[NSXMLNode attributeWithName:@"insertions" stringValue:[NSString stringWithFormat:@"%lu",[stat insertedCharacters]]]];
            [element addAttribute:[NSXMLNode attributeWithName:@"selections" stringValue:[NSString stringWithFormat:@"%lu",[stat selectedCharacters]]]];
        }
        [contributorsElement addChild:element];
    }
    NSXMLDocument *document = [NSXMLDocument documentWithRootElement:rootElement];
    [document setCharacterEncoding:(NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding))];
    return [[document XMLDataWithOptions:NSXMLNodePrettyPrint|NSXMLNodePreserveEmptyElements] writeToURL:absoluteURL options:0 error:outError];
}

- (NSString *)autosavingFileType {
    return kSEETypeSEEText;
}

- (BOOL)writeSafelyToURL:(NSURL*)anAbsoluteURL ofType:(NSString *)docType forSaveOperation:(NSSaveOperationType)saveOperationType error:(NSError **)outError {
    
    NSString *fullDocumentPath = [anAbsoluteURL path];
    DEBUGLOG(@"FileIOLogDomain", DetailedLogLevel, @"writeSavelyToURL: %@", anAbsoluteURL);
    
    NSError *error = nil;
	BOOL needsAuthenticatedSave = NO;
    BOOL hasBeenWritten = [super writeSafelyToURL:anAbsoluteURL ofType:docType forSaveOperation:saveOperationType error:&error];
    if (outError) {
        *outError = error;
    }
    
    if (!hasBeenWritten) {
        DEBUGLOG(@"FileIOLogDomain", AllLogLevel, @"Failed to write using writeSafelyToURL: %@",*outError);
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:fullDocumentPath error:nil];
        NSUInteger fileReferenceCount = [[fileAttributes objectForKey:NSFileReferenceCount] unsignedLongValue];
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
        
        if ( !hasBeenWritten && ((error && [error TCM_relatesToErrorCode:NSFileWriteNoPermissionError inDomain:nil]) ||
								 (error && [error TCM_relatesToErrorCode:13 inDomain:NSPOSIXErrorDomain])) ) {

            if (outError) *outError = nil; // clear outerror because we already showed it
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
					needsAuthenticatedSave = YES;
                } else if (returnCode == NSAlertSecondButtonReturn) {
                    NSFileManager *fileManager = [NSFileManager defaultManager];
                    NSString *tempFilePath = tempFileName(fullDocumentPath);
                    hasBeenWritten = [self writeToURL:[NSURL fileURLWithPath:tempFilePath] ofType:docType forSaveOperation:saveOperationType originalContentsURL:nil error:outError];
                    if (hasBeenWritten) {
                        BOOL result = [fileManager removeItemAtPath:fullDocumentPath error:nil];
                        if (result) {
                            hasBeenWritten = [fileManager moveItemAtPath:tempFilePath toPath:fullDocumentPath error:nil];
                            if (hasBeenWritten) {
                                NSDictionary *fattrs = [self fileAttributesToWriteToURL:[NSURL fileURLWithPath:fullDocumentPath] ofType:docType forSaveOperation:saveOperationType originalContentsURL:nil error:nil];
                                [fileManager setAttributes:fattrs ofItemAtPath:fullDocumentPath error:nil];
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
								if ( outError )
									*outError = nil; 
                            }
                        } else {
                            (void)[fileManager removeItemAtPath:tempFilePath error:nil];
                            NSAlert *newAlert = [[[NSAlert alloc] init] autorelease];
                            [newAlert setAlertStyle:NSWarningAlertStyle];
                            [newAlert setMessageText:NSLocalizedString(@"Save", nil)];
                            [newAlert setInformativeText:NSLocalizedString(@"AlertInformativeText: Error occurred during replace", @"Informative text in an alert which tells the user that an error prevented the replace")];
                            [newAlert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
                            [self presentAlert:newAlert
                                 modalDelegate:nil
                                didEndSelector:nil
                                   contextInfo:NULL];
							if ( outError )
								*outError = nil; 

                        }
                    }
                }
            } else {
                DEBUGLOG(@"FileIOLogDomain", AllLogLevel, @"We need root power!");
				needsAuthenticatedSave = YES;
            }
        }
     }

	if (needsAuthenticatedSave && (saveOperationType != NSAutosaveElsewhereOperation)) {
		if (outError) {
			*outError = [NSError errorWithDomain:@"SEEDocumentSavingDomain" code:0X0FF userInfo:nil];
		}
	}

    return hasBeenWritten;
}

- (BOOL)writeUsingAuthenticationToURL:(NSURL *)anAbsoluteURL ofType:(NSString *)docType saveOperation:(NSSaveOperationType)saveOperationType error:(NSError **)outError {

	__block BOOL result = NO;

	NSError *applicationScriptURLError = nil;
	NSURL *applicationScriptURL = [[NSFileManager defaultManager] URLForDirectory:NSApplicationScriptsDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:&applicationScriptURLError];

	if (! applicationScriptURLError) {
		NSError *authenticationScriptError = nil;
		NSURL *authenticationScriptURL = [applicationScriptURL URLByAppendingPathComponent:@"SubEthaEdit_AuthenticatedSave.scpt"];
		NSUserAppleScriptTask *authorisationScript = [[[NSUserAppleScriptTask alloc] initWithURL:authenticationScriptURL error:&authenticationScriptError] autorelease];

		if (! authenticationScriptError) {
			NSURL *tempFileURL = [NSURL fileURLWithPath:NSTemporaryDirectory()];
			tempFileURL = [tempFileURL URLByAppendingPathComponent:anAbsoluteURL.lastPathComponent];

			__block BOOL tempFileWritten = NO;
			__block NSError *fileWritingError = nil;
			[self performSynchronousFileAccessUsingBlock:^{
				NSError *error = nil;
				tempFileWritten = [self writeToURL:tempFileURL ofType:docType forSaveOperation:saveOperationType originalContentsURL:anAbsoluteURL error:&error];
				fileWritingError = [error retain];
			}];

			if (tempFileWritten) {
				NSAppleEventDescriptor *containerDescriptor = [NSAppleEventDescriptor appleEventWithEventClass:kCoreEventClass eventID:kAEOpenApplication targetDescriptor:nil returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID];

				{
					NSAppleEventDescriptor *functionDescriptor = [NSAppleEventDescriptor descriptorWithString:@"run"];
					[containerDescriptor setParamDescriptor:functionDescriptor forKeyword:'snam'];
				}

				{
					NSAppleEventDescriptor* argumentsDescriptor = [NSAppleEventDescriptor listDescriptor];
					[argumentsDescriptor insertDescriptor:[NSAppleEventDescriptor descriptorWithString:tempFileURL.path] atIndex:1];
					[argumentsDescriptor insertDescriptor:[NSAppleEventDescriptor descriptorWithString:anAbsoluteURL.path] atIndex:2];
					[containerDescriptor setParamDescriptor:argumentsDescriptor forKeyword:keyDirectObject];
				}

				dispatch_group_t group = dispatch_group_create();
				dispatch_group_enter(group);
				__block NSError *appleScriptExecutionError = nil;
				[authorisationScript executeWithAppleEvent:containerDescriptor completionHandler:^(NSAppleEventDescriptor *resultDescriptor, NSError *error) {
					if (error) {
						appleScriptExecutionError = [error retain];
					} else {
						result = YES;
					}
					dispatch_group_leave(group);
				}];
				dispatch_group_wait(group, DISPATCH_TIME_FOREVER);

				if (result) {
					if (saveOperationType == NSSaveOperation || saveOperationType == NSSaveAsOperation) {
						[self updateChangeCount:NSChangeCleared];

						[self setFileURL:anAbsoluteURL];
						[self setFileType:docType];

						NSError *fileModificationDateError = nil;
						NSDate *modificationDate = nil;
						if ([anAbsoluteURL getResourceValue:&modificationDate forKey:NSURLContentModificationDateKey error:&fileModificationDateError]) {
							[self setFileModificationDate:modificationDate];
						} else {
							NSLog(@"%s - Can't get file modification date dure to error : %@", __FUNCTION__, fileModificationDateError);
							[self setFileModificationDate:[NSDate date]]; // fallback
						}
					}
				} else {
					if (outError) {
						*outError = [appleScriptExecutionError autorelease];
					}
				}
			} else {
				if (outError) {
					*outError = [fileWritingError autorelease];
				}
			}
		} else {
			if (outError) {

				if ([authenticationScriptError.domain isEqualToString:NSCocoaErrorDomain] && authenticationScriptError.code == 260) {
					// Error Domain=NSCocoaErrorDomain Code=260 "The file “SubEthaEdit_AuthenticatedSave.scpt” couldn’t be opened because there is no such file.
					id revoveryAttempter = [[[SEEAuthenticatedSaveMissingScriptRecoveryAttempter alloc] init] autorelease];

					NSDictionary *userInfo =
					@{NSUnderlyingErrorKey: authenticationScriptError,
					  NSLocalizedDescriptionKey: NSLocalizedStringWithDefaultValue(@"AUTHENTICATION_SCRIPT_MISSING_ERROR_DESCRIPTION", nil, [NSBundle mainBundle], @"Can't find authentication helper script.", @""),

					  NSLocalizedRecoverySuggestionErrorKey: NSLocalizedStringWithDefaultValue(@"AUTHENTICATION_SCRIPT_MISSING_ERROR_SUGGESTION", nil, [NSBundle mainBundle], @"Please visit our website to download the script and follow the instructions to install.", @""),

					  NSLocalizedRecoveryOptionsErrorKey: @[NSLocalizedStringWithDefaultValue(@"AUTHENTICATION_SCRIPT_MISSING_ERROR_BUTTON_TITLE1", nil, [NSBundle mainBundle], @"Visit Website…", @""),
															NSLocalizedStringWithDefaultValue(@"AUTHENTICATION_SCRIPT_MISSING_ERROR_BUTTON_TITLE2", nil, [NSBundle mainBundle], @"Ignore", )],

					  NSRecoveryAttempterErrorKey: revoveryAttempter
					  };

					NSError *error = [NSError errorWithDomain:@"SEEDocumentSavingDomain" code:0x0FE userInfo:userInfo];
					*outError = error;
				} else {
					*outError = authenticationScriptError;
				}
			}
		}
	} else {
		if (outError) {
			*outError = applicationScriptURLError;
		}
	}
	return result;
}

- (BOOL)writeToURL:(NSURL *)absoluteURL ofType:(NSString *)inType forSaveOperation:(NSSaveOperationType)saveOperation originalContentsURL:(NSURL *)originalContentsURL error:(NSError **)outError {
	//-timelog    NSDate *startDate = [NSDate date];
	//-timelog    NSLog(@"%s %@ %@ %d %@",__FUNCTION__, absoluteURL, inTypeName, saveOperation,originalContentsURL);
    DEBUGLOG(@"FileIOLogDomain", AllLogLevel, @"write to:%@ type:%@ saveOperation:%lu originalURL:%@", absoluteURL, inType, (unsigned long)saveOperation,originalContentsURL);
    if (UTTypeConformsTo((CFStringRef)inType, kUTTypeData)) {
        BOOL modeWantsUTF8BOM = [[[self documentMode] defaultForKey:DocumentModeUTF8BOMPreferenceKey] boolValue];
        DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel, @"modeWantsUTF8BOM: %d, hasUTF8BOM: %d", modeWantsUTF8BOM, I_flags.hasUTF8BOM);
        BOOL useUTF8Encoding = ((I_lastSaveOperation == NSSaveToOperation) && (I_encodingFromLastRunSaveToOperation == NSUTF8StringEncoding)) || ((I_lastSaveOperation != NSSaveToOperation) && ([self fileEncoding] == NSUTF8StringEncoding));
		BOOL result = NO;
        if ((I_flags.hasUTF8BOM || modeWantsUTF8BOM) && useUTF8Encoding) {
            NSData *data = [[[self textStorage] string] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
            result = [[data dataPrefixedWithUTF8BOM] writeToURL:absoluteURL options:0 error:outError];
            if (result) {
            	// write the xtended attribute for utf-8
            	[UKXattrMetadataStore setString:@"UTF-8;134217984" forKey:@"com.apple.TextEncoding" atPath:[absoluteURL path] traverseLink:YES];
            }
        } else {
            // let us write using NSStrings write methods so the encoding is added to the extended attributes
            result = [[[(FoldableTextStorage *)[self textStorage] fullTextStorage] string] writeToURL:absoluteURL atomically:NO encoding:[self fileEncoding] error:outError];
        }

		// state data
		NSData *stateData = [self stateData];
        if (stateData && ![[NSUserDefaults standardUserDefaults] boolForKey:kSEEDefaultsKeyDontSaveDocumentStateInXattrs]) {
			[UKXattrMetadataStore setData:stateData forKey:@"de.codingmonkeys.seestate" atPath:[absoluteURL path] traverseLink:YES];
		} else {
			// due to the way fspathreplaceobject of carbon core works, we need to remove the xattr from the original file if it exists
			if (originalContentsURL) {
				[UKXattrMetadataStore removeDataForKey:@"de.codingmonkeys.seestate" atPath:[originalContentsURL path] traverseLink:YES];
			}
		}
		//        NSArray *xattrKeys = [UKXattrMetadataStore allKeysAtPath:[absoluteURL path] traverseLink:YES];
		//        NSLog(@"%s xattrKeys:%@",__FUNCTION__,xattrKeys);
        return result;
    } else if (UTTypeConformsTo((CFStringRef)inType, (CFStringRef)kSEETypeSEEText)) {
        NSString *packagePath = [absoluteURL path];
        NSFileManager *fm =[NSFileManager defaultManager];
        if ([fm createDirectoryAtPath:packagePath withIntermediateDirectories:YES attributes:nil error:nil]) {
            BOOL success = YES;

            // mark it as package
            NSString *contentsPath = [packagePath stringByAppendingPathComponent:@"Contents"];
            success = [fm createDirectoryAtPath:contentsPath withIntermediateDirectories:YES attributes:nil error:nil];
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
            if (saveOperation == NSAutosaveElsewhereOperation) {
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
            if (self.preservedDataFromSEETextFile) {
                [dataArray addObjectsFromArray:self.preservedDataFromSEETextFile];
            }
			//-timelog            tempDate = [NSDate date];
            [data appendData:TCM_BencodedObject(dataArray)];
			//-timelog            NSLog(@"bencoding the final dictionary took %fs",[tempDate timeIntervalSinceNow]*-1.);
			//-timelog            NSLog(@"%s bencoding and compressing took: %fs",__FUNCTION__,[intermediateDate timeIntervalSinceNow]*-1.);

            if (success) success = [data writeToURL:[NSURL fileURLWithPath:[packagePath stringByAppendingPathComponent:@"collaborationdata.bencoded"]] options:0 error:outError];
			// autosave in utf-8 always no matter what to accomodate for strange inserted characters
            if (success) success = [[[(FoldableTextStorage *)[self textStorage] fullTextStorage] string] writeToURL:[NSURL fileURLWithPath:[packagePath stringByAppendingPathComponent:@"plain.txt"]] atomically:NO encoding:(saveOperation == NSAutosaveElsewhereOperation) ? NSUTF8StringEncoding : [self fileEncoding] error:outError];
            if (success) success = [self writeMetaDataToURL:[NSURL fileURLWithPath:[packagePath stringByAppendingPathComponent:@"metadata.xml"]] error:outError];

            if (saveOperation != NSAutosaveElsewhereOperation) {
                NSString *quicklookPath = [packagePath stringByAppendingPathComponent:@"QuickLook"];
                if (success) success = [fm createDirectoryAtPath:quicklookPath withIntermediateDirectories:YES attributes:nil error:nil];
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
						NSURL *pdfURL = [NSURL fileURLWithPath:pdfPath];
                        [printDict setObject:pdfURL forKey:NSPrintJobSavingURL];
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
                        [op setShowsPrintPanel:NO];
                        [self runModalPrintOperation:op
                                            delegate:nil
                                      didRunSelector:NULL
                                         contextInfo:nil];
                        [[self printOptions] addEntriesFromDictionary:savedPrintOptions];
						[savedPrintOptions release];
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
                                        [fm createDirectoryAtPath:[targetPath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];
                                    }
                                    // copy the file afterwards
                                    [fm copyItemAtPath:sourcePath toPath:targetPath error:nil];
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
                [fm removeItemAtPath:packagePath error:nil];
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
        return [super writeToURL:absoluteURL ofType:inType forSaveOperation:saveOperation originalContentsURL:originalContentsURL error:outError];
    }   
}

- (NSData *)dataOfType:(NSString *)aType error:(NSError **)outError {
	NSData *data = nil;
	
	if (! (UTTypeConformsTo((CFStringRef)aType, (CFStringRef)kSEETypeSEEText) &&
		   UTTypeConformsTo((CFStringRef)aType, (CFStringRef)kSEETypeSEEMode))) {
		if (I_lastSaveOperation == NSSaveToOperation) {
			DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel, @"Save a copy using encoding: %@", [NSString localizedNameOfStringEncoding:I_encodingFromLastRunSaveToOperation]);
			[[EncodingManager sharedInstance] unregisterEncoding:I_encodingFromLastRunSaveToOperation];
			data = [[[I_textStorage fullTextStorage] string] dataUsingEncoding:I_encodingFromLastRunSaveToOperation allowLossyConversion:YES];
		} else {
			DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel, @"Save using encoding: %@", [NSString localizedNameOfStringEncoding:[self fileEncoding]]);
			data = [[[I_textStorage fullTextStorage] string] dataUsingEncoding:[self fileEncoding] allowLossyConversion:YES];
		}
		
		BOOL modeWantsUTF8BOM = [[[self documentMode] defaultForKey:DocumentModeUTF8BOMPreferenceKey] boolValue];
		DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel, @"modeWantsUTF8BOM: %d, hasUTF8BOM: %d", modeWantsUTF8BOM, I_flags.hasUTF8BOM);
		BOOL useUTF8Encoding = ((I_lastSaveOperation == NSSaveToOperation) && (I_encodingFromLastRunSaveToOperation == NSUTF8StringEncoding)) || ((I_lastSaveOperation != NSSaveToOperation) && ([self fileEncoding] == NSUTF8StringEncoding));
		
		if ((I_flags.hasUTF8BOM || modeWantsUTF8BOM) && useUTF8Encoding) {
			data =  [data dataPrefixedWithUTF8BOM];
		}
	}
	
	if (data == nil) {
		if (outError) {
			NSString *errorMessage = [NSString stringWithFormat:@"Could not create data for Filetype: %@", aType];
			NSError *error =
			[NSError errorWithDomain:@"SEEDomain"
								code:42
							userInfo:@{NSLocalizedDescriptionKey: errorMessage}];
			*outError = error;
		}
	}
	
	return data;
}

- (BOOL)TCM_validateDocument {
    NSString *fileName = [[self fileURL] path];
    DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel, @"Validate document: %@", fileName);

    NSDictionary *fattrs = [[NSFileManager defaultManager] attributesOfItemAtPath:fileName error:nil];
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

- (BOOL)hasMarkedTexts {
	NSEnumerator *plainTextEditors = [[self plainTextEditors] objectEnumerator];
	PlainTextEditor *editor = nil;
	while ((editor = [plainTextEditors nextObject])) {
		if ([[editor textView] hasMarkedText]) {
//			[[editor textView] unmarkText];
			return YES;
		}
	}
	return NO;
}



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
        if ([self fileEncoding] == (NSUInteger)[anItem tag]) {
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
                         NSLocalizedString(@"Advertise",@"Menu/Toolbar Title for advertising the Document")];
        return [[self session] isServer];
    } else if (selector == @selector(toggleIsAnnouncedOnAllDocuments:)) {
        [anItem setTitle:[self isAnnounced]?
                         NSLocalizedString(@"Conceal All",@"Menu/Toolbar Title for concealing all Documents"):
                         NSLocalizedString(@"Advertise All",@"Menu/Toolbar Title for advertising all Documents")];
        return YES;
    } else if (selector == @selector(saveDocument:)) {
        return ![self isProxyDocument] && ![self hasMarkedTexts];
    } else if (selector == @selector(saveDocumentAs:)) {
        return ![self isProxyDocument] && ![self hasMarkedTexts];
    } else if (selector == @selector(saveDocumentTo:)) {
        return ![self isProxyDocument] && ![self hasMarkedTexts];
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

- (IBAction)saveDocumentAs:(id)aSender {
	if (![self hasMarkedTexts]) {
		[super saveDocumentAs:aSender];
	}
}

- (IBAction)saveDocument:(id)aSender {
	if (![self hasMarkedTexts]) {
		[super saveDocument:aSender];
	}
}

- (IBAction)saveDocumentTo:(id)aSender {
	if (![self hasMarkedTexts]) {
		[super saveDocumentTo:aSender];
	}
}

- (NSString *)lineEndingString {
    return I_lineEndingString;
}

- (LineEnding)lineEnding {
    return [(FoldableTextStorage *)[self textStorage] lineEnding];
}

// http://developer.apple.com/documentation/Carbon/Conceptual/ATSUI_Concepts/atsui_chap4/chapter_4_section_5.html

- (void)setLineEnding:(LineEnding)newLineEnding {
    [(FoldableTextStorage *)[self textStorage] setLineEnding:newLineEnding];
    I_lineEndingString = [NSString lineEndingStringForLineEnding:newLineEnding];
    [self TCM_sendPlainTextDocumentDidChangeEditStatusNotification];
}

- (void)setLineEndingUndoable:(LineEnding)lineEnding {
    [[self documentUndoManager] beginUndoGrouping];
    [[[self documentUndoManager] prepareWithInvocationTarget:self] setLineEndingUndoable:[self lineEnding]];
    [[self documentUndoManager] endUndoGrouping];
    [self setLineEnding:lineEnding];
}

// caution this call releases its argument because it doesn't seem to work otherwise :(
- (void)setAttributedStringUndoable:(NSAttributedString *)aString {
    [[self documentUndoManager] beginUndoGrouping];
    FullTextStorage *fullTextStorage = [I_textStorage fullTextStorage];
    [[[self documentUndoManager] prepareWithInvocationTarget:self] setAttributedStringUndoable:[fullTextStorage attributedSubstringFromRange:NSMakeRange(0,[fullTextStorage length])]];
    [[self documentUndoManager] endUndoGrouping];
    BOOL previousState = [self isHandlingUndoManually];
    [self setIsHandlingUndoManually:YES];
    [I_textStorage setAttributedString:aString];
    [self setIsHandlingUndoManually:previousState];
}

- (IBAction)chooseLineEndings:(id)aSender {
    [self setLineEndingUndoable:[aSender tag]];
}

- (IBAction)reindentSelection:(id)aSender {
	FullTextStorage *fullTextStorage = [I_textStorage fullTextStorage];
	PlainTextEditor *activeTextEditor = [self activePlainTextEditor];
	NSRange selectionRange = [I_textStorage fullRangeForFoldedRange:[[activeTextEditor textView] selectedRange]];
	
	NSString *tabString = [self usesTabs] ? @"\t" : [@"" stringByPaddingToLength:[self tabWidth] withString:@" " startingAtIndex:0];
    [[self documentUndoManager] beginUndoGrouping];
	[fullTextStorage reindentRange:selectionRange usingTabStringPerLevel:tabString];
    [[self documentUndoManager] endUndoGrouping];
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
        FoldableTextStorage *textStorage=(FoldableTextStorage *)[self textStorage];
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

// ranges are in fulltextstorage
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

// ranges are in fulltextstorage
- (NSRange)rangeOfPrevious:(BOOL)aPrevious changeForRange:(NSRange)aRange {
    NSRange searchRange;
    FullTextStorage *textStorage=[(FoldableTextStorage *)[self textStorage] fullTextStorage];
    NSString *userID=nil;
    unsigned position;
    NSRange fullRange=NSMakeRange(0,[textStorage length]);
    if (aRange.location>=fullRange.length) {
        if (aRange.location>0) aRange.location-=1;
        else return NSMakeRange(NSNotFound,0);
    }
    
    [textStorage attribute:ChangedByUserIDAttributeName atIndex:aRange.location longestEffectiveRange:&searchRange inRange:fullRange];
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
        return I_boldItalicFont;
    } else if (aFontTrait & NSItalicFontMask) {
        return I_italicFont;
    } else if (aFontTrait & NSBoldFontMask) {
        return I_boldFont;
    } else {
        return I_plainFont;
    }
}

- (void)setPlainFont:(NSFont *)aFont {
    [I_styleCacheDictionary autorelease];
    I_styleCacheDictionary = [NSMutableDictionary new];
//    BOOL useDefaultStyle=[[[self documentMode] defaultForKey:DocumentModeUseDefaultStylePreferenceKey] boolValue];
//    BOOL darkBackground=[[[self documentMode] defaultForKey:DocumentModeBackgroundColorIsDarkPreferenceKey] boolValue];
//    NSDictionary *syntaxStyle=[useDefaultStyle?[[DocumentModeManager baseMode] syntaxStyle]:[[self documentMode] syntaxStyle] styleForKey:SyntaxStyleBaseIdentifier];
    SEEStyleSheetSettings *styleSheetSettings = [[self documentMode] styleSheetSettings];
    [self setDocumentBackgroundColor:[styleSheetSettings documentBackgroundColor]];
    [self setDocumentForegroundColor:[styleSheetSettings documentForegroundColor]];
    [I_plainFont autorelease];
    I_plainFont = [aFont copy];
    [self TCM_styleFonts];
    [self TCM_invalidateTextAttributes];
    [self TCM_invalidateDefaultParagraphStyle];
    [[self plainTextEditors] makeObjectsPerformSelector:@selector(adjustDisplayOfPageGuide)];
}


- (NSDictionary *)styleAttributesForScope:(NSString *)aScope languageContext:(NSString *)aLangaugeContext {

//	NSLog(@"%s %@ %@",__FUNCTION__,aScope, aLangaugeContext);
	
	if (!aScope) {
		NSLog(@"%s was called with a aScope of nil",__FUNCTION__);
		return [NSDictionary dictionary];
	}
	
    NSDictionary *result=[I_styleCacheDictionary objectForKey:aScope];
    if (!result) {
        DocumentMode *documentMode=[self documentMode];

        SEEStyleSheet *styleSheet = [documentMode styleSheetForLanguageContext:aLangaugeContext];
        result = [SEEStyleSheet textAttributesForStyleAttributes:[styleSheet styleAttributesForScope:aScope] font:I_plainFont];
        
		if ( aScope && result ) 
			[I_styleCacheDictionary setObject:result forKey:aScope];
    }
    return result;
	
}


- (NSDictionary *)styleAttributesForStyleID:(NSString *)aStyleID {
	if (!aStyleID) {
		NSLog(@"%s was called with a styleID of nil",__FUNCTION__);
		return [NSDictionary dictionary];
	}
    NSMutableDictionary *result=[I_styleCacheDictionary objectForKey:aStyleID];
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
		
		if (![style objectForKey:@"color"]) {
			// This is a style without color, so fall back to scope color.
			style = [I_styleCacheDictionary objectForKey:[style objectForKey:@"scope"]];
			//if (!style) style = [[documentMode syntaxStyle] styleForScope:[style objectForKey:@"scope"]]; // FIXME: if no style then no style objectforkey scope
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
                
        result=[NSMutableDictionary dictionaryWithObjectsAndKeys:font,NSFontAttributeName,
				foregroundColor,NSForegroundColorAttributeName,
            aStyleID,@"styleID",
            [NSNumber numberWithFloat:obliquenessFactor],NSObliquenessAttributeName,
            [NSNumber numberWithFloat:strokeWidth],NSStrokeWidthAttributeName,
            nil];

		NSColor *backgroundColor=[style objectForKey:darkBackground?@"inverted-background-color":@"background-color"];
		if (backgroundColor) {
			[result setObject:backgroundColor forKey:NSBackgroundColorAttributeName];
		}
        
		if ([style objectForKey:NSStrikethroughStyleAttributeName])
			[result setObject:[style objectForKey:NSStrikethroughStyleAttributeName] forKey:NSStrikethroughStyleAttributeName];
		
		if ([style objectForKey:NSUnderlineStyleAttributeName])
			[result setObject:[style objectForKey:NSUnderlineStyleAttributeName] forKey:NSUnderlineStyleAttributeName];
		
		if ([style objectForKey:@"scope"]) {
			[result setObject:[style objectForKey:@"scope"] forKey:kSyntaxHighlightingScopenameAttributeName];
		}
		
		
		// this is necessary for the highlighter to actually set the correct link attribute here
        if ([[style objectForKey:@"type"] isEqualToString:@"url"]) [result setObject:@"link" forKey:NSLinkAttributeName];
			
		if ( aStyleID && result ) 
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
        [attributes addEntriesFromDictionary:[self styleAttributesForScope:SEEStyleSheetMetaDefaultScopeName languageContext:self.documentMode.scriptedName]];
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
        NSFont *font=[sLayoutManager substituteFontForFont:[self fontWithTrait:0]];
		float charWidth = 0.0f;
		if ( font != nil )
			charWidth = [@" " sizeWithAttributes:[NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName]].width;

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
    FullTextStorage *fullTextStorage = [I_textStorage fullTextStorage];
    NSRange wholeRange=NSMakeRange(0,[fullTextStorage length]);
    [fullTextStorage addAttributes:[self plainTextAttributes]
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
    if (!result) {
		result=[[self windowControllers] firstObject];
	}
	if (!result) {
		NSLog(@"%s Warning: wanting a windowController but returning none because we have none.",__FUNCTION__);
	}
    return result;
}


- (void)gotoLine:(unsigned)aLine {
    PlainTextWindowController *windowController=[self topmostWindowController];
    [windowController selectTabForDocument:self];
    [windowController gotoLine:aLine];
}

// dispatches to the plaintexteditor eventually
- (void)selectRange:(NSRange)aRange {
    PlainTextWindowController *windowController=[self topmostWindowController];
    [windowController selectTabForDocument:self];
    [windowController selectRange:aRange];
}

// dispatches to the plaintexteditor eventually
- (void)selectRangeInBackground:(NSRange)aRange {
    PlainTextWindowController *windowController=[self topmostWindowController];
    [windowController selectTabForDocument:self];
    [windowController selectRangeInBackground:aRange];
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

- (NSArray *)findAllControllers {
	NSArray *result = [[I_findAllControllers copy] autorelease];
	return result;
}

- (NSURL *)documentURLForGroup:(NSString *)aGroup {
    if (![[self session] isServer]) {
        return nil;
    }

	NSURL *applicationConnectionURL = [SEEConnectionManager applicationConnectionURL];
	if (! applicationConnectionURL) {
		return nil;
	}

	NSMutableString *address = [[[applicationConnectionURL absoluteString] mutableCopy] autorelease];

	NSString *title = [self.fileURL.path lastPathComponent];
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
        [address appendFormat:@"?%@=%@", @"sessionID", escapedDocumentId];

        if (aGroup) {
            NSString *token = [[self session] invitationTokenForGroup:aGroup];
            NSString *escapedToken = (NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)token, NULL, CFSTR(";/?:@&=+,$"), kCFStringEncodingUTF8);
            if (escapedToken) {
                [escapedToken autorelease];
                [address appendFormat:@"&token=%@",escapedToken];
            }
        }

    }

    DEBUGLOG(@"InternetLogLevel", DetailedLogLevel, @"address: %@", address);
    if (address != nil && [address length] > 0) {
        NSURL *url = [NSURL URLWithString:address];
        DEBUGLOG(@"InternetLogDomain", DetailedLogLevel, @"url: %@", [url description]);
        return url;
    }

    return nil;
}

- (NSURL *)documentURL {
    return [self documentURLForGroup:nil];
}

#pragma mark -

+ (NSString *)displayStringWithAdditionalPathComponentsForPathComponents:(NSArray *)aPathComponentsArray {
	NSString *result = nil;
	NSInteger count = (NSInteger)[aPathComponentsArray count];
	if (count > 0) {
		if (count==1) {
			result = aPathComponentsArray.lastObject;
		} else {
			NSMutableString *mutableResult = [NSMutableString string];
			NSInteger i = 0;
			NSInteger pathComponentsToShow = [[NSUserDefaults standardUserDefaults] integerForKey:AdditionalShownPathComponentsPreferenceKey] + 1;
			for (i = count-1; i >= 1 && i > count-pathComponentsToShow-1; i--) {
				if (i != count-1) {
					[mutableResult insertString:@"/" atIndex:0];
				}
				[mutableResult insertString:aPathComponentsArray[i] atIndex:0];
			}
			if (pathComponentsToShow>1 && i<1 && [aPathComponentsArray[0] isEqualToString:@"/"]) {
				[mutableResult insertString:@"/" atIndex:0];
			}
			result = [[mutableResult copy] autorelease];
		}
	}
	return result;
}

- (NSString *)preparedDisplayName {
    NSArray *pathComponents = nil;
	NSString *result = nil;
    if ([self fileURL]) {
        pathComponents = [self.fileURL.path pathComponents];
    } else if ([self temporaryDisplayName]) {
        pathComponents = [[self temporaryDisplayName] pathComponents];
    } 
    
	result = [PlainTextDocument displayStringWithAdditionalPathComponentsForPathComponents:pathComponents];
	if (!result) {
		result = [self displayName];
	}

	return result;
}

- (NSString *)displayName {
    if ([self temporaryDisplayName] && ![self fileURL]) {
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
    if (!I_flags.isSettingFileURL) {
        if (![self fileURL]) {
            [self setTemporaryDisplayName:aDisplayName];
        } else {
            [self setFileURL:[NSURL fileURLWithPath:[[self.fileURL.path stringByDeletingLastPathComponent] stringByAppendingPathComponent:aDisplayName]]];
        }
    }
    if ([[super class] instancesRespondToSelector:_cmd]) { // _cmd is always the current selector
//        NSLog(@"%s oh look, super supports us!",__FUNCTION__);
        [super setDisplayName:aDisplayName];
    }
	[self invalidateRestorableState];
}

#pragma mark -
#pragma mark ### Printing ###

- (NSPrintOperation *)printOperationWithSettings:(NSDictionary *)printSettings error:(NSError **)outError
{
	NSPrintOperation *printOperation = [NSPrintOperation printOperationWithView:[self printableView]];
    
    SEEPrintOptionsViewController *printPanelAccessory = [[[SEEPrintOptionsViewController alloc] initWithNibName:nil bundle:nil] autorelease];
    printPanelAccessory.document = self;

    NSPrintPanel *printPanel = [printOperation printPanel];
    [printPanel addAccessoryController:printPanelAccessory];
	
    return printOperation;
}

- (NSView *)printableView {
    // make sure everything is colored if it should be
    MultiPagePrintView *printView = [[MultiPagePrintView alloc] initWithFrame:NSMakeRect(0.0, 0.0, 100.0, 100.0) document:self];
    return [printView autorelease];
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
	[self invalidateRestorableState];
}


// wrapline setting is only for book keeping - editor scope
- (BOOL)wrapLines {
    return I_flags.wrapLines;
}

- (void)setWrapLines:(BOOL)aFlag {
    if (I_flags.wrapLines!=aFlag) {
        I_flags.wrapLines=aFlag;
        [self TCM_sendPlainTextDocumentDidChangeEditStatusNotification];
		[self invalidateRestorableState];
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
		[self invalidateRestorableState];
    }
}

- (void)setUsesTabs:(BOOL)aFlag {
    if (I_flags.usesTabs!=aFlag) {
        I_flags.usesTabs=aFlag;
        [self TCM_sendPlainTextDocumentDidChangeEditStatusNotification];
		[self invalidateRestorableState];
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
	[self invalidateRestorableState];
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
	[self invalidateRestorableState];
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
		[self invalidateRestorableState];
    }
}

- (void)takeSpellCheckingSettingsFromEditor:(PlainTextEditor *)anEditor {
	SEETextView *textView = (SEETextView *)[anEditor textView];
	NSMutableDictionary *modeDefaults = [[self documentMode] defaults];
	[modeDefaults setObject:[NSNumber numberWithBool:[textView isContinuousSpellCheckingEnabled]] forKey:DocumentModeSpellCheckingPreferenceKey];
	
	NSDictionary *attributeForDefaultKeyDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
		DocumentModeGrammarCheckingPreferenceKey,@"isGrammarCheckingEnabled",
		DocumentModeAutomaticLinkDetectionPreferenceKey,@"isAutomaticLinkDetectionEnabled",
		DocumentModeAutomaticDashSubstitutionPreferenceKey,@"isAutomaticDashSubstitutionEnabled",
		DocumentModeAutomaticQuoteSubstitutionPreferenceKey,@"isAutomaticQuoteSubstitutionEnabled",
		DocumentModeAutomaticTextReplacementPreferenceKey,@"isAutomaticTextReplacementEnabled",
		DocumentModeAutomaticSpellingCorrectionPreferenceKey,@"isAutomaticSpellingCorrectionEnabled",
		nil];
	NSEnumerator *keyEnumerator = [attributeForDefaultKeyDictionary keyEnumerator];
	NSString *attributeString = nil;
	while ((attributeString = [keyEnumerator nextObject])) {
		NSString *defaultKey = [attributeForDefaultKeyDictionary objectForKey:attributeString];
		if ([textView respondsToSelector:NSSelectorFromString(attributeString)]) {
			[modeDefaults setObject:[textView valueForKey:attributeString] forKey:defaultKey];
//			NSLog(@"%s set %@ for %@ now %@",__FUNCTION__,attributeString, defaultKey, [textView valueForKey:attributeString]);
		}
	}
//	NSLog(@"%s %@",__FUNCTION__,modeDefaults);
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


- (BOOL)isPreparedForTermination {
	return I_flags.isPreparedForTermination;
}

- (void)setPreparedForTermination:(BOOL)aFlag {
	I_flags.isPreparedForTermination = aFlag;
}


#pragma mark -

- (void)alertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    NSDictionary *alertContext = [(NSDictionary *)contextInfo autorelease];
    NSString *alertIdentifier = [alertContext objectForKey:@"Alert"];
    DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel, @"alertDidEnd: %@", alertIdentifier);

    if ([alertIdentifier isEqualToString:@"ShouldPromoteAlert"]) {
        NSTextView *textView = [alertContext objectForKey:@"TextView"];
        NSString *replacementString = [alertContext objectForKey:@"ReplacementString"];
		NSRange affectedRange = [[alertContext objectForKey:@"AffectedCharRange"] rangeValue];
        if (returnCode == NSAlertThirdButtonReturn) {
            [self setFileEncodingUndoable:NSUnicodeStringEncoding];
            if (replacementString) {
				[textView setSelectedRange:affectedRange];
				[textView insertText:replacementString];
			}
        } else if (returnCode == NSAlertSecondButtonReturn) {
            [self setFileEncodingUndoable:NSUTF8StringEncoding];
            if (replacementString) {
				[textView setSelectedRange:affectedRange];
				[textView insertText:replacementString];
			}
        } else if (returnCode == NSAlertFirstButtonReturn) {
            NSData *lossyData = [replacementString dataUsingEncoding:[self fileEncoding] allowLossyConversion:YES];
            if (lossyData) {
				[textView setSelectedRange:affectedRange];
				[textView insertText:[NSString stringWithData:lossyData encoding:[self fileEncoding]]];
			}
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
}

- (void)applicationDidBecomeActive:(NSNotification *)aNotification {
    DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel, @"applicationDidBecomeActive: %@", [self fileURL]);
    if (![self fileURL]) {
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
		transientDocumentWindowFrame = NSZeroRect;
		
		PlainTextWindowController *windowController = self.windowControllers.firstObject;
		windowController.window.restorable = YES;
		
		[[SEEDocumentController sharedInstance] documentListWindow].restorable = YES;
	}

    if (changeType == NSChangeCleared || changeType == NSChangeAutosaved || I_flags.shouldChangeChangeCount) {
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
        if (newMode) {
            [self setDocumentMode:newMode];
            I_flags.shouldSelectModeOnSave=NO;
        } else {
            [[self plainTextEditors] makeObjectsPerformSelector:@selector(TCM_updateBottomStatusBar)];
        }

    }
}

- (void)setHighlightsSyntax:(BOOL)aFlag {
    if (I_flags.highlightSyntax != aFlag) {
    	FullTextStorage *fts = [I_textStorage fullTextStorage];
        I_flags.highlightSyntax = aFlag;
        if (I_flags.highlightSyntax) {
            [self highlightSyntaxInRange:NSMakeRange(0,[fts length])];
        } else {
            [[I_documentMode syntaxHighlighter] cleanUpTextStorage:fts];
            [fts addAttributes:[self plainTextAttributes]
                                   range:NSMakeRange(0,[fts length])];
        }
    }
}

- (BOOL)highlightsSyntax {
    return I_flags.highlightSyntax;
}

- (IBAction)toggleSyntaxHighlighting:(id)aSender {
    [self setHighlightsSyntax:![self highlightsSyntax]];
}

// this method expects ranges of the fulltextstorage
- (void)highlightSyntaxInRange:(NSRange)aRange {
    if (I_flags.highlightSyntax) {
    	FullTextStorage *fts = [I_textStorage fullTextStorage];
        NSRange range=NSIntersectionRange(aRange,NSMakeRange(0,[fts length]));
        if (range.length>0) {
            [fts removeAttribute:kSyntaxHighlightingIsCorrectAttributeName range:range synchronize:NO];
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
        float delay = MIN(3.,[[[SEEDocumentController sharedInstance] documents] count]*0.3);
        if ([[[NSApp mainWindow] windowController] document] == self) {
            delay = 0.0;
            if (!I_flags.textDidChangeSinceLastSyntaxHighlighting) {
                // if we don't have a recent change take our time (but still be as quick as 2.6.5
                delay = 0.3;
            }
        }
        if ([NSThread isMainThread]) {
	        [self performSelector:@selector(highlightSyntaxLoop) withObject:nil afterDelay:delay];
			I_flags.isPerformingSyntaxHighlighting=YES;
		} else {
			[self performSelectorOnMainThread:@selector(performHighlightSyntax) withObject:nil waitUntilDone:NO];
		}
    }
}

- (void)highlightSyntaxLoop {
    I_flags.isPerformingSyntaxHighlighting=NO;
    if (I_flags.highlightSyntax) {
        SyntaxHighlighter *highlighter=[I_documentMode syntaxHighlighter];
        if (highlighter) {
            if (!I_flags.syntaxHighlightingIsSuspended) {
                if (![highlighter colorizeDirtyRanges:[I_textStorage fullTextStorage] ofDocument:self]) {
                    I_flags.textDidChangeSinceLastSyntaxHighlighting = NO;
                    [self performHighlightSyntax];
                } else {
                	// tell the gutter to show stuff
					[[self plainTextEditors] makeObjectsPerformSelector:@selector(setNeedsDisplayForRuler) withObject:nil];
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
    NSEnumerator *writingParticipants=[[[session participants] objectForKey:TCMMMSessionReadWriteGroupName] objectEnumerator];
    TCMMMUser *user=nil;
    while ((user=[writingParticipants nextObject])) {
        SelectionOperation *selectionOperation=[[user propertiesForSessionID:sessionID] objectForKey:@"SelectionOperation"];
        if (selectionOperation) {
            [aState handleOperation:selectionOperation];
        }
    }

    [aState handleOperation:[SelectionOperation selectionOperationWithRange:[[[self activePlainTextEditor] textView] selectedRange] userID:[TCMMMUserManager myUserID]]];
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
    I_flags.isReceivingContent = YES;
    [windowController document:self isReceivingContent:YES];
    
	BOOL closeTransientDocument = transientDocument
	&& NSEqualRects(transientDocumentWindowFrame, [[[transientDocument topmostWindowController] window] frame])
	&& [[[NSUserDefaults standardUserDefaults] objectForKey:OpenDocumentOnStartPreferenceKey] boolValue];
	
	if (closeTransientDocument) {
		NSWindow *window = [[self topmostWindowController] window];
		[window setFrameTopLeftPoint:NSMakePoint(transientDocumentWindowFrame.origin.x, NSMaxY(transientDocumentWindowFrame))];
		[transientDocument close];
	} else if (![[windowController window] isVisible]) {
        [windowController cascadeWindow];
    }
    [I_documentProxyWindowController dissolveToWindow:[windowController window]];
	
	if (closeTransientDocument) {
		transientDocument = nil;
		transientDocumentWindowFrame = NSZeroRect;

		PlainTextWindowController *windowController = self.windowControllers.firstObject;
		windowController.window.restorable = YES;
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


- (NSMutableDictionary *)stateDataBaseDictionary {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSMutableDictionary *stateDictionary = [NSMutableDictionary dictionary];
	PlainTextEditor *activeTextEditor = [self activePlainTextEditor];
	DocumentMode *mode = [self documentMode];

	NSRange selectionRange = [I_textStorage fullRangeForFoldedRange:[[activeTextEditor textView] selectedRange]];
	
	if ([defaults boolForKey:DocumentStateSaveAndLoadSelectionKey]) {
		[stateDictionary setObject:[NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithUnsignedInt:selectionRange.location],@"p", //position
			[NSNumber numberWithUnsignedInt:selectionRange.length]  ,@"l", //length
			nil] forKey:@"s"];
	}
	
	
	if ([defaults boolForKey:DocumentStateSaveAndLoadWindowPositionKey]) {
		NSRect windowFrame = [[[activeTextEditor textView] window] frame];
		
		[stateDictionary setObject:[NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithInt:windowFrame.origin.x],@"x", //x
			[NSNumber numberWithInt:windowFrame.origin.y],@"y", //y
			[NSNumber numberWithInt:windowFrame.size.width],@"w", //w
			[NSNumber numberWithInt:windowFrame.size.height],@"h", //h
			nil] forKey:@"p"]; // window position
	}

	if ([defaults boolForKey:DocumentStateSaveAndLoadTabSettingKey]) {
		BOOL documentValue = [self usesTabs];
		BOOL modeValue = [[mode defaultForKey:DocumentModeUseTabsPreferenceKey] boolValue];
			
		[stateDictionary setObject:[NSNumber numberWithInt:[self lineEnding]] forKey:@"e"];
	
		if (((documentValue && !modeValue) || (!documentValue && modeValue)) ||
			([self tabWidth] != [[mode defaultForKey:DocumentModeTabWidthPreferenceKey] intValue])) {
			NSDictionary *tabValuesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				[NSNumber numberWithInt:documentValue ? 1 : 0],@"u",
				[NSNumber numberWithInt:[self tabWidth]],@"w",
			nil];
			[stateDictionary setObject:tabValuesDictionary forKey:@"t"];
		}
	}

	return stateDictionary;
}

// this is the data stored in the seetext file format
- (NSDictionary *)documentState {
    NSMutableDictionary *result = [[[self sessionInformation] mutableCopy] autorelease];
    [result removeObjectForKey:@"FileType"]; // don't save the filetype in a seetext
    [result setObject:[NSNumber numberWithBool:[self showsChangeMarks]]
               forKey:HighlightChangesPreferenceKey];
    [result setObject:[NSNumber numberWithBool:[self showsGutter]]
               forKey:DocumentModeShowLineNumbersPreferenceKey];
    [result setObject:[NSNumber numberWithBool:[self showInvisibleCharacters]]
               forKey:DocumentModeShowInvisibleCharactersPreferenceKey];
    [result setObject:[NSNumber numberWithBool:[self highlightsSyntax]]
               forKey:DocumentModeHighlightSyntaxPreferenceKey];

    NSMutableDictionary *stateDictionary = [self stateDataBaseDictionary];

	if ([stateDictionary count]) {
		[result setObject:stateDictionary forKey:@"stateDataDictionary"];
	}
    
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
    
    value = [aDocumentState objectForKey:@"stateDataDictionary"];
    if ([value isKindOfClass:[NSDictionary class]]) {
    	I_stateDictionaryFromLoading = [value retain];	
    }    
}

// this is the data stored in the extended attributes - which differs from the seetext format data
// used keys:
//  p: window position (window Frame as (dict with x,y,w,h))
//  l: textstorage length (to check if folding data may be applied)
//  f: foldingData
//  s: selection (in full text range)
//  m: document mode identifier
//  e: line ending
//  w: wraps lines - 0:no 1:wordwrap 2:characterwrap
//  t: tabsettings (dict with w:<int> u:0|1)
//  g: shows gutter

- (NSData *)stateData {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSMutableDictionary *stateDictionary = [self stateDataBaseDictionary];
	PlainTextEditor *activeTextEditor = [self activePlainTextEditor];
		
	DocumentMode *mode = [self documentMode];
		
	if ([defaults boolForKey:DocumentStateSaveAndLoadDocumentModeKey]) {
		if (![mode isBaseMode]) {
			// save the mode if it is not the base mode
			[stateDictionary setObject:[[self documentMode] documentModeIdentifier] forKey:@"m"];
		}
	}
	
	BOOL documentValue = NO;
	BOOL modeValue = NO;
	
	if ([defaults boolForKey:DocumentStateSaveAndLoadWrapSettingKey]) {
		documentValue = [self wrapLines];
		modeValue = [[mode defaultForKey:DocumentModeWrapLinesPreferenceKey] boolValue];
		if ((documentValue && !modeValue) || (!documentValue && modeValue)) {
			NSNumber *wrapSetting = [NSNumber numberWithInt:0];
			if (documentValue) {
				wrapSetting = [NSNumber numberWithInt:[self wrapMode]==DocumentModeWrapModeCharacters ? 2 : 1];
			}
			[stateDictionary setObject:wrapSetting forKey:@"w"];
		}
	}
	
	documentValue = [activeTextEditor showsGutter];
	modeValue = [[mode defaultForKey:DocumentModeShowLineNumbersPreferenceKey] boolValue];
	if ((documentValue && !modeValue) || (!documentValue && modeValue)) {
		[stateDictionary setObject:[NSNumber numberWithInt:documentValue ? 1 : 0] forKey:@"g"];
	}
		
	if ([defaults boolForKey:DocumentStateSaveAndLoadFoldingStateKey]) {
		[stateDictionary setObject:[NSNumber numberWithUnsignedInt:[[I_textStorage fullTextStorage] length]] forKey:@"l"]; // characterlength
		NSData *foldingStateData = [I_textStorage dataRepresentationOfFoldedRangesWithMaxDepth:-1];
		if (foldingStateData && [foldingStateData length]) {
			[stateDictionary setObject:foldingStateData forKey:@"f"]; // foldingstatedata
		}
	}
	
	// here we could check our xtended attribute data for length and use less depth with the foldings 
//	NSLog(@"%s %@",__FUNCTION__,stateDictionary);
	return TCM_BencodedObject(stateDictionary);
}


- (void)setFileURL:(NSURL *)aFileURL {
    I_flags.isSettingFileURL = YES;
    [super setFileURL:aFileURL];
    TCMMMSession *session=[self session];
    if ([session isServer]) {
        [session setFilename:[self preparedDisplayName]];
    }
    I_flags.isSettingFileURL = NO;
}

- (NSDictionary *)textStorageDictionaryRepresentation
{
    return [(FoldableTextStorage *)[self textStorage] dictionaryRepresentation];
}

- (void)setContentByDictionaryRepresentation:(NSDictionary *)aRepresentation {
    I_flags.isRemotelyEditingTextStorage=YES;
	{
		FoldableTextStorage *textStorage=(FoldableTextStorage *)[self textStorage];
		[textStorage setContentByDictionaryRepresentation:[aRepresentation objectForKey:@"TextStorage"]];
		NSRange wholeRange=NSMakeRange(0,[textStorage length]);
		[textStorage addAttributes:[self plainTextAttributes] range:wholeRange];
		[textStorage addAttribute:NSParagraphStyleAttributeName value:[self defaultParagraphStyle] range:wholeRange];
	}
    I_flags.isRemotelyEditingTextStorage=NO;

    [self TCM_sendPlainTextDocumentDidChangeEditStatusNotification];
	[self updateChangeCount:NSChangeCleared];
	I_flags.shouldSelectModeOnSave = NO;
	I_flags.shouldChangeExtensionOnModeChange = NO;
}

- (void)session:(TCMMMSession *)aSession didReceiveContent:(NSDictionary *)aContent {
    if ([[self windowControllers] count]>0) {
        [self setContentByDictionaryRepresentation:aContent];

		[self autosaveForStateRestore];

        I_flags.isReceivingContent = NO;
        PlainTextWindowController *windowController=(PlainTextWindowController *)[[self windowControllers] objectAtIndex:0];
        [windowController document:self isReceivingContent:NO];

		[[self topmostWindowController] openParticipantsOverlayForDocument:self];
		if ([[NSUserDefaults standardUserDefaults] boolForKey:HighlightChangesPreferenceKey]) {
			NSEnumerator *plainTextEditors=[[self plainTextEditors] objectEnumerator];
			PlainTextEditor *editor=nil;
			while ((editor=[plainTextEditors nextObject])) {
				[editor setShowsChangeMarks:YES];
			}
		}
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


- (PlainTextEditor *)activePlainTextEditor {
    return [[self topmostWindowController] activePlainTextEditorForDocument:self];
}


- (NSArray *)plainTextEditors {
    NSMutableArray *result = [NSMutableArray array];
    NSEnumerator *windowControllers = [[self windowControllers] objectEnumerator];
    PlainTextWindowController *windowController;
    while ((windowController = [windowControllers nextObject])) 
	{
		[result addObjectsFromArray:[windowController plainTextEditorsForDocument:self]];
	}
    return result;
}

- (BOOL)handleOperation:(TCMMMOperation *)aOperation {
    if ([[aOperation operationID] isEqualToString:[TextOperation operationID]]) {
        TextOperation *operation=(TextOperation *)aOperation;
		FullTextStorage *fullTextStorage = [I_textStorage fullTextStorage];
    
        // check validity of operation
        if (NSMaxRange([operation affectedCharRange])>[fullTextStorage length]) {
            NSLog(@"User tried to change text outside the document bounds:%@ %@",operation,[[TCMMMUserManager sharedInstance] userForUserID:[operation userID]]);
            return NO;
        }
    
        // gather selections from all textviews and transform them
        NSArray *editors=[self plainTextEditors];
        I_flags.isRemotelyEditingTextStorage=![[aOperation userID] isEqualToString:[TCMMMUserManager myUserID]];
        NSMutableArray   *oldSelections=[NSMutableArray array];
        if (I_flags.isRemotelyEditingTextStorage) {
            PlainTextEditor *editor=nil;
            for (editor in editors) {
                [oldSelections addObject:[SelectionOperation selectionOperationWithRange:[[editor textView] selectedRange] userID:@"doesn't matter"]];
                [editor storePosition];
            }
        }

        [fullTextStorage beginEditing];
        NSRange newRange=NSMakeRange([operation affectedCharRange].location,
                                     [[operation replacementString] length]);
        [fullTextStorage replaceCharactersInRange:[operation affectedCharRange]
                                   withString:[operation replacementString]];
        [fullTextStorage addAttribute:WrittenByUserIDAttributeName value:[operation userID]
                            range:newRange];
        [fullTextStorage addAttribute:ChangedByUserIDAttributeName value:[operation userID]
                            range:newRange];
        [fullTextStorage addAttributes:[fullTextStorage attributeDictionaryByAddingStyleAttributesForInsertLocation:newRange.location toDictionary:[self plainTextAttributes]] range:newRange];
        [fullTextStorage endEditing];


        if (I_flags.isRemotelyEditingTextStorage) {
            // set selection of all textviews
            TCMMMTransformator *transformator=[TCMMMTransformator sharedInstance];
            int index=0;
            for (index=0;index<(int)[editors count];index++) {
                SelectionOperation *selectionOperation = [oldSelections objectAtIndex:index];
                [transformator transformOperation:selectionOperation serverOperation:aOperation];
                PlainTextEditor *editor = [editors objectAtIndex:index];
                [[editor textView] setSelectedRange:[selectionOperation selectedRange]];
                [editor restorePositionAfterOperation:aOperation];
            }
        }

        if (I_flags.isRemotelyEditingTextStorage) {
            [[self documentUndoManager] transformStacksWithOperation:operation];
        }
        I_flags.isRemotelyEditingTextStorage=NO;
    } else if ([[aOperation operationID] isEqualToString:[SelectionOperation operationID]]){
        NSArray *editors=[self plainTextEditors];

		[editors makeObjectsPerformSelector:@selector(storePosition) withObject:nil];

        [self changeSelectionOfUserWithID:[aOperation userID]
              toRange:[(SelectionOperation *)aOperation selectedRange]];

		[editors makeObjectsPerformSelector:@selector(restorePositionAfterOperation:) withObject:aOperation];
    }
    return YES;
}

- (void)undoManagerDidPerformUndoGroupWithLastOperation:(TextOperation *)aOperation {
	// adjust selection to be after the changed character or if it was more than one character select the whole text
	NSTextView *textView = [[self activePlainTextEditor] textView];
	NSRange rangeToSelect = NSMakeRange([aOperation affectedCharRange].location,[[aOperation replacementString] length]);
	if ([[self documentUndoManager] isRedoing]) {
		rangeToSelect.location += rangeToSelect.length;
		rangeToSelect.length = 0;
	}
	[textView setSelectedRange:[I_textStorage foldedRangeForFullRange:rangeToSelect]];
	[textView scrollRangeToVisible:[textView selectedRange]];
}


#pragma mark - Invite Users

- (IBAction)inviteUsersToDocumentViaSharingService:(id)sender {
	NSURL *documentSharingURL = [self documentURL];
	NSArray *sharingServiceItems = @[];
	if (documentSharingURL && self.isAnnounced) {
		sharingServiceItems = @[documentSharingURL];
	}

	NSSharingServicePicker *servicePicker = [[[NSSharingServicePicker alloc] initWithItems:sharingServiceItems] autorelease];
	[servicePicker setDelegate:self];
	[servicePicker showRelativeToRect:NSZeroRect ofView:sender preferredEdge:CGRectMaxYEdge];
}


- (BOOL)invitePeopleFromPasteboard:(NSPasteboard *)aPasteboard {
	BOOL success = NO;
	if ([[aPasteboard types] containsObject:@"IMHandleNames"]) {
		NSArray *presentityNames= [aPasteboard propertyListForType:@"IMHandleNames"];
		NSUInteger i=0;

		NSSharingService *service = [NSSharingService sharingServiceNamed:NSSharingServiceNameComposeMessage];
		service.delegate = self;
		NSMutableArray *recipients = [NSMutableArray array];
		for (i=0;i<[presentityNames count];i+=4) {
//			NSString *serviceID = presentityNames[i];
//			NSString *accountID = presentityNames[i+1];
//			// don't know the format of the recipients field, so leave it blank and the user has to paste it in
//			[recipients addObject:[@"bonjour://" stringByAppendingString:accountID]];
//			[self sendInvitationToServiceWithID:[presentityNames objectAtIndex:i] buddy:[presentityNames objectAtIndex:i+1] url:aURL];
		}
		service.recipients = recipients;
//		service.recipients = @[@"bonjour:something"];
		[service performWithItems:@[[self documentURLForGroup:TCMMMSessionReadWriteGroupName]]];
		success = YES;
	}

	return success;
}


#pragma mark - NSSharingServiceDelegate

- (void)sharingService:(NSSharingService *)sharingService didShareItems:(NSArray *)items
{
	[[self topmostWindowController] openParticipantsOverlayForDocument:self];
	if ([[NSUserDefaults standardUserDefaults] boolForKey:HighlightChangesPreferenceKey]) {
		NSEnumerator *plainTextEditors=[[self plainTextEditors] objectEnumerator];
		PlainTextEditor *editor=nil;
		while ((editor=[plainTextEditors nextObject])) {
			[editor setShowsChangeMarks:YES];
		}
	}
}

- (NSRect)sharingService:(NSSharingService *)sharingService sourceFrameOnScreenForShareItem:(id <NSPasteboardWriting>)item {
	NSArray *windowControllers = [self windowControllers];
	if (windowControllers.count > 0) {
		NSWindow *window = [[windowControllers objectAtIndex:0] window];
		NSView *windowView = [[window contentView] superview];
		return [window convertRectToScreen:[windowView convertRect:[windowView frame] toView:nil]];
	}
	return NSZeroRect;
}

- (NSImage *)sharingService:(NSSharingService *)sharingService transitionImageForShareItem:(id <NSPasteboardWriting>)item contentRect:(NSRect *)contentRect {
	NSArray *windowControllers = [self windowControllers];
	if (windowControllers.count > 0) {
		NSWindow *window = [[windowControllers objectAtIndex:0] window];
		NSView *windowView = [[window contentView] superview];
		NSBitmapImageRep *bitmapRep = [windowView bitmapImageRepForCachingDisplayInRect:[windowView visibleRect]];
		[windowView cacheDisplayInRect:[windowView visibleRect] toBitmapImageRep:bitmapRep];
		NSImage *image = [[[NSImage alloc] initWithSize:[windowView bounds].size] autorelease];
		[image addRepresentation:bitmapRep];
		return image;
	}
	return nil;
}

- (NSWindow *)sharingService:(NSSharingService *)sharingService sourceWindowForShareItems:(NSArray *)items sharingContentScope:(NSSharingContentScope *)sharingContentScope {
	NSArray *windowControllers = [self windowControllers];
	if (windowControllers.count > 0)
		return [[windowControllers objectAtIndex:0] window];
	return nil;
}


#pragma mark - NSSharingServicePickerDelegate

- (NSArray *)sharingServicePicker:(NSSharingServicePicker *)sharingServicePicker sharingServicesForItems:(NSArray *)items proposedSharingServices:(NSArray *)proposedServices {
	NSMutableArray *sharingServices = [[proposedServices mutableCopy] autorelease];

	if (self.session.isServer) {
		NSArray *allConnections = [[SEEConnectionManager sharedInstance] entries];
		for (SEEConnection *connection in allConnections) {
			{
				if (connection.isVisible) {
					TCMMMUser *user = connection.user;

					NSString *sharingServiceTitle = [NSString stringWithFormat:NSLocalizedString(@"Invite %@", @"Invitation format string used in sharing service picker. %@ will be replaced with the user name."), [user name]];
					NSImage *userImage = [user image];
					NSSharingService *customSharingService = [[[NSSharingService alloc] initWithTitle:sharingServiceTitle image:userImage alternateImage:nil handler:^{
						TCMBEEPSession *BEEPSession = [[TCMMMBEEPSessionManager sharedInstance] sessionForUserID:[user userID]];// peerAddressData:[userDescription objectForKey:@"PeerAddressData"]];
						[self setPlainTextEditorsShowChangeMarksOnInvitation];
						[self.session inviteUser:user intoGroup:TCMMMSessionReadWriteGroupName usingBEEPSession:BEEPSession];
					}] autorelease];

					[sharingServices insertObject:customSharingService atIndex:0];
				}
			}
		}
	}

	// check if we have a mapped public URL
	BOOL hasPublicURL = NO;
	TCMPortMapper *pm = [TCMPortMapper sharedInstance];
	TCMPortMapping *mapping = [[pm portMappings] anyObject];
	if (([mapping mappingStatus] == TCMPortMappingStatusMapped) && [pm externalIPAddress] && ![[pm externalIPAddress] isEqual:@"0.0.0.0"] && ([mapping externalPort] > 0)) {
		hasPublicURL = YES;
	}

	if (! hasPublicURL) { // if we don't have a public URL remove also email and messages
		[sharingServices removeObject:[NSSharingService sharingServiceNamed:NSSharingServiceNameComposeEmail]];
		[sharingServices removeObject:[NSSharingService sharingServiceNamed:NSSharingServiceNameComposeMessage]];
	}

	// remove Safari Reading List entry if available...
	[sharingServices removeObject:[NSSharingService sharingServiceNamed:NSSharingServiceNameAddToSafariReadingList]];

	// remove social media entries, because they need persistant URLS and change the see:// scheme.
	[sharingServices removeObject:[NSSharingService sharingServiceNamed:NSSharingServiceNamePostOnFacebook]];
	[sharingServices removeObject:[NSSharingService sharingServiceNamed:NSSharingServiceNamePostOnTwitter]];
	[sharingServices removeObject:[NSSharingService sharingServiceNamed:NSSharingServiceNamePostOnSinaWeibo]];
	[sharingServices removeObject:[NSSharingService sharingServiceNamed:NSSharingServiceNamePostOnTencentWeibo]];
	[sharingServices removeObject:[NSSharingService sharingServiceNamed:NSSharingServiceNamePostOnLinkedIn]];

	if (! self.isAnnounced && self.session.isServer && self.documentURL) {
		NSString *sharingServiceTitle = NSLocalizedString(@"Advertise Document", @"Advertise document string used in sharing service picker.");
		NSImage *sharingServiceImage = [NSImage imageNamed:@"SharingServiceAnnounceMenuIcon"];
		NSSharingService *customSharingService = [[[NSSharingService alloc] initWithTitle:sharingServiceTitle image:sharingServiceImage alternateImage:nil handler:^{
			[self toggleIsAnnounced:self];
		}] autorelease];

		[sharingServices addObject:customSharingService];
	}

	return sharingServices;
}

- (id <NSSharingServiceDelegate>)sharingServicePicker:(NSSharingServicePicker *)sharingServicePicker delegateForSharingService:(NSSharingService *)sharingService {
	return self;
}

#pragma mark -
#pragma mark ### TextStorage Delegate Methods ###
- (void)textStorageDidChangeNumberOfTopLevelFoldings:(FoldableTextStorage *)aFoldableTextStorage {
	// currently just ensure the gutter updates
	[[self plainTextEditors] makeObjectsPerformSelector:@selector(setNeedsDisplayForRuler) withObject:nil];
}

// these delegate methods return ranges regarding the fullTextStorage, and also return it

- (void)textStorage:(FullTextStorage *)aTextStorage willReplaceCharactersInRange:(NSRange)aRange withString:(NSString *)aString {
//    NSLog(@"textStorage:%@ willReplaceCharactersInRange:%@ withString:%@",aTextStorage,NSStringFromRange(aRange),aString);
	[I_session setLastReplacedAttributedString:[aTextStorage attributedSubstringFromRange:aRange]];
    if (!I_flags.isRemotelyEditingTextStorage && !I_flags.isReadingFile && !I_flags.isHandlingUndoManually) {
    	FullTextStorage *fullTextStorage = (FullTextStorage *)aTextStorage;
    
        TextOperation *operation=[TextOperation textOperationWithAffectedCharRange:aRange replacementString:aString userID:(NSString *)[TCMMMUserManager myUserID]];
        UndoManager *undoManager=[self documentUndoManager];
        BOOL shouldGroup=YES;
        if (![undoManager isRedoing] && ![undoManager isUndoing]) {
            shouldGroup=[operation shouldBeGroupedWithTextOperation:I_lastRegisteredUndoOperation];
        }
        [undoManager registerUndoChangeTextInRange:NSMakeRange(aRange.location,[aString length])
                     replacementString:[[fullTextStorage string] substringWithRange:aRange] shouldGroupWithPriorOperation:shouldGroup];
        [I_lastRegisteredUndoOperation release];
        I_lastRegisteredUndoOperation = [operation retain];
    }
}


- (void)textStorage:(FullTextStorage *)aTextStorage didReplaceCharactersInRange:(NSRange)aRange withString:(NSString *)aString {
//    NSLog(@"textStorage:%@ didReplaceCharactersInRange:%@ withString:%@\n\n%d==%d?",aTextStorage,NSStringFromRange(aRange),aString, [aTextStorage length], [aString length]);

	FullTextStorage *fullTextStorage = (FullTextStorage *)aTextStorage;
    TextOperation *textOp=[TextOperation textOperationWithAffectedCharRange:aRange replacementString:aString userID:[TCMMMUserManager myUserID]];
    if (!I_flags.isRemotelyEditingTextStorage) {
        [[self session] documentDidApplyOperation:textOp];
    } 
    
    if ([fullTextStorage length]==[aString length]) { // complete replacement needs basic attributes set again
        [fullTextStorage addAttributes:[self plainTextAttributes] range:NSMakeRange(0,[aString length])];
    }

    if (I_flags.highlightSyntax) {
        if ([aString length]) {
            NSRange range=NSMakeRange(aRange.location,[aString length]);
//            NSLog(@"%s %@",__FUNCTION__, NSStringFromRange(range));
            [self highlightSyntaxInRange:range];
        } else {
            unsigned length=[aTextStorage length];
            NSRange range=NSMakeRange(aRange.location!=0?aRange.location-1:aRange.location,length>=2?2:1);
            [self highlightSyntaxInRange:range];
        }
    }

    UndoManager *undoManager=[self documentUndoManager];
    if (![undoManager isUndoing]) {
        if ([undoManager isRedoing]) {
            [self updateChangeCount:NSChangeRedone];
        } else {
            [self updateChangeCount:NSChangeDone];
        }

        if (I_flags.showMatchingBrackets && ![undoManager isRedoing] &&
            !I_flags.isRemotelyEditingTextStorage &&
    //        !I_blockedit.isBlockediting && !I_blockedit.didBlockedit &&
            [aString length]==1 &&
            [self.bracketSettings charIsBracket:[aString characterAtIndex:0]] &&
			![self.bracketSettings shouldIgnoreBracketAtRangeBoundaries:NSMakeRange(aRange.location, aString.length) attributedString:aTextStorage]) {
            _currentBracketMatchingBracketPosition=aRange.location;
        }
    } else {
        [self updateChangeCount:NSChangeUndone];
    }
    I_flags.textDidChangeSinceLastSyntaxHighlighting=YES;
    [self triggerUpdateSymbolTableTimer];

// transform all selectedRanges
    TCMMMSession *session=[self session];
    NSString *sessionID=[session sessionID];
    NSEnumerator *participants=[[[session participants] objectForKey:TCMMMSessionReadWriteGroupName] objectEnumerator];
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

	if ([aString length] == 0) {
		// deletion happend and has nasty layout not being done bugs, so let us invalidate some characters after the change
		[self invalidateLayoutForRange:NSMakeRange(aRange.location,2)];
	}

// transform SymbolTable if there
    SymbolTableEntry *entry=nil;
    for (entry in I_symbolArray) {
        if (![entry isSeparator]) {
            [transformator transformOperation:[entry jumpRangeSelectionOperation] serverOperation:textOp];
            [transformator transformOperation:[entry rangeSelectionOperation] serverOperation:textOp];
        }
    }


// transform FindAllTables if there
    FindAllController *findAllWindow = nil;
    for (findAllWindow in I_findAllControllers) {
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

    [[NSNotificationQueue defaultQueue]
    enqueueNotification:[NSNotification notificationWithName:PlainTextDocumentDidChangeTextStorageNotification object:self]
           postingStyle:NSPostWhenIdle
           coalesceMask:NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender
               forModes:[NSArray arrayWithObject:NSDefaultRunLoopMode]];
}

- (NSDictionary *)blockeditAttributesForTextStorage:(FoldableTextStorage *)aTextStorage {
    return [self blockeditAttributes];
}

- (void)textStorageDidStartBlockedit:(FoldableTextStorage *)aTextStorage {
//	NSLog(@"%s",__FUNCTION__);
	for (PlainTextEditor *editor in self.plainTextEditors) {
		[editor updateViews];
	}
}

- (void)textStorageDidStopBlockedit:(FoldableTextStorage *)aTextStorage {
//	NSLog(@"%s",__FUNCTION__);
	for (PlainTextEditor *editor in self.plainTextEditors) {
		[editor updateViews];
	}
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
	BOOL tabKeyReplaces = [[[self documentMode] defaultForKey:DocumentModeTabKeyReplacesSelectionPreferenceKey] boolValue];
    NSRange affectedRange=[aTextView rangeForUserTextChange];
    NSRange selectedRange=[aTextView selectedRange];
    if (aSelector==@selector(cancel:)) {
        FoldableTextStorage *textStorage=(FoldableTextStorage *)[self textStorage];
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
                    //position=lineRange.location;
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
                    	NSTextStorage *textStorage = [aTextView textStorage];
                        [textStorage replaceCharactersInRange:deleteRange withString:@""];
                        [aTextView didChangeText];
                    }
                    return YES;
                }
            }
        } else if (aSelector==@selector(insertNewline:)) {
            NSString *indentString=nil;
            NSString *postString = @"";
            if (I_flags.indentNewLines) {
                // when we have a newline, we have to find the last linebreak
                FoldableTextStorage *foldableTextStorage = (FoldableTextStorage *)[self textStorage];
                NSString    *string=[foldableTextStorage string];
                NSRange indentRange=[string lineRangeForRange:affectedRange];
                indentRange = [string rangeOfLeadingWhitespaceStartingAt:indentRange.location];
                if (NSMaxRange(indentRange)>affectedRange.location) {
                    indentRange.length-=NSMaxRange(indentRange)-affectedRange.location;
                }
                BOOL needsIndent = [[foldableTextStorage fullTextStorage] nextLineNeedsIndentation:[foldableTextStorage fullRangeForFoldedRange:NSMakeRange(indentRange.location,affectedRange.location - indentRange.location)]];
                if (indentRange.length || needsIndent) {
                    indentString=[string substringWithRange:indentRange];
					// if we find a folding start prior in that line we need to indent further
					if (needsIndent) {

						// check if the range after the effected range is a end of a folding, then we push it to the next line, one indentation less
						if (NSMaxRange(affectedRange) < [[self textStorage] length]) {
							NSString *endFoldingDelimiter = [[self textStorage] attribute:kSyntaxHighlightingFoldDelimiterName atIndex:NSMaxRange(affectedRange) effectiveRange:NULL];
							if ([endFoldingDelimiter isEqualToString:kSyntaxHighlightingStateDelimiterEndValue]) {
								postString = [NSString stringWithFormat:@"%@%@",[self lineEndingString],indentString];
							}
						}

						indentString = [I_flags.usesTabs ? @"\t" : [@" " stringByPaddingToLength:I_tabWidth withString:@" " startingAtIndex:0] stringByAppendingString: indentString];
					}
                }
            }
            if (indentString) {
                [aTextView insertText:[NSString stringWithFormat:@"%@%@%@",[self lineEndingString],indentString, postString]];
                if ([postString length] > 0) {
                	// move selection back to the desired position
                	NSRange selectedRange = [aTextView selectedRange];
                	selectedRange.location -= [postString length];
                	[aTextView setSelectedRange:selectedRange];
                }
            } else {
                [aTextView insertText:[self lineEndingString]];
            }
            return YES;

        } else if (aSelector==@selector(insertBacktab:) && !tabKeyReplaces && selectedRange.length > 0) {
        	PlainTextEditor *editor = [(SEETextView *)aTextView editor];
        	[editor shiftLeft:self];
        	return YES;
        }  else if (aSelector==@selector(insertTab:)    && !tabKeyReplaces && selectedRange.length > 0) {
        	PlainTextEditor *editor = [(SEETextView *)aTextView editor];
        	[editor shiftRight:self];
        	return YES;
        } else if (aSelector==@selector(insertTab:)) {
			BOOL tabKeyMovesToIndent  = [[[self documentMode] defaultForKey:DocumentModeTabKeyMovesToIndentPreferenceKey] boolValue];

        	if (tabKeyMovesToIndent && selectedRange.length == 0) {
        		NSString *string = [[self textStorage] string]; // this is the string including the foldings
        		NSRange currentLineRange = [string lineRangeForRange:selectedRange];
        		if (currentLineRange.location > 0) { // do nothing special if we are in the first line
	        		NSRange rangeToReplace = [string rangeOfLeadingWhitespaceStartingAt:currentLineRange.location];
					NSRange rangeToReplaceWith = NSMakeRange(NSNotFound,0);
					BOOL indentOneStepFurther = NO;
					NSInteger location = currentLineRange.location;
					while (location != 0) {
						NSUInteger startIndex, lineEndIndex, contentsEndIndex;
						[string getLineStart:&startIndex end:&lineEndIndex contentsEnd:&contentsEndIndex forRange:NSMakeRange(location-1,0)];
						NSRange whiteSpaceRange = [string rangeOfLeadingWhitespaceStartingAt:startIndex];
						if (NSMaxRange(whiteSpaceRange) < contentsEndIndex) {
							// found it, this is a line with content
							rangeToReplaceWith = whiteSpaceRange;
							// if we find a folding start at the end of that line we want to indent one step further
							indentOneStepFurther = [[(FoldableTextStorage *)[self textStorage] fullTextStorage] nextLineNeedsIndentation:[(FoldableTextStorage *)[self textStorage] fullRangeForFoldedRange:NSMakeRange(startIndex,contentsEndIndex - startIndex)]];
							break;
						} else {
							location = startIndex;
						}
					}
					
					if (rangeToReplaceWith.location != NSNotFound) {
						int tabWidth = [self tabWidth];
						if ([string detabbedLengthForRange:rangeToReplace     tabWidth:tabWidth] < 
							[string detabbedLengthForRange:rangeToReplaceWith tabWidth:tabWidth] &&
							NSLocationInRange(selectedRange.location,NSMakeRange(rangeToReplace.location,rangeToReplace.length+1))) {
							// sanity is checked, we need to indent!
							NSString *replacementString = [string substringWithRange:rangeToReplaceWith];
							if (indentOneStepFurther) replacementString = [I_flags.usesTabs ? @"\t" : [@" " stringByPaddingToLength:I_tabWidth withString:@" " startingAtIndex:0] stringByAppendingString:replacementString];
							if ([aTextView shouldChangeTextInRange:rangeToReplace replacementString:replacementString]) {
								NSTextStorage *textStorage = [aTextView textStorage];
								[textStorage replaceCharactersInRange:rangeToReplace withString:replacementString];
								[aTextView didChangeText];
							}
							return YES;
						}
					}
        		}
        	}
        	if (!I_flags.usesTabs) {
				// when we have a tab we have to find the last linebreak
				NSRange lineRange=[[[self textStorage] string] lineRangeForRange:affectedRange];
				NSString *replacementString=[@" " stringByPaddingToLength:I_tabWidth-((affectedRange.location-lineRange.location)%I_tabWidth)
															   withString:@" " startingAtIndex:0];
				[aTextView insertText:replacementString];
				return YES;
			}
			return NO; // do the default behaviour
        } else if ((aSelector==@selector(moveLeft:)    || aSelector==@selector(moveRight:) || 
                    aSelector==@selector(moveForward:) || aSelector==@selector(moveBackward:)) &&
                    I_flags.showMatchingBrackets) {
            NSInteger position=0;
            if (aSelector==@selector(moveLeft:) || aSelector==@selector(moveBackward:)) {
                position=selectedRange.location-1;
            } else {
                position=NSMaxRange(selectedRange);
            }
			position = [self.textStorage fullRangeForFoldedRange:NSMakeRange(position, 1)].location;
            NSString *string=[[[self textStorage] fullTextStorage] string];
            if (position>=0 && position<[string length] &&
                [self.bracketSettings charIsBracket:[string characterAtIndex:position]] &&
				![self.bracketSettings shouldIgnoreBracketAtIndex:position attributedString:self.textStorage.fullTextStorage]) {
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
    FoldableTextStorage *textStorage = (FoldableTextStorage *)[aTextView textStorage];
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
        
		if (NSPointInRect(point, glyphRect))
		{
            // Convert the glyph index to a character index
            NSUInteger charIndex=[layoutManager characterIndexForGlyphAtIndex:glyphIndex];
            if ([self.bracketSettings charIsBracket:[[[self textStorage] string] characterAtIndex:charIndex]]) {
				// we have a bracket - so lets switch up to fullTextStorage
				FullTextStorage *fullTextStorage = self.textStorage.fullTextStorage;
				NSUInteger fullIndex = [self.textStorage fullRangeForFoldedRange:NSMakeRange(charIndex, 1)].location;
				if (![self.bracketSettings shouldIgnoreBracketAtIndex:fullIndex attributedString:fullTextStorage]) {
					NSUInteger matchingPosition = [fullTextStorage TCM_positionOfMatchingBracketToPosition:fullIndex bracketSettings:self.bracketSettings];
					if (matchingPosition!=NSNotFound) {
						aNewSelectedCharRange = NSUnionRange(NSMakeRange(fullIndex,1),
															 NSMakeRange(matchingPosition,1));
						aNewSelectedCharRange = [self.textStorage foldedRangeForFullRange:aNewSelectedCharRange];
					}
				}
			}
        }
    }

    return aNewSelectedCharRange;
}


- (void)textViewDidChangeSelection:(NSNotification *)aNotification {
    if (!I_flags.isRemotelyEditingTextStorage) {
        NSTextView *textView=(NSTextView *)[aNotification object];
        NSRange selectedRange = [I_textStorage fullRangeForFoldedRange:[textView selectedRange]];
        SelectionOperation *selOp = [SelectionOperation selectionOperationWithRange:selectedRange userID:[TCMMMUserManager myUserID]];
        [[self session] documentDidApplyOperation:selOp];
        [self TCM_sendPlainTextDocumentParticipantsDataDidChangeNotification];
    }
}

- (BOOL)didPauseBecauseOfMarkedText {
	return I_flags.isRemotelyEditingTextStorage;
}


- (BOOL)textView:(NSTextView *)aTextView shouldChangeTextInRange:(NSRange)aAffectedCharRange replacementString:(NSString *)aReplacementString {
    FoldableTextStorage *textStorage=(FoldableTextStorage *)[aTextView textStorage];
    if ([aTextView hasMarkedText] && !I_flags.didPauseBecauseOfMarkedText) {
        //NSLog(@"paused because of marked...");
        I_flags.didPauseBecauseOfMarkedText=YES;
        [[self session] pauseProcessing];
//        [[self documentUndoManager] beginUndoGrouping];
//		NSLog(@"%s beginning marked text undo group",__FUNCTION__);

    }
	
	if ([textStorage length] == 0 && I_flags.shouldChangeExtensionOnModeChange && [(SEETextView *)aTextView isPasting]) {
//		NSLog(@"%s now we check",__FUNCTION__);
		DocumentMode *mode = [[DocumentModeManager sharedInstance] documentModeForPath:@"" withContentString:aReplacementString];
		
		if (![mode isBaseMode]) {
			[self setDocumentMode:mode];
		}
		I_flags.shouldSelectModeOnSave=NO;
		// clear the change marks after this first paste, to not have a totally changed first document
		[self performSelector:@selector(clearChangeMarks:) withObject:nil afterDelay:0];
	}
	
	// record this change for possible later use
	 I_lastTextShouldChangeReplacementRange = aAffectedCharRange;
	[I_lastTextShouldChangeReplacementString release];
	 I_lastTextShouldChangeReplacementString = [aReplacementString copy];

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

    NSArray *plainTextEditors = [self plainTextEditors];
    unsigned editorCount = [plainTextEditors count];
    if ([plainTextEditors count] > 1) {
        [I_currentTextOperation release];
         I_currentTextOperation = [[TextOperation textOperationWithAffectedCharRange:aAffectedCharRange replacementString:aReplacementString userID:(NSString *)[TCMMMUserManager myUserID]] retain];
        while (editorCount--) {
            PlainTextEditor *editor = [plainTextEditors objectAtIndex:editorCount];
            if ([editor textView] != aTextView) {
                [editor storePosition];
            }
        }
    }

    return YES;
}

- (void)textDidChange:(NSNotification *)aNotification {
    NSTextView *textView=[aNotification object];
    FoldableTextStorage *textStorage = (FoldableTextStorage *) [textView textStorage];
    BOOL cancelBlockEdit = NO;

    if (I_flags.didPauseBecauseOfMarkedText && textView && ![textView hasMarkedText]) {
        //NSLog(@"started because of marked... in did change");
        I_flags.didPauseBecauseOfMarkedText=NO;

		
		// check change for conformance
		if ((![I_lastTextShouldChangeReplacementString canBeConvertedToEncoding:[self fileEncoding]])) {
//			NSLog(@"%s %@ %@",__FUNCTION__,NSStringFromRange(I_lastTextShouldChangeReplacementRange),I_lastTextShouldChangeReplacementString);
			cancelBlockEdit = YES;
			
			// undo last change
			[textStorage replaceCharactersInRange:NSMakeRange(I_lastTextShouldChangeReplacementRange.location,[I_lastTextShouldChangeReplacementString length]) withString:@""];
			
			NSLog(@"%s %@",__FUNCTION__,textStorage);
			
			// show sheet
			TCMMMSession *session=[self session];
			if ([session isServer] && [session participantCount]<=1) {
				NSMutableDictionary *contextInfo = [[NSMutableDictionary alloc] init];
				[contextInfo setObject:@"ShouldPromoteAlert" forKey:@"Alert"];
				[contextInfo setObject:textView forKey:@"TextView"];
				[contextInfo setObject:[[I_lastTextShouldChangeReplacementString copy] autorelease] forKey:@"ReplacementString"];
				[contextInfo autorelease];
		
				NSAlert *alert = [[[NSAlert alloc] init] autorelease];
				[alert setAlertStyle:NSWarningAlertStyle];
				[alert setMessageText:NSLocalizedString(@"You are trying to insert characters that cannot be handled by the file's current encoding. Do you want to cancel the change?", nil)];
				[alert setInformativeText:[NSLocalizedString(@"You are no longer restricted by the file's current encoding if you promote to a Unicode encoding.", nil) stringByAppendingString:[NSString stringWithFormat:@"\n%@ ->\n%@",I_lastTextShouldChangeReplacementString,[NSString stringWithData:[I_lastTextShouldChangeReplacementString dataUsingEncoding:[self fileEncoding] allowLossyConversion:YES] encoding:[self fileEncoding]]]]];
				[alert addButtonWithTitle:NSLocalizedString(@"Insert", nil)];
				[alert addButtonWithTitle:NSLocalizedString(@"Promote to UTF8", nil)];
				[alert addButtonWithTitle:NSLocalizedString(@"Promote to Unicode", nil)];
				[[[alert buttons] objectAtIndex:0] setKeyEquivalent:@"\r"];
				[alert beginSheetModalForWindow:[textView window]
								  modalDelegate:self
								 didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
									contextInfo:[contextInfo retain]];
			} else {
				NSBeep();
			}
		}
//		NSLog(@"%s ending marked text undo group",__FUNCTION__);
//		[[self documentUndoManager] endUndoGrouping];


        [[self session] startProcessing];
//        DEBUGLOG(@"MillionMonkeysDomain",AlwaysLogLevel,@"start");
    }

	// highlight the freshly closed bracket
    if (![textStorage didBlockedit]) {
        if (_currentBracketMatchingBracketPosition!=NSNotFound) {
            [self TCM_highlightBracketAtPosition:_currentBracketMatchingBracketPosition inTextView:textView];
            _currentBracketMatchingBracketPosition=NSNotFound;
        }
    }
    
    // take care for blockedit
	
    if ([textStorage didBlockedit] && ![textStorage isBlockediting] && ![textView hasMarkedText] && !cancelBlockEdit) {
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

    NSArray *plainTextEditors = [self plainTextEditors];
    unsigned editorCount = [plainTextEditors count];
    if ([plainTextEditors count] > 1) {
        while (editorCount--) {
            PlainTextEditor *editor = [plainTextEditors objectAtIndex:editorCount];
            if ([editor textView] != textView) {
                [editor restorePositionAfterOperation:I_currentTextOperation];
            }
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
    SEETextView *textView = [[SEETextView alloc] initWithFrame:frame textContainer:textContainer];
    [textView setTextContainerInset:textContainerInset];
    [textView setMaxSize:[textView frame].size];
    [textView setBackgroundColor:[self documentBackgroundColor]];
    [layoutManager setShowsChangeMarks:YES];
    [layoutManager addTextContainer:textContainer];
    NSRange wholeRange = NSMakeRange(0,[[self textStorage] length]);
    [layoutManager invalidateLayoutForCharacterRange:wholeRange isSoft:NO actualCharacterRange:NULL];
    [textView setNeedsDisplay:YES];
    
    NSRect rectToCache = [textView frame];
    NSBitmapImageRep *rep = [textView bitmapImageRepForCachingDisplayInRect:rectToCache];
    [textView cacheDisplayInRect:[textView frame] toBitmapImageRep:rep];

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

- (id)handleSaveScriptCommand:(NSScriptCommand *)command {
	NSDictionary *arguments = command.evaluatedArguments;
	NSURL *fileURL = [arguments objectForKey:@"File"];
	if (fileURL) { // only in save as mode
		if ([[SEEScopedBookmarkManager sharedManager] startAccessingScriptedFileURL:fileURL]) {
			NSLog(@"Access granted.");
		}
	}
	return [super handleSaveScriptCommand:command];
}

- (id)handleCloseScriptCommand:(NSCloseCommand *)command {
	NSDictionary *arguments = command.evaluatedArguments;
	NSURL *fileURL = [arguments objectForKey:@"File"];
	if (fileURL) { // only in save as mode
		if ([[SEEScopedBookmarkManager sharedManager] startAccessingScriptedFileURL:fileURL]) {
			NSLog(@"Access granted.");
		}
	}
	return [super handleCloseScriptCommand:command];
}

- (void)handleBeginUndoGroupCommand:(NSScriptCommand *)command {
    [[self documentUndoManager] beginUndoGrouping];
	[I_textStorage beginEditing];
}

- (void)handleEndUndoGroupCommand:(NSScriptCommand *)command {
	[I_textStorage endEditing];
    [[self documentUndoManager] endUndoGrouping];
}


- (void)handleClearChangeMarksCommand:(NSScriptCommand *)command {
    [self clearChangeMarks:self];
}

- (void)handleShowWebPreviewCommand:(NSScriptCommand *)command {
	PlainTextWindowController *windowController = self.topmostWindowController;
	PlainTextWindowControllerTabContext *tabContext = [windowController windowControllerTabContextForDocument:self];

	if ([windowController.document isEqual:self]) {
		if (! tabContext.webPreviewViewController) {
			[windowController toggleWebPreview:self];
		} else {
			[tabContext.webPreviewViewController refresh:self];
		}
	} else {
		if (!tabContext.hasWebPreviewSplit) {
			tabContext.hasWebPreviewSplit = YES;
		} else {
			[tabContext.webPreviewViewController refresh:self];
		}
	}
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

    FullTextStorage *textStorage = [(FoldableTextStorage *)[self textStorage] fullTextStorage];
    [textStorage replaceCharactersInRange:aRange withString:mutableString];
    if ([mutableString length] > 0) {
        [textStorage addAttributes:[self typingAttributes] 
                             range:NSMakeRange(aRange.location, [mutableString length])];
    }
    
    [mutableString release];
    
//    if (I_flags.highlightSyntax) {
//        [self highlightSyntaxInRange:NSMakeRange(0, [[I_textStorage fullTextStorage] length])];
//    }

}

- (NSNumber *)uniqueID {
//    return [NSNumber numberWithUnsignedInt:(uintptr_t)self];
    return [NSNumber numberWithInteger:(int32_t)self];
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
        if ([[[I_textStorage fullTextStorage] string] canBeConvertedToEncoding:encoding]) {
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
    return [[I_textStorage fullTextStorage] string];
}

- (void)setScriptedContents:(id)value {
    [self replaceTextInRange:NSMakeRange(0,[[I_textStorage fullTextStorage] length]) withString:value];
}

- (FoldableTextStorage *)scriptedPlainContents {
    return I_textStorage;
}

- (void)setScriptedPlainContents:(id)value {
    if ([value isKindOfClass:[NSString class]]) {
        [self replaceTextInRange:NSMakeRange(0, [[I_textStorage fullTextStorage] length]) withString:value];
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

+ (id)coerceValue:(id)value toClass:(Class)toClass {
	if ([value isKindOfClass:[PlainTextDocument class]]) {
		if ([toClass isSubclassOfClass:[NSString class]]) {
			return [value scriptedContents];
		} else if ([toClass isSubclassOfClass:[FoldableTextStorage class]]) {
			return [value scriptedPlainContents];
		}
	}
	return nil;
}


- (id)scriptDocumentMode {
	return [self documentMode];
}


- (id)scriptSelection {
    if ([self isProxyDocument]) return nil;
    return [[self activePlainTextEditor] scriptSelection];
}

- (void)setScriptSelection:(id)aSelection {
    if ([self isProxyDocument]) return;
    [[self activePlainTextEditor] setScriptSelection:aSelection];
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
	NSString *result = nil;
	PlainTextWindowController *windowController = self.topmostWindowController;
	PlainTextWindowControllerTabContext *tabContext = [windowController selectedTabContext];

	if (! tabContext.webPreviewViewController) {
		result = [[self fileURL] absoluteString];
	} else {
		result = tabContext.webPreviewViewController.baseURL.absoluteString;
	}
    return result;
}

- (void)setScriptedWebPreviewBaseURL:(NSString *)aString {
	PlainTextWindowController *windowController = self.topmostWindowController;
	PlainTextWindowControllerTabContext *tabContext = [windowController selectedTabContext];

	if (! tabContext.webPreviewViewController) {
		[windowController toggleWebPreview:self];
	}

	tabContext.webPreviewViewController.baseURL = [NSURL URLWithString:aString];
	[tabContext.webPreviewViewController refresh:self];
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
    NSTextView *myTextView = [[self activePlainTextEditor] textView];
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
