//
//  PlainTextEditor.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Tue Apr 06 2004.
//  Copyright (c) 2004-2007 TheCodingMonkeys. All rights reserved.
//

#import "FindReplaceController.h"
#import "DocumentController.h"
#import "PlainTextEditor.h"
#import "PlainTextDocument.h"
#import "PlainTextWindowController.h"
#import "LayoutManager.h"
#import "TextView.h"
#import "GutterRulerView.h"
#import "DocumentMode.h"
#import "TCMMMUserManager.h"
#import "TCMMMUser.h"
#import "TCMMMUserSEEAdditions.h"
#import "TCMMMSession.h"
#import "ButtonScrollView.h"
#import "PopUpButton.h"
#import "PopUpButtonCell.h"
#import "RadarScroller.h"
#import "SelectionOperation.h"
#import "UndoManager.h"
#import "BorderedTextField.h"
#import "DocumentModeManager.h"
#import "AppController.h"
#import "InsetTextFieldCell.h"
#import <OgreKit/OgreKit.h>
#import "SyntaxDefinition.h"
#import "SyntaxHighlighter.h"
#import "ScriptTextSelection.h"
#import "NSMenuTCMAdditions.h"
#import "NSMutableAttributedStringSEEAdditions.h"

@interface NSTextView (PrivateAdditions)
- (BOOL)_isUnmarking;
@end

@interface NSMenu (UndefinedStuff)
- (NSMenu *)bottomPart;
@end

@implementation NSMenu (UndefinedStuff)
- (NSMenu *)bottomPart {
    NSMenu *newMenu=[[NSMenu new] autorelease];
    NSArray *items=[self itemArray];
    int count=[items count];
    int index=count-1;
    while (index>=0) {
        if ([[items objectAtIndex:index] isSeparatorItem]) {
            index++; break;
        }
        index--;
    }
    while (index<count) {
        [newMenu addItem:[[[items objectAtIndex:index] copy] autorelease]];
        index++;
    }
    return newMenu;
}
@end


@interface PlainTextEditor (PlainTextEditorPrivateAdditions)
- (void)TCM_updateStatusBar;
- (void)TCM_updateBottomStatusBar;
- (float)pageGuidePositionForColumns:(int)aColumns;
@end

@implementation PlainTextEditor

- (id)initWithWindowControllerTabContext:(PlainTextWindowControllerTabContext *)aWindowControllerTabContext splitButton:(BOOL)aFlag {
    self = [super init];
    if (self) {
        I_windowControllerTabContext = aWindowControllerTabContext;
        I_flags.hasSplitButton = aFlag;
        I_flags.showTopStatusBar = YES;
        I_flags.showBottomStatusBar = YES;
        I_flags.pausedProcessing = NO;
        [self setFollowUserID:nil];
        [NSBundle loadNibNamed:@"PlainTextEditor" owner:self];
        I_storedSelectedRanges = [NSMutableArray new];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:[I_windowControllerTabContext document] name:NSTextViewDidChangeSelectionNotification object:I_textView];
    [[NSNotificationCenter defaultCenter] removeObserver:[I_windowControllerTabContext document] name:NSTextDidChangeNotification object:I_textView];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [I_textView setDelegate:nil];
    [O_editorView setNextResponder:nil];
    [O_editorView release];
    [I_textContainer release];
    [I_radarScroller release];
    [I_followUserID release];
    [I_storedSelectedRanges release];
    [super dealloc];
}

