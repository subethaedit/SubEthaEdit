//
//  PlainTextEditorWindowController.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Tue Apr 06 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

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
#import <OgreKit/OgreKit.h>

@interface PlainTextEditor (PlainTextEditorPrivateAdditions) 
- (void)TCM_updateStatusBar;
- (void)TCM_updateBottomStatusBar;
@end

@implementation PlainTextEditor 

- (id)initWithWindowController:(NSWindowController *)aWindowController splitButton:(BOOL)aFlag {
    self = [super init];
    if (self) {
        I_windowController = aWindowController;
        I_flags.hasSplitButton = aFlag;
        I_flags.showTopStatusBar = YES;
        I_flags.showBottomStatusBar = YES;
        [self setFollowUserID:nil];
        [NSBundle loadNibNamed:@"PlainTextEditor" owner:self];
    }   
    return self; 
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:[I_windowController document] name:NSTextViewDidChangeSelectionNotification object:I_textView];
    [[NSNotificationCenter defaultCenter] removeObserver:[I_windowController document] name:NSTextDidChangeNotification object:I_textView];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [I_textView setDelegate:nil];
    [O_editorView release];
    [I_textContainer release];
    [I_radarScroller release];
    [I_followUserID release];
    [super dealloc];
}

- (void)awakeFromNib {
    PlainTextDocument *document=[self document];

    [[NSNotificationCenter defaultCenter] 
            addObserver:self selector:@selector(defaultParagraphStyleDidChange:) 
            name:PlainTextDocumentDefaultParagraphStyleDidChangeNotification object:[I_windowController document]];
    [[NSNotificationCenter defaultCenter] 
            addObserver:self selector:@selector(userDidChangeSelection:) 
            name:PlainTextDocumentUserDidChangeSelectionNotification object:[I_windowController document]];
    [[NSNotificationCenter defaultCenter] 
            addObserver:self selector:@selector(plainTextDocumentDidChangeEditStatus:) 
            name:PlainTextDocumentDidChangeEditStatusNotification object:[I_windowController document]];
    [[NSNotificationCenter defaultCenter] 
            addObserver:self selector:@selector(plainTextDocumentDidChangeSymbols:) 
            name:PlainTextDocumentDidChangeSymbolsNotification object:[I_windowController document]];
[[NSNotificationCenter defaultCenter] 
            addObserver:self selector:@selector(plainTextDocumentUserDidChangeSelection:) 
            name:PlainTextDocumentUserDidChangeSelectionNotification object:[I_windowController document]];



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

    [I_textView setDelegate:self];
    [I_textContainer setHeightTracksTextView:NO];
    [I_textContainer setWidthTracksTextView:YES];
    [layoutManager addTextContainer:I_textContainer];
    
    [O_scrollView setVerticalRulerView:[[[GutterRulerView alloc] initWithScrollView:O_scrollView orientation:NSVerticalRuler] autorelease]];
    [O_scrollView setHasVerticalRuler:YES];
    [[O_scrollView verticalRulerView] setRuleThickness:32.];

    [O_scrollView setDocumentView:[I_textView autorelease]];
    [[O_scrollView verticalRulerView] setClientView:I_textView];

    
    [layoutManager release];
    
    [I_textView setDefaultParagraphStyle:[document defaultParagraphStyle]];
    

    [[NSNotificationCenter defaultCenter] addObserver:document selector:@selector(textViewDidChangeSelection:) name:NSTextViewDidChangeSelectionNotification object:I_textView];
    [[NSNotificationCenter defaultCenter] addObserver:document selector:@selector(textDidChange:) name:NSTextDidChangeNotification object:I_textView];
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
    [[O_symbolPopUpButton cell] setControlSize:NSSmallControlSize];
    [O_symbolPopUpButton setBordered:NO];
    [O_symbolPopUpButton setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSSmallControlSize]]];
    
    [self TCM_updateStatusBar];
    [self TCM_updateBottomStatusBar];
    
    [self takeSettingsFromDocument];
    [self setShowsChangeMarks:[document showsChangeMarks]];
    [self setShowsTopStatusBar:[document showsTopStatusBar]];
    [self setShowsBottomStatusBar:[document showsBottomStatusBar]];
}

- (void)takeSettingsFromDocument {
    PlainTextDocument *document=[self document];
    [[self textView] setBackgroundColor:[document documentBackgroundColor]];
    [self setShowsInvisibleCharacters:[document showInvisibleCharacters]];
    [self setWrapsLines: [document wrapLines]];
    [self setShowsGutter:[document showsGutter]];
    [self updateSymbolPopUpSorted:NO];
    [self TCM_updateStatusBar];
    [self TCM_updateBottomStatusBar];
    [I_textView setEditable:[document isEditable]];
}

