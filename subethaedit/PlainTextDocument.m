//
//  PlainTextDocument.m
//  SubEthaEdit
//
//  Created by Martin Ott on Tue Feb 24 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Carbon/Carbon.h>

#import "TCMMillionMonkeys/TCMMillionMonkeys.h"
#import "PlainTextEditor.h"
#import "DocumentController.h"
#import "PlainTextDocument.h"
#import "PlainTextWindowController.h"

#import "DocumentModeManager.h"
#import "DocumentMode.h"
#import "SyntaxHighlighter.h"

#import "TextStorage.h"
#import "EncodingManager.h"
#import "TextOperation.h"
#import "SelectionOperation.h"
#import "ODBEditorSuite.h"


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


enum {
    UnknownStringEncoding = NoStringEncoding,
    SmallestCustomStringEncoding = 0xFFFFFFF0
};

static NSString * const PlainTextDocumentSyntaxColorizeNotification = @"PlainTextDocumentSyntaxColorizeNotification";
NSString * const PlainTextDocumentDidChangeDisplayNameNotification = @"PlainTextDocumentDidChangeDisplayNameNotification";
NSString * const PlainTextDocumentDefaultParagraphStyleDidChangeNotification = @"PlainTextDocumentDefaultParagraphStyleDidChangeNotification";


@interface PlainTextDocument (PlainTextDocumentPrivateAdditions) 
- (void)TCM_invalidateDefaultParagraphStyle;
- (void)TCM_styleFonts;
- (void)TCM_initHelper;
- (void)TCM_sendPlainTextDocumentDidChangeDisplayNameNotification;
- (void)TCM_handleOpenDocumentEvent;
- (void)TCM_sendODBCloseEvent;
- (void)TCM_sendODBModifiedEvent;
@end

#pragma mark -

@implementation PlainTextDocument

- (void)TCM_sendPlainTextDocumentDidChangeDisplayNameNotification {
    [[NSNotificationQueue defaultQueue] 
    enqueueNotification:[NSNotification notificationWithName:PlainTextDocumentDidChangeDisplayNameNotification object:self]
           postingStyle:NSPostWhenIdle 
           coalesceMask:NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender 
               forModes:[NSArray arrayWithObject:NSDefaultRunLoopMode]];
}

- (void)TCM_styleFonts {
    [I_fonts.boldFont autorelease];
    [I_fonts.italicFont autorelease];
    [I_fonts.boldItalicFont autorelease];
    NSFontManager *manager=[NSFontManager sharedFontManager];
    I_fonts.boldFont = [[manager convertFont:I_fonts.plainFont toHaveTrait:NSBoldFontMask] retain];
    I_fonts.italicFont = [[manager convertFont:I_fonts.plainFont toHaveTrait:NSItalicFontMask] retain];
    I_fonts.boldItalicFont = [[manager convertFont:I_fonts.plainFont toHaveTrait:NSBoldFontMask & NSItalicFontMask] retain];
}

- (void)TCM_initHelper {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(performHighlightSyntax)
        name:PlainTextDocumentSyntaxColorizeNotification object:self];
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
                    err = AESend([appleEvent aeDesc], &reply, kAENoReply, kAEHighPriority, kAEDefaultTimeout, NULL, NULL);
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
                    err = AESend([appleEvent aeDesc], &reply, kAENoReply, kAEHighPriority, kAEDefaultTimeout, NULL, NULL);
                }
            }
        }
    } else {
        DEBUGLOG(@"FileIOLogDomain", DetailedLogLevel, @"Unable to generate direct parameter.");
    }
}

- (id)init {
    self = [super init];
    if (self) {
    
        // Add your subclass-specific initialization here.
        // If an error occurs here, send a [self release] message and return nil.
        [self setSession:[[TCMMMSession alloc] initWithDocument:self]];
        [[TCMMMPresenceManager sharedInstance] registerSession:[self session]];
        I_textStorage = [TextStorage new];
        [I_textStorage setDelegate:self];
        [self setDocumentMode:[[DocumentModeManager sharedInstance] baseMode]];
        I_flags.isRemotelyEditingTextStorage=NO;
        [self TCM_initHelper];
    }
    return self;
}

