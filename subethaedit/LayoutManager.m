//
//  LayoutManager.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Tue Apr 06 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "LayoutManager.h"
#import "PlainTextDocument.h"
#import "TCMMMUserManager.h"
#import "TCMMMUser.h"
#import "TCMMMUserSEEAdditions.h"
#import "TCMMMSession.h"
#import "GeneralPreferences.h"
#import "TextStorage.h"
#import "SelectionOperation.h"

@implementation LayoutManager

- (id)init {
    if ((self=[super init])) {
        I_flags.showsChangeMarks=NO;
    }
    return self;
}

- (void)drawBorderedMarksWithColor:(NSColor *)aColor atRects:(NSRectArray)aRectArray rectCount:(unsigned int)rectCount {

    if (rectCount == 0) return;
    NSBezierPath *markPath = [NSBezierPath bezierPath];
    NSRect topRect = aRectArray[0];
    float left;
    float x;
    float y;
    unsigned i = 0;
    if ((rectCount > 1) && topRect.origin.x != aRectArray[1].origin.x) {
        if (topRect.origin.x >= aRectArray[1].origin.x + aRectArray[1].size.width) {
            [markPath appendBezierPathWithRect:NSMakeRect(topRect.origin.x+1, topRect.origin.y, topRect.size.width-1, topRect.size.height-1)];
            x = aRectArray[1].origin.x + 1;
            y = aRectArray[1].origin.y;
            [markPath moveToPoint:NSMakePoint(x, y)];
            i = 1;
            left = aRectArray[1].origin.x + 1;
        } else {
            left = aRectArray[1].origin.x + 1;
            x = left;
            y = topRect.origin.y + topRect.size.height;
            [markPath moveToPoint:NSMakePoint(x, y)];
            x = topRect.origin.x + 1;
            [markPath lineToPoint:NSMakePoint(x, y)];
            y = topRect.origin.y;
            [markPath lineToPoint:NSMakePoint(x, y)];
        }
    } else {
        left = topRect.origin.x + 1;
        x = topRect.origin.x + 1;
        y = topRect.origin.y;
        [markPath moveToPoint:NSMakePoint(x, y)];
    }

    for (; i < rectCount; i++) {
        NSRect rect = aRectArray[i];


        x = rect.origin.x + rect.size.width;

        float nextX = (i < rectCount)?aRectArray[i+1].origin.x + aRectArray[i+1].size.width:left;

        [markPath lineToPoint:NSMakePoint(x, y)];
        if (x < nextX && (i != 0)) {
            y = rect.origin.y + rect.size.height;
            [markPath lineToPoint:NSMakePoint(x, y)];
        } else {
            y = rect.origin.y + rect.size.height - 1;
            [markPath lineToPoint:NSMakePoint(x, y)];
        }
    }

    x = left;
    [markPath lineToPoint:NSMakePoint(x, y)];

    [markPath closePath];

    NSAffineTransform *transform = [NSAffineTransform transform];
    [transform translateXBy:-0.5 yBy:0.5];
    [markPath transformUsingAffineTransform: transform];

    //[markPath addClip];

    [aColor set];
    [markPath fill];

    NSColor *borderColor = [aColor shadowWithLevel:0.3];
    [borderColor set];
    [markPath stroke];
}


- (void)drawCaretWithColor:(NSColor *)aColor atPoint:(NSPoint)aPoint {
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
//    [[NSGraphicsContext currentContext] setShouldAntialias:NO];
    [caretPath fill];
//    [caretPath stroke];
    [[NSGraphicsContext currentContext] setShouldAntialias:shouldAntialias];
}


- (BOOL)showsChangeMarks {
    return I_flags.showsChangeMarks;
}

