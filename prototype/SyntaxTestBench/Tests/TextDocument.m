//
//  TextDocument.m
//  Hydra
//
//  Created by Dominik Wagner on Fri Jan 24 2003.
//  Copyright (c) 2003 TheCodingMonkeys. All rights reserved.
//

#import <AddressBook/AddressBook.h>
#import <Carbon/Carbon.h>
#import "TextDocument.h"
#import "ODBEditorSuite.h"
#import "ConnectionManager.h"

enum {
    UnknownStringEncoding = NoStringEncoding,
    SmallestCustomStringEncoding = 0xFFFFFFF0
};

NSString * const kDocumentDocumentIdProperty=@"DocumentId";
NSString * const kDocumentTitleProperty=@"DocumentTitle";

NSString * const TextDocumentUserDidLeaveNotification=@"TextDocumentUserDidLeaveNotification";
NSString * const TextDocumentUserDidJoinNotification=@"TextDocumentUserDidJoinNotification";
NSString * const TextDocumentSelectionOfUserHasChangedNotification=@"TextDocumentSelectionOfUserHasChangedNotification";
NSString * const TextDocumentSyntaxColorizeNotification=@"TextDocumentSyntaxColorizeNotification";
NSString * const TextDocumentTextDidChangeNotification=@"TextDocumentTextDidChangeNotification";
NSString * const TextDocumentNewNotification = @"TextDocumentNewNotification";
NSString * const TextDocumentDeallocNotification = @"TextDocumentDeallocNotification";


// Attributes
NSString * const kHighlightColorAttribute=@"HighlightColor";
NSString * const kBlockeditAttributeName =@"Blockedit";
NSString * const kBlockeditAttributeValue=@"YES";

// Keys for _participantData
NSString * const kSelectionProperty=@"Selection";

@interface NSMenuItem (Sorting)
- (NSComparisonResult)compareAlphabetically:(NSMenuItem *)aNotherMenuItem;
@end

@implementation NSMenuItem (Sorting)
- (NSComparisonResult)compareAlphabetically:(NSMenuItem *)aMenuItem {
    return [[self title] caseInsensitiveCompare:[aMenuItem title]];
}
@end

@interface TextDocument (Private)

- (NSString *)newFileName;
- (void)setNewFileName:(NSString *)newName;
- (void)sendODBCloseEvent;
- (void)sendODBModifiedEvent;

@end

@implementation TextDocument (Private)

- (NSString *)newFileName
{
    return _newFileName;
}

- (void)setNewFileName:(NSString *)newName
{
    [_newFileName autorelease];
    _newFileName = [newName copy];
}

- (void)sendODBCloseEvent
{
    if (LOGLEVEL(3)) NSLog(@"preparing ODB close event");
    if (LOGLEVEL(3)) NSLog(@"ODBParameters: %@", [[self ODBParameters] description]);
    
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
                    if (LOGLEVEL(3)) NSLog(@"Sending apple event");
                    AppleEvent reply;
                    err = AESend([appleEvent aeDesc], &reply, kAENoReply, kAEHighPriority, kAEDefaultTimeout, NULL, NULL);
                }
            }
        }
    }
}

- (void)sendODBModifiedEvent
{
    OSErr err;
    if (LOGLEVEL(3)) NSLog(@"preparing ODB modified event");
    if (LOGLEVEL(3)) NSLog(@"ODBParameters: %@", [[self ODBParameters] description]);
    if ([self ODBParameters] == nil || [[self ODBParameters] count] == 0)
        return;
    
    if (_saveCopyFromRunningSavePanel)
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
        if (LOGLEVEL(3)) NSLog(@"Failed to create fsspec");
        return;
    }
    
    NSAppleEventDescriptor *newLocationDesc = nil;
    NSString *newFileName = [self newFileName];
    if (newFileName != nil && [newFileName length] > 0) {
        NSURL *fileURL = [NSURL fileURLWithPath:newFileName];
        FSRef fileRef;
        CFURLGetFSRef((CFURLRef)fileURL, &fileRef);
        FSSpec fsSpec;
        err = FSGetCatalogInfo(&fileRef, kFSCatInfoNone, NULL, NULL, &fsSpec, NULL);
        if (err == noErr) {
            newLocationDesc = [NSAppleEventDescriptor descriptorWithDescriptorType:typeFSS bytes:&fsSpec length:sizeof(fsSpec)];
        }
    }
    [self setNewFileName:nil];
            
    if (directObjectDesc != nil) {
        NSData *signatureData = [[self ODBParameters] objectForKey:@"keyFileSender"];
        if (signatureData != nil) {
            NSAppleEventDescriptor *addressDescriptor = [NSAppleEventDescriptor descriptorWithDescriptorType:typeApplSignature bytes:[signatureData bytes] length:[signatureData length]];
            if (addressDescriptor != nil) {
                NSAppleEventDescriptor *appleEvent = [NSAppleEventDescriptor appleEventWithEventClass:kODBEditorSuite eventID:kAEModifiedFile targetDescriptor:addressDescriptor returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID];
                [appleEvent setParamDescriptor:directObjectDesc forKeyword:keyDirectObject];
                if (newLocationDesc != nil) {
                    [appleEvent setParamDescriptor:newLocationDesc forKeyword:keyNewLocation];
                }
                NSAppleEventDescriptor *tokenDesc = [[self ODBParameters] objectForKey:@"keyFileSenderToken"];
                if (tokenDesc != nil) {
                    [appleEvent setParamDescriptor:tokenDesc forKeyword:keySenderToken];
                }
                if (appleEvent != nil) {
                    if (LOGLEVEL(3)) NSLog(@"Sending apple event");
                    AppleEvent reply;
                    err = AESend([appleEvent aeDesc], &reply, kAENoReply, kAEHighPriority, kAEDefaultTimeout, NULL, NULL);
                }
            }
        }
    }
}

@end


@implementation TextDocument

- (id)init {
    self = [super init];
    if (self) {
    
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        // Add your subclass-specific initialization here.
        // If an error occurs here, send a [self release] message and return nil.
        CFUUIDRef myUUID = CFUUIDCreate(NULL);
        CFStringRef myUUIDString = CFUUIDCreateString(NULL, myUUID);
        [self setDocumentId:(NSString *)myUUIDString];
        CFRelease(myUUIDString);
        CFRelease(myUUID);
        _isRemote=NO;
        _isShared=NO;
        _autoAccept=NO;
        _changeHighlighting=[defaults boolForKey:HighlightChangesLocalPreferenceKey];

        _symbolListNeedsUpdate=YES;
        _symbolPopUpMenu=[[NSMenu alloc] initWithTitle:@"Symbols"];
        _sortedSymbolPopUpMenu=[[NSMenu alloc] initWithTitle:@"Symbols"];

        _saveCopyFromRunningSavePanel = NO;
        _participantData=[NSMutableDictionary new];
        _participants   =[NSMutableArray new];
        _joinRequests   =[NSMutableArray new];
        _textStorage    =[HydraTextStorage new];
                
        _lastTextOperation=nil;
        _undoGroupStart=NO;
        _textAttributes = nil;
        _showMatchingBracketPosition=NSNotFound;
        _textChangeTextView=nil;
        
        _webPreviewWindowController=nil;
        
        NSStringEncoding encoding = [[defaults objectForKey:DefaultEncodingPreferenceKey] unsignedIntValue];
        if (encoding == UnknownStringEncoding) {
            encoding = CFStringConvertEncodingToNSStringEncoding(CFStringGetSystemEncoding());
        }
        [[EncodingManager sharedInstance] registerEncoding:encoding];
        _fileEncoding = encoding;
        [self setLineEnding:[[defaults objectForKey:DefaultLineEndingPreferenceKey] intValue]];
        [self setEncodingAccessoryPopUpButton:nil];
        [self setUserIdOfHost:[[[UserManager sharedInstance] me] objectForKey:kUserUserIdProperty]];
        [_participants addObject:_userIdOfHost];

    
            
        _jupiterUndoManager=[[JupiterUndoManager alloc] initWithDocument:self];
        _jupiterObject=[[JupiterServer alloc] initWithDocument:self undoManager:_jupiterUndoManager];
        _outsideAction=0;  
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(preferencesDidChange:)
                                                     name:kPreferencesDidChangeNotification 
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(performSyntaxColorize:)
                                                     name:TextDocumentSyntaxColorizeNotification
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(undoManagerWillUndoRedo:)
                                                     name:JupiterUndoManagerWillRedoChangeNotification
                                                   object:_jupiterUndoManager];
        
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(undoManagerWillUndoRedo:)
                                                     name:JupiterUndoManagerWillUndoChangeNotification
                                                   object:_jupiterUndoManager];
        
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(undoManagerDidUndoRedo:)
                                                     name:JupiterUndoManagerDidUndoChangeNotification
                                                   object:_jupiterUndoManager];
        
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(undoManagerDidUndoRedo:)
                                                     name:JupiterUndoManagerDidRedoChangeNotification
                                                   object:_jupiterUndoManager];

        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(textDocumentTextDidChange:)
                                                     name:TextDocumentTextDidChangeNotification
                                                   object:self];
        _undoingTextView=nil;
        _flags.hasBlockeditRanges=NO;
        _flags.isBlockediting    =NO;
        _flags.didBlockedit      =NO;
        _flags.controlBlockedit  =NO;
        [self setSyntaxName:[[NSUserDefaults standardUserDefaults]  objectForKey:DefaultSyntaxModePreferenceKey]];        
        _colorizeSyntax=[[NSUserDefaults standardUserDefaults] boolForKey:DefaultSyntaxColorizePreferenceKey];
        [self setIsNew:YES];
        [self setFileAttributes:nil];
        [self setODBParameters:nil];
        [self setNewFileName:nil];
    }
    return self;
}

- (void)dealloc {
    
    if (_isRemote) {
        [[ConnectionManager sharedInstance] leaveDocument:_documentId];
        [[DocumentBrowserController sharedInstance] updateTableView];
        [[NSNotificationCenter defaultCenter] postNotificationName:TextDocumentDeallocNotification
                                                            object:self];
    } else {
        [self unshareDocument];
    }
    
    [self sendODBCloseEvent];
    
    if (LOGLEVEL(4)) NSLog(@"TextDocument dealloc");
    [_webPreviewWindowController release];
    [[EncodingManager sharedInstance] unregisterEncoding:_fileEncoding];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_symbolPopUpMenu release];
    [_sortedSymbolPopUpMenu release];
    [_symbols release];
    NSRunLoop *runLoop=[NSRunLoop currentRunLoop];
    [runLoop cancelPerformSelectorsWithTarget:self];
    [_syntaxHighlighter release];
    [_jupiterObject invalidate];
    [_jupiterObject release];
    [_jupiterUndoManager release];
    [_documentId release];
    [_sharedTitle release];
    [_textStorage release];
    [_participants release];
    [_participantData release];
    [_joinRequests release];
    [_textAttributes release];
    [_lastTextOperation release];
    [_fileAttributes release];
    [_ODBParameters release];
    [_newFileName release];
    [super dealloc];
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
    [super windowControllerDidLoadNib:aController];
    // should be posted just once, when the first windowController was loaded
    [[NSNotificationCenter defaultCenter] postNotificationName:TextDocumentNewNotification object:self];
}

- (void)makeWindowControllers {
    [self addWindowController:[[TextDocumentWindowController new] autorelease]];
}

- (void)removeWindowController:(NSWindowController *)windowController {
    [super removeWindowController:windowController];
    [self synchronizeWindowTitleWithDocumentName];
}

#pragma mark -

- (IBAction) newView:(id)aSender {
    TextDocumentWindowController *controller=[TextDocumentWindowController new];
    [self addWindowController:controller];
    [controller showWindow:aSender];
    [controller release];
    [self synchronizeWindowTitleWithDocumentName];
}

- (NSDictionary *)fileAttributesToWriteToFile:(NSString *)fullDocumentPath ofType:(NSString *)documentTypeName saveOperation:(NSSaveOperationType)saveOperationType {
    if ([self isNew]) {
        [self setIsNew:NO];

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
    } else {
        NSMutableDictionary *newAttributes = [NSMutableDictionary dictionaryWithDictionary:[super fileAttributesToWriteToFile:fullDocumentPath ofType:documentTypeName saveOperation:saveOperationType]];
        if ([self fileAttributes] != nil) {
            [newAttributes setObject:[[self fileAttributes] objectForKey:NSFileHFSTypeCode] forKey:NSFileHFSTypeCode];
            [newAttributes setObject:[[self fileAttributes] objectForKey:NSFileHFSCreatorCode] forKey:NSFileHFSCreatorCode];
        } else {
            if (LOGLEVEL(2)) NSLog(@"File is not new, but no fileAttributes are set.");
        }
        return newAttributes;
    }
}

#pragma mark -
#pragma mark ### WindowController update/propagation methods ###

- (void)reloadPeopleTableViewData {
    NSEnumerator *windowControllers=[[self windowControllers] objectEnumerator];
    TextDocumentWindowController *windowController;
    while ((windowController=(TextDocumentWindowController *)[windowControllers nextObject])) {
        [[windowController peopleTableView] reloadData];
    }
}

- (void)updateMaxYForRadarScroller {
    NSEnumerator *windowControllers=[[self windowControllers] objectEnumerator];
    TextDocumentWindowController *windowController;
    while ((windowController=(TextDocumentWindowController *)[windowControllers nextObject])) {
        [windowController updateMaxYForRadarScroller];
    }
}

- (void)updatePositionTextField {
    NSEnumerator *windowControllers=[[self windowControllers] objectEnumerator];
    TextDocumentWindowController *windowController;
    while ((windowController=(TextDocumentWindowController *)[windowControllers nextObject])) {
        [windowController updatePositionTextField];
    }
}

- (void)validateToolbars {
    NSEnumerator *windowControllers=[[self windowControllers] objectEnumerator];
    TextDocumentWindowController *windowController;
    while ((windowController=(TextDocumentWindowController *)[windowControllers nextObject])) {
        [[[windowController window] toolbar] validateVisibleItems];
    }
}

- (void)synchronizeWindowTitleWithDocumentName {
    NSEnumerator *windowControllers=[[self windowControllers] objectEnumerator];
    TextDocumentWindowController *windowController;
    while ((windowController=(TextDocumentWindowController *)[windowControllers nextObject])) {
        [windowController synchronizeWindowTitleWithDocumentName];
    }

}

- (void)updateSymbolList {
    if (_symbolListNeedsUpdate) {
        [_symbols release];
        _symbols=[[_syntaxHighlighter getFunctions:_textStorage] retain];
        
        int count=[_symbolPopUpMenu numberOfItems];
        while (count) {
            [_symbolPopUpMenu removeItemAtIndex:count-1];
            count=[_symbolPopUpMenu numberOfItems];
        }

        count=[_sortedSymbolPopUpMenu numberOfItems];
        while (count) {
            [_sortedSymbolPopUpMenu removeItemAtIndex:count-1];
            count=[_sortedSymbolPopUpMenu numberOfItems];
        }
        
        NSEnumerator *symbols=[_symbols objectEnumerator];    
        NSMenuItem *prototypeMenuItem=[[NSMenuItem alloc] initWithTitle:@"" 
                                                                 action:@selector(didChooseGotoSymbolMenuItem:) 
                                                          keyEquivalent:@""];
        [prototypeMenuItem setTarget:self];

        NSMutableArray *itemsToSort=[NSMutableArray array];

        NSDictionary *symbol;
        int i=0;
        while ((symbol=[symbols nextObject])) {
            NSMenuItem *menuItem;
            NSString   *name=[symbol objectForKey:@"Name"];
            if ([name isEqualToString:@""]) {
                [_symbolPopUpMenu addItem:[NSMenuItem separatorItem]];
            } else {
                menuItem=[prototypeMenuItem copy];
                [menuItem setTag:i];
                [menuItem setTitle:name];
                [_symbolPopUpMenu addItem:menuItem];
                [itemsToSort addObject:[[menuItem copy]autorelease]];
                [menuItem release];
            }
            i++;
        }  
        [prototypeMenuItem release];

        [itemsToSort sortUsingSelector:@selector(compareAlphabetically:)];
        symbols=[itemsToSort objectEnumerator];
        NSMenuItem *menuItem;
        while (menuItem=[symbols nextObject]) {
            [_sortedSymbolPopUpMenu addItem:menuItem];
        }

        _symbolListNeedsUpdate=NO;

        NSEnumerator *windowControllers=[[self windowControllers] objectEnumerator];
        TextDocumentWindowController *windowController;
        while ((windowController=(TextDocumentWindowController *)[windowControllers nextObject])) {
            [windowController setSymbolPopUpMenuNeedsUpdate:YES];
        }
    }
}

