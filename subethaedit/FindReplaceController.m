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
#import "PlainTextDocument.h"
#import "PlainTextEditor.h"
#import "TCMMMSession.h"
#import "TextStorage.h"
#import "FindAllController.h"
#import "UndoManager.h"
#import "time.h"
#import "TextOperation.h"

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
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSApplicationDidBecomeActiveNotification object:[NSApplication sharedApplication]];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSApplicationWillResignActiveNotification object:[NSApplication sharedApplication]];
    [I_findHistory dealloc];
    [I_replaceHistory dealloc];
    [super dealloc];
}

- (void)loadUI {
    if (!O_findPanel) {
        if (![NSBundle loadNibNamed:@"FindReplace" owner:self]) {
            NSBeep();
        } else {
			[O_findComboBox setButtonBordered:NO];
			[O_replaceComboBox setButtonBordered:NO];
		}
    }
}

- (void)awakeFromNib {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidActivate:) name:NSApplicationDidBecomeActiveNotification object:[NSApplication sharedApplication]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResign:) name:NSApplicationWillResignActiveNotification object:[NSApplication sharedApplication]];
}

- (NSPanel *)findPanel {
    if (!O_findPanel) {
        [self loadUI];
        [O_findPanel setFloatingPanel:NO];
        [self loadStateFromPreferences];
        [O_findComboBox reloadData];
        [O_replaceComboBox reloadData];
        [O_findPanel setDelegate:self];
        // It seems buttons can't have keyEquivalent with ctrl in it.
        //[O_ReplaceFindButton setKeyEquivalent:@"g"];
        //[O_ReplaceFindButton setKeyEquivalentModifierMask:(NSCommandKeyMask | NSControlKeyMask)];
    }
    return O_findPanel;
}


- (NSPanel *)gotoPanel {
    if (!O_findPanel) [self loadUI];
    return O_gotoPanel;
}

- (NSPopUpButton *)scopePopup {
    if (!O_findPanel) [self loadUI];
    return O_scopePopup;
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
    return [[[[self textViewToSearchIn] window] windowController] document]!=nil;
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
    // This is a workaround from dts to trick the KeyViewLoopValidation on Tiger (atm 10.4.4)
    // Quoting Scott Ritchie (dts) <sritchie@apple.com>:
    
    // The problem occurs because there is a drawer (or toolbar, for that matter) present that does not contain any views that can become key. When AppKit searches the drawer for a potential key view and finds none, it erroneously selects the current key view as the one to tab to.  Thus, tabbing gets stuck.

    //If possible, simply place a control that can gain the input focus in the drawer. This will cause the tabbing problem to go away.

    //If this isn't an option, I submit the following internal method. This will suppress the AppKit logic that attempts to dynamically splice drawers and the toolbar into the window's key loop. You should be fine if you condition its use on a -respondsToSelector: check.
    
    if ([[self findPanel] respondsToSelector:@selector(_setKeyViewRedirectionDisabled:)]) {
        [[self findPanel] _setKeyViewRedirectionDisabled:YES];
    }
    
    //It will be necessary to do this after each time the window is ordered in, since the ordering-in process clears this setting.

    //If in the future you add a potential key view to the drawer, or a toolbar to the window, you should remove this code to allow the tabbing to include those areas again.
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
    if ([O_regexCaptureGroupsCheckbox state]==NSOnState) options |= OgreCaptureGroupOption; else options |= OgreDontCaptureGroupOption;
    return options;
}

