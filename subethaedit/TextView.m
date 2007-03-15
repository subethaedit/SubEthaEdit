//
//  TextView.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Tue Apr 06 2004.
//  Copyright (c) 2004-2006 TheCodingMonkeys. All rights reserved.
//

#import "LayoutManager.h"
#import "TextView.h"
#import "TextStorage.h"
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

#define SPANNINGRANGE(a,b) NSMakeRange(MIN(a,b),MAX(a,b)-MIN(a,b)+1)

@interface TextView (TextViewPrivateAdditions) 
- (PlainTextDocument *)document;
@end

@interface NSTextView (NSTextViewTCMPrivateAdditions) 
- (void)_adjustedCenteredScrollRectToVisible:(NSRect)aRect forceCenter:(BOOL)force;
@end

@implementation TextView

- (void)_adjustedCenteredScrollRectToVisible:(NSRect)aRect forceCenter:(BOOL)force {
    if (aRect.origin.x == [[self textContainer] lineFragmentPadding]) {
        aRect.origin.x = 0; // fixes the left hand edge moving
    }
    [super _adjustedCenteredScrollRectToVisible:aRect forceCenter:force];
}

static NSMenu *defaultMenu=nil;


+ (NSMenu *)defaultMenu {
    return defaultMenu;
}

+ (void)setDefaultMenu:(NSMenu *)aMenu {
    defaultMenu=[aMenu copy];
}