- (void)closeDrawers {

    NSEnumerator *windowControllers=[[self windowControllers] objectEnumerator];
    TextDocumentWindowController *windowController;
    while ((windowController=(TextDocumentWindowController *)[windowControllers nextObject])) {
        [windowController validateDrawerButtons];
        NSEnumerator *drawers=[[[windowController window] drawers] objectEnumerator];
        NSDrawer *drawer;
        while ((drawer=[drawers nextObject])) {
            [drawer close];
        }
    }
    
}

#pragma mark -
#pragma mark ### Accessors ###

- (NSDictionary *)ODBParameters {
    return _ODBParameters;
}

- (void)setODBParameters:(NSDictionary *)newParameters {
    [_ODBParameters autorelease];
    _ODBParameters = [newParameters retain];
}

- (BOOL)isNew {
    return _flags.isNew;
}

- (void)setIsNew:(BOOL)newValue {
    _flags.isNew = newValue;
}

- (NSDictionary *)fileAttributes {
    return _fileAttributes;
}

- (void)setFileAttributes:(NSDictionary *)newFileAttributes {
    [_fileAttributes autorelease];
    _fileAttributes = [newFileAttributes retain];   
}

- (LineEnding)lineEnding {
    return _lineEnding;
}

- (void)setLineEnding:(LineEnding)newLineEnding {
    _lineEnding = newLineEnding;
    switch(_lineEnding) {
        case LineEndingLF:
            _lineEndingString=@"\n";
            break;
        case LineEndingCR:
            _lineEndingString=@"\r";
            break;
        case LineEndingCRLF:
            _lineEndingString=@"\r\n";
            break;
        case LineEndingUnicodeLineSeparator:
            _lineEndingString=@"\n";
            break;
        case LineEndingUnicodeParagraphSeparator:
            _lineEndingString=@"\r\n";
            break;        
    }
}

- (unsigned int)fileEncoding {
    return _fileEncoding;
}

- (void)setFileEncoding:(unsigned int)newFileEncoding {
    [[EncodingManager sharedInstance] unregisterEncoding:_fileEncoding];
    _fileEncoding = newFileEncoding;
    [[EncodingManager sharedInstance] registerEncoding:newFileEncoding];
}

- (NSPopUpButton *)encodingAccessoryPopUpButton {
    return encodingAccessoryPopUpButton;
}

- (void)setEncodingAccessoryPopUpButton:(NSPopUpButton *)newPopUpButton {
    [encodingAccessoryPopUpButton autorelease];
    encodingAccessoryPopUpButton = [newPopUpButton retain];
}

- (NSObject<Jupiter> *)jupiterObject {
    return _jupiterObject;
}

- (NSString *)documentId {
    return _documentId;
}

- (void)setDocumentId:(NSString *)aNewId {
    if (_documentId != aNewId) {
        NSString *oldValue = _documentId;
        _documentId = [aNewId retain];
        [oldValue release];
    }
}

- (NSString *)userIdOfHost {
    return _userIdOfHost;
}

- (void)setUserIdOfHost:(NSString*)aUserId {
    if (_userIdOfHost != aUserId) {
        NSString *oldValue = _userIdOfHost;
        _userIdOfHost = [aUserId retain];
        [oldValue release];
    }
}

- (NSString *)sharedTitle {
    return _sharedTitle;
}

- (void)setSharedTitle:(NSString *)newSharedTitle {
    if (newSharedTitle==nil) newSharedTitle=@"";
    if (_sharedTitle != newSharedTitle) {
        NSString *oldValue = _sharedTitle;
        _sharedTitle=[newSharedTitle copy];
        [oldValue autorelease];
    }
}

- (void)setFileName:(NSString *)aFileName {
    [super setFileName:aFileName];
    if (![self isRemote]) {
        NSEnumerator *users=[_participants objectEnumerator];
        NSString *userId;
        NSDictionary *documentInfo=[self infoDictionary];
        while ((userId=[users nextObject])) {
            if (![userId isEqualToString:[UserManager myId]]) {
                [[ConnectionManager sharedInstance] sendDictionary:documentInfo 
                                                       forDocument:[self documentId] 
                                                            toUser:userId];
            }
        }
    }
}


-(NSString*)displayName {
    if (_isRemote) {
        return _sharedTitle;
    } else {
        NSString *result=[super displayName];
        if (![self fileName]) {
            result=[result stringByAppendingString:@".txt"];
        }
        return result;
    }
}


- (NSDictionary *)infoDictionary {
    return [NSDictionary dictionaryWithObjectsAndKeys:_documentId,kDocumentDocumentIdProperty,
                                                      [self displayName],kDocumentTitleProperty,nil];
}                                                                                                    
                                                                                                    
- (NSTextStorage *)textStorage {
    return _textStorage;
}

- (BOOL)changeHighlighting {
    return _changeHighlighting;
}

- (void)setChangeHighlighting:(BOOL)aBoolean {
    _changeHighlighting=aBoolean;
    if ([_textStorage length]>0) {
        [self recolorTextStorageInRange:NSMakeRange(0,[_textStorage length])];
    }
}

- (BOOL)isShared {
    return _isShared;
}

- (BOOL)isRemote {
    return _isRemote;
}

- (void)setIsRemote:(BOOL)aBool {
    _isRemote=aBool;
}

- (BOOL)autoAccept {
    return _autoAccept;
}

- (void)setAutoAccept:(BOOL)aBool {
    if (aBool!=_autoAccept) {
        _autoAccept=aBool;
        NSEnumerator *windowControllers=[[self windowControllers] objectEnumerator];
        TextDocumentWindowController *windowController;
        while ((windowController=(TextDocumentWindowController *)[windowControllers nextObject])) {
            [windowController validateAutoAcceptButton];
        }       
    }
}



- (NSMutableDictionary *)participantData {
    return _participantData;
}

- (NSRange)selectionRangeForUser:(NSString *)aUserId {
    NSRange result=NSMakeRange(NSNotFound,0);
    NSArray *selectionArray=[[_participantData objectForKey:aUserId] objectForKey:kSelectionProperty];
    if (selectionArray) {
        result.location=[[selectionArray objectAtIndex:0] unsignedIntValue];
        result.length  =[[selectionArray objectAtIndex:1] unsignedIntValue];
    }
    return result;
}

- (NSMutableArray *)participants {
    return _participants;
}

- (NSMutableArray *)requests {
    return _joinRequests;
}

- (NSMutableArray *)lineStarts {
    return [_textStorage lineStarts];
}

- (void)setLineStartsOnlyValidUpTo:(unsigned int)aLocation {
    [_textStorage setLineStartsOnlyValidUpTo:aLocation];
}

static NSArray *tabStopArrayForFontAndTabWidth(NSFont *font, unsigned tabWidth) {
    static NSMutableArray *array = nil;
    static float currentWidthOfTab = -1;
    float charWidth;
    float widthOfTab;
    unsigned i;

    charWidth = [font widthOfString:@" "];
    if (charWidth<=0) {
        charWidth=[font maximumAdvancement].width;
    }
    widthOfTab =charWidth * tabWidth;

    if (!array) {
        array = [[NSMutableArray allocWithZone:NULL] initWithCapacity:100];
    }

    if (widthOfTab != currentWidthOfTab) {
        [array removeAllObjects];
        for (i = 1; i <= 100; i++) {
            NSTextTab *tab = [[NSTextTab alloc] initWithType:NSLeftTabStopType location:(float)((int)((widthOfTab * i)*1))/1.];
            [array addObject:tab];
            [tab release];
        }
        currentWidthOfTab = widthOfTab;
    }

    if (LOGLEVEL(6)) NSLog(@"TabstopArray: %@", [array description]);
    return array;
}

- (NSMutableDictionary *)plainTextAttributes {
    if (!_textAttributes) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSFont *userFont = [NSFont userFixedPitchFontOfSize:0.0];
        BOOL usesScreenFonts = [[defaults objectForKey:UsesScreenFontsPreferenceKey] boolValue];
        NSFont *displayFont = nil;
        if (usesScreenFonts)
            displayFont = [userFont screenFont];
        if (displayFont == nil)
            displayFont = userFont;
        NSMutableParagraphStyle *myParagraphStyle = [[NSMutableParagraphStyle new] autorelease];
        [myParagraphStyle setParagraphStyle:[NSParagraphStyle defaultParagraphStyle]];
        NSArray *tabStops;
        //float spaceWidth = [userFont widthOfString:@" "];
        unsigned spacesPerTab=[defaults integerForKey:TabWidthPreferenceKey];
        //float tabWidth = spaceWidth*spacesPerTab;

        tabStops = tabStopArrayForFontAndTabWidth(displayFont, spacesPerTab);

        [myParagraphStyle setTabStops:tabStops];
        NSColor *foregroundColor=[NSColor documentForegroundColor];

        _textAttributes=[NSMutableDictionary new];
        [_textAttributes setObject:userFont
                            forKey:NSFontAttributeName];
        [_textAttributes setObject:[NSNumber numberWithInt:0]
                            forKey:NSLigatureAttributeName];
        [_textAttributes setObject:myParagraphStyle
                            forKey:NSParagraphStyleAttributeName];
        [_textAttributes setObject:foregroundColor
                            forKey:NSForegroundColorAttributeName];
    }
    return _textAttributes;
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {

    if ([menuItem action] == @selector(selectedEncoding:)){
        if ([self fileEncoding] == (unsigned int)[menuItem tag]) {
            [menuItem setState:NSOnState];
        } else {
            [menuItem setState:NSOffState];
        }
        if ([self isRemote] || [self isShared]) {
            return NO;
        }
    } else if ([menuItem action] == @selector(convertLineEndings:)) {
        [menuItem setState:(([menuItem tag] == (int)[self lineEnding]) ? NSOnState : NSOffState)];
        if ([self isRemote] || [self isShared]) {
            return NO;
        }
    } else if ([menuItem action] == @selector(saveDocument:) ||
               [menuItem action] == @selector(saveDocumentAs:)) {
        return ![self isRemote];           
    } else if ([menuItem action] == @selector(revertDocumentToSaved:)) {
        return (![self isRemote] && [self fileName]);
    } else if ([menuItem action] == @selector(chooseSyntaxName:)) {
        if ([menuItem tag]==kNoneModeMenuItemTag)   {
            [menuItem setState:[_syntaxName isEqualToString:@""]?NSOnState:NSOffState];
        } else {
            [menuItem setState:[[menuItem title] isEqualToString:_syntaxName]?NSOnState:NSOffState];
        }
        return YES;
    } else if ([menuItem action] == @selector(toggleSyntaxColoring:)) {
        [menuItem setState:_colorizeSyntax?NSOnState:NSOffState];
        return YES;
    }
    return YES;
}

- (SyntaxHighlighter *)syntaxHighlighter {
    return [[_syntaxHighlighter retain] autorelease];
}

- (void)setSyntaxName:(NSString *)aSyntaxName {
    [_syntaxName autorelease];
    _syntaxName=[aSyntaxName copy];
    NSString *syntaxFile=[[SyntaxManager sharedInstance] syntaxDefinitionForName:_syntaxName];
    [[NSRunLoop currentRunLoop] cancelPerformSelectorsWithTarget:self];
    [_syntaxHighlighter cleanup:_textStorage];
    [_syntaxHighlighter release];
    if (syntaxFile) {
        _syntaxHighlighter=[[SyntaxHighlighter alloc] initWithFile:syntaxFile];
    } else {
        _syntaxHighlighter=nil;
    }   
    _symbolListNeedsUpdate=YES; 
}

- (void)setLastTextOperationWithRange:(NSRange)aAffectedCharRange 
                    replacementString:(NSString *)aReplacementString {
    [_lastTextOperation autorelease];
    _lastTextOperation=[JupiterTextOperation new];
    [_lastTextOperation setAffectedCharRange:aAffectedCharRange];
    [_lastTextOperation setReplacementString:aReplacementString];
}

- (NSRange)lastTextOperationRange {
    if (_lastTextOperation) {
        return [_lastTextOperation affectedCharRange];
    } else {
        return NSMakeRange(NSNotFound,0);
    }
}

- (NSString *)lastTextOperationString {
    return [_lastTextOperation replacementString];
}

#pragma mark -
#pragma mark ### Actions ###

- (IBAction)showWebPreview:(id)aSender {
    if (!_webPreviewWindowController) {
        _webPreviewWindowController=[[WebPreviewWindowController alloc] initWithDocument:self];
    }
    if (![[_webPreviewWindowController window] isVisible]) {
        [_webPreviewWindowController showWindow:self];
        [_webPreviewWindowController refresh:self];
    } else {
        [[_webPreviewWindowController window] orderFront:self];
    }
}

- (IBAction)refreshWebPreview:(id)aSender {
    if (!_webPreviewWindowController) {
        [self showWebPreview:self];
    } else {
        [_webPreviewWindowController refresh:self];
    }
}

- (IBAction)toggleSyntaxColoring:(id)aSender {
    _colorizeSyntax=!_colorizeSyntax;
    [_textStorage beginEditing];
    if (_colorizeSyntax) {
        [self syntaxColorizeInRange:NSMakeRange(0,[_textStorage length])];
    } else {
        [_textStorage addAttributes:[self plainTextAttributes] 
                              range:NSMakeRange(0,[_textStorage length])];
    }
    [_textStorage endEditing];
}

- (void)chooseSyntaxName:(id)aSender {
    
    [self setSyntaxName:[aSender tag]==kNoneModeMenuItemTag?@"":[aSender title]];
    if (_colorizeSyntax) {
        if (_syntaxHighlighter) {
            [self syntaxColorizeInRange:NSMakeRange(0,[_textStorage length])];
        } else {
            [_textStorage addAttributes:[self plainTextAttributes] 
                                  range:NSMakeRange(0,[_textStorage length])];
        }
    }
    [self updatePositionTextField];
}

- (IBAction)clearBackground:(id)aSender {
    NSRange textRange=NSMakeRange(0,[_textStorage length]);
    [_textStorage removeAttribute:kHighlightFromUserAttribute range:textRange];
    [self recolorTextStorageInRange:textRange];
}

- (IBAction)convertLineEndings:(id)aSender {

    if (LOGLEVEL(1)) NSLog(@"Convert line endings to: %d", [aSender tag]);
    NSMutableString *mutableString = [_textStorage mutableString];
    //NSRange charRange = NSMakeRange(0, [mutableString length]);
    //if ([self shouldChangeTextInRange:charRange replacementString:nil]) {
    
    [_textStorage beginEditing];

    if ([aSender tag] == LineEndingLF) {
        [mutableString convertLineEndingsToLF];
        [self setLineEnding:LineEndingLF];
        [self updateChangeCount:NSChangeDone];
    } else if ([aSender tag] == LineEndingCR) {
        [mutableString convertLineEndingsToCR];
        [self setLineEnding:LineEndingCR];
        [self updateChangeCount:NSChangeDone];
    } else if ([aSender tag] == LineEndingCRLF) {
        [mutableString convertLineEndingsToCRLF];
        [self setLineEnding:LineEndingCRLF];
        [self updateChangeCount:NSChangeDone];
    }
    
    [_textStorage endEditing];
}

- (void)selectedEncoding:(id)aSender {

    //[(NSMenuItem *)aSender setState:NSOnState];
    NSStringEncoding encoding = [aSender tag];
    
    if (LOGLEVEL(2)) NSLog(@"selectedEncoding: %@", [NSString localizedNameOfStringEncoding:encoding]);
    
    if ([self fileEncoding] != encoding) {

        NSBeginAlertSheet(
            NSLocalizedString(@"File Encoding", nil),
            NSLocalizedString(@"Convert", nil),             
            NSLocalizedString(@"Reinterpret", nil),
            NSLocalizedString(@"Cancel", nil),                  
            [NSApp mainWindow],                
            self,                  
            @selector(sheetDidEndShouldConvert:returnCode:contextInfo:),
            NULL,                   
            aSender,
            NSLocalizedString(@"ConvertOrReinterpret", nil),
            nil);
    }
}

