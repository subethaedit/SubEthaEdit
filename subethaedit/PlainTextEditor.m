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

@interface PlainTextEditor (PlainTextEditorPrivateAdditions) 
- (void)TCM_updateStatusBar;
- (void)TCM_updateBottomStatusBar;
@end

@implementation PlainTextEditor 

- (id)initWithWindowController:(NSWindowController *)aWindowController {
    self = [super init];
    if (self) {
        I_windowController = aWindowController;
        [NSBundle loadNibNamed:@"PlainTextEditor" owner:self];
        I_flags.showTopStatusBar = YES;
        I_flags.showBottomStatusBar = YES;
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
}

- (void)awakeFromNib {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(defaultParagraphStyleDidChange:) name:PlainTextDocumentDefaultParagraphStyleDidChangeNotification object:[I_windowController document]];

    [O_scrollView setHasVerticalScroller:YES];
    NSRect frame;
    frame.origin=NSMakePoint(0.,0.);
    frame.size  =[O_scrollView contentSize];

    
    LayoutManager *layoutManager=[LayoutManager new];
    [[[I_windowController document] textStorage] addLayoutManager:layoutManager];
    
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
    [I_textView setAllowsUndo:YES];

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
    
    [I_textView setDefaultParagraphStyle:[[I_windowController document] defaultParagraphStyle]];
    

    [[NSNotificationCenter defaultCenter] addObserver:[I_windowController document] selector:@selector(textViewDidChangeSelection:) name:NSTextViewDidChangeSelectionNotification object:I_textView];
    [[NSNotificationCenter defaultCenter] addObserver:[I_windowController document] selector:@selector(textDidChange:) name:NSTextDidChangeNotification object:I_textView];
    NSView *view=[[NSView alloc] initWithFrame:[O_editorView frame]];
    [view setAutoresizesSubviews:YES];
    [view setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [view addSubview:[O_editorView autorelease]];
    [view setPostsFrameChangedNotifications:YES];
    [O_editorView setNextResponder:self];
    [self setNextResponder:view];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewFrameDidChange:) name:NSViewFrameDidChangeNotification object:view];
    O_editorView = view;
    [self TCM_updateStatusBar];
    [self TCM_updateBottomStatusBar];
}