- (OgreSyntax) currentOgreSyntax
{
    int syntax = [[O_regexSyntaxPopup selectedItem] tag];
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
    [prefs setObject:[NSNumber numberWithInt:[[O_regexSyntaxPopup selectedItem] tag]] forKey:@"Syntax2"];
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
        if ([prefs objectForKey:@"Syntax2"]) {
            NSMenuItem *item = [[O_regexSyntaxPopup menu] itemWithTag:[[prefs objectForKey:@"Syntax2"] intValue]];
            if (item) [O_regexSyntaxPopup selectItem:item];
        } else {
            if ([prefs objectForKey:@"Syntax"]) {
                NSMenuItem *item = [[O_regexSyntaxPopup menu] itemWithTag:[[prefs objectForKey:@"Syntax"] intValue] + 1];
                if (item) [O_regexSyntaxPopup selectItem:item];
            }
        }

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

- (void)alertForReadonlyDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == NSAlertFirstButtonReturn) {
        NSDictionary *alertContext = (NSDictionary *)contextInfo;
        PlainTextDocument *document = [alertContext objectForKey:@"Document"];
        [document setEditAnyway:YES];
        [self performFindPanelAction:[alertContext objectForKey:@"Sender"]];
    }
}

- (void)alertForEncodingDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    NSDictionary *alertContext = (NSDictionary *)contextInfo;
    PlainTextDocument *document = [alertContext objectForKey:@"Document"];
    if (returnCode == NSAlertThirdButtonReturn) {
        [document setFileEncoding:NSUnicodeStringEncoding];
        [[document documentUndoManager] removeAllActions];
        [self performFindPanelAction:[alertContext objectForKey:@"Sender"]];
    } else if (returnCode == NSAlertSecondButtonReturn) {
        [document setFileEncoding:NSUTF8StringEncoding];
        [[document documentUndoManager] removeAllActions];
        [self performFindPanelAction:[alertContext objectForKey:@"Sender"]];
    }
}

