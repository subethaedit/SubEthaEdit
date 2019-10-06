//  GutterRulerView.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Mon May 05 2003.

#import "GutterRulerView.h"
#import "SyntaxHighlighter.h"
#import "FoldableTextStorage.h"
#import "SEETextView.h"
#import "PlainTextEditor.h"


@interface NSBezierPath (BezierPathGutterRulerViewAdditions)
+ (NSBezierPath *)trianglePathInRect:(NSRect)aRect arrowPoint:(NSRectEdge)anEdge;
+ (void)fillTriangleInRect:(NSRect)aRect arrowPoint:(NSRectEdge)anEdge;
@end



#define FOLDING_BAR_WIDTH 11.
#define RIGHT_INSET  4.
#define MAX_FOLDING_DEPTH (12)

static NSColor *S_colorForDepth[MAX_FOLDING_DEPTH];
static NSColor *S_searchScopeColorForDepth[MAX_FOLDING_DEPTH];

FOUNDATION_STATIC_INLINE void DrawIndicatorForDepthInRect(int aDepth, NSRect aRect, BOOL isSearchScope, NSDictionary<NSString *, id> *colors) {
	[(NSColor *)(isSearchScope ? colors[@"SearchScopeSteps"] : colors[@"FoldingBarSteps"])[MIN(aDepth,(MAX_FOLDING_DEPTH - 1))] set];
	NSRectFill(aRect); 
	if (aDepth >= MAX_FOLDING_DEPTH) {
		[(NSColor *)colors[@"FoldingBarSteps"][MAX(MAX_FOLDING_DEPTH - (aDepth - MAX_FOLDING_DEPTH) - 2,0)] set];
		NSRect rectToFill = NSOffsetRect(NSInsetRect(aRect,2.5,0),2.5,0);
		NSRectFill(rectToFill);
	}
}

@implementation NSBezierPath (BezierPathGutterRulerViewAdditions)
+ (NSBezierPath *)trianglePathInRect:(NSRect)aRect arrowPoint:(NSRectEdge)anEdge {
	aRect = NSInsetRect(aRect,0.5,0.5);
	NSBezierPath *path = [NSBezierPath bezierPath];
	[path setLineWidth:1.0];
	[path setLineJoinStyle:NSMiterLineJoinStyle];
	[path moveToPoint:aRect.origin];
	[path lineToPoint:NSMakePoint(aRect.origin.x,NSMaxY(aRect))];
	[path lineToPoint:NSMakePoint(NSMaxX(aRect)-1,aRect.origin.y + aRect.size.height / 2.0)];
	[path closePath];
	return path;
}
+ (void)fillTriangleInRect:(NSRect)aRect arrowPoint:(NSRectEdge)anEdge {
	NSBezierPath *path = [NSBezierPath trianglePathInRect:aRect arrowPoint:anEdge];
	[path fill];
}
@end

@implementation GutterRulerView {
    NSPoint I_lastMouseDownPoint;
}

- (instancetype)initWithScrollView:(NSScrollView *)aScrollView
             orientation:(NSRulerOrientation)orientation {
    self = [super initWithScrollView:aScrollView orientation:orientation];
    return self;
}

- (void)drawRect:(NSRect)aRect {
//    NSLog(@"bounds:%@",NSStringFromRect([self bounds]));
//    NSLog(@"frame:%@",NSStringFromRect([self frame]));
//    NSLog(@"drawRect:%@",NSStringFromRect(aRect));
    [super drawRect:aRect];
}

- (NSRect)baseRectForFoldingBar {
	double ruleThickness = [self ruleThickness];
	double rightHandAlignment = ruleThickness - FOLDING_BAR_WIDTH - RIGHT_INSET;
	return NSMakeRect(rightHandAlignment + RIGHT_INSET + 1.0,0,FOLDING_BAR_WIDTH-3.0,0);
}

