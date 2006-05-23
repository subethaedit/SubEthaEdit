//
//  PlainTextDocument.m
//  SubEthaEdit
//
//  Created by Martin Ott on Tue Feb 24 2004.
//  Copyright (c) 2004-2006 TheCodingMonkeys. All rights reserved.
//

#import <Carbon/Carbon.h>
#import <SystemConfiguration/SystemConfiguration.h>

#import "TCMMillionMonkeys/TCMMillionMonkeys.h"
#import "PlainTextEditor.h"
#import "DocumentController.h"
#import "PlainTextDocument.h"
#import "PlainTextWindowController.h"
#import "WebPreviewWindowController.h"
#import "DocumentProxyWindowController.h"
#import "UndoManager.h"
#import "TCMMMUserSEEAdditions.h"
#import "PrintPreferences.h"
#import "AppController.h"
#import "NSSavePanelTCMAdditions.h"

#import "DocumentModeManager.h"
#import "DocumentMode.h"
#import "SyntaxHighlighter.h"
#import "SymbolTableEntry.h"

#import "TextStorage.h"
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

#import "ScriptTextSelection.h"
#import "ScriptWrapper.h"
#import "NSMenuTCMAdditions.h"

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

#pragma mark -

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

@interface PlainTextDocument (PlainTextDocumentPrivateAdditions)
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
- (BOOL)TCM_readFromFile:(NSString *)fileName ofType:(NSString *)docType properties:(NSDictionary *)properties;
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
    [[NSNotificationQueue defaultQueue]
    enqueueNotification:[NSNotification notificationWithName:PlainTextDocumentDidChangeDisplayNameNotification object:self]
           postingStyle:NSPostWhenIdle
           coalesceMask:NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender
               forModes:[NSArray arrayWithObject:NSDefaultRunLoopMode]];
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
    I_bracketMatching.matchingBracketPosition=NSNotFound;
    [self setKeepDocumentVersion:NO];
    [self setEditAnyway:NO];
    [self setIsFileWritable:YES];
    I_undoManager = [(UndoManager *)[UndoManager alloc] initWithDocument:self];
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
        if ([controller isKindOfClass:[PlainTextWindowController class]]) {
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
                    if ([self TCM_charIsOpeningBracket:buffer[i]]) {
                        if (++stackPosition>=STACKLIMIT) {
                            stop=YES;
                        } else {
                            stack[stackPosition]=[self TCM_matchingBracketForChar:buffer[i]];
                        }
                    } else if ([self TCM_charIsClosingBracket:buffer[i]]) {
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
                    if ([self TCM_charIsClosingBracket:buffer[i]]) {
                        if (++stackPosition>=STACKLIMIT) {
                            stop=YES;
                        } else {
                            stack[stackPosition]=[self TCM_matchingBracketForChar:buffer[i]];
                        }
                    } else if ([self TCM_charIsOpeningBracket:buffer[i]]) {
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
        [self TCM_initHelper];
    }
    return self;
}

- (void)dealloc {

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
    
    [I_symbolUpdateTimer release];
    [I_webPreviewDelayedRefreshTimer release];

    [[TCMMMPresenceManager sharedInstance] unregisterSession:[self session]];
    [I_textStorage setDelegate:nil];
    [I_textStorage release];
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

    free(I_bracketMatching.openingBracketsArray);
    free(I_bracketMatching.closingBracketsArray);
    [super dealloc];
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
    [self setLineEnding:[[documentMode defaultForKey:DocumentModeLineEndingPreferenceKey] intValue]];
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
    }
}

- (IBAction)toggleIsAnnounced:(id)aSender {
    [self setIsAnnounced:![self isAnnounced]];
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
        [I_webPreviewWindowController refresh:self];
    } else {
        [[I_webPreviewWindowController window] orderFront:self];
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
    if (!I_flags.isReceivingContent && [[self windowControllers] count]>0) {
        PlainTextWindowController *controller=[PlainTextWindowController new];
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
        [alert beginSheetModalForWindow:[self windowForSheet]
                          modalDelegate:self
                         didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
                            contextInfo:[[NSDictionary dictionaryWithObjectsAndKeys:
                                                            @"SelectEncodingAlert", @"Alert",
                                                            [NSNumber numberWithUnsignedInt:encoding], @"Encoding",
                                                            nil] retain]];
    }
}

- (void)makeWindowControllers {
    [self addWindowController:[[PlainTextWindowController new] autorelease]];
}

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
    }
}

- (void)updateProxyWindow {
    [I_documentProxyWindowController update];
}

- (void)proxyWindowWillClose {
    [self killProxyWindowController];
}

- (void)removeWindowController:(NSWindowController *)windowController {
    [super removeWindowController:windowController];
    if ([[self windowControllers] count] == 0) {
        // terminate syntax coloring
        I_flags.highlightSyntax = NO;
        [I_symbolUpdateTimer invalidate];
        [I_webPreviewDelayedRefreshTimer invalidate];
        [self TCM_sendODBCloseEvent];
        if (I_authRef != NULL) {
            (void)AuthorizationFree(I_authRef, kAuthorizationFlagDestroyRights);
            I_authRef = NULL;
        }
    } else {
        // if doing always, we delay the dealloc method ad inifitum on quit
        [self TCM_sendPlainTextDocumentDidChangeDisplayNameNotification];
    }
}

- (void)TCM_validateLineEndings {

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
            [alert beginSheetModalForWindow:[self windowForSheet]
                              modalDelegate:self
                             didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
                                contextInfo:[[NSDictionary dictionaryWithObjectsAndKeys:
                                                                @"MixedLineEndingsAlert", @"Alert",
                                                                [sortedLineEndingStatsKeys objectAtIndex:4], @"LineEnding",
                                                                nil] retain]];
        }
    }
}