- (void)setShowsChangeMarks:(BOOL)showsChangeMarks {
    if (showsChangeMarks != I_flags.showsChangeMarks) {
        I_flags.showsChangeMarks=showsChangeMarks;
        TextStorage *textStorage = (TextStorage *)[self textStorage];
        NSRange wholeRange=NSMakeRange(0,[textStorage length]);
        NSRange searchRange;
        unsigned position=wholeRange.location;
        while (position < NSMaxRange(wholeRange)) {
            NSString *userID=[textStorage attribute:ChangedByUserIDAttributeName 
                                atIndex:position longestEffectiveRange:&searchRange inRange:wholeRange];
            if (userID) {
                [self invalidateLayoutForCharacterRange:searchRange isSoft:NO actualCharacterRange:NULL];
            }
            position=NSMaxRange(searchRange);
        }
    }
}

- (void)drawBackgroundForGlyphRange:(NSRange)aGlyphRange atPoint:(NSPoint)anOrigin {
    NSTextContainer *container = [self textContainerForGlyphAtIndex:aGlyphRange.location effectiveRange:nil];
    NSRange charRange = [self characterRangeForGlyphRange:aGlyphRange actualGlyphRange:nil];
    if (I_flags.showsChangeMarks) {
        NSTextStorage *textStorage = [self textStorage];
        NSString *textStorageString=[textStorage string];
        unsigned int position = charRange.location;
        NSRange attributeRange;
        while (position < NSMaxRange(charRange)) {
            NSString *userID=[textStorage attribute:ChangedByUserIDAttributeName atIndex:position longestEffectiveRange:&attributeRange inRange:charRange];
            if (userID) {
                NSColor *changeColor=[[[TCMMMUserManager sharedInstance] userForUserID:userID] changeColor];
                NSColor *backgroundColor=[NSColor whiteColor]; // TODO: take from preferences
                backgroundColor=[backgroundColor blendedColorWithFraction:
                                    [[NSUserDefaults standardUserDefaults] floatForKey:ChangesSaturationPreferenceKey]/100.
                                 ofColor:changeColor];
                [backgroundColor set];
                
                unsigned startIndex, lineEndIndex, contentsEndIndex;
                unsigned innerPosition = attributeRange.location;
                while (innerPosition < NSMaxRange(attributeRange)) {
                    [textStorageString getLineStart:&startIndex end:&lineEndIndex contentsEnd:&contentsEndIndex forRange:NSMakeRange(innerPosition,0)];
                    innerPosition=lineEndIndex+1;
                    if (startIndex<attributeRange.location) startIndex=attributeRange.location;
                    if (contentsEndIndex>NSMaxRange(attributeRange)) contentsEndIndex=NSMaxRange(attributeRange);
                    unsigned rectCount;
                    NSRectArray rectArray = [self rectArrayForCharacterRange:NSMakeRange(startIndex,contentsEndIndex-startIndex) withinSelectedCharacterRange:NSMakeRange(NSNotFound,0) inTextContainer:container rectCount:&rectCount];
                    unsigned i;
                    for (i=0;i<rectCount;i++) {
                        NSRectFill(rectArray[i]);
                    }
                }
            }
            position=NSMaxRange(attributeRange);
        }
    }

    // selections and carets
    PlainTextDocument *document = (PlainTextDocument *)[[[[container textView] window] windowController] document];
    TCMMMSession *session=[document session];
    NSString *sessionID=[session sessionID];
    NSDictionary *sessionParticipants=[session participants];
    NSEnumerator *participants = [[sessionParticipants objectForKey:@"ReadWrite"] objectEnumerator];
    TCMMMUser *user;
//    float saturation=[[[NSUserDefaults standardUserDefaults] objectForKey:SelectionSaturationPreferenceKey] floatValue];
//    NSColor *backgroundColor=[NSColor documentBackgroundColor];
    while ((user = [participants nextObject])) {
        SelectionOperation *selectionOperation=[[user propertiesForSessionID:sessionID] objectForKey:@"SelectionOperation"];
        if (selectionOperation) {
            NSRange selectionRange = NSIntersectionRange(charRange, [selectionOperation selectedRange]);
            if (selectionRange.length !=0) {
                NSColor *changeColor=[user changeColor];
                NSColor *backgroundColor=[NSColor whiteColor]; // TODO: take from preferences
                backgroundColor=[backgroundColor blendedColorWithFraction:
                                    [[NSUserDefaults standardUserDefaults] floatForKey:SelectionSaturationPreferenceKey]/100.
                                 ofColor:changeColor];
                unsigned rectCount;
                NSRectArray selectionRectArray = [self rectArrayForCharacterRange:selectionRange withinSelectedCharacterRange:selectionRange inTextContainer:container rectCount:&rectCount];
                [self drawBorderedMarksWithColor:changeColor atRects:selectionRectArray rectCount:rectCount];
            }
        }
    }


    [super drawBackgroundForGlyphRange:aGlyphRange atPoint:anOrigin];
}