- (BOOL)shareDocument {
    if (!_isShared) {
        _isShared=[[ConnectionManager sharedInstance] shareDocument:[self documentId]];
        if (!_isShared) {
            NSWindow *docWindow = [[[self windowControllers] objectAtIndex:0] window];
            NSBeginInformationalAlertSheet(NSLocalizedString(@"Could not share", nil), 
                               NSLocalizedString(@"OK", nil), 
                               nil, 
                               nil, 
                               docWindow, 
                               nil,
                               NULL, 
                               NULL, 
                               nil, 
                               NSLocalizedString(@"Could not share info", nil), 
                               nil);
        } else {
            [self setChangeHighlighting:[self changeHighlighting] || [[NSUserDefaults standardUserDefaults]
                                                                        boolForKey:HighlightChangesPreferenceKey]];
        }
        [self validateToolbars];
    }
    return _isShared;
}

- (void)unshareDocument {
    if (_isShared) {
        [[ConnectionManager sharedInstance] unshareDocument:[self documentId]];        
        _isShared=NO;
        
        NSEnumerator *userIds=[_participants objectEnumerator];
        NSString *userId;
        while ((userId=[userIds nextObject])) {
            if (![userId isEqualToString:[UserManager myId]]) {
                [[NSNotificationCenter defaultCenter] 
                    postNotificationName:TextDocumentUserDidLeaveNotification 
                                  object:self 
                                userInfo:[NSDictionary dictionaryWithObjectsAndKeys:userId,kUserUserIdProperty,nil]];
            }
        }
        [_participants removeAllObjects];
        [_participants addObject:[[[UserManager sharedInstance] me] objectForKey:kUserUserIdProperty]];
        [_participantData removeAllObjects];

        [_joinRequests removeAllObjects];

        [self validateToolbars];
        [self recolorTextStorageInRange:NSMakeRange(0,[_textStorage length])];
    }
}

- (void)recolorTextStorageInRange:(NSRange)aRange {
    // iterate over the range
    aRange=NSIntersectionRange(aRange,NSMakeRange(0,[_textStorage length]));
    if (aRange.length>0) {
        [_textStorage beginEditing];
        [_textStorage removeAttribute:kHighlightColorAttribute range:aRange];
        
        NSColor *backgroundColor=[NSColor documentBackgroundColor];
        NSString *userId;
    
        if (_changeHighlighting) {
            float changesSaturation=[[[NSUserDefaults standardUserDefaults]
                                        objectForKey:ChangesSaturationPreferenceKey] floatValue];
            NSRange attributeRange;
            unsigned int position;
            for (position=aRange.location;position<NSMaxRange(aRange);position=NSMaxRange(attributeRange)) {
                userId=[_textStorage attribute:kHighlightFromUserAttribute atIndex:position
                        longestEffectiveRange:&attributeRange inRange:aRange];
                if (userId) {
                    float userHue=[[[[UserManager sharedInstance] userForUserId:userId] 
                                        objectForKey:kUserColorHueProperty] floatValue];
                    NSColor *userColor=[backgroundColor userColorWithHue:userHue fraction:changesSaturation];
                    [_textStorage addAttribute:kHighlightColorAttribute 
                                        value:userColor
                                        range:attributeRange];
                }
            }
        }
        
        [_textStorage endEditing];        
    }
}

- (int)dentLineInTextView:(NSTextView *)aTextView withRange:(NSRange)aLineRange in:(BOOL)aIndent{
    int changedChars=0;
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    NSRange affectedCharRange=NSMakeRange(aLineRange.location,0);
    NSString *replacementString=@"";
    NSString *string=[_textStorage string];
    int tabWidth=[defaults integerForKey:TabWidthPreferenceKey];
    if ([defaults boolForKey:UsesTabsPreferenceKey]) {
         if (aIndent) {
            replacementString=@"\t";
            changedChars+=1;        
        } else {
            if ([string length]>aLineRange.location &&
            	[string characterAtIndex:aLineRange.location]==[@"\t" characterAtIndex:0]) {
                affectedCharRange.length=1;
                changedChars-=1;
            }
        }
    } else {
        unsigned firstCharacter=aLineRange.location;
        while (firstCharacter<NSMaxRange(aLineRange)) {
            unichar character;
            character=[string characterAtIndex:firstCharacter];
            if (character==[@" " characterAtIndex:0]) {
                firstCharacter++;
            } else if (character==[@"\t" characterAtIndex:0]) {
                changedChars+=tabWidth-1;
                firstCharacter++;
            } else {
                break;
            }   
        }
        if (changedChars!=0) {
            NSRange affectedRange=NSMakeRange(aLineRange.location,firstCharacter-aLineRange.location);
            NSString *replacementString=[@" " stringByPaddingToLength:firstCharacter-aLineRange.location+changedChars 
                                                       withString:@" " startingAtIndex:0];
            if ([[aTextView delegate] textView:aTextView 
                              shouldChangeTextInRange:affectedRange 
                                    replacementString:replacementString]) {
                NSAttributedString *attributedReplaceString=[[NSAttributedString alloc] 
                                                                initWithString:replacementString 
                                                                    attributes:[aTextView typingAttributes]];
                
                [_textStorage replaceCharactersInRange:affectedRange 
                                  withAttributedString:attributedReplaceString];                    
                [[aTextView delegate] 
                    textDidChange:[NSNotification notificationWithName:NSTextDidChangeNotification 
                                                                object:aTextView]];
                firstCharacter+=changedChars;  
                [attributedReplaceString release];
            }
        }

        if (aIndent) {
            changedChars+=tabWidth;
            replacementString=[@" " stringByPaddingToLength:tabWidth
                                                 withString:@" " startingAtIndex:0];
        } else {
            if (firstCharacter>=affectedCharRange.location+tabWidth) {
                affectedCharRange.length=tabWidth;
                changedChars-=tabWidth;
            } else {
                affectedCharRange.length=firstCharacter-affectedCharRange.location;
                changedChars-=affectedCharRange.length;
            }                 
        }
    }
    if (affectedCharRange.length>0 || [replacementString length]>0) {
        if ([[aTextView delegate] textView:aTextView 
                          shouldChangeTextInRange:affectedCharRange 
                                replacementString:replacementString]) {
            NSAttributedString *attributedReplaceString=[[NSAttributedString alloc] 
                                                            initWithString:replacementString 
                                                                attributes:[aTextView typingAttributes]];
            [_textStorage replaceCharactersInRange:affectedCharRange 
                              withAttributedString:attributedReplaceString];                    
            [[aTextView delegate] 
                textDidChange:[NSNotification notificationWithName:NSTextDidChangeNotification 
                                                            object:aTextView]];
            [attributedReplaceString release];
        }
    }
    return changedChars;
}

- (void)dentParagraphsInTextView:(NSTextView *)aTextView in:(BOOL)aIndent{
    if (_flags.hasBlockeditRanges) {
        NSBeep();
    } else {
    
        NSRange affectedRange=[aTextView selectedRange];
        NSString *string=[_textStorage string];
        NSRange lineRange;
        if ([_jupiterUndoManager groupingLevel]) {
            [_jupiterUndoManager endUndoGrouping];
        }
        
        [self beginUndoGroup];
        if (affectedRange.length==0) {
            [_textStorage beginEditing];
            lineRange=[string lineRangeForRange:affectedRange];
            int lengthChange=[self dentLineInTextView:aTextView withRange:lineRange in:aIndent];
            [_textStorage endEditing];
            if (lengthChange>0) {
                affectedRange.location+=lengthChange;
            } else if (lengthChange<0) {
                if (affectedRange.location-lineRange.location<ABS(lengthChange)) {
                    affectedRange.location=lineRange.location;
                } else {
                    affectedRange.location+=lengthChange;
                }
            }
            [aTextView setSelectedRange:affectedRange];
        } else {
            affectedRange=[string lineRangeForRange:affectedRange];
            [_textStorage beginEditing];
            lineRange.location=NSMaxRange(affectedRange)-1;
            lineRange.length=1;
            lineRange=[string lineRangeForRange:lineRange];        
            int result=0;
            int changedLength=0;
            while (!DisjointRanges(lineRange,affectedRange)) {
                result=[self dentLineInTextView:aTextView withRange:lineRange in:aIndent];
    
                changedLength+=result;
                // special case
                if (lineRange.location==0) break;
                
                lineRange=[string lineRangeForRange:NSMakeRange(lineRange.location-1,1)];  
            }
            affectedRange.length+=changedLength;
            [_textStorage endEditing];
            
            if (affectedRange.location<0 || NSMaxRange(affectedRange)>[_textStorage length]) {
                if (affectedRange.length>0) {
                    affectedRange=NSIntersectionRange(affectedRange,NSMakeRange(0,[_textStorage length]));
                } else {
                    if (affectedRange.location<0) {
                        affectedRange.location=0;
                    } else {
                        affectedRange.location=[_textStorage length];
                    }
                }
            }
            [aTextView setSelectedRange:affectedRange];
        } 
        [self endUndoGroup];
    }
}

- (int)blockChangeTextInRange:(NSRange)aRange replacementString:(NSString *)aReplacementString
           lineRange:(NSRange)aLineRange inTextView:(NSTextView *)aTextView {
    int lengthChange=0;
    int tabWidth=[[NSUserDefaults standardUserDefaults] integerForKey:TabWidthPreferenceKey];
    NSRange aReplacementRange=aRange;
    NSString *string=[_textStorage string];
    aReplacementRange.location+=aLineRange.location;
    // don't touch newlines
    {
        unsigned lineEnd,contentsEnd;
        [[_textStorage string] getLineStart:nil 
                                        end:&lineEnd 
                                contentsEnd:&contentsEnd 
                                   forRange:aLineRange];
        aLineRange.length-=lineEnd-contentsEnd;
    }
    unsigned detabbedLengthOfLine=[string detabbedLengthForRange:aLineRange tabWidth:tabWidth];
    if (detabbedLengthOfLine<=aRange.location) {
        // the line is to short, so just add whitespace
//        NSLog(@"line to short %u/%u",detabbedLengthOfLine,aRange.location);
        if ([aReplacementString length]>0) {
//            NSLog(@"no replacment length");
            // issue: add tabs when tab mode
            if (detabbedLengthOfLine!=aRange.location) {
                aReplacementString=[NSString stringWithFormat:@"%@%@",
                                    [@" " stringByPaddingToLength:aRange.location-detabbedLengthOfLine
                                                     withString:@" " startingAtIndex:0],
                                    aReplacementString];
            }
            aReplacementRange.location=NSMaxRange(aLineRange);
            aReplacementRange.length=0;
        } else {
            aReplacementRange.location=NSNotFound;
        }
    } else { // detabbedLengthOfLine>aRange.location
        // check if our location is character aligned
//        NSLog(@"line long enough %u/%u",detabbedLengthOfLine,aRange.location);
        unsigned length,index;
        if ([string detabbedLength:aRange.location fromIndex:aLineRange.location 
                            length:&length upToCharacterIndex:&index tabWidth:tabWidth]) {
            // we were character aligned
//            NSLog(@"location is aligned: %u - in line: %u",index,index-aLineRange.location);
            aReplacementRange.location=index;
            if (aReplacementRange.length>0) {
                if (NSMaxRange(aRange)>=detabbedLengthOfLine) {
                    //line is shorter than what we wanted to replace, so replace everything
                    aReplacementRange.length=NSMaxRange(aLineRange)-index;
                } else {
                    unsigned toIndex,toLength;
                    if ([string detabbedLength:NSMaxRange(aRange) fromIndex:aLineRange.location
                                        length:&toLength upToCharacterIndex:&toIndex tabWidth:tabWidth]) {
                        aReplacementRange.length=toIndex-index;
                    } else {
                    	aReplacementRange.length=toIndex-index+1;
                        int spacesTheTabTakes=tabWidth-(toLength)%tabWidth;
		                aReplacementString=[NSString stringWithFormat:@"%@%@",
		                                    aReplacementString,
		                                    [@" " stringByPaddingToLength:spacesTheTabTakes-(NSMaxRange(aRange)-toLength)
		                                                     withString:@" " startingAtIndex:0]];
                    }
                }
            }
        } else {
//            NSLog(@"location is not aligned: %u - in line: %u",index,index-aLineRange.location);
            // our location is not character aligned
            // so index points to a tab and length is shorter than wanted
            aReplacementRange.location=index;
            // apply padding spaces to the beginning and ending of your replacementString, 
            // according to the tab
            // aReplacementRange.length=0; // we don't replace the tab
            aReplacementString=[NSString stringWithFormat:@"%@%@",
                                [@" " stringByPaddingToLength:(aRange.location-length)
                                                 withString:@" " startingAtIndex:0],
                                aReplacementString];
            if (aReplacementRange.length!=0) {
                unsigned toIndex,toLength;
                if ([string detabbedLength:NSMaxRange(aRange) fromIndex:aLineRange.location
                                    length:&toLength upToCharacterIndex:&toIndex tabWidth:tabWidth]) {
                    aReplacementRange.length=toIndex-index;
                } else {           
                    	aReplacementRange.length=toIndex-index+1;
                        int spacesTheTabTakes=tabWidth-(toLength)%tabWidth;
		                aReplacementString=[NSString stringWithFormat:@"%@%@",
		                                    aReplacementString,
		                                    [@" " stringByPaddingToLength:spacesTheTabTakes-(NSMaxRange(aRange)-toLength)
		                                                     withString:@" " startingAtIndex:0]];
                }
            }
        }
    }


// change the stuff
    if (aReplacementRange.location!=NSNotFound) {
        if (NSMaxRange(aReplacementRange)>NSMaxRange(aLineRange)) {
            aReplacementRange.length=NSMaxRange(aLineRange)-aReplacementRange.location;
        }
        if ([[aTextView delegate] textView:aTextView 
              shouldChangeTextInRange:aReplacementRange 
                    replacementString:aReplacementString]) {
            lengthChange+=[aReplacementString length]-aReplacementRange.length;
            [_textStorage replaceCharactersInRange:aReplacementRange 
                                        withString:aReplacementString];
            [_textStorage setAttributes:[aTextView typingAttributes] 
                                  range:NSMakeRange(aReplacementRange.location,[aReplacementString length])];
            [[aTextView delegate] 
                textDidChange:[NSNotification notificationWithName:NSTextDidChangeNotification 
                                                            object:aTextView]];
        }
    }

    return lengthChange;
}

- (NSRange)blockChangeTextInRange:(NSRange)aRange replacementString:(NSString *)aReplacementString
        paragraphRange:(NSRange)aParagraphRange inTextView:(NSTextView *)aTextView {
 
//    NSLog(@"blockChangeTextInRange: %@",NSStringFromRange(aRange));
    
    NSString *string=[_textStorage string];
    NSRange lineRange;
        
    aParagraphRange=[string lineRangeForRange:aParagraphRange];
    int lengthChange=0;
    
    [_textStorage beginEditing];
    lineRange.location=NSMaxRange(aParagraphRange)-1;
    lineRange.length  =1;
    lineRange=[string lineRangeForRange:lineRange];        
    int result=0;
    while (!DisjointRanges(lineRange,aParagraphRange)) {
        result=[self blockChangeTextInRange:aRange replacementString:aReplacementString
                     lineRange:lineRange inTextView:aTextView];
        lengthChange+=result;
        // special case
        if (lineRange.location==0) break;
        
        lineRange=[string lineRangeForRange:NSMakeRange(lineRange.location-1,1)];  
    }
    [_textStorage endEditing];

    return NSMakeRange(aParagraphRange.location,aParagraphRange.length+lengthChange);
}

- (void)shiftRightInTextView:(NSTextView*)aTextView {
    [self dentParagraphsInTextView:aTextView in:YES];
}

- (void)shiftLeftInTextView:(NSTextView*)aTextView {
    [self dentParagraphsInTextView:aTextView in:NO];
}

- (void)jumpToSymbolInTextView:(NSTextView*)aTextView next:(BOOL)aNext {
    [self updateSymbolList];
    NSRange symbol=NSMakeRange(0,0);
    unsigned position=[aTextView selectedRange].location;
    if ([_symbols count]) {
        int i;
        for (i=0;i<(int)[_symbols count] && symbol.location<=position;i++) {
            symbol=[[[_symbols objectAtIndex:i] objectForKey:@"Range"] rangeValue];
        }
        if (!aNext && (i-2>=0)) {
            symbol=[[[_symbols objectAtIndex:i-2] objectForKey:@"Range"] rangeValue];
            if (symbol.location==[aTextView selectedRange].location && (i-3)>=0) {
                symbol=[[[_symbols objectAtIndex:i-3] objectForKey:@"Range"] rangeValue];               
            }             
        }
        [aTextView setSelectedRange:symbol];
        [aTextView centerSelectionInVisibleArea:self];
    } else {
        NSBeep();
    }
}

