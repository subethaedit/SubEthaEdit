//
//  TextView.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Tue Apr 06 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "TextView.h"
#import "TextStorage.h"
#import "PlaintextDocument.h"
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

@implementation TextView

static NSMenu *defaultMenu=nil;
static NSColor *nonCommercialColor=nil;

+ (void)initialize {
    NSRect rect=NSMakeRect(0,0,0,0);
    NSFont *font=[NSFont boldSystemFontOfSize:25.];
    NSString *text=NSLocalizedString(@"Licensed for non-commercial use",@"");
    text = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if ([text length] < 3) {
        text = @"non-commercial use only";
    }
    NSDictionary *attributes=[NSDictionary dictionaryWithObjectsAndKeys:[NSColor colorWithCalibratedWhite:.5 alpha:.25],NSForegroundColorAttributeName,font,NSFontAttributeName,nil];
    rect.size=[text sizeWithAttributes:attributes];
    float height=rect.size.height;
    float width=rect.size.width;
    rect.size.width = (int)(cos(30./180.*M_PI)*width+height*2);
    rect.size.height= (int)(sin(30./180.*M_PI)*width+height);
    NSImage *image=[[[NSImage alloc] initWithSize:rect.size] autorelease];
    [image lockFocus];
    [[NSColor clearColor] set];
    [NSBezierPath fillRect:rect];
    [[NSColor colorWithCalibratedWhite:.5 alpha:.3] set];
//    NSFrameRect(rect);
    NSAffineTransform *transform=[NSAffineTransform transform];
    [transform translateXBy:height yBy:0.];
    [transform rotateByDegrees:30.];
    [transform concat];
//    NSFrameRect(rect);
    [text drawAtPoint:NSMakePoint(0.,0.) withAttributes:attributes];
    [transform invert];
    [transform concat];
    [image unlockFocus];
    nonCommercialColor=[[NSColor colorWithPatternImage:image] retain];
}

+ (NSMenu *)defaultMenu {
    return defaultMenu;
}

+ (void)setDefaultMenu:(NSMenu *)aMenu {
    defaultMenu=[aMenu copy];
}

