//
//  GutterRulerView.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Mon May 05 2003.
//  Copyright (c) 2003 TheCodingMonkeys. All rights reserved.
//

#import "GutterRulerView.h"
#import "SyntaxHighlighter.h"
#import "FoldableTextStorage.h"

#define FOLDING_BAR_WIDTH 9.
#define RIGHT_INSET  4.
#define MAX_FOLDING_DEPTH 5.

@interface NSBezierPath (BezierPathGutterRulerViewAdditions)
+ (void)fillTriangleInRect:(NSRect)aRect arrowPoint:(NSRectEdge)anEdge;
@end

@implementation NSBezierPath (BezierPathGutterRulerViewAdditions)
+ (void)fillTriangleInRect:(NSRect)aRect arrowPoint:(NSRectEdge)anEdge {
	// ignore edge for the moment
	NSBezierPath *path = [NSBezierPath bezierPath];
	[path moveToPoint:aRect.origin];
	[path lineToPoint:NSMakePoint(aRect.origin.x,NSMaxY(aRect))];
	[path lineToPoint:NSMakePoint(NSMaxX(aRect),aRect.origin.y + aRect.size.height / 2.0)];
	[path closePath];
	[path fill];
}
@end

@implementation GutterRulerView

- (id)initWithScrollView:(NSScrollView *)aScrollView 
             orientation:(NSRulerOrientation)orientation {
    self=[super initWithScrollView:aScrollView orientation:orientation];
    return self;
}

- (void)drawRect:(NSRect)aRect {
//    NSLog(@"bounds:%@",NSStringFromRect([self bounds]));
//    NSLog(@"frame:%@",NSStringFromRect([self frame]));
//    NSLog(@"drawRect:%@",NSStringFromRect(aRect));
    [super drawRect:aRect];
}

- (NSColor *)colorForLineRange:(NSRange)aLineRange inTextStorage:(NSTextStorage *)aTextStorage {
	int maxDepth = 0;
	NSArray *highlightingStack = nil;
	
	if (aLineRange.length > 0) {
		NSRange attributeRange = NSMakeRange(aLineRange.location,0);
		do {
			highlightingStack = [aTextStorage attribute:kSyntaxHighlightingStackName atIndex:NSMaxRange(attributeRange) longestEffectiveRange:&attributeRange inRange:aLineRange];
			maxDepth = MAX([highlightingStack count],maxDepth);
		} while (NSMaxRange(attributeRange) < NSMaxRange(aLineRange));
	}
	return [NSColor colorWithCalibratedWhite:1.0 - ((MAX(maxDepth, 1.0) - 1) / MAX_FOLDING_DEPTH) alpha:1.0];
}

- (NSRect)baseRectForFoldingBar {
	double ruleThickness = [self ruleThickness];
	double rightHandAlignment = ruleThickness - FOLDING_BAR_WIDTH - RIGHT_INSET;
	return NSMakeRect(rightHandAlignment + RIGHT_INSET + 1.0,0,FOLDING_BAR_WIDTH-3.0,0);
}