- (id)initWithSession:(TCMMMSession *)aSession {
    self = [super init];
    if (self) {
        [self setSession:aSession];
        [[TCMMMPresenceManager sharedInstance] registerSession:[self session]];
        I_textStorage = [TextStorage new];
        [I_textStorage setDelegate:self];
        [self setDocumentMode:[[DocumentModeManager sharedInstance] baseMode]];
        I_flags.isRemotelyEditingTextStorage=NO;
        [aSession setDocument:self];
        [self TCM_initHelper];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (I_flags.isAnnounced) {
        [[TCMMMPresenceManager sharedInstance] concealSession:[self session]];
    }
    
    [self TCM_sendODBCloseEvent];
        
    [[TCMMMPresenceManager sharedInstance] unregisterSession:[self session]];
    [I_textStorage setDelegate:nil];
    [I_textStorage release];
    [I_session release];
    [I_plainTextAttributes release];
    [I_fonts.plainFont release];
    [I_fonts.boldFont release];
    [I_fonts.italicFont release];
    [I_fonts.boldItalicFont release];
    [I_defaultParagraphStyle release];
    [I_fileAttributes release];
    [I_ODBParameters release];
    [super dealloc];
}

- (void)setSession:(TCMMMSession *)aSession {
    [I_session autorelease];
    I_session = [aSession retain];
}

- (TCMMMSession *)session {
    return I_session;
}

- (NSTextStorage *)textStorage {
    return I_textStorage;
}

- (DocumentMode *)documentMode {
    return I_documentMode;
}

- (void)setDocumentMode:(DocumentMode *)aDocumentMode {
    [I_documentMode autorelease];
    SyntaxHighlighter *highlighter=[I_documentMode syntaxHighlighter];
    [highlighter cleanUpTextStorage:[self textStorage]];
     I_documentMode = [aDocumentMode retain];
    I_flags.highlightSyntax = [[aDocumentMode defaultForKey:DocumentModeHighlightSyntaxPreferenceKey] boolValue];
    NSDictionary *fontAttributes=[aDocumentMode defaultForKey:DocumentModeFontAttributesPreferenceKey];
    NSFont *newFont=[NSFont fontWithName:[fontAttributes objectForKey:NSFontNameAttribute] size:[[fontAttributes objectForKey:NSFontSizeAttribute] floatValue]];
    if (!newFont) newFont=[NSFont userFixedPitchFontOfSize:[[fontAttributes objectForKey:NSFontSizeAttribute] floatValue]];
    I_flags.indentNewLines=[[aDocumentMode defaultForKey:DocumentModeIndentNewLinesPreferenceKey] boolValue];
    I_flags.usesTabs=[[aDocumentMode defaultForKey:DocumentModeUseTabsPreferenceKey] boolValue];
    [self setTabWidth:[[aDocumentMode defaultForKey:DocumentModeTabWidthPreferenceKey] intValue]];
    [self setPlainFont:newFont];
    [I_textStorage addAttributes:[self plainTextAttributes]
                               range:NSMakeRange(0,[I_textStorage length])];
    if (I_flags.highlightSyntax) {
        [self highlightSyntaxInRange:NSMakeRange(0,[[self textStorage] length])];
    }
}

- (unsigned int)fileEncoding {
    return [(TextStorage *)[self textStorage] encoding];
}

- (void)setFileEncoding:(unsigned int)anEncoding {
    [(TextStorage *)[self textStorage] setEncoding:anEncoding];
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

- (IBAction)announce:(id)aSender {
    DEBUGLOG(@"Document", 5, @"announce");
    [[TCMMMPresenceManager sharedInstance] announceSession:[self session]];
    I_flags.isAnnounced=YES;
}

- (IBAction)conceal:(id)aSender {
    DEBUGLOG(@"Document", 5, @"conceal");
    [[TCMMMPresenceManager sharedInstance] concealSession:[self session]];
    I_flags.isAnnounced=NO;
}

- (IBAction)newView:(id)aSender {
    PlainTextWindowController *controller=[PlainTextWindowController new];
    [self addWindowController:controller];
    [controller showWindow:aSender];
    [controller release];
    [self TCM_sendPlainTextDocumentDidChangeDisplayNameNotification];
}

- (void)selectEncoding:(id)aSender {

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
        [alert beginSheetModalForWindow:[self windowForSheet] modalDelegate:nil didEndSelector:nil contextInfo:nil];
        // @selector(sheetDidEndShouldConvert:returnCode:contextInfo:)
    }
}

- (void)makeWindowControllers {
    DEBUGLOG(@"blah",5,@"makeWindowCotrollers");
    [self addWindowController:[[PlainTextWindowController new] autorelease]];
}

- (void)removeWindowController:(NSWindowController *)windowController {
    [super removeWindowController:windowController];
    [self TCM_sendPlainTextDocumentDidChangeDisplayNameNotification];
}

- (void)windowControllerWillLoadNib:(NSWindowController *)aController {
    [super windowControllerWillLoadNib:aController];
    DEBUGLOG(@"blah",5,@"Willload");
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
}


- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
    [super windowControllerDidLoadNib:aController];
    [self TCM_handleOpenDocumentEvent];
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

- (void)TCM_handleOpenDocumentEvent {
    DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel, @"TCM_handleOpenDocumentEvent");
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
                        //[self selectRange:NSMakeRange(selectionRange->startRange, selectionRange->endRange - selectionRange->startRange) scrollToVisible:YES];
                    } else {
                        DEBUGLOG(@"FileIOLogDomain", DetailedLogLevel, @"gotoLine");
                        //[self gotoLine:selectionRange->lineNum + 1 orderFront:YES];
                    }
                }
                
                // save ODB parameters in case of ODB event
                NSMutableDictionary *ODBParameters = [NSMutableDictionary dictionary];
                if (fileSenderDesc) {
                    [ODBParameters setObject:[fileSenderDesc data] forKey:@"keyFileSender"];
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
}

