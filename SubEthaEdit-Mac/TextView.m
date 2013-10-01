//
//  TextView.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Tue Apr 06 2004.
//  Copyright (c) 2004-2006 TheCodingMonkeys. All rights reserved.
//

#import "LayoutManager.h"
#import "TextView.h"
#import "FoldableTextStorage.h"
#import "FullTextStorage.h"
#import "PlainTextDocument.h"
#import "TCMMMUserManager.h"
#import "TCMMMUser.h"
#import "TCMMMUserSEEAdditions.h"
#import "TCMMMSession.h"
#import "SelectionOperation.h"
#import "FindReplaceController.h"
#import "ParticipantsView.h"
#import "PlainTextWindowController.h"
#import "PlainTextEditor.h"
#import "AppController.h"
#import "DocumentMode.h"
#import "SyntaxHighlighter.h"
#import "SyntaxDefinition.h"
#import <OgreKit/OgreKit.h>
#import "NSCursorSEEAdditions.h"
#import "DocumentModeManager.h"
#import "ConnectionBrowserController.h"

#define SPANNINGRANGE(a,b) NSMakeRange(MIN(a,b),MAX(a,b)-MIN(a,b)+1)

@interface TextView (TextViewPrivateAdditions) 
- (PlainTextDocument *)document;
@end

@interface NSTextView (NSTextViewTCMPrivateAdditions) 
- (void)_adjustedCenteredScrollRectToVisible:(NSRect)aRect forceCenter:(BOOL)force;
@end

@implementation TextView

- (id)delegate {
	return (id)super.delegate;
}

// - (void)setNeedsDisplayInRect:(NSRect)aRect avoidAdditionalLayout:(BOOL)needsLayout {
// 	NSLog(@"%s %@ %@",__FUNCTION__,NSStringFromRect(aRect),needsLayout?@"YES":@"NO");
// 	[super setNeedsDisplayInRect:aRect avoidAdditionalLayout:NO];
// }

- (void)_adjustedCenteredScrollRectToVisible:(NSRect)aRect forceCenter:(BOOL)force {
    if (aRect.origin.x == [[self textContainer] lineFragmentPadding]) {
        aRect.origin.x = 0; // fixes the left hand edge moving
    }
    [super _adjustedCenteredScrollRectToVisible:aRect forceCenter:force];
}

static NSMenu *S_defaultMenu=nil;


+ (NSMenu *)defaultMenu {
    return S_defaultMenu;
}

+ (void)setDefaultMenu:(NSMenu *)aMenu {
	[S_defaultMenu autorelease];
    S_defaultMenu=[aMenu copy];
}

- (PlainTextDocument *)document {
    return (PlainTextDocument *)[(FoldableTextStorage *)[self textStorage] delegate];
}


- (void)setPageGuidePosition:(float)aPosition {
    I_pageGuidePosition = aPosition;
    [self setNeedsDisplay:YES];
}

- (IBAction)paste:(id)sender {
    I_flags.isPasting = YES;
    [super paste:sender];
    I_flags.isPasting = NO;
}

- (BOOL)isPasting {
    return I_flags.isPasting;
}

- (void)trackMouseForBlockeditWithEvent:(NSEvent *)aEvent {
    BOOL timerOn=NO;

    NSPoint currentPoint;

    unsigned glyphIndex,characterIndex,beginIndex;

    LayoutManager *layoutManager=(LayoutManager *)[self layoutManager];
    FoldableTextStorage *textStorage=(FoldableTextStorage *)[self textStorage];
    if ([textStorage length]==0) return;
    NSString *string = [self string];

    NSRange blockeditRange,tempRange;

    currentPoint = [self convertPoint:[aEvent locationInWindow] fromView:nil];
    glyphIndex = [layoutManager glyphIndexForPoint:currentPoint 
                                   inTextContainer:[self textContainer]];
    beginIndex=[layoutManager characterIndexForGlyphAtIndex:glyphIndex];
    
    BOOL isAddingBlockeditRanges = [[textStorage attributesAtIndex:beginIndex effectiveRange:NULL] objectForKey:BlockeditAttributeName]==nil;
    NSDictionary *blockeditAttributes=[[self delegate] blockeditAttributesForTextView:self];
    NSDictionary *tempAttributes=blockeditAttributes;
    if (!isAddingBlockeditRanges) {
        tempAttributes = [NSDictionary dictionaryWithObject:[self backgroundColor] forKey:NSBackgroundColorAttributeName];
    }

    blockeditRange=[string lineRangeForRange:NSMakeRange(beginIndex,0)];
    [layoutManager addTemporaryAttributes:tempAttributes
                        forCharacterRange:blockeditRange];

    NSEvent *leftMouseDraggedEvent = nil;
    while (YES) {
        NSRange intersectionRange;
        aEvent=[[self window] nextEventMatchingMask:(NSLeftMouseDraggedMask|NSLeftMouseUpMask|NSPeriodicMask)];

        if ([aEvent type] == NSLeftMouseDragged) {
            [leftMouseDraggedEvent release];
             leftMouseDraggedEvent=[aEvent retain];
            BOOL hitsContent=[self mouse:[self convertPoint:[aEvent locationInWindow] fromView:nil] 
                                  inRect:[self visibleRect]];
            if (timerOn) {
                if (hitsContent) {
                    [NSEvent stopPeriodicEvents];
                    timerOn=NO;
                }
            } else {
                if (!hitsContent) {
                    [NSEvent startPeriodicEventsAfterDelay:0.1 withPeriod:0.1];
                    timerOn=YES;
                }
            }
        }
        
        if ([aEvent type] == NSPeriodic) {
            [self autoscroll:leftMouseDraggedEvent];
        } 
        
        if ([aEvent type] == NSLeftMouseUp) {
            if ([textStorage length]>0) {
                [textStorage setHasBlockeditRanges:YES];
                [NSEvent stopPeriodicEvents];
                [leftMouseDraggedEvent release];
                 leftMouseDraggedEvent = nil;
                if (isAddingBlockeditRanges) {
                    [textStorage addAttributes:blockeditAttributes
                                         range:blockeditRange];
                } else {
                    [textStorage removeAttributes:[blockeditAttributes allKeys]
                                            range:blockeditRange];
                }
                [layoutManager removeTemporaryAttributes:[tempAttributes allKeys]
                                       forCharacterRange:blockeditRange];
                // evil hack for unpause
                [[self delegate] textViewDidChangeSelection:nil];
            }
            break;
        } else {
            currentPoint = [self convertPoint:[leftMouseDraggedEvent locationInWindow] fromView:nil];
            glyphIndex =[layoutManager glyphIndexForPoint:currentPoint 
                                          inTextContainer:[self textContainer]]; 
            characterIndex=[layoutManager characterIndexForGlyphAtIndex:glyphIndex];
            tempRange=[string lineRangeForRange:SPANNINGRANGE(beginIndex,characterIndex)];

            if (!NSEqualRanges(blockeditRange,tempRange)) {
                if (blockeditRange.location!=tempRange.location) {
                    if (blockeditRange.location>tempRange.location) {
                        intersectionRange.location=tempRange.location;
                        intersectionRange.length=blockeditRange.location-tempRange.location;
                        [layoutManager addTemporaryAttributes:tempAttributes
                                            forCharacterRange:intersectionRange];
                    } else {
                        intersectionRange.location=blockeditRange.location;
                        intersectionRange.length=tempRange.location-blockeditRange.location;
                        [layoutManager removeTemporaryAttributes:[tempAttributes allKeys]
                                               forCharacterRange:intersectionRange];
                    }
                }
                if (NSMaxRange(blockeditRange)!=NSMaxRange(tempRange)) {
                    if (NSMaxRange(blockeditRange)<NSMaxRange(tempRange)) {
                        intersectionRange.location=NSMaxRange(blockeditRange);
                        intersectionRange.length=NSMaxRange(tempRange)-NSMaxRange(blockeditRange);
                        [layoutManager addTemporaryAttributes:tempAttributes
                                            forCharacterRange:intersectionRange];
                    } else {
                        intersectionRange.location=NSMaxRange(tempRange);
                        intersectionRange.length  =NSMaxRange(blockeditRange)-NSMaxRange(tempRange);
                        [layoutManager removeTemporaryAttributes:[tempAttributes allKeys]
                                               forCharacterRange:intersectionRange];
                    }
                }
                blockeditRange=tempRange;
            }
        }
    }
}