- (void)awakeFromNib {
    PlainTextDocument *document=[self document];
    if (document) {
        [[NSNotificationCenter defaultCenter]
                addObserver:self selector:@selector(defaultParagraphStyleDidChange:)
                name:PlainTextDocumentDefaultParagraphStyleDidChangeNotification object:document];
        [[NSNotificationCenter defaultCenter]
                addObserver:self selector:@selector(userDidChangeSelection:)
                name:PlainTextDocumentUserDidChangeSelectionNotification object:document];
        [[NSNotificationCenter defaultCenter]
                addObserver:self selector:@selector(plainTextDocumentDidChangeEditStatus:)
                name:PlainTextDocumentDidChangeEditStatusNotification object:document];
        [[NSNotificationCenter defaultCenter]
                addObserver:self selector:@selector(plainTextDocumentDidChangeSymbols:)
                name:PlainTextDocumentDidChangeSymbolsNotification object:document];
    [[NSNotificationCenter defaultCenter]
                addObserver:self selector:@selector(plainTextDocumentUserDidChangeSelection:)
                name:PlainTextDocumentUserDidChangeSelectionNotification object:document];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(TCM_updateBottomStatusBar) name:@"AfterEncodingsListChanged" object:nil];


    if (I_flags.hasSplitButton) {
        NSRect scrollviewFrame=[O_scrollView frame];
        [O_scrollView removeFromSuperview];
        O_scrollView = [[ButtonScrollView alloc] initWithFrame:scrollviewFrame];
        [O_scrollView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        [O_editorView addSubview:O_scrollView];
        [O_scrollView release];
    }
    I_radarScroller=[RadarScroller new];
    [O_scrollView setHasVerticalScroller:YES];
    [O_scrollView setVerticalScroller:I_radarScroller];
    NSRect frame;
    frame.origin=NSMakePoint(0.,0.);
    frame.size  =[O_scrollView contentSize];


    LayoutManager *layoutManager=[LayoutManager new];
    if ([layoutManager respondsToSelector:@selector(setNonContiguousLayout:)]) {
        [layoutManager performSelector:@selector(setNonContiguousLayout:) withObject:[NSNumber numberWithBool:YES]];
    }
    if ([NSLayoutManager respondsToSelector:@selector(setNonContiguousLayout:)]) {
        [NSLayoutManager performSelector:@selector(setNonContiguousLayout:) withObject:[NSNumber numberWithBool:YES]];
    }
    [[document textStorage] addLayoutManager:layoutManager];

    I_textContainer =  [[NSTextContainer alloc] initWithContainerSize:NSMakeSize(frame.size.width,FLT_MAX)];

    I_textView=[[TextView alloc] initWithFrame:frame textContainer:I_textContainer];
    [I_textView setHorizontallyResizable:NO];
    [I_textView setVerticallyResizable:YES];
    [I_textView setAutoresizingMask:NSViewWidthSizable];
    [I_textView setMaxSize:NSMakeSize(FLT_MAX, FLT_MAX)];
    [I_textView setSelectable:YES];
    [I_textView setEditable:YES];
    [I_textView setRichText:NO];
    [I_textView setImportsGraphics:NO];
    [I_textView setUsesFontPanel:NO];
    [I_textView setUsesRuler:YES];
    [I_textView setUsesFindPanel:YES];
    [I_textView setAllowsUndo:NO];
    [I_textView setSmartInsertDeleteEnabled:NO];
//	if ([I_textView respondsToSelector:@selector(setAutomaticLinkDetectionEnabled:)]) {
//		[I_textView setAutomaticLinkDetectionEnabled:YES];
//	}

    [I_textView setDelegate:self];
    [I_textContainer setHeightTracksTextView:NO];
    [I_textContainer setWidthTracksTextView:YES];
    [layoutManager addTextContainer:I_textContainer];

    [O_scrollView setVerticalRulerView:[[[GutterRulerView alloc] initWithScrollView:O_scrollView orientation:NSVerticalRuler] autorelease]];
    [O_scrollView setHasVerticalRuler:YES];
    [[O_scrollView verticalRulerView] setRuleThickness:32.];

    [O_scrollView setDocumentView:I_textView];
    [I_textView release];
    [[O_scrollView verticalRulerView] setClientView:I_textView];


    [layoutManager release];

    [I_textView setDefaultParagraphStyle:[document defaultParagraphStyle]];


    [[NSNotificationCenter defaultCenter] addObserver:document selector:@selector(textViewDidChangeSelection:) name:NSTextViewDidChangeSelectionNotification object:I_textView];
    [[NSNotificationCenter defaultCenter] addObserver:document selector:@selector(textDidChange:) name:NSTextDidChangeNotification object:I_textView];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange:) name:PlainTextDocumentDidChangeTextStorageNotification object:document];
    NSView *view=[[NSView alloc] initWithFrame:[O_editorView frame]];
    [view setAutoresizesSubviews:YES];
    [view setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [view addSubview:[O_editorView autorelease]];
    [view setPostsFrameChangedNotifications:YES];
    [I_textView setPostsFrameChangedNotifications:YES];
    [O_editorView setNextResponder:self];
    [self setNextResponder:view];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewFrameDidChange:) name:NSViewFrameDidChangeNotification object:view];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textViewFrameDidChange:) name:NSViewFrameDidChangeNotification object:I_textView];
    O_editorView = view;
    [O_symbolPopUpButton setDelegate:self];

    [self takeSettingsFromDocument];
    [self takeStyleSettingsFromDocument];
    [self setShowsChangeMarks:[document showsChangeMarks]];
    [self setShowsTopStatusBar:[document showsTopStatusBar]];
    [self setShowsBottomStatusBar:[document showsBottomStatusBar]];
    [(BorderedTextField *)O_windowWidthTextField setHasRightBorder:NO];

    DocumentModeMenu *menu=[[DocumentModeMenu new] autorelease];
    [menu configureWithAction:@selector(chooseMode:) alternateDisplay:NO];
    [[O_modePopUpButton cell] setMenu:menu];

    EncodingMenu *fileEncodingsSubmenu = [[EncodingMenu new] autorelease];
    [fileEncodingsSubmenu configureWithAction:@selector(selectEncoding:)];
    [[[fileEncodingsSubmenu itemArray] lastObject] setTarget:self];
    [[[fileEncodingsSubmenu itemArray] lastObject] setAction:@selector(showCustomizeEncodingPanel:)];
    [[O_encodingPopUpButton cell] setMenu:fileEncodingsSubmenu];
    
    NSMenu *lineEndingMenu = [[NSMenu new] autorelease];
    [O_lineEndingPopUpButton setPullsDown:YES];
    // insert title item of pulldown popupbutton
    [lineEndingMenu addItem:[[[NSMenuItem alloc] initWithTitle:@"" action:NULL keyEquivalent:@""] autorelease]];
    NSMenuItem *item=nil;
    SEL chooseLineEndings=@selector(chooseLineEndings:);
    NSEnumerator *formatSubmenuItems=[[[[[NSApp mainMenu] itemWithTag:FormatMenuTag] submenu] itemArray] objectEnumerator];
    while ((item=[formatSubmenuItems nextObject])) {
        if ([item hasSubmenu] && [[[[item submenu] itemArray] objectAtIndex:0] action] == chooseLineEndings) {
            NSEnumerator *interestingItems = [[[item submenu] itemArray] objectEnumerator];
            NSMenuItem *innerItem = nil;
            while ((innerItem = [interestingItems nextObject])) {
                if ([innerItem isSeparatorItem]) {
                    [lineEndingMenu addItem:[NSMenuItem separatorItem]];
                } else {
                    item=[[[NSMenuItem alloc] initWithTitle:[innerItem title] action:[innerItem action] keyEquivalent:@""] autorelease];
                    [item setTarget:[innerItem target]];
                    [item setTag:   [innerItem tag]];
                    [lineEndingMenu addItem:item];
                }
            }
            break;
        }
    }
    [[O_lineEndingPopUpButton cell] setMenu:lineEndingMenu];

    [O_tabStatusPopUpButton setPullsDown:YES];
    NSMenu *tabMenu = [[NSMenu new] autorelease];
    // insert title item of pulldown popupbutton
    [tabMenu addItem:[[[NSMenuItem alloc] initWithTitle:@"" action:NULL keyEquivalent:@""] autorelease]];
    formatSubmenuItems=[[[[[NSApp mainMenu] itemWithTag:FormatMenuTag] submenu] itemArray] objectEnumerator];
    BOOL copyItems = NO;
    while ((item=[formatSubmenuItems nextObject])) {
        if ([item action] == @selector(toggleUsesTabs:)) copyItems = YES;
        if (copyItems) {
            if ([item isSeparatorItem]) {
                [tabMenu addItem:[NSMenuItem separatorItem]];
            } else {
                NSMenuItem *newItem=[tabMenu addItemWithTitle:[item title] action:[item action] keyEquivalent:@""];
                [newItem setTarget:[item target]];
                [newItem setTag:   [item tag]];
                if ([item hasSubmenu]) {
                    [newItem setSubmenu:[[[item submenu] copy] autorelease]];
                }
            }
        }
    }
    [[O_tabStatusPopUpButton cell] setMenu:tabMenu];


    // replace the textfield cell
    NSMutableData *data=[NSMutableData data];
    NSKeyedArchiver *archiver=[[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [archiver setClassName:@"InsetTextFieldCell"
              forClass:[NSTextFieldCell class]];
    [archiver encodeObject:[O_positionTextField cell] forKey:@"MyCell"];
    [archiver finishEncoding];
    [archiver release];
    
    NSKeyedUnarchiver *unarchiver=[[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    [unarchiver setClass:[InsetTextFieldCell class]
                forClassName:@"NSTextFieldCell"];
    [O_positionTextField setCell:[unarchiver decodeObjectForKey:@"MyCell"]];
    [unarchiver finishDecoding];
    [unarchiver release];

    [self TCM_updateStatusBar];
    [self TCM_updateBottomStatusBar];

}

- (void)pushSelectedRanges {
    [I_storedSelectedRanges addObject:[NSValue valueWithRange:[I_textView selectedRange]]];
}
- (void)popSelectedRanges {
    NSValue *value = [I_storedSelectedRanges lastObject];
    if (value) {
        NSRange selectedRange = [value rangeValue];
        [I_textView setSelectedRange:RangeConfinedToRange(selectedRange,NSMakeRange(0,[[I_textView string] length]))];
        [I_storedSelectedRanges removeLastObject];
    } else {
        [I_textView setSelectedRange:NSMakeRange(0,0)];
    }
}


- (void)adjustDisplayOfPageGuide {
    PlainTextDocument *document=[self document];
    if (document) {
        DocumentMode *mode = [document documentMode];
        if ([[mode defaultForKey:DocumentModeShowPageGuidePreferenceKey] boolValue]) {
            [(TextView *)I_textView setPageGuidePosition:[self pageGuidePositionForColumns:[[mode defaultForKey:DocumentModePageGuideWidthPreferenceKey] intValue]]];
        } else {
            [(TextView *)I_textView setPageGuidePosition:0];
        }
    }
}

- (void)takeStyleSettingsFromDocument {
    PlainTextDocument *document=[self document];
    if (document) {
        [[self textView] setBackgroundColor:[document documentBackgroundColor]];
    }
}

- (void)takeSettingsFromDocument {
    PlainTextDocument *document=[self document];
    if (document) {
        [self setShowsInvisibleCharacters:[document showInvisibleCharacters]];
        [self setWrapsLines: [document wrapLines]];
        [self setShowsGutter:[document showsGutter]];
    }
    [self updateSymbolPopUpSorted:NO];
    [self setShowsTopStatusBar:[document showsTopStatusBar]];
    [self TCM_updateStatusBar];
    [self TCM_updateBottomStatusBar];
    [I_textView setEditable:[document isEditable]];
    [I_textView setContinuousSpellCheckingEnabled:[document isContinuousSpellCheckingEnabled]];
    [self adjustDisplayOfPageGuide];
}

#define RIGHTINSET 5.

- (void)TCM_adjustTopStatusBarFrames {
    static float s_initialXPosition=NSNotFound;
    if (s_initialXPosition==NSNotFound) {
        s_initialXPosition=[O_positionTextField frame].origin.x;
    }
    if (I_flags.showTopStatusBar) {
        float symbolWidth=[(PopUpButtonCell *)[O_symbolPopUpButton cell] desiredWidth];
        PlainTextDocument *document=[self document];
        NSRect bounds=[O_topStatusBarView bounds];
        NSRect positionFrame=[O_positionTextField frame];
        BOOL isWaiting=[[self document] isWaiting];
        [O_waitPipeStatusImageView setHidden:!isWaiting];
        [(BorderedTextField *)O_positionTextField setHasLeftBorder:isWaiting];
        positionFrame.origin.x=isWaiting?s_initialXPosition+19.:s_initialXPosition;
        NSPoint position=positionFrame.origin;
        positionFrame.size.width=[[O_positionTextField stringValue]
                        sizeWithAttributes:[NSDictionary dictionaryWithObject:[O_positionTextField font]
                                                                       forKey:NSFontAttributeName]].width+9.;
        [O_positionTextField setFrame:NSIntegralRect(positionFrame)];
        position.x = (float)(int)NSMaxX(positionFrame);
        NSRect newWrittenByFrame=[O_writtenByTextField frame];
        newWrittenByFrame.size.width=[[O_writtenByTextField stringValue]
                                        sizeWithAttributes:[NSDictionary dictionaryWithObject:[O_writtenByTextField font]
                                                                                       forKey:NSFontAttributeName]].width+5.;
        NSRect newPopUpFrame=[O_symbolPopUpButton frame];
        newPopUpFrame.origin.x=position.x;
        if ([[document documentMode] hasSymbols]) {
            newPopUpFrame.size.width=symbolWidth;
            [O_symbolPopUpButton setHidden:NO];
        } else {
            [O_symbolPopUpButton setHidden:YES];
        }
        int remainingWidth=bounds.size.width-position.x-5.-RIGHTINSET;
        if (newWrittenByFrame.size.width + newPopUpFrame.size.width > remainingWidth) {
            if (remainingWidth - newWrittenByFrame.size.width>20.) {
                newPopUpFrame.size.width=remainingWidth - newWrittenByFrame.size.width;
            } else {
                // manage
                unsigned space=(remainingWidth-20.)/2.;
                newPopUpFrame.size.width=space+20.;
                newWrittenByFrame.size.width=space;
            }
        }
        newWrittenByFrame.origin.x = bounds.origin.x+bounds.size.width-RIGHTINSET-newWrittenByFrame.size.width;
        [O_writtenByTextField setFrame:newWrittenByFrame];
        [O_symbolPopUpButton  setFrame:NSIntegralRect(newPopUpFrame)];
        [O_topStatusBarView setNeedsDisplay:YES];
    }
}


- (void)TCM_updateStatusBar {
    if (I_flags.showTopStatusBar) {
        NSRange selection=[I_textView selectedRange];

        // findLine
        TextStorage *textStorage=(TextStorage *)[I_textView textStorage];
        NSString *string=[textStorage positionStringForRange:selection];
        if (selection.location<[textStorage length]) {
            id blockAttribute=[textStorage
                                attribute:BlockeditAttributeName
                                  atIndex:selection.location effectiveRange:nil];
            if (blockAttribute) string=[string stringByAppendingFormat:@" %@",NSLocalizedString(@"[Blockediting]", nil)];
        }
        [O_positionTextField setStringValue:string];

        [O_writtenByTextField setStringValue:@""];

        NSString *followUserID=[self followUserID];
        if (followUserID) {
            NSString *userName=[[[TCMMMUserManager sharedInstance] userForUserID:followUserID] name];
            if (userName) {
                [O_writtenByTextField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Following %@","Status bar text when following"),userName]];
            }
        } else {
            if (selection.location<[textStorage length]) {
                NSRange range;
                NSString *userId=[textStorage attribute:WrittenByUserIDAttributeName atIndex:selection.location
                                    longestEffectiveRange:&range inRange:selection];
                if (!userId && selection.length>range.length) {
                    userId=[[[self document] textStorage] attribute:WrittenByUserIDAttributeName atIndex:NSMaxRange(range)
                                    longestEffectiveRange:&range inRange:selection];
                }
                if (userId) {
                    NSMutableString *string;
                    NSString *userName = nil;
                    if ([userId isEqualToString:[TCMMMUserManager myUserID]]) {
                        userName = NSLocalizedString(@"me", nil);
                    } else {
                        userName = [[[TCMMMUserManager sharedInstance] userForUserID:userId] name];
                        if (!userName) userName = @"";
                    }

                    if (selection.length>range.length) {
                        string = [NSString stringWithFormat:NSLocalizedString(@"Written by %@ et al", nil), userName];
                    } else {
                        string = [NSString stringWithFormat:NSLocalizedString(@"Written by %@", nil), userName];
                    }
                    [O_writtenByTextField setStringValue:string];
                }
            }
        }
        [self TCM_adjustTopStatusBarFrames];
    }
}

- (float)pageGuidePositionForColumns:(int)aColumns {
    NSFont *font=[[self document] fontWithTrait:0];
    float characterWidth=[font widthOfString:@"n"];
    return aColumns * characterWidth + [[I_textView textContainer] lineFragmentPadding]+[I_textView textContainerInset].width;
}

- (NSSize)desiredSizeForColumns:(int)aColumns rows:(int)aRows {
    NSSize result;
    NSFont *font=[[self document] fontWithTrait:0];
    float characterWidth=[font widthOfString:@"n"];
    result.width = characterWidth*aColumns + [[I_textView textContainer] lineFragmentPadding]*2 + [I_textView textContainerInset].width*2 + ([O_editorView bounds].size.width - [[I_textView enclosingScrollView] contentSize].width);
    result.height = [font defaultLineHeightForFont]*aRows +
                    [I_textView textContainerInset].height * 2 +
                    ([O_editorView bounds].size.height - [[I_textView enclosingScrollView] contentSize].height);
    return result;
}

- (int)displayedRows {
    NSFont *font=[[self document] fontWithTrait:0];
    return (int)(([[I_textView enclosingScrollView] contentSize].height-[I_textView textContainerInset].height*2)/[font defaultLineHeightForFont]);
}

- (int)displayedColumns {
    PlainTextDocument *document=[self document];
    NSFont *font=[document fontWithTrait:0];
    float characterWidth=[font widthOfString:@"n"];
    return (int)(([I_textView bounds].size.width-[I_textView textContainerInset].width*2-[[I_textView textContainer] lineFragmentPadding]*2)/characterWidth);
}

- (void)TCM_updateBottomStatusBar {
    if (I_flags.showBottomStatusBar) {
        PlainTextDocument *document=[self document];
        [O_tabStatusPopUpButton setTitle:[NSString stringWithFormat:NSLocalizedString(@"%@ (%d)",@"arrangement of Tab setting and tab width in Bottm Status Bar"),[document usesTabs]?NSLocalizedString(@"TrueTab",@"Bottom status bar text for TrueTab setting"):NSLocalizedString(@"Spaces",@"Bottom status bar text for use Spaces (instead of Tab) setting"),[document tabWidth]]];
        [O_modePopUpButton selectItemAtIndex:[O_modePopUpButton indexOfItemWithTag:[[DocumentModeManager sharedInstance] tagForDocumentModeIdentifier:[[document documentMode] documentModeIdentifier]]]];

        [O_encodingPopUpButton selectItemAtIndex:[O_encodingPopUpButton indexOfItemWithTag:[document fileEncoding]]];

        int charactersPerLine = [self displayedColumns];
        [O_windowWidthTextField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"WindowWidth%d%@",@"WindowWidthArangementString"),charactersPerLine,[O_scrollView hasHorizontalScroller]?@"":([document wrapMode]==DocumentModeWrapModeCharacters?NSLocalizedString(@"CharacterWrap",@"As shown in bottom status bar"):NSLocalizedString(@"WordWrap",@"As shown in bottom status bar"))]];

        [O_lineEndingPopUpButton selectItemAtIndex:[O_lineEndingPopUpButton indexOfItemWithTag:[document lineEnding]]];
        NSString *lineEndingStatusString=@"";
        switch ([document lineEnding]) {
            case LineEndingLF:
                lineEndingStatusString=@"LF";
                break;
            case LineEndingCR:
                lineEndingStatusString=@"CR";
                break;
            case LineEndingCRLF:
                lineEndingStatusString=@"CRLF";
                break;
            case LineEndingUnicodeLineSeparator:
                lineEndingStatusString=@"LSEP";
                break;
            case LineEndingUnicodeParagraphSeparator:
                lineEndingStatusString=@"PSEP";
                break;
        }
        [O_lineEndingPopUpButton setTitle:lineEndingStatusString];
     }
}

- (NSView *)editorView {
    return O_editorView;
}

- (NSTextView *)textView {
    return I_textView;
}

- (PlainTextDocument *)document {
    return (PlainTextDocument *)[I_windowControllerTabContext document];
}

- (void)setWindowControllerTabContext:(PlainTextWindowControllerTabContext *)aContext {
    I_windowControllerTabContext = aContext;
}

- (void)setIsSplit:(BOOL)aFlag {
    if (I_flags.hasSplitButton) {
        [[(ButtonScrollView *)O_scrollView button] setState:aFlag?NSOnState:NSOffState];
    }
}

- (int)dentLineInTextView:(NSTextView *)aTextView withRange:(NSRange)aLineRange in:(BOOL)aIndent{
    int changedChars=0;
    static NSCharacterSet *spaceTabSet=nil;
    if (!spaceTabSet) {
        spaceTabSet=[NSCharacterSet whitespaceCharacterSet];
    }
    NSRange affectedCharRange=NSMakeRange(aLineRange.location,0);
    NSString *replacementString=@"";
    NSTextStorage *textStorage=[aTextView textStorage];
    NSString *string=[textStorage string];
    int tabWidth=[[self document] tabWidth];
    if ([[self document] usesTabs]) {
         if (aIndent) {
            // replace spaces with tabs and add one tab
            unsigned lastCharacter=aLineRange.location;
            while (lastCharacter<NSMaxRange(aLineRange) && 
                   [spaceTabSet characterIsMember:[string characterAtIndex:lastCharacter]]) {
                lastCharacter++;
            }
            if (aLineRange.location!=lastCharacter && lastCharacter<NSMaxRange(aLineRange)) {
                affectedCharRange=NSMakeRange(aLineRange.location,lastCharacter-aLineRange.location);
                unsigned detabbedLength=[string detabbedLengthForRange:affectedCharRange 
                                                tabWidth:tabWidth];
                
                replacementString=[NSString stringWithFormat:@"\t%@%@",
                                  [@"" stringByPaddingToLength:(int)detabbedLength/tabWidth
                                       withString:@"\t" startingAtIndex:0],
                                  [@"" stringByPaddingToLength:(int)detabbedLength%tabWidth
                                       withString:@" " startingAtIndex:0]
                                  ];
                if (affectedCharRange.length!=[replacementString length]-1) {
                    changedChars=[replacementString length]-affectedCharRange.length;
                } else {
                    affectedCharRange=NSMakeRange(aLineRange.location,0);
                    replacementString=@"\t";
                    changedChars=1;
                }
            } else {
                replacementString=@"\t";
                changedChars=1;
            }
        } else {
            if ([string length]>aLineRange.location) {
                // replace spaces with tabs and remove one tab or the remaining whitespace
                unsigned lastCharacter=aLineRange.location;
                while (lastCharacter<NSMaxRange(aLineRange) && 
                       [spaceTabSet characterIsMember:[string characterAtIndex:lastCharacter]]) {
                    lastCharacter++;
                }
                affectedCharRange=NSMakeRange(aLineRange.location,lastCharacter-aLineRange.location);
                if (aLineRange.location!=lastCharacter && lastCharacter<NSMaxRange(aLineRange)) {
                    affectedCharRange=NSMakeRange(aLineRange.location,lastCharacter-aLineRange.location);
                    unsigned detabbedLength=[string detabbedLengthForRange:affectedCharRange 
                                                    tabWidth:tabWidth];
                    
                    replacementString=[NSString stringWithFormat:@"%@%@",
                                      [@"" stringByPaddingToLength:(int)detabbedLength/tabWidth
                                           withString:@"\t" startingAtIndex:0],
                                      [@"" stringByPaddingToLength:(int)detabbedLength%tabWidth
                                           withString:@" " startingAtIndex:0]
                                      ];
                    if ([replacementString length]!=affectedCharRange.length || 
                        ((int)detabbedLength/tabWidth)==0 ) {
                        if ((int)detabbedLength/tabWidth > 0) {
                            replacementString=[replacementString substringWithRange:NSMakeRange(1,[replacementString length]-1)];
                        } else {
                            replacementString=@"";
                        }
                        changedChars=[replacementString length]-affectedCharRange.length;
                    } else {
                        // this if is always true due to the ifs above
                        // if ([string characterAtIndex:aLineRange.location]==[@"\t" characterAtIndex:0]) {
                            affectedCharRange=NSMakeRange(aLineRange.location,1);
                            changedChars=-1;
                            replacementString=@"";
                        // }
                    }
                } else {
                    changedChars=[replacementString length]-affectedCharRange.length;
                }
            }
        }
    } else {
        unsigned firstCharacter=aLineRange.location;
        // replace tabs with spaces
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
            if ([aTextView shouldChangeTextInRange:affectedRange
                                 replacementString:replacementString]) {
                NSAttributedString *attributedReplaceString=[[NSAttributedString alloc]
                                                                initWithString:replacementString
                                                                    attributes:[aTextView typingAttributes]];

                [textStorage replaceCharactersInRange:affectedRange
                                  withAttributedString:attributedReplaceString];
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
    NSRange newRange=NSMakeRange(affectedCharRange.location,[replacementString length]);
    if (affectedCharRange.length>0 || newRange.length>0) {
        if ([aTextView  shouldChangeTextInRange:affectedCharRange
                              replacementString:replacementString]) {
            [textStorage replaceCharactersInRange:affectedCharRange
                                       withString:replacementString];
            if (newRange.length>0) {
//                [textStorage addAttribute:NSParagraphStyleAttributeName value:[aTextView defaultParagraphStyle] range:newRange];
                [textStorage addAttributes:[aTextView typingAttributes] range:newRange];
            }
        }
    }
    return changedChars;
}

- (void)dentParagraphsInTextView:(NSTextView *)aTextView in:(BOOL)aIndent{
    if ([(TextStorage *)[aTextView textStorage] hasBlockeditRanges]) {
        NSBeep();
    } else {

        NSRange affectedRange=[aTextView selectedRange];
        [aTextView setSelectedRange:NSMakeRange(affectedRange.location,0)];
        NSRange lineRange;
        UndoManager *undoManager=[[self document] documentUndoManager];
        NSTextStorage *textStorage=[aTextView textStorage];
        NSString *string=[textStorage string];

        [undoManager beginUndoGrouping];
        if (affectedRange.length==0) {
            [textStorage beginEditing];
            lineRange=[string lineRangeForRange:affectedRange];
            int lengthChange=[self dentLineInTextView:aTextView withRange:lineRange in:aIndent];
            [textStorage endEditing];
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
            [textStorage beginEditing];
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
            [textStorage endEditing];
            [aTextView didChangeText];

            if (affectedRange.location<0 || NSMaxRange(affectedRange)>[textStorage length]) {
                if (affectedRange.length>0) {
                    affectedRange=NSIntersectionRange(affectedRange,NSMakeRange(0,[textStorage length]));
                } else {
                    if (affectedRange.location<0) {
                        affectedRange.location=0;
                    } else {
                        affectedRange.location=[textStorage length];
                    }
                }
            }
            [aTextView setSelectedRange:affectedRange];
        }
        [undoManager endUndoGrouping];
    }
}

- (void)tabParagraphsInTextView:(NSTextView *)aTextView de:(BOOL)shouldDetab {
    if ([(TextStorage *)[aTextView textStorage] hasBlockeditRanges]) {
        NSBeep();
    } else {
        NSRange affectedRange=[aTextView selectedRange];
        [aTextView setSelectedRange:NSMakeRange(affectedRange.location,0)];

        UndoManager *undoManager=[[self document] documentUndoManager];
        NSTextStorage *textStorage=[aTextView textStorage];
        NSString *string=[textStorage string];

        [undoManager beginUndoGrouping];
        if (affectedRange.length==0) {
            affectedRange = NSMakeRange(0,[textStorage length]);
        }
        affectedRange=[string lineRangeForRange:affectedRange];

        affectedRange=[textStorage detab:shouldDetab inRange:affectedRange 
                                   tabWidth:[[self document] tabWidth] askingTextView:aTextView];

        [aTextView setSelectedRange:affectedRange];

        [undoManager endUndoGrouping];
    }
}

- (void)updateViews
{
    [self TCM_adjustTopStatusBarFrames];
    [self TCM_updateBottomStatusBar];
}

#pragma mark -
#pragma mark First Responder Actions

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    SEL selector = [menuItem action];

    if (selector == @selector(toggleWrap:)) {
        [menuItem setState:[O_scrollView hasHorizontalScroller]?NSOffState:NSOnState];
        return YES;
    } else if (selector == @selector(toggleTopStatusBar:)) {
        [menuItem setState:[self showsTopStatusBar]?NSOnState:NSOffState];
        return YES;
    } else if (selector == @selector(toggleShowsChangeMarks:)) {
        BOOL showsChangeMarks=[self showsChangeMarks];
        [menuItem setState:showsChangeMarks?NSOnState:NSOffState];
        return YES;
    } else if (selector == @selector(toggleShowInvisibles:)) {
        [menuItem setState:[self showsInvisibleCharacters]?NSOnState:NSOffState];
        return YES;
    } else if (selector == @selector(blockeditSelection:) || selector==@selector(endBlockedit:)) {
        TextStorage *textStorage=(TextStorage *)[I_textView textStorage];
        if ([textStorage hasBlockeditRanges]) {
            [menuItem setTitle:NSLocalizedString(@"MenuBlockeditEnd",@"End Blockedit in edit Menu")];
            [menuItem setKeyEquivalent:@"\e"];
            [menuItem setAction:@selector(endBlockedit:)];
            [menuItem setKeyEquivalentModifierMask:0];
            return YES;
        }
        [menuItem setTitle:NSLocalizedString(@"MenuBlockeditSelection",@"Blockedit Selection in edit Menu")];
        [menuItem setKeyEquivalent:@"B"];
        [menuItem setAction:@selector(blockeditSelection:)];
        [menuItem setKeyEquivalentModifierMask:NSCommandKeyMask|NSShiftKeyMask];
        return YES;
    } else if (selector==@selector(copyAsXHTML:)) {
        return ([I_textView selectedRange].length>0);
    }
    return YES;
}

/*" Copies the current selection as XHTML to the pasteboard
    font is added, background and foreground color is used
    - if wrapping is off: <pre> is used
                     on: leading whitespace is fixed via &nbsp;, <br /> is added for line break
    - if colorize syntax is on: <span style="color: ...;">, <strong> and <em> are used to style the text
    - if Show Changes is on: background is colored according to user color, <a title="name"> tags are added
    TODO: detab before exporting
"*/

- (IBAction)copyAsXHTML:(id)aSender {
    static NSDictionary *baseAttributeMapping;
    static NSDictionary *writtenByAttributeMapping;
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
                            nil];
        [baseAttributeMapping retain];
        writtenByAttributeMapping=[NSDictionary dictionaryWithObjectsAndKeys:
                            [NSDictionary dictionaryWithObjectsAndKeys:
                                @"<span style=\"background-color:%@;\">",@"openTag",
                                @"</span>",@"closeTag",nil], @"BackgroundColor",
                            [NSDictionary dictionaryWithObjectsAndKeys:
                                @"<a title=\"%@\">",@"openTag",
                                @"</a>",@"closeTag",nil], @"WrittenBy",
                            nil];
        [writtenByAttributeMapping retain];

    }
    NSRange selectedRange=[I_textView selectedRange];
    if (selectedRange.location!=NSNotFound && selectedRange.length>0) {
        NSMutableDictionary *mapping=[[baseAttributeMapping mutableCopy] autorelease];
        if ([self showsChangeMarks]) {
            [mapping addEntriesFromDictionary:writtenByAttributeMapping];
        }
        PlainTextDocument *document=[self document];
        NSColor *backgroundColor=[document documentBackgroundColor];
        NSColor *foregroundColor=[document documentForegroundColor]; 
        TextStorage *textStorage=(TextStorage *)[I_textView textStorage];
        NSMutableAttributedString *attributedStringForXHTML=[textStorage attributedStringForXHTMLExportWithRange:selectedRange foregroundColor:foregroundColor backgroundColor:backgroundColor];
        [attributedStringForXHTML detab:YES inRange:NSMakeRange(0,[attributedStringForXHTML length]) tabWidth:[document tabWidth] askingTextView:nil];
        if ([self wrapsLines]) {
            [attributedStringForXHTML makeLeadingWhitespaceNonBreaking]; 
        }
        selectedRange.location=0;
        
        NSString *fontString=@"";
        if ([[[self document] fontWithTrait:0] isFixedPitch] || 
            [@"Monaco" isEqualToString:[[[self document] fontWithTrait:0] fontName]]) {
            fontString=@"font-size:small; font-family:monospace; ";
        } 
        
        // pre or div?
        NSString *topLevelTag=([self wrapsLines]?@"div":@"pre");
        
        NSMutableString *result=[[NSMutableString alloc] initWithCapacity:selectedRange.length*2];
        [result appendFormat:@"<%@ style=\"text-align:left;color:%@; background-color:%@; border:solid black 1px; padding:0.5em 1em 0.5em 1em; overflow:auto;%@\">",topLevelTag, [foregroundColor HTMLString],[backgroundColor HTMLString],fontString];
        NSMutableString *content=[attributedStringForXHTML XHTMLStringWithAttributeMapping:mapping forUTF8:NO];
        if ([self wrapsLines]) {
            [content addBRs];
        }
        [result appendString:content];
        [result appendFormat:@"</%@>",topLevelTag];
        [[NSPasteboard generalPasteboard] declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
        [[NSPasteboard generalPasteboard] setString:result forType:NSStringPboardType];
        [result release];
    } else {
        NSBeep();
    }
}


//- (IBAction)copyAsXHTML:(id)aSender {
//    NSRange selectedRange=[I_textView selectedRange];
//    if (selectedRange.location!=NSNotFound && selectedRange.length>0) {
//        PlainTextDocument *document=[self document];
//        NSColor *backgroundColor=[document documentBackgroundColor];
//        NSColor *foregroundColor=[document documentForegroundColor]; 
//        TextStorage *textStorage=(TextStorage *)[I_textView textStorage];
//        NSAttributedString *attributedStringForXHTML=[textStorage attributedStringForXHTMLExportWithRange:selectedRange foregroundColor:foregroundColor];
//        selectedRange.location=0;
//        
//        NSRange foundRange;
//        NSMutableString *result=[[NSMutableString alloc] initWithCapacity:selectedRange.length*2];
//        [result appendFormat:@"<pre style=\"color:%@; background-color:%@; border: solid black 1px; padding: 0.5em 1em 0.5em 1em; overflow:auto;\">",[foregroundColor HTMLString],[backgroundColor HTMLString]];
//        NSDictionary *attributes=nil;
//        unsigned int index=selectedRange.location;
//        do {
//            NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];
//            attributes=[attributedStringForXHTML attributesAtIndex:index
//                    longestEffectiveRange:&foundRange inRange:selectedRange];
//            index=NSMaxRange(foundRange);
//            NSString *contentString=[[[attributedStringForXHTML string] substringWithRange:foundRange] stringByReplacingEntities];
//            NSMutableString *styleString=[NSMutableString string];
//            if (attributes) {
//                NSString *htmlColor=[attributes objectForKey:@"ForegroundColor"];
//                if (htmlColor) {
//                    [styleString appendFormat:@"color:%@;",htmlColor];
//                }
//                NSNumber *traitMask=[attributes objectForKey:@"FontTraits"];
//                if (traitMask) {
//                    unsigned traits=[traitMask unsignedIntValue];
//                    if (traits & NSBoldFontMask) {
//                        [styleString appendString:@"font-weight:bold;"];
//                    }
//                    if (traits & NSItalicFontMask) {
//                        [styleString appendString:@"font-style:oblique;"];
//                    }
//                }
//                if ([styleString length]>0) {
//                    [result appendFormat:@"<span style=\"%@\">",styleString];
//                }
//            }
//            [result appendString:contentString];
//            if (attributes && [styleString length]>0) {
//                [result appendString:@"</span>"];
//            }
//
//            index=NSMaxRange(foundRange);
//            [pool release];
//        } while (index<NSMaxRange(selectedRange));
//        [result appendString:@"</pre>"];
//        [[NSPasteboard generalPasteboard] declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
//        [[NSPasteboard generalPasteboard] setString:result forType:NSStringPboardType];
//        [result release];
//    } else {
//        NSBeep();
//    }
//}

- (IBAction)blockeditSelection:(id)aSender {
    NSRange selection=[I_textView selectedRange];
    TextStorage *textStorage=(TextStorage *)[I_textView textStorage];
    NSRange lineRange=[[textStorage string] lineRangeForRange:selection];
    NSDictionary *blockeditAttributes=[[I_textView delegate] blockeditAttributesForTextView:I_textView];
    [textStorage addAttributes:blockeditAttributes
                 range:lineRange];
    [I_textView setSelectedRange:NSMakeRange(selection.location,0)];
    [textStorage setHasBlockeditRanges:YES];
}

- (IBAction)endBlockedit:(id)aSender {
    TextStorage *textStorage=(TextStorage *)[I_textView textStorage];
    if ([textStorage hasBlockeditRanges]) {
        [textStorage stopBlockedit];
    }
}

- (void)setShowsChangeMarks:(BOOL)aFlag {
    LayoutManager *layoutManager =(LayoutManager *)[I_textView layoutManager];
    if ([layoutManager showsChangeMarks]!=aFlag) {
        [layoutManager setShowsChangeMarks:aFlag];
        [[self document] setShowsChangeMarks:aFlag];
    }
}

- (BOOL)showsChangeMarks {
    return [(LayoutManager *)[I_textView layoutManager] showsChangeMarks];
}

- (void)setShowsInvisibleCharacters:(BOOL)aFlag {
    LayoutManager *layoutManager = (LayoutManager *)[I_textView layoutManager];
    [layoutManager   setShowsInvisibles:aFlag];
    [[self document] setShowInvisibleCharacters:aFlag];
    [I_textView setNeedsDisplay:YES];
}

- (BOOL)showsInvisibleCharacters {
    return [(LayoutManager *)[I_textView layoutManager] showsInvisibles];
}

- (IBAction)toggleShowInvisibles:(id)aSender {
    [self setShowsInvisibleCharacters:![self showsInvisibleCharacters]];
}

- (void)setWrapsLines:(BOOL)aFlag {
    if (aFlag!=[self wrapsLines]) {
        [self toggleWrap:self];
    }
}

- (BOOL)wrapsLines {
    return ![O_scrollView hasHorizontalScroller];
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
        // this needs to be done if no text flows over the text view margins (SEE-364)
        [I_textContainer setContainerSize:NSMakeSize(NSWidth([I_textView frame])-2.0*[I_textView textContainerInset].width,FLT_MAX)];
        [I_textView setNeedsDisplay:YES];
    }
    [[self document] setWrapLines:[self wrapsLines]];
    [self TCM_updateBottomStatusBar];
}

- (IBAction)positionClick:(id)aSender {
    if (([[NSApp currentEvent] type] == NSLeftMouseDown || 
         [[NSApp currentEvent] type] == NSLeftMouseUp)) {
        if ([[NSApp currentEvent] clickCount] == 1) {
            [I_textView doCommandBySelector:@selector(centerSelectionInVisibleArea:)];
        } else if ([[NSApp currentEvent] clickCount] > 1) {
            [[FindReplaceController sharedInstance] orderFrontGotoPanel:self];
        }
    }
}

- (BOOL)showsGutter {
    return [O_scrollView rulersVisible];
}

- (void)setShowsGutter:(BOOL)aFlag {
    [O_scrollView setRulersVisible:aFlag];
    [self TCM_updateBottomStatusBar];
}

#define STATUSBARSIZE 17.

- (BOOL)showsTopStatusBar {
    return I_flags.showTopStatusBar;
}

- (void)setShowsTopStatusBar:(BOOL)aFlag {
    if (I_flags.showTopStatusBar!=aFlag) {
        I_flags.showTopStatusBar=!I_flags.showTopStatusBar;
        NSRect frame=[O_scrollView frame];
        if (!I_flags.showTopStatusBar) {
            frame.size.height+=STATUSBARSIZE;
        } else {
            frame.size.height-=STATUSBARSIZE;
            [O_editorView setNeedsDisplayInRect:NSMakeRect(frame.origin.x,NSMaxY(frame),frame.size.width,STATUSBARSIZE)];
            [self TCM_updateStatusBar];
        }
        [O_scrollView setFrame:frame];
        [O_topStatusBarView setHidden:!I_flags.showTopStatusBar];
        [O_topStatusBarView setNeedsDisplay:YES];
        [[self document] setShowsTopStatusBar:aFlag];
    }
}

- (BOOL)showsBottomStatusBar {
    return I_flags.showBottomStatusBar;
}

- (void)setShowsBottomStatusBar:(BOOL)aFlag {
    if (I_flags.showBottomStatusBar!=aFlag) {
        I_flags.showBottomStatusBar=!I_flags.showBottomStatusBar;
        NSRect frame=[O_scrollView frame];
        if (!I_flags.showBottomStatusBar) {
            frame.size.height+=STATUSBARSIZE;
            frame.origin.y   -=STATUSBARSIZE;
        } else {
            frame.size.height-=STATUSBARSIZE;
            frame.origin.y   +=STATUSBARSIZE;
            [O_editorView setNeedsDisplayInRect:NSMakeRect(frame.origin.x,frame.origin.y-STATUSBARSIZE,frame.size.width,STATUSBARSIZE)];
            [self TCM_updateBottomStatusBar];
        }
        [O_scrollView setFrame:frame];
        [O_bottomStatusBarView setHidden:!I_flags.showBottomStatusBar];
        [O_bottomStatusBarView setNeedsDisplay:YES];
    }
}

- (void)setFollowUserID:(NSString *)userID {
    if (!(I_followUserID==nil && userID==nil)) {
        [I_followUserID autorelease];
        I_followUserID = [userID copy];
        [self scrollToUserWithID:userID];
        [self TCM_updateStatusBar];
        id windowController = [[O_editorView window] windowController];
        if ([windowController respondsToSelector:@selector(validateButtons)]) {
            [windowController performSelector:@selector(validateButtons)];
        }
    }
}

- (NSString *)followUserID {
    return I_followUserID;
}

- (IBAction)toggleShowsChangeMarks:(id)aSender {
    [self setShowsChangeMarks:![self showsChangeMarks]];
}

- (IBAction)toggleTopStatusBar:(id)aSender {
    [self setShowsTopStatusBar:![self showsTopStatusBar]];
}

- (IBAction)shiftRight:(id)aSender {
    [self dentParagraphsInTextView:I_textView in:YES];
}

- (IBAction)shiftLeft:(id)aSender {
    [self dentParagraphsInTextView:I_textView in:NO];
}

- (IBAction)detab:(id)aSender {
    [self tabParagraphsInTextView:I_textView de:YES];
}

- (IBAction)entab:(id)aSender {
    [self tabParagraphsInTextView:I_textView de:NO];
}

- (IBAction)jumpToNextChange:(id)aSender {
    TextView *textView = (TextView *)[self textView];
    unsigned maxrange=NSMaxRange([textView selectedRange]);
    NSRange change = [[self document] rangeOfPrevious:NO
                                       changeForRange:NSMakeRange(maxrange>0?maxrange-1:maxrange,0)];
    if (change.location == NSNotFound) {
        NSBeep();
    } else {
        [textView setSelectedRange:change];
        [textView scrollRangeToVisible:change];
    }
}

- (IBAction)jumpToPreviousChange:(id)aSender {
    TextView *textView = (TextView *)[self textView];
    NSRange change = [[self document] rangeOfPrevious:YES
                                       changeForRange:NSMakeRange([textView selectedRange].location,0)];
    if (change.location == NSNotFound) {
        NSBeep();
    } else {
        [textView setSelectedRange:change];
        [textView scrollRangeToVisible:change];
    }
}

- (void)keyDown:(NSEvent *)aEvent {
//    NSLog(@"aEvent: %@",[aEvent description]);
    int flags=[aEvent modifierFlags];
    if ((flags & NSControlKeyMask) && 
        !(flags & NSCommandKeyMask) && 
        [[aEvent characters] length]==1) {
        NSString *characters = [aEvent characters];
        if ([characters isEqualToString:@"2"] &&
            [self showsTopStatusBar] &&
            ![O_symbolPopUpButton isHidden]) {
            [O_symbolPopUpButton performClick:self];
            return;
        } else if ([characters isEqualToString:@"1"]) {
            static NSPopUpButtonCell *s_cell = nil;
            if (!s_cell) {
                s_cell = [NSPopUpButtonCell new];
                [s_cell setControlSize:NSSmallControlSize];
                [s_cell setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSSmallControlSize]]];
            }
            [s_cell setMenu:[[DocumentController sharedInstance] documentMenu]];
            NSEnumerator *menuItems = [[[s_cell menu] itemArray] objectEnumerator];
            NSMenuItem   *menuItem  = nil;
            while ((menuItem=[menuItems nextObject])) {
                if ([menuItem target]==[[I_textView window] windowController] && [menuItem representedObject]==[self document]) {
                    [s_cell selectItem:menuItem];
                    break;
                }
            }
            NSRect frame = [O_editorView frame];
            frame.size.width = 50;
            frame.origin.y = frame.size.height-20;
            frame.size.height = 20;
            [s_cell performClickWithFrame:frame inView:O_editorView];
            return;
        } else if ([self showsBottomStatusBar]) {
                   if ([characters isEqualToString:@"3"]) {
                [O_modePopUpButton performClick:self];
                return;
            } else if ([characters isEqualToString:@"4"]) {
                [O_tabStatusPopUpButton performClick:self];
                return;
            } else if ([characters isEqualToString:@"5"]) {
                [O_lineEndingPopUpButton performClick:self];
                return;
            } else if ([characters isEqualToString:@"6"]) {
                [O_encodingPopUpButton performClick:self];
                return;
            } else if ([characters isEqualToString:@"7"]) {
                [O_windowWidthTextField performClick:self];
                return;
            }
        } else {
            static NSSet *s_bottomShortCutSet = nil;
            if (!s_bottomShortCutSet) {
                 s_bottomShortCutSet = [[NSSet alloc] initWithObjects:@"3",@"4",@"5",@"6",@"7",nil];
            }
            PlainTextEditor *otherEditor=
                [[I_windowControllerTabContext plainTextEditors] lastObject];
            if ([otherEditor showsBottomStatusBar] && 
                [s_bottomShortCutSet containsObject:characters]) {
                [otherEditor keyDown:aEvent];
                return;
            }
        }
    }
    
    
    
    [super keyDown:aEvent];
}