- (void)runModalSavePanelForSaveOperation:(NSSaveOperationType)saveOperation delegate:(id)delegate didSaveSelector:(SEL)didSaveSelector contextInfo:(void *)contextInfo {
    I_lastSaveOperation = saveOperation;
    [super runModalSavePanelForSaveOperation:saveOperation delegate:delegate didSaveSelector:didSaveSelector contextInfo:contextInfo];
}

- (BOOL)prepareSavePanel:(NSSavePanel *)savePanel {
    if (I_lastSaveOperation == NSSaveToOperation) {
        if (![NSBundle loadNibNamed:@"SavePanelAccessory" owner:self])  {
            NSLog(@"Failed to load SavePanelAccessory.nib");
            return nil;
        }

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
    }
    
    return [super prepareSavePanel:savePanel];
}

- (void)saveToFile:(NSString *)fileName saveOperation:(NSSaveOperationType)saveOperation delegate:(id)delegate didSaveSelector:(SEL)didSaveSelector contextInfo:(void *)contextInfo {
    if (saveOperation == NSSaveToOperation) {
        I_encodingFromLastRunSaveToOperation = [[O_encodingPopUpButton selectedItem] tag];
    }
    [super saveToFile:fileName saveOperation:saveOperation delegate:delegate didSaveSelector:didSaveSelector contextInfo:contextInfo];
}

- (NSData *)dataRepresentationOfType:(NSString *)aType {

    if ([aType isEqualToString:@"PlainTextType"]) {
        if (I_lastSaveOperation == NSSaveToOperation) {
            DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel, @"Save a copy using encoding: %@", [NSString localizedNameOfStringEncoding:I_encodingFromLastRunSaveToOperation]);
            [[EncodingManager sharedInstance] unregisterEncoding:I_encodingFromLastRunSaveToOperation];
            return [[I_textStorage string] dataUsingEncoding:[self fileEncoding] allowLossyConversion:YES];
        } else {
            DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel, @"Save using encoding: %@", [NSString localizedNameOfStringEncoding:[self fileEncoding]]);
            return [[I_textStorage string] dataUsingEncoding:[self fileEncoding] allowLossyConversion:YES];
        }
    }

    return nil;
}