- (void)TCM_updateStatusBar {
    if (I_flags.showTopStatusBar) {
        NSRange selection=[I_textView selectedRange];
        
        // findLine
        TextStorage *textStorage=(TextStorage *)[I_textView textStorage];
        int lineNumber=[textStorage lineNumberForLocation:selection.location];
        unsigned lineStartLocation=[[[textStorage lineStarts] objectAtIndex:lineNumber-1] intValue];
        NSString *string=[NSString stringWithFormat:@"%d:%d",lineNumber, selection.location-lineStartLocation];
        if (selection.length>0) string=[string stringByAppendingFormat:@" (%d)",selection.length]; 
    //    if (selection.location<[textStorage length]) { 
    //        id blockAttribute=[textStorage 
    //                            attribute:kBlockeditAttributeName 
    //                              atIndex:selection.location effectiveRange:nil];
    //        if (blockAttribute) string=[string stringByAppendingFormat:@" %@",NSLocalizedString(@"[Blockediting]", nil)];        
    //    }
        [O_positionTextField setStringValue:string];        

        [O_writtenByTextField setStringValue:@""];
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
}

- (void)TCM_updateBottomStatusBar {
    if (I_flags.showBottomStatusBar) {
        PlainTextDocument *document=[self document];
        [O_tabStatusTextField setStringValue:[NSString stringWithFormat:@"%@ (%d)",[document usesTabs]?@"TrueTab":@"Spaces",[document tabWidth]]];
        [O_modeTextField setStringValue:[[document documentMode] displayName]];
        
        NSFont *font=[document fontWithTrait:0];
        float characterWidth=[font widthOfString:@"m"];
        int charactersPerLine = (int)(([I_textView bounds].size.width-[I_textView textContainerInset].width*2-[[I_textView textContainer] lineFragmentPadding]*2)/characterWidth);
        [O_windowWidthTextField setStringValue:[NSString stringWithFormat:@"%d%@",charactersPerLine,[O_scrollView hasHorizontalScroller]?@"":([document wrapsCharacters]?@"c":@"w")]];
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
        NSUndoManager *undoManager=[[self document] undoManager];
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

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    SEL selector = [menuItem action];
    
    if (selector == @selector(toggleWrap:)) {
        [menuItem setState:[O_scrollView hasHorizontalScroller]?NSOffState:NSOnState];
        return YES;
    } else if (selector == @selector(toggleLineNumbers:)) {
        [menuItem setState:[O_scrollView rulersVisible]?NSOnState:NSOffState];
        return YES;
    } else if (selector == @selector(toggleTopStatusBar:)) {
        [menuItem setState:[self showsTopStatusBar]?NSOnState:NSOffState];
        return YES;
    } else if (selector == @selector(toggleBottomStatusBar:)) {
        [menuItem setState:[self showsBottomStatusBar]?NSOnState:NSOffState];
        return YES;
    } else if (selector == @selector(toggleShowsChangeMarks:)) {
        BOOL showsChangeMarks=[(LayoutManager *)[I_textView layoutManager] showsChangeMarks];
        [menuItem setTitle:showsChangeMarks 
                              ?NSLocalizedString(@"Hide Changes", nil) 
                              :NSLocalizedString(@"Show Changes", nil)];
        return YES;
    }
    return YES;
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
    [self TCM_updateBottomStatusBar];
}

- (IBAction)toggleLineNumbers:(id)aSender {
    [O_scrollView setRulersVisible:![O_scrollView rulersVisible]];
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

- (IBAction)toggleShowsChangeMarks:(id)aSender {
    LayoutManager *layoutManager=(LayoutManager *)[I_textView layoutManager];
    [layoutManager setShowsChangeMarks:![layoutManager showsChangeMarks]];
}

- (IBAction)toggleTopStatusBar:(id)aSender {
    [self setShowsTopStatusBar:![self showsTopStatusBar]];
}

- (IBAction)toggleBottomStatusBar:(id)aSender {
    [self setShowsBottomStatusBar:![self showsBottomStatusBar]];
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


#pragma mark -
#pragma mark ### NSTextView delegate methods ###

- (BOOL)textView:(NSTextView *)aTextView doCommandBySelector:(SEL)aSelector {
    return [[I_windowController document] textView:aTextView doCommandBySelector:aSelector];
}

-(BOOL)textView:(NSTextView *)aTextView shouldChangeTextInRange:(NSRange)affectedCharRange replacementString:(NSString *)replacementString {
    [aTextView setTypingAttributes:[(PlainTextDocument *)[I_windowController document] typingAttributes]];
    return YES;
}

- (void)textDidChange:(NSNotification *)aNotification {
    if ([O_scrollView rulersVisible]) {
        [[O_scrollView verticalRulerView] setNeedsDisplay:YES];     
    }
}

- (NSRange)textView:(NSTextView *)aTextView 
           willChangeSelectionFromCharacterRange:(NSRange)aOldSelectedCharRange 
                                toCharacterRange:(NSRange)aNewSelectedCharRange {
    return [[I_windowController document] textView:aTextView 
             willChangeSelectionFromCharacterRange:aOldSelectedCharRange 
                                  toCharacterRange:aNewSelectedCharRange];
}
- (void)textViewDidChangeSelection:(NSNotification *)aNotification {
    [self TCM_updateStatusBar];
}

#pragma mark -

- (void)defaultParagraphStyleDidChange:(NSNotification *)aNotification {
    [I_textView setDefaultParagraphStyle:[[I_windowController document] defaultParagraphStyle]];
    [self TCM_updateBottomStatusBar];
}


#pragma mark -
#pragma mark ### notification handling ###

- (void)viewFrameDidChange:(NSNotification *)aNotification {
    [self TCM_updateBottomStatusBar];
}

@end
