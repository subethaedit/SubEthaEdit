//
//  FindReplaceController.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Fri Apr 23 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "OgreKit/OgreKit.h"
#import "FindReplaceController.h"
#import "PlainTextWindowController.h"
#import "TextStorage.h"
#import "FindAllController.h"
#import "UndoManager.h"
#import "time.h"

static FindReplaceController *sharedInstance=nil;

@implementation FindReplaceController


+ (FindReplaceController *)sharedInstance {
    return sharedInstance;
}

- (id)init {
    if (sharedInstance) {
        [super dealloc];
        return sharedInstance;
    }
    
    self = [super init];
    if (self) {
        sharedInstance = self;
        I_findHistory = [NSMutableArray new];
        I_replaceHistory = [NSMutableArray new];
    }
    return self;
}

- (void) dealloc {
    [I_findHistory dealloc];
    [I_replaceHistory dealloc];
    [super dealloc];
}

- (void)loadUI {
    if (!O_findPanel) {
        if (![NSBundle loadNibNamed:@"FindReplace" owner:self]) {
            NSLog(@"Failed to load FindReplace.nib");
            NSBeep();
        }
    }
}

- (void)awakeFromNib {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidActivate:) name:NSApplicationDidBecomeActiveNotification object:[NSApplication sharedApplication]];
}

- (NSPanel *)findPanel {
    if (!O_findPanel) {
        [self loadUI];
        [O_findPanel setFloatingPanel:NO];
        [self loadStateFromPreferences];
        [O_findComboBox reloadData];
        [O_replaceComboBox reloadData];
    }
    return O_findPanel;
}

- (NSPanel *)gotoPanel {
    if (!O_findPanel) [self loadUI];
    return O_gotoPanel;
}

- (NSPanel *)tabWidthPanel {
    if (!O_tabWidthPanel) [self loadUI];
    return O_tabWidthPanel;
}

- (NSTextView *)textViewToSearchIn {
    id obj = [[NSApp mainWindow] firstResponder];
    return (obj && [obj isKindOfClass:[NSTextView class]]) ? obj : nil;
}

- (IBAction)orderFrontTabWidthPanel:(id)aSender {
        PlainTextDocument *document=(PlainTextDocument *)[[[[self textViewToSearchIn] window] windowController] document];
    if (document) {
        NSPanel *panel = [self tabWidthPanel];
        [O_tabWidthTextField setIntValue:[document tabWidth]];
        [O_tabWidthTextField selectText:nil];
        [panel makeKeyAndOrderFront:nil];
    }
}

- (BOOL)validateMenuItem:(NSMenuItem *)anItem {
    SEL selector=[anItem action];
    if (selector==@selector(orderFrontTabWidthPanel:) || 
        selector==@selector(orderFrontGotoPanel:)) {
        return [[[[self textViewToSearchIn] window] windowController] document]!=nil;
    }
    return YES;
}

- (IBAction)chooseTabWidth:(id)aSender {
    PlainTextDocument *document=(PlainTextDocument *)[[[[self textViewToSearchIn] window] windowController] document];
    int tabWidth=[O_tabWidthTextField intValue];
    if (tabWidth>0) {
        [document setTabWidth:tabWidth];
        [[self tabWidthPanel] orderOut:self];   
    }
}

- (IBAction)orderFrontGotoPanel:(id)aSender {
    NSPanel *panel = [self gotoPanel];
    [[O_gotoLineTextField cell] setSendsActionOnEndEditing:NO];
    [O_gotoLineTextField selectText:nil];
    [panel makeKeyAndOrderFront:nil];    
    [[O_gotoLineTextField cell] setSendsActionOnEndEditing:YES];
}

- (IBAction)orderFrontFindPanel:(id)aSender {
    NSPanel *panel = [self findPanel];
    [O_findComboBox selectText:nil];
    [panel makeKeyAndOrderFront:nil];
}

- (IBAction)gotoLine:(id)aSender {
    NSTextView *textView = [self textViewToSearchIn];
    [(PlainTextWindowController *)[[textView window] windowController] gotoLine:[O_gotoLineTextField intValue]];

}

- (IBAction)gotoLineAndClosePanel:(id)aSender {
    [self gotoLine:aSender];
    [[self gotoPanel] orderOut:self];   
}