- (void)mouseDown:(NSEvent *)aEvent {
    if ([[self delegate] respondsToSelector:@selector(textView:mouseDidGoDown:)]) {
        [[self delegate] textView:self mouseDidGoDown:aEvent];
    }
    
    if (([aEvent modifierFlags] & NSAlternateKeyMask) && [self isEditable]) {
        [self trackMouseForBlockeditWithEvent:aEvent];
    } else {
        [super mouseDown:aEvent]; 
    }
}

- (BOOL)dragSelectionWithEvent:(NSEvent *)event offset:(NSSize)mouseOffset slideBack:(BOOL)slideBack {
    I_flags.isDraggingText = YES;
    return [super dragSelectionWithEvent:event offset:mouseOffset slideBack:slideBack];
}

// make sure our document gets the font change
- (void)changeFont:(id)aSender {
#if defined(CODA)
	[[editor document] changeFontInteral:aSender];
#else
    [[self document] changeFont:aSender];
#endif //defined(CODA)
}


- (void)drawInsertionPointWithColor:(NSColor *)aColor atPoint:(NSPoint)aPoint {
    //NSLog(@"draw ins point (%f,%f)", aPoint.x, aPoint.y);
    aPoint.x = round(aPoint.x) + .5 ; aPoint.y = round(aPoint.y) - .5;
    NSBezierPath *caretPath = [NSBezierPath bezierPath];
    [caretPath moveToPoint:NSMakePoint(aPoint.x,aPoint.y-2)];
    [caretPath lineToPoint:NSMakePoint(aPoint.x+2,aPoint.y)];
    [caretPath lineToPoint:NSMakePoint(aPoint.x+3,aPoint.y-1)];
    [caretPath lineToPoint:NSMakePoint(aPoint.x,aPoint.y-4)];
    [caretPath lineToPoint:NSMakePoint(aPoint.x-3,aPoint.y-1)];
    [caretPath lineToPoint:NSMakePoint(aPoint.x-2,aPoint.y)];
    [caretPath closePath];
    [aColor set];

    BOOL shouldAntialias = [[NSGraphicsContext currentContext] shouldAntialias];
    [[NSGraphicsContext currentContext] setShouldAntialias:NO];
    [caretPath fill];
    //[caretPath stroke];
    [[NSGraphicsContext currentContext] setShouldAntialias:shouldAntialias];
}

- (void)drawViewBackgroundInRect:(NSRect)aRect {
    [super drawViewBackgroundInRect:aRect];
    if (I_pageGuidePosition > 0) {
        [[NSColor colorWithCalibratedWhite:.5 alpha:0.2] set];
        NSRect rectToFill=[self bounds];
        rectToFill.origin.x = I_pageGuidePosition;
        [NSBezierPath fillRect:rectToFill];
    }
}

- (void)drawRect:(NSRect)aRect {
    [super drawRect:aRect];
    // now paint Cursors if there are any
    PlainTextDocument *document=(PlainTextDocument *)[editor document];
    TCMMMSession *session=[document session];
    NSString *sessionID=[session sessionID];
    NSDictionary *sessionParticipants=[session participants];
    NSEnumerator *participants = [[sessionParticipants objectForKey:@"ReadWrite"] objectEnumerator];
    TCMMMUser *user;
    TCMMMUser *me=[TCMMMUserManager me];

    FoldableTextStorage *ts = (FoldableTextStorage *)[self textStorage];

#if defined(CODA)
	NSSize textOffset = [self textContainerInset]; 
#endif //defined(CODA)

    if (document) {
        while ((user=[participants nextObject])) {
            if (user != me) {
                SelectionOperation *selectionOperation= [[user propertiesForSessionID:sessionID] objectForKey:@"SelectionOperation"];
                if (selectionOperation) {
                    NSRange selectionRange = [ts foldedRangeForFullRange:[selectionOperation selectedRange]];
                    if (selectionRange.length==0) {
                        // now we have to paint a caret at position
        //                NSRange selection = NSMakeRange((unsigned)[(NSNumber *)[selection objectAtIndex:0] unsignedIntValue],0);
        
                        NSUInteger rectCount;
                        NSRectArray rectArray=[[self layoutManager] 
                                                    rectArrayForCharacterRange:selectionRange 
                                                    withinSelectedCharacterRange:selectionRange 
                                                    inTextContainer:[self textContainer] rectCount:&rectCount];
                        NSColor *changeColor=[[user changeColor] shadowWithLevel:0.1];
                                                
                        if (rectCount>0) {
                            NSPoint myPoint = rectArray[0].origin;
#if defined(CODA)
					        myPoint.x -= (0.5 + textOffset.width); 
                            myPoint.y += (rectArray[0].size.height - 0.5 + textOffset.height);
#else
                            myPoint.x -= 0.5;
                            myPoint.y += rectArray[0].size.height - 0.5;
#endif //defined(CODA)
                            [self drawInsertionPointWithColor:changeColor atPoint:myPoint];
                        }
                    }
                }
            }
        }
    }

    if (I_isDragTarget) {
        [[[NSColor selectedTextBackgroundColor] colorWithAlphaComponent:0.5] set];
        NSBezierPath *path=[NSBezierPath bezierPathWithRect:NSInsetRect([self bounds],2,2)];
#if defined(CODA)
		// need to set-up the clip to over-ride the systems clipping of the text view
		[NSGraphicsContext saveGraphicsState];
		[[NSBezierPath bezierPathWithRect:[self visibleRect]] setClip];
#endif //defined(CODA)
        [path setLineWidth:4.];
        [path setLineJoinStyle:NSRoundLineCapStyle];
        [path stroke];
#if defined(CODA)
		[NSGraphicsContext restoreGraphicsState];
#endif //defined(CODA)
    }
}