- (void)performFindPanelAction:(id)sender 
{
    [O_statusTextField setStringValue:@""];
    [O_statusTextField setHidden:YES];
    [O_statusTextField display];
    [O_findPanel display];
    NSString *findString = [O_findComboBox stringValue];
    NSRange scope = {NSNotFound, 0};
    NSTextView *target = [self targetToFindIn];
    if (target) {
        if ([[O_scopePopup selectedItem] tag]==1) scope = [target selectedRange];
        else scope = NSMakeRange(0,[[target string] length]);
        
        // Check for replace operation in case it's a read-only file.
        if (([sender tag]==NSFindPanelActionReplace)||([sender tag]==NSFindPanelActionReplaceAndFind)||([sender tag]==NSFindPanelActionReplaceAll)) {
            PlainTextDocument *document = (PlainTextDocument *)[[[target window] windowController] document];
            if (document && ![document isFileWritable] && ![document editAnyway]) {
                // Call sheet
                NSDictionary *contextInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                                            @"EditAnywayAlert", @"Alert",
                                                            sender, @"Sender",
                                                            document, @"Document",
                                                            nil];
        
                NSAlert *alert = [[[NSAlert alloc] init] autorelease];
                [alert setAlertStyle:NSWarningAlertStyle];
                [alert setMessageText:NSLocalizedString(@"Warning", nil)];
                [alert setInformativeText:NSLocalizedString(@"File is read-only", nil)];
                [alert addButtonWithTitle:NSLocalizedString(@"Edit anyway", nil)];
                [alert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
                [[[alert buttons] objectAtIndex:0] setKeyEquivalent:@"\r"];
                [alert beginSheetModalForWindow:[target window]
                                  modalDelegate:self
                                 didEndSelector:@selector(alertForReadonlyDidEnd:returnCode:contextInfo:)
                                    contextInfo:[contextInfo retain]];
                return;
            }
            
            NSString *replacementString = [O_replaceComboBox stringValue];
            if (![replacementString canBeConvertedToEncoding:[document fileEncoding]]) {
                TCMMMSession *session=[document session];
                if ([session isServer] && [session participantCount]<=1) {
                NSDictionary *contextInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                                            @"ShouldPromoteAlert", @"Alert",
                                                            sender, @"Sender",
                                                            document, @"Document",
                                                            target, @"TextView",
                                                            nil];
        
                    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
                    [alert setAlertStyle:NSWarningAlertStyle];
                    [alert setMessageText:NSLocalizedString(@"You are trying to insert characters that cannot be handled by the file's current encoding. Do you want to cancel the change?", nil)];
                    [alert setInformativeText:NSLocalizedString(@"You are no longer restricted by the file's current encoding if you promote to a Unicode encoding.", nil)];
                    [alert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
                    [alert addButtonWithTitle:NSLocalizedString(@"Promote to UTF8", nil)];
                    [alert addButtonWithTitle:NSLocalizedString(@"Promote to Unicode", nil)];
                    [[[alert buttons] objectAtIndex:0] setKeyEquivalent:@"\r"];
                    [alert beginSheetModalForWindow:[target window]
                                      modalDelegate:self
                                     didEndSelector:@selector(alertForEncodingDidEnd:returnCode:contextInfo:)
                                        contextInfo:[contextInfo retain]];
                    return;
                } else {
                    NSBeep();
                }
            }
        }
    }
    
    if ([sender tag]==NSFindPanelActionShowFindPanel) {
        [self orderFrontFindPanel:self];
        [self updateRegexDrawer:self];
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
        if (![findString isEqualToString:@""]) [self find:findString forward:YES ];
        else NSBeep();
    } else if ([sender tag]==NSFindPanelActionSetFindString) {
        [self findPanel];
        NSTextView *target = [self targetToFindIn];
        if (target) {
            [O_findComboBox setStringValue:[[target string] substringWithRange:[target selectedRange]]];
            [self saveFindStringToPasteboard];
        } else NSBeep();
    } else if ([sender tag]==TCMFindPanelSetReplaceString) {
        [self findPanel];
        NSTextView *target = [self targetToFindIn];
        if (target) {
            [O_replaceComboBox setStringValue:[[target string] substringWithRange:[target selectedRange]]];
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

            if ([[O_scopePopup selectedItem] tag]!=1) scope = NSMakeRange (NSNotFound, 0);
            FindAllController *findall = [[[FindAllController alloc] initWithRegex:regex andRange:scope] autorelease];
            [(PlainTextDocument *)[[[target window] windowController] document] addFindAllController:findall];
            if ([self currentOgreSyntax]==OgreSimpleMatchingSyntax) [self saveFindStringToPasteboard];
            [findall findAll:self];
        } else NSBeep();
    }
    
    [self saveStateToPreferences];
}

- (void) replaceSelection
{
    BOOL found = YES;

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
        
        [[aDocument session] pauseProcessing];
        [[target textStorage] beginEditing];
        
        if ([self currentOgreSyntax]==OgreSimpleMatchingSyntax) {
            [[aDocument documentUndoManager] beginUndoGrouping];
            [self saveFindStringToPasteboard];
            [text replaceCharactersInRange:selection withString:replaceString];
            [[target textStorage] addAttributes:attributes range:NSMakeRange(selection.location, [replaceString length])];
            selection.location = selection.location + [replaceString length];
            selection.length = 0;
        } else {
            // This might not work for lookahead etc.
            OGRegularExpression *regex = [OGRegularExpression regularExpressionWithString:findString
                                            options:[self currentOgreOptions]
                                            syntax:[self currentOgreSyntax]
                                            escapeCharacter:[self currentOgreEscapeCharacter]];
            OGRegularExpressionMatch * aMatch = [regex matchInString:text options:[self currentOgreOptions] range:selection];
            if (aMatch != nil) {
                [[aDocument documentUndoManager] beginUndoGrouping];
                OGReplaceExpression *repex = [OGReplaceExpression replaceExpressionWithString:replaceString];
                NSRange matchedRange = [aMatch rangeOfMatchedString];
                NSString *replaceWith = [repex replaceMatchedStringOf:aMatch];
                [text replaceCharactersInRange:matchedRange withString:replaceWith];
                [[target textStorage] addAttributes:attributes range:NSMakeRange(matchedRange.location, [replaceWith length])];
                selection.location = selection.location + [replaceWith length];
                selection.length = 0;
            } else {
                NSBeep();
                found=NO;
            }
        }
        
        [[target textStorage] endEditing];
        if (found) [[aDocument documentUndoManager] endUndoGrouping];
        [[aDocument session] startProcessing];
        
        [target setSelectedRange:selection];
    }
}

