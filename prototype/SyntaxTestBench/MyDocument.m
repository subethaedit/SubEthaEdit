//
//  MyDocument.m
//  SubEthaHighlighter
//
//  Created by Dominik Wagner on Fri Jan 23 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "sys/time.h"
#import "MyDocument.h"
#import "AppController.h"

NSString * const kBlockeditAttributeName =@"Blockedit";
NSString * const kBlockeditAttributeValue=@"YES";

enum {
    SmallestCustomStringEncoding = 0xFFFFFFF0
};

@interface NSMenuItem (Sorting)
- (NSComparisonResult)compareAlphabetically:(NSMenuItem *)aNotherMenuItem;
@end

@implementation NSMenuItem (Sorting)
- (NSComparisonResult)compareAlphabetically:(NSMenuItem *)aMenuItem {
    return [[self title] caseInsensitiveCompare:[aMenuItem title]];
}
@end

/*"Assistant function for correct tabwidth"*/
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

    return array;
}

NSString * const TextDocumentSyntaxColorizeNotification=@"TextDocumentSyntaxColorizeNotification";

@interface MyDocument (MyDocumentPrivateAdditions) 

-(void)updatePositionTextField;
-(void)adjustStatusBarFrames;
    
@end

@implementation MyDocument
/*"!{MyDocument} is just a demo implementation for a Multi-Document-Architecture controller class that utilizes our editing code"*/

#pragma mark ### initialisation / deallocation ###
- (id)init {
    self = [super init];
    if (self) {
        I_textStorage=[TextStorage new];
        I_textContainer=nil;
        I_flags.colorizeSyntax=YES;
        I_flags.performingSyntaxColorize=NO;
        I_flags.symbolListNeedsUpdate=YES;

        I_symbolPopUpMenu      =[NSMenu new];
        I_symbolPopUpMenuSorted=[NSMenu new];
        I_symbols=nil;
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(performSyntaxColorize:)
                                                     name:TextDocumentSyntaxColorizeNotification
                                                   object:nil];
                                                   
        I_selectedSymbolUpdateTimer=nil;
    }
    return self;
}

- (void)dealloc {
    //NSLog(@"Document gets dealloced");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [I_selectedSymbolUpdateTimer invalidate];
    [I_selectedSymbolUpdateTimer release];
    [I_textStorage release];
    [I_textContainer release];
    [I_symbolPopUpMenu       release];
    [I_symbolPopUpMenuSorted release];
    [I_symbols release];
    [super dealloc];
}

- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"MyDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [super windowControllerDidLoadNib:aController];

    [O_scrollView setHasVerticalScroller:YES];
//    [[O_scrollView contentView] setAutoresizesSubviews:NO];
    NSRect frame;
    frame.origin=NSMakePoint(0.,0.);
    frame.size  =[O_scrollView contentSize];

    NSLayoutManager *layoutManager= [NSLayoutManager new];
    [I_textStorage addLayoutManager:layoutManager];
    
    I_textContainer =  [[NSTextContainer alloc] initWithContainerSize:NSMakeSize(frame.size.width,FLT_MAX)];

    I_textView=[[NSTextView alloc] initWithFrame:frame textContainer:I_textContainer];
    [I_textView setHorizontallyResizable:NO];
    [I_textView setVerticallyResizable:YES];
    [I_textView setAutoresizingMask:NSViewWidthSizable];
    [I_textView setMaxSize:NSMakeSize(FLT_MAX, FLT_MAX)];
    [I_textView setSelectable:YES];
    [I_textView setEditable:YES];
    [I_textView setRichText:YES];
    [I_textView setImportsGraphics:YES];
    [I_textView setUsesFontPanel:YES];
    [I_textView setUsesRuler:YES];

    [I_textContainer setHeightTracksTextView:NO];
    [I_textContainer setWidthTracksTextView:YES];
    [layoutManager addTextContainer:I_textContainer];
    
    [O_scrollView setVerticalRulerView:[[[LineNumberRulerView alloc] initWithScrollView:O_scrollView orientation:NSVerticalRuler] autorelease]];
    [O_scrollView setHasVerticalRuler:YES];
    [[O_scrollView verticalRulerView] setRuleThickness:32.];

    [O_scrollView setDocumentView:I_textView];
    [[O_scrollView verticalRulerView] setClientView:I_textView];
    
    [I_textView setDelegate:self];
    [layoutManager release];

    [O_symbolPopUpButton setDelegate:self];
    [O_symbolPopUpButton setPullsDown:NO];
    [O_symbolPopUpButton setStringValue:NSLocalizedString(@"<No selected symbol>", nil)];
    [[O_symbolPopUpButton cell] setControlSize:NSSmallControlSize];
    [[O_symbolPopUpButton cell] setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];

    [self updatePositionTextField];
}