- (BOOL)usesFindPanel 
{
    return YES;
}

- (void)performFindPanelAction:(id)sender 
{
    [[FindReplaceController sharedInstance] performFindPanelAction:sender forTextView:self];
}

-(BOOL)validateMenuItem:(NSMenuItem*)menuItem 
{
	SEL action = [menuItem action];
    BOOL returnValue = [super validateMenuItem:menuItem];
    if (!returnValue) {
        if ([menuItem tag]==1001) returnValue=YES;
        if ([menuItem tag]==1002) returnValue=YES;
    }
    if (returnValue && action == @selector(copyStyled:)) {
        return [self selectedRange].length>0;
    }
    
    if ( action == @selector(foldAllTopLevelBlocks:) ) {
	    PlainTextDocument *document=(PlainTextDocument *)[editor document];
    	[menuItem setTitle:[NSString stringWithFormat:NSLocalizedString(@"Fold All Level %d Blocks","Fold at top level menu entry label"),MAX(1,[[[document documentMode] syntaxDefinition] foldingTopLevel])]];
    }
    
    if ( action == @selector(foldAllTopLevelBlocks:) || 
         action == @selector(foldAllBlocksAtTagLevel:) || 
         action == @selector(foldCurrentBlock:) || 
         action == @selector(foldAllCommentBlocks:) ||
         action == @selector(foldAllBlocksAtCurrentLevel:) ) {
	    PlainTextDocument *document=(PlainTextDocument *)[editor document];
	    DocumentMode *mode = [document documentMode];
    	BOOL hasFoldingInformation = [mode syntaxHighlighter] && [document highlightsSyntax];
    	returnValue = hasFoldingInformation;
    }
    
    if (action == @selector(toggleGrammarChecking:) ||
        action == @selector(toggleAutomaticSpellingCorrection:) ||
        action == @selector(toggleAutomaticLinkDetection:) ||
        action == @selector(toggleAutomaticDashSubstitution:) ||
        action == @selector(toggleAutomaticQuoteSubstitution:) ||
        action == @selector(toggleAutomaticTextReplacement:)) {
        returnValue = [NSTextView instancesRespondToSelector:action];
    }
    
    return returnValue;
}

- (NSMenu *)menuForEvent:(NSEvent *)anEvent {
    NSMenu *menu = [super menuForEvent:anEvent];
    id delegate = [self delegate];
    if ([delegate respondsToSelector:@selector(textViewContextMenuNeedsUpdate:)]) {
        [delegate textViewContextMenuNeedsUpdate:menu];
    }
    return menu;
}

- (void)resetCursorRects {
    // disable cursor rects and therefore mouse cursor changing when we have a dark background so the documentcursor is used
    if ([[self insertionPointColor] isDark]) [super resetCursorRects];
}

- (NSRange)selectionRangeForProposedRange:(NSRange)proposedSelRange granularity:(NSSelectionGranularity)granularity {
    NSEvent *currentEvent=[NSApp currentEvent];
    NSEventType type = [currentEvent type];
    if (currentEvent && (type==NSLeftMouseDown || type==NSLeftMouseUp)) {
        NSInteger clickCount = [currentEvent clickCount];
        NSTextStorage *ts = [self textStorage];
        NSRange wholeRange = NSMakeRange(0,[ts length]);
        if (clickCount == 3) {
            NSRange lineRange = [[ts string] lineRangeForRange:proposedSelRange];
            // select area that belongs to a style
            NSUInteger index = [self characterIndexForPoint:[[self window] convertBaseToScreen:[[NSApp currentEvent] locationInWindow]]];
            NSRange resultRange = lineRange;
            if (index != NSNotFound && index < NSMaxRange(wholeRange)) {
                [ts attribute:kSyntaxHighlightingScopenameAttributeName atIndex:index longestEffectiveRange:&resultRange inRange:wholeRange];
                return RangeConfinedToRange(resultRange,lineRange);
            }
        } else if (clickCount >= 5) {
            return wholeRange;
        }
    }
    return [super selectionRangeForProposedRange:proposedSelRange granularity:granularity];
}

- (void)selectFullRangeAppropriateAfterFolding:(NSRange)aFullRange {
	// first get foldedRange:
	FoldableTextStorage *textStorage = (FoldableTextStorage *)[self textStorage];
	NSRange foldedRange = [textStorage foldedRangeForFullRange:aFullRange];

	// then select and scroll to
	[self setSelectedRange:foldedRange];
	[self scrollRangeToVisible:foldedRange];
}

- (IBAction)foldTextSelection:(id)aSender {
	NSRange selectedRange = [self selectedRange];
	if (selectedRange.length > 0) {
		FoldableTextStorage *ts = (FoldableTextStorage *)[self textStorage];
		[ts foldRange:selectedRange];
		NSScrollView *scrollView = [self enclosingScrollView];
		if ([scrollView rulersVisible]) {
			[[scrollView verticalRulerView] setNeedsDisplay:YES];
		}
	} else {
		NSBeep();
	}
}

