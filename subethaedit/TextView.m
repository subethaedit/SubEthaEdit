//
//  TextView.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Tue Apr 06 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "TextView.h"
#import "TextStorage.h"


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
            [textStorage setHasBlockeditRanges:YES];
            [NSEvent stopPeriodicEvents];
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
    
    if ([aEvent modifierFlags] & NSAlternateKeyMask) {
        [self trackMouseForBlockeditWithEvent:aEvent];
    } else {
        [super mouseDown:aEvent]; 
    }
}


// make sure our document gets the font change
- (void)changeFont:(id)aSender {
    [[[[self window] windowController] document] changeFont:aSender];
}


@end