#pragma mark -
#pragma mark ### PopUpButton delegate methods ###
- (void)updateSelectedSymbol {
    PlainTextDocument *document=[self document];
    if ([[document documentMode] hasSymbols]) {
        int symbolTag = [document selectedSymbolForRange:[I_textView selectedRange]];
        if (symbolTag == -1) {
            [O_symbolPopUpButton selectItemAtIndex:0];
        } else {
            [O_symbolPopUpButton selectItem:[[O_symbolPopUpButton menu] itemWithTag:symbolTag]];
        }
    }
}

- (void)updateSymbolPopUpSorted:(BOOL)aSorted {
    NSMenu *popUpMenu=[[self document] symbolPopUpMenuForView:I_textView sorted:aSorted];
    NSPopUpButtonCell *cell=[O_symbolPopUpButton cell];
    [[[cell menu] retain] autorelease];
    if ([[popUpMenu itemArray] count]) {
        NSMenu *copiedMenu=[popUpMenu copyWithZone:[NSMenu menuZone]];
        [cell setMenu:copiedMenu];
        [copiedMenu release];
        [self updateSelectedSymbol];
    }
    [self TCM_adjustTopStatusBarFrames];
}

- (void)popUpWillShowMenu:(PopUpButton *)aButton {
    NSEvent *currentEvent=[NSApp currentEvent];
    BOOL sorted=([currentEvent type]==NSLeftMouseDown && ([currentEvent modifierFlags]&NSAlternateKeyMask));
    if (sorted != I_flags.symbolPopUpIsSorted) {
        [self updateSymbolPopUpSorted:sorted];
        I_flags.symbolPopUpIsSorted=sorted;
    }
}