- (IBAction)foldCurrentBlock:(id)aSender {
	FoldableTextStorage *textStorage = (FoldableTextStorage *)[self textStorage];
	NSRange mySelectedRange = [self selectedRange];
	
	NSRange foldedRange = NSMakeRange(NSNotFound,0);
	
	NSRange foldableCommentRange = [textStorage foldableCommentRangeForCharacterAtIndex:mySelectedRange.location];
	if (foldableCommentRange.location != NSNotFound && foldableCommentRange.length > 0) {
		foldedRange = foldableCommentRange;
		[textStorage foldRange:foldedRange];
	} else {
		NSRange selectedRange = [textStorage fullRangeForFoldedRange:mySelectedRange];
		NSRange fullRangeToFold = [[textStorage fullTextStorage] foldableRangeForCharacterAtIndex:selectedRange.location]; 
		if (fullRangeToFold.location != NSNotFound) {
			NSRange foldableRangeToFold = [textStorage foldedRangeForFullRange:fullRangeToFold];
			foldedRange = foldableRangeToFold;
			[textStorage foldRange:foldedRange];
		} else {
			NSBeep();
		}
	}

	if (foldedRange.location != NSNotFound) { // some folding happenend
		// select the first character in front of the start of the current folding if possible
		NSRange rangeToSelect = NSMakeRange(0,0);
		if (foldedRange.location > 0) {
			NSRange startRange = NSMakeRange(foldedRange.location-1,0);
			id startAttribute = [textStorage attribute:kSyntaxHighlightingFoldDelimiterName atIndex:startRange.location longestEffectiveRange:&startRange inRange:NSMakeRange(0,foldedRange.location)];
			if ([startAttribute isEqualToString:kSyntaxHighlightingStateDelimiterStartValue]) {
				NSRange startWithSameDepthRange = NSMakeRange(NSMaxRange(startRange)-1,0);
				/*id depthValue =*/ [textStorage attribute:kSyntaxHighlightingFoldingDepthAttributeName atIndex:startWithSameDepthRange.location longestEffectiveRange:&startWithSameDepthRange inRange:startRange];
				rangeToSelect.location = startWithSameDepthRange.location;
				if (rangeToSelect.location > [[textStorage string] lineRangeForRange:rangeToSelect].location) {
					rangeToSelect.location -= 1;
				}
				[self setSelectedRange:rangeToSelect];
				[self scrollRangeToVisible:rangeToSelect];
			}
		}

		NSScrollView *scrollView = [self enclosingScrollView];
		if ([scrollView rulersVisible]) {
			[[scrollView verticalRulerView] setNeedsDisplay:YES];
		}
	}
}

- (IBAction)unfoldCurrentBlock:(id)aSender {
	NSRange selectedRange = [self selectedRange];
	FoldableTextStorage *textStorage = (FoldableTextStorage *)[self textStorage];
	NSRange fullRangeOfSelection = [textStorage fullRangeForFoldedRange:selectedRange];

	if (![textStorage unfoldFoldingForPosition:selectedRange.location]) {
		NSBeep();
	} else {
		[self selectFullRangeAppropriateAfterFolding:fullRangeOfSelection];
	}
}

- (IBAction)foldAllCommentBlocks:(id)aSender {
	NSRange selectedRange = [self selectedRange];
	FoldableTextStorage *textStorage = (FoldableTextStorage *)[self textStorage];
	NSRange fullRangeOfSelection = [textStorage fullRangeForFoldedRange:selectedRange];

	[textStorage foldAllComments];

	[self selectFullRangeAppropriateAfterFolding:fullRangeOfSelection];
}

- (IBAction)unfoldAllBlocks:(id)aSender {
	NSRange selectedRange = [self selectedRange];
	FoldableTextStorage *textStorage = (FoldableTextStorage *)[self textStorage];
	NSRange fullRangeOfSelection = [textStorage fullRangeForFoldedRange:selectedRange];

	[textStorage unfoldAll];

	[self selectFullRangeAppropriateAfterFolding:fullRangeOfSelection];
}

- (IBAction)foldAllTopLevelBlocks:(id)aSender {
	NSRange selectedRange = [self selectedRange];
	FoldableTextStorage *textStorage = (FoldableTextStorage *)[self textStorage];
	NSRange fullRangeOfSelection = [textStorage fullRangeForFoldedRange:selectedRange];
    PlainTextDocument *document=(PlainTextDocument *)[editor document];
	[textStorage foldAllWithFoldingLevel:[[[document documentMode] syntaxDefinition] foldingTopLevel]];
	[self selectFullRangeAppropriateAfterFolding:fullRangeOfSelection];
}

- (IBAction)foldAllBlocksAtTagLevel:(id)aSender {
	int level = [aSender tag];
	if (level > 0) {
		NSRange selectedRange = [self selectedRange];
		FoldableTextStorage *textStorage = (FoldableTextStorage *)[self textStorage];
		NSRange fullRangeOfSelection = [textStorage fullRangeForFoldedRange:selectedRange];
		[textStorage foldAllWithFoldingLevel:level];
		[self selectFullRangeAppropriateAfterFolding:fullRangeOfSelection];
	}
}

- (IBAction)foldAllBlocksAtCurrentLevel:(id)aSender {
	NSRange selectedRange = [self selectedRange];
	FoldableTextStorage *textStorage = (FoldableTextStorage *)[self textStorage];
	NSRange fullRangeOfSelection = [textStorage fullRangeForFoldedRange:selectedRange];

	unsigned int location = selectedRange.location;
	unsigned int length = [textStorage length];
	if (length > 0) {
		if (location >= length) {
			location--;
		}
		int currentLevel = [[textStorage attribute:kSyntaxHighlightingFoldingDepthAttributeName atIndex:location effectiveRange:NULL] intValue];
		[textStorage foldAllWithFoldingLevel:currentLevel];

		[self selectFullRangeAppropriateAfterFolding:fullRangeOfSelection];
	}
}