- (void)drawHashMarksAndLabelsInRect:(NSRect)aRect {
    
    static NSDictionary *attributes=nil;
    static float linenumberFontSize=9.;
    static NSSize sizeOfZero;
    if (!attributes) {
        NSFont *font=[NSFont fontWithName:@"Lucida Sans Typewriter-Regular" size:linenumberFontSize];
        if (!font) font=[NSFont systemFontOfSize:linenumberFontSize];
        attributes=[[NSDictionary dictionaryWithObjectsAndKeys:
                        font,NSFontAttributeName,
                        [NSColor colorWithCalibratedWhite:0.27 alpha:1.0],NSForegroundColorAttributeName,                        nil] retain];
        sizeOfZero=[@"0" sizeWithAttributes:attributes];
    }

    NSTextView              *textView=(NSTextView *)[self clientView];
    TextStorage          *textStorage=(TextStorage *)[textView textStorage];
    NSString                    *text=[textView string];
    NSScrollView          *scrollView=[textView enclosingScrollView];
    NSLayoutManager    *layoutManager=[textView layoutManager];
    NSRect visibleRect=[scrollView documentVisibleRect];
    NSPoint point=visibleRect.origin;
    point.y+=aRect.origin.y+1.;
    unsigned glyphIndex,characterIndex;
    NSString *lineNumberString;
    NSRect bounds = [self bounds];
    NSRect boundingRect,previousBoundingRect,lineFragmentRectForLastCharacter;
    NSColor *delimiterLineColor = [NSColor colorWithCalibratedWhite:0.5 alpha:1.0];
    NSColor *triangleColor      = [NSColor colorWithCalibratedWhite:0.1 alpha:1.0];
    NSColor *triangleHighlightColor      = [NSColor selectedControlColor];

	NSRange longestEffectiveAttachmentRange;
    NSRange lineRange;
    unsigned lineNumber;
    unsigned maxRange;
    unsigned cardinalityComparitor=10;
    unsigned cardinality=1;

	double ruleThickness = [self ruleThickness];
	double rightHandAlignment = ruleThickness - FOLDING_BAR_WIDTH - RIGHT_INSET;

	NSRect foldingAreaRect  = [self baseRectForFoldingBar];
	[delimiterLineColor set];
	[NSBezierPath strokeLineFromPoint:NSMakePoint(foldingAreaRect.origin.x-1.5,bounds.origin.y) 
							  toPoint:NSMakePoint(foldingAreaRect.origin.x-1.5,NSMaxY(bounds))];

    if ([textStorage length]) {
    

        boundingRect=NSMakeRect(0,0,0,0);
        previousBoundingRect=boundingRect;
        glyphIndex=[layoutManager glyphIndexForPoint:point 
                                     inTextContainer:[textView textContainer]];
        characterIndex=[layoutManager characterIndexForGlyphAtIndex:glyphIndex];
        boundingRect  =[layoutManager lineFragmentRectForGlyphAtIndex:glyphIndex 
                                                       effectiveRange:nil];
        lineNumber=[textStorage lineNumberForLocation:characterIndex];
        
        while (lineNumber>=cardinalityComparitor) {
            cardinalityComparitor*=10;
            cardinality++;
        }
        
        if (characterIndex==[text lineRangeForRange:NSMakeRange(characterIndex,0)].location) {
            [[NSColor blackColor] set];
            lineNumberString=[NSString stringWithFormat:@"%u",lineNumber];
            [lineNumberString drawAtPoint:NSMakePoint(rightHandAlignment-(sizeOfZero.width*cardinality),
                                                      NSMaxY(boundingRect)-visibleRect.origin.y-sizeOfZero.height
                                                      -(boundingRect.size.height-sizeOfZero.height)/2.-1.) 
                           withAttributes:attributes];

        }
        
        BOOL goOn = YES;

        lineRange=[text lineRangeForRange:NSMakeRange(characterIndex,0)];
        maxRange=NSMaxRange(lineRange);

		glyphIndex=[layoutManager glyphRangeForCharacterRange:NSMakeRange(maxRange-1,1) 
										 actualCharacterRange:nil].location;
        lineFragmentRectForLastCharacter=[layoutManager lineFragmentRectForGlyphAtIndex:glyphIndex 
                                                               effectiveRange:nil];

		foldingAreaRect.origin.y = boundingRect.origin.y - visibleRect.origin.y;
        foldingAreaRect.size.height = NSMaxY(lineFragmentRectForLastCharacter) - boundingRect.origin.y;
       	
       	NSColor *depthColor = [self colorForLineRange:lineRange inTextStorage:textStorage];
		[depthColor set];
        NSRectFill(foldingAreaRect);

		if (lineRange.length) {
			[textStorage attribute:NSAttachmentAttributeName atIndex:lineRange.location longestEffectiveRange:&longestEffectiveAttachmentRange inRange:lineRange];
			if (!NSEqualRanges(lineRange,longestEffectiveAttachmentRange)) {
				// there is an attachment of some kind in our line. so show it
				[((I_lastMouseDownPoint.y >= boundingRect.origin.y && I_lastMouseDownPoint.y <= NSMaxY(boundingRect)) ? triangleHighlightColor : triangleColor) set];
				[NSBezierPath fillTriangleInRect:NSMakeRect(foldingAreaRect.origin.x+1, NSMaxY(boundingRect)-visibleRect.origin.y - FOLDING_BAR_WIDTH - (boundingRect.size.height-FOLDING_BAR_WIDTH - 3)/2. ,FOLDING_BAR_WIDTH - 4,FOLDING_BAR_WIDTH - 2) arrowPoint:NSMaxXEdge];
			}
		}

        while (NSMaxY(previousBoundingRect)<NSMaxY(boundingRect) && 
               NSMaxY(boundingRect)<visibleRect.origin.y+NSMaxY(aRect) &&
               goOn) {
            lineRange=[text lineRangeForRange:NSMakeRange(maxRange,0)];
            if (maxRange==NSMaxRange(lineRange)) {
                if ([textStorage lastLineIsEmpty]) {
                    goOn = NO;
                } else {
                    break;
                }
            }
            maxRange=NSMaxRange(lineRange);
			lineNumber=[textStorage lineNumberForLocation:lineRange.location];
//            lineNumber++;
            while (lineNumber>=cardinalityComparitor) {
                cardinalityComparitor*=10;
                cardinality++;
            }
            
            if (goOn) {
                glyphIndex=[layoutManager glyphRangeForCharacterRange:NSMakeRange(lineRange.location,1) 
                                                 actualCharacterRange:nil].location;
                previousBoundingRect = boundingRect;
                boundingRect  =[layoutManager lineFragmentRectForGlyphAtIndex:glyphIndex 
                                                               effectiveRange:nil];
            } else {
                glyphIndex=[layoutManager glyphRangeForCharacterRange:NSMakeRange(maxRange-1,1) 
                                                 actualCharacterRange:nil].location;
                previousBoundingRect = boundingRect;
                boundingRect  =[layoutManager lineFragmentRectForGlyphAtIndex:glyphIndex 
                                                               effectiveRange:nil];
                boundingRect.origin.y += boundingRect.size.height;
            }
            lineNumberString=[NSString stringWithFormat:@"%u",lineNumber];
            [lineNumberString drawAtPoint:NSMakePoint(rightHandAlignment-(+sizeOfZero.width*cardinality),
                                                      NSMaxY(boundingRect)-visibleRect.origin.y-sizeOfZero.height
                                                      -(boundingRect.size.height-sizeOfZero.height)/2.-1.) 
                           withAttributes:attributes];

			glyphIndex=[layoutManager glyphRangeForCharacterRange:NSMakeRange(maxRange-1,1) 
											 actualCharacterRange:nil].location;
			lineFragmentRectForLastCharacter=[layoutManager lineFragmentRectForGlyphAtIndex:glyphIndex 
																   effectiveRange:nil];
	
			foldingAreaRect.origin.y = boundingRect.origin.y - visibleRect.origin.y;
			foldingAreaRect.size.height = NSMaxY(lineFragmentRectForLastCharacter) - boundingRect.origin.y;

			if (lineRange.length > 0) {
				depthColor = [self colorForLineRange:lineRange inTextStorage:textStorage];;
			}
			[depthColor set];
			NSRectFill(foldingAreaRect);

			if (lineRange.length) {
				[textStorage attribute:NSAttachmentAttributeName atIndex:lineRange.location longestEffectiveRange:&longestEffectiveAttachmentRange inRange:lineRange];
				if (!NSEqualRanges(lineRange,longestEffectiveAttachmentRange)) {
					// there is an attachment of some kind in our line. so show it
//					NSLog(@"%s mouseDown:%@ boundingRect:%@",__FUNCTION__,NSStringFromPoint(I_lastMouseDownPoint),NSStringFromRect(boundingRect));
					[((I_lastMouseDownPoint.y >= boundingRect.origin.y && I_lastMouseDownPoint.y <= NSMaxY(boundingRect)) ? triangleHighlightColor : triangleColor) set];
					[NSBezierPath fillTriangleInRect:NSMakeRect(foldingAreaRect.origin.x+1, NSMaxY(boundingRect)-visibleRect.origin.y - FOLDING_BAR_WIDTH - (boundingRect.size.height-FOLDING_BAR_WIDTH - 3)/2. ,FOLDING_BAR_WIDTH - 4,FOLDING_BAR_WIDTH - 2) arrowPoint:NSMaxXEdge];
				}
			}
        }
 
        
        
        float potentialNewWidth=8.+sizeOfZero.width*cardinality + FOLDING_BAR_WIDTH + RIGHT_INSET;
        if ([self ruleThickness]<potentialNewWidth) {
            [self setRuleThickness:ceil(potentialNewWidth)];
        }
    }
}

