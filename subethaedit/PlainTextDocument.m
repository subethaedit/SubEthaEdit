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

#import "DocumentModeManager.h"
#import "DocumentMode.h"
#import "SyntaxHighlighter.h"

#import "TextStorage.h"
#import "TextOperation.h"
#import "SelectionOperation.h"

static NSString * const PlainTextDocumentSyntaxColorizeNotification = @"PlainTextDocumentSyntaxColorizeNotification";

@implementation PlainTextDocument

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
    I_flags.highlightSyntax = YES;
    I_fonts.plainFont = [[NSFont fontWithName:@"ArialMT" size:0.] retain];
    [self TCM_styleFonts];
}

- (id)init
{
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
    [[TCMMMPresenceManager sharedInstance] unregisterSession:[self session]];
    [I_textStorage setDelegate:nil];
    [I_textStorage release];
    [I_session release];
    [I_plainTextAttributes release];
    [I_fonts.plainFont release];
    [I_fonts.boldFont release];
    [I_fonts.italicFont release];
    [I_fonts.boldItalicFont release];
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

- (DocumentMode *)documentMode {
    return I_documentMode;
}

- (void)setDocumentMode:(DocumentMode *)aDocumentMode {
    [I_documentMode autorelease];
     I_documentMode = [aDocumentMode retain];
}

- (unsigned int)fileEncoding {
    return [(TextStorage *)[self textStorage] encoding];
}

- (void)setFileEncoding:(unsigned int)anEncoding {
    [(TextStorage *)[self textStorage] setEncoding:anEncoding];
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

    [I_textStorage addAttributes:[self plainTextAttributes]
                           range:NSMakeRange(0,[I_textStorage length])];

    DocumentMode *mode=[[DocumentModeManager sharedInstance] documentModeForExtension:[[aURL path] pathExtension]];
    [self setDocumentMode:mode];
    
    if ([mode syntaxHighlighter]!=nil) {
        [self highlightSyntaxInRange:NSMakeRange(0,[I_textStorage length])];
    }

    return YES;
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
        [attributes setObject:[self fontWithTrait:NSBoldFontMask]
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

#pragma mark -
#pragma mark ### Syntax Highlighting ###
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

- (void)handleOperation:(TCMMMOperation *)aOperation {
    if ([[aOperation operationID] isEqualToString:[TextOperation operationID]]) {
        // gather selections from all textviews and transform them
        NSArray *controllers=[self windowControllers];
        NSMutableArray   *oldSelections=[NSMutableArray array];
        NSEnumerator *windowControllers=[controllers objectEnumerator];
        PlainTextWindowController *windowController;
        while ((windowController=[windowControllers nextObject])) {
            [oldSelections addObject:[SelectionOperation selectionOperationWithRange:[[windowController textView] selectedRange] userID:@"doesn't matter"]];
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
        for (index=0;index<(int)[[self windowControllers] count];index++) {
            SelectionOperation *selectionOperation = [oldSelections objectAtIndex:index];
            [[TCMMMTransformator sharedInstance] transformOperation:selectionOperation serverOperation:aOperation];
            windowController = [controllers objectAtIndex:index];
            [[windowController textView] setSelectedRange:[selectionOperation selectedRange]];
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
#pragma mark ### TextView Notifications ###

- (void)textViewDidChangeSelection:(NSNotification *)aNotification {
    if (!I_flags.isRemotelyEditingTextStorage) {
        NSRange selectedRange = [(NSTextView *)[aNotification object] selectedRange];
        SelectionOperation *selOp = [SelectionOperation selectionOperationWithRange:selectedRange userID:[TCMMMUserManager myUserID]];
        [[self session] documentDidApplyOperation:selOp];
    }
}

@end