- (void)setBackgroundColor:(NSColor *)aColor {
    BOOL wasDark = [[self backgroundColor] isDark];
    BOOL isDark = [aColor isDark];
    [super setBackgroundColor:aColor];
    [self setInsertionPointColor:isDark?[NSColor whiteColor]:[NSColor blackColor]];
    [self setSelectedTextAttributes:[NSDictionary dictionaryWithObject:isDark?[[NSColor selectedTextBackgroundColor] brightnessInvertedSelectionColor]:[NSColor selectedTextBackgroundColor] forKey:NSBackgroundColorAttributeName]];
    [[self enclosingScrollView] setDocumentCursor:isDark?[NSCursor invertedIBeamCursor]:[NSCursor IBeamCursor]];
    if (( wasDark && !isDark) || 
        (!wasDark &&  isDark)) {
#if !defined(CODA)
        // remove and add from Superview to activiate my cursor rect and deactivate the ones of the TextView
        NSScrollView *sv = [[[self enclosingScrollView] retain] autorelease];
        NSView *superview = [sv superview];
        [sv removeFromSuperview];
        [superview addSubview:sv];
#endif //!defined(CODA)
    }
#if !defined(CODA)
    [[self window] invalidateCursorRectsForView:self];
#endif //!defined(CODA)
}

- (void)toggleContinuousSpellChecking:(id)sender {
    [super toggleContinuousSpellChecking:sender];
    if ([[self delegate] respondsToSelector:@selector(textViewDidChangeSpellCheckingSetting:)]) {
        [[self delegate] textViewDidChangeSpellCheckingSetting:self];
    }
}

- (void)toggleGrammarChecking:(id)sender {
	[super toggleGrammarChecking:sender];
    if ([[self delegate] respondsToSelector:@selector(textViewDidChangeSpellCheckingSetting:)]) {
        [[self delegate] textViewDidChangeSpellCheckingSetting:self];
    }
}

- (void)toggleAutomaticSpellingCorrection:(id)sender {
	[super toggleAutomaticSpellingCorrection:sender];
    if ([[self delegate] respondsToSelector:@selector(textViewDidChangeSpellCheckingSetting:)]) {
        [[self delegate] textViewDidChangeSpellCheckingSetting:self];
    }
}


- (void)toggleAutomaticLinkDetection:(id)sender {
	[super toggleAutomaticLinkDetection:sender];
    if ([[self delegate] respondsToSelector:@selector(textViewDidChangeSpellCheckingSetting:)]) {
        [[self delegate] textViewDidChangeSpellCheckingSetting:self];
    }
}

- (void)toggleAutomaticDashSubstitution:(id)sender {
	[super toggleAutomaticDashSubstitution:sender];
    if ([[self delegate] respondsToSelector:@selector(textViewDidChangeSpellCheckingSetting:)]) {
        [[self delegate] textViewDidChangeSpellCheckingSetting:self];
    }
}

- (void)toggleAutomaticQuoteSubstitution:(id)sender {
	[super toggleAutomaticQuoteSubstitution:sender];
    if ([[self delegate] respondsToSelector:@selector(textViewDidChangeSpellCheckingSetting:)]) {
        [[self delegate] textViewDidChangeSpellCheckingSetting:self];
    }
}

- (void)toggleAutomaticTextReplacement:(id)sender {
	[super toggleAutomaticTextReplacement:sender];
    if ([[self delegate] respondsToSelector:@selector(textViewDidChangeSpellCheckingSetting:)]) {
        [[self delegate] textViewDidChangeSpellCheckingSetting:self];
    }
}

- (void)complete:(id)sender {
    FoldableTextStorage *textStorage=(FoldableTextStorage *)[self textStorage];
    if ([textStorage hasBlockeditRanges]) {
        NSEvent *event=[NSApp currentEvent];
        // 53 is the escape key
        if ( ([event type]==NSKeyDown || [event type]==NSKeyUp) && [event keyCode]==53 && 
             !([event modifierFlags] & (NSControlKeyMask | NSAlternateKeyMask | NSCommandKeyMask | NSShiftKeyMask)) ) {
//            NSLog(@"keyCode: %d, characters: %@, modifierFlags:%d, %@",
//                    [event keyCode], [event characters], [event modifierFlags],
//                    [event description]);
            [self tryToPerform:@selector(endBlockedit:) with:nil];
			return;
        } else {
            unsigned index=[self selectedRange].location;
            if (index >= [textStorage length]) {
                index=[textStorage length];
                if (index) index--;
                else return;
            }
            if ([textStorage attribute:BlockeditAttributeName atIndex:index effectiveRange:nil]) {
                NSBeep();
                return;
            }
        }
    }

    I_flags.shouldCheckCompleteStart=YES;
    //I_flags.autoCompleteInProgress=YES; // Temporarliy disabled (SEE-874)
#if !defined(CODA)
    [super complete:sender]; 
#endif //!defined(CODA)
}

- (NSArray *)completionsForPartialWordRange:(NSRange)charRange indexOfSelectedItem:(NSInteger *)index {
    NSArray *result=[super completionsForPartialWordRange:charRange indexOfSelectedItem:index];
    if (I_flags.shouldCheckCompleteStart) {
        if ([result count]) {
            if ([[self delegate] respondsToSelector:@selector(textViewWillStartAutocomplete:)]) {
                [[self delegate] textViewWillStartAutocomplete:self];
            }
        } else {
            NSBeep();
            I_flags.autoCompleteInProgress=NO;
        }
        
        if ([result count]<2) {
            I_flags.autoCompleteInProgress=NO;
        }
        
        I_flags.shouldCheckCompleteStart=NO;
    }
    return result;
}

#define APPKIT10_3 743

- (void)insertCompletion:(NSString *)word forPartialWordRange:(NSRange)charRange movement:(NSInteger)movement isFinal:(BOOL)flag {
    [super insertCompletion:word forPartialWordRange:charRange movement:movement isFinal:flag];
    if (flag) {
        //NSLog(@"%f",NSAppKitVersionNumber);
        if (floor(NSAppKitVersionNumber) <= APPKIT10_3 && charRange.length==1) {
            // Documented bug in 10.3.x so work around it
            [self setSelectedRange:charRange];
            [self insertText:word];
            [self setSelectedRange:NSMakeRange(charRange.location,[word length])];
        }
        if ([[self delegate] respondsToSelector:@selector(textView:didFinishAutocompleteByInsertingCompletion:forPartialWordRange:movement:)]) {
            [[self delegate] textView:self didFinishAutocompleteByInsertingCompletion:word forPartialWordRange:charRange movement:movement];
        }

        NSEvent *event=[NSApp currentEvent];
        if ((([event type]==NSKeyDown || [event type]==NSKeyUp))&&(([event keyCode]==36) || ([event keyCode]==76) || ([event keyCode]==53) || ([event keyCode]==49) || ([event keyCode]==48))) {I_flags.autoCompleteInProgress=NO;}

    }

}