- (void)mouseDown:(NSEvent *)anEvent {
	// check for click in folding gutter
	NSPoint point = [self convertPoint:[anEvent locationInWindow] fromView:nil];
	NSRect baseRect = [self baseRectForFoldingBar];
	if (point.x >= baseRect.origin.x && point.x <= NSMaxX(baseRect)) {
		I_lastMouseDownPoint = point;
		// now get the line - and if a folding is in that line expand the folding
		NSTextView              *textView=(NSTextView *)[self clientView];
		FoldableTextStorage  *textStorage=(FoldableTextStorage *)[textView textStorage];
		NSString                    *text=[textView string];
		NSScrollView          *scrollView=[textView enclosingScrollView];
		NSLayoutManager    *layoutManager=[textView layoutManager];
        unsigned glyphIndex=[layoutManager glyphIndexForPoint:NSMakePoint(0.0,point.y) 
                                     inTextContainer:[textView textContainer]];
        unsigned characterIndex=[layoutManager characterIndexForGlyphAtIndex:glyphIndex];
        NSRect boundingRect  =[layoutManager lineFragmentRectForGlyphAtIndex:glyphIndex 
                                                       effectiveRange:nil];
        NSRange lineRange=[text lineRangeForRange:NSMakeRange(characterIndex,0)];
        NSRange attributeRange = NSMakeRange(lineRange.location,0);
        id attachment = nil;
        do {
			attachment = [textStorage attribute:NSAttachmentAttributeName atIndex:NSMaxRange(attributeRange) longestEffectiveRange:&attributeRange inRange:lineRange];
		} while (!attachment && NSMaxRange(attributeRange) < NSMaxRange(lineRange));

		if (attachment) {
			[self setNeedsDisplay:YES];
			// wait for mouseup and make the action if still inside the area
			while (1) {
		        NSEvent *event = [[self window] nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask)];
				NSPoint innerPoint = [self convertPoint:[event locationInWindow] fromView:nil];
				BOOL pointWasIn = (innerPoint.x >= baseRect.origin.x && innerPoint.x <= NSMaxX(baseRect) && innerPoint.y >= boundingRect.origin.y && innerPoint.y <= NSMaxY(boundingRect));
				if ([event type] == NSLeftMouseDragged) {
					if (pointWasIn && NSEqualPoints(I_lastMouseDownPoint,NSZeroPoint)) {
						I_lastMouseDownPoint = point;
						[self setNeedsDisplay:YES];
					} else if (!pointWasIn && !NSEqualPoints(I_lastMouseDownPoint,NSZeroPoint)) {
						I_lastMouseDownPoint = NSZeroPoint;
						[self setNeedsDisplay:YES];
					}
				} else if ([event type] == NSLeftMouseUp) {
					if (pointWasIn) {
						[textStorage unfoldAttachment:attachment atCharacterIndex:attributeRange.location];
					}
					I_lastMouseDownPoint = NSZeroPoint;
					[self setNeedsDisplay:YES];
					break;
				}
			}
		}
	} else {
		// else call super so the delegate can handle
		[super mouseDown:anEvent];
	}
}


@end