- (void)letJoinUserWithAtPosition:(int)aPosition {
    if (aPosition<(int)[_joinRequests count]) {
        NSString *userId=[[_joinRequests objectAtIndex:aPosition] retain];
        [[ConnectionManager sharedInstance] doHandshake:userId
                                    forDocument:[self documentId] 
                                        withData:[self contentAsDictionary]];
        [_joinRequests removeObjectAtIndex:aPosition];
        [self userDidJoin:userId];
        [userId release];    
        [self synchronizeWindowTitleWithDocumentName];
    }
}

- (void)denyRequestByUserAtPosition:(int)aPosition {
    [[ConnectionManager sharedInstance] denyConnection:[_joinRequests objectAtIndex:aPosition] 
                                            forDocument:[self documentId]];
    [_joinRequests removeObjectAtIndex:aPosition];
    [self reloadPeopleTableViewData];
    [self synchronizeWindowTitleWithDocumentName];
}

- (void)kickUserAtPosition:(int)aPosition {
    NSString *userId=[_participants objectAtIndex:aPosition];
    if (![userId isEqualToString:[[[UserManager sharedInstance] me] objectForKey:kUserUserIdProperty]]) {
        [[ConnectionManager sharedInstance] kickUser:userId forDocument:_documentId];
        [self userDidLeave:userId];
    }
}

#pragma mark -

- (void)sheetDidEndShouldConvert:(NSWindow *)sheet
                     returnCode:(int)returnCode
                    contextInfo:(void *)contextInfo
{
    NSStringEncoding encoding = [(NSMenuItem *)contextInfo tag];
    
    if (returnCode == NSAlertDefaultReturn) {
        if (LOGLEVEL(1)) NSLog(@"Trying to convert file encoding");
        [sheet close];
        if (![[_textStorage string] canBeConvertedToEncoding:encoding]) {
            
            NSBeginAlertSheet(
                NSLocalizedString(@"Error", nil),
                NSLocalizedString(@"Cancel", nil),             
                nil,
                nil,                  
                [NSApp mainWindow],                
                nil,                  
                nil,
                NULL,                   
                nil,
                NSLocalizedString(@"Encoding %@ not applicable", nil),
                [NSString localizedNameOfStringEncoding:encoding]);
        } else {
            [self setFileEncoding:encoding];
            [self updateChangeCount:NSChangeDone];
        }
    }
    
    if (returnCode == NSAlertAlternateReturn) {
        if (LOGLEVEL(1)) NSLog(@"Trying to reinterpret file encoding");
        [sheet close];
        
        NSData *stringData = [[_textStorage string] dataUsingEncoding:[self fileEncoding]];
        NSString *reinterpretedString = [[NSString alloc] initWithData:stringData encoding:encoding];
        
        if (reinterpretedString == nil) {
            NSBeginAlertSheet(
                NSLocalizedString(@"Error", nil),
                NSLocalizedString(@"Cancel", nil),             
                nil,
                nil,                  
                [NSApp mainWindow],                
                nil,                  
                nil,
                NULL,                   
                nil,
                NSLocalizedString(@"Encoding %@ not reinterpretable", nil),
                [NSString localizedNameOfStringEncoding:encoding]);
        } else {
            [_textStorage beginEditing];
            [_textStorage replaceCharactersInRange:NSMakeRange(0, [_textStorage length]) withString:reinterpretedString];
            [_textStorage setAttributes:[self plainTextAttributes] range:NSMakeRange(0, [_textStorage length])];
            
            if (_colorizeSyntax) {
                [self syntaxColorizeInRange:NSMakeRange(0,[_textStorage length])];
            }
            [_textStorage endEditing];
            
            [reinterpretedString release];
            [self setFileEncoding:encoding];
            [self updateChangeCount:NSChangeDone];
        }
    }
}

- (void)sheetDidEndShouldPromote:(NSWindow *)aSheet
                      returnCode:(int)aReturnCode
                     contextInfo:(NSDictionary *)aContextInfo {

    if (aReturnCode == NSAlertAlternateReturn) {
        [self setFileEncoding:NSUnicodeStringEncoding];
        NSTextView *textView = [aContextInfo objectForKey:@"textView"];
        [textView insertText:[aContextInfo objectForKey:@"replacementString"]];
    } else if (aReturnCode == NSAlertOtherReturn) {
        [self setFileEncoding:NSUTF8StringEncoding];
        NSTextView *textView = [aContextInfo objectForKey:@"textView"];
        [textView insertText:[aContextInfo objectForKey:@"replacementString"]];
    }

    [aContextInfo autorelease];
}

- (void)printOperationDidRun:(NSPrintOperation *)printOperation
                     success:(BOOL)success
                 contextInfo:(void *)contextInfo {
    if (_printView) {
        [_printView release];
        _printView=nil;
    }
}

#pragma mark -
#pragma mark ### Notification/Delegate Handling ###

- (void)undoManagerWillUndoRedo:(NSNotification *)aNotification {

    TextDocumentWindowController *windowController=[[NSApp mainWindow] windowController];
    // sanity check
    if ([windowController document] != self ) {
        windowController=[[self windowControllers] objectAtIndex:0];
    }
    _undoingTextView=[windowController textView];
    [_textStorage beginEditing];
}

- (void)undoManagerDidUndoRedo:(NSNotification *)aNotification {
    [_textStorage endEditing];
    NSRange selection=NSMakeRange([self lastTextOperationRange].location+
                                                   [[self lastTextOperationString] length],0);
    [_undoingTextView setSelectedRange:selection];
    [_undoingTextView scrollRangeToVisible:selection];
    _undoingTextView=nil;
}

- (void)textDocumentDidChange:(NSNotification *)aNotification {
    [self updateMaxYForRadarScroller];
}

- (void)joinRequestedByUser:(NSString*)aUserId {
    if (_autoAccept) {
        [[ConnectionManager sharedInstance] doHandshake:aUserId
                                    forDocument:[self documentId] 
                                       withData:[self contentAsDictionary]];
        [self userDidJoin:aUserId];
        [self synchronizeWindowTitleWithDocumentName];
    } else {
        [_joinRequests addObject:aUserId];
        [self reloadPeopleTableViewData];
        [[SoundManager sharedInstance] playNewUserSound];
        [self synchronizeWindowTitleWithDocumentName];
    }
}

- (void)requestCancelledByUser:(NSString *)aUserId {
    [_joinRequests removeObject:aUserId];
    [self reloadPeopleTableViewData];
    [self synchronizeWindowTitleWithDocumentName];
}

- (void)userDidJoin:(NSString*)aUserId {
    if (![_participants containsObject:aUserId] && aUserId) {
        [_participants addObject:aUserId];
        if (![_participantData objectForKey:aUserId]) {
            [self setSelectionRange:NSMakeRange(0,0) forUser:aUserId];
        }
        [[NSNotificationCenter defaultCenter] 
            postNotificationName:TextDocumentSelectionOfUserHasChangedNotification 
                          object:self 
                        userInfo:[NSDictionary dictionaryWithObjectsAndKeys:aUserId,kUserUserIdProperty,nil]];

        [self reloadPeopleTableViewData];
        NSEnumerator *userIds=[_participants objectEnumerator];
        NSString *userId;
        while ((userId=[userIds nextObject])) {
            if (![userId isEqualToString:aUserId] &&
                ![userId isEqualToString:[UserManager myId]]) {
                [[ConnectionManager sharedInstance] 
                    addUser:[[UserManager sharedInstance] userForUserId:aUserId] 
                    forDocument:_documentId toUser:userId];
            }
        }
    }
    [_jupiterObject userDidJoin:aUserId];
}

- (void)userDidChange:(NSDictionary*)aUser {
    [self recolorTextStorageInRange:NSMakeRange(0,[_textStorage length])];
    if (![self isRemote]) {
        NSEnumerator *participants=[_participants objectEnumerator];
        NSString *userId;
        while ((userId=[participants nextObject])) {
            if (![userId isEqualToString:[UserManager myId]] &&
                ![userId isEqualToString:[aUser objectForKey:kUserUserIdProperty]]) {
                [[ConnectionManager sharedInstance] propagateChangeOfUser:aUser 
                                                              forDocument:[self documentId] 
                                                                   toUser:userId];
            }
        }
    }
    [self reloadPeopleTableViewData];
}

- (void)userDidLeave:(NSString*)aUserId {
    BOOL reloadData=NO;
    if ([_participants containsObject:aUserId]) { 
        [_participants removeObject:aUserId];
        if ([_participantData objectForKey:aUserId]) {
            [_participantData removeObjectForKey:aUserId];
            [self recolorTextStorageInRange:NSMakeRange(0,[_textStorage length])];
        }
        reloadData=YES;
        if (!_isRemote) {
            NSEnumerator *userIds=[_participants objectEnumerator];
            NSString *userId;
            while ((userId=[userIds nextObject])) {
                if (![userId isEqualToString:aUserId] &&
                    ![userId isEqualToString:[[[UserManager sharedInstance] me] objectForKey:kUserUserIdProperty]]) {
                    [[ConnectionManager sharedInstance] removeUser:aUserId forDocument:_documentId toUser:userId];
                }
            }
        }
        if (aUserId) {
            [[NSNotificationCenter defaultCenter] 
                postNotificationName:TextDocumentUserDidLeaveNotification 
                              object:self 
                            userInfo:[NSDictionary dictionaryWithObjectsAndKeys:aUserId,kUserUserIdProperty,nil]];
        } else {
            NSLog(@"TextDocument userDidLeave was called with a nil userId");        
        }                    
    } else if ([_joinRequests containsObject:aUserId]) {
        [_joinRequests removeObject:aUserId];
        reloadData=YES;
    }
    [_jupiterObject userDidLeave:aUserId];
    if (reloadData) [self reloadPeopleTableViewData];
}

- (void)didReceiveDictionary:(NSDictionary *)aDictionary {
    NSString *sharedTitle=[aDictionary objectForKey:kDocumentTitleProperty];
    if (sharedTitle) {
        [self setSharedTitle:sharedTitle];
        [self synchronizeWindowTitleWithDocumentName];
    }
}

- (void)wasKickedFromDocument {
    [self didUnshareDocument];
}

- (void)didUnshareDocument {
    [_jupiterObject invalidate];
    [_jupiterObject release];
    _jupiterObject=nil;
    [self retain];
    [[DocumentController sharedDocumentController] removeDocument:self];
    CFUUIDRef myUUID = CFUUIDCreate(NULL);
    CFStringRef myUUIDString = CFUUIDCreateString(NULL, myUUID);
    [self setDocumentId:(NSString *)myUUIDString];
    CFRelease(myUUIDString);
    CFRelease(myUUID);
    [self setIsRemote:NO];
    [self setUserIdOfHost:[[[UserManager sharedInstance] me] objectForKey:kUserUserIdProperty]];
    NSEnumerator *userIds=[_participants objectEnumerator];
    NSString *userId;
    while ((userId=[userIds nextObject])) {
        if (![userId isEqualToString:[UserManager myId]]) {
            [[NSNotificationCenter defaultCenter] 
                postNotificationName:TextDocumentUserDidLeaveNotification 
                              object:self 
                            userInfo:[NSDictionary dictionaryWithObjectsAndKeys:userId,kUserUserIdProperty,nil]];
        }
    }
    [_participants removeAllObjects];
    [_participants addObject:[[[UserManager sharedInstance] me] objectForKey:kUserUserIdProperty]];
    [_participantData removeAllObjects];
    [[DocumentController sharedDocumentController] addDocument:self];
    [self reloadPeopleTableViewData];
    _jupiterObject=[[JupiterServer alloc] initWithDocument:self undoManager:_jupiterUndoManager];
    [self setFileName:_sharedTitle];
    [self release];
    [self recolorTextStorageInRange:NSMakeRange(0,[_textStorage length])];
    [self closeDrawers];
    [self validateToolbars];
}

- (void)preferencesDidChange:(NSNotification *)aNotification {
    NSDictionary *userInfo=[aNotification userInfo];
    
    if ([userInfo objectForKey:PreferedColorHuePreferenceKey]) {
        if ([self isRemote]) {
            [[ConnectionManager sharedInstance] propagateChangeOfUser:[UserManager me] 
                                                          forDocument:[self documentId] 
                                                               toUser:[self userIdOfHost]];
        } else {
            NSEnumerator *participants=[_participants objectEnumerator];
            NSString *userId;
            while ((userId=[participants nextObject])) {
                if (![userId isEqualToString:[UserManager myId]]) {
                    [[ConnectionManager sharedInstance] propagateChangeOfUser:[UserManager me] 
                                                                  forDocument:[self documentId] 
                                                                       toUser:userId];
                }
            }
        }
        [self reloadPeopleTableViewData];
    }
    
    if ([userInfo objectForKey:SelectionSaturationPreferenceKey] ||
        [userInfo objectForKey:ChangesSaturationPreferenceKey] ||
        [userInfo objectForKey:PreferedColorHuePreferenceKey] ||
        [userInfo objectForKey:BackgroundColorPreferenceKey]) {
            [self recolorTextStorageInRange:NSMakeRange(0, [_textStorage length])];
            [self reloadPeopleTableViewData];
    }

    if ([userInfo objectForKey:ForegroundColorPreferenceKey]) {
        [_textAttributes release];
        _textAttributes=nil;
        [_textStorage beginEditing];
        [_textStorage addAttributes:[self plainTextAttributes]
                              range:NSMakeRange(0, [_textStorage length])];
        [_textStorage endEditing];
        [self syntaxColorizeInRange:NSMakeRange(0, [_textStorage length])];
        [self reloadPeopleTableViewData];
    }
    
    if ([userInfo objectForKey:FontPreferenceKey]||
    	[userInfo objectForKey:TabWidthPreferenceKey]||
    	[userInfo objectForKey:UsesScreenFontsPreferenceKey]) {
        [_textAttributes release];
        _textAttributes=nil;
        [_textStorage beginEditing];
        [_textStorage addAttributes:[self plainTextAttributes]
                              range:NSMakeRange(0, [_textStorage length])];
        [_textStorage endEditing];
        [self syntaxColorizeInRange:NSMakeRange(0, [_textStorage length])];
        [[NSNotificationQueue defaultQueue] 
            enqueueNotification:[NSNotification notificationWithName:TextDocumentTextDidChangeNotification object:self]
                   postingStyle:NSPostWhenIdle 
                   coalesceMask:NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender 
                       forModes:[NSArray arrayWithObject:NSDefaultRunLoopMode]];
    }
}

- (NSMenu *)symbolPopUpMenuForView:(NSTextView *)aTextView sorted:(BOOL)aSorted {
    NSMenu *menu=aSorted?_sortedSymbolPopUpMenu:_symbolPopUpMenu;
    NSEnumerator *menuItems=[[menu itemArray] objectEnumerator];    
    NSMenuItem *item;

    while ((item=[menuItems nextObject])) {
        if (![item isSeparatorItem]) {
            [item setRepresentedObject:aTextView];
        }
    } 
    return menu; 
}

- (int)selectedSymbolForRange:(NSRange)aRange {
    [self updateSymbolList];
    int select=0;
    int lastPossibleSelect=0;
    NSEnumerator *items=[[_symbolPopUpMenu itemArray] objectEnumerator];
    NSMenuItem   *item;
    while ((item=[items nextObject])) { 
        if (![item isSeparatorItem]) { 
            NSRange symbolRange=[[[_symbols objectAtIndex:[item tag]] objectForKey:@"Range"] rangeValue];
            if (symbolRange.location>aRange.location) {
                break;
            }
            lastPossibleSelect=select;
        }
        select++;
    }
    if ((int)[[_symbolPopUpMenu itemArray] count]==select) select--;
    return lastPossibleSelect;
}

- (void)textPopUpWillShowMenu:(NSPopUpButtonCell *)aCell {
    TextDocumentWindowController *windowController=[[[aCell controlView] window] windowController];
    [windowController updateSelectedSymbol];
}

#pragma mark -
#pragma mark ### Loading/Saving Content setting ###

- (IBAction)saveDocument:(id)aSender
{
    _saveCopyFromRunningSavePanel = NO;
    [super saveDocument:aSender];
}