- (BOOL)readFromFile:(NSString *)fileName ofType:(NSString *)docType {

    DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel, @"readFromFile:%@ ofType:%@", fileName, docType);

    if (![docType isEqualToString:@"PlainTextType"]) {
        return NO;
    }
    
    BOOL isDocumentFromOpenPanel = [(DocumentController *)[NSDocumentController sharedDocumentController] isDocumentFromLastRunOpenPanel:self];
    DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel, @"Document opened via open panel: %@", isDocumentFromOpenPanel ? @"YES" : @"NO");
    
    BOOL isDir, fileExists;
    fileExists = [[NSFileManager defaultManager] fileExistsAtPath:fileName isDirectory:&isDir];
    if (!fileExists || isDir) {
        return NO;
    }
    
    NSDictionary *fattrs = [[NSFileManager defaultManager] fileAttributesAtPath:fileName traverseLink:YES];
    [self setFileAttributes:fattrs];
    
    NSTextStorage *textStorage = [self textStorage];

//    int oldLength = [textStorage length];
//    [self setIsNew:NO];

    // Determine mode
    DocumentMode *mode = nil;
    if (isDocumentFromOpenPanel) {
        NSString *identifier = [(DocumentController *)[NSDocumentController sharedDocumentController] modeIdentifierFromLastRunOpenPanel];
        if ([identifier isEqualToString:AUTOMATICMODEIDENTIFIER]) {
            NSString *extension = [fileName pathExtension];
            mode = [[DocumentModeManager sharedInstance] documentModeForExtension:extension];
        } else {
            mode = [[DocumentModeManager sharedInstance] documentModeForIdentifier:identifier];
        }
    }
    
    if (!mode) {
        // get default mode (may be automatic)
        // currently following workaround is used
        mode = [[DocumentModeManager sharedInstance] documentModeForExtension:[fileName pathExtension]];
    }
    
    
    // Determine encoding
    NSStringEncoding encoding;
    if (isDocumentFromOpenPanel) {
        DocumentController *documentController = (DocumentController *)[NSDocumentController sharedDocumentController];
        encoding = [documentController encodingFromLastRunOpenPanel];
        if (encoding == ModeStringEncoding) {
            encoding = [[mode defaultForKey:DocumentModeEncodingPreferenceKey] unsignedIntValue];
        }
    } else {
        encoding = [[mode defaultForKey:DocumentModeEncodingPreferenceKey] unsignedIntValue];
    }
    
    NSDictionary *docAttrs = nil;
    NSMutableDictionary *options = [NSMutableDictionary dictionary];
    
    if (encoding < SmallestCustomStringEncoding) {
        DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel, @"Setting \"CharacterEncoding\" option: %@", [NSString localizedNameOfStringEncoding:encoding]);
        [options setObject:[NSNumber numberWithUnsignedInt:encoding] forKey:@"CharacterEncoding"];
    }
    
    //[options setObject:[self plainTextAttributes] forKey:@"DefaultAttributes"];
    
    [[textStorage mutableString] setString:@""]; // Empty the document
    
    NSURL *fileURL = [NSURL fileURLWithPath:[fileName stringByExpandingTildeInPath]];
    
    while (TRUE) {
        BOOL success;
        
        [textStorage beginEditing];
        success = [textStorage readFromURL:fileURL options:options documentAttributes:&docAttrs];
        [textStorage endEditing];
        
        DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel, @"Read successful? %@", success ? @"YES" : @"NO");
        DEBUGLOG(@"FileIOLogDomain", DetailedLogLevel, @"documentAttributes: %@", [docAttrs description]);
        
        if (!success) {
            NSNumber *encodingNumber = [options objectForKey:@"CharacterEncoding"];
            if (encodingNumber != nil) {
                NSStringEncoding systemEncoding = CFStringConvertEncodingToNSStringEncoding(CFStringGetSystemEncoding());
                NSStringEncoding triedEncoding = [encodingNumber unsignedIntValue];
                if (triedEncoding == NSUTF8StringEncoding && triedEncoding != systemEncoding) {
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
    
    [self setFileEncoding:[[docAttrs objectForKey:@"CharacterEncoding"] unsignedIntValue]];
    DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel, @"fileEncoding: %@", [NSString localizedNameOfStringEncoding:[self fileEncoding]]);
    
    // guess lineEnding and set instance variable
//    unsigned startIndex = 0;
//    unsigned lineEndIndex = 0;
//    unsigned contentsEndIndex = 0;
//    [[_textStorage string] getLineStart:&startIndex end:&lineEndIndex contentsEnd:&contentsEndIndex forRange:NSMakeRange(0, 0)];
//    
//    unsigned length = lineEndIndex - contentsEndIndex;
//    if (LOGLEVEL(2)) NSLog(@"lineEnding, lineEndIndex: %u, contentsEndIndex: %u, length: %u", lineEndIndex, contentsEndIndex, length);
//    if (length == 1) {
//        unichar character = [[_textStorage string] characterAtIndex:contentsEndIndex];
//        if (character == [@"\n" characterAtIndex:0]) {
//            [self setLineEnding:LineEndingLF];
//        } else if (character == [@"\r" characterAtIndex:0]) {
//            [self setLineEnding:LineEndingCR];
//        }
//    } else if (length == 2) {
//        unichar character1 = [[_textStorage string] characterAtIndex:contentsEndIndex];
//        unichar character2 = [[_textStorage string] characterAtIndex:contentsEndIndex + 1];
//        if ((character1 == [@"\r" characterAtIndex:0]) && (character2 == [@"\n" characterAtIndex:0])) {
//            [self setLineEnding:LineEndingCRLF];
//        }
//    }
//    
//    if (LOGLEVEL(1)) NSLog(@"lineEnding: %u", [self lineEnding]);
    

//    if (_colorizeSyntax) {
//        [self syntaxColorizeInRange:NSMakeRange(0,[_textStorage length])];
//    }

//    if (oldLength > 0) {
//        // inform other about revert
//        [_jupiterUndoManager removeAllActions];
//        [_jupiterObject changeTextInRange:NSMakeRange(0, oldLength)
//                        replacementString:[_textStorage string]]; 
//    }
//    //[self updateMaxYForRadarScroller];

    [I_textStorage addAttributes:[self plainTextAttributes]
                           range:NSMakeRange(0, [I_textStorage length])];

    [self setDocumentMode:mode];
    
    return YES;
}

- (BOOL)writeWithBackupToFile:(NSString *)fullDocumentPath ofType:(NSString *)docType saveOperation:(NSSaveOperationType)saveOperationType {
    BOOL result = [super writeWithBackupToFile:(NSString *)fullDocumentPath ofType:(NSString *)docType saveOperation:saveOperationType];
    if (result) {
        if (saveOperationType == NSSaveOperation) {
            [self TCM_sendODBModifiedEvent];
        } else if (saveOperationType == NSSaveAsOperation) {
            if ([fullDocumentPath isEqualToString:[self fileName]]) {
                [self TCM_sendODBModifiedEvent];
            } else {
                [self setODBParameters:nil];
            }
        }
    }
    return result;
}

- (BOOL)validateMenuItem:(NSMenuItem *)anItem {
    SEL selector=[anItem action];
    if (selector==@selector(announce:)) {
        return !I_flags.isAnnounced;
    } else if (selector==@selector(conceal:)) {
        return I_flags.isAnnounced;
    } else if (selector==@selector(toggleSyntaxHighlighting:)) {
        [anItem setState:(I_flags.highlightSyntax?NSOnState:NSOffState)];
        return YES;
    } else if (selector == @selector(selectEncoding:)) {
        if ([self fileEncoding] == (unsigned int)[anItem tag]) {
            [anItem setState:NSOnState];
        } else {
            [anItem setState:NSOffState];
        }
    } else if (selector == @selector(chooseMode:)) {
        DocumentModeManager *modeManager=[DocumentModeManager sharedInstance];
        NSString *identifier=[modeManager documentModeIdentifierForTag:[anItem tag]];
        if (identifier && [[self documentMode] isEqualTo:[modeManager documentModeForIdentifier:identifier]]) {
            [anItem setState:NSOnState];
        } else {
            [anItem setState:NSOffState];
        }
    } else if (selector == @selector(toggleUsesTabs:)) {
        [anItem setState:(I_flags.usesTabs?NSOnState:NSOffState)];
        return YES;
    } else if (selector == @selector(toggleCharacterWrapping:)) {
        [anItem setState:(I_flags.wrapsCharacters?NSOnState:NSOffState)];
        return YES;
    } else if (selector == @selector(toggleIndentNewLines:)) {
        [anItem setState:(I_flags.indentNewLines?NSOnState:NSOffState)];
        return YES;
    } else if (selector == @selector(changeTabWidth:)) {
        [anItem setState:(I_tabWidth==[[anItem title]intValue]?NSOnState:NSOffState)];
    }

    return [super validateMenuItem:anItem];
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
    [I_fonts.plainFont autorelease];
    I_fonts.plainFont = [aFont copy];
    [self TCM_styleFonts];
    [I_plainTextAttributes release];
    I_plainTextAttributes=nil;
    [self TCM_invalidateDefaultParagraphStyle];
}

- (NSDictionary *)plainTextAttributes {
    if (!I_plainTextAttributes) {
//        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSFont *userFont = [NSFont userFixedPitchFontOfSize:0.0];
//        BOOL usesScreenFonts = [[defaults objectForKey:UsesScreenFontsPreferenceKey] boolValue];
        NSFont *displayFont = nil;
        if (NO)
            displayFont = [userFont screenFont];
        if (displayFont == nil)
            displayFont = userFont;
//        NSMutableParagraphStyle *myParagraphStyle = [[NSMutableParagraphStyle new] autorelease];
//        [myParagraphStyle setParagraphStyle:[NSParagraphStyle defaultParagraphStyle]];
//        NSArray *tabStops;
        //float spaceWidth = [userFont widthOfString:@" "];
//        unsigned spacesPerTab=[defaults integerForKey:TabWidthPreferenceKey];
        //float tabWidth = spaceWidth*spacesPerTab;

//        tabStops = tabStopArrayForFontAndTabWidth(displayFont, spacesPerTab);

//        [myParagraphStyle setTabStops:tabStops];
        NSColor *foregroundColor=[NSColor blackColor];

        NSMutableDictionary *attributes=[NSMutableDictionary new];
        [attributes setObject:[self fontWithTrait:0]
                            forKey:NSFontAttributeName];
        [attributes setObject:[NSNumber numberWithInt:0]
                            forKey:NSLigatureAttributeName];
//        [I_plainTextAttributes setObject:myParagraphStyle
//                            forKey:NSParagraphStyleAttributeName];
        [attributes setObject:foregroundColor
                            forKey:NSForegroundColorAttributeName];
        I_plainTextAttributes=attributes;
    }
    return I_plainTextAttributes;

}

- (NSParagraphStyle *)defaultParagraphStyle {
    if (!I_defaultParagraphStyle) {
        I_defaultParagraphStyle = [[NSMutableParagraphStyle alloc] init];
        [I_defaultParagraphStyle setTabStops:[NSArray array]];
        NSFont *font=[self fontWithTrait:nil];
        float charWidth = [font widthOfString:@" "];
        if (charWidth<=0) {
            charWidth=[font maximumAdvancement].width;
        }
        [I_defaultParagraphStyle setLineBreakMode:I_flags.wrapsCharacters?NSLineBreakByCharWrapping:NSLineBreakByWordWrapping];
        [I_defaultParagraphStyle setDefaultTabInterval:charWidth*I_tabWidth];
        [I_defaultParagraphStyle addTabStop:[[[NSTextTab alloc] initWithType:NSLeftTabStopType location:charWidth*I_tabWidth] autorelease]];
        [[self textStorage] addAttribute:NSParagraphStyleAttributeName value:I_defaultParagraphStyle range:NSMakeRange(0,[[self textStorage] length])];
    }
    return I_defaultParagraphStyle;
}


- (void)TCM_invalidateDefaultParagraphStyle {
    [I_defaultParagraphStyle autorelease];
    I_defaultParagraphStyle=nil;
    [[NSNotificationQueue defaultQueue] 
        enqueueNotification:[NSNotification notificationWithName:PlainTextDocumentDefaultParagraphStyleDidChangeNotification object:self]
               postingStyle:NSPostWhenIdle 
               coalesceMask:NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender 
                   forModes:[NSArray arrayWithObject:NSDefaultRunLoopMode]];
}

- (BOOL)wrapsCharacters {
    return I_flags.wrapsCharacters;
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
}

#pragma mark -
#pragma mark ### Syntax Highlighting ###

- (IBAction)toggleShowInvisibles:(id)aSender {
    NSEnumerator *layoutManagers = [[[self textStorage] layoutManagers] objectEnumerator];
    NSLayoutManager *layoutManager = nil;
    while ((layoutManager = [layoutManagers nextObject])) {
        [layoutManager setShowsInvisibleCharacters:![layoutManager showsInvisibleCharacters]];
    }
}

- (IBAction)toggleCharacterWrapping:(id)aSender {
    I_flags.wrapsCharacters = !I_flags.wrapsCharacters;
    [self TCM_invalidateDefaultParagraphStyle];
}

- (IBAction)toggleUsesTabs:(id)aSender {
    I_flags.usesTabs=!I_flags.usesTabs;
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
    }
}