#pragma mark -
#pragma mark ### display fixes for bottom status bar pop up buttons ###
// proxy method for status bar encoding dropdown to reset state on selection
- (IBAction)showCustomizeEncodingPanel:(id)aSender {
    [self performSelector:@selector(TCM_updateBottomStatusBar) withObject:nil afterDelay:0.0001];
    [[EncodingManager sharedInstance] showPanel:self];
}

#pragma mark -
#pragma mark ### NSTextView delegate methods ###

- (void)textViewContextMenuNeedsUpdate:(NSMenu *)aContextMenu {
    NSMenu *scriptMenu = [[aContextMenu itemWithTag:12345] submenu];
    [scriptMenu removeAllItems];
    PlainTextDocument *document=(PlainTextDocument *)[self document];
    [document fillScriptsIntoContextMenu:scriptMenu];
    if ([scriptMenu numberOfItems] == 0) {
        [[aContextMenu itemWithTag:12345] setEnabled:NO];
    } else {
        [[aContextMenu itemWithTag:12345] setEnabled:YES];
    }
}

- (BOOL)textView:(NSTextView *)aTextView doCommandBySelector:(SEL)aSelector {
    PlainTextDocument *document=(PlainTextDocument *)[self document];
    if (![document isRemotelyEditingTextStorage]) {
        [self setFollowUserID:nil];
    }
    return [document textView:aTextView doCommandBySelector:aSelector];
}