- (IBAction)saveDocumentAs:(id)aSender
{
    _saveCopyFromRunningSavePanel = NO;
    [super saveDocumentAs:aSender];
}

- (IBAction)saveDocumentTo:(id)aSender {
    _saveCopyFromRunningSavePanel = YES;
    [super saveDocumentTo:aSender];
}

- (BOOL)prepareSavePanel:(NSSavePanel *)savePanel
{
    if (_saveCopyFromRunningSavePanel) {
        NSPopUpButton *encodingPopUp;

        NSArray *encodings = [[EncodingManager sharedInstance] enabledEncodings];
        NSMutableArray *lossyEncodings = [NSMutableArray array];
        unsigned int i;
        for (i = 0; i < [encodings count]; i++) {
            if (![[_textStorage string] canBeConvertedToEncoding:[[encodings objectAtIndex:i] unsignedIntValue]]) {
                [lossyEncodings addObject:[encodings objectAtIndex:i]];
            }
        }
        [[EncodingManager sharedInstance] registerEncoding:[self fileEncoding]];
        [savePanel setAccessoryView:[[EncodingManager sharedInstance] encodingAccessory:[self fileEncoding] includeDefaultEntry:NO enableIgnoreRichTextButton:NO encodingPopUp:&encodingPopUp ignoreRichTextButton:nil lossyEncodings:lossyEncodings]];
        [self setEncodingAccessoryPopUpButton:encodingPopUp];
    } else {
        [savePanel setAccessoryView:nil];
    }

    return [super prepareSavePanel:savePanel];
}

- (BOOL)readFromFile:(NSString *)fileName ofType:(NSString *)docType
{
    if (LOGLEVEL(1))NSLog(@"readFromFile: %@", fileName);
    return [self readFromURL:[NSURL fileURLWithPath:fileName] ofType:docType];
}

- (BOOL)readFromURL:(NSURL *)aURL ofType:(NSString *)docType {

    if (LOGLEVEL(1)) NSLog(@"readFromURL: %@", [aURL description]);
    
    BOOL isDir, fileExists;
    fileExists = [[NSFileManager defaultManager] fileExistsAtPath:[aURL path] isDirectory:&isDir];
    if (!fileExists || isDir) {
        return NO;
    }
    
    int oldLength = [_textStorage length];
        
    if (oldLength==0) {
        // determine Syntaxname
        NSString *extension=[[aURL path] pathExtension];
        NSString *syntaxDefinitionFile=[[SyntaxManager sharedInstance] syntaxDefinitionForExtension:extension];
        if (syntaxDefinitionFile) {
            NSDictionary *syntaxNames=[[SyntaxManager sharedInstance] availableSyntaxNames];
            NSArray *keys=[syntaxNames allKeysForObject:syntaxDefinitionFile];
            if ([keys count]>0) {
                [self setSyntaxName:[keys objectAtIndex:0]];
            }
        } else {
            [self setSyntaxName:@""];
        }
    }
    
    [self setIsNew:NO];
    if ([aURL isFileURL]) {
        NSDictionary *fattrs = [[NSFileManager defaultManager] fileAttributesAtPath:[aURL path] traverseLink:YES];
        [self setFileAttributes:fattrs];
    }
    
    NSDictionary *docAttrs = nil;
    NSMutableDictionary *options = [NSMutableDictionary dictionary];
    
    NSStringEncoding encoding;
    NSNumber *encodingFromRunningOpenPanel = [[DocumentController sharedDocumentController] encodingFromRunningOpenPanel];
    if (encodingFromRunningOpenPanel != nil) {
        encoding = [encodingFromRunningOpenPanel unsignedIntValue];
    } else {
        encoding = [[[NSUserDefaults standardUserDefaults] objectForKey:DefaultEncodingPreferenceKey] unsignedIntValue];
    }
    [[DocumentController sharedDocumentController] setEncodingFromRunningOpenPanel:nil];

    if (encoding < SmallestCustomStringEncoding) {
        if (LOGLEVEL(1)) {
            NSLog(@"Setting \"CharacterEncoding\" option");
            NSLog(@"trying encoding: %@", [NSString localizedNameOfStringEncoding:encoding]);
        }
        [options setObject:[NSNumber numberWithUnsignedInt:encoding] forKey:@"CharacterEncoding"];
    }
    
    //[options setObject:NSPlainTextDocumentType forKey:@"DocumentType"];
    [options setObject:[self plainTextAttributes] forKey:@"DefaultAttributes"];
    
    [[_textStorage mutableString] setString:@""];	// Empty the document
    
    while (TRUE) {
        BOOL success;
        
        [_textStorage beginEditing];
        success = [_textStorage readFromURL:aURL options:options documentAttributes:&docAttrs];
        [_textStorage endEditing];
        if (LOGLEVEL(1)) {
            NSLog(@"read succeeded: %@", success ? @"YES" : @"NO");
            NSLog(@"documentAttributes: %@", [docAttrs description]);
        }
        if (!success) {
            NSNumber *encodingNumber = [options objectForKey:@"CharacterEncoding"];
            if (encodingNumber != nil) {
                NSStringEncoding systemEncoding = CFStringConvertEncodingToNSStringEncoding(CFStringGetSystemEncoding());
                NSStringEncoding triedEncoding = [encodingNumber unsignedIntValue];
                if (triedEncoding == NSUTF8StringEncoding && triedEncoding != systemEncoding) {
                    [[_textStorage mutableString] setString:@""];	// Empty the document, and reload
                    [options setObject:[NSNumber numberWithUnsignedInt:systemEncoding] forKey:@"CharacterEncoding"];
                    continue;
                }
            }
            
            return NO;
        }
        
        if (![[docAttrs objectForKey:@"DocumentType"] isEqualToString:NSPlainTextDocumentType] &&
            ![[options objectForKey:@"DocumentType"] isEqualToString:NSPlainTextDocumentType]) {
            [[_textStorage mutableString] setString:@""];	// Empty the document, and reload
            [options setObject:NSPlainTextDocumentType forKey:@"DocumentType"];
        } else {
            break;
        }
    }
    
    [_textStorage beginEditing];
    [_textStorage addAttributes:[self plainTextAttributes]
                          range:NSMakeRange(0, [_textStorage length])];
    [_textStorage endEditing];
    
    [self setFileEncoding:[[docAttrs objectForKey:@"CharacterEncoding"] intValue]];
    if (LOGLEVEL(1)) NSLog(@"fileEncoding: %@", [NSString localizedNameOfStringEncoding:[self fileEncoding]]);

    // guess lineEnding and set instance variable
    unsigned startIndex = 0;
    unsigned lineEndIndex = 0;
    unsigned contentsEndIndex = 0;
    [[_textStorage string] getLineStart:&startIndex end:&lineEndIndex contentsEnd:&contentsEndIndex forRange:NSMakeRange(0, 0)];
    
    unsigned length = lineEndIndex - contentsEndIndex;
    if (LOGLEVEL(2)) NSLog(@"lineEnding, lineEndIndex: %u, contentsEndIndex: %u, length: %u", lineEndIndex, contentsEndIndex, length);
    if (length == 1) {
        unichar character = [[_textStorage string] characterAtIndex:contentsEndIndex];
        if (character == [@"\n" characterAtIndex:0]) {
            [self setLineEnding:LineEndingLF];
        } else if (character == [@"\r" characterAtIndex:0]) {
            [self setLineEnding:LineEndingCR];
        }
    } else if (length == 2) {
        unichar character1 = [[_textStorage string] characterAtIndex:contentsEndIndex];
        unichar character2 = [[_textStorage string] characterAtIndex:contentsEndIndex + 1];
        if ((character1 == [@"\r" characterAtIndex:0]) && (character2 == [@"\n" characterAtIndex:0])) {
            [self setLineEnding:LineEndingCRLF];
        }
    }
    
    if (LOGLEVEL(1)) NSLog(@"lineEnding: %u", [self lineEnding]);
    

    if (_colorizeSyntax) {
        [self syntaxColorizeInRange:NSMakeRange(0,[_textStorage length])];
    }

    if (oldLength > 0) {
        // inform other about revert
        [_jupiterUndoManager removeAllActions];
        [_jupiterObject changeTextInRange:NSMakeRange(0, oldLength)
                        replacementString:[_textStorage string]]; 
    }
    //[self updateMaxYForRadarScroller];
    return YES;
}

- (NSData *)dataRepresentationOfType:(NSString *)aType {

    if (_saveCopyFromRunningSavePanel) {
        NSStringEncoding encoding = [[[self encodingAccessoryPopUpButton] selectedItem] tag];
        if (LOGLEVEL(1)) NSLog(@"Save a copy using encoding: %@", [NSString localizedNameOfStringEncoding:encoding]);
        [[EncodingManager sharedInstance] unregisterEncoding:encoding];
        return [[_textStorage string] dataUsingEncoding:encoding allowLossyConversion:YES];
    } else {
        if (LOGLEVEL(1)) NSLog(@"Save using encoding: %@", [NSString localizedNameOfStringEncoding:[self fileEncoding]]);
        return [[_textStorage string] dataUsingEncoding:[self fileEncoding] allowLossyConversion:YES];
    }
}

- (void)setContentByDictionary:(NSDictionary*)aDictionary {
    _outsideAction++;
    [_participants removeAllObjects];

    [_textStorage beginEditing];
    NSAttributedString *attributedString=[aDictionary objectForKey:@"TextAsString"];
    [_textStorage replaceCharactersInRange:NSMakeRange(0, [_textStorage length])
                      withAttributedString:attributedString];
      
    
    [_textStorage addAttributes:[self plainTextAttributes]
                         range:NSMakeRange(0,[_textStorage length])];
    [_textStorage endEditing]; 

    [_participantData addEntriesFromDictionary:[aDictionary objectForKey:@"ParticipantData"]];
    NSEnumerator *participants=[[aDictionary objectForKey:@"Participants"] objectEnumerator];
    NSDictionary *user;
    UserManager *userManager=[UserManager sharedInstance];
    while ((user=[participants nextObject])) {
        [userManager setUser:user forUserId:[user objectForKey:kUserUserIdProperty]];
        [self userDidJoin:[user objectForKey:kUserUserIdProperty]];
    }
    [_participants addObject:[UserManager myId]];
    
    participants=[[aDictionary objectForKey:@"ExParticipants"] objectEnumerator];
    while ((user=[participants nextObject])) {
        [userManager setUser:user forUserId:[user objectForKey:kUserUserIdProperty]];
    }
    
    [self setSharedTitle:[aDictionary objectForKey:@"Title"]];
    [self setFileEncoding:[[aDictionary objectForKey:@"FileEncoding"] unsignedIntValue]];
    [self setLineEnding:[[aDictionary objectForKey:@"LineEnding"] intValue]];
    [self setSyntaxName:[aDictionary objectForKey:@"SyntaxName"]];

    
    [self recolorTextStorageInRange:NSMakeRange(0, [_textStorage length])];
    [self syntaxColorizeInRange:    NSMakeRange(0, [_textStorage length])];
   
    [[[[self windowControllers] objectAtIndex:0] peopleDrawer] open];
    [[[[self windowControllers] objectAtIndex:0] textView] setSelectedRange:NSMakeRange(0,0)];
     [[[self windowControllers] objectAtIndex:0] validateDrawerButtons];

    [_jupiterObject invalidate];
    [_jupiterObject release];
    _jupiterObject=nil;
    _jupiterObject=[[JupiterClient alloc] initWithDocument:self undoManager:_jupiterUndoManager];
    
    [self setChangeHighlighting:[self changeHighlighting] || 
                                [[NSUserDefaults standardUserDefaults]
                                    boolForKey:HighlightChangesPreferenceKey]];
    [[NSNotificationQueue defaultQueue] 
        enqueueNotification:[NSNotification notificationWithName:TextDocumentTextDidChangeNotification object:self]
               postingStyle:NSPostWhenIdle 
               coalesceMask:NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender 
                   forModes:[NSArray arrayWithObject:NSDefaultRunLoopMode]];
    
//    [self updateMaxYForRadarScroller];
    
    [self synchronizeWindowTitleWithDocumentName];
    _outsideAction--;
}

- (void)_webPreviewOnSaveRefresh {
    if (_webPreviewWindowController) {
        if ([[_webPreviewWindowController window] isVisible] &&
            [_webPreviewWindowController refreshType] == kWebPreviewRefreshOnSave) {
            [_webPreviewWindowController refreshAndEmptyCache:self];
        }
    }
}

- (BOOL)writeToFile:(NSString *)fileName ofType:(NSString *)docType {
    if (LOGLEVEL(1)) NSLog(@"writeToFile:%@ ofType:%@", fileName, docType);
    if (LOGLEVEL(2)) NSLog(@"pre fileName: %@", [self fileName]);
    BOOL result = [super writeToFile:fileName ofType:docType];
    if (result) {
        [self sendODBModifiedEvent];
        [self _webPreviewOnSaveRefresh];
    }
    if (LOGLEVEL(2)) NSLog(@"post fileName: %@", [self fileName]);
    return result;
}

- (BOOL)writeToURL:(NSURL *)aURL ofType:(NSString *)docType {
    if (LOGLEVEL(1)) NSLog(@"writeToURL:ofType:");
    BOOL result = [super writeToURL:aURL ofType:docType];
    if (result) {
        [self sendODBModifiedEvent];
        [self _webPreviewOnSaveRefresh];
    }
    return result;
}

- (void)saveToFile:(NSString *)fileName saveOperation:(NSSaveOperationType)saveOperation delegate:(id)delegate didSaveSelector:(SEL)didSaveSelector contextInfo:(void *)contextInfo {

    if (![self fileName]) {
        NSString *extension=[fileName pathExtension];
        NSString *syntaxDefinitionFile=
                [[SyntaxManager sharedInstance] syntaxDefinitionForExtension:extension];
        if (syntaxDefinitionFile) {
            NSDictionary *syntaxNames=[[SyntaxManager sharedInstance] availableSyntaxNames];
            NSArray *keys=[syntaxNames allKeysForObject:syntaxDefinitionFile];
            if ([keys count]>0) {
                [self setSyntaxName:[keys objectAtIndex:0]];
                [self syntaxColorizeInRange:NSMakeRange(0,[_textStorage length])];
            }
        } 
    }
    if (LOGLEVEL(1)) NSLog(@"saveToFile: %@", fileName);
    [self setNewFileName:fileName];
    [super saveToFile:fileName saveOperation:saveOperation delegate:delegate didSaveSelector:didSaveSelector contextInfo:contextInfo];
}

- (NSDictionary*)contentAsDictionary {
    HydraTextStorage *textStorage=[[_textStorage mutableCopy] autorelease];
    [textStorage removeAttribute:NSForegroundColorAttributeName range:NSMakeRange(0,[textStorage length])];
    [textStorage removeAttribute:NSBackgroundColorAttributeName range:NSMakeRange(0,[textStorage length])];
    [textStorage removeAttribute:kBlockeditAttributeName        range:NSMakeRange(0,[textStorage length])];
    NSMutableDictionary *data=[NSMutableDictionary dictionary];
    [data setObject:textStorage forKey:@"TextAsString"];
    NSMutableDictionary *participantData=[[_participantData mutableCopy] autorelease];
    NSRange selectionRange=[[[[self windowControllers] objectAtIndex:0] textView] selectedRange];
    [participantData setObject:[NSDictionary dictionaryWithObject:[NSArray arrayWithObjects:
                               [NSNumber numberWithInt:selectionRange.location],
                               [NSNumber numberWithInt:selectionRange.length],nil]
                                                            forKey:kSelectionProperty]
                         forKey:[UserManager myId]];

    [data setObject:participantData forKey:@"ParticipantData"];
    [data setObject:[NSNumber numberWithFloat:0.1] forKey:@"Version"];
    [data setObject:[NSNumber numberWithUnsignedInt:[self fileEncoding]] forKey:@"FileEncoding"];
    [data setObject:[NSNumber numberWithInt:[self lineEnding]] forKey:@"LineEnding"];
    if (_syntaxName) {
        [data setObject:[[_syntaxName copy] autorelease] forKey:@"SyntaxName"];
    }
    NSMutableArray *participants=[NSMutableArray array];
    NSEnumerator   *participantIds=[_participants objectEnumerator];
    NSString       *userId;
    UserManager    *userManager=[UserManager sharedInstance];
    while (userId=[participantIds nextObject]) {
        [participants addObject:[userManager userForUserId:userId]];
    }
    [data setObject:participants forKey:@"Participants"];
    [data setObject:[self displayName] forKey:@"Title"];

    // now go through the textdocument and see if anyone has made 
    // changes that is not participating anymore
    NSRange insertionRange;
    NSRange wholeText=NSMakeRange(0,[_textStorage length]);
    NSMutableSet *exParticipants=[NSMutableSet set];
    unsigned int position;
    for (position=0;position<wholeText.length;position=NSMaxRange(insertionRange)) {
        userId=[_textStorage attribute:kHighlightFromUserAttribute atIndex:position
                 longestEffectiveRange:&insertionRange inRange:wholeText];
        if (userId) {
            if (![_participants containsObject:userId]) {
                [exParticipants addObject:[userManager userForUserId:userId]];
            }
        }
    }
    [data setObject:exParticipants forKey:@"ExParticipants"];

    return data;
}