- (void)changeFont:(id)aSender {
    NSFont *newFont = [aSender convertFont:I_fonts.plainFont];
    [self setPlainFont:newFont];
        [I_textStorage addAttributes:[self plainTextAttributes]
                               range:NSMakeRange(0,[I_textStorage length])];
    if (I_flags.highlightSyntax) {
        [self highlightSyntaxInRange:NSMakeRange(0,[[self textStorage] length])];
    }

}

- (IBAction)toggleSyntaxHighlighting:(id)aSender {
    I_flags.highlightSyntax = !I_flags.highlightSyntax;
    if (I_flags.highlightSyntax) {
        [self highlightSyntaxInRange:NSMakeRange(0,[I_textStorage length])];
    } else {
        [I_textStorage addAttributes:[self plainTextAttributes]
                               range:NSMakeRange(0,[I_textStorage length])];
    }
}

- (void)highlightSyntaxInRange:(NSRange)aRange {
    if (I_flags.highlightSyntax) {
        NSRange range=NSIntersectionRange(aRange,NSMakeRange(0,[I_textStorage length]));
        if (range.length>0) {
            [I_textStorage addAttribute:kSyntaxHighlightingIsDirtyAttributeName 
                                  value:kSyntaxHighlightingIsDirtyAttributeValue 
                                  range:range];
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
    I_flags.isPerformingSyntaxHighlighting=NO;
    if (I_flags.highlightSyntax) {
        SyntaxHighlighter *highlighter=[I_documentMode syntaxHighlighter];
        if (highlighter && ![highlighter colorizeDirtyRanges:I_textStorage]) {
            [self performHighlightSyntax];
        }
    }
}

#pragma mark -
#pragma mark ### Session Interaction ###

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
        NSMutableArray   *oldSelections=[NSMutableArray array];
        NSEnumerator *editorEnumerator=[editors objectEnumerator];
        PlainTextEditor *editor;
        while ((editor=[editorEnumerator nextObject])) {
            [oldSelections addObject:[SelectionOperation selectionOperationWithRange:[[editor textView] selectedRange] userID:@"doesn't matter"]];
        }


        I_flags.isRemotelyEditingTextStorage=YES;
        TextOperation *operation=(TextOperation *)aOperation;
        NSTextStorage *textStorage=[self textStorage];
        [textStorage beginEditing];
        [textStorage replaceCharactersInRange:[operation affectedCharRange]
                                   withString:[operation replacementString]];
        [textStorage addAttribute:@"UserID" value:[operation userID] 
                            range:NSMakeRange([operation affectedCharRange].location,
                                              [[operation replacementString] length])];
        [textStorage endEditing];

        // set selection of all textviews
        int index=0;
        for (index=0;index<(int)[editors count];index++) {
            SelectionOperation *selectionOperation = [oldSelections objectAtIndex:index];
            [[TCMMMTransformator sharedInstance] transformOperation:selectionOperation serverOperation:aOperation];
            editor = [editors objectAtIndex:index];
            [[editor textView] setSelectedRange:[selectionOperation selectedRange]];
        }

        I_flags.isRemotelyEditingTextStorage=NO;

    }   
}