- (BOOL)textView:(NSTextView *)aTextView shouldChangeTextInRange:(NSRange)affectedCharRange replacementString:(NSString *)replacementString {
	if (replacementString == nil) return YES; // only styles are changed
    PlainTextDocument *document = [self document];
    if (![document isRemotelyEditingTextStorage]) {
        [self setFollowUserID:nil];
    }

    if (document && ![document isFileWritable] && ![document editAnyway]) {
        NSDictionary *contextInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                                    @"EditAnywayAlert", @"Alert",
                                                    aTextView, @"TextView",
                                                    [[replacementString copy] autorelease], @"ReplacementString",
                                                    nil];

        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert setMessageText:NSLocalizedString(@"Warning", nil)];
        [alert setInformativeText:NSLocalizedString(@"File is read-only", nil)];
        [alert addButtonWithTitle:NSLocalizedString(@"Edit anyway", nil)];
        [alert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
        [[[alert buttons] objectAtIndex:0] setKeyEquivalent:@"\r"];
        [alert beginSheetModalForWindow:[aTextView window]
                          modalDelegate:document
                         didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
                            contextInfo:[contextInfo retain]];

        return NO;
    }

    if (![replacementString canBeConvertedToEncoding:[document fileEncoding]] && (![aTextView hasMarkedText] || [aTextView _isUnmarking])) {
        TCMMMSession *session=[document session];
        if ([session isServer] && [session participantCount]<=1) {
            NSMutableDictionary *contextInfo = [[NSMutableDictionary alloc] init];
            [contextInfo setObject:@"ShouldPromoteAlert" forKey:@"Alert"];
            [contextInfo setObject:aTextView forKey:@"TextView"];
            [contextInfo setObject:[[replacementString copy] autorelease] forKey:@"ReplacementString"];
            [contextInfo autorelease];

            NSAlert *alert = [[[NSAlert alloc] init] autorelease];
            [alert setAlertStyle:NSWarningAlertStyle];
            [alert setMessageText:NSLocalizedString(@"You are trying to insert characters that cannot be handled by the file's current encoding. Do you want to cancel the change?", nil)];
            [alert setInformativeText:NSLocalizedString(@"You are no longer restricted by the file's current encoding if you promote to a Unicode encoding.", nil)];
            [alert addButtonWithTitle:NSLocalizedString(@"Insert", nil)];
            [alert addButtonWithTitle:NSLocalizedString(@"Promote to UTF8", nil)];
            [alert addButtonWithTitle:NSLocalizedString(@"Promote to Unicode", nil)];
            [[[alert buttons] objectAtIndex:0] setKeyEquivalent:@"\r"];
            [alert beginSheetModalForWindow:[aTextView window]
                              modalDelegate:document
                             didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
                                contextInfo:[contextInfo retain]];
        } else {
            NSBeep();
        }
        return NO;
    } else {
        [aTextView setTypingAttributes:[(PlainTextDocument *)[self document] typingAttributes]];
    }
    
    if ([(TextView *)aTextView isPasting] && ![(TextStorage *)[aTextView textStorage] hasMixedLineEndings]) {
        unsigned length = [replacementString length];
        unsigned curPos = 0;
        unsigned startIndex, endIndex, contentsEndIndex;
        NSString *lineEndingString = [document lineEndingString];
        unsigned lineEndingStringLength = [lineEndingString length];
        unichar *lineEndingBuffer = NSZoneMalloc(NULL, sizeof(unichar) * lineEndingStringLength);
        [lineEndingString getCharacters:lineEndingBuffer];
        BOOL isLineEndingValid = YES;
        
        while (curPos < length) {
            [replacementString getLineStart:&startIndex end:&endIndex contentsEnd:&contentsEndIndex forRange:NSMakeRange(curPos, 0)];
            if ((contentsEndIndex + lineEndingStringLength) <= length) {
                unsigned i;
                for (i = 0; i < lineEndingStringLength; i++) {
                    if ([replacementString characterAtIndex:contentsEndIndex + i] != lineEndingBuffer[i]) {
                        isLineEndingValid = NO;
                        break;
                    }
                }            
            }
            curPos = endIndex;
        }
        
        NSZoneFree(NSZoneFromPointer(lineEndingBuffer), lineEndingBuffer);
        
        if (!isLineEndingValid) {
            NSMutableDictionary *contextInfo = [[NSMutableDictionary alloc] init];
            [contextInfo setObject:@"PasteWrongLineEndingsAlert" forKey:@"Alert"];
            [contextInfo setObject:aTextView forKey:@"TextView"];
            [contextInfo setObject:[[replacementString copy] autorelease] forKey:@"ReplacementString"];
            [contextInfo autorelease];
            
            NSAlert *alert = [[[NSAlert alloc] init] autorelease];
            [alert setAlertStyle:NSWarningAlertStyle];
            [alert setMessageText:NSLocalizedString(@"You are pasting text that does not match the file's current line endings. Do you want to paste the text with converted line endings?", nil)];
            [alert setInformativeText:NSLocalizedString(@"The file will have mixed line endings if you do not paste converted text.", nil)];
            [alert addButtonWithTitle:NSLocalizedString(@"Paste Converted", nil)];
            [alert addButtonWithTitle:NSLocalizedString(@"Paste Unchanged", nil)];
            [[[alert buttons] objectAtIndex:0] setKeyEquivalent:@"\r"];
            [alert beginSheetModalForWindow:[aTextView window]
                              modalDelegate:document
                             didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
                                contextInfo:[contextInfo retain]];
            return NO;
        }
    }

    return [document textView:aTextView shouldChangeTextInRange:affectedCharRange replacementString:replacementString];
}