- (IBAction)updateRegexDrawer:(id)aSender
{
    if ([O_regexCheckbox state]==NSOnState) {
        [O_regexDrawer openOnEdge:NSMinYEdge];
    } else {
        [O_regexDrawer close];
    }

}

- (unsigned) currentOgreOptions 
{
    unsigned options = OgreNoneOption;
    if ([O_regexSinglelineCheckbox state]==NSOnState) options |= OgreSingleLineOption;
    if ([O_regexMultilineCheckbox state]==NSOnState) options |= OgreMultilineOption;
    if ([O_ignoreCaseCheckbox state]==NSOnState) options |= OgreIgnoreCaseOption;
    if ([O_regexExtendedCheckbox state]==NSOnState) options |= OgreExtendOption;
    if ([O_regexFindLongestCheckbox state]==NSOnState) options |= OgreFindLongestOption;
    if ([O_regexIgnoreEmptyCheckbox state]==NSOnState) options |= OgreFindNotEmptyOption;
    if ([O_regexNegateSinglelineCheckbox state]==NSOnState) options |= OgreNegateSingleLineOption;
    if ([O_regexDontCaptureCheckbox state]==NSOnState) options |= OgreDontCaptureGroupOption;
    if ([O_regexCaptureGroupsCheckbox state]==NSOnState) options |= OgreCaptureGroupOption;
    return options;
}

- (OgreSyntax) currentOgreSyntax
{
    int syntax = [O_regexSyntaxPopup tag];
    if([O_regexCheckbox state]==NSOffState) return OgreSimpleMatchingSyntax;
    else if(syntax==1) return OgrePOSIXBasicSyntax;
    else if(syntax==2) return OgrePOSIXExtendedSyntax;
    else if(syntax==3) return OgreEmacsSyntax;
    else if(syntax==4) return OgreGrepSyntax;
    else if(syntax==5) return OgreGNURegexSyntax;
    else if(syntax==6) return OgreJavaSyntax;
    else if(syntax==7) return OgrePerlSyntax;
    else return OgreRubySyntax;
}

- (NSString*)currentOgreEscapeCharacter
{
    if ([O_regexEscapeCharacter tag]==1) return OgreGUIYenCharacter;
    else return OgreBackslashCharacter;
}

- (void)performFindPanelAction:(id)sender forTextView:(NSTextView *)aTextView {
    [self performFindPanelAction:sender];
}

- (id)targetToFindIn
{
    id obj = [[NSApp mainWindow] firstResponder];
    return (obj && [obj isKindOfClass:[NSTextView class]]) ? obj : nil;
}

- (void)saveStateToPreferences
{
    NSMutableDictionary *prefs = [NSMutableDictionary dictionary];
    [prefs setObject:[NSNumber numberWithInt:[O_regexSyntaxPopup indexOfSelectedItem]] forKey:@"Syntax"];
    [prefs setObject:[NSNumber numberWithInt:[O_regexEscapeCharacter indexOfSelectedItem]] forKey:@"Escape"];
    [prefs setObject:[NSNumber numberWithInt:[O_scopePopup indexOfSelectedItem]] forKey:@"Scope"];
    
    [prefs setObject:[NSNumber numberWithInt:[O_wrapAroundCheckbox state]] forKey:@"Wrap"];
    [prefs setObject:[NSNumber numberWithInt:[O_regexCheckbox state]] forKey:@"RegEx"];   
    [prefs setObject:[NSNumber numberWithInt:[O_regexSinglelineCheckbox state]] forKey:@"Singleline"];
    [prefs setObject:[NSNumber numberWithInt:[O_regexMultilineCheckbox state]] forKey:@"Multiline"];
    [prefs setObject:[NSNumber numberWithInt:[O_ignoreCaseCheckbox state]] forKey:@"IgnoreCase"];
    [prefs setObject:[NSNumber numberWithInt:[O_regexExtendedCheckbox state]] forKey:@"Extended"];
    [prefs setObject:[NSNumber numberWithInt:[O_regexFindLongestCheckbox state]] forKey:@"FindLongest"];
    [prefs setObject:[NSNumber numberWithInt:[O_regexIgnoreEmptyCheckbox state]] forKey:@"IgnoreEmpty"];
    [prefs setObject:[NSNumber numberWithInt:[O_regexNegateSinglelineCheckbox state]] forKey:@"NegateSingleline"];
    [prefs setObject:[NSNumber numberWithInt:[O_regexDontCaptureCheckbox state]] forKey:@"DontCapture"];
    [prefs setObject:[NSNumber numberWithInt:[O_regexCaptureGroupsCheckbox state]] forKey:@"Capture"];
    if (I_findHistory) {
        [prefs setObject:I_findHistory forKey:@"FindHistory"];
    }
    if (I_replaceHistory) [prefs setObject:I_replaceHistory forKey:@"ReplaceHistory"];
    [[NSUserDefaults standardUserDefaults] setObject:prefs forKey:@"Find Panel Preferences"];
}