- (PlainTextDocument *)document {
    return [(TextStorage *)[self textStorage] delegate];
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
    TextStorage *textStorage=(TextStorage *)[self textStorage];
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
    PlainTextDocument *document=(PlainTextDocument *)[self document];
    TCMMMSession *session=[document session];
    NSString *sessionID=[session sessionID];
    NSDictionary *sessionParticipants=[session participants];
    NSEnumerator *participants = [[sessionParticipants objectForKey:@"ReadWrite"] objectEnumerator];
    TCMMMUser *user;
    TCMMMUser *me=[TCMMMUserManager me];
    if (document) {
        while ((user=[participants nextObject])) {
            if (user != me) {
                SelectionOperation *selectionOperation= [[user propertiesForSessionID:sessionID] objectForKey:@"SelectionOperation"];
                if (selectionOperation) {
                    NSRange selectionRange = [selectionOperation selectedRange];
                    if (selectionRange.length==0) {
                        // now we have to paint a caret at position
        //                NSRange selection = NSMakeRange((unsigned)[(NSNumber *)[selection objectAtIndex:0] unsignedIntValue],0);
        
                        unsigned rectCount;
                        NSRectArray rectArray=[[self layoutManager] 
                                                    rectArrayForCharacterRange:selectionRange 
                                                    withinSelectedCharacterRange:selectionRange 
                                                    inTextContainer:[self textContainer] rectCount:&rectCount];
                        NSColor *changeColor=[[user changeColor] shadowWithLevel:0.1];
                                                
                        if (rectCount>0) {
                            NSPoint myPoint = rectArray[0].origin;
                            myPoint.x -= 0.5;
                            myPoint.y += rectArray[0].size.height - 0.5;
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
    [[FindReplaceController sharedInstance] performFindPanelAction:sender forTextView:self];
}

-(BOOL)validateMenuItem:(id <NSMenuItem>)menuItem 
{

    BOOL returnValue = [super validateMenuItem:menuItem];
    if (!returnValue) {
        if ([menuItem tag]==1001) returnValue=YES;
        if ([menuItem tag]==1002) returnValue=YES;
    }
    if (returnValue && [menuItem action]==@selector(copyStyled:)) {
        return [self selectedRange].length>0;
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

- (void)setBackgroundColor:(NSColor *)aColor {
    [super setBackgroundColor:aColor];
    [self setInsertionPointColor:[aColor isDark]?[NSColor whiteColor]:[NSColor blackColor]];
    [self setSelectedTextAttributes:[NSDictionary dictionaryWithObject:[aColor isDark]?[[NSColor selectedTextBackgroundColor] brightnessInvertedSelectionColor]:[NSColor selectedTextBackgroundColor] forKey:NSBackgroundColorAttributeName]];
    [[self enclosingScrollView] setDocumentCursor:[aColor isDark]?[NSCursor invertedIBeamCursor]:[NSCursor IBeamCursor]];
    [[self window] invalidateCursorRectsForView:self];
}

- (void)toggleContinuousSpellChecking:(id)sender {
    [super toggleContinuousSpellChecking:sender];
    if ([[self delegate] respondsToSelector:@selector(textViewDidChangeSpellCheckingSetting:)]) {
        [[self delegate] textViewDidChangeSpellCheckingSetting:self];
    }
}

- (void)complete:(id)sender {
    TextStorage *textStorage=(TextStorage *)[self textStorage];
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
    [super complete:sender];
}

- (NSArray *)completionsForPartialWordRange:(NSRange)charRange indexOfSelectedItem:(int *)index {
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

- (void)insertCompletion:(NSString *)word forPartialWordRange:(NSRange)charRange movement:(int)movement isFinal:(BOOL)flag {
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
        PlainTextDocument *document=(PlainTextDocument *)[self document];
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
        BOOL shouldDrag=[[(PlainTextDocument *)[self document] session] isServer];
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
    } 
    [self setIsDragTarget:NO];
    return [super draggingUpdated:sender];
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender {
    NSPasteboard *pboard = [sender draggingPasteboard];
    if ([[pboard types] containsObject:@"PboardTypeTBD"]) {
        //NSLog(@"prepareForDragOperation:");
        BOOL shouldDrag=[[(PlainTextDocument *)[self document] session] isServer];
        [self setIsDragTarget:shouldDrag];
        return shouldDrag;
    } else if ([[pboard types] containsObject:@"ParticipantDrag"]) {
        if ([[sender draggingSource] isKindOfClass:[ParticipantsView class]] && 
            [[[sender draggingSource] window] windowController]==[[self window]  windowController]) {
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
        PlainTextDocument *document=(PlainTextDocument *)[self document];
        TCMMMSession *session=[document session];
        NSEnumerator *userDescriptions=[userArray objectEnumerator];
        NSDictionary *userDescription=nil;
        while ((userDescription=[userDescriptions nextObject])) {
            TCMMMUser *user=[[TCMMMUserManager sharedInstance] userForUserID:[userDescription objectForKey:@"UserID"]];
            if (user) {
                TCMBEEPSession *BEEPSession=[[TCMMMBEEPSessionManager sharedInstance] sessionForUserID:[user userID] URLString:[userDescription objectForKey:@"URLString"]];
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
    NSCharacterSet *tokenSet = [[[[[self document] documentMode] syntaxHighlighter] syntaxDefinition] autoCompleteTokenSet];

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
    
    //NSLog(@"rangeForUserCompletion: %@",NSStringFromRange(result));
    return result;
}

#pragma mark -
#pragma mark ### handle ruler interaction ###

- (void)trackMouseForLineSelectionWithEvent:(NSEvent *)anEvent {
    NSString *textStorageString = [[self textStorage] string];
    if ([textStorageString length]==0) return;
    NSLayoutManager *layoutManager = [self layoutManager];
    NSTextContainer *textContainer = [self textContainer];
    NSPoint point = [self convertPoint:[anEvent locationInWindow] fromView:nil];
    point.x=5;
    unsigned glyphIndex,endCharacterIndex,startCharacterIndex;
    glyphIndex=[layoutManager glyphIndexForPoint:point 
                                 inTextContainer:textContainer];
    endCharacterIndex = startCharacterIndex = [layoutManager characterIndexForGlyphAtIndex:glyphIndex];
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
        }
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


@end