- (void)textDidChange:(NSNotification *)aNotification {
    if ([O_scrollView rulersVisible]) {
        [[O_scrollView verticalRulerView] setNeedsDisplay:YES];
    }
}

- (NSRange)textView:(NSTextView *)aTextView
           willChangeSelectionFromCharacterRange:(NSRange)aOldSelectedCharRange
                                toCharacterRange:(NSRange)aNewSelectedCharRange {
    PlainTextDocument *document=(PlainTextDocument *)[self document];
    return [document textView:aTextView
             willChangeSelectionFromCharacterRange:aOldSelectedCharRange
                                  toCharacterRange:aNewSelectedCharRange];
}

- (void)textViewDidChangeSelection:(NSNotification *)aNotification {
    if (I_flags.pausedProcessing) {
        I_flags.pausedProcessing=NO;
        [[[self document] session] startProcessing];
    }
    [self updateSelectedSymbol];
    [self TCM_updateStatusBar];
}

- (NSDictionary *)blockeditAttributesForTextView:(NSTextView *)aTextView {
    return [[self document] blockeditAttributes];
}

- (void)textViewDidChangeSpellCheckingSetting:(TextView *)aTextView {
    [[self document] setContinuousSpellCheckingEnabled:[aTextView isContinuousSpellCheckingEnabled]];
}