- (void)loadStateFromPreferences
{
    NSDictionary *prefs = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"Find Panel Preferences"];
    if (prefs) {
        [O_regexSyntaxPopup selectItemAtIndex:[[prefs objectForKey:@"Syntax"] intValue]];
        [O_regexEscapeCharacter selectItemAtIndex:[[prefs objectForKey:@"Escape"] intValue]];
        [O_scopePopup selectItemAtIndex:[[prefs objectForKey:@"Scope"] intValue]];
    
        [O_wrapAroundCheckbox setState:[[prefs objectForKey:@"Wrap"] intValue]];
        [O_regexCheckbox setState:[[prefs objectForKey:@"RegEx"] intValue]];
        [O_regexSinglelineCheckbox setState:[[prefs objectForKey:@"Singleline"] intValue]];
        [O_regexMultilineCheckbox setState:[[prefs objectForKey:@"Multiline"] intValue]];
        [O_ignoreCaseCheckbox setState:[[prefs objectForKey:@"IgnoreCase"] intValue]];
        [O_regexExtendedCheckbox setState:[[prefs objectForKey:@"Extended"] intValue]];
        [O_regexFindLongestCheckbox setState:[[prefs objectForKey:@"FindLongest"] intValue]];
        [O_regexIgnoreEmptyCheckbox setState:[[prefs objectForKey:@"IgnoreEmpty"] intValue]];
        [O_regexNegateSinglelineCheckbox setState:[[prefs objectForKey:@"NegateSingleline"] intValue]];
        [O_regexDontCaptureCheckbox setState:[[prefs objectForKey:@"DontCapture"] intValue]];
        [O_regexCaptureGroupsCheckbox setState:[[prefs objectForKey:@"Capture"] intValue]];
    }
    if ([prefs objectForKey:@"FindHistory"]) {
        [I_findHistory autorelease];
        I_findHistory = [[prefs objectForKey:@"FindHistory"] mutableCopy];
    }
    if ([prefs objectForKey:@"ReplaceHistory"]) {
        [I_replaceHistory autorelease];
        I_replaceHistory = [[prefs objectForKey:@"ReplaceHistory"] mutableCopy];
    }
}