- (NSDictionary *)colorsForDark:(BOOL)isDark {

    static NSMutableDictionary<NSString *, NSColor *> *brightColors;
    static NSMutableDictionary<NSString *, NSColor *> *darkColors;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        brightColors = [@{
          @"GutterBackground" : [NSColor colorWithWhite:0.9 alpha:1.0],
          @"FontColor" : [NSColor colorWithCalibratedWhite:0.39 alpha:1.0],
          @"DelimiterLine" : [NSColor colorWithCalibratedWhite:0.5 alpha:1.0],
          @"TriangleFill" : [NSColor colorWithCalibratedWhite:1.0 alpha:1.0],
          @"TriangleStroke" : [NSColor colorWithCalibratedWhite:0.0 alpha:0.4],
          @"TriangleHighlightFill" : [NSColor selectedControlColor],
          @"TriangleHighlightStroke" : [NSColor whiteColor],
          @"GutterMin" : [NSColor whiteColor],
          @"GutterMax" : [NSColor blackColor],
          } mutableCopy];
        
        darkColors = [NSMutableDictionary new];
        [brightColors enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSColor *color, BOOL *_stop) {
            darkColors[key] = [color brightnessInvertedColor];
        }];
        darkColors[@"DelimiterLine"] = [NSColor colorWithCalibratedWhite:0.29 alpha: 1.0];
        
        for (NSMutableDictionary *colors in @[darkColors, brightColors]) {
            NSMutableArray *foldingColors = [NSMutableArray new];
            NSMutableArray *searchScopeColors = [NSMutableArray new];
            NSColor *minColor = colors[@"GutterMin"];
            NSColor *maxColor = colors[@"GutterMax"];
            for (int i=0; i<MAX_FOLDING_DEPTH; i++) {
                NSColor *color = [maxColor blendedColorWithFraction:MAX(1.0 - ((MAX((i+0.5), 0.0) - 0) / (double)MAX_FOLDING_DEPTH), 0.0) ofColor:minColor];
                [foldingColors addObject:color];
                [searchScopeColors addObject:[color blendedColorWithFraction:0.5 ofColor:[NSColor searchScopeBaseColor]]];
            }
            colors[@"FoldingBarSteps"] = foldingColors;
            colors[@"SearchScopeSteps"] = searchScopeColors;
        }
    });

    return isDark ? darkColors : brightColors;
}