// first REsponder debug
- (IBAction)recolorize:(id)aSender {
    [self syntaxColorizeInRange:NSMakeRange(0,[_textStorage length])];
}

- (void)printShowingPrintPanel:(BOOL)aBoolean {
    NSPrintInfo *printInfo=[self printInfo];
    NSPrintOperation *operation;
    if (_printView) {
        [_printView release];
        _printView=nil;
    }
    _printView=[[HydraPrintView alloc] initWithTextStorage:_textStorage
                                                 printInfo:printInfo];

    operation=[NSPrintOperation printOperationWithView:_printView
                                             printInfo:printInfo];
    [operation setShowPanels:aBoolean];
    [self runModalPrintOperation:operation delegate:self 
                  didRunSelector:@selector(printOperationDidRun:success:contextInfo:) contextInfo:nil];
}

- (IBAction)didChooseGotoSymbolMenuItem:(NSMenuItem *)aMenuItem {
    if (LOGLEVEL(2)) NSLog(@"TextDocument Popupmenu Menu item chosen %@",[aMenuItem description]);
    NSTextView *textView=[aMenuItem representedObject];
    NSRange symbolRange=[[[_symbols objectAtIndex:[aMenuItem tag]] objectForKey:@"Range"] rangeValue];
    [textView setSelectedRange:symbolRange];
    [textView scrollRangeToVisible:symbolRange];   
}

#pragma mark -
#pragma mark ### textView/Jupiter interaction ###

- (void)startBlockedit {
    _flags.hasBlockeditRanges=YES;
    [self updatePositionTextField];
    [_jupiterObject continueProcessing];
}

- (void)stopBlockedit {
    [_textStorage removeAttribute:NSBackgroundColorAttributeName
                    range:NSMakeRange(0,[_textStorage length])];
    [_textStorage removeAttribute:kBlockeditAttributeName
                    range:NSMakeRange(0,[_textStorage length])];
    [self updatePositionTextField];
    _flags.hasBlockeditRanges=NO;
}