- (void)performFindPanelAction:(id)sender 
{
    [O_statusTextField setStringValue:@""];
    [O_statusTextField setHidden:YES];
    [O_statusTextField display];
    [O_findPanel display];
    NSString *findString = [O_findComboBox stringValue];
    NSRange scope;
    NSTextView *target = [self targetToFindIn];
    if (target) {
        if ([[O_scopePopup selectedItem] tag]==1) scope = [target selectedRange];
        else scope = NSMakeRange(0, [[target string] length]);
    }
    
    if ([sender tag]==NSFindPanelActionShowFindPanel) {
        [self updateRegexDrawer:self];
        [self orderFrontFindPanel:self];
    } else if ([sender tag]==NSFindPanelActionNext) {
        if (![findString isEqualToString:@""]) [self find:findString forward:YES];
        else NSBeep();
    } else if ([sender tag]==NSFindPanelActionPrevious) {
        if ((![findString isEqualToString:@""])&&(findString)) [self find:findString forward:NO];
        else NSBeep();
    } else if ([sender tag]==NSFindPanelActionReplaceAll) {
        [self replaceAllInRange:scope];
    } else if ([sender tag]==NSFindPanelActionReplace) {
        [self replaceSelection];
    } else if ([sender tag]==NSFindPanelActionReplaceAndFind) {
        [self replaceSelection];
        if (![findString isEqualToString:@""]) [self find:findString forward:YES];
        else NSBeep();
    } else if ([sender tag]==NSFindPanelActionSetFindString) {
        [self findPanel];
        NSTextView *target = [self targetToFindIn];
        if (target) {
            [O_findComboBox setStringValue:[[target string] substringWithRange:[target selectedRange]]];
            [self loadFindStringToPasteboard];
        } else NSBeep();
    } else if ([sender tag]==TCMFindPanelActionFindAll) {
        if ([findString isEqualToString:@""]) {
            NSBeep();
            return;
        }
        if ((![OGRegularExpression isValidExpressionString:findString])&&(![self currentOgreSyntax]==OgreSimpleMatchingSyntax)) {
            [O_statusTextField setStringValue:NSLocalizedString(@"Invalid regex",@"InvalidRegex")];
            [O_statusTextField setHidden:NO];
            NSBeep();
            return;
        }
        NSTextView *target = [self targetToFindIn];
        if (target) {
            [self addString:findString toHistory:I_findHistory];
            OGRegularExpression *regex = [OGRegularExpression regularExpressionWithString:[O_findComboBox stringValue]
                                         options:[self currentOgreOptions]
                                         syntax:[self currentOgreSyntax]
                                         escapeCharacter:[self currentOgreEscapeCharacter]];

            FindAllController *findall = [[[FindAllController alloc] initWithRegex:regex andRange:scope] autorelease];
            [(PlainTextDocument *)[[[target window] windowController] document] addFindAllController:findall];
            if ([self currentOgreSyntax]==OgreSimpleMatchingSyntax) [self loadFindStringToPasteboard];
            [findall findAll:self];
        } else NSBeep();
    }
    
    [self saveStateToPreferences];
}

- (void) replaceSelection
{
    NSTextView *target = [self targetToFindIn];
    if (target) {
        if (![target isEditable]) {
            NSBeep();
            return;
        }
        NSString *findString = [O_findComboBox stringValue];
        NSString *replaceString = [O_replaceComboBox stringValue];
        [self addString:findString toHistory:I_findHistory];
        [self addString:replaceString toHistory:I_replaceHistory];
        NSMutableString *text = [[target textStorage] mutableString];
        NSRange selection = [target selectedRange];
        if (selection.length==0) {
            NSBeep();
            return;
        }
        
        PlainTextDocument *aDocument = (PlainTextDocument *)[[[target window] windowController] document];
        NSDictionary *attributes = [aDocument typingAttributes];
        
        [[aDocument documentUndoManager] beginUndoGrouping];
        [[target textStorage] beginEditing];
        
        if ([self currentOgreSyntax]==OgreSimpleMatchingSyntax) {
            [self loadFindStringToPasteboard];
            [text replaceCharactersInRange:selection withString:replaceString];
            [[target textStorage] addAttributes:attributes range:NSMakeRange(selection.location, [replaceString length])];
        } else {
            // This might not work for lookahead etc.
            OGRegularExpression *regex = [OGRegularExpression regularExpressionWithString:findString
                                            options:[self currentOgreOptions]
                                            syntax:[self currentOgreSyntax]
                                            escapeCharacter:[self currentOgreEscapeCharacter]];
            OGRegularExpressionMatch * aMatch = [regex matchInString:text options:[self currentOgreOptions] range:selection];
            if (aMatch != nil) {
                OGReplaceExpression *repex = [OGReplaceExpression replaceExpressionWithString:replaceString];
                NSRange matchedRange = [aMatch rangeOfMatchedString];
                NSString *replaceWith = [repex replaceMatchedStringOf:aMatch];
                [text replaceCharactersInRange:matchedRange withString:replaceWith];
                [[target textStorage] addAttributes:attributes range:NSMakeRange(matchedRange.location, [replaceWith length])];
            } else NSBeep();
        }
        
        [[target textStorage] endEditing];
        [[aDocument documentUndoManager] endUndoGrouping];
    }
}