#define RIGHTINSET 5.

- (void)TCM_adjustTopStatusBarFrames {
    if (I_flags.showTopStatusBar) {
        float symbolWidth=[(PopUpButtonCell *)[O_symbolPopUpButton cell] desiredWidth];
        
        NSRect bounds=[O_topStatusBarView bounds];
        NSRect positionFrame=[O_positionTextField frame];
        NSPoint position=positionFrame.origin;
        positionFrame.size.width=[[O_positionTextField stringValue]
                        sizeWithAttributes:[NSDictionary dictionaryWithObject:[O_positionTextField font] 
                                                                       forKey:NSFontAttributeName]].width+5.;
        [O_positionTextField setFrame:positionFrame];
        position.x = (float)(int)NSMaxX(positionFrame);
        NSRect newWrittenByFrame=[O_writtenByTextField frame];
        newWrittenByFrame.size.width=[[O_writtenByTextField stringValue]
                                        sizeWithAttributes:[NSDictionary dictionaryWithObject:[O_writtenByTextField font] 
                                                                                       forKey:NSFontAttributeName]].width+5.;
        NSRect newPopUpFrame=[O_symbolPopUpButton frame];
        newPopUpFrame.origin.x=position.x;
        if (![[[self document] documentMode] hasSymbols]) {
            newPopUpFrame.size.width=0;
            [O_symbolPopUpButton setHidden:YES];
        } else {
            newPopUpFrame.size.width=symbolWidth;
            [O_symbolPopUpButton setHidden:NO];
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
        [O_symbolPopUpButton  setFrame:newPopUpFrame];
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

- (NSSize)desiredSizeForColumns:(int)aColumns rows:(int)aRows {
    NSSize result;
    NSFont *font=[[self document] fontWithTrait:0];
    float characterWidth=[font widthOfString:@"m"];
    result.width = characterWidth*aColumns + [[I_textView textContainer] lineFragmentPadding]*2 + [I_textView textContainerInset].width*2 + ([O_editorView bounds].size.width - [I_textView bounds].size.width);
    result.height = [font defaultLineHeightForFont]*aRows + 
                    ([self showsBottomStatusBar]?18.:0) + 
                    ([self showsTopStatusBar]?18.:0) +
                    [I_textView textContainerInset].height * 2;
    return result;
}

- (void)TCM_updateBottomStatusBar {
    if (I_flags.showBottomStatusBar) {
        PlainTextDocument *document=[self document];
        [O_tabStatusTextField setStringValue:[NSString stringWithFormat:@"%@ (%d)",[document usesTabs]?@"TrueTab":@"Spaces",[document tabWidth]]];
        [O_modeTextField setStringValue:[[document documentMode] displayName]];
        
        [O_encodingTextField setStringValue:[NSString localizedNameOfStringEncoding:[document fileEncoding]]];
        
        NSFont *font=[document fontWithTrait:0];
        float characterWidth=[font widthOfString:@"m"];
        int charactersPerLine = (int)(([I_textView bounds].size.width-[I_textView textContainerInset].width*2-[[I_textView textContainer] lineFragmentPadding]*2)/characterWidth);
        [O_windowWidthTextField setStringValue:[NSString stringWithFormat:@"%d%@",charactersPerLine,[O_scrollView hasHorizontalScroller]?@"":([document wrapMode]==DocumentModeWrapModeCharacters?@"c":@"w")]];
        NSString *lineEndingStatusString=@"";
        switch ([document lineEnding]) {
            case LineEndingLF:
                lineEndingStatusString=@"(LF)";
                break;
            case LineEndingCR:
                lineEndingStatusString=@"(CR)";
                break;
            case LineEndingCRLF:
                lineEndingStatusString=@"(CRLF)";
                break;
            case LineEndingUnicodeLineSeparator:
                lineEndingStatusString=@"(LSEP)";
                break;
            case LineEndingUnicodeParagraphSeparator:
                lineEndingStatusString=@"(PSEP)";
                break;
        }
        [O_lineEndingTextField setStringValue:lineEndingStatusString];
    }
}

- (NSView *)editorView {
    return O_editorView;
}

- (NSTextView *)textView {
    return I_textView;
}

- (PlainTextDocument *)document {
    return (PlainTextDocument *)[I_windowController document];
}

- (void)setIsSplit:(BOOL)aFlag {
    if (I_flags.hasSplitButton) {
        [[(ButtonScrollView *)O_scrollView button] setState:aFlag?NSOnState:NSOffState];
    }
}

- (int)dentLineInTextView:(NSTextView *)aTextView withRange:(NSRange)aLineRange in:(BOOL)aIndent{
    int changedChars=0;
    NSRange affectedCharRange=NSMakeRange(aLineRange.location,0);
    NSString *replacementString=@"";
    NSTextStorage *textStorage=[aTextView textStorage];
    NSString *string=[textStorage string];
    int tabWidth=[[self document] tabWidth];
    if ([[self document] usesTabs]) {
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
    if (affectedCharRange.length>0 || [replacementString length]>0) {
        if ([aTextView  shouldChangeTextInRange:affectedCharRange 
                              replacementString:replacementString]) {
            NSAttributedString *attributedReplaceString=[[NSAttributedString alloc] 
                                                            initWithString:replacementString 
                                                                attributes:[aTextView typingAttributes]];
            [textStorage replaceCharactersInRange:affectedCharRange 
                              withAttributedString:attributedReplaceString];                    
            [attributedReplaceString release];
        }
    }
    return changedChars;
}

- (void)dentParagraphsInTextView:(NSTextView *)aTextView in:(BOOL)aIndent{
//    if (I_blockedit.hasBlockeditRanges) {
//        NSBeep();
//    } else {
    
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
//    }
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
        [menuItem setTitle:showsChangeMarks 
                              ?NSLocalizedString(@"Hide Changes", nil) 
                              :NSLocalizedString(@"Show Changes", nil)];
        return YES;
    } else if (selector == @selector(toggleShowInvisibles:)) {
        [menuItem setState:[self showsInvisibleCharacters]?NSOnState:NSOffState];
        return YES;
    } 
    return YES;
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
    [layoutManager   setShowsInvisibleCharacters:aFlag];
    [[self document] setShowInvisibleCharacters:aFlag];
}

- (BOOL)showsInvisibleCharacters {
    return [[I_textView layoutManager] showsInvisibleCharacters];
}

- (IBAction)toggleShowInvisibles:(id)aSender {
    LayoutManager *layoutManager = (LayoutManager *)[I_textView layoutManager];
    BOOL newSetting=![layoutManager showsInvisibleCharacters];
    [layoutManager   setShowsInvisibleCharacters:newSetting];
    [[self document] setShowInvisibleCharacters:newSetting];
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
        [I_textView setNeedsDisplay:YES];
    }
    [[self document] setWrapLines:[self wrapsLines]];
    [self TCM_updateBottomStatusBar];
}

- (BOOL)showsGutter {
    return [O_scrollView rulersVisible];
}

- (void)setShowsGutter:(BOOL)aFlag {
    [O_scrollView setRulersVisible:aFlag];
    [self TCM_updateBottomStatusBar];
}

#define STATUSBARSIZE 18.

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

- (BOOL)validateToolbarItem:(NSToolbarItem *)toolbarItem {
    NSString *itemIdentifier = [toolbarItem itemIdentifier];
    
    if ([itemIdentifier isEqualToString:ToggleChangeMarksToolbarItemIdentifier]) {
        BOOL showsChangeMarks=[(LayoutManager *)[I_textView layoutManager] showsChangeMarks];
        [toolbarItem setImage:showsChangeMarks
                              ?[NSImage imageNamed: @"HideChangeMarks"]
                              :[NSImage imageNamed: @"ShowChangeMarks"]  ];
        [toolbarItem setLabel:showsChangeMarks 
                              ?NSLocalizedString(@"Hide Changes", nil) 
                              :NSLocalizedString(@"Show Changes", nil)];
    }
    
    return YES;
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
#pragma mark ### NSTextView delegate methods ###

- (BOOL)textView:(NSTextView *)aTextView doCommandBySelector:(SEL)aSelector {
    return [[I_windowController document] textView:aTextView doCommandBySelector:aSelector];
}

- (BOOL)textView:(NSTextView *)aTextView shouldChangeTextInRange:(NSRange)affectedCharRange replacementString:(NSString *)replacementString {
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
    
    if (![replacementString canBeConvertedToEncoding:[document fileEncoding]]) {
        TCMMMSession *session=[document session];
        if ([session isServer] && [session participantCount]<=1) {
            NSDictionary *contextInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                                            @"ShouldPromoteAlert", @"Alert",
                                                            aTextView, @"TextView",
                                                            [[replacementString copy] autorelease], @"ReplacementString",
                                                            nil];
            
            NSAlert *alert = [[[NSAlert alloc] init] autorelease];
            [alert setAlertStyle:NSWarningAlertStyle];
            [alert setMessageText:NSLocalizedString(@"Warning", nil)];
            [alert setInformativeText:NSLocalizedString(@"CancelOrPromote", nil)];
            [alert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
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
        [aTextView setTypingAttributes:[(PlainTextDocument *)[I_windowController document] typingAttributes]];
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
    PlainTextDocument *document=(PlainTextDocument *)[I_windowController document];
    if (![document isRemotelyEditingTextStorage]) {
        [self setFollowUserID:nil];
    }
    return [document textView:aTextView 
             willChangeSelectionFromCharacterRange:aOldSelectedCharRange 
                                  toCharacterRange:aNewSelectedCharRange];
}

- (void)textViewDidChangeSelection:(NSNotification *)aNotification {
    [self updateSelectedSymbol];
    [self TCM_updateStatusBar];
}

- (NSDictionary *)blockeditAttributesForTextView:(NSTextView *)aTextView {
    return [[self document] blockeditAttributes];
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
    [I_textView setDefaultParagraphStyle:[[I_windowController document] defaultParagraphStyle]];
}

- (void)plainTextDocumentDidChangeEditStatus:(NSNotification *)aNotification {
    [self TCM_updateBottomStatusBar];
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

- (void)userDidChangeSelection:(NSNotification *)aNotification {
    TCMMMUser *user=[[aNotification userInfo] objectForKey:@"User"];
    if (user) {
        NSString *sessionID=[[[self document] session] sessionID];
        NSColor *changeColor=[user changeColor];
        
        
        SelectionOperation *selectionOperation=[[user propertiesForSessionID:sessionID] objectForKey:@"SelectionOperation"];
        if (selectionOperation) {
            int rectCount;
            NSRange range=[selectionOperation selectedRange];
            NSRectArray rects=[[I_textView layoutManager]
                                rectArrayForCharacterRange:range
                              withinSelectedCharacterRange:range 
                                           inTextContainer:[I_textView textContainer] 
                                                 rectCount:&rectCount];
            if (rectCount>0) {
                NSRect rect=rects[0]; 
                int i;
                for (i=1; i<rectCount;i++) {
                    rect=NSUnionRect(rect,rects[i]);
                }                                    
                [I_radarScroller setMarkFor:[user userID] 
                                withColor:changeColor
                            forMinLocation:(float)rect.origin.y 
                            andMaxLocation:(float)NSMaxY(rect)];            
            }
        }
    }
}

#pragma mark -
#pragma mark ### Auto completion ###

- (NSArray *)textView:(NSTextView *)textView completions:(NSArray *)words forPartialWordRange:(NSRange)charRange indexOfSelectedItem:(int *)index {
    NSString *partialWord, *completionEntry;
    NSMutableArray *completionSource;
    NSMutableArray *completions = [NSMutableArray array];
    unsigned i, count;
    NSString *textString=[[textView textStorage] string];
    // Get the current partial word being completed.
    partialWord = [textString substringWithRange:charRange];
    
    // Find all known names.
    completionSource = [NSMutableArray array];

    NSMutableDictionary *dictionary=[NSMutableDictionary new];

    // find all matches in the current text for this prefix
    OGRegularExpression *findExpression=[[OGRegularExpression alloc] initWithString:[NSString stringWithFormat:@"(?<=\\W)%@\\w+",partialWord] options:OgreFindNotEmptyOption];
    NSEnumerator *matches=[findExpression matchEnumeratorInString:textString];
    OGRegularExpressionMatch *match=nil;
    while ((match=[matches nextObject])) {
        [dictionary setObject:@"Blah" forKey:[match matchedString]];
    }
    [findExpression release];
    [completions addObjectsFromArray:[[dictionary allKeys] sortedArrayUsingSelector:@selector(compare:)]];
    [dictionary release];
// Too slow unfortunatly.
/*    NSArray *paras = [[[self document] textStorage] paragraphs];

    count = [paras count];
    for (i = 0; i < count; i++) {
        NSArray *words = [[paras objectAtIndex:i] words];
        int wordcount = [words count];
        int j;
        for (j = 0; j < wordcount; j++) {
            completionEntry = [[words objectAtIndex:j] string];
            if ([completionEntry hasPrefix:partialWord]) {
              if (![completions containsObject:completionEntry]) [completions addObject:completionEntry];
            }
        }
    }
*/
    [completionSource addObjectsFromArray:[[[self document] documentMode] autocompleteDictionary]];
//    [completionSource addObjectsFromArray:words]; // The whole stuff: spellchecker + all words in text

    // Examine the names one by one.
    count = [completionSource count];
    for (i = 0; i < count; i++) {
        completionEntry = [completionSource objectAtIndex:i];
        // Add those that match the current partial word to the list of completions.
        if (([completionEntry hasPrefix:partialWord])&&(![completions containsObject:completionEntry])) [completions addObject:completionEntry];
    }

    
    //DEBUGLOG(@"SyntaxHighlighterDomain", DetailedLogLevel, @"Finished autocomplete");

    return completions;
}


@end