- (IBAction)copyStyled:(id)aSender {
    [self setRichText:YES];
    [self copy:aSender];
    [self setRichText:NO];
}

- (IBAction)copy:(id)aSender {
	NSRange selectedRange = [self selectedRange];
	if (selectedRange.length == 0) return;
	
	NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
	BOOL isRichText = [self isRichText];
	
	[pasteboard declareTypes:(isRichText ? [NSArray arrayWithObjects:NSRTFDPboardType,NSRTFPboardType,nil] : [NSArray arrayWithObjects:NSStringPboardType,nil]) owner:nil];
	
	if (isRichText) {
		id textStorage = [self textStorage];
		if ([textStorage respondsToSelector:@selector(fullRangeForFoldedRange:)]) {
			selectedRange = [textStorage fullRangeForFoldedRange:selectedRange];
			textStorage = [textStorage fullTextStorage];
		}
		NSMutableAttributedString *mutableString = [[[[self textStorage] attributedSubstringFromRange:[self selectedRange]] mutableCopy] autorelease];
		NSTextAttachment *foldingIconAttachment = [[[NSTextAttachment alloc] initWithFileWrapper:[[[NSFileWrapper alloc] initWithPath:[[NSBundle mainBundle] pathForResource:@"FoldingBubbleBig" ofType:@"png"]] autorelease]] autorelease];
//		[[[foldingIconAttachment attachmentCell] image] setSize:NSMakeSize(19,10)];
		NSAttributedString *foldingIconString = [NSAttributedString attributedStringWithAttachment:foldingIconAttachment];
		NSAttributedString *foldingIconReplacementString = [[[NSAttributedString alloc] initWithPath:[[NSBundle mainBundle] pathForResource:@"FoldingBubbleText" ofType:@"rtf"] documentAttributes:nil] autorelease];
		[mutableString replaceAttachmentsWithAttributedString:foldingIconString];
		[pasteboard setData:[mutableString RTFDFromRange:NSMakeRange(0,[mutableString length]) documentAttributes:nil] forType:NSRTFDPboardType];
		[mutableString replaceAttachmentsWithAttributedString:foldingIconReplacementString];
		[pasteboard setData:[mutableString  RTFFromRange:NSMakeRange(0,[mutableString length]) documentAttributes:nil] forType:NSRTFPboardType];
	} else {
		[self writeSelectionToPasteboard:pasteboard type:NSStringPboardType];
	}
}

- (NSArray *)writablePasteboardTypes {
	NSMutableArray *result = [NSArray arrayWithObject:NSStringPboardType];
	return result;
}

- (BOOL)writeSelectionToPasteboard:(NSPasteboard *)pasteboard type:(NSString *)type {
	if ([type isEqualToString:NSStringPboardType]) {
		NSRange selectedRange = [self selectedRange];
		if (selectedRange.length == 0) return NO;
		
		id textStorage = [self textStorage];
		if ([textStorage respondsToSelector:@selector(fullRangeForFoldedRange:)]) {
			selectedRange = [textStorage fullRangeForFoldedRange:selectedRange];
			textStorage = [textStorage fullTextStorage];
		}
		
		[pasteboard setString:[[textStorage string] substringWithRange:selectedRange] forType:NSStringPboardType];		
		return YES;
	}
	return NO;
}

#pragma mark Folding Related Methods
- (void)scrollFullRangeToVisible:(NSRange)aRange {
	[self scrollRangeToVisible:[(FoldableTextStorage *)[self textStorage] foldedRangeForFullRange:aRange]];
}


#pragma mark -
#pragma mark ### dragging ###

- (void)setIsDragTarget:(BOOL)aFlag {
    if (aFlag != I_isDragTarget) {
        I_isDragTarget=aFlag;
        [self setNeedsDisplay:YES];
    }
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    NSPasteboard *pboard = [sender draggingPasteboard];
    if ([[pboard types] containsObject:@"PboardTypeTBD"]) {
        //NSLog(@"draggingEntered:");
        PlainTextDocument *document=(PlainTextDocument *)[editor document];
        TCMMMSession *session=[document session];
        if ([session isServer]) {
            [[[self window] drawers] makeObjectsPerformSelector:@selector(open)];
            [self setIsDragTarget:YES];
            return NSDragOperationGeneric;
        }
    } else if ([[pboard types] containsObject:@"ParticipantDrag"]) {
        if ([[sender draggingSource] isKindOfClass:[ParticipantsView class]] && 
            [[sender draggingSource] windowController]==[[self window] windowController]) {
            [self setIsDragTarget:YES];
            return NSDragOperationGeneric;
        }
    } else if ([[pboard types] containsObject:@"PresentityNames"] ||
			   [[pboard types] containsObject:@"IMHandleNames"]) {
        BOOL shouldDrag=[[(PlainTextDocument *)[self document] session] isServer];
        if (shouldDrag) {
            [self setIsDragTarget:YES];
            return NSDragOperationGeneric;
        }
    }
    [self setIsDragTarget:NO];
    return [super draggingEntered:sender];
}