- (void) replaceAFewPlainMatches
{
    const int replacePerCycle = 100;
    int i = replacePerCycle;

    [[I_replaceAllTarget textStorage] beginEditing];
    [O_statusTextField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"%d replaced.",@"Number of replaced strings"), I_replaceAllReplaced]];
 
    while (YES) {
        i--;
        if (i<0) break;
        NSRange foundRange = [I_replaceAllText findString:I_replaceAllFindString selectedRange:I_replaceAllPosRange options:I_replaceAllOptions wrap:NO];
        if (foundRange.length) {
            if (foundRange.location < I_replaceAllRange.location) break;
            if (I_replaceAllReplaced==0) [[(PlainTextDocument *)[[[I_replaceAllTarget window] windowController] document] documentUndoManager] beginUndoGrouping];
            [I_replaceAllText replaceCharactersInRange:foundRange withString:I_replaceAllReplaceString];
            [[I_replaceAllTarget textStorage] addAttributes:I_replaceAllAttributes range:NSMakeRange(foundRange.location, [I_replaceAllReplaceString length])];
            I_replaceAllReplaced++;
            I_replaceAllPosRange.location = foundRange.location;
        } else {
            [[I_replaceAllTarget textStorage] endEditing];
            [I_replaceAllFindString release];
            [I_replaceAllReplaceString release];
            [I_replaceAllTarget release];
            [I_replaceAllText release];
            if (I_replaceAllReplaced==0) {
                [O_statusTextField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Not found.",@"Find string not found")]];
                NSBeep();
            } else {
                [[(PlainTextDocument *)[[[I_replaceAllTarget window] windowController] document] documentUndoManager] endUndoGrouping];
            }
            return;
        }
    }
    
    [[I_replaceAllTarget textStorage] endEditing];    
    [self performSelector:@selector(replaceAFewPlainMatches) withObject:nil afterDelay:0.1];
}

- (void) replaceAFewMatches
{
    const int replacePerCycle = 50;
    int i;
    int index = I_replaceAllArrayIndex;

    [[I_replaceAllTarget textStorage] beginEditing];
        
    for (i = index; i >= MAX(index-replacePerCycle,0); i--) {
        OGRegularExpressionMatch *aMatch = [I_replaceAllMatchArray objectAtIndex:i];
        NSRange matchedRange = [aMatch rangeOfMatchedString];
        NSString *replaceWith = [I_replaceAllRepex replaceMatchedStringOf:aMatch];

        if (I_replaceAllReplaced==0) [[(PlainTextDocument *)[[[I_replaceAllTarget window] windowController] document] documentUndoManager] beginUndoGrouping];

        [I_replaceAllText replaceCharactersInRange:matchedRange withString:replaceWith];
        
        NSRange newRange = NSMakeRange(matchedRange.location, [replaceWith length]);
        [[I_replaceAllTarget textStorage] addAttributes:I_replaceAllAttributes range:newRange];
        I_replaceAllReplaced++;
        [O_progressIndicatorDet setDoubleValue:(double)I_replaceAllReplaced];
    }
    
    I_replaceAllArrayIndex = i;
    
    if (I_replaceAllArrayIndex > 0) { // Not ready yet
        [self performSelector:@selector(replaceAFewMatches) withObject:nil afterDelay:0.1];
    } else { // Ready.
        [[I_replaceAllTarget textStorage] endEditing];
        [I_replaceAllTarget release];
        [I_replaceAllMatchArray release];
        [I_replaceAllText release];
        [I_replaceAllRepex release];
        [I_replaceAllRegex release];
        if (I_replaceAllReplaced==0) {
            [O_statusTextField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Not found.",@"Find string not found")]];
            NSBeep();
        } else {
            [[(PlainTextDocument *)[[[I_replaceAllTarget window] windowController] document] documentUndoManager] endUndoGrouping];
            [O_statusTextField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"%d replaced.",@"Number of replaced strings"), I_replaceAllReplaced]];
        }
        [O_progressIndicatorDet stopAnimation:nil];
        [O_progressIndicatorDet setHidden:YES];
        [O_progressIndicatorDet display];
        [O_findPanel display];
        [O_statusTextField setHidden:NO];
        return;
    }
    [[I_replaceAllTarget textStorage] endEditing];
}