#pragma mark -
#pragma mark ### TextStorage Delegate Methods ###
- (void)textStorage:(NSTextStorage *)aTextStorage didReplaceCharactersInRange:(NSRange)aRange withString:(NSString *)aString {
    //NSLog(@"textStorage:%@ didReplaceCharactersInRange:%@ withString:%@",aTextStorage,NSStringFromRange(aRange),aString);
    if (!I_flags.isRemotelyEditingTextStorage) {
        TextOperation *textOp=[TextOperation textOperationWithAffectedCharRange:aRange replacementString:aString userID:[TCMMMUserManager myUserID]];
        [[self session] documentDidApplyOperation:textOp];
    }
    if (I_flags.highlightSyntax) {
        if ([aString length]) {
            NSRange range=NSMakeRange(aRange.location,[aString length]);
            [aTextStorage addAttribute:kSyntaxHighlightingIsDirtyAttributeName value:kSyntaxHighlightingIsDirtyAttributeValue range:range];
            [self highlightSyntaxInRange:range];
        } else {
            NSRange range=NSMakeRange(aRange.location!=0?aRange.location-1:aRange.location,1);
            if ([aTextStorage length]>=NSMaxRange(range)) {
                [aTextStorage addAttribute:kSyntaxHighlightingIsDirtyAttributeName value:kSyntaxHighlightingIsDirtyAttributeValue range:range];
            }
            [self highlightSyntaxInRange:range];
        }
        
    }
}

