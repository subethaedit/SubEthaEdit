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


@implementation TextView

static NSMenu *defaultMenu=nil;

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
    }
    
    return returnValue;
}

- (void)setBackgroundColor:(NSColor *)aColor {
    [super setBackgroundColor:aColor];
    [self setInsertionPointColor:[aColor isDark]?[NSColor whiteColor]:[NSColor blackColor]];
    [self setSelectedTextAttributes:[NSDictionary dictionaryWithObject:[aColor isDark]?[[NSColor selectedTextBackgroundColor] brightnessInvertedColor]:[NSColor selectedTextBackgroundColor] forKey:NSBackgroundColorAttributeName]];
}

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
    } 
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
    } 
    return [super draggingUpdated:sender];
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender {
    NSPasteboard *pboard = [sender draggingPasteboard];
    if ([[pboard types] containsObject:@"PboardTypeTBD"]) {
        //NSLog(@"prepareForDragOperation:");
        BOOL shouldDrag=[[(PlainTextDocument *)[[[self window] windowController] document] session] isServer];
        [self setIsDragTarget:shouldDrag];
        return shouldDrag;
    } else {
        return [super prepareForDragOperation:sender];
    }
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
    NSPasteboard *pboard = [sender draggingPasteboard];
    if ([[pboard types] containsObject:@"PboardTypeTBD"]) {
        NSLog(@"performDragOperation:");
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
    } else {
        return [super performDragOperation:sender];
    }
}

- (NSArray *)acceptableDragTypes {
    NSMutableArray *dragTypes=[[super acceptableDragTypes] mutableCopy];
    [dragTypes addObject:@"PboardTypeTBD"];
    return [dragTypes autorelease];
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender {
    NSPasteboard *pboard = [sender draggingPasteboard];
    if ([[pboard types] containsObject:@"PboardTypeTBD"]) {
        NSLog(@"concludeDragOperation:");
    } else {
        [super concludeDragOperation:sender];
    }
}



@end