- (void)draggingExited:(id <NSDraggingInfo>)sender {
    [self setIsDragTarget:NO];
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender {
    NSPasteboard *pboard = [sender draggingPasteboard];
    if ([[pboard types] containsObject:@"PboardTypeTBD"]) {
        //NSLog(@"draggingUpdated:");
        BOOL shouldDrag=[[(PlainTextDocument *)[editor document] session] isServer];
        [self setIsDragTarget:shouldDrag];
        if (shouldDrag) {
            return NSDragOperationGeneric;
        }
    } else if ([[pboard types] containsObject:@"ParticipantDrag"]) {
        if ([[sender draggingSource] isKindOfClass:[ParticipantsView class]] && 
            [[sender draggingSource] windowController]==[[self window] windowController]) {
            [self setIsDragTarget:YES];
            return NSDragOperationGeneric;
        }
    } else if ([[pboard types] containsObject:@"PresentityNames"] ||
			   [[pboard types] containsObject:@"IMHandleNames"]) {
        // perform this by selector to not create dependency on TCMPortMapper
        BOOL shouldDrag=[[(PlainTextDocument *)[self document] session] isServer];
        if (shouldDrag) {
            [self setIsDragTarget:YES];
            return NSDragOperationGeneric;
        }
    }
 
    [self setIsDragTarget:NO];
    return [super draggingUpdated:sender];
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender {
    NSPasteboard *pboard = [sender draggingPasteboard];
    if ([[pboard types] containsObject:@"PboardTypeTBD"]) {
        //NSLog(@"prepareForDragOperation:");
        BOOL shouldDrag=[[(PlainTextDocument *)[editor document] session] isServer];
        [self setIsDragTarget:shouldDrag];
        return shouldDrag;
    } else if ([[pboard types] containsObject:@"ParticipantDrag"]) {
        if ([[sender draggingSource] isKindOfClass:[ParticipantsView class]] && 
            [[[sender draggingSource] window] windowController]==[[self window]  windowController]) {
            return YES;
        }
    } else if ([[pboard types] containsObject:@"PresentityNames"] ||
			   [[pboard types] containsObject:@"IMHandleNames"]) {
        BOOL shouldDrag=[[(PlainTextDocument *)[self document] session] isServer];
        [self setIsDragTarget:YES];
        if (shouldDrag) {
            [(PlainTextDocument *)[self document] setIsAnnounced:YES];
            return YES;
        }
    }

    
    return [super prepareForDragOperation:sender];
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
    NSPasteboard *pboard = [sender draggingPasteboard];
    if ([[pboard types] containsObject:@"PboardTypeTBD"]) {
        //NSLog(@"performDragOperation:");
        NSArray *userArray=[pboard propertyListForType:@"PboardTypeTBD"];
        PlainTextDocument *document=(PlainTextDocument *)[editor document];
        TCMMMSession *session=[document session];
        NSDictionary *userDescription=nil;
        for (userDescription in userArray) {
            TCMMMUser *user=[[TCMMMUserManager sharedInstance] userForUserID:[userDescription objectForKey:@"UserID"]];
            if (user) {
                TCMBEEPSession *BEEPSession=[[TCMMMBEEPSessionManager sharedInstance] sessionForUserID:[user userID] peerAddressData:[userDescription objectForKey:@"PeerAddressData"]];
                [document setPlainTextEditorsShowChangeMarksOnInvitation];
                [session inviteUser:user intoGroup:@"ReadWrite" usingBEEPSession:BEEPSession];
            }
        }
        [self setIsDragTarget:NO];
        return YES;
    } else if ([[pboard types] containsObject:@"ParticipantDrag"]) {
        if ([[sender draggingSource] isKindOfClass:[ParticipantsView class]] && 
            [[sender draggingSource] windowController]==[[self window] windowController]) {
            PlainTextWindowController *controller=[[self window] windowController];
            [controller performSelector:@selector(followUser:) withObject:self];
            [self setIsDragTarget:NO];
            return YES;
        }
    } else if ([[pboard types] containsObject:@"PresentityNames"] ||
			   [[pboard types] containsObject:@"IMHandleNames"]) {
        BOOL shouldDrag=[[(PlainTextDocument *)[self document] session] isServer];
        [self setIsDragTarget:YES];
        if (shouldDrag) {
            [ConnectionBrowserController invitePeopleFromPasteboard:pboard intoDocument:[self document] group:TCMMMSessionReadWriteGroupName];
            [self setIsDragTarget:NO];
            return YES;
        }
    }

    [self setIsDragTarget:NO];
    PlainTextDocument *document=nil;
    if (I_flags.isDraggingText) {
            document=(PlainTextDocument *)[self document];
        [[document documentUndoManager] beginUndoGrouping];
    }
    BOOL result = [super performDragOperation:sender];
    if (I_flags.isDraggingText) {
        I_flags.isDraggingText = NO;
        [[document documentUndoManager] endUndoGrouping];
    }
    return result;
}

- (NSArray *)acceptableDragTypes {
    NSMutableArray *dragTypes=[[super acceptableDragTypes] mutableCopy];
    [dragTypes addObject:@"PboardTypeTBD"];
    [dragTypes addObject:@"ParticipantDrag"];
    [dragTypes addObject:@"PresentityNames"];
    [dragTypes addObject:@"IMHandleNames"];
    return [dragTypes autorelease];
}

- (void)updateDragTypeRegistration {
    [super updateDragTypeRegistration];
    if (![self isEditable]) {
        [self registerForDraggedTypes:[NSArray arrayWithObject:@"ParticipantDrag"]];
    }
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender {
    NSPasteboard *pboard = [sender draggingPasteboard];
    if ([[pboard types] containsObject:@"PboardTypeTBD"] || [[pboard types] containsObject:@"ParticipantDrag"]) {
        //NSLog(@"concludeDragOperation:");
    } else {
        [super concludeDragOperation:sender];
    }
}

- (void)keyDown:(NSEvent *)aEvent {

    static NSCharacterSet *s_passThroughCharacterSet=nil;
    if (s_passThroughCharacterSet==nil) {
        s_passThroughCharacterSet=[[NSCharacterSet characterSetWithCharactersInString:@"1234567"] retain];
    }
    int flags=[aEvent modifierFlags];
    if ((flags & NSControlKeyMask) && !(flags & NSCommandKeyMask) && 
        [[aEvent characters] length]==1 &&
        [s_passThroughCharacterSet characterIsMember:[[aEvent characters] characterAtIndex:0]]) {
        id nextResponder=[self nextResponder];
        while (nextResponder) {
            if ([nextResponder isKindOfClass:[PlainTextEditor class]] &&
                [nextResponder respondsToSelector:@selector(keyDown:)]) {
//                NSLog(@"Weiter mit dir: %@, %@",nextResponder, aEvent);
                [[self nextResponder] keyDown:aEvent];
                return;
            }
            nextResponder=[nextResponder nextResponder];
        }
    }
        
    [super keyDown:aEvent];
        
    if (I_flags.autoCompleteInProgress) {
        if ([self selectedRange].location>1) {
            if ([aEvent keyCode]==51){
                [self setSelectedRange: NSMakeRange([self selectedRange].location-1,[self selectedRange].length+1)];
            }
            [self complete:self];
        } else I_flags.autoCompleteInProgress=NO;
    }

}

- (NSRange)rangeForUserCompletion {
    NSRange result=[super rangeForUserCompletion];
    NSString *string=[[self textStorage] string];
	DocumentMode *theMode = [[self document] documentMode];
	
	unsigned int characterIndex = result.location;
	unsigned int stringLength = [string length];
	if ( characterIndex < stringLength || 
		 (characterIndex == stringLength && characterIndex > 0) ) {
		if (characterIndex == stringLength) {
			characterIndex--;
		}
		NSString *modeForAutocomplete = [[self textStorage] attribute:kSyntaxHighlightingParentModeForAutocompleteAttributeName atIndex:characterIndex effectiveRange:NULL];
		if (modeForAutocomplete) {
			theMode = [[DocumentModeManager sharedInstance] documentModeForName:modeForAutocomplete];
		}
	}
	
	
    NSCharacterSet *tokenSet = [[[theMode syntaxHighlighter] syntaxDefinition] autoCompleteTokenSet];
	if (!tokenSet) tokenSet = [[[theMode syntaxHighlighter] syntaxDefinition] tokenSet];
    if (tokenSet) {
        result = [self selectedRange]; // Start with a fresh range
        while (YES) {
            if (result.location==0) break;
            NSString *aCharacter = [string substringWithRange:NSMakeRange(result.location-1,1)];
            if ([aCharacter rangeOfCharacterFromSet:tokenSet].location!=NSNotFound) {
                result = NSMakeRange(result.location-1,result.length+1);           
            } else break;
        }
    }
    
    NSLog(@"rangeForUserCompletion: %@ - %@ - %@",NSStringFromRange(result), [theMode documentModeIdentifier], tokenSet);
    return result;
}

#pragma mark -
#pragma mark ### handle ruler interaction ###

- (void)trackMouseForLineSelectionWithEvent:(NSEvent *)anEvent {
    BOOL wasShift = ([anEvent modifierFlags] & NSShiftKeyMask) != 0;
    NSString *textStorageString = [[self textStorage] string];
    if ([textStorageString length]==0) return;
    NSLayoutManager *layoutManager = [self layoutManager];
    NSTextContainer *textContainer = [self textContainer];
    NSPoint point = [self convertPoint:[anEvent locationInWindow] fromView:nil];
    point.x=5;
#if defined(CODA)
	point.y -= [self textContainerInset].height; 
#endif //defined(CODA)
    unsigned glyphIndex,endCharacterIndex,startCharacterIndex;
    glyphIndex=[layoutManager glyphIndexForPoint:point 
                                 inTextContainer:textContainer];
    endCharacterIndex = startCharacterIndex = [layoutManager characterIndexForGlyphAtIndex:glyphIndex];
    if (wasShift) {
        NSRange previousRange = [self selectedRange];
        if (previousRange.location <= startCharacterIndex) {
            startCharacterIndex = previousRange.location;
        } else {
            startCharacterIndex = NSMaxRange([self selectedRange]);
            if (startCharacterIndex != 0 && 
                (previousRange.length != 0 || startCharacterIndex == [textStorageString length]) ) startCharacterIndex--;
        }
    }
    NSRange selectedRange = [textStorageString lineRangeForRange:SPANNINGRANGE(startCharacterIndex, endCharacterIndex)];
    [self setSelectedRange:selectedRange];
    NSEvent *autoscrollEvent=nil;
    BOOL timerOn = NO;
    while (1) {
        NSEvent *event = [[self window] nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask | NSPeriodicMask)];
        switch ([event type]) {
            case NSPeriodic:
                if (autoscrollEvent) [self autoscroll:autoscrollEvent];
                event = autoscrollEvent;           
            case NSLeftMouseDragged:
                point = [self convertPoint:[event locationInWindow] fromView:nil];
#if defined(CODA)
				point.y -= [self textContainerInset].height; 
#endif //defined(CODA)
                glyphIndex = [layoutManager glyphIndexForPoint:point
                                               inTextContainer:textContainer];
                endCharacterIndex = [layoutManager characterIndexForGlyphAtIndex:glyphIndex];
                selectedRange = [textStorageString lineRangeForRange:SPANNINGRANGE(startCharacterIndex, endCharacterIndex)];
                if (!NSEqualRanges([self selectedRange], selectedRange)) {
                    [self setSelectedRange:selectedRange];
                }
                if ([self mouse:point inRect:[self visibleRect]]) {
                    if (timerOn) {
                        [NSEvent stopPeriodicEvents];
                        timerOn = NO;
                        [autoscrollEvent release];
                        autoscrollEvent = nil;
                    }
                } else {
                    if (timerOn) {
                        [autoscrollEvent release];
                         autoscrollEvent = [event retain];
                    } else {
                        [NSEvent startPeriodicEventsAfterDelay:0.1 withPeriod:0.1];
                        timerOn = YES;
                        [autoscrollEvent release];
                        autoscrollEvent = [event retain];
                    }
                }
            break;
                
            case NSLeftMouseUp:
                if (timerOn) {
                    [NSEvent stopPeriodicEvents];
                    timerOn = NO;
                    [autoscrollEvent release];
                    autoscrollEvent = nil;
                }
            return;
				
			default:
				break;
        }
    }
}

- (void)cursorUpdate:(NSEvent *)anEvent
{
    // ugly
    if ( [NSCursor currentCursor] == [NSCursor IBeamCursor] && 
         [[self backgroundColor] isDark]) {

        [[NSCursor invertedIBeamCursor] set];

    } else if ([NSCursor currentCursor] != [NSCursor invertedIBeamCursor] &&
               [super respondsToSelector:@selector(cursorUpdate:)] && !I_flags.isDoingUglyHack) {
		I_flags.isDoingUglyHack = YES;
		[super performSelector:@selector(cursorUpdate:) withObject:anEvent];
		I_flags.isDoingUglyHack = NO;
	}
}

- (void)mouseMoved:(NSEvent *)anEvent
{
	// ugly
    if ( [NSCursor currentCursor] == [NSCursor IBeamCursor] &&
         [[self backgroundColor] isDark] )  {

        [[NSCursor invertedIBeamCursor] set];

	} else if ([NSCursor currentCursor] != [NSCursor invertedIBeamCursor] &&
	           [super respondsToSelector:@selector(mouseMoved:)]) {
		[super mouseMoved:anEvent];
	}
}

// needs the textview to be delegate to the ruler
- (void)rulerView:(NSRulerView *)aRulerView handleMouseDown:(NSEvent *)anEvent {
    if (([anEvent modifierFlags] & NSAlternateKeyMask) && [self isEditable]) {
        [self trackMouseForBlockeditWithEvent:anEvent];
    } else {
        [self trackMouseForLineSelectionWithEvent:anEvent];
    }    
}

- (void)setEditor:(PlainTextEditor*)inEditor
{
	editor = inEditor; // XXX - avoid circular retain?
}

- (PlainTextEditor*)editor
{
	return editor;
}

@end
