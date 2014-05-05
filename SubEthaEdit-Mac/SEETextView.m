//
//  SEETextView.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Tue Apr 06 2004.
//  Copyright (c) 2004-2006 TheCodingMonkeys. All rights reserved.
//

// this file needs arc - either project wide,
// or add -fobjc-arc on a per file basis in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif


#import "LayoutManager.h"
#import "SEETextView.h"
#import "FoldableTextStorage.h"
#import "FullTextStorage.h"
#import "PlainTextDocument.h"
#import "TCMMMUserManager.h"
#import "TCMMMUser.h"
#import "TCMMMUserSEEAdditions.h"
#import "TCMMMSession.h"
#import "SelectionOperation.h"
#import "FindReplaceController.h"
#import "PlainTextWindowController.h"
#import "PlainTextEditor.h"
#import "AppController.h"
#import "DocumentMode.h"
#import "SyntaxHighlighter.h"
#import "SyntaxDefinition.h"
#import <OgreKit/OgreKit.h>
#import "NSCursorSEEAdditions.h"
#import "DocumentModeManager.h"
#import "SEEConnectionManager.h"
#import "PlainTextDocument.h"
#import "SEEPlainTextEditorScrollView.h"

#define SPANNINGRANGE(a,b) NSMakeRange(MIN(a,b),MAX(a,b)-MIN(a,b)+1)

@interface SEETextView () 
@property (nonatomic, readonly) PlainTextDocument *document;
@property (nonatomic) NSPoint cachedTextContainerOrigin;
@property (nonatomic) BOOL TCM_adjustsVisibleRectWithInsets;

/* used to temporarily adjust the visible rect methods to substract the overlay insets - used to make sure scrollToSelected also respects that - needs to be temporary because the scrollview itself gets irritated by a visible-rect that does not correspond to the total visible rect */
- (void)performBlockWithAdjustedVisibleRect:(dispatch_block_t)aBlock;

@end

@implementation SEETextView

#define VERTICAL_INSET 2.0

- (id)delegate {
	return (id)super.delegate;
}

// - (void)setNeedsDisplayInRect:(NSRect)aRect avoidAdditionalLayout:(BOOL)needsLayout {
// 	NSLog(@"%s %@ %@",__FUNCTION__,NSStringFromRect(aRect),needsLayout?@"YES":@"NO");
// 	[super setNeedsDisplayInRect:aRect avoidAdditionalLayout:NO];
// }

- (void)adjustContainerInsetToScrollView {
	SEEPlainTextEditorScrollView *enclosingScrollView = (SEEPlainTextEditorScrollView *)self.enclosingScrollView;
	if ([enclosingScrollView isKindOfClass:[SEEPlainTextEditorScrollView class]]) {
		NSSize currentInset = [self textContainerInset];
		CGFloat height = (enclosingScrollView.topOverlayHeight + enclosingScrollView.bottomOverlayHeight) / 2.0;
		height = height + VERTICAL_INSET / 2.0;
		if (height != currentInset.height) {
			currentInset.height = height;
			[self setTextContainerInset:currentInset];
			LayoutManager *layoutManager = (LayoutManager *)[self layoutManager];
			[layoutManager forceTextViewGeometryUpdate];
		}
	}
}

- (void)setFrameSize:(NSSize)newSize {
	[super setFrameSize:newSize];
}

- (NSPoint)textContainerOrigin {
	SEEPlainTextEditorScrollView *enclosingScrollView = (SEEPlainTextEditorScrollView *)self.enclosingScrollView;
	// doing this to not cause havoc if the textstorage is being edited during the resize
	if (self.textStorage.editedMask == 0) {
		self.cachedTextContainerOrigin = [super textContainerOrigin];
	}
    NSPoint origin = self.cachedTextContainerOrigin;
	if ([enclosingScrollView isKindOfClass:[SEEPlainTextEditorScrollView class]]) {
		origin = NSMakePoint(origin.x, enclosingScrollView.topOverlayHeight + VERTICAL_INSET);
	}
	return origin;
}


static NSMenu *S_defaultMenu=nil;

+ (NSMenu *)defaultMenu {
    return S_defaultMenu;
}