- (void)showWindows {    
    BOOL closeTransient = transientDocument 
                          && NSEqualRects(transientDocumentWindowFrame, [[[transientDocument topmostWindowController] window] frame])
                          && [[[NSUserDefaults standardUserDefaults] objectForKey:OpenDocumentOnStartPreferenceKey] boolValue];

    if (I_documentProxyWindowController) {
        [[I_documentProxyWindowController window] orderFront:self];
    } else {
        if (closeTransient) {
            NSWindow *window = [[self topmostWindowController] window];
            [window setFrameTopLeftPoint:NSMakePoint(transientDocumentWindowFrame.origin.x, NSMaxY(transientDocumentWindowFrame))];
        }
        [[self topmostWindowController] showWindow:self];
    }
    
    if (closeTransient && ![self isProxyDocument]) {
        [transientDocument close];
        transientDocument = nil;
    }
    
    if ([[DocumentController sharedInstance] isOpeningUntitledDocument] && [[AppController sharedInstance] lastShouldOpenUntitledFile]) {
        transientDocument = self;
        transientDocumentWindowFrame = [[[transientDocument topmostWindowController] window] frame];
    }
    
    if ([I_textStorage length] > [[NSUserDefaults standardUserDefaults] integerForKey:@"StringLengthToStopHighlightingAndWrapping"]) {
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
        [alert setAlertStyle:NSInformationalAlertStyle];
        [alert setMessageText:NSLocalizedString(@"Syntax Highlighting and Wrap Lines have been turned off due to the size of the Document.", @"BigFile Message Text")];
        [alert setInformativeText:NSLocalizedString(@"Turning on Syntax Highlighting for very large Documents is not recommended.", @"BigFile Informative Text")];
        [alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
        [alert beginSheetModalForWindow:[self windowForSheet]
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
            if ([fileManager createDirectoryAtPath:imageDirectory attributes:nil]) {
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
    
- (BOOL)prepareSavePanel:(NSSavePanel *)savePanel {
    if (![NSBundle loadNibNamed:@"SavePanelAccessory" owner:self])  {
        NSLog(@"Failed to load SavePanelAccessory.nib");
        return nil;
    }
    
    BOOL isGoingIntoBundles = [[NSUserDefaults standardUserDefaults] boolForKey:@"GoIntoBundlesPrefKey"];
    [savePanel setTreatsFilePackagesAsDirectories:isGoingIntoBundles];
    
    BOOL showsHiddenFiles = [[NSUserDefaults standardUserDefaults] boolForKey:@"ShowsHiddenFiles"];
    if ([savePanel canShowHiddenFiles]) {
        [savePanel setInternalShowsHiddenFiles:showsHiddenFiles];
    }    
    
    I_savePanel = savePanel;
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
    }

    [O_savePanelAccessoryView release];
    O_savePanelAccessoryView = nil;
    
    [O_savePanelAccessoryView2 release];
    O_savePanelAccessoryView2 = nil;
        
    return [super prepareSavePanel:savePanel];
}

- (void)saveDocumentWithDelegate:(id)delegate didSaveSelector:(SEL)didSaveSelector contextInfo:(void *)contextInfo {
    if ([self TCM_validateDocument]) {
        [super saveDocumentWithDelegate:delegate didSaveSelector:didSaveSelector contextInfo:contextInfo];
    }
}

- (void)saveToFile:(NSString *)fileName saveOperation:(NSSaveOperationType)saveOperation delegate:(id)delegate didSaveSelector:(SEL)didSaveSelector contextInfo:(void *)contextInfo {

    [I_savePanel setDelegate:nil];
    I_savePanel = nil;
    
    if (fileName) {
        if (I_flags.shouldSelectModeOnSave) {
            DocumentMode *mode = [[DocumentModeManager sharedInstance] documentModeForExtension:[fileName pathExtension]];
            if (![mode isBaseMode]) {
                [self setDocumentMode:mode];
            }
            I_flags.shouldSelectModeOnSave=NO;
            I_flags.shouldChangeExtensionOnModeChange=NO;
        }

        if (saveOperation == NSSaveToOperation) {
            I_encodingFromLastRunSaveToOperation = [[O_encodingPopUpButton selectedItem] tag];
        }
    }
    
    [super saveToFile:fileName saveOperation:saveOperation delegate:delegate didSaveSelector:didSaveSelector contextInfo:contextInfo];
}

- (NSData *)dataRepresentationOfType:(NSString *)aType {

    if ([aType isEqualToString:@"PlainTextType"] || [aType isEqualToString:@"SubEthaEditSyntaxStyle"]) {
        if (I_lastSaveOperation == NSSaveToOperation) {
            DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel, @"Save a copy using encoding: %@", [NSString localizedNameOfStringEncoding:I_encodingFromLastRunSaveToOperation]);
            [[EncodingManager sharedInstance] unregisterEncoding:I_encodingFromLastRunSaveToOperation];
            return [[I_textStorage string] dataUsingEncoding:I_encodingFromLastRunSaveToOperation allowLossyConversion:YES];
        } else {
            DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel, @"Save using encoding: %@", [NSString localizedNameOfStringEncoding:[self fileEncoding]]);
            return [[I_textStorage string] dataUsingEncoding:[self fileEncoding] allowLossyConversion:YES];
        }
    }

    return nil;
}

- (BOOL)revertToSavedFromFile:(NSString *)fileName ofType:(NSString *)type {
    BOOL success = [super revertToSavedFromFile:fileName ofType:type];
    if (success) {
        [self setFileName:fileName];
    }
    return success;
}

- (BOOL)readFromURL:(NSURL *)aURL ofType:(NSString *)docType {
    if ([aURL isFileURL]) {
        return [self readFromFile:[aURL path] ofType:docType];
    } else {
        return NO;
    }
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

- (BOOL)TCM_readFromFile:(NSString *)fileName ofType:(NSString *)docType properties:(NSDictionary *)properties {
    DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel, @"readFromFile:%@ ofType:%@ properties: %@", fileName, docType, properties);

    I_flags.shouldChangeExtensionOnModeChange = NO;
    I_flags.shouldSelectModeOnSave = NO;
    I_flags.isReadingFile = YES;

    if (![docType isEqualToString:@"PlainTextType"] && ![docType isEqualToString:@"SubEthaEditSyntaxStyle"]) {
        I_flags.isReadingFile = NO;
        return NO;
    }

    BOOL isDir, fileExists;
    fileExists = [[NSFileManager defaultManager] fileExistsAtPath:fileName isDirectory:&isDir];
    if (!fileExists || isDir) {
        I_flags.isReadingFile = NO;
        return NO;
    }

    NSTextStorage *textStorage = [self textStorage];
    BOOL isReverting = ([textStorage length] != 0);

    BOOL isDocumentFromOpenPanel = [(DocumentController *)[NSDocumentController sharedDocumentController] isDocumentFromLastRunOpenPanel:self];
    DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel, @"Document opened via open panel: %@", isDocumentFromOpenPanel ? @"YES" : @"NO");

    // Determine mode
    DocumentMode *mode = nil;
    BOOL chooseModeByContent = NO;
    if (!isReverting) {
        if ([properties objectForKey:@"mode"]) {
            NSString *modeName = [properties objectForKey:@"mode"];
            mode = [[DocumentModeManager sharedInstance] documentModeForName:modeName];
            if (!mode) {
                DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel, @"Mode name invalid: %@", modeName);
            }
        } else {
            if (isDocumentFromOpenPanel) {
                NSString *identifier = [(DocumentController *)[NSDocumentController sharedDocumentController] modeIdentifierFromLastRunOpenPanel];
                if ([identifier isEqualToString:AUTOMATICMODEIDENTIFIER]) {
                    // Choose mode
                    // Priorities: Filename, Regex, Extension
                    // Check filename
                    mode = [[DocumentModeManager sharedInstance] documentModeForFilename:[fileName lastPathComponent]];
                    if ([mode isBaseMode]) {
                        chooseModeByContent = YES;
                        // Check extensions
                        NSString *extension = [fileName pathExtension];
                        mode = [[DocumentModeManager sharedInstance] documentModeForExtension:extension];
                    }
                } else {
                    mode = [[DocumentModeManager sharedInstance] documentModeForIdentifier:identifier];
                }
            }
        }

        if (!mode) {
            // get default mode (may be automatic)
            // currently following workaround is used
            mode = [[DocumentModeManager sharedInstance] documentModeForFilename:[fileName lastPathComponent]];
            if ([mode isBaseMode]) {
                chooseModeByContent = YES;
                // Check extensions
                NSString *extension = [fileName pathExtension];
                mode = [[DocumentModeManager sharedInstance] documentModeForExtension:extension];
            }
        }
    } else {
        mode = [self documentMode];
    }

    // Determine encoding
    BOOL usesModePreferenceEncoding = NO;
    NSStringEncoding encoding = NoStringEncoding;
    if ([properties objectForKey:@"encoding"]) {
        NSString *IANACharSetName = [properties objectForKey:@"encoding"];
        if (IANACharSetName) {
            CFStringEncoding cfEncoding = CFStringConvertIANACharSetNameToEncoding((CFStringRef)IANACharSetName);
            if (cfEncoding != kCFStringEncodingInvalidId) {
                encoding = CFStringConvertEncodingToNSStringEncoding(cfEncoding);
            } else {
                DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel, @"IANACharSetName invalid: %@", IANACharSetName);
            }
        }
    } else {
        if (isDocumentFromOpenPanel) {
            DocumentController *documentController = (DocumentController *)[NSDocumentController sharedDocumentController];
            encoding = [documentController encodingFromLastRunOpenPanel];
            if (encoding == ModeStringEncoding) {
                encoding = [[mode defaultForKey:DocumentModeEncodingPreferenceKey] unsignedIntValue];
                usesModePreferenceEncoding = YES;
            }
        }
    }
    
    if (encoding == NoStringEncoding) {
        encoding = [[mode defaultForKey:DocumentModeEncodingPreferenceKey] unsignedIntValue];
        usesModePreferenceEncoding = YES;
    }
    
    
    NSDictionary *docAttrs = nil;
    NSMutableDictionary *options = [NSMutableDictionary dictionary];

    if (encoding < SmallestCustomStringEncoding) {
        DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel, @"Setting \"CharacterEncoding\" option: %@", [NSString localizedNameOfStringEncoding:encoding]);
        [options setObject:[NSNumber numberWithUnsignedInt:encoding] forKey:@"CharacterEncoding"];
    }


    BOOL isReadable = [[NSFileManager defaultManager] isReadableFileAtPath:fileName];
    NSData *fileData = nil;
    if (!isReadable) {
        DEBUGLOG(@"FileIOLogDomain", AllLogLevel, @"We need root power!");
        fileData = [self TCM_dataWithContentsOfFileReadUsingAuthorizedHelper:fileName];
        if (fileData == nil) {
            I_flags.isReadingFile = NO;
            return NO;
        }
    }
    
    NSString *extension = [[fileName pathExtension] lowercaseString];
    BOOL isHTML = [extension isEqual:@"htm"] || [extension isEqual:@"html"];
    
    if (isHTML && isReadable) {
        fileData = [[NSData alloc] initWithContentsOfFile:[fileName stringByExpandingTildeInPath]];
    }
    
    [[textStorage mutableString] setString:@""]; // Empty the document

    NSURL *fileURL = [NSURL fileURLWithPath:[fileName stringByExpandingTildeInPath]];

    while (TRUE) {
        BOOL success;

        [textStorage beginEditing];
        if (isHTML || !isReadable) {
            success = [textStorage readFromData:fileData options:options documentAttributes:&docAttrs];
        } else {
            success = [textStorage readFromURL:fileURL options:options documentAttributes:&docAttrs];
        }
        [textStorage endEditing];

        DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel, @"Read successful? %@", success ? @"YES" : @"NO");
        DEBUGLOG(@"FileIOLogDomain", DetailedLogLevel, @"documentAttributes: %@", [docAttrs description]);

        if (!success) {
            NSNumber *encodingNumber = [options objectForKey:@"CharacterEncoding"];
            if (encodingNumber != nil) {
                NSStringEncoding systemEncoding = CFStringConvertEncodingToNSStringEncoding(CFStringGetSystemEncoding());
                NSStringEncoding triedEncoding = [encodingNumber unsignedIntValue];
                if (triedEncoding != systemEncoding) {
                    [[textStorage mutableString] setString:@""]; // Empty the document, and reload
                    [options setObject:[NSNumber numberWithUnsignedInt:systemEncoding] forKey:@"CharacterEncoding"];
                    continue;
                }
            }
            return NO;
        }

        if (![[docAttrs objectForKey:@"DocumentType"] isEqualToString:NSPlainTextDocumentType] &&
            ![[options objectForKey:@"DocumentType"] isEqualToString:NSPlainTextDocumentType]) {
            [[textStorage mutableString] setString:@""]; // Empty the document, and reload
            [options setObject:NSPlainTextDocumentType forKey:@"DocumentType"];
        } else {
            break;
        }
    }

    if (isHTML && isReadable) {
        [fileData release];
    }

    [self setFileEncoding:[[docAttrs objectForKey:@"CharacterEncoding"] unsignedIntValue]];


    // Check for ModeByContent changes and reinterpret to new encoding if necessary.
    if (chooseModeByContent) {
        NSString *beginning = [[I_textStorage string] substringWithRange:NSMakeRange(0,MIN(4000,[[I_textStorage string] length]))];
        DocumentMode *contentmode = [[DocumentModeManager sharedInstance] documentModeForContent:beginning];
        if (![contentmode isBaseMode]) {
            mode = contentmode;
            // Check for encoding!
            if (usesModePreferenceEncoding) {
                NSStringEncoding newencoding = [[mode defaultForKey:DocumentModeEncodingPreferenceKey] unsignedIntValue];
                if (newencoding != encoding) {
                    encoding = newencoding;
                    if ([[I_textStorage string] canBeConvertedToEncoding:encoding]){
                        NSString *reinterpretedString = [[NSString alloc] initWithData:[[I_textStorage string] dataUsingEncoding:[self fileEncoding]] encoding:encoding];
                        if (reinterpretedString) {
                            [I_textStorage replaceCharactersInRange:NSMakeRange(0, [I_textStorage length]) withString:reinterpretedString];
                            [self setFileEncoding:encoding];
                        }
                    }
                }
            }
        }
    }

    DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel, @"fileEncoding: %@", [NSString localizedNameOfStringEncoding:[self fileEncoding]]);

    [self setKeepDocumentVersion:NO];
    NSDictionary *fattrs = [[NSFileManager defaultManager] fileAttributesAtPath:fileName traverseLink:YES];
    [self setFileAttributes:fattrs];
    BOOL isWritable = [[NSFileManager defaultManager] isWritableFileAtPath:fileName];
    DEBUGLOG(@"FileIOLogDomain", DetailedLogLevel, @"isWritable: %@", isWritable ? @"YES" : @"NO");
    [self setIsFileWritable:isWritable];


    unsigned int wholeLength = [I_textStorage length];
    [I_textStorage addAttributes:[self plainTextAttributes]
                           range:NSMakeRange(0, wholeLength)];


    [self setDocumentMode:mode];
    if (wholeLength > [[NSUserDefaults standardUserDefaults] integerForKey:@"StringLengthToStopHighlightingAndWrapping"]) {
        [self setHighlightsSyntax:NO];
        [self setWrapLines:NO];
    }

    [self updateChangeCount:NSChangeCleared];

    I_flags.isReadingFile = NO;

    return YES;
}