#pragma mark -
#pragma mark ### TextView Notifications / Extended Delegate ###

- (BOOL)textView:(NSTextView *)aTextView doCommandBySelector:(SEL)aSelector {
    // NSLog(@"TextDocument textView doCommandBySelector:%@",NSStringFromSelector(aSelector));
    NSRange affectedRange=[aTextView rangeForUserTextChange];
//    NSRange selectedRange=[aTextView selectedRange];
//    if (aSelector==@selector(cancel:)) {
//        if (_flags.hasBlockeditRanges) {
//            [self stopBlockedit];
//            [(TextDocumentWindowController *)[[aTextView window] windowController] updatePositionTextField];
//            return YES;
//        }
//    } else 
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
                [aTextView setSelectedRange:NSMakeRange(deleteRange.location,deleteRange.length)];
                [aTextView insertText:@""];
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
        NSString *_lineEndingString=@"\n";
        if (indentString) {
            [aTextView insertText:[NSString stringWithFormat:@"%@%@",_lineEndingString,indentString]];        
        } else {
            [aTextView insertText:_lineEndingString];
        }
        return YES;
        
    } 
    else if (aSelector==@selector(insertTab:) && !I_flags.usesTabs) {
        // when we have a tab we have to find the last linebreak
        NSRange lineRange=[[[self textStorage] string] lineRangeForRange:affectedRange];        
        NSString *replacementString=[@" " stringByPaddingToLength:I_tabWidth-((affectedRange.location-lineRange.location)%I_tabWidth)
                                                       withString:@" " startingAtIndex:0];
        [aTextView insertText:replacementString];
        return YES;
    } 
//    else if ((aSelector==@selector(moveLeft:) || aSelector==@selector(moveRight:)) &&
//                [defaults boolForKey:ShowMatchingBracketsPreferenceKey]) {
//        unsigned int position=0;
//        if (aSelector==@selector(moveLeft:)) {
//            position=selectedRange.location-1;        
//        } else {
//            position=NSMaxRange(selectedRange);
//        }
//        NSString *string=[_textStorage string];
//        if (position>=0 && position<[_textStorage length] && 
//            isBracket([string characterAtIndex:position]) ) { 
//            [self highlightBracketAtPosition:position inTextView:aTextView];
//        }
//    }
//    _flags.controlBlockedit=YES;
    return NO;
}


- (void)textViewDidChangeSelection:(NSNotification *)aNotification {
    if (!I_flags.isRemotelyEditingTextStorage) {
        NSRange selectedRange = [(NSTextView *)[aNotification object] selectedRange];
        SelectionOperation *selOp = [SelectionOperation selectionOperationWithRange:selectedRange userID:[TCMMMUserManager myUserID]];
        [[self session] documentDidApplyOperation:selOp];
    }
}

@end