- (void)trackMouseForBlockeditWithEvent:(NSEvent *)aEvent {
    NSDictionary *blockeditAttributes=[[self delegate] blockeditAttributesForTextView:self];
    BOOL outside=NO;
    NSScrollView *scrollView=[self enclosingScrollView];

    NSPoint currentPoint;

    unsigned glyphIndex,characterIndex,beginIndex;

    NSLayoutManager *layoutManager=[self layoutManager];
    TextStorage *textStorage=(TextStorage *)[self textStorage];
    NSRange blockeditRange,tempRange;

    currentPoint = [self convertPoint:[aEvent locationInWindow] fromView:nil];
    glyphIndex =[layoutManager glyphIndexForPoint:currentPoint 
                                     inTextContainer:[self textContainer]];
    beginIndex=[layoutManager characterIndexForGlyphAtIndex:glyphIndex];
    blockeditRange=[[self string] lineRangeForRange:NSMakeRange(beginIndex,0)];
    [textStorage addAttributes:blockeditAttributes 
                 range:blockeditRange];    

    while (YES) {
        NSRange intersectionRange;
        NSEvent *leftMouseDraggedEvent = nil;
        aEvent=[[self window] nextEventMatchingMask:(NSLeftMouseDraggedMask|NSLeftMouseUpMask|NSPeriodicMask)];

        if ([aEvent type] == NSLeftMouseDragged) {
            leftMouseDraggedEvent=aEvent;
            BOOL hitsContent=[scrollView 
                                 mouse:[scrollView convertPoint:[aEvent locationInWindow] fromView:nil] 
                                inRect:[scrollView bounds]];
            if (outside) {
                if (hitsContent) {
                    [NSEvent stopPeriodicEvents];
                    outside=NO;
                }
            } else {
                if (!hitsContent) {
                    [NSEvent startPeriodicEventsAfterDelay:0.0 withPeriod:0.1];
                    outside=YES;
                }
            }
        }
        
        if ([aEvent type] == NSPeriodic) {
            [self autoscroll:aEvent];
        } 
        
        if ([aEvent type] == NSLeftMouseUp) {
            if ([textStorage length]>0) {
                [textStorage setHasBlockeditRanges:YES];
                [NSEvent stopPeriodicEvents];
                // evil hack for unpause
                [[self delegate] textViewDidChangeSelection:nil];
            }
            break;
        } else {
            currentPoint = [self convertPoint:[leftMouseDraggedEvent locationInWindow] fromView:nil];
            glyphIndex =[layoutManager glyphIndexForPoint:currentPoint 
                                             inTextContainer:[self textContainer]]; 
            characterIndex=[layoutManager characterIndexForGlyphAtIndex:glyphIndex];
            tempRange.location=MIN(beginIndex,characterIndex);
            tempRange.length  =MAX(beginIndex,characterIndex)-MIN(beginIndex,characterIndex);
            tempRange=[[self string] lineRangeForRange:tempRange];
            if (!NSEqualRanges(blockeditRange,tempRange)) {
                if (blockeditRange.location!=tempRange.location) {
                    if (blockeditRange.location>tempRange.location) {
                        intersectionRange.location=tempRange.location;
                        intersectionRange.length=blockeditRange.location-tempRange.location;
                        [textStorage  addAttributes:blockeditAttributes 
                                              range:intersectionRange];
                    } else {
                        intersectionRange.location=blockeditRange.location;
                        intersectionRange.length=tempRange.location-blockeditRange.location;
                        NSEnumerator *attributeNames=[blockeditAttributes keyEnumerator];
                        id attributeName=nil;
                        while ((attributeName=[attributeNames nextObject])) {
                            [textStorage removeAttribute:attributeName
                                                   range:intersectionRange];
                        }
                    }
                }
                if (NSMaxRange(blockeditRange)!=NSMaxRange(tempRange)) {
                    if (NSMaxRange(blockeditRange)<NSMaxRange(tempRange)) {
                        intersectionRange.location=NSMaxRange(blockeditRange);
                        intersectionRange.length=NSMaxRange(tempRange)-NSMaxRange(blockeditRange);
                        [textStorage addAttributes:blockeditAttributes 
                                             range:intersectionRange];
                    } else {
                        intersectionRange.location=NSMaxRange(tempRange);
                        intersectionRange.length  =NSMaxRange(blockeditRange)-NSMaxRange(tempRange);
                        NSEnumerator *attributeNames=[blockeditAttributes keyEnumerator];
                        id attributeName=nil;
                        while ((attributeName=[attributeNames nextObject])) {
                            [textStorage removeAttribute:attributeName
                                                   range:intersectionRange];
                        }
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


// make sure our document gets the font change
- (void)changeFont:(id)aSender {
    [[[[self window] windowController] document] changeFont:aSender];
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

- (void)drawViewBackgroundInRect:(NSRect)rect {
    [super drawViewBackgroundInRect:rect];
    if (!abcde()) {
        NSGraphicsContext *context=[NSGraphicsContext currentContext];
        NSPoint phase=[context patternPhase];
        [context setPatternPhase:NSMakePoint(phase.x+[[self superview] frame].origin.x,phase.y)];
        [nonCommercialColor set];
        [NSBezierPath fillRect:rect];
        [context setPatternPhase:phase];
    }
}

- (void)drawRect:(NSRect)aRect {
    [super drawRect:aRect];
    // now paint Cursors if there are any
    PlainTextDocument *document=(PlainTextDocument *)[[[self window] windowController] document];
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

- (void)setBackgroundColor:(NSColor *)aColor {
    [super setBackgroundColor:aColor];
    [self setInsertionPointColor:[aColor isDark]?[NSColor whiteColor]:[NSColor blackColor]];
    [self setSelectedTextAttributes:[NSDictionary dictionaryWithObject:[aColor isDark]?[[NSColor selectedTextBackgroundColor] brightnessInvertedColor]:[NSColor selectedTextBackgroundColor] forKey:NSBackgroundColorAttributeName]];
}

- (void)toggleContinuousSpellChecking:(id)sender {
    [super toggleContinuousSpellChecking:sender];
    if ([[self delegate] respondsToSelector:@selector(textViewDidChangeSpellCheckingSetting:)]) {
        [[self delegate] textViewDidChangeSpellCheckingSetting:self];
    }
}

- (void)complete:(id)sender {
    I_flags.shouldCheckCompleteStart=YES;
    [super complete:sender];
}

- (NSArray *)completionsForPartialWordRange:(NSRange)charRange indexOfSelectedItem:(int *)index {
    NSArray *result=[super completionsForPartialWordRange:charRange indexOfSelectedItem:index];
    if (I_flags.shouldCheckCompleteStart) {
        if ([result count]) {
            if ([[self delegate] respondsToSelector:@selector(textViewWillStartAutocomplete:)]) {
                [[self delegate] textViewWillStartAutocomplete:self];
            }
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
    }
}

- (IBAction)copyStyled:(id)aSender {
    [self setRichText:YES];
    [self copy:aSender];
    [self setRichText:NO];
}

#define WATERMARKINTERVAL 5.

//- (void)trigger {
//    if ([I_timer isValid]) {
//        [I_timer setFireDate:[NSDate dateWithTimeIntervalSinceNow:WATERMARKINTERVAL]];
//    } else {
//        [I_timer release];
//        I_timer=[[NSTimer timerWithTimeInterval:WATERMARKINTERVAL
//                                                target:self
//                                              selector:@selector(triggerAction:)
//                                              userInfo:nil repeats:NO] retain];
//        [[NSRunLoop currentRunLoop] addTimer:I_timer forMode:NSDefaultRunLoopMode]; //(NSString *)kCFRunLoopCommonModes];
//    }
//}
//
//- (void)triggerAction:(void *)context {
//    [self setNeedsDisplay:YES];
//}
//
//- (BOOL)resignFirstResponder {
//    BOOL result=[super resignFirstResponder];
//    if (result && !abcde()) {
//        [self trigger];
//    }
//    return result;
//}

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
        PlainTextDocument *document=(PlainTextDocument *)[[[self window] windowController] document];
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
        BOOL shouldDrag=[[(PlainTextDocument *)[[[self window] windowController] document] session] isServer];
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
        BOOL shouldDrag=[[(PlainTextDocument *)[[[self window] windowController] document] session] isServer];
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
        PlainTextDocument *document=(PlainTextDocument *)[[[self window] windowController] document];
        TCMMMSession *session=[document session];
        NSEnumerator *userDescriptions=[userArray objectEnumerator];
        NSDictionary *userDescription=nil;
        while ((userDescription=[userDescriptions nextObject])) {
            TCMMMUser *user=[[TCMMMUserManager sharedInstance] userForUserID:[userDescription objectForKey:@"UserID"]];
            if (user) {
                TCMBEEPSession *BEEPSession=[[TCMMMBEEPSessionManager sharedInstance] sessionForUserID:[user userID] URLString:[userDescription objectForKey:@"URLString"]];
                [session inviteUser:user intoGroup:@"ReadWrite" usingBEEPSession:BEEPSession];
            }
        }
        [self setIsDragTarget:NO];
        return YES;
    } else if ([[pboard types] containsObject:@"ParticipantDrag"]) {
        if ([[sender draggingSource] isKindOfClass:[ParticipantsView class]] && 
            [[sender draggingSource] windowController]==[[self window]windowController]) {
            PlainTextWindowController *controller=[[self window] windowController];
            [controller performSelector:@selector(followUser:) withObject:self];
            [self setIsDragTarget:NO];
            return YES;
        }
    }
    [self setIsDragTarget:NO];
    return [super performDragOperation:sender];
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
    static NSCharacterSet *passThroughCharacterSet=nil;
    if (passThroughCharacterSet==nil) {
        passThroughCharacterSet=[[NSCharacterSet characterSetWithCharactersInString:@"123"] retain];
    }
    int flags=[aEvent modifierFlags];
    if ((flags & NSControlKeyMask) && !(flags & NSCommandKeyMask) && 
        [[aEvent characters] length]==1 &&
        [passThroughCharacterSet characterIsMember:[[aEvent characters] characterAtIndex:0]]) {
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
}


@end