- (void)drawHashMarksAndLabelsInRect:(NSRect)aRect {

    static NSSize sizeOfZero;
    static void(^drawLineNumber)(NSUInteger aLineNumber, unsigned aCardinality, CGFloat aRightHandAlignment, NSRect aLineBoundingRect, CGFloat aTotalYOffset) = nil;

    BOOL isDark = NO;
    if (@available(macOS 10.14, *)) {
        static BOOL wasDark = NO;
        if (self.scrollView.effectiveAppearance.SEE_isDark) {
            if (!wasDark) { drawLineNumber = nil; }
            wasDark = YES;
            isDark = YES;
        } else {
            if (wasDark) { drawLineNumber = nil; }
            wasDark = NO;
        }
    }
    
    NSDictionary<NSString *, NSColor *> *colors = [self colorsForDark:isDark];
    
	[colors[@"GutterBackground"] set];
	NSRectFill(aRect);
    
	if (!drawLineNumber) {
		CGFloat linenumberFontSize=9.;
			NSFont *font=[NSFont fontWithName:@"Tahoma" size:linenumberFontSize];
			if (!font) font=[NSFont systemFontOfSize:linenumberFontSize];
			NSDictionary *attributes=[NSDictionary dictionaryWithObjectsAndKeys:
						 font,NSFontAttributeName,
						 colors[@"FontColor"],NSForegroundColorAttributeName,
						 nil];
			sizeOfZero=[@"0" sizeWithAttributes:attributes];
		
		drawLineNumber = ^(NSUInteger aLineNumber, unsigned aCardinality, CGFloat aRightHandAlignment, NSRect aLineBoundingRect, CGFloat aTotalYOffset) {
			NSString *lineNumberString=[NSString stringWithFormat:@"%llu",(unsigned long long)aLineNumber];
			[lineNumberString drawAtPoint:NSMakePoint(aRightHandAlignment-(sizeOfZero.width*aCardinality),
													  ceil(NSMaxY(aLineBoundingRect)+aTotalYOffset -sizeOfZero.height
														   -(aLineBoundingRect.size.height-sizeOfZero.height)/2.-2.))
						   withAttributes:attributes];
			
        };
    }

    NSTextView              *textView=(NSTextView *)[self clientView];
    FoldableTextStorage  *textStorage=(FoldableTextStorage *)[textView textStorage];
	PlainTextEditor           *editor=[(SEETextView *)textView editor];
    NSString                    *text=[textView string];
    NSScrollView          *scrollView=[textView enclosingScrollView];
    NSLayoutManager    *layoutManager=[textView layoutManager];
    NSRect visibleRect=[scrollView documentVisibleRect];
	CGFloat textContainerInsetTopY = [textView textContainerOrigin].y;
	CGFloat totalYOffset = -visibleRect.origin.y + textContainerInsetTopY;
	
	
    NSPoint point=visibleRect.origin;
    point.y+=aRect.origin.y+1. - 150.;
    unsigned glyphIndex,characterIndex;
    NSRect bounds = [self bounds];
    NSRect boundingRect,previousBoundingRect,lineFragmentRectForLastCharacter;
    NSColor *delimiterLineColor = colors[@"DelimiterLine"];
    NSColor *triangleColor      = colors[@"TriangleFill"];
    NSColor *triangleStrokeColor= colors[@"TriangleStroke"];
    NSColor *triangleHighlightColor      = colors[@"TriangleHighlightFill"];
    NSColor *triangleHighlightStrokeColor= colors[@"TriangleHighlightStroke"];

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
	[NSBezierPath strokeLineFromPoint:NSMakePoint(CGRectGetMaxX(foldingAreaRect)+1.5,bounds.origin.y)
							  toPoint:NSMakePoint(CGRectGetMaxX(foldingAreaRect)+1.5,NSMaxY(bounds))];
	NSRect fullFoldingAreaRect = [self bounds];
	fullFoldingAreaRect.origin.x = foldingAreaRect.origin.x;
	fullFoldingAreaRect.size.width = foldingAreaRect.size.width;
	[colors[@"GutterMin"] set];
	NSRectFill(fullFoldingAreaRect);

    if (self.suspendDrawing) {
        return;
    }

	
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
			drawLineNumber(lineNumber, cardinality, rightHandAlignment, boundingRect, totalYOffset);
        }
        
        BOOL goOn = YES;

        lineRange=[text lineRangeForRange:NSMakeRange(characterIndex,0)];
        maxRange=NSMaxRange(lineRange);

		glyphIndex=[layoutManager glyphRangeForCharacterRange:NSMakeRange(maxRange-1,1) 
										 actualCharacterRange:nil].location;
        lineFragmentRectForLastCharacter=[layoutManager lineFragmentRectForGlyphAtIndex:glyphIndex 
                                                               effectiveRange:nil];

		foldingAreaRect.origin.y = boundingRect.origin.y - visibleRect.origin.y + textContainerInsetTopY;
        foldingAreaRect.size.height = NSMaxY(lineFragmentRectForLastCharacter) - boundingRect.origin.y;
       	
       	int foldingDepth = [textStorage foldingDepthForLine:lineNumber];
		BOOL shouldShowSearchScope = [(PlainTextWindowController *)editor.textView.window.windowController isShowingFindAndReplaceInterface];
		BOOL isSearchScope = shouldShowSearchScope &&
		[editor hasSearchScopeInFullRange:[textStorage fullRangeForFoldedRange:lineRange]];
       	DrawIndicatorForDepthInRect(foldingDepth, foldingAreaRect, isSearchScope, colors);
		
		if (lineRange.length) {
			[textStorage attribute:NSAttachmentAttributeName atIndex:lineRange.location longestEffectiveRange:&longestEffectiveAttachmentRange inRange:lineRange];
			if (!NSEqualRanges(lineRange,longestEffectiveAttachmentRange)) {
				BOOL isHighlighted = (!NSEqualPoints(I_lastMouseDownPoint,NSZeroPoint) && I_lastMouseDownPoint.y >= boundingRect.origin.y && I_lastMouseDownPoint.y <= NSMaxY(boundingRect));
				// there is an attachment of some kind in our line. so show it
				NSBezierPath *trianglePath = [NSBezierPath trianglePathInRect:NSMakeRect(foldingAreaRect.origin.x+1, NSMaxY(boundingRect)+totalYOffset - FOLDING_BAR_WIDTH - (boundingRect.size.height-FOLDING_BAR_WIDTH - 3)/2. ,FOLDING_BAR_WIDTH - 4,FOLDING_BAR_WIDTH - 2) arrowPoint:NSMaxXEdge];
				[(isHighlighted ? triangleHighlightColor : triangleColor) set];
				[trianglePath fill];
				[(isHighlighted ? triangleHighlightStrokeColor : triangleStrokeColor) set];
				[trianglePath stroke];
			}
		}

        while (NSMaxY(previousBoundingRect)<NSMaxY(boundingRect) && 
               NSMaxY(boundingRect)<visibleRect.origin.y + textContainerInsetTopY +NSMaxY(aRect) &&
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
			drawLineNumber(lineNumber, cardinality, rightHandAlignment, boundingRect, totalYOffset);

			glyphIndex=[layoutManager glyphRangeForCharacterRange:NSMakeRange(maxRange-1,1) 
											 actualCharacterRange:nil].location;
			lineFragmentRectForLastCharacter=[layoutManager lineFragmentRectForGlyphAtIndex:glyphIndex 
																   effectiveRange:nil];
	
			foldingAreaRect.origin.y = boundingRect.origin.y - visibleRect.origin.y + textContainerInsetTopY;
			foldingAreaRect.size.height = NSMaxY(lineFragmentRectForLastCharacter) - boundingRect.origin.y;

			if (lineRange.length > 0) {
				foldingDepth = [textStorage foldingDepthForLine:lineNumber];
				BOOL isSearchScope = shouldShowSearchScope &&
				[editor hasSearchScopeInFullRange:[textStorage fullRangeForFoldedRange:lineRange]];
				DrawIndicatorForDepthInRect(foldingDepth, foldingAreaRect, isSearchScope, colors);
			} else {
				[colors[@"GutterMin"] set];
				NSRectFill(foldingAreaRect);
			}

			if (lineRange.length) {
				[textStorage attribute:NSAttachmentAttributeName atIndex:lineRange.location longestEffectiveRange:&longestEffectiveAttachmentRange inRange:lineRange];
				if (!NSEqualRanges(lineRange,longestEffectiveAttachmentRange)) {
					BOOL isHighlighted = (!NSEqualPoints(I_lastMouseDownPoint,NSZeroPoint) && I_lastMouseDownPoint.y + visibleRect.origin.y - textContainerInsetTopY >= boundingRect.origin.y && I_lastMouseDownPoint.y  + visibleRect.origin.y - textContainerInsetTopY <= NSMaxY(boundingRect));
					// there is an attachment of some kind in our line. so show it
//					NSLog(@"%s mouseDown:%@ boundingRect:%@",__FUNCTION__,NSStringFromPoint(I_lastMouseDownPoint),NSStringFromRect(boundingRect));
					NSBezierPath *trianglePath = [NSBezierPath trianglePathInRect:NSMakeRect(foldingAreaRect.origin.x+1, NSMaxY(boundingRect)+totalYOffset - FOLDING_BAR_WIDTH - (boundingRect.size.height-FOLDING_BAR_WIDTH - 3)/2. ,FOLDING_BAR_WIDTH - 4,FOLDING_BAR_WIDTH - 2) arrowPoint:NSMaxXEdge];
					[(isHighlighted ? triangleHighlightColor : triangleColor) set];
					[trianglePath fill];
					[(isHighlighted ? triangleHighlightStrokeColor : triangleStrokeColor) set];
					[trianglePath stroke];

				}
			}
        }
 
        
        
        float potentialNewWidth=5.+sizeOfZero.width*cardinality + FOLDING_BAR_WIDTH + RIGHT_INSET;
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
		NSRect visibleRect=[scrollView documentVisibleRect];
		CGFloat textContainerInsetTopY = [textView textContainerOrigin].y;

		NSLayoutManager    *layoutManager=[textView layoutManager];
        unsigned glyphIndex=[layoutManager glyphIndexForPoint:NSMakePoint(0.0,point.y + visibleRect.origin.y - textContainerInsetTopY)
                                     inTextContainer:[textView textContainer] fractionOfDistanceThroughGlyph:NULL];
        unsigned characterIndex=[layoutManager characterIndexForGlyphAtIndex:glyphIndex];
        NSRect boundingRect  =[layoutManager lineFragmentRectForGlyphAtIndex:glyphIndex 
                                                       effectiveRange:nil];
        NSRange lineRange=[text lineRangeForRange:NSMakeRange(characterIndex,0)];
        NSRange attributeRange = NSMakeRange(lineRange.location,0);

		// transform bounding rect to view coordinates
		boundingRect = NSOffsetRect(boundingRect, 0, textContainerInsetTopY);
		