- (void) lockDocument:(PlainTextDocument *)aDocument
{
    NSEnumerator *plainTextEditors=[[aDocument plainTextEditors] objectEnumerator];
    PlainTextEditor *editor=nil;
    while ((editor=[plainTextEditors nextObject])) {
        [[editor textView] setEditable:NO];
    }
    
    [O_FindAllButton setEnabled:NO];
    [O_NextButton setEnabled:NO];
    [O_PrevButton setEnabled:NO];
    [O_ReplaceButton setEnabled:NO];
    [O_ReplaceAllButton setEnabled:NO];
    [O_ReplaceFindButton setEnabled:NO];
}

- (void) unlockDocument:(PlainTextDocument *)aDocument
{
    NSEnumerator *plainTextEditors=[[aDocument plainTextEditors] objectEnumerator];
    PlainTextEditor *editor=nil;
    while ((editor=[plainTextEditors nextObject])) {
        [[editor textView] setEditable:YES];
    }

    [O_FindAllButton setEnabled:YES];
    [O_NextButton setEnabled:YES];
    [O_PrevButton setEnabled:YES];
    [O_ReplaceButton setEnabled:YES];
    [O_ReplaceAllButton setEnabled:YES];
    [O_ReplaceFindButton setEnabled:YES];
}

- (void) replaceAFewPlainMatches
{
    const int replacePerCycle = 100;
    int i = replacePerCycle;
    TCMMMTransformator *transformator=[TCMMMTransformator sharedInstance];

    [[I_replaceAllTarget textStorage] beginEditing];
    if (I_replaceAllReplaced>0) 
        [O_statusTextField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"%d replaced.",@"Number of replaced strings"), I_replaceAllReplaced]];
 
    while (YES) {
        i--;
        if (i<0) break;
        
        
        NSRange foundRange = [I_replaceAllText findString:I_replaceAllFindString selectedRange:I_replaceAllPosRange options:I_replaceAllOptions wrap:NO];
        if (foundRange.length) {
            if (foundRange.location < I_replaceAllRange.location) {
                I_replaceAllPosRange = NSMakeRange(0,0);
                break;
            }
            if (I_replaceAllReplaced==0) {
                PlainTextDocument *aDocument = (PlainTextDocument *)[[[I_replaceAllTarget window] windowController] document];
                [[aDocument session] pauseProcessing];
                [self lockDocument:aDocument];
                [[aDocument documentUndoManager] beginUndoGrouping];
            }
            [I_replaceAllText replaceCharactersInRange:foundRange withString:I_replaceAllReplaceString];

            [transformator transformOperation:I_replaceAllSelectionOperation serverOperation:[TextOperation textOperationWithAffectedCharRange:foundRange replacementString:I_replaceAllReplaceString userID:[TCMMMUserManager myUserID]]];

            [[I_replaceAllTarget textStorage] addAttributes:I_replaceAllAttributes range:NSMakeRange(foundRange.location, [I_replaceAllReplaceString length])];
            I_replaceAllReplaced++;
            I_replaceAllPosRange.location = foundRange.location;
        }

        if (!foundRange.length) {
            [[I_replaceAllTarget textStorage] endEditing];
            [I_replaceAllFindString release];
            [I_replaceAllReplaceString release];
            [I_replaceAllTarget release];
            [I_replaceAllText release];
            [I_replaceAllAttributes release];
            
            PlainTextDocument *aDocument = (PlainTextDocument *)[[[I_replaceAllTarget window] windowController] document];
            
            [aDocument selectRange:[I_replaceAllSelectionOperation selectedRange]];
            [I_replaceAllSelectionOperation release];
            
            if (I_replaceAllReplaced==0) {
                if ([[O_scopePopup selectedItem] tag]==1) {
                    [O_statusTextField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Not found in selection.",@"Find string not found in selection")]];
                } else {
                    [O_statusTextField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Not found.",@"Find string not found")]];
                }
                NSBeep();
            } else {
                [O_statusTextField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"%d replaced.",@"Number of replaced strings"), I_replaceAllReplaced]];
                [[aDocument documentUndoManager] endUndoGrouping];
                [[aDocument session] startProcessing];
                [self unlockDocument:aDocument];
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
    TCMMMTransformator *transformator=[TCMMMTransformator sharedInstance];

    [[I_replaceAllTarget textStorage] beginEditing];
        
    for (i = index; i >= MAX(index-replacePerCycle,0); i--) {
        OGRegularExpressionMatch *aMatch = [I_replaceAllMatchArray objectAtIndex:i];
        NSRange matchedRange = [aMatch rangeOfMatchedString];
        NSString *replaceWith = [I_replaceAllRepex replaceMatchedStringOf:aMatch];

        if (I_replaceAllReplaced==0) {
            PlainTextDocument *aDocument = (PlainTextDocument *)[[[I_replaceAllTarget window] windowController] document];
            [[aDocument session] pauseProcessing];
            [self lockDocument:aDocument];
            [[aDocument documentUndoManager] beginUndoGrouping];
        }

        [I_replaceAllText replaceCharactersInRange:matchedRange withString:replaceWith];

        [transformator transformOperation:I_replaceAllSelectionOperation serverOperation:[TextOperation textOperationWithAffectedCharRange:matchedRange replacementString:replaceWith userID:[TCMMMUserManager myUserID]]];

        
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
        [I_replaceAllAttributes release];
        
        PlainTextDocument *aDocument = (PlainTextDocument *)[[[I_replaceAllTarget window] windowController] document];
        
        [aDocument selectRange:[I_replaceAllSelectionOperation selectedRange]];
        [I_replaceAllSelectionOperation release];
        
        if (I_replaceAllReplaced==0) {
            if ([[O_scopePopup selectedItem] tag]==1) {
                [O_statusTextField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Not found in selection.",@"Find string not found in selection")]];
            } else {
                [O_statusTextField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Not found.",@"Find string not found")]];
            }
            NSBeep();
        } else {
            [[aDocument documentUndoManager] endUndoGrouping];
            [self unlockDocument:aDocument];
            [[aDocument session] startProcessing];
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
        if ((![target isEditable])||(aRange.length==0)) {
            [O_progressIndicator stopAnimation:nil];
            NSBeep();
            return;
        }
        NSMutableString *text = [[target textStorage] mutableString];
        PlainTextDocument *aDocument = (PlainTextDocument *)[[[target window] windowController] document];
        NSDictionary *attributes = [aDocument typingAttributes];
        
        I_replaceAllAttributes = [attributes retain];
        
        I_replaceAllSelectionOperation = [SelectionOperation new];
        [I_replaceAllSelectionOperation setSelectedRange:[target selectedRange]];
        
        if ([self currentOgreSyntax]==OgreSimpleMatchingSyntax) {
            [self saveFindStringToPasteboard];
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
    
            
            if (![OGRegularExpression isValidExpressionString:findString]) {
                [O_progressIndicator stopAnimation:nil];
                [O_findComboBox selectText:nil];
                [O_statusTextField setStringValue:NSLocalizedString(@"Invalid regex",@"InvalidRegex")];
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
            
			unsigned ogreoptions = [self currentOgreOptions];
			ogreoptions &= ~OgreFindLongestOption;
            NSArray *matchArray = [regex allMatchesInString:text options:ogreoptions range:aRange];
            
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

- (void)selectAndHighlightRange:(NSRange)aRange inTarget:(id)aTarget {
	[aTarget setSelectedRange:aRange];
	[aTarget scrollRangeToVisible:aRange];
	[aTarget setNeedsDisplay:YES];
	if ([aTarget respondsToSelector:@selector(showFindIndicatorForRange:)]) {
		[aTarget showFindIndicatorForRange:aRange];
	} 
}

- (BOOL) find:(NSString*)findString forward:(BOOL)forward
{
    BOOL found = NO;
    [self addString:findString toHistory:I_findHistory];
    NSAutoreleasePool *findPool = [NSAutoreleasePool new];     
    [O_progressIndicator startAnimation:nil];
    
    // Check for invalid RegEx    
    if ((![OGRegularExpression isValidExpressionString:findString])&&(![self currentOgreSyntax]==OgreSimpleMatchingSyntax)) {
        [O_progressIndicator stopAnimation:nil];
        [O_statusTextField setStringValue:NSLocalizedString(@"Invalid regex",@"InvalidRegex")];
        [O_statusTextField setHidden:NO];
        NSBeep();
        [findPool release];
        return NO;
    }
    
    OGRegularExpression *regex;
    regex = [OGRegularExpression regularExpressionWithString:findString
                                 options:[self currentOgreOptions]
                                 syntax:[self currentOgreSyntax]
                                 escapeCharacter:[self currentOgreEscapeCharacter]];

    NSTextView *target = [self targetToFindIn];
    if (target) {
        NSRange scope = {NSNotFound, 0};
        if ([[O_scopePopup selectedItem] tag]==1) scope = [target selectedRange];
        else scope = NSMakeRange(0,[[target string] length]);

        NSString *text = [target string];
        NSRange selection = [target selectedRange];        
        
        OGRegularExpressionMatch *aMatch = nil;
        NSEnumerator *enumerator;
        
        if (forward) {
            if ([self currentOgreSyntax]==OgreSimpleMatchingSyntax) {
                [self saveFindStringToPasteboard];
                unsigned options = NSLiteralSearch;
                if ([O_ignoreCaseCheckbox state]==NSOnState) options |= NSCaseInsensitiveSearch;
                BOOL wrap = ([O_wrapAroundCheckbox state]==NSOnState); 
                
                NSRange foundRange;
                // Check for scoping, as findString:selectedRange:options:wrap:
                // only makes sense for scope:document.
                if ([[O_scopePopup selectedItem] tag]==1) {
                    foundRange = [text rangeOfString:findString options:options range:scope];
                } else foundRange = [text findString:findString selectedRange:selection options:options wrap:wrap];                
                
                if (foundRange.length) {
                    found = YES;
					[self selectAndHighlightRange:foundRange inTarget:target];
                } else {NSBeep();}

            } else {
                NSRange findRange;
                if ([[O_scopePopup selectedItem] tag]==1) 
                    findRange = scope;
                else 
                    findRange = NSMakeRange(NSMaxRange(selection), [text length] - NSMaxRange(selection));

                enumerator=[regex matchEnumeratorInString:text options:[self currentOgreOptions] range:findRange];
                aMatch = [enumerator nextObject];
                if (aMatch != nil) {
                    found = YES;
                    NSRange foundRange = [aMatch rangeOfMatchedString];
					[self selectAndHighlightRange:foundRange inTarget:target];
                } else if (([O_wrapAroundCheckbox state] == NSOnState)&&([[O_scopePopup selectedItem] tag]!=1)){
                    enumerator = [regex matchEnumeratorInString:text options:[self currentOgreOptions] range:NSMakeRange(0,NSMaxRange(selection))];
                    aMatch = [enumerator nextObject];
                    if (aMatch != nil) {
                        found = YES;
                        NSRange foundRange = [aMatch rangeOfMatchedString];
						[self selectAndHighlightRange:foundRange inTarget:target];
                    } else {NSBeep();}
                } else {NSBeep();}
            }
        } else { // backwards
            if ([self currentOgreSyntax]==OgreSimpleMatchingSyntax) {
                // If we are just simple searching, use NSBackwardsSearch because Regex Searching is sloooow backwards.
                [self saveFindStringToPasteboard];
                unsigned options = NSLiteralSearch|NSBackwardsSearch;
                if ([O_ignoreCaseCheckbox state]==NSOnState) options |= NSCaseInsensitiveSearch;
                BOOL wrap = ([O_wrapAroundCheckbox state]==NSOnState); 

                NSRange foundRange;
                // Check for scoping, as findString:selectedRange:options:wrap:
                // only makes sense for scope:document.
                if ([[O_scopePopup selectedItem] tag]==1) {
                    foundRange = [text rangeOfString:findString options:options range:scope];
                } else foundRange = [text findString:findString selectedRange:selection options:options wrap:wrap];                
                if (foundRange.length) {
                    found = YES;
					[self selectAndHighlightRange:foundRange inTarget:target];
                } else {NSBeep();}
            } else {
                NSRange findRange;
                if ([[O_scopePopup selectedItem] tag]==1) 
                    findRange = scope;
                else 
                    findRange = NSMakeRange(0, selection.location);

                NSArray *matchArray = [regex allMatchesInString:text options:[self currentOgreOptions] range:findRange];
                if ([matchArray count] > 0) aMatch = [matchArray objectAtIndex:([matchArray count] - 1)];
                if (aMatch != nil) {
                    found = YES;
                    NSRange foundRange = [aMatch rangeOfMatchedString];
					[self selectAndHighlightRange:foundRange inTarget:target];
                } else if ([O_wrapAroundCheckbox state] == NSOnState){
                    NSArray *matchArray = [regex allMatchesInString:text options:[self currentOgreOptions] range:NSMakeRange(selection.location, [text length] - selection.location)];
                    if ([matchArray count] > 0) aMatch = [matchArray objectAtIndex:([matchArray count] - 1)];
                    if (aMatch != nil) {
                        found = YES;
                        NSRange foundRange = [aMatch rangeOfMatchedString];
                        [self selectAndHighlightRange:foundRange inTarget:target];
                    } else {NSBeep();}
                } else {NSBeep();}
            }
        }
    } else {
        NSBeep(); // No target
    }
                                 
    [O_progressIndicator stopAnimation:nil];
    if (!found){
        if ([[O_scopePopup selectedItem] tag]==1) {
            [O_statusTextField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Not found in selection.",@"Find string not found in selection")]];
        } else {
            [O_statusTextField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Not found.",@"Find string not found")]];
        }
        [O_statusTextField setHidden:NO];
    }
    [findPool release];
    return found;
}

#pragma mark -
#pragma mark ### Notification handling ###

- (void)applicationDidActivate:(NSNotification *)notification {
    //if ([self currentOgreSyntax]==OgreSimpleMatchingSyntax) 
	[self loadFindStringFromPasteboard];
}

- (void)applicationWillResign:(NSNotification *)notification {
    //if ([self currentOgreSyntax]==OgreSimpleMatchingSyntax) 
	[self saveFindStringToPasteboard];
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

- (void)saveFindStringToPasteboard {
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
            searchRange.length = NSMaxRange(selectedRange);
            range = [self rangeOfString:string options:options range:searchRange];
        }
    } else {
	searchRange.location = 0;
	searchRange.length = selectedRange.location;
        range = [self rangeOfString:string options:options range:searchRange];
        if ((range.length == 0) && wrap) {
            searchRange.location = selectedRange.location;
            searchRange.length = length - searchRange.location;
            range = [self rangeOfString:string options:options range:searchRange];
        }
    }
    return range;
}    

@end