- (void)drawGlyphsForGlyphRange:(NSRange)glyphRange atPoint:(NSPoint)containerOrigin
{
    if ([self showsInvisibleCharacters]) {
        // figure out what invisibles to draw
        NSRange charRange = [self characterRangeForGlyphRange:glyphRange actualGlyphRange:NULL];
        NSString *characters = [[self textStorage] string];
        unsigned i;
        unichar previousChar=0;
        for (i=charRange.location;i<NSMaxRange(charRange);i++) {
            unichar c = [characters characterAtIndex: i];
            unichar draw = 0;
            if (c == ' ') {		// "real" space
                draw = 0x2024; // one dot leader 0x00b7; // "middle dot" 0x22c5; // "Dot centered"
            } else if (c == '\t') {	// "correct" indentation
                draw = 0x2192; // "Arrow right"
            } else if (c == 0x21e4 || c == 0x21e5) {	// not "correct" indentation (leftward tab, rightward tab)
                draw = 0x2192; // "Arrow right"
            } else if (c == '\r') {	// mac line feed
                draw = 0x204b; // "reversed Pilcrow"
            } else if (c == 0x0a) {	// unix line feed
                if (previousChar == '\r') {
                    draw = 0x2014; // m-dash 
                } else {
                    draw = 0x00b6; // "Pilcrow sign"
                }
            } else if (c == 0x2028) { // unicode line separator
                draw = 0x2761;
            } else if (c == 0x2029) { // unicode paragraph separator
                draw = 0x21ab;
            } else if (c == 0x0c) {	// page break
                draw = 0x21cb; // leftwards harpoon over rightwards harpoon
            } else if (c < 0x20 || (0x007f <= c && c <= 0x009f) || [[NSCharacterSet illegalCharacterSet] characterIsMember: c]) {	// some other mystery control character
                draw = 0xfffd; // replacement character for controls that don't belong there
            } else {
                NSRange glyphRange = [self glyphRangeForCharacterRange:NSMakeRange(i,1) actualCharacterRange:NULL];
                if (glyphRange.length == 0) {
                    // something that doesn't show up as a glpyh
                    draw = 0xfffd; // replacement character
                }
            }
            if (draw) {
                // where is that one?
                NSString *glyphString=[[NSString alloc] initWithCharactersNoCopy:&draw length:1 freeWhenDone:NO];
                NSMutableDictionary *attributes = [[[self textStorage] attributesAtIndex:i effectiveRange:NULL] mutableCopy];
                [attributes setObject:[NSColor grayColor] forKey:NSForegroundColorAttributeName];
                NSSize glyphSize=[glyphString sizeWithAttributes:attributes];
                NSRange glyphRange = [self glyphRangeForCharacterRange:NSMakeRange(i,1) actualCharacterRange:NULL];
                NSPoint where = [self locationForGlyphAtIndex:glyphRange.location];
                NSRect fragment = [self lineFragmentRectForGlyphAtIndex:glyphRange.location effectiveRange:NULL];
                where.x += containerOrigin.x + fragment.origin.x;
                where.y = containerOrigin.y + fragment.origin.y + (fragment.size.height-glyphSize.height)/2.;
                //NSLog(@"Drawing invisible %C at %g,%g",draw,where.x,where.y);
                // now draw the thing in the right font/size, attributes, etc...
                //c = '*';
                [glyphString drawAtPoint:where withAttributes:attributes];
                [glyphString release];
                [attributes release];
            }
            previousChar=c;
        }
    }

    // draw the real glyphs
    [super drawGlyphsForGlyphRange: glyphRange atPoint: containerOrigin];
}


@end