- (void) replaceAllInRange:(NSRange)aRange
{
    I_replaceAllReplaced = 0;
    NSTextView *target = [self targetToFindIn];
    NSString *findString = [O_findComboBox stringValue];
    NSString *replaceString = [O_replaceComboBox stringValue];
    [self addString:findString toHistory:I_findHistory];
    [self addString:replaceString toHistory:I_replaceHistory];

    if (target) {
        if (![target isEditable]) {
            [O_progressIndicator stopAnimation:nil];
            NSBeep();
            return;
        }
        NSMutableString *text = [[target textStorage] mutableString];
        PlainTextDocument *aDocument = (PlainTextDocument *)[[[target window] windowController] document];
        NSDictionary *attributes = [aDocument typingAttributes];
        
        I_replaceAllAttributes = [attributes retain];
        
        if ([self currentOgreSyntax]==OgreSimpleMatchingSyntax) {
            [self loadFindStringToPasteboard];
            unsigned options = NSLiteralSearch|NSBackwardsSearch;
            if ([O_ignoreCaseCheckbox state]==NSOnState) options |= NSCaseInsensitiveSearch;
            
            I_replaceAllOptions = options;
            I_replaceAllPosRange = NSMakeRange(NSMaxRange(aRange),0);
            I_replaceAllFindString = [findString retain];
            I_replaceAllReplaceString = [replaceString retain];
            I_replaceAllRange = aRange;
            I_replaceAllText = [text retain];
            I_replaceAllTarget = [target retain];
            
            [O_statusTextField setStringValue:@""];
            [O_statusTextField setHidden:NO];
            [self replaceAFewPlainMatches];

        } else {
        
            [O_progressIndicatorDet setIndeterminate:YES];
            [O_progressIndicatorDet setHidden:NO];
            [O_progressIndicatorDet startAnimation:nil];
    
            BOOL findIsValid = [OGRegularExpression isValidExpressionString:findString];
            BOOL replaceIsValid = [OGRegularExpression isValidExpressionString:replaceString];
            
            if ((!findIsValid)||(!replaceIsValid)) {
                [O_progressIndicator stopAnimation:nil];
                if (!findIsValid) {
                    [O_findComboBox selectText:nil];
                    [O_statusTextField setStringValue:NSLocalizedString(@"Invalid regex",@"InvalidRegex")];
                } else {
                    [O_replaceComboBox selectText:nil];
                    [O_statusTextField setStringValue:NSLocalizedString(@"Invalid regex",@"InvalidRegex")];
                }
                [O_statusTextField setHidden:NO];
                [O_progressIndicator stopAnimation:nil];
                [O_progressIndicatorDet setHidden:YES];
                NSBeep();
                return;
            }
                

            OGRegularExpression *regex = [OGRegularExpression regularExpressionWithString:findString
                                     options:[self currentOgreOptions]
                                     syntax:[self currentOgreSyntax]
                                     escapeCharacter:[self currentOgreEscapeCharacter]];
    
            OGReplaceExpression *repex = [OGReplaceExpression replaceExpressionWithString:replaceString];
            
            NSArray *matchArray = [regex allMatchesInString:text options:[self currentOgreOptions] range:aRange];
            
            I_replaceAllRepex = [repex retain];
            I_replaceAllRegex = [regex retain];
            I_replaceAllMatchArray = [matchArray retain];
            I_replaceAllText = [text retain];
            I_replaceAllTarget = [target retain];
            
            int count = [matchArray count];
            I_replaceAllArrayIndex = count - 1;
            [O_progressIndicatorDet setMaxValue:count];
            [O_progressIndicatorDet setMinValue:0];
            [O_progressIndicatorDet setDoubleValue:0];
            [O_progressIndicatorDet setIndeterminate:NO];
            
                        
            [self replaceAFewMatches];
            
        }
    }
}

- (void) findNextAndOrderOut:(id)sender 
{
    // NSComboBox's action sending behavior is very albern.
    // Action does get sent on click, but not on pressing enter in history dropdown...
    NSEvent *currentEvent = [NSApp currentEvent];
    if ([currentEvent type]==NSKeyDown) {
        if([self find:[O_findComboBox stringValue] forward:YES]) [[self findPanel] orderOut:self];
        else [O_findComboBox selectText:nil];
    } else [O_findComboBox selectText:nil];
    [self saveStateToPreferences];
}