//		NSLog(@"%s bounds:%@ documentVisibleRect:%@",__FUNCTION__,NSStringFromRect([self bounds]),NSStringFromRect(visibleRect));

        id attachment = nil;
        do {
			attachment = [textStorage attribute:NSAttachmentAttributeName atIndex:NSMaxRange(attributeRange) longestEffectiveRange:&attributeRange inRange:lineRange];
		} while (!attachment && NSMaxRange(attributeRange) < NSMaxRange(lineRange));

		if (attachment) {
			[self setNeedsDisplay:YES];
			// wait for mouseup and make the action if still inside the area
			while (1) {
		        NSEvent *event = [[self window] nextEventMatchingMask:(NSEventMaskLeftMouseDragged | NSEventMaskLeftMouseUp)];
				NSPoint innerPoint = [self convertPoint:[event locationInWindow] fromView:nil];
				BOOL pointWasIn = (innerPoint.x >= baseRect.origin.x && innerPoint.x <= NSMaxX(baseRect) && 
								   innerPoint.y + visibleRect.origin.y >= boundingRect.origin.y && innerPoint.y + visibleRect.origin.y <= NSMaxY(boundingRect));
				if ([event type] == NSEventTypeLeftMouseDragged) {
					if (pointWasIn && NSEqualPoints(I_lastMouseDownPoint,NSZeroPoint)) {
						I_lastMouseDownPoint = point;
						[self setNeedsDisplay:YES];
					} else if (!pointWasIn && !NSEqualPoints(I_lastMouseDownPoint,NSZeroPoint)) {
						I_lastMouseDownPoint = NSZeroPoint;
						[self setNeedsDisplay:YES];
					}
				} else if ([event type] == NSEventTypeLeftMouseUp) {
					if (pointWasIn) {
						[textStorage unfoldAttachment:attachment atCharacterIndex:attributeRange.location];
					}
					I_lastMouseDownPoint = NSZeroPoint;
					[self setNeedsDisplay:YES];
					break;
				}
			}
		} else { // no attachment but maybe folding depth - if so show the folding area or even fold if it is a double click
			unsigned lineNumber=[textStorage lineNumberForLocation:lineRange.location];
			if ([textStorage foldingDepthForLine:lineNumber] > 0) {
				NSRange foldingRange = [textStorage foldingRangeForLine:lineNumber];
				if (foldingRange.location != NSNotFound) {
					if ([anEvent clickCount] == 1) {
						// show
	//					if ([textView respondsToSelector:@selector(showFindIndicatorForRange:)]) {
	//						[textView showFindIndicatorForRange:foldingRange];
	//					} else {
							[textView setSelectedRange:foldingRange];
	//					}
					} else if ([anEvent clickCount] == 2) {
						// fold
						[textStorage foldRange:foldingRange];
					}
				}
			}
		}

		// always clear the mousedown point
		I_lastMouseDownPoint = NSZeroPoint;
		[self setNeedsDisplay:YES];
	} else {
		// else call super so the delegate can handle
		[super mouseDown:anEvent];
	}
}

@end
