//
//  PlainTextDocument.m
//  SubEthaEdit
//
//  Created by Martin Ott on Tue Feb 24 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "TCMMillionMonkeys/TCMMillionMonkeys.h"
#import "PlainTextDocument.h"
#import "PlainTextWindowController.h"


@implementation PlainTextDocument

- (id)init
{
    self = [super init];
    if (self) {
    
        // Add your subclass-specific initialization here.
        // If an error occurs here, send a [self release] message and return nil.
        [self setSession:[[TCMMMSession alloc] initWithDocument:self]];
        [[TCMMMPresenceManager sharedInstance] registerSession:[self session]];
        I_textStorage = [NSTextStorage new];
        [I_textStorage setDelegate:self];
    
    }
    return self;
}

- (void)dealloc {
    if (I_flags.isAnnounced) {
        [[TCMMMPresenceManager sharedInstance] concealSession:[self session]];
    }
    [[TCMMMPresenceManager sharedInstance] unregisterSession:[self session]];
    [I_textStorage setDelegate:nil];
    [I_textStorage release];
    [I_session release];
}

- (void)setSession:(TCMMMSession *)aSession
{
    [I_session autorelease];
    I_session = [aSession retain];
}

- (TCMMMSession *)session
{
    return I_session;
}

- (NSTextStorage *)textStorage {
    return I_textStorage;
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

- (void)makeWindowControllers {
    DEBUGLOG(@"blah",5,@"makeWindowCotrollers");
    [self addWindowController:[[PlainTextWindowController new] autorelease]];
}

- (void)windowControllerWillLoadNib:(NSWindowController *) aController
{
    [super windowControllerWillLoadNib:aController];
    DEBUGLOG(@"blah",5,@"Willload");
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
}


- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [super windowControllerDidLoadNib:aController];
    DEBUGLOG(@"blah",5,@"didload");
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
}

- (NSData *)dataRepresentationOfType:(NSString *)aType
{
    // Insert code here to write your document from the given data.  You can also choose to override -fileWrapperRepresentationOfType: or -writeToFile:ofType: instead.
    return nil;
}

- (BOOL)readFromFile:(NSString *)fileName ofType:(NSString *)docType
{
    return [self readFromURL:[NSURL fileURLWithPath:fileName] ofType:docType];
}

- (BOOL)readFromURL:(NSURL *)aURL ofType:(NSString *)docType {

    BOOL isDir, fileExists;
    fileExists = [[NSFileManager defaultManager] fileExistsAtPath:[aURL path] isDirectory:&isDir];
    if (!fileExists || isDir) {
        return NO;
    }
    NSTextStorage *textStorage=[self textStorage];
//    int oldLength = [textStorage length];
        
//    if (oldLength==0) {
//        // determine Syntaxname
//        NSString *extension=[[aURL path] pathExtension];
//        NSString *syntaxDefinitionFile=[[SyntaxManager sharedInstance] syntaxDefinitionForExtension:extension];
//        if (syntaxDefinitionFile) {
//            NSDictionary *syntaxNames=[[SyntaxManager sharedInstance] availableSyntaxNames];
//            NSArray *keys=[syntaxNames allKeysForObject:syntaxDefinitionFile];
//            if ([keys count]>0) {
//                [self setSyntaxName:[keys objectAtIndex:0]];
//            }
//        } else {
//            [self setSyntaxName:@""];
//        }
//    }
    
//    [self setIsNew:NO];
//    if ([aURL isFileURL]) {
//        NSDictionary *fattrs = [[NSFileManager defaultManager] fileAttributesAtPath:[aURL path] traverseLink:YES];
//        [self setFileAttributes:fattrs];
//    }
    
    NSDictionary *docAttrs = nil;
    NSMutableDictionary *options = [NSMutableDictionary dictionary];
    
//    NSStringEncoding encoding;
//    NSNumber *encodingFromRunningOpenPanel = [[DocumentController sharedDocumentController] encodingFromRunningOpenPanel];
//    if (encodingFromRunningOpenPanel != nil) {
//        encoding = [encodingFromRunningOpenPanel unsignedIntValue];
//    } else {
//        encoding = [[[NSUserDefaults standardUserDefaults] objectForKey:DefaultEncodingPreferenceKey] unsignedIntValue];
//    }
//    [[DocumentController sharedDocumentController] setEncodingFromRunningOpenPanel:nil];

//    if (encoding < SmallestCustomStringEncoding) {
//        if (LOGLEVEL(1)) {
//            NSLog(@"Setting \"CharacterEncoding\" option");
//            NSLog(@"trying encoding: %@", [NSString localizedNameOfStringEncoding:encoding]);
//        }
//        [options setObject:[NSNumber numberWithUnsignedInt:encoding] forKey:@"CharacterEncoding"];
//    }
    
    //[options setObject:NSPlainTextDocumentType forKey:@"DocumentType"];
//    [options setObject:[self plainTextAttributes] forKey:@"DefaultAttributes"];
    
    [[textStorage mutableString] setString:@""];	// Empty the document
    
    while (TRUE) {
        BOOL success;
        
        [textStorage beginEditing];
        success = [textStorage readFromURL:aURL options:options documentAttributes:&docAttrs];
        [textStorage endEditing];
        if (!success) {
            NSNumber *encodingNumber = [options objectForKey:@"CharacterEncoding"];
            if (encodingNumber != nil) {
                NSStringEncoding systemEncoding = CFStringConvertEncodingToNSStringEncoding(CFStringGetSystemEncoding());
                NSStringEncoding triedEncoding = [encodingNumber unsignedIntValue];
                if (triedEncoding == NSUTF8StringEncoding && triedEncoding != systemEncoding) {
                    [[textStorage mutableString] setString:@""];	// Empty the document, and reload
                    [options setObject:[NSNumber numberWithUnsignedInt:systemEncoding] forKey:@"CharacterEncoding"];
                    continue;
                }
            }
            return NO;
        }
        
        if (![[docAttrs objectForKey:@"DocumentType"] isEqualToString:NSPlainTextDocumentType] &&
            ![[options objectForKey:@"DocumentType"] isEqualToString:NSPlainTextDocumentType]) {
            [[textStorage mutableString] setString:@""];	// Empty the document, and reload
            [options setObject:NSPlainTextDocumentType forKey:@"DocumentType"];
        } else {
            break;
        }
    }
    
//    [_textStorage beginEditing];
//    [_textStorage addAttributes:[self plainTextAttributes]
//                          range:NSMakeRange(0, [_textStorage length])];
//    [_textStorage endEditing];
    
//    [self setFileEncoding:[[docAttrs objectForKey:@"CharacterEncoding"] intValue]];
//    if (LOGLEVEL(1)) NSLog(@"fileEncoding: %@", [NSString localizedNameOfStringEncoding:[self fileEncoding]]);

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
    return YES;
}


- (BOOL)validateMenuItem:(NSMenuItem *)anItem {
    SEL selector=[anItem action];
    if (selector==@selector(announce:)) {
        return !I_flags.isAnnounced;
    } else if (selector==@selector(conceal:)) {
        return I_flags.isAnnounced;
    }
    return [super validateMenuItem:anItem];
}

#pragma mark -
#pragma mark ### Session Interaction ###

- (void)handleOperation:(TCMMMOperation *)aOperation {
    
}

@end