- (void)textView:(NSTextView *)aTextView mouseDidGoDown:(NSEvent *)aEvent {
    [self setFollowUserID:nil];
    if (!I_flags.pausedProcessing) {
        I_flags.pausedProcessing=YES;
        [[[self document] session] pauseProcessing];
    }
}

#pragma mark -

- (void)scrollToUserWithID:(NSString *)aUserID {
    TCMMMUser *user=[[TCMMMUserManager sharedInstance] userForUserID:aUserID];
    if (user) {
        NSDictionary *sessionProperties=[user propertiesForSessionID:[[[self document] session] sessionID]];
        SelectionOperation *selectionOperation=[sessionProperties objectForKey:@"SelectionOperation"];
        if (selectionOperation) {
            [I_textView scrollRangeToVisible:[selectionOperation selectedRange]];
        }
    }
}

- (void)defaultParagraphStyleDidChange:(NSNotification *)aNotification {
    [I_textView setDefaultParagraphStyle:[(PlainTextDocument *)[self document] defaultParagraphStyle]];
    [self TCM_updateBottomStatusBar];
    [self textDidChange:aNotification];
    [I_textView setNeedsDisplay:YES];
}

- (void)plainTextDocumentDidChangeEditStatus:(NSNotification *)aNotification {
    if ([[self document] wrapLines] != [self wrapsLines]) {
        [self setWrapsLines:[[self document] wrapLines]];
    }
    [self TCM_updateBottomStatusBar];
    [I_textView setNeedsDisplay:YES]; // because the change could have involved line endings
}

- (void)plainTextDocumentDidChangeSymbols:(NSNotification *)aNotification {
    [self updateSymbolPopUpSorted:NO];
}