#pragma mark ### Accesors ###

- (NSWindow *)window {
    return O_window;
}

/*"This method returns the plainTextAttributes that should be default for newly inserted and uncolored code. This includes Tabstops as well. Foregroundcolor is essential because the syntaxhighlighter has to removes attributes by applying these."*/
- (NSMutableDictionary *)plainTextAttributes {
    if (!I_textAttributes) {
//        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSFont *userFont = [NSFont userFixedPitchFontOfSize:0.0];
        NSFont *displayFont = nil;
        if (displayFont == nil)
            displayFont = userFont;
        NSMutableParagraphStyle *myParagraphStyle = [[NSMutableParagraphStyle new] autorelease];
        [myParagraphStyle setParagraphStyle:[NSParagraphStyle defaultParagraphStyle]];
        NSArray *tabStops;
        unsigned spacesPerTab=5; //[defaults integerForKey:TabWidthPreferenceKey];
        tabStops = tabStopArrayForFontAndTabWidth(displayFont, spacesPerTab);

        [myParagraphStyle setTabStops:tabStops];
        NSColor *foregroundColor=[NSColor blackColor];

        I_textAttributes=[NSMutableDictionary new];
        [I_textAttributes setObject:userFont
                            forKey:NSFontAttributeName];
        [I_textAttributes setObject:[NSNumber numberWithInt:0]
                            forKey:NSLigatureAttributeName];
        [I_textAttributes setObject:myParagraphStyle
                            forKey:NSParagraphStyleAttributeName];
        [I_textAttributes setObject:foregroundColor
                            forKey:NSForegroundColorAttributeName];
    }
    return I_textAttributes;
}

/*"Sets the Name of the Syntax Definition to be used and changes the Syntax Coloring accordingly (if on)"*/
- (void)setSyntaxName:(NSString *)aSyntaxName {
    [I_syntaxName autorelease];
    I_syntaxName=[aSyntaxName copy];
    [[NSRunLoop currentRunLoop] cancelPerformSelectorsWithTarget:self];
    [I_syntaxHighlighter cleanup:[I_textView textStorage]];
    [I_syntaxHighlighter release];
    
    I_syntaxHighlighter=[[SyntaxManager sharedInstance] syntaxHighlighterForName:I_syntaxName];
//    I_flags.symbolListNeedsUpdate=YES; 
}


#pragma mark ### File loading/saving ###


- (NSData *)dataRepresentationOfType:(NSString *)aType
{
    // Insert code here to write your document from the given data.  You can also choose to override -fileWrapperRepresentationOfType: or -writeToFile:ofType: instead.
    return nil;
}