- (BOOL) find:(NSString*)findString forward:(BOOL)forward
{
    BOOL found = NO;
    [self addString:findString toHistory:I_findHistory];
    NSAutoreleasePool *findPool = [NSAutoreleasePool new];     
    [O_progressIndicator startAnimation:nil];
        
    if ((![OGRegularExpression isValidExpressionString:findString])&&(![self currentOgreSyntax]==OgreSimpleMatchingSyntax)) {
        [O_progressIndicator stopAnimation:nil];
        [O_statusTextField setStringValue:NSLocalizedString(@"Invalid regex",@"InvalidRegex")];
        [O_statusTextField setHidden:NO];
        NSBeep();
        return NO;
    }
    
    OGRegularExpression *regex;
    regex = [OGRegularExpression regularExpressionWithString:findString
                                 options:[self currentOgreOptions]
                                 syntax:[self currentOgreSyntax]
                                 escapeCharacter:[self currentOgreEscapeCharacter]];

    NSTextView *target = [self targetToFindIn];
    if (target) {
        
        NSString *text = [target string];
        NSRange selection = [target selectedRange];        
        
        OGRegularExpressionMatch *aMatch = nil;
        NSEnumerator *enumerator;
        
        if (forward) {
            if ([self currentOgreSyntax]==OgreSimpleMatchingSyntax) {
                [self loadFindStringToPasteboard];
                unsigned options = NSLiteralSearch;
                if ([O_ignoreCaseCheckbox state]==NSOnState) options |= NSCaseInsensitiveSearch;
                BOOL wrap = ([O_wrapAroundCheckbox state]==NSOnState); 
                NSRange foundRange = [text findString:findString selectedRange:selection options:options wrap:wrap];
                if (foundRange.length) {
                    found = YES;
                    [target setSelectedRange:foundRange];
                    [target scrollRangeToVisible:foundRange];
                    [target display];
                } else {NSBeep();}

            } else {
                enumerator=[regex matchEnumeratorInString:text options:[self currentOgreOptions] range:NSMakeRange(NSMaxRange(selection), [text length] - NSMaxRange(selection))];
                aMatch = [enumerator nextObject];
                if (aMatch != nil) {
                    found = YES;
                    NSRange foundRange = [aMatch rangeOfMatchedString];
                    [target setSelectedRange:foundRange];
                    [target scrollRangeToVisible:foundRange];
                    [target display];
                } else if ([O_wrapAroundCheckbox state] == NSOnState){
                    enumerator = [regex matchEnumeratorInString:text options:[self currentOgreOptions] range:NSMakeRange(0,selection.location)];
                    aMatch = [enumerator nextObject];
                    if (aMatch != nil) {
                        found = YES;
                        NSRange foundRange = [aMatch rangeOfMatchedString];
                        [target setSelectedRange:foundRange];
                        [target scrollRangeToVisible:foundRange];
                        [target display];
                    } else {NSBeep();}
                } else {NSBeep();}
            }
        } else { // backwards
            if ([self currentOgreSyntax]==OgreSimpleMatchingSyntax) {
                // If we are just simple searching, use NSBackwardsSearch because Regex Searching is sloooow backwards.
                [self loadFindStringToPasteboard];
                unsigned options = NSLiteralSearch|NSBackwardsSearch;
                if ([O_ignoreCaseCheckbox state]==NSOnState) options |= NSCaseInsensitiveSearch;
                BOOL wrap = ([O_wrapAroundCheckbox state]==NSOnState); 
                NSRange foundRange = [text findString:findString selectedRange:selection options:options wrap:wrap];
                if (foundRange.length) {
                    found = YES;
                    [target setSelectedRange:foundRange];
                    [target scrollRangeToVisible:foundRange];
                    [target display];
                } else {NSBeep();}
            } else {
                NSArray *matchArray = [regex allMatchesInString:text options:[self currentOgreOptions] range:NSMakeRange(0, selection.location)];
                if ([matchArray count] > 0) aMatch = [matchArray objectAtIndex:([matchArray count] - 1)];
                if (aMatch != nil) {
                    found = YES;
                    NSRange foundRange = [aMatch rangeOfMatchedString];
                    [target setSelectedRange:foundRange];
                    [target scrollRangeToVisible:foundRange];
                    [target display];
                } else if ([O_wrapAroundCheckbox state] == NSOnState){
                    NSArray *matchArray = [regex allMatchesInString:text options:[self currentOgreOptions] range:NSMakeRange(NSMaxRange(selection), [text length] - NSMaxRange(selection))];
                    if ([matchArray count] > 0) aMatch = [matchArray objectAtIndex:([matchArray count] - 1)];
                    if (aMatch != nil) {
                        found = YES;
                        NSRange foundRange = [aMatch rangeOfMatchedString];
                        [target setSelectedRange:foundRange];
                        [target scrollRangeToVisible:foundRange];
                        [target display];
                    } else {NSBeep();}
                } else {NSBeep();}
            }
        }
    } else {
        NSBeep(); // No target
    }
                                 
    [O_progressIndicator stopAnimation:nil];
    if (!found){
        [O_statusTextField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Not found.",@"Find string not found")]];
        [O_statusTextField setHidden:NO];
    }
    [findPool release];
    return found;
}

#pragma mark -
#pragma mark ### Notification handling ###

- (void)applicationDidActivate:(NSNotification *)notification {
    if ([self currentOgreSyntax]==OgreSimpleMatchingSyntax) [self loadFindStringFromPasteboard];
}

- (void)loadFindStringFromPasteboard {
    NSPasteboard *pasteboard = [NSPasteboard pasteboardWithName:NSFindPboard];
    if ([[pasteboard types] containsObject:NSStringPboardType]) {
        NSString *string = [pasteboard stringForType:NSStringPboardType];
        if (string && [string length]) {
            [self findPanel];
            [O_findComboBox setStringValue:string];
        }
    }
}

- (void)loadFindStringToPasteboard {
    NSPasteboard *pasteboard = [NSPasteboard pasteboardWithName:NSFindPboard];
    [pasteboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
    [pasteboard setString:[O_findComboBox stringValue] forType:NSStringPboardType];
}

#pragma mark -
#pragma mark ### NSComboBox data source ###

- (int)numberOfItemsInComboBox:(NSComboBox*)aComboBox
{
	if (aComboBox == O_replaceComboBox) {
		return [I_replaceHistory count];
	}
	return [I_findHistory count];
}

- (id)comboBox:(NSComboBox*)aComboBox objectValueForItemAtIndex:(int)index
{
	if (aComboBox == O_replaceComboBox) {
		return [I_replaceHistory objectAtIndex:index];
	}
	return [I_findHistory objectAtIndex:index];
}

- (unsigned)comboBox:(NSComboBox*)aComboBox indexOfItemWithStringValue:(NSString*)string
{
	if (aComboBox == O_replaceComboBox) {
		return [I_replaceHistory indexOfObject:string];
	}
	return [I_findHistory indexOfObject:string];
}

- (void)addString:(NSString*)aString toHistory:(NSMutableArray *)anArray
{
    if (![anArray containsObject:aString]) [anArray insertObject:aString atIndex:0];
    int count = [anArray count]-1;
    int i;
    for (i=count;i>15;i--) {
        [anArray removeObjectAtIndex:i];
    }
    [O_findComboBox reloadData];
    [O_replaceComboBox reloadData];
}


@end 

@implementation NSString (NSStringTextFinding)

- (NSRange)findString:(NSString *)string selectedRange:(NSRange)selectedRange options:(unsigned)options wrap:(BOOL)wrap {
    BOOL forwards = (options & NSBackwardsSearch) == 0;
    unsigned length = [self length];
    NSRange searchRange, range;

    if (forwards) {
	searchRange.location = NSMaxRange(selectedRange);
	searchRange.length = length - searchRange.location;
	range = [self rangeOfString:string options:options range:searchRange];
        if ((range.length == 0) && wrap) {	/* If not found look at the first part of the string */
	    searchRange.location = 0;
            searchRange.length = selectedRange.location;
            range = [self rangeOfString:string options:options range:searchRange];
        }
    } else {
	searchRange.location = 0;
	searchRange.length = selectedRange.location;
        range = [self rangeOfString:string options:options range:searchRange];
        if ((range.length == 0) && wrap) {
            searchRange.location = NSMaxRange(selectedRange);
            searchRange.length = length - searchRange.location;
            range = [self rangeOfString:string options:options range:searchRange];
        }
    }
    return range;
}    

@end