- (void)plainTextDocumentUserDidChangeSelection:(NSNotification *)aNotification {
    NSString *followUserID=[self followUserID];
    if (followUserID) {
        if ([[[[aNotification userInfo] objectForKey:@"User"] userID] isEqualToString:followUserID]) {
            [self scrollToUserWithID:followUserID];
        }
    }
}

#pragma mark -
#pragma mark ### notification handling ###

- (void)textViewFrameDidChange:(NSNotification *)aNotification {
    [I_radarScroller setMaxHeight:[I_textView frame].size.height];
}

- (void)viewFrameDidChange:(NSNotification *)aNotification {
    [self TCM_adjustTopStatusBarFrames];
    [self TCM_updateBottomStatusBar];
}

- (void)setRadarMarkForUser:(TCMMMUser *)aUser {
    NSString *sessionID=[[[self document] session] sessionID];
    NSColor *changeColor=[aUser changeColor];

    SelectionOperation *selectionOperation=[[aUser propertiesForSessionID:sessionID] objectForKey:@"SelectionOperation"];
    if (selectionOperation) {
        unsigned rectCount;
        NSRange range=[selectionOperation selectedRange];
        NSLayoutManager *layoutManager = [I_textView layoutManager];
        if (layoutManager) {
            NSRectArray rects=[layoutManager
                                rectArrayForCharacterRange:range
                              withinSelectedCharacterRange:range
                                           inTextContainer:[I_textView textContainer]
                                                 rectCount:&rectCount];
            if (rectCount>0) {
                NSRect rect=rects[0];
                unsigned i;
                for (i=1; i<rectCount;i++) {
                    rect=NSUnionRect(rect,rects[i]);
                }
                [I_radarScroller setMarkFor:[aUser userID]
                                withColor:changeColor
                            forMinLocation:(float)rect.origin.y
                            andMaxLocation:(float)NSMaxY(rect)];
            }
        } else {
            NSLog(@"%s Textview:%@ has not yet a layoutmanager:%@ - strange document: %@",__FUNCTION__,I_textView,layoutManager,[[self document] displayName]);
        }
    } else {
        [I_radarScroller removeMarkFor:[aUser userID]];
    }
}

- (void)userDidChangeSelection:(NSNotification *)aNotification {
    TCMMMUser *user=[[aNotification userInfo] objectForKey:@"User"];
    if (user) {
        [self setRadarMarkForUser:user];
    }
}

#pragma mark -
#pragma mark ### Auto completion ###

- (NSArray *)textView:(NSTextView *)textView completions:(NSArray *)words forPartialWordRange:(NSRange)charRange indexOfSelectedItem:(int *)index {
    NSString *partialWord, *completionEntry;
    NSMutableArray *completions = [NSMutableArray array];
    unsigned i, count;
    NSString *textString=[[textView textStorage] string];
    // Get the current partial word being completed.
    partialWord = [textString substringWithRange:charRange];

    NSMutableDictionary *dictionaryOfResultStrings=[NSMutableDictionary new];

    // find all matches in the current text for this prefix
    OGRegularExpression *findExpression=[[OGRegularExpression alloc] initWithString:[NSString stringWithFormat:@"(?<=\\W|^)%@\\w+",partialWord] options:OgreFindNotEmptyOption];
    DocumentMode *documentMode = [[self document] documentMode];

	NSEnumerator *matches=[findExpression matchEnumeratorInString:textString];
	OGRegularExpressionMatch *match=nil;
	while ((match=[matches nextObject])) {
		[dictionaryOfResultStrings setObject:@"YES" forKey:[match matchedString]];
	}
    [completions addObjectsFromArray:[[dictionaryOfResultStrings allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]];
	
	// Check if we should use a different mode than the default mode here.
	NSString *modeForAutocomplete = [[textView textStorage] attribute:kSyntaxHighlightingParentModeForAutocompleteAttributeName atIndex:charRange.location effectiveRange:NULL];
	
	DocumentMode *theMode;
	if (modeForAutocomplete) theMode = [[DocumentModeManager sharedInstance] documentModeForName:modeForAutocomplete];
	else theMode = documentMode;
	
    // Get autocompletions from mode responsible for the insert location.
    NSArray *completionSource = [theMode autocompleteDictionary];
    // Examine them one by one.
    count = [completionSource count];
    for (i = 0; i < count; i++) {
        completionEntry = [completionSource objectAtIndex:i];
        // Add those that match the current partial word to the list of completions.
        if ([completionEntry hasPrefix:partialWord] &&
            [dictionaryOfResultStrings objectForKey:completionEntry]==nil) {
            [completions addObject:completionEntry];
            [dictionaryOfResultStrings setObject:@"YES" forKey:completionEntry];
        }
    }

	// add suggestions from all other open documents
	NSMutableDictionary *otherDictionaryOfResultStrings=[NSMutableDictionary new];
    NSEnumerator *documents=[[[DocumentController sharedInstance] documents] objectEnumerator];
    PlainTextDocument *document=nil;
    while ((document=[documents nextObject])) {
		if (document==[self document]) continue;
        NSEnumerator *matches=[findExpression matchEnumeratorInString:[[document textStorage] string]];
        OGRegularExpressionMatch *match=nil;
        while ((match=[matches nextObject])) {
			if ([dictionaryOfResultStrings objectForKey:[match matchedString]]==nil)
				[otherDictionaryOfResultStrings setObject:@"YES" forKey:[match matchedString]];
        }
    }
    [findExpression release];
    [completions addObjectsFromArray:[[otherDictionaryOfResultStrings allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]];
	[dictionaryOfResultStrings addEntriesFromDictionary:otherDictionaryOfResultStrings];
    
	// add the originally suggested words if spelling dictionary should be used
    if ([[documentMode syntaxDefinition] useSpellingDictionary]) {
        NSEnumerator *enumerator = [words objectEnumerator];
        id word;
        while (word = [enumerator nextObject]) {
            if ([dictionaryOfResultStrings objectForKey:word]==nil)
                [completions addObject:word];
                [dictionaryOfResultStrings setObject:@"YES" forKey:word];
        }
    }

    //DEBUGLOG(@"SyntaxHighlighterDomain", DetailedLogLevel, @"Finished autocomplete");
    [dictionaryOfResultStrings release];
    [otherDictionaryOfResultStrings release];

    return completions;
}

- (void)textViewWillStartAutocomplete:(TextView *)aTextView {
//    NSLog(@"Start");
    PlainTextDocument *document=[self document];
    [document setIsHandlingUndoManually:YES];
    [document setShouldChangeChangeCount:NO];
}

- (void)textView:(TextView *)aTextView didFinishAutocompleteByInsertingCompletion:(NSString *)aWord forPartialWordRange:(NSRange)aCharRange movement:(int)aMovement {
//    NSLog(@"textView: didFinishAutocompleteByInsertingCompletion:%@ forPartialWordRange:%@ movement:%d",aWord,NSStringFromRange(aCharRange),aMovement);
    PlainTextDocument *document=[self document];
    UndoManager *undoManager=[document documentUndoManager];
    [undoManager registerUndoChangeTextInRange:NSMakeRange(aCharRange.location,[aWord length])
                 replacementString:[[[aTextView textStorage] string] substringWithRange:aCharRange] shouldGroupWithPriorOperation:NO];

    [document setIsHandlingUndoManually:NO];
    [document setShouldChangeChangeCount:YES];
    [document updateChangeCount:NSChangeDone];

}

@end


@implementation PlainTextEditor (PlainTextEditorScriptingAdditions)
- (id)scriptSelection {
    return [ScriptTextSelection scriptTextSelectionWithTextStorage:(TextStorage *)[[self textView] textStorage] editor:self];
}

- (void)setScriptSelection:(id)selection {
    //NSLog(@"%s %@",__FUNCTION__,[selection debugDescription]);
    NSTextView *textView = [self textView];
    unsigned length = [[textView textStorage] length];
    if ([selection isKindOfClass:[NSArray class]] && [selection count] == 2) {
        int startIndex = [[selection objectAtIndex:0] intValue];
        int endIndex = [[selection objectAtIndex:1] intValue];
        
        if (startIndex > 0 && startIndex <= length && endIndex >= startIndex && endIndex <= length)
            [textView setSelectedRange:NSMakeRange(startIndex - 1, endIndex - startIndex + 1)];
    } else if ([selection isKindOfClass:[NSNumber class]]) {
        int insertionPointIndex = [selection intValue]-1;
        insertionPointIndex = MAX(insertionPointIndex,0);
        insertionPointIndex = MIN(insertionPointIndex,length);
        [textView setSelectedRange:NSMakeRange(insertionPointIndex,0)];
    } else if ([selection isKindOfClass:[ScriptTextBase class]] || [selection isKindOfClass:[TextStorage class]]) {
        NSRange newRange=RangeConfinedToRange([selection rangeRepresentation], NSMakeRange(0,length));
        [textView setSelectedRange:newRange];
    }
}

@end