- (BOOL)loadDataRepresentation:(NSData *)data ofType:(NSString *)aType
{
    return nil;
//    NSString *tempString=[[[NSString alloc] initWithData:data encoding:NSMacOSRomanStringEncoding] autorelease];
//    I_textStorage=[[NSTextStorage alloc] initWithString:tempString];
//    return YES;
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
    
    NSDictionary *docAttrs = nil;
    NSMutableDictionary *options = [NSMutableDictionary dictionary];
    
    NSStringEncoding encoding=NSUTF8StringEncoding;
    
    if (encoding < SmallestCustomStringEncoding) {
        [options setObject:[NSNumber numberWithUnsignedInt:encoding] forKey:@"CharacterEncoding"];
    }
    
    [options setObject:[self plainTextAttributes] forKey:@"DefaultAttributes"];
    
    [[I_textStorage mutableString] setString:@""]; // Empty the document (e.g. for revert)
    
    while (YES) {
        BOOL success;
        
        [I_textStorage beginEditing];
        success = [I_textStorage readFromURL:aURL options:options documentAttributes:&docAttrs];
        [I_textStorage endEditing];
        if (!success) {
            NSNumber *encodingNumber = [options objectForKey:@"CharacterEncoding"];
            if (encodingNumber != nil) {
                NSStringEncoding systemEncoding = CFStringConvertEncodingToNSStringEncoding(CFStringGetSystemEncoding());
                NSStringEncoding triedEncoding = [encodingNumber unsignedIntValue];
                if (triedEncoding == NSUTF8StringEncoding && triedEncoding != systemEncoding) {
                    [[I_textStorage mutableString] setString:@""];	// Empty the document, and reload
                    [options setObject:[NSNumber numberWithUnsignedInt:systemEncoding] 
                                forKey:@"CharacterEncoding"];
                    continue;
                }
            }
             return NO;
        }
        
        if (![[docAttrs objectForKey:@"DocumentType"] isEqualToString:NSPlainTextDocumentType] &&
            ![[options  objectForKey:@"DocumentType"] isEqualToString:NSPlainTextDocumentType]) {
            [[I_textStorage mutableString] setString:@""];	// Empty the document, and reload
            [options setObject:NSPlainTextDocumentType forKey:@"DocumentType"];
        } else {
            break;
        }
    }
    
    [I_textStorage beginEditing];
    [I_textStorage addAttributes:[self plainTextAttributes]
                          range:NSMakeRange(0,[I_textStorage length])];
    [I_textStorage endEditing];
    
//    [self setFileEncoding:[[docAttrs objectForKey:@"CharacterEncoding"] intValue]];

    if (I_flags.colorizeSyntax) {
        struct timeval begin, end;
        
        gettimeofday(&begin, NULL); //Start

        [self syntaxColorizeInOneGoInRange:NSMakeRange(0,[I_textStorage length])];

        gettimeofday(&end, NULL); //Ende
        
        lasttime = (double)((end.tv_sec - begin.tv_sec)*1000000 + (end.tv_usec-begin.tv_usec))/1000;
        NSLog(@"Syntax coloring upon load: %f mSecs", lasttime);
    }

    return YES;
}