+ (void)setDefaultMenu:(NSMenu *)aMenu {
    S_defaultMenu=[aMenu copy];
}

- (PlainTextDocument *)document {
	// was (PlainTextDocument *)[(FoldableTextStorage *)[self textStorage] delegate]
    return [self.editor document];
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
	currentPoint.y -= self.textContainerOrigin.y;

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
			leftMouseDraggedEvent=aEvent;
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
			leftMouseDraggedEvent = nil;
			break;
        } else {
            currentPoint = [self convertPoint:[leftMouseDraggedEvent locationInWindow] fromView:nil];
			currentPoint.y -= self.textContainerOrigin.y;

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
	if ([self.editor hitTestOverlayViewsWithEvent:aEvent]) {
		return;
	}

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
    [[self document] changeFont:aSender];
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
    PlainTextDocument *document = self.document;
    TCMMMSession *session=[document session];
    NSString *sessionID=[session sessionID];
    NSDictionary *sessionParticipants=[session participants];
    NSEnumerator *participants = [[sessionParticipants objectForKey:TCMMMSessionReadWriteGroupName] objectEnumerator];
    TCMMMUser *user;
    TCMMMUser *me=[TCMMMUserManager me];

    FoldableTextStorage *ts = (FoldableTextStorage *)[self textStorage];

    if (document) {
        while ((user=[participants nextObject])) {
            if (user != me) {
				NSPoint textContainerOrigin = self.textContainerOrigin;

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
                            myPoint.x -= 0.5;
                            myPoint.y += rectArray[0].size.height - 0.5;
							
							myPoint.x += textContainerOrigin.x;
							myPoint.y += textContainerOrigin.y;
							
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
        [path setLineWidth:4.];
        [path setLineJoinStyle:NSRoundLineCapStyle];
        [path stroke];
    }
}

- (BOOL)usesFindPanel 
{
    return YES;
}

- (void)performFindPanelAction:(id)sender 
{
    [[FindReplaceController sharedInstance] performFindPanelAction:sender inTargetTextView:self];
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
	    PlainTextDocument *document=self.document;
    	[menuItem setTitle:[NSString stringWithFormat:NSLocalizedString(@"Fold All Level %d Blocks","Fold at top level menu entry label"),MAX(1,[[[document documentMode] syntaxDefinition] foldingTopLevel])]];
    }
    
    if ( action == @selector(foldAllTopLevelBlocks:) || 
         action == @selector(foldAllBlocksAtTagLevel:) || 
         action == @selector(foldCurrentBlock:) || 
         action == @selector(foldAllCommentBlocks:) ||
         action == @selector(foldAllBlocksAtCurrentLevel:) ) {
	    PlainTextDocument *document = self.document;
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

- (NSArray *)searchScopeRanges {
	FullTextStorage *fullTextStorage = [(FoldableTextStorage *)[self textStorage] fullTextStorage];
	NSArray *result = [fullTextStorage searchScopeRangesForAttributeValue:self.editor.searchScopeValue];
	if (result.count == 0) {
		result = @[[NSValue valueWithRange:fullTextStorage.TCM_fullLengthRange]];
	}
	return result;
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
    PlainTextDocument *document = self.document;
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
	[(LayoutManager *)self.layoutManager setInactiveSelectionColor:[aColor blendedColorWithFraction:0.4 ofColor:[NSColor colorWithCalibratedWhite:isDark ? 1.0 : 0.0 alpha:1.0]]];
    [[self enclosingScrollView] setDocumentCursor:isDark?[NSCursor invertedIBeamCursor]:[NSCursor IBeamCursor]];
    if (( wasDark && !isDark) || 
        (!wasDark &&  isDark)) {
		BOOL wasFirstResponder = [[self.window firstResponder] isEqual:self];
        // remove and add from Superview to activiate my cursor rect and deactivate the ones of the TextView
        NSScrollView *sv = [self enclosingScrollView];
        NSView *superview = [sv superview];
		NSArray *subviews = [[superview subviews] copy];
		NSUInteger subViewIndex = [subviews indexOfObject:sv];
		NSView *viewAbove = nil;
		if (subviews.count > subViewIndex + 1) {
			viewAbove = [subviews objectAtIndex:subViewIndex + 1];
		}
        [sv removeFromSuperview];
        [superview addSubview:sv positioned:NSWindowBelow relativeTo:viewAbove];
		if (wasFirstResponder) {
			[self.window makeFirstResponder:self];
		}
    }
    [[self window] invalidateCursorRectsForView:self];
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
        if ( ([event type]==NSKeyDown || [event type]==NSKeyUp) &&
			  [event keyCode]==53 &&
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
    [super complete:sender];
}

- (NSArray *)completionsForPartialWordRange:(NSRange)charRange indexOfSelectedItem:(NSInteger *)index {
	if (charRange.length == 0) {
		// no partial range, no completion!
		return nil;
	}
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

- (void)insertCompletion:(NSString *)word forPartialWordRange:(NSRange)charRange movement:(NSInteger)movement isFinal:(BOOL)flag {
    [super insertCompletion:word forPartialWordRange:charRange movement:movement isFinal:flag];
    if (flag) {
        if ([[self delegate] respondsToSelector:@selector(textView:didFinishAutocompleteByInsertingCompletion:forPartialWordRange:movement:)]) {
            [[self delegate] textView:self didFinishAutocompleteByInsertingCompletion:word forPartialWordRange:charRange movement:movement];
        }

        NSEvent *event=[NSApp currentEvent];
        if ( (([event type]==NSKeyDown || [event type]==NSKeyUp)) &&
			 (([event keyCode]==36) || ([event keyCode]==76) || ([event keyCode]==53) || ([event keyCode]==49) || ([event keyCode]==48))) {
			I_flags.autoCompleteInProgress=NO;
		}

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
			#pragma unused (selectedRange,textStorage)
		}
		NSMutableAttributedString *mutableString = [[[self textStorage] attributedSubstringFromRange:[self selectedRange]] mutableCopy];
		NSTextAttachment *foldingIconAttachment = [[NSTextAttachment alloc] initWithFileWrapper:[[NSFileWrapper alloc] initWithPath:[[NSBundle mainBundle] pathForResource:@"FoldingBubbleBig" ofType:@"png"]]];
//		[[[foldingIconAttachment attachmentCell] image] setSize:NSMakeSize(19,10)];
		NSAttributedString *foldingIconString = [NSAttributedString attributedStringWithAttachment:foldingIconAttachment];
		NSAttributedString *foldingIconReplacementString = [[NSAttributedString alloc] initWithPath:[[NSBundle mainBundle] pathForResource:@"FoldingBubbleText" ofType:@"rtf"] documentAttributes:nil];
		[mutableString replaceAttachmentsWithAttributedString:foldingIconString];
		[pasteboard setData:[mutableString RTFDFromRange:NSMakeRange(0,[mutableString length]) documentAttributes:nil] forType:NSRTFDPboardType];
		[mutableString replaceAttachmentsWithAttributedString:foldingIconReplacementString];
		[pasteboard setData:[mutableString  RTFFromRange:NSMakeRange(0,[mutableString length]) documentAttributes:nil] forType:NSRTFPboardType];
	} else {
		[self writeSelectionToPasteboard:pasteboard type:NSStringPboardType];
	}
}

- (NSArray *)writablePasteboardTypes {
	NSArray *result = [NSArray arrayWithObject:NSStringPboardType];
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

- (void)scrollRangeToVisible:(NSRange)aRange {
	[self performBlockWithAdjustedVisibleRect:^{
		[super scrollRangeToVisible:aRange];
	}];
}

- (NSRange)topLeftCharacterRange {
    // idea: get the character index of the character in the upper left of the window, store that, and for restore apply the operation and scroll that character back to the upper left line
    NSRect visibleRect = [self.enclosingScrollView documentVisibleRect];
    NSPoint point = visibleRect.origin;
	
    point.y += 1.;
    NSLayoutManager *layoutManager = [self layoutManager];
    NSTextStorage *textStorage = [self textStorage];
	
    if ([textStorage length]) {
        unsigned glyphIndex = [layoutManager glyphIndexForPoint:point
												inTextContainer:[self textContainer]];
        unsigned characterIndex = [layoutManager characterIndexForGlyphAtIndex:glyphIndex];
		return NSMakeRange(characterIndex, 0);
    }
	return NSMakeRange(NSNotFound,0);
}


- (void)scrollCharacterRangeToTopLeft:(NSRange)aCharacterRange {
    if (aCharacterRange.location != NSNotFound &&
		[[self textStorage] length]) {
        NSLayoutManager *layoutManager = [self layoutManager];
        unsigned glyphIndex = [layoutManager glyphRangeForCharacterRange:aCharacterRange actualCharacterRange:NULL].location;
        NSRect boundingRect  = [layoutManager lineFragmentRectForGlyphAtIndex:glyphIndex
															   effectiveRange:nil];
        NSRect visibleRect = [self.enclosingScrollView documentVisibleRect];
		
        if (visibleRect.origin.y != boundingRect.origin.y) {
            visibleRect.origin.y = boundingRect.origin.y;
            [self scrollRectToVisible:visibleRect];
        }
    }
}


- (void)viewDidEndLiveResize {
	// fix top left position
	NSRange topLeftCharacterRange = [self topLeftCharacterRange];
	
	[super viewDidEndLiveResize];
	
	// scroll back
	[self scrollCharacterRangeToTopLeft:topLeftCharacterRange];
}

- (BOOL)scrollRectToVisible:(NSRect)aRect {
	if (self.TCM_adjustsVisibleRectWithInsets) {
		SEEPlainTextEditorScrollView *enclosingScrollView = (SEEPlainTextEditorScrollView *)[self enclosingScrollView];
		if ([enclosingScrollView isKindOfClass:[SEEPlainTextEditorScrollView class]]) {
			aRect.size.height += enclosingScrollView.topOverlayHeight + enclosingScrollView.bottomOverlayHeight;
			aRect.origin.y -= enclosingScrollView.topOverlayHeight;
		}
	}

	if (aRect.origin.x == [[self textContainer] lineFragmentPadding]) {
        aRect.origin.x = 0; // fixes the left hand edge moving when scrolled totally to the left
    }

	
	BOOL result = [super scrollRectToVisible:aRect];
	return result;
}

- (NSRect)visibleRect {
	NSRect result = [super visibleRect];

	if (self.TCM_adjustsVisibleRectWithInsets) {
		SEEPlainTextEditorScrollView *enclosingScrollView = (SEEPlainTextEditorScrollView *)[self enclosingScrollView];
		if ([enclosingScrollView isKindOfClass:[SEEPlainTextEditorScrollView class]]) {
			
			result.size.height -= enclosingScrollView.topOverlayHeight + enclosingScrollView.bottomOverlayHeight;
			result.origin.y += enclosingScrollView.topOverlayHeight;
		}
	}
	return result;
}

- (void)performBlockWithAdjustedVisibleRect:(dispatch_block_t)aBlock {
	BOOL oldValue = self.TCM_adjustsVisibleRectWithInsets;
	self.TCM_adjustsVisibleRectWithInsets = YES;
	aBlock();
	self.TCM_adjustsVisibleRectWithInsets = oldValue;
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
    if ([[pboard types] containsObject:@"SEEConnectionPbordType"]) {
        //NSLog(@"draggingEntered:");
        PlainTextDocument *document = self.document;
        TCMMMSession *session=[document session];
        if ([session isServer]) {
			[[[self window] windowController] performSelector:@selector(openParticipantsOverlayForDocument:) withObject:document];
            [self setIsDragTarget:YES];
            return NSDragOperationGeneric;
        }
    } else if ([[pboard types] containsObject:@"ParticipantDrag"]) {
    } else if ([[pboard types] containsObject:@"PresentityNames"] ||
			   [[pboard types] containsObject:@"IMHandleNames"]) {
        BOOL shouldDrag=[[self.document session] isServer];
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
    if ([[pboard types] containsObject:@"SEEConnectionPbordType"]) {
        //NSLog(@"draggingUpdated:");
        BOOL shouldDrag=[[self.document session] isServer];
        [self setIsDragTarget:shouldDrag];
        if (shouldDrag) {
            return NSDragOperationGeneric;
        }
    } else if ([[pboard types] containsObject:@"ParticipantDrag"]) {
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
    if ([[pboard types] containsObject:@"SEEConnectionPbordType"]) {
        //NSLog(@"prepareForDragOperation:");
        BOOL shouldDrag=[[self.document session] isServer];
        [self setIsDragTarget:shouldDrag];
        return shouldDrag;
    } else if ([[pboard types] containsObject:@"ParticipantDrag"]) {
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
    if ([[pboard types] containsObject:@"SEEConnectionPbordType"]) {
        //NSLog(@"performDragOperation:");
        NSArray *userArray=[pboard propertyListForType:@"SEEConnectionPbordType"];
        PlainTextDocument *document=self.document;
        TCMMMSession *session=[document session];
        NSDictionary *userDescription=nil;
        for (userDescription in userArray) {
            TCMMMUser *user=[[TCMMMUserManager sharedInstance] userForUserID:[userDescription objectForKey:@"UserID"]];
            if (user) {
                TCMBEEPSession *BEEPSession=[[TCMMMBEEPSessionManager sharedInstance] sessionForUserID:[user userID] peerAddressData:[userDescription objectForKey:@"PeerAddressData"]];
                [document setPlainTextEditorsShowChangeMarksOnInvitation];
                [session inviteUser:user intoGroup:TCMMMSessionReadWriteGroupName usingBEEPSession:BEEPSession];
            }
        }
        [self setIsDragTarget:NO];
        return YES;
    } else if ([[pboard types] containsObject:@"ParticipantDrag"]) {
    } else if ([[pboard types] containsObject:@"PresentityNames"] ||
			   [[pboard types] containsObject:@"IMHandleNames"]) {
        BOOL shouldDrag=[[(PlainTextDocument *)[self document] session] isServer];
        [self setIsDragTarget:YES];
        if (shouldDrag) {
            [SEEConnectionManager invitePeopleFromPasteboard:pboard intoDocumentGroupURL:[self.document documentURLForGroup:TCMMMSessionReadWriteGroupName]];
            [self setIsDragTarget:NO];
            return YES;
        }
    }

    [self setIsDragTarget:NO];
    PlainTextDocument *document=nil;
    if (I_flags.isDraggingText) {
		document = [self document];
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
    [dragTypes addObject:@"SEEConnectionPbordType"];
    [dragTypes addObject:@"ParticipantDrag"];
    [dragTypes addObject:@"PresentityNames"];
    [dragTypes addObject:@"IMHandleNames"];
    return dragTypes;
}

- (void)updateDragTypeRegistration {
    [super updateDragTypeRegistration];
    if (![self isEditable]) {
        [self registerForDraggedTypes:[NSArray arrayWithObject:@"ParticipantDrag"]];
    }
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender {
    NSPasteboard *pboard = [sender draggingPasteboard];
    if ([[pboard types] containsObject:@"SEEConnectionPbordType"] || [[pboard types] containsObject:@"ParticipantDrag"]) {
        //NSLog(@"concludeDragOperation:");
    } else {
        [super concludeDragOperation:sender];
    }
}

- (void)keyDown:(NSEvent *)aEvent {

    static NSCharacterSet *s_passThroughCharacterSet=nil;
    if (s_passThroughCharacterSet==nil) {
        s_passThroughCharacterSet=[NSCharacterSet characterSetWithCharactersInString:@"1234567"];
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
    
	//    NSLog(@"rangeForUserCompletion: %@ - %@ - %@",NSStringFromRange(result), [theMode documentModeIdentifier], tokenSet);
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
    NSPoint currentPoint = [self convertPoint:[anEvent locationInWindow] fromView:nil];
    currentPoint.x=5;
	currentPoint.y -= self.textContainerOrigin.y;
    unsigned glyphIndex,endCharacterIndex,startCharacterIndex;
    glyphIndex=[layoutManager glyphIndexForPoint:currentPoint 
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
                currentPoint = [self convertPoint:[event locationInWindow] fromView:nil];
				currentPoint.y -= self.textContainerOrigin.y;
                glyphIndex = [layoutManager glyphIndexForPoint:currentPoint
                                               inTextContainer:textContainer];
                endCharacterIndex = [layoutManager characterIndexForGlyphAtIndex:glyphIndex];
                selectedRange = [textStorageString lineRangeForRange:SPANNINGRANGE(startCharacterIndex, endCharacterIndex)];
                if (!NSEqualRanges([self selectedRange], selectedRange)) {
                    [self setSelectedRange:selectedRange];
                }
                if ([self mouse:currentPoint inRect:[self visibleRect]]) {
                    if (timerOn) {
                        [NSEvent stopPeriodicEvents];
                        timerOn = NO;
                        autoscrollEvent = nil;
                    }
                } else {
                    if (timerOn) {
                         autoscrollEvent = event;
                    } else {
                        [NSEvent startPeriodicEventsAfterDelay:0.1 withPeriod:0.1];
                        timerOn = YES;
                        autoscrollEvent = event;
                    }
                }
            break;
                
            case NSLeftMouseUp:
                if (timerOn) {
                    [NSEvent stopPeriodicEvents];
//                    timerOn = NO;
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

// (void)mouseDown:(NSEvent *)theEvent // look abouve!

- (void)rightMouseDown:(NSEvent *)theEvent {
	if ([self.editor hitTestOverlayViewsWithEvent:theEvent]) {
		return;
	}
	[super rightMouseDown:theEvent];
}

- (void)otherMouseDown:(NSEvent *)theEvent {
	if ([self.editor hitTestOverlayViewsWithEvent:theEvent]) {
		return;
	}
	[super otherMouseDown:theEvent];
}

- (void)mouseUp:(NSEvent *)theEvent {
	if ([self.editor hitTestOverlayViewsWithEvent:theEvent]) {
		return;
	}
	[super mouseUp:theEvent];
}

- (void)rightMouseUp:(NSEvent *)theEvent {
	if ([self.editor hitTestOverlayViewsWithEvent:theEvent]) {
		return;
	}
	[super rightMouseUp:theEvent];
}

- (void)otherMouseUp:(NSEvent *)theEvent {
	if ([self.editor hitTestOverlayViewsWithEvent:theEvent]) {
		return;
	}
	[super otherMouseUp:theEvent];
}

- (void)mouseMoved:(NSEvent *)anEvent
{
	if ([self.editor hitTestOverlayViewsWithEvent:anEvent]) {
		return;
	}

	// ugly
    if ( [NSCursor currentCursor] == [NSCursor IBeamCursor] &&
		[[self backgroundColor] isDark] )  {

        [[NSCursor invertedIBeamCursor] set];

	} else if ([NSCursor currentCursor] != [NSCursor invertedIBeamCursor] &&
	           [super respondsToSelector:@selector(mouseMoved:)]) {
		[super mouseMoved:anEvent];
	}
}

- (void)mouseDragged:(NSEvent *)theEvent {
	if ([self.editor hitTestOverlayViewsWithEvent:theEvent]) {
		return;
	}
	[super mouseDragged:theEvent];
}

- (void)scrollWheel:(NSEvent *)theEvent {
	if ([self.editor hitTestOverlayViewsWithEvent:theEvent]) {
		return;
	}
	[super scrollWheel:theEvent];
}

- (void)rightMouseDragged:(NSEvent *)theEvent {
	if ([self.editor hitTestOverlayViewsWithEvent:theEvent]) {
		return;
	}
	[super rightMouseDragged:theEvent];
}

- (void)otherMouseDragged:(NSEvent *)theEvent {
	if ([self.editor hitTestOverlayViewsWithEvent:theEvent]) {
		return;
	}
	[super otherMouseDragged:theEvent];
}

// needs the textview to be delegate to the ruler
- (void)rulerView:(NSRulerView *)aRulerView handleMouseDown:(NSEvent *)anEvent {
    if (([anEvent modifierFlags] & NSAlternateKeyMask) && [self isEditable]) {
        [self trackMouseForBlockeditWithEvent:anEvent];
    } else {
        [self trackMouseForLineSelectionWithEvent:anEvent];
    }    
}


- (BOOL)becomeFirstResponder {
	BOOL result = [super becomeFirstResponder];
	if (result) {
		[[self.window windowController] setActivePlainTextEditor:self.editor];
	}
	return result;
}

@end