- (TextDocumentWindowController *)topmostWindowController {
    // todo: return window controller with the topmost window
    if (LOGLEVEL(3)) NSLog(@"topmostWindowController: %@", [[self windowControllers] objectAtIndex:0]);
    NSEnumerator *orderedWindowEnumerator=[[NSApp orderedWindows] objectEnumerator];
    NSWindow *window;
    TextDocumentWindowController *result=nil;
    while ((window=[orderedWindowEnumerator nextObject])) {
        if ([[window windowController] document]==self) {
//            NSLog(@"window %@", [window title]);
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
    TextDocumentWindowController *windowController=[self topmostWindowController];
    [windowController gotoLine:aLine];
    if (aFlag) [[windowController window] makeKeyAndOrderFront:self];
}

- (void)selectRange:(NSRange)aRange scrollToVisible:(BOOL)aScroll {
    TextDocumentWindowController *windowController=[self topmostWindowController];
    [windowController selectRange:aRange scrollToVisible:aScroll];
    [[windowController window] makeKeyAndOrderFront:self];
}

- (IBAction) undo:(id)aSender {
    [_jupiterUndoManager undo];
}

- (IBAction) redo:(id)aSender {
    [_jupiterUndoManager redo];
}

- (JupiterUndoManager *)jupiterUndoManager {
    return _jupiterUndoManager;
}

- (void)beginUndoGroup {
    [_jupiterUndoManager beginUndoGrouping];
    _undoGroupStart=YES;
}

- (void)endUndoGroup {
    [_jupiterUndoManager endUndoGrouping];
    _undoGroupStart=NO;
}

- (void)performSyntaxColorize:(id)aSender {
    if (!_performingSyntaxColorize && _colorizeSyntax && _syntaxHighlighter) {
        [self performSelector:@selector(syntaxColorize) withObject:nil afterDelay:0.3];                
        _performingSyntaxColorize=YES;
    }
}

- (void)syntaxColorize {
    _performingSyntaxColorize=NO;
    if (_colorizeSyntax) {
        if (_syntaxHighlighter && ![_syntaxHighlighter colorizeDirtyRanges:_textStorage]) {
            [self performSyntaxColorize:self];
        }
    }
}

- (void)syntaxColorizeInRange:(NSRange)aRange {
    if (_colorizeSyntax) {
        NSRange range=NSIntersectionRange(aRange,NSMakeRange(0,[_textStorage length]));
        if (range.length>0) {
            [_textStorage addAttribute:kSyntaxColoringIsDirtyAttribute 
                                 value:kSyntaxColoringIsDirtyAttributeValue 
                                 range:range];
            [[NSNotificationQueue defaultQueue] 
                enqueueNotification:[NSNotification notificationWithName:TextDocumentSyntaxColorizeNotification object:self]
                       postingStyle:NSPostWhenIdle 
                       coalesceMask:NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender 
                           forModes:[NSArray arrayWithObject:NSDefaultRunLoopMode]];
        }
    }
}

- (void)highlightBracketAtPosition:(unsigned)aPosition inTextView:(NSTextView *)aTextView {
    static NSDictionary *mBracketAttributes=nil;
    if (!mBracketAttributes) mBracketAttributes=[[NSDictionary dictionaryWithObject:[[NSColor redColor] highlightWithLevel:0.3] 
                                                    forKey:NSBackgroundColorAttributeName] retain];
    unsigned int matchingBracketPosition=positionOfMatchingBracket([_textStorage string],aPosition);
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

- (BOOL)textView:(NSTextView *)aTextView doCommandBySelector:(SEL)aSelector {
    // NSLog(@"TextDocument textView doCommandBySelector:%@",NSStringFromSelector(aSelector));
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    NSRange affectedRange=[aTextView rangeForUserTextChange];
    NSRange selectedRange=[aTextView selectedRange];
    if (aSelector==@selector(cancel:)) {
        if (_flags.hasBlockeditRanges) {
            [self stopBlockedit];
            [(TextDocumentWindowController *)[[aTextView window] windowController] updatePositionTextField];
            return YES;
        }
    } else if (aSelector==@selector(deleteBackward:)) {
        //NSLog(@"AffectedRange=%d,%d",affectedRange.location,affectedRange.length);
        if (affectedRange.length==0 && affectedRange.location>0) {
            if (![defaults boolForKey:UsesTabsPreferenceKey]) {
                int tabWidth=[defaults integerForKey:TabWidthPreferenceKey];
                // when we have a tab we have to find the last linebreak
                NSString *string=[_textStorage string];
                int position=affectedRange.location;
                unsigned firstCharacter=0;
                while (--position>=0 && [string characterAtIndex:position]!=[@"\n" characterAtIndex:0]) {
                    if (!firstCharacter && [string characterAtIndex:position]!=[@"\t" characterAtIndex:0] &&
                                           [string characterAtIndex:position]!=[@" " characterAtIndex:0]) {
                        firstCharacter=position+1;                       
                    }
                }
                position++;
                //NSLog(@"last linebreak, firstcharacter=%d,%d",position,firstCharacter);
                if (firstCharacter==affectedRange.location || firstCharacter) {
                    return NO;
                }
                int toDelete=(affectedRange.location-position)%tabWidth;
                if (toDelete==0 && (int)affectedRange.location>position) {
                    toDelete=tabWidth; 
                }
                NSRange deleteRange;
                deleteRange.location=affectedRange.location-toDelete;
                if (deleteRange.location<firstCharacter) deleteRange.location=firstCharacter;
                deleteRange.length=affectedRange.location-deleteRange.location;
                if (deleteRange.length==0) {
                    return NO;
                }
                //NSLog(@"deleteRange=%d,%d",deleteRange.location,deleteRange.length);
                [aTextView setSelectedRange:NSMakeRange(deleteRange.location,deleteRange.length)];
                [aTextView insertText:@""];
                return YES;
            }
        }    
    } else if (aSelector==@selector(insertNewline:)) {
        NSString *indentString=nil;
        if ([defaults boolForKey:IndentsOnLinebreakPreferenceKey]) {
            // when we have a newline, we have to find the last linebreak
            NSString    *string=[_textStorage string];
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
            [aTextView insertText:[NSString stringWithFormat:@"%@%@",_lineEndingString,indentString]];        
        } else {
            [aTextView insertText:_lineEndingString];
        }
        return YES;
        
    } else if (aSelector==@selector(insertTab:) && ![defaults boolForKey:UsesTabsPreferenceKey]) {
        int tabWidth=[defaults integerForKey:TabWidthPreferenceKey];
        // when we have a tab we have to find the last linebreak
        NSRange lineRange=[[_textStorage string] lineRangeForRange:affectedRange];        
        NSString *replacementString=[@" " stringByPaddingToLength:tabWidth-((affectedRange.location-lineRange.location)%tabWidth)
                                                       withString:@" " startingAtIndex:0];
        [aTextView insertText:replacementString];
        return YES;
    } else if ((aSelector==@selector(moveLeft:) || aSelector==@selector(moveRight:)) &&
                [defaults boolForKey:ShowMatchingBracketsPreferenceKey]) {
        unsigned int position=0;
        if (aSelector==@selector(moveLeft:)) {
            position=selectedRange.location-1;        
        } else {
            position=NSMaxRange(selectedRange);
        }
        NSString *string=[_textStorage string];
        if (position>=0 && position<[_textStorage length] && 
            isBracket([string characterAtIndex:position]) ) { 
            [self highlightBracketAtPosition:position inTextView:aTextView];
        }
    }
    _flags.controlBlockedit=YES;
    return NO;
}

- (BOOL)textView:(NSTextView *)aTextView shouldChangeTextInRange:(NSRange)aAffectedCharRange 
                                               replacementString:(NSString *)aReplacementString {
//    NSLog(@"textView %d shouldChageTextInRange: %@: %@", (int)aTextView,
//            NSStringFromRange(aAffectedCharRange), 
//            aReplacementString);

    if ([aTextView hasMarkedText]) {
        [_jupiterObject pauseProcessing];
    }

    if (_flags.hasBlockeditRanges && !_flags.isBlockediting && 
        ![[self jupiterUndoManager] isUndoing] &&
        ![[self jupiterUndoManager] isRedoing]) {
        
        if ([[NSApp currentEvent] type]==NSLeftMouseUp) {
            NSBeep();
            return NO;
        }
        
        static NSCharacterSet *lineEndingSet=nil;
        if (!lineEndingSet) lineEndingSet=[[NSCharacterSet characterSetWithCharactersInString:@"\n\r"] retain];
        
        id value=[_textStorage attribute:kBlockeditAttributeName atIndex:(aAffectedCharRange.location<[_textStorage length]?aAffectedCharRange.location:[_textStorage length]-1) 
                               longestEffectiveRange:nil inRange:NSMakeRange(0,[_textStorage length])];
        if (value) {
            NSRange foundRange=[[_textStorage string] rangeOfCharacterFromSet:lineEndingSet options:0 range:aAffectedCharRange];
            if (foundRange.location!=NSNotFound) {
                NSBeep();
                return NO;
            }
            foundRange=[aReplacementString rangeOfCharacterFromSet:lineEndingSet];
            if (foundRange.location!=NSNotFound) {
                NSBeep();
//                NSLog(@"here, %d",_flags.didBlockedit);
                return NO;
            }
//          NSLog(@"Blockediting affected:%@ %@",NSStringFromRange(aAffectedCharRange),aReplacementString);
            // go through the whole text and blockedit every block, starting from the bottom
            if (!_flags.didBlockedit) {
                if ([_jupiterUndoManager groupingLevel]) {
                    [_jupiterUndoManager endUndoGrouping];
                }
                [self beginUndoGroup];

                int tabWidth=[[NSUserDefaults standardUserDefaults] integerForKey:TabWidthPreferenceKey];
                NSRange lineRange=[[_textStorage string] lineRangeForRange:aAffectedCharRange];
                unsigned locationLength=[[_textStorage string]
                    detabbedLengthForRange:NSMakeRange(lineRange.location,aAffectedCharRange.location-lineRange.location) 
                                  tabWidth:tabWidth];
                unsigned length=[[_textStorage string]
                    detabbedLengthForRange:NSMakeRange(lineRange.location,NSMaxRange(aAffectedCharRange)-lineRange.location) 
                                  tabWidth:tabWidth];
        //        lineRange.location=_flags.didBlockeditRange.location-lineRange.location;
                _flags.didBlockedit=YES;
                _flags.didBlockeditRange=aAffectedCharRange;
                _flags.didBlockeditLineRange=NSMakeRange(locationLength,length-locationLength);
            }
        } else {
            [self stopBlockedit];
        }
    } 


//    NSLog(@"NSTextView hasMarkedText: %@", ([aTextView hasMarkedText] ? @"YES" : @"NO"));
    if (![aReplacementString canBeConvertedToEncoding:[self fileEncoding]]) {
        if (!([self isRemote] || [self isShared])) {
            NSDictionary *contextInfo = [NSDictionary dictionaryWithObjectsAndKeys:aTextView, @"textView", [[aReplacementString copy] autorelease], @"replacementString", nil];
            NSBeginAlertSheet(
                NSLocalizedString(@"Warning", nil),
                NSLocalizedString(@"Cancel", nil),             
                NSLocalizedString(@"Promote to Unicode", nil),
                NSLocalizedString(@"Promote to UTF8", nil),
                [aTextView window],                
                self,                  
                @selector(sheetDidEndShouldPromote:returnCode:contextInfo:),
                NULL,                   
                [contextInfo retain],
                NSLocalizedString(@"CancelOrPromote", nil),
                nil);
        } else {
            NSBeep();
        }      
        return NO;
    } else {
        _textChangeTextView=aTextView;       
        NSAssert(!_outsideAction,@"Assertion: TextDocument textviewshouldchangetextinRange called");

        if (!_isRemote) [self updateChangeCount:[_jupiterUndoManager isUndoing]?NSChangeUndone:NSChangeDone];

        // the User changed things so he should bail out follow mode
        [[[aTextView window] windowController] setFollowUser:nil];
        
        if (LOGLEVEL(4)) NSLog(@"TextDocument: Notifying jupiter of text change");
        // decide about grouping
        if ([aReplacementString length]>1 || aAffectedCharRange.length>0) {
            if (!_undoGroupStart) {
                if ([_jupiterUndoManager groupingLevel] &&
                    ([self lastTextOperationRange].location+[[self lastTextOperationString] length])==aAffectedCharRange.location &&
                    [[self lastTextOperationString] isWhiteSpace] &&
                    [aReplacementString isWhiteSpace]) {
                    // Yes, thats right, do nothing 
                } else {
                    if ([_jupiterUndoManager groupingLevel]) {
                        [_jupiterUndoManager endUndoGrouping];
                    }
                    [_jupiterUndoManager beginUndoGrouping];
                }
            } else {
                _undoGroupStart=NO;
                [_jupiterUndoManager beginUndoGrouping];
            }
        } else if ([aReplacementString length]==1) {
            NSString *string=[self lastTextOperationString];
            if (string) {
                if ([string length]==1 &&
                    [self lastTextOperationRange].location+1==aAffectedCharRange.location &&
                    [_jupiterUndoManager groupingLevel] &&
                    ([string isWhiteSpace] == [aReplacementString isWhiteSpace])) {
                    // Yes, thats right, do nothing 
                } else {
                    if (!_undoGroupStart) {
                        if ([_jupiterUndoManager groupingLevel]) {
                            [_jupiterUndoManager endUndoGrouping];
                        }
                    } else {
                        _undoGroupStart=NO;
                    }
                    [_jupiterUndoManager beginUndoGrouping];
                }
            } else {
                [_jupiterUndoManager beginUndoGrouping];
            }
        }
        [_jupiterUndoManager registerUndoChangeTextInRange:
                            NSMakeRange(aAffectedCharRange.location,[aReplacementString length])
                        replacementString:[[_textStorage string] substringWithRange:aAffectedCharRange]];
        [self setLastTextOperationWithRange:aAffectedCharRange replacementString:aReplacementString];
        [_jupiterObject changeTextInRange:aAffectedCharRange
                        replacementString:aReplacementString]; 
        
        NSMutableDictionary *attributes=[[[self plainTextAttributes] mutableCopy] autorelease];
        if (_changeHighlighting) {
            NSColor *backgroundColor=[NSColor documentBackgroundColor];

            float userHue=[[[[UserManager sharedInstance] me] 
                            objectForKey:kUserColorHueProperty] floatValue];
            [attributes setObject:[backgroundColor userColorWithHue:userHue
                                        fraction:[[[NSUserDefaults standardUserDefaults]
                                                    objectForKey:ChangesSaturationPreferenceKey] floatValue]]
                    forKey:kHighlightColorAttribute];
        }
        [attributes setObject:[UserManager myId] forKey:kInsertedByUserAttribute];
        [attributes setObject:[UserManager myId] forKey:kHighlightFromUserAttribute];
        [attributes setObject:kSyntaxColoringIsDirtyAttributeValue forKey:kSyntaxColoringIsDirtyAttribute];
        
        if (_colorizeSyntax && _syntaxHighlighter) { // maybe optimize and put down to textDidChange
            [_textStorage beginEditing];
            if (aAffectedCharRange.location>0) {
                [_textStorage addAttribute:kSyntaxColoringIsDirtyAttribute
                                     value:kSyntaxColoringIsDirtyAttributeValue
                                     range:NSMakeRange(aAffectedCharRange.location-1,1)];
            }
            if (NSMaxRange(aAffectedCharRange)<[_textStorage length]) {
                [_textStorage addAttribute:kSyntaxColoringIsDirtyAttribute
                                     value:kSyntaxColoringIsDirtyAttributeValue
                                     range:NSMakeRange(NSMaxRange(aAffectedCharRange),1)];
            }
            [_textStorage endEditing];
        }
                    
        [aTextView setTypingAttributes:attributes];
        [_textStorage setLineStartsOnlyValidUpTo:aAffectedCharRange.location];
        _symbolListNeedsUpdate=YES;
        
        if (![_jupiterUndoManager isUndoing] && ![_jupiterUndoManager isRedoing] &&
            !_flags.isBlockediting && !_flags.didBlockedit &&
            [aReplacementString length]==1 && 
            [[NSUserDefaults standardUserDefaults] boolForKey:ShowMatchingBracketsPreferenceKey] && 
            isBracket([aReplacementString characterAtIndex:0])) {
            _showMatchingBracketPosition=aAffectedCharRange.location;
        }
        
        return YES;
    }
}

- (void)textDidChange:(NSNotification *)aNotification {
    NSTextView *textView=[aNotification object];
    if ([textView hasMarkedText]) {
        [_jupiterObject pauseProcessing];
    }
//    NSLog(@"textDidChange: %d",(int)textView);
    _textChangeTextView=nil;
    if (_colorizeSyntax) {
        [[NSNotificationQueue defaultQueue] 
            enqueueNotification:[NSNotification notificationWithName:TextDocumentSyntaxColorizeNotification object:self]
                   postingStyle:NSPostWhenIdle 
                   coalesceMask:NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender 
                       forModes:[NSArray arrayWithObject:NSDefaultRunLoopMode]];
    }        
    [[NSNotificationQueue defaultQueue] 
        enqueueNotification:[NSNotification notificationWithName:TextDocumentTextDidChangeNotification object:self]
               postingStyle:NSPostWhenIdle 
               coalesceMask:NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender 
                   forModes:[NSArray arrayWithObject:NSDefaultRunLoopMode]];
    if (_showMatchingBracketPosition!=NSNotFound) {
        [self highlightBracketAtPosition:_showMatchingBracketPosition inTextView:textView];
        _showMatchingBracketPosition=NSNotFound;
    }
    // now lets transform the participantData 
    NSEnumerator *participants=[_participants objectEnumerator];
    NSString *userId;
    while ((userId=[participants nextObject])) {
        NSRange oldSelection=[self selectionRangeForUser:userId];
        if (oldSelection.location!=NSNotFound) {
            NSRange alteredSelection=[JupiterSelectionOperation transformSelection:oldSelection 
                                                                 withTextOperation:_lastTextOperation];
            if (!NSEqualRanges(alteredSelection,oldSelection)) {
                [self setSelectionRange:alteredSelection forUser:userId];     
            }
        }
    }  
    [[[textView window] windowController] triggerSelectedSymbolTimer];
    
    // take care for blockedit
    
//    NSLog(@"haha here, %d",_flags.didBlockedit);
    if (_flags.didBlockedit && !_flags.isBlockediting && ![textView hasMarkedText]) {
//    	NSLog(@"haha");
        NSRange lineRange=_flags.didBlockeditLineRange;
        NSRange selectedRange=[textView selectedRange];
        NSString *replacementString=[[_textStorage string] 
                                        substringWithRange:NSMakeRange(_flags.didBlockeditRange.location,
                                                                       selectedRange.location-
                                                                       _flags.didBlockeditRange.location)];
        
        NSRange blockeditRange=NSMakeRange([_textStorage length],0);
        NSRange newSelectedRange=NSMakeRange(NSNotFound,0);
        int lengthChange=0;
        NSRange tempRange;
        while (blockeditRange.location!=0) {
            id value=[_textStorage attribute:kBlockeditAttributeName atIndex:blockeditRange.location-1 
                              longestEffectiveRange:&blockeditRange inRange:NSMakeRange(0,[_textStorage length])];
 
            if (value) {
                if ((!DisjointRanges(blockeditRange,selectedRange) ||
                           selectedRange.location==blockeditRange.location ||
                       NSMaxRange(blockeditRange)==selectedRange.location)) {
                    _flags.isBlockediting=YES;
                    NSRange lineRangeToExclude=[[_textStorage string] lineRangeForRange:NSMakeRange(selectedRange.location,0)];
                    if (NSMaxRange(blockeditRange)>NSMaxRange(lineRangeToExclude)) {
                        [self blockChangeTextInRange:lineRange
                                   replacementString:replacementString
                                      paragraphRange:NSMakeRange(NSMaxRange(lineRangeToExclude),
                                                                 NSMaxRange(blockeditRange)-NSMaxRange(lineRangeToExclude)) 
                                          inTextView:textView];
//                        NSLog(@"Edited Block after");
                    }
                    newSelectedRange=[textView selectedRange];
                    if (blockeditRange.location<lineRangeToExclude.location) {
                        NSRange otherRange;
                        tempRange=
                        [self blockChangeTextInRange:lineRange
                                   replacementString:replacementString
                                      paragraphRange:(otherRange=NSMakeRange(blockeditRange.location,
                                                                 lineRangeToExclude.location-blockeditRange.location)) 
                                          inTextView:textView];
//                        NSLog(@"Edited Block before");
                        lengthChange+=tempRange.length-otherRange.length;
                    }
                    _flags.isBlockediting=NO;
                } else {
                    _flags.isBlockediting=YES;
                    tempRange=
                    [self blockChangeTextInRange:lineRange
                              replacementString:replacementString
                                 paragraphRange:blockeditRange 
                                     inTextView:textView];
    //                        NSLog(@"Edited Block");
                    if (newSelectedRange.location!=NSNotFound) {
                        lengthChange+=tempRange.length-blockeditRange.length;
                    }
                    _flags.isBlockediting=NO;
                } 
            }
        }
        _flags.didBlockedit=NO;
        [self endUndoGroup];
        newSelectedRange.location+=lengthChange;
        if (!NSEqualRanges(newSelectedRange,[textView selectedRange])) {
            [textView setSelectedRange:newSelectedRange];
        }
    }
}

- (void)textDocumentTextDidChange:(NSNotification *)aNotification {
    if (_webPreviewWindowController) {
        if ([[_webPreviewWindowController window] isVisible] &&
            [_webPreviewWindowController refreshType] == kWebPreviewRefreshAutomatic) {
            [_webPreviewWindowController refresh:self];
        }
    }
}
- (void)textView:(NSTextView *)aTextView mouseDidGoDown:(NSEvent *)aEvent {
    [_jupiterObject pauseProcessing];
    if (!([aEvent modifierFlags] & NSAlternateKeyMask)) {
        _flags.controlBlockedit=YES;
    }
}

- (NSRange)textView:(NSTextView *)aTextView 
           willChangeSelectionFromCharacterRange:(NSRange)aOldSelectedCharRange 
                                toCharacterRange:(NSRange)aNewSelectedCharRange {

    if (!_flags.isBlockediting && _flags.hasBlockeditRanges && _flags.controlBlockedit) {
        unsigned positionToCheck=aNewSelectedCharRange.location;
        if (positionToCheck<[_textStorage length] || positionToCheck!=0) {
            if (positionToCheck>=[_textStorage length]) positionToCheck--;
            NSDictionary *attributes=[_textStorage attributesAtIndex:positionToCheck
            effectiveRange:NULL];
            if (![attributes objectForKey:kBlockeditAttributeName]) {
                [self stopBlockedit];
            }
            _flags.controlBlockedit=NO;
        }
    }


//    NSLog(@"textView %d willChangeSelection: %@, %@", (int)aTextView,
//           NSStringFromRange(aOldSelectedCharRange), 
//            NSStringFromRange(aNewSelectedCharRange));
    if (_outsideAction<=0 && (!_textChangeTextView || _textChangeTextView==aTextView)) {
//        NSLog(@"Really");
        [[[aTextView window] windowController] setFollowUser:nil];
        // if we have a double Click, select to matching bracket    
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
                NSString *string=[_textStorage string];
                if (isBracket([string characterAtIndex:charIndex])) {
                    unsigned matchingPosition=positionOfMatchingBracket(string,charIndex);
                    if (matchingPosition!=NSNotFound) {
                       aNewSelectedCharRange = NSUnionRange(NSMakeRange(charIndex,1),
                                                            NSMakeRange(matchingPosition,1));
                    }
                }
            }
        }
    }
    return aNewSelectedCharRange;
}

- (void)textViewDidChangeSelection:(NSNotification *)aNotification {
    NSTextView *textView=[aNotification object];
//    NSLog(@"TextView didChangeSelection %d",(int)textView);
    if (_outsideAction<=0 && ((!_textChangeTextView) || (_textChangeTextView==textView))) {
//        NSLog(@"Really");
        NSRange oldSelection=[[[aNotification userInfo] objectForKey:@"NSOldSelectedCharacterRange"] rangeValue];
        if (LOGLEVEL(4)) NSLog(@"TextDocument: Notifying jupiter of selectionChange");
        [_jupiterObject changeSelectionFromCharacterRange:oldSelection 
                                         toCharacterRange:[textView selectedRange]];
    }
    if ([textView hasMarkedText]) {
        [_jupiterObject pauseProcessing];
    }
    TextDocumentWindowController *windowController=[[textView window] windowController];
    [windowController updatePositionTextField];
    [windowController triggerSelectedSymbolTimer]; 
}

- (void)setSelectionRange:(NSRange)aSelectionRange forUser:(NSString *)aUserId {
    NSRange changedRanges[5];
    int numberOfChangedRanges=0;

    NSRange previousSelectionRange=NSMakeRange(NSNotFound,0);
    NSMutableDictionary *participantData=[_participantData objectForKey:aUserId];
    if (participantData) {
        NSArray *selectionArray=[participantData objectForKey:kSelectionProperty];
        if (selectionArray) {
            previousSelectionRange.location=[[selectionArray objectAtIndex:0] unsignedIntValue];
            previousSelectionRange.length  =[[selectionArray objectAtIndex:1] unsignedIntValue];
        }
        participantData=[[participantData mutableCopy] autorelease];
    } else {
        participantData=[NSMutableDictionary dictionary];
    }
    [participantData setObject:[NSArray arrayWithObjects:
                                    [NSNumber numberWithInt:aSelectionRange.location],
                                    [NSNumber numberWithInt:aSelectionRange.length],nil]
                        forKey:kSelectionProperty];

    [_participantData setObject:participantData
                         forKey:aUserId];                         

    if (aUserId) {
        [[NSNotificationQueue defaultQueue] 
        enqueueNotification:[NSNotification notificationWithName:TextDocumentSelectionOfUserHasChangedNotification object:self
                                                        userInfo:[NSDictionary dictionaryWithObjectsAndKeys:aUserId,kUserUserIdProperty,nil]]
               postingStyle:NSPostWhenIdle 
               coalesceMask:NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender 
                   forModes:[NSArray arrayWithObject:NSDefaultRunLoopMode]];
    }
          
    NSRange wholeText=NSMakeRange(0,[_textStorage length]);

    NSRange intersectionRange=NSIntersectionRange(previousSelectionRange,aSelectionRange);
//    NSLog(@"p: %@, s: %@, i: %@ text:%u",NSStringFromRange(previousSelectionRange),NSStringFromRange(aSelectionRange),NSStringFromRange(intersectionRange),[_textStorage length]);
    
    if (intersectionRange.length==0) {
//        NSLog(@"no intersection");
        aSelectionRange.length+=1;
        previousSelectionRange.length+=1;
        changedRanges[numberOfChangedRanges++]=previousSelectionRange;
        changedRanges[numberOfChangedRanges++]=aSelectionRange;
    } else {
        // sort, first range first, if equal, longer range first
        NSRange firstRange,secondRange;
        if (previousSelectionRange.location<aSelectionRange.location) {
            firstRange=previousSelectionRange;
            secondRange=aSelectionRange;
        } else if (previousSelectionRange.location>aSelectionRange.location) {
            firstRange=aSelectionRange;
            secondRange=previousSelectionRange;
        } else {
            if (previousSelectionRange.length>aSelectionRange.length) {
                firstRange=previousSelectionRange;
                secondRange=aSelectionRange;
            } else {
                firstRange=aSelectionRange;
                secondRange=previousSelectionRange;
            }
        }
        
        // decide
        if (NSEqualRanges(firstRange,secondRange)) {
//            NSLog(@"1");
            changedRanges[numberOfChangedRanges++]=firstRange;
        } else if (NSMaxRange(firstRange)==NSMaxRange(secondRange)) {
//            NSLog(@"2");
            changedRanges[numberOfChangedRanges++]=NSMakeRange(firstRange.location,
                                                               secondRange.location-firstRange.location);
        } else if (firstRange.location==secondRange.location) {
//            NSLog(@"3");
            // this is necessary to avoid lines being drawn or not drawn
            NSRange range=NSMakeRange(NSMaxRange(secondRange),NSMaxRange(firstRange)-NSMaxRange(secondRange));
            if (NSMaxRange(range)>=[_textStorage length]) {
                range=NSIntersectionRange(range,wholeText);
                if (range.length==0) {
                    if (wholeText.length>0) {
                        range.location=wholeText.length-1;
                        range.length=0;
                    } else {
                        range.location=0;
                        range.length=0;
                    }
                }
            }
            changedRanges[numberOfChangedRanges++]=[[_textStorage string] 
                                                    lineRangeForRange:range];
        } else if (NSEqualRanges(secondRange,intersectionRange)) {
//            NSLog(@"4");
            changedRanges[numberOfChangedRanges++]=
                NSMakeRange(firstRange.location,secondRange.location-firstRange.location);
            changedRanges[numberOfChangedRanges++]=
                NSMakeRange(NSMaxRange(secondRange),NSMaxRange(firstRange)-NSMaxRange(secondRange));
        } else {
//            NSLog(@"5: %@, %@",NSStringFromRange(firstRange),NSStringFromRange(secondRange));
            changedRanges[numberOfChangedRanges++]=
                NSMakeRange(firstRange.location,secondRange.location-firstRange.location);
            changedRanges[numberOfChangedRanges++]=
                NSMakeRange(NSMaxRange(firstRange),NSMaxRange(secondRange)-NSMaxRange(firstRange));
        }
    }
        
    int i;

    [_textStorage beginEditing];          
    for (i=0;i<numberOfChangedRanges;i++) {
        if (changedRanges[i].location>0) {
            changedRanges[i].location-=1;
            changedRanges[i].length  +=2;
        }
        changedRanges[i]=NSIntersectionRange(changedRanges[i],wholeText);
        if (changedRanges[i].length>0) {
            [_textStorage edited:NSTextStorageEditedAttributes range:changedRanges[i] changeInLength:0];
        }
    }
    [_textStorage endEditing]; 
}

- (void)remoteChangeTextInRange:   (NSRange)aAffectedCharRange
              replacementString:(NSString *)aReplacementString 
                         byUser:(NSString *)aUserId {    
    
    if (!_isRemote) [self updateChangeCount:NSChangeDone];
    
    if (NSMaxRange(aAffectedCharRange) > [_textStorage length]) {
        if (LOGLEVEL(1)) { 
            NSLog(@"INTENTIONAL ERROR!!!!!!\nSomebody wants to do things beyond your document!");
        }
    } else {
        // store oldSelections
        NSMutableArray   *oldSelections=[NSMutableArray array];
        NSEnumerator *windowControllers=[[self windowControllers] objectEnumerator];
        TextDocumentWindowController *windowController;
        while ((windowController=[windowControllers nextObject])) {
            [oldSelections addObject:[NSValue valueWithRange:[[windowController textView] selectedRange]]];
        }
        
        // change Text
        _outsideAction++;
    
        float userHue=[[[[UserManager sharedInstance] userForUserId:aUserId] 
                        objectForKey:kUserColorHueProperty] floatValue];
                        
        NSMutableDictionary *attributes=[[self plainTextAttributes] mutableCopy];
        if (_changeHighlighting) {
            NSColor *backgroundColor=[NSColor documentBackgroundColor];
            [attributes setObject:[backgroundColor userColorWithHue:userHue
                                        fraction:[[[NSUserDefaults standardUserDefaults]
                                                      objectForKey:ChangesSaturationPreferenceKey] floatValue]] 
                        forKey:kHighlightColorAttribute];
        } 
        [attributes setObject:aUserId forKey:kInsertedByUserAttribute];
        [attributes setObject:aUserId forKey:kHighlightFromUserAttribute];

        [attributes setObject:kSyntaxColoringIsDirtyAttributeValue forKey:kSyntaxColoringIsDirtyAttribute];
    
        [_textStorage beginEditing];
        if (aAffectedCharRange.location>0) {
            [_textStorage addAttribute:kSyntaxColoringIsDirtyAttribute
                                 value:kSyntaxColoringIsDirtyAttributeValue
                                 range:NSMakeRange(aAffectedCharRange.location-1,1)];
        }
        if (NSMaxRange(aAffectedCharRange)<[_textStorage length]) {
            [_textStorage addAttribute:kSyntaxColoringIsDirtyAttribute
                                 value:kSyntaxColoringIsDirtyAttributeValue
                                 range:NSMakeRange(NSMaxRange(aAffectedCharRange),1)];
        }
        [_textStorage replaceCharactersInRange:aAffectedCharRange 
                                    withString:aReplacementString];
        if ([aReplacementString length]>0) {
            [_textStorage setAttributes:attributes 
                                  range:NSMakeRange(aAffectedCharRange.location,[aReplacementString length])];
        }
        [_textStorage endEditing];
        
        [attributes release];
    
        if (_colorizeSyntax) {
            [[NSNotificationQueue defaultQueue] 
                enqueueNotification:[NSNotification notificationWithName:TextDocumentSyntaxColorizeNotification object:self]
                       postingStyle:NSPostWhenIdle 
                       coalesceMask:NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender 
                           forModes:[NSArray arrayWithObject:NSDefaultRunLoopMode]];
        }        
        [[NSNotificationQueue defaultQueue] 
            enqueueNotification:[NSNotification notificationWithName:TextDocumentTextDidChangeNotification object:self]
                   postingStyle:NSPostWhenIdle 
                   coalesceMask:NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender 
                       forModes:[NSArray arrayWithObject:NSDefaultRunLoopMode]];

        _symbolListNeedsUpdate=YES;
        [_textStorage setLineStartsOnlyValidUpTo:aAffectedCharRange.location];

        // restore old Selections
        int loop;
        JupiterTextOperation *textOperation=[JupiterTextOperation new];
        [textOperation setAffectedCharRange:aAffectedCharRange];
        [textOperation setReplacementString:aReplacementString];
        for (loop=0;loop<(int)[[self windowControllers] count];loop++) {
            NSRange oldSelection=[[oldSelections objectAtIndex:loop] rangeValue];
            oldSelection=[JupiterSelectionOperation 
                            transformSelection:oldSelection 
                             withTextOperation:textOperation];
            
            if (oldSelection.location<0 || NSMaxRange(oldSelection)>[_textStorage length]) {
                NSLog(@"Ooops, transformed Selection (%d,%d) to out of bounds of the textStorage (%d,%d)",
                        oldSelection.location,oldSelection.length,0,[_textStorage length]);
            } else { 
                [[[[self windowControllers] objectAtIndex:loop] textView] setSelectedRange:oldSelection];  
            }
        }
        // now lets transform the participantData 
        NSEnumerator *participants=[_participants objectEnumerator];
        NSString *userId;
        while ((userId=[participants nextObject])) {
            if ([userId isEqualToString:aUserId]) {
                [self setSelectionRange:NSMakeRange(aAffectedCharRange.location+[aReplacementString length],0)
                        forUser:userId];
            } else {
                NSRange     oldSelection=[self selectionRangeForUser:userId];
                if (oldSelection.location!=NSNotFound) {
                    NSRange alteredSelection=[JupiterSelectionOperation transformSelection:oldSelection 
                                                                         withTextOperation:textOperation];
                    if (!NSEqualRanges(alteredSelection,oldSelection)) {
                        [self setSelectionRange:alteredSelection forUser:userId];     
                    }
                }
            }
        }
        [textOperation release];
        _outsideAction--;    
    }
}

- (void)changeSelectionFromCharacterRange:(NSRange)aOldSelectedCharRange
                         toCharacterRange:(NSRange)aNewSelectedCharRange
                                   byUser:(NSString *)aUserId {
    
    if (!NSEqualRanges(aNewSelectedCharRange,[self selectionRangeForUser:aUserId])) {                               
        [self setSelectionRange:aNewSelectedCharRange forUser:aUserId]; 
    }
}                                  


// only Hook for Jupiter Stuff
- (void)_applyOperation:(JupiterOperation *)anOperation fromUser:(NSString*)aUserId {

    if ([anOperation isKindOfClass:[JupiterTextOperation class]]) {
        JupiterTextOperation *operation=(JupiterTextOperation *)anOperation;
        if (![operation isNoOperation]) {
            // Verify bounds of operation
            NSRange affectedCharRange = [operation affectedCharRange];
            unsigned stringLength = [[operation replacementString] length];
            unsigned length = [[self textStorage] length];
            if ((affectedCharRange.location < 0) || (NSMaxRange(affectedCharRange) > length)) {
                NSLog(@"FATAL ERROR! TextOperation out of bounds.");
                [NSException raise:@"JupiterRangeException"
                            format:@"Range: %@, Length: %u\nTextStorageLength: %u", 
                                    NSStringFromRange(affectedCharRange), stringLength, 
                                    length];
            }
            
            [self remoteChangeTextInRange:[operation affectedCharRange]
                        replacementString:[operation replacementString]
                                   byUser:aUserId];
        }                                    
    } else if ([anOperation isKindOfClass:[JupiterSelectionOperation class]]) {
        JupiterSelectionOperation *operation=(JupiterSelectionOperation *)anOperation;
        // Verfiy bounds of operation
        NSRange newSelectedCharRange = [operation newSelectedCharRange];
        unsigned length = [[self textStorage] length];
        if ((newSelectedCharRange.location < 0) || (NSMaxRange(newSelectedCharRange) > length)) {
            NSLog(@"FATAL ERROR! SelectionOperation out of bounds.");
#ifndef HYDRA_BLOCK_EXCEPTIONS
            [NSException raise:@"JupiterRangeException"
                        format:@"Range: %@\nLength: %u", 
                                NSStringFromRange(newSelectedCharRange), 
                                length];
#endif
        }
        
        [self changeSelectionFromCharacterRange:[operation oldSelectedCharRange]
                               toCharacterRange:[operation newSelectedCharRange]
                                         byUser:aUserId];
    }
}

- (void)applyOperation:(JupiterOperation *)anOperation fromUser:(NSString*)aUserId {
    if (!aUserId) {
        // internal operation unsupported at the moment
    } else if (_undoingTextView) {
        if ([anOperation isKindOfClass:[JupiterTextOperation class]]) {
            JupiterTextOperation *textOperation=(JupiterTextOperation *)anOperation;
            if ([[_undoingTextView delegate] textView:_undoingTextView 
                              shouldChangeTextInRange:[textOperation affectedCharRange] 
                                    replacementString:[textOperation replacementString]]) {
                NSAttributedString *attributedReplaceString=[[NSAttributedString alloc] 
                                                                initWithString:[textOperation replacementString] 
                                                                    attributes:[_undoingTextView typingAttributes]];
                
                [_textStorage replaceCharactersInRange:[textOperation affectedCharRange] 
                                  withAttributedString:attributedReplaceString];                    
                [[_undoingTextView delegate] 
                    textDidChange:[NSNotification notificationWithName:NSTextDidChangeNotification 
                                                                object:_undoingTextView]];
                [attributedReplaceString release];
            }            
        }
    } else {
        // remote operation
        _outsideAction++;
        [self _applyOperation:anOperation fromUser:aUserId];
        _outsideAction--;
    }
}

#pragma mark -
#pragma mark ### TableView ###

// DataSource for oPeopleTableView
- (int)numberOfRowsInTableView:(NSTableView *)tableView {
    int Return=[_participants count];
    if ([_joinRequests count]>0) {
        Return+=[_joinRequests count]+1;
    } 
    return Return;
}

- (id)tableView:(NSTableView *)aTableView 
      objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)aRow {
    static NSImage *mBlankImage=nil;
    if (!mBlankImage) mBlankImage=[[NSImage alloc] initWithSize:NSMakeSize(1.,1.)];  
    
    static NSDictionary *mSubtextAttributes=nil;
    static NSDictionary *mHostUserAttributes=nil;
    static NSDictionary *mUserAttributes=nil;
    static NSDictionary *mMiddleAttributes=nil;
    if (!mSubtextAttributes) {
        mSubtextAttributes = [[NSDictionary dictionaryWithObject:
			                 [NSFont systemFontOfSize:[NSFont smallSystemFontSize]] forKey:NSFontAttributeName] retain];
        mHostUserAttributes = [[NSDictionary dictionaryWithObject:
            [NSFont boldSystemFontOfSize:[NSFont systemFontSize]] forKey:NSFontAttributeName] retain];
        mUserAttributes = [[NSDictionary dictionaryWithObject:
                [NSFont systemFontOfSize:[NSFont systemFontSize]] forKey:NSFontAttributeName] retain];
        mMiddleAttributes=[[NSDictionary dictionaryWithObject:
                [NSFont systemFontOfSize:5.0] forKey:NSFontAttributeName] retain];

    }
    
    static NSMutableAttributedString *mPending=nil;
    if (!mPending) {
        mPending=[NSMutableAttributedString new];
        [mPending appendAttributedString: [[[NSAttributedString alloc]
                        initWithString:@"\n" attributes:mSubtextAttributes] autorelease]];
        [mPending appendAttributedString: [[[NSAttributedString alloc]
                        initWithString:NSLocalizedString(@"Pending Users:", nil) attributes:mHostUserAttributes] autorelease]];
    }
    
    NSDictionary *user=nil;
    
    if ([_joinRequests count]>0 && aRow>=(int)[_participants count]) {
        if (aRow==(int)[_participants count]) {
            if ([[aTableColumn identifier] isEqualToString:@"User"]) {
                return mPending;
            } else {
                return mBlankImage;
            }
        } else {
            user=[[UserManager sharedInstance] 
                    userForUserId:[_joinRequests objectAtIndex:aRow-[_participants count]-1]];
        }        
    } else {
        user=[[UserManager sharedInstance] userForUserId:[_participants objectAtIndex:aRow]];
    }

    if (user) {
        if ([[aTableColumn identifier] isEqualToString:@"User"]) {

            NSMutableAttributedString *result = [[[NSMutableAttributedString alloc] init] autorelease];
            if (aRow>(int)[_participants count]) {
                [result appendAttributedString:[[[NSAttributedString alloc] initWithString:@"\n" attributes:mMiddleAttributes] autorelease]];
            }
            [result appendAttributedString:[[[NSAttributedString alloc]
                    initWithString:[[user objectForKey:kUserNameProperty] 
           stringByAppendingString:@"\n"]
                        attributes:[[user objectForKey:kUserUserIdProperty] isEqualTo:_userIdOfHost]?
                                                                mHostUserAttributes:mUserAttributes] autorelease]];
            if (aRow<(int)[_participants count]) {
                NSArray *array=nil;
                if ((array=[[_participantData objectForKey:[user objectForKey:kUserUserIdProperty]] objectForKey:kSelectionProperty])) {
                    NSRange selection=NSMakeRange([[array objectAtIndex:0] intValue],
                                                  [[array objectAtIndex:1] intValue]);
                    int lineNumber=[_textStorage lineNumberForLocation:selection.location];
                    
                    [result appendAttributedString: [[[NSAttributedString alloc]
                            initWithString:[NSString stringWithFormat:@"%d:%d ",lineNumber,
                                            selection.location-[[[self lineStarts] objectAtIndex:lineNumber-1] intValue]] 
                                attributes:mSubtextAttributes] autorelease]];
                    if (selection.length) {
                        [result appendAttributedString: [[[NSAttributedString alloc]
                                initWithString:[NSString stringWithFormat:@"(%d) ",selection.length] 
                                    attributes:mSubtextAttributes] autorelease]];                
                    }
                } else if ([[user objectForKey:kUserUserIdProperty] isEqualTo:[UserManager myId]]) {
                    NSRange selection=[[(TextDocumentWindowController *)[aTableView delegate] textView] selectedRange];
                    int lineNumber=[_textStorage lineNumberForLocation:selection.location];
                    [result appendAttributedString: [[[NSAttributedString alloc]
                            initWithString:[NSString stringWithFormat:@"%d:%d ",lineNumber,
                                            selection.location-[[[self lineStarts] objectAtIndex:lineNumber-1] intValue]] 
                                attributes:mSubtextAttributes] autorelease]];
                    if (selection.length) {
                        [result appendAttributedString: [[[NSAttributedString alloc]
                                initWithString:[NSString stringWithFormat:@"(%d) ",selection.length] 
                                    attributes:mSubtextAttributes] autorelease]];                
                    }
                }
                [result addAttribute:NSForegroundColorAttributeName 
                               value:[NSColor documentForegroundColor] 
                               range:NSMakeRange(0,[result length])];
            }
            return result;

        } else {
            return [user objectForKey:[aTableColumn identifier]];
        }
    }
    return nil;
}