- (IBAction)runTest:(id)aSender 
{
    
    NSLog(@"Test: %@", [aSender title]);
    
    int i;
    double totaltime=0;
    for(i=0;i<5;i++) {
        [self readFromFile:[[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Tests/"] stringByAppendingPathComponent:[aSender title]] ofType:@"DocumentType"];
        totaltime+=lasttime;
    }

    for(i=0;i<5;i++) {
        struct timeval begin, end;
        
        gettimeofday(&begin, NULL); //Start

        [self syntaxColorizeInOneGoInRange:NSMakeRange(0,[I_textStorage length])];

        gettimeofday(&end, NULL); //Ende
        
        lasttime = (double)((end.tv_sec - begin.tv_sec)*1000000 + (end.tv_usec-begin.tv_usec))/1000;
        NSLog(@"Syntax coloring upon recoloring: %f mSecs", lasttime);

        totaltime+=lasttime;
    }
    
    NSLog(@"10 Loads average: %f mSecs", totaltime / 10);
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {

    if ([menuItem action] == @selector(chooseSyntaxName:)) {
        if ([menuItem tag]==kNoneModeMenuItemTag)   {
            [menuItem setState:[I_syntaxName isEqualToString:@""]?NSOnState:NSOffState];
        } else {
            [menuItem setState:[[menuItem title] isEqualToString:I_syntaxName]?NSOnState:NSOffState];
        }
        return YES;
    } else if ([menuItem action]==@selector(toggleWrap:)) {
        [menuItem setState:(![O_scrollView hasHorizontalScroller])];
    } else if ([menuItem action] == @selector(toggleSyntaxColoring:)) {
        [menuItem setState:I_flags.colorizeSyntax?NSOnState:NSOffState];
        return YES;
    }
    return YES;
}

/*"IBAction to toggle Wrap/NoWrap"*/
- (IBAction)toggleLineNumbers:(id)aSender {
    [O_scrollView setRulersVisible:![O_scrollView rulersVisible]];
}


/*"IBAction to toggle Wrap/NoWrap"*/
- (IBAction)toggleWrap:(id)aSender {
    if (![O_scrollView hasHorizontalScroller]) {
        // turn wrap off
        [O_scrollView setHasHorizontalScroller:YES];
        [I_textContainer setWidthTracksTextView:NO];
        [I_textView setAutoresizingMask:NSViewNotSizable];
        [I_textContainer setContainerSize:NSMakeSize(FLT_MAX,FLT_MAX)];
        [I_textView setHorizontallyResizable:YES];
        [I_textView setNeedsDisplay:YES];
        [O_scrollView setNeedsDisplay:YES];
    } else {            
        // turn wrap on
        [O_scrollView setHasHorizontalScroller:NO];
        [O_scrollView setNeedsDisplay:YES];
        [I_textContainer setWidthTracksTextView:YES];
        [I_textView setHorizontallyResizable:NO];
        [I_textView setAutoresizingMask:NSViewWidthSizable];
        NSRect frame=[I_textView frame];
        frame.size.width=[O_scrollView contentSize].width;
        [I_textView setFrame:frame];
        [I_textView setNeedsDisplay:YES];
    }
}


/*"IBAction for the Syntax Mode Menu entries"*/
- (IBAction)chooseSyntaxName:(id)aSender {
    
    [self setSyntaxName:[aSender tag]==kNoneModeMenuItemTag?@"":[aSender title]];
    if (I_flags.colorizeSyntax) {
        if (I_syntaxHighlighter) {
            [self syntaxColorizeInRange:NSMakeRange(0,[[I_textView textStorage] length])];
        } else {
            [[I_textView textStorage] addAttributes:[self plainTextAttributes] 
                                  range:NSMakeRange(0,[[I_textView textStorage] length])];
        }
    }
    //[self updatePositionTextField];
}

/*"IBAction for "Colorize Syntax" menu item"*/
- (IBAction)toggleSyntaxColoring:(id)aSender {
    I_flags.colorizeSyntax=!I_flags.colorizeSyntax;
    NSTextStorage *textStorage=[I_textView textStorage];
    [textStorage beginEditing];
    if (I_flags.colorizeSyntax) {
        [self syntaxColorizeInRange:NSMakeRange(0,[textStorage length])];
    } else {
        [textStorage addAttributes:[self plainTextAttributes] 
                              range:NSMakeRange(0,[textStorage length])];
    }
    [textStorage endEditing];
}

/*"Schedule a syntaxColorize if not already scheduled"*/
- (void)performSyntaxColorize:(id)aSender {
    if (!I_flags.performingSyntaxColorize && I_flags.colorizeSyntax && I_syntaxHighlighter) {
        [self performSelector:@selector(syntaxColorize) withObject:nil afterDelay:0.3];                
        I_flags.performingSyntaxColorize=YES;
    }
}

/*"colorize a chunck of the dirty part of the TextStorage, if not complete schedule another call"*/
- (void)syntaxColorize {
    I_flags.performingSyntaxColorize=NO;
    if (I_flags.colorizeSyntax) {
        NSTextStorage *textStorage= I_textStorage?I_textStorage:[I_textView textStorage];
        if (I_syntaxHighlighter && ![I_syntaxHighlighter colorizeDirtyRanges:textStorage]) {
            [self performSyntaxColorize:self];
        }
    }
}

/*"mark range as dirty and colorize afterwards via notficiation so the actual caller can end its job first"*/
- (void)syntaxColorizeInRange:(NSRange)aRange {
    if (I_flags.colorizeSyntax) {
        NSTextStorage *textStorage= I_textStorage?I_textStorage:[I_textView textStorage];
        NSRange range=NSIntersectionRange(aRange,NSMakeRange(0,[textStorage length]));
        if (range.length>0) {
            [textStorage addAttribute:kSyntaxColoringIsDirtyAttribute 
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

- (void)syntaxColorizeInOneGoInRange:(NSRange)aRange {
    // mark range as dirty
    NSTextStorage *textStorage= I_textStorage?I_textStorage:[I_textView textStorage];
    [textStorage addAttribute:kSyntaxColoringIsDirtyAttribute 
                                 value:kSyntaxColoringIsDirtyAttributeValue 
                                 range:aRange];
    while (![I_syntaxHighlighter colorizeDirtyRanges:textStorage]) {
        ;
    }
}

#pragma mark ### Symbol Pop Up Handling ###

#define POPUPUPDATEINTERVAL 2.5

- (void)triggerSelectedSymbolTimer {
    if ([I_selectedSymbolUpdateTimer isValid]) {
        [I_selectedSymbolUpdateTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:POPUPUPDATEINTERVAL]];
    } else {
        [I_selectedSymbolUpdateTimer release];
        I_selectedSymbolUpdateTimer=[[NSTimer scheduledTimerWithTimeInterval:POPUPUPDATEINTERVAL 
                                                target:self 
                                              selector:@selector(selectedSymbolTimerAction:)
                                              userInfo:nil repeats:NO] retain];
    }
}

- (void)selectedSymbolTimerAction:(NSTimer *)aTimer {
    [self updateSelectedSymbol];
}


- (void)updateSymbolList {
    if (I_flags.symbolListNeedsUpdate) {
        [I_symbols release];
        I_symbols=[[I_syntaxHighlighter symbolsInAttributedString:I_textStorage] retain];
        
        int count=[I_symbolPopUpMenu numberOfItems];
        while (count) {
            [I_symbolPopUpMenu removeItemAtIndex:count-1];
            count=[I_symbolPopUpMenu numberOfItems];
        }

        count=[I_symbolPopUpMenuSorted numberOfItems];
        while (count) {
            [I_symbolPopUpMenuSorted removeItemAtIndex:count-1];
            count=[I_symbolPopUpMenuSorted numberOfItems];
        }
        
        NSEnumerator *symbols=[I_symbols objectEnumerator];    
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
                [I_symbolPopUpMenu addItem:[NSMenuItem separatorItem]];
            } else {
                menuItem=[prototypeMenuItem copy];
                [menuItem setTag:i];
                [menuItem setTitle:name];
                [I_symbolPopUpMenu addItem:menuItem];
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
            [I_symbolPopUpMenuSorted addItem:menuItem];
        }

        I_flags.symbolListNeedsUpdate=NO;

        I_flags.symbolPopUpMenuNeedsUpdate=YES;
    }
}


- (NSMenu *)symbolPopUpMenuForView:(NSTextView *)aTextView sorted:(BOOL)aSorted {
    NSMenu *menu=aSorted?I_symbolPopUpMenuSorted:I_symbolPopUpMenu;
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
    NSEnumerator *items=[[I_symbolPopUpMenu itemArray] objectEnumerator];
    NSMenuItem   *item;
    while ((item=[items nextObject])) { 
        if (![item isSeparatorItem]) { 
            NSRange symbolRange=[[[I_symbols objectAtIndex:[item tag]] objectForKey:@"Range"] rangeValue];
            if (symbolRange.location>aRange.location) {
                break;
            }
            lastPossibleSelect=select;
        }
        select++;
    }
    return lastPossibleSelect;
}

- (void)updateSymbolPopUpMenu {
    NSEvent *currentEvent=[NSApp currentEvent];
    BOOL sorted=([currentEvent type]==NSLeftMouseDown && ([currentEvent modifierFlags]&NSAlternateKeyMask));
    if (I_flags.symbolPopUpMenuNeedsUpdate || sorted!=I_flags.symbolLastPopUpMenuWasSorted) {
        I_flags.symbolLastPopUpMenuWasSorted=sorted;
        NSMenu *popUpMenu=[self symbolPopUpMenuForView:I_textView sorted:sorted];
        NSPopUpButtonCell *popUpCell=[O_symbolPopUpButton cell];
        [popUpCell removeAllItems];
        if ([[popUpMenu itemArray] count]) {
            NSMenu *copiedMenu=[popUpMenu copyWithZone:[NSMenu menuZone]];
            [popUpCell setMenu:copiedMenu];
            [copiedMenu release];
        } else {
            [popUpCell addItemWithTitle:NSLocalizedString(@"<No selected symbol>", nil)];
        }
        
        I_flags.symbolPopUpMenuNeedsUpdate=NO;
    }
}

- (void)updateSelectedSymbol {
    int selectedSymbol=[self selectedSymbolForRange:[I_textView selectedRange]];
    [self updateSymbolPopUpMenu];
    NSArray *itemArray=[[O_symbolPopUpButton cell] itemArray];
    int i;
    for (i=[itemArray count]-1;i>=0;i--) {
        if ([[itemArray objectAtIndex:i] tag]==selectedSymbol) {
            break;
        }
    }
    [[O_symbolPopUpButton cell] selectItemAtIndex:i];
    [self adjustStatusBarFrames];
}


- (void)textPopUpWillShowMenu:(NSPopUpButtonCell *)aCell {
    [self updateSelectedSymbol];
}

- (IBAction)didChooseGotoSymbolMenuItem:(NSMenuItem *)aMenuItem {
    NSRange symbolRange=[[[I_symbols objectAtIndex:[aMenuItem tag]] objectForKey:@"Range"] rangeValue];
    [I_textView setSelectedRange:symbolRange];
    [I_textView scrollRangeToVisible:symbolRange];   
}


#pragma mark ### Notification Handling ###

#define RIGHTINSET 5.

- (void)updatePositionTextField {
    if (/*_hasStatusBar*/ YES) {
        NSRange selection=[I_textView selectedRange];
        
        // findLine
        int lineNumber=[I_textStorage lineNumberForLocation:selection.location];
        unsigned lineStartLocation=[[[I_textStorage lineStarts] objectAtIndex:lineNumber-1] intValue];
        NSString *string=[NSString stringWithFormat:@"%d:%d",lineNumber, selection.location-lineStartLocation];
        if (selection.length>0) string=[string stringByAppendingFormat:@" (%d)",selection.length]; 
        if (selection.location<[I_textStorage length]) { 
            id blockAttribute=[I_textStorage 
                                attribute:kBlockeditAttributeName 
                                  atIndex:selection.location effectiveRange:nil];
            if (blockAttribute) string=[string stringByAppendingFormat:@" %@",NSLocalizedString(@"[Blockediting]", nil)];        
        }
        [O_positionTextField setStringValue:string];        
        
        [self adjustStatusBarFrames];  
    }
}


/*"moves the popup-window according to the position so no space is wasted"*/
- (void)adjustStatusBarFrames {

    static NSDictionary *smallFontAttributes=nil;
    if (!smallFontAttributes)
        smallFontAttributes=[[NSDictionary dictionaryWithObject:[O_positionTextField font] 
                                                         forKey:NSFontAttributeName] retain];

    NSView *contentView=[[self window] contentView];
    NSRect  refreshRect=[contentView bounds];
    NSPoint    position=[O_positionTextField frame].origin;
    position.x+=[[O_positionTextField stringValue] sizeWithAttributes:smallFontAttributes].width+5.;
    unsigned width=refreshRect.size.width+refreshRect.origin.x-position.x-RIGHTINSET-3.;
    NSRect newPopUpFrame=[O_symbolPopUpButton frame];
    newPopUpFrame.origin.x=position.x;
    if ([I_syntaxHighlighter hasSymbols]) {
        newPopUpFrame.size.width=[[O_symbolPopUpButton cell] desiredWidth];
        if (newPopUpFrame.size.width>width) {
            newPopUpFrame.size.width=width;    
        }
    } else {
        newPopUpFrame.size.width=0;
    }

    [O_symbolPopUpButton setFrame:newPopUpFrame];
    [O_symbolPopUpButton setNeedsDisplay:YES];

    refreshRect.origin.y=newPopUpFrame.origin.y;
    refreshRect.size.height=newPopUpFrame.size.height;
    [contentView setNeedsDisplayInRect:refreshRect];
}

-(void)windowWillClose:(NSNotification *)aNotification {
    [I_selectedSymbolUpdateTimer invalidate];
    [I_selectedSymbolUpdateTimer release];
    I_selectedSymbolUpdateTimer=nil;
    //NSLog(@"windowDidClose");
    [[NSRunLoop currentRunLoop] cancelPerformSelectorsWithTarget:self];
}

-(void)windowDidResize:(NSNotification *)aNotification {
    [self adjustStatusBarFrames];
}


#pragma mark ### Text View Delegate Methods ###
- (void)textViewDidChangeSelection:(NSNotification *)aNotification {
    [self updatePositionTextField];
    [self triggerSelectedSymbolTimer];
}

- (BOOL)textView:(NSTextView *)aTextView shouldChangeTextInRange:(NSRange)aAffectedCharRange 
                                               replacementString:(NSString *)aReplacementString {

        NSMutableDictionary *attributes=[[[self plainTextAttributes] mutableCopy] autorelease];
        [attributes setObject:kSyntaxColoringIsDirtyAttributeValue forKey:kSyntaxColoringIsDirtyAttribute];
        
        if (I_flags.colorizeSyntax && I_syntaxHighlighter) { 
            [[aTextView textStorage] beginEditing];
            if (aAffectedCharRange.location>0) {
                [[aTextView textStorage] addAttribute:kSyntaxColoringIsDirtyAttribute
                                     value:kSyntaxColoringIsDirtyAttributeValue
                                     range:NSMakeRange(aAffectedCharRange.location-1,1)];
            }
            if (NSMaxRange(aAffectedCharRange)<[[aTextView textStorage] length]) {
                [[aTextView textStorage] addAttribute:kSyntaxColoringIsDirtyAttribute
                                     value:kSyntaxColoringIsDirtyAttributeValue
                                     range:NSMakeRange(NSMaxRange(aAffectedCharRange),1)];
            }
            [[aTextView textStorage] endEditing];
        }
                    
        [aTextView setTypingAttributes:attributes];

        return YES;
}

- (void)textDidChange:(NSNotification *)aNotification {
    if (I_flags.colorizeSyntax) {
        [[NSNotificationQueue defaultQueue] 
            enqueueNotification:[NSNotification notificationWithName:TextDocumentSyntaxColorizeNotification object:self]
                   postingStyle:NSPostWhenIdle 
                   coalesceMask:NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender 
                       forModes:[NSArray arrayWithObject:NSDefaultRunLoopMode]];
    }   
    if ([O_scrollView rulersVisible]) {
        [[O_scrollView verticalRulerView] setNeedsDisplay:YES];     
    }
    [self triggerSelectedSymbolTimer];
    I_flags.symbolListNeedsUpdate=YES;
}



@end