- (BOOL)readFromFile:(NSString *)fileName ofType:(NSString *)docType {
    NSDictionary *properties = [[DocumentController sharedDocumentController] propertiesForOpenedFile:fileName];
    return [self TCM_readFromFile:fileName ofType:docType properties:properties];
}


- (NSDictionary *)fileAttributesToWriteToFile:(NSString *)fullDocumentPath ofType:(NSString *)documentTypeName saveOperation:(NSSaveOperationType)saveOperationType {

    DEBUGLOG(@"FileIOLogDomain", AllLogLevel, @"fileAttributesToWriteToFile: %@", fullDocumentPath);
    
    // Preserve HFS Type and Creator code
    if ([self fileName] && [self fileType]) {
        DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel, @"Preserve HFS Type and Creator Code");
        NSMutableDictionary *newAttributes = [NSMutableDictionary dictionaryWithDictionary:[super fileAttributesToWriteToFile:fullDocumentPath ofType:documentTypeName saveOperation:saveOperationType]];
        if ([self fileAttributes] != nil) {
            [newAttributes setObject:[[self fileAttributes] objectForKey:NSFileHFSTypeCode] forKey:NSFileHFSTypeCode];
            [newAttributes setObject:[[self fileAttributes] objectForKey:NSFileHFSCreatorCode] forKey:NSFileHFSCreatorCode];
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

    // If neither type nor creator code exist, use the default implementation.
    if (!(typeCode || creatorCode)) {
        return [super fileAttributesToWriteToFile:fullDocumentPath ofType:documentTypeName saveOperation:saveOperationType];
    }

    // Otherwise, add the type and/or creator to the dictionary.
    newAttributes = [NSMutableDictionary dictionaryWithDictionary:[super
        fileAttributesToWriteToFile:fullDocumentPath ofType:documentTypeName
        saveOperation:saveOperationType]];
    if (typeCode)
        [newAttributes setObject:typeCode forKey:NSFileHFSTypeCode];
    if (creatorCode)
        [newAttributes setObject:creatorCode forKey:NSFileHFSCreatorCode];

    [self setFileAttributes:newAttributes];
    return newAttributes;
}

- (BOOL)TCM_writeUsingAuthorizedHelperToFile:(NSString *)fullDocumentPath ofType:(NSString *)docType saveOperation:(NSSaveOperationType)saveOperationType {
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
                        NSData *data = [self dataRepresentationOfType:docType];
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
            
            return ((err == noErr) ? YES : NO);
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
                NSData *data = [self dataRepresentationOfType:docType];
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
        NSMutableDictionary *attrs = [[self fileAttributesToWriteToFile:fullDocumentPath ofType:docType saveOperation:saveOperationType] mutableCopy];
        if (![attrs objectForKey:NSFilePosixPermissions]) {
            [attrs setObject:[NSNumber numberWithUnsignedShort:S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH] forKey:NSFilePosixPermissions];
        }
        request = [NSDictionary dictionaryWithObjectsAndKeys:
                            @"ExchangeFileContents", @"CommandName",
                            fullDocumentPath, @"ActualFileName",
                            intermediateFileName, @"IntermediateFileName",
                            [attrs autorelease], @"Attributes",
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
    
    return ((err == noErr) ? YES : NO);
}

- (BOOL)writeWithBackupToFile:(NSString *)fullDocumentPath ofType:(NSString *)docType saveOperation:(NSSaveOperationType)saveOperationType {
    DEBUGLOG(@"FileIOLogDomain", DetailedLogLevel, @"writeWithBackupToFile: %@", fullDocumentPath);
    BOOL hasBeenWritten = [super writeWithBackupToFile:fullDocumentPath ofType:docType saveOperation:saveOperationType];
    if (!hasBeenWritten) {
        DEBUGLOG(@"FileIOLogDomain", AllLogLevel, @"Failed to write using writeWithBackupToFile:");
        
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
                    NSData *data = [self dataRepresentationOfType:docType];
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
                    hasBeenWritten = [self TCM_writeUsingAuthorizedHelperToFile:fullDocumentPath ofType:docType saveOperation:saveOperationType];
                } else if (returnCode == NSAlertSecondButtonReturn) {
                    NSFileManager *fileManager = [NSFileManager defaultManager];
                    NSString *tempFilePath = tempFileName(fullDocumentPath);
                    hasBeenWritten = [self writeToFile:tempFilePath ofType:docType];
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
                                [newAlert beginSheetModalForWindow:[self windowForSheet]
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
                            [newAlert beginSheetModalForWindow:[self windowForSheet]
                                                 modalDelegate:nil
                                                didEndSelector:nil
                                                   contextInfo:NULL];

                        }
                    }
                }
            } else {
                DEBUGLOG(@"FileIOLogDomain", AllLogLevel, @"We need root power!");
                hasBeenWritten = [self TCM_writeUsingAuthorizedHelperToFile:fullDocumentPath ofType:docType saveOperation:saveOperationType];
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
    
    if (saveOperationType != NSSaveToOperation) {
        NSDictionary *fattrs = [[NSFileManager defaultManager] fileAttributesAtPath:fullDocumentPath traverseLink:YES];
        [self setFileAttributes:fattrs];
        [self setIsFileWritable:[[NSFileManager defaultManager] isWritableFileAtPath:fullDocumentPath]];
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
    NSWindow *window = [self windowForSheet];
    if (!window) {
        return YES;
    }

    NSString *fileName = [self fileName];
    DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel, @"Validate document: %@", fileName);

    NSDictionary *fattrs = [[NSFileManager defaultManager] fileAttributesAtPath:fileName traverseLink:YES];
    if ([[fattrs fileModificationDate] compare:[[self fileAttributes] fileModificationDate]] != NSOrderedSame) {
        DEBUGLOG(@"FileIOLogDomain", DetailedLogLevel, @"Document has been changed externally");
        if ([self keepDocumentVersion]) {
            DEBUGLOG(@"FileIOLogDomain", DetailedLogLevel, @"Keep document version");
            return YES;
        }
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert setMessageText:NSLocalizedString(@"Warning", nil)];
        [alert setInformativeText:NSLocalizedString(@"Document changed externally", nil)];
        [alert addButtonWithTitle:NSLocalizedString(@"Keep SubEthaEdit Version", nil)];
        [alert addButtonWithTitle:NSLocalizedString(@"Revert", nil)];
        [[[alert buttons] objectAtIndex:0] setKeyEquivalent:@"\r"];
        [alert beginSheetModalForWindow:window
                          modalDelegate:self
                         didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
                            contextInfo:[[NSDictionary dictionaryWithObjectsAndKeys:
                                                            @"DocumentChangedExternallyAlert", @"Alert",
                                                            nil] retain]];

        return NO;
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
    } else if (selector == @selector(toggleIsAnnounced:)) {
        [anItem setTitle:[self isAnnounced]?
                         NSLocalizedString(@"Conceal",@"Menu/Toolbar Title for concealing the Document"):
                         NSLocalizedString(@"Announce",@"Menu/Toolbar Title for announcing the Document")];
        return [[self session] isServer];
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
    } else if (selector == @selector(clearChangeMarks:)) {
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

- (IBAction)chooseLineEndings:(id)aSender {
    [self setLineEnding:[aSender tag]];
}

- (void)convertLineEndingsToLineEnding:(LineEnding)lineEnding {   
    TextStorage *textStorage=(TextStorage *)[self textStorage];
    [textStorage setShouldWatchLineEndings:NO];

    [self setLineEnding:lineEnding];
    [[self documentUndoManager] beginUndoGrouping];
    [[textStorage mutableString] convertLineEndingsToLineEndingString:[self lineEndingString]];
    [[self documentUndoManager] endUndoGrouping];

    [textStorage setShouldWatchLineEndings:YES];
    [textStorage setHasMixedLineEndings:NO];
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
        if ([[window windowController] document]==self) {
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
    [windowController gotoLine:aLine];
    if (aFlag) [[windowController window] makeKeyAndOrderFront:self];
}

- (void)selectRange:(NSRange)aRange {
    PlainTextWindowController *windowController=[self topmostWindowController];
    [windowController selectRange:aRange];
    [[windowController window] makeKeyAndOrderFront:self];
}

- (void)selectRangeInBackground:(NSRange)aRange {
    PlainTextWindowController *windowController=[self topmostWindowController];
    [windowController selectRange:aRange];
}

- (void)addFindAllController:(FindAllController *)aController
{
    [aController setDocument:self];
    if (I_findAllControllers) [I_findAllControllers addObject:aController];
    //else NSLog(@"Something has gone terribly wrong: No FindAllController array");
}

- (void)removeFindAllController:(FindAllController *)aController
{
    if (I_findAllControllers) [I_findAllControllers removeObject:aController];
    //else NSLog(@"Something has gone terribly wrong: No FindAllController array");
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
        hostAddress = [NSString stringWithFormat:@"%@.local", (NSString *)localHostName];
        CFRelease(localHostName);
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

    if ([alertIdentifier isEqualToString:@"SelectEncodingAlert"]) {
        TCMMMSession *session=[self session];
        if (!I_flags.isReceivingContent && [session isServer] && [session participantCount]<=1) {
            NSStringEncoding encoding = [[alertContext objectForKey:@"Encoding"] unsignedIntValue];
            if (returnCode == NSAlertFirstButtonReturn) {
                DEBUGLOG(@"FileIOLogDomain", DetailedLogLevel, @"Trying to convert file encoding");
                [[alert window] orderOut:self];
                if (![[I_textStorage string] canBeConvertedToEncoding:encoding]) {
                    NSAlert *newAlert = [[[NSAlert alloc] init] autorelease];
                    [newAlert setAlertStyle:NSWarningAlertStyle];
                    [newAlert setMessageText:NSLocalizedString(@"Error", nil)];
                    [newAlert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"Encoding %@ not applicable", nil), [NSString localizedNameOfStringEncoding:encoding]]];
                    [newAlert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
                    [newAlert beginSheetModalForWindow:[self windowForSheet]
                                         modalDelegate:nil
                                        didEndSelector:nil
                                           contextInfo:NULL];
                    // didn't work so update bottom status bar to previous state
                    [self TCM_sendPlainTextDocumentDidChangeEditStatusNotification];
                } else {
                    [self setFileEncoding:encoding];
                    [self updateChangeCount:NSChangeDone];
                }
            }

            if (returnCode == NSAlertSecondButtonReturn) {
              // canceled so update bottom status bar to previous state
              [self TCM_sendPlainTextDocumentDidChangeEditStatusNotification];
            }

            if (returnCode == NSAlertThirdButtonReturn) {
                DEBUGLOG(@"FileIOLogDomain", DetailedLogLevel, @"Trying to reinterpret file encoding");
                [[alert window] orderOut:self];
                NSData *stringData = [[I_textStorage string] dataUsingEncoding:[self fileEncoding]];
                NSString *reinterpretedString = [[NSString alloc] initWithData:stringData encoding:encoding];
                if (!reinterpretedString) {
                    NSAlert *newAlert = [[[NSAlert alloc] init] autorelease];
                    [newAlert setAlertStyle:NSWarningAlertStyle];
                    [newAlert setMessageText:NSLocalizedString(@"Error", nil)];
                    [newAlert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"Encoding %@ not reinterpretable", nil), [NSString localizedNameOfStringEncoding:encoding]]];
                    [newAlert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
                    [newAlert beginSheetModalForWindow:[self windowForSheet]
                                         modalDelegate:nil
                                        didEndSelector:nil
                                           contextInfo:NULL];
                    // didn't work so update bottom status bar to previous state
                    [self TCM_sendPlainTextDocumentDidChangeEditStatusNotification];
                } else {
                    BOOL isEdited = [self isDocumentEdited];
                    [I_textStorage beginEditing];
                    [I_textStorage replaceCharactersInRange:NSMakeRange(0, [I_textStorage length]) withString:reinterpretedString];
                    [I_textStorage setAttributes:[self plainTextAttributes] range:NSMakeRange(0, [I_textStorage length])];

                    if (I_flags.highlightSyntax) {
                        [self highlightSyntaxInRange:NSMakeRange(0, [I_textStorage length])];
                    }

                    [I_textStorage endEditing];

                    [[self documentUndoManager] removeAllActions];
                    [reinterpretedString release];
                    [self setFileEncoding:encoding];
                    if (!isEdited) {
                        [self updateChangeCount:NSChangeCleared];
                    }
                    
                    [self TCM_validateLineEndings];
                }
            }
        }
    } else if ([alertIdentifier isEqualToString:@"ShouldPromoteAlert"]) {
        if (returnCode == NSAlertThirdButtonReturn) {
            [self setFileEncoding:NSUnicodeStringEncoding];
            NSTextView *textView = [alertContext objectForKey:@"TextView"];
            NSString *replacementString = [alertContext objectForKey:@"ReplacementString"];
            if (replacementString) [textView insertText:replacementString];
            [[self documentUndoManager] removeAllActions];
        } else if (returnCode == NSAlertSecondButtonReturn) {
            [self setFileEncoding:NSUTF8StringEncoding];
            NSTextView *textView = [alertContext objectForKey:@"TextView"];
            NSString *replacementString = [alertContext objectForKey:@"ReplacementString"];
            if (replacementString) [textView insertText:replacementString];
            [[self documentUndoManager] removeAllActions];
        }

    } else if ([alertIdentifier isEqualToString:@"DocumentChangedExternallyAlert"]) {
        if (returnCode == NSAlertFirstButtonReturn) {
            [self setKeepDocumentVersion:YES];
            [self updateChangeCount:NSChangeDone];
        } else if (returnCode == NSAlertSecondButtonReturn) {
            DEBUGLOG(@"FileIOLogDomain", DetailedLogLevel, @"Revert document");
            BOOL successful = [self revertToSavedFromFile:[self fileName] ofType:[self fileType]];
            if (successful) {
                [self updateChangeCount:NSChangeCleared];
            }
        }
    } else if ([alertIdentifier isEqualToString:@"EditAnywayAlert"]) {
        if (returnCode == NSAlertFirstButtonReturn) {
            [self setEditAnyway:YES];
            NSTextView *textView = [alertContext objectForKey:@"TextView"];
            [textView insertText:[alertContext objectForKey:@"ReplacementString"]];
        }
    } else if ([alertIdentifier isEqualToString:@"MixedLineEndingsAlert"]) {
        LineEnding lineEnding = [[alertContext objectForKey:@"LineEnding"] unsignedShortValue];
        if (returnCode == NSAlertFirstButtonReturn) {
            [self convertLineEndingsToLineEnding:lineEnding];
        } else if (returnCode == NSAlertSecondButtonReturn) {
            [self setLineEnding:lineEnding];
        }
    } else if ([alertIdentifier isEqualToString:@"PasteWrongLineEndingsAlert"]) {
        NSTextView *textView = [alertContext objectForKey:@"TextView"];
        NSString *replacementString = [alertContext objectForKey:@"ReplacementString"];
        if (returnCode == NSAlertFirstButtonReturn) {
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

- (void)updateChangeCount:(NSDocumentChangeType)changeType {
    if (transientDocument == self) {
        transientDocument = nil;
    }
    
    if (changeType==NSChangeCleared || I_flags.shouldChangeChangeCount) {
        [super updateChangeCount:changeType];
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
        [self performSelector:@selector(highlightSyntaxLoop) withObject:nil afterDelay:0.3];
        I_flags.isPerformingSyntaxHighlighting=YES;
    }
}

- (void)highlightSyntaxLoop {
//    NSLog(@"%s",__FUNCTION__);
    I_flags.isPerformingSyntaxHighlighting=NO;
    if (I_flags.highlightSyntax) {
        SyntaxHighlighter *highlighter=[I_documentMode syntaxHighlighter];
        if (highlighter) {
            if (!I_flags.syntaxHighlightingIsSuspended) {
                if (![highlighter colorizeDirtyRanges:I_textStorage ofDocument:self]) {
                    [self performHighlightSyntax];
                }
            } else {
                [self performHighlightSyntax];
            }
        }
    }
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

- (void)sendInitialUserState {
    TCMMMSession *session=[self session];
    NSString *sessionID=[session sessionID];
    NSEnumerator *writingParticipants=[[[session participants] objectForKey:@"ReadWrite"] objectEnumerator];
    TCMMMUser *user=nil;
    while ((user=[writingParticipants nextObject])) {
        SelectionOperation *selectionOperation=[[user propertiesForSessionID:sessionID] objectForKey:@"SelectionOperation"];
        if (selectionOperation) {
            [session documentDidApplyOperation:selectionOperation];
        }
    }

    [session documentDidApplyOperation:[SelectionOperation selectionOperationWithRange:[[[[self topmostWindowController] activePlainTextEditor] textView] selectedRange] userID:[TCMMMUserManager myUserID]]];
}

- (void)sessionDidDenyJoinRequest:(TCMMMSession *)aSession {
    [I_documentProxyWindowController joinRequestWasDenied];
}

- (void)sessionDidAcceptJoinRequest:(TCMMMSession *)aSession {
}

- (void)sessionDidReceiveKick:(TCMMMSession *)aSession {
    [self TCM_generateNewSession];
    NSAlert *alert=[NSAlert alertWithMessageText:NSLocalizedString(@"Kicked",@"Kick title in Sheet") defaultButton:NSLocalizedString(@"OK",@"Ok in sheet") alternateButton:@"" otherButton:@"" informativeTextWithFormat:NSLocalizedString(@"KickedInfo",@"Kick info in Sheet")];
    [alert setAlertStyle:NSInformationalAlertStyle];
    [alert beginSheetModalForWindow:[self windowForSheet] modalDelegate:nil didEndSelector:NULL contextInfo:nil];
}

- (void)sessionDidCancelInvitation:(TCMMMSession *)aSession {
    [I_documentProxyWindowController invitationWasCanceled];
}

- (void)sessionDidReceiveClose:(TCMMMSession *)aSession {
    [self TCM_generateNewSession];
    NSAlert *alert=[NSAlert alertWithMessageText:NSLocalizedString(@"Closed",@"Server Closed Document title in Sheet") defaultButton:NSLocalizedString(@"OK",@"Ok in sheet") alternateButton:@"" otherButton:@"" informativeTextWithFormat:NSLocalizedString(@"ClosedInfo",@"Server Closed Document info in Sheet")];
    [alert setAlertStyle:NSInformationalAlertStyle];
    [alert beginSheetModalForWindow:[self windowForSheet] modalDelegate:nil didEndSelector:NULL contextInfo:nil];
}

- (void)sessionDidLoseConnection:(TCMMMSession *)aSession {
    if ([[self windowControllers] count]>0) {
        [self TCM_generateNewSession];
        if (I_flags.isReceivingContent) {
            PlainTextWindowController *controller=[[self windowControllers] objectAtIndex:0];
            [controller didLoseConnection];
        } else {
            NSAlert *alert=[NSAlert alertWithMessageText:NSLocalizedString(@"LostConnection",@"LostConnection title in Sheet") defaultButton:NSLocalizedString(@"OK",@"Ok in sheet") alternateButton:@"" otherButton:@"" informativeTextWithFormat:NSLocalizedString(@"LostConnectionInfo",@"LostConnection info in Sheet")];
            [alert setAlertStyle:NSInformationalAlertStyle];
            [alert beginSheetModalForWindow:[self windowForSheet] modalDelegate:nil didEndSelector:NULL contextInfo:nil];
        }
    } else if (I_documentProxyWindowController) {
        [I_documentProxyWindowController didLoseConnection];
    }
}

- (void)session:(TCMMMSession *)aSession didReceiveSessionInformation:(NSDictionary *)aSessionInformation {
    DocumentModeManager *manager=[DocumentModeManager sharedInstance];
    DocumentMode *mode=[manager documentModeForIdentifier:[aSessionInformation objectForKey:@"DocumentMode"]];
    if (!mode) {
        mode = [manager documentModeForExtension:[[aSession filename] pathExtension]];
    }
    [self setDocumentMode:mode];
    [self setLineEnding:[[aSessionInformation objectForKey:DocumentModeLineEndingPreferenceKey] intValue]];
    [self setTabWidth:[[aSessionInformation objectForKey:DocumentModeTabWidthPreferenceKey] intValue]];
    [self setUsesTabs:[[aSessionInformation objectForKey:DocumentModeUseTabsPreferenceKey] boolValue]];
    [self setWrapLines:[[aSessionInformation objectForKey:DocumentModeWrapLinesPreferenceKey] boolValue]];
    [self setWrapMode:[[aSessionInformation objectForKey:DocumentModeWrapModePreferenceKey] intValue]];

    //[self setFileName:[aSession filename]];
    [self setTemporaryDisplayName:[aSession filename]];

    [self makeWindowControllers];
    PlainTextWindowController *windowController=(PlainTextWindowController *)[[self windowControllers] objectAtIndex:0];
    I_flags.isReceivingContent=YES;
    [windowController setIsReceivingContent:YES];
    [I_documentProxyWindowController dissolveToWindow:[windowController window]];
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
    return result;
}

- (void)setFileName:(NSString *)fileName {
    [super setFileName:fileName];
    TCMMMSession *session=[self session];
    if ([session isServer]) {
        [session setFilename:[self preparedDisplayName]];
    }
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
        [windowController setIsReceivingContent:NO];
    }
    I_flags.isReceivingContent = NO;
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
    NSEnumerator *windowControllers=[[self windowControllers] objectEnumerator];
    PlainTextWindowController *windowController;
    while ((windowController=[windowControllers nextObject])) {
        [result addObjectsFromArray:[windowController plainTextEditors]];
    }
    return result;
}

- (void)handleOperation:(TCMMMOperation *)aOperation {
    if ([[aOperation operationID] isEqualToString:[TextOperation operationID]]) {
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

        TextOperation *operation=(TextOperation *)aOperation;
        NSTextStorage *textStorage=[self textStorage];
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
            [self TCM_charIsBracket:[aString characterAtIndex:0]]) {
            I_bracketMatching.matchingBracketPosition=aRange.location;
        }
    } else {
        [self updateChangeCount:NSChangeUndone];
    }
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
                    while (--position>=lineRange.location) {
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
                indentRange.length=0;
                while (NSMaxRange(indentRange)<affectedRange.location &&
                       ([string characterAtIndex:NSMaxRange(indentRange)]==[@" "  characterAtIndex:0] ||
                        [string characterAtIndex:NSMaxRange(indentRange)]==[@"\t" characterAtIndex:0])) {
                    indentRange.length++;
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
                [self TCM_charIsBracket:[string characterAtIndex:position]]) {
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
            if ([self TCM_charIsBracket:[string characterAtIndex:charIndex]]) {
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
    // NSLog(@"%s", __FUNCTION__);
    return [I_textStorage string];
}

- (void)setScriptedContents:(id)value {
    // NSLog(@"%s: %d", __FUNCTION__, value);
    [self replaceTextInRange:NSMakeRange(0,[I_textStorage length]) withString:value];
}

- (TextStorage *)scriptedPlainContents {
    // NSLog(@"%s", __FUNCTION__);
    return (TextStorage *)I_textStorage;
}

- (void)setScriptedPlainContents:(id)value {
    // NSLog(@"%s: %@", __FUNCTION__, value);
    if ([value isKindOfClass:[NSString class]]) {
        [self replaceTextInRange:NSMakeRange(0, [I_textStorage length]) withString:value];
    }
}

- (id)coerceValueForDocumentMode:(id)value {
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

- (id)scriptSelection {
    if ([self isProxyDocument]) return nil;
    return [[[self topmostWindowController] activePlainTextEditor] scriptSelection];
}

- (void)setScriptSelection:(id)aSelection {
    if ([self isProxyDocument]) return;
    [[[self topmostWindowController] activePlainTextEditor] setScriptSelection:aSelection];
}

- (NSArray *)orderedWindows {
    NSMutableArray *orderedWindows = [NSMutableArray array];
    NSEnumerator *windowsEnumerator = [[NSApp orderedWindows] objectEnumerator];
    NSWindow *window;
    while ((window = [windowsEnumerator nextObject])) {
        if ([[[window windowController] document] isEqual:self] && ![self isProxyDocument]) {
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


@end