// this method is currently forwarded by the corresponding window controller
- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell 
   forTableColumn:(NSTableColumn *)aTableColumn row:(int)aRow {
    float hue;
    NSDictionary *user=nil;
    if (aRow<(int)[_participants count]) {
        user=[[UserManager sharedInstance] 
                userForUserId:[_participants objectAtIndex:aRow]];
    } 
    //else if (aRow>[_participants count]) {
    //    user=[[UserManager sharedInstance] 
    //            userForUserId:[_joinRequests objectAtIndex:aRow-[_participants count]-1]];
    //}
    NSColor *backgroundColor=[NSColor documentBackgroundColor];

    if ([aCell isKindOfClass:[NSTextFieldCell class]]) {
        if  (user) {
            hue=[[user objectForKey:kUserColorHueProperty] floatValue];
            [aCell setDrawsBackground: YES];
            [aCell setBackgroundColor: [backgroundColor userColorWithHue:hue
                                            fraction: [[[NSUserDefaults standardUserDefaults]
                                    objectForKey:SelectionSaturationPreferenceKey] floatValue]]];
        }
        else {
            [aCell setDrawsBackground: NO];
            [aCell setBackgroundColor: [NSColor whiteColor]];
        }
    } else {
        if (aRow>(int)[_participants count]) {
            [aCell setEnabled:NO];
        } else { 
            [aCell setEnabled:YES];
        }
    }
}

@end
