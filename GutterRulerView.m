//
//  GutterRulerView.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Mon May 05 2003.
//  Copyright (c) 2003 TheCodingMonkeys. All rights reserved.
//

#import "GutterRulerView.h"

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

- (void)drawHashMarksAndLabelsInRect:(NSRect)aRect {
    [[NSColor blackColor] set];
    
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
    NSRect boundingRect,previousBoundingRect;

    NSRange lineRange;
    unsigned lineNumber;
    unsigned maxRange;
    unsigned cardinalityComparitor=10;
    unsigned cardinality=1;

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
            [lineNumberString drawAtPoint:NSMakePoint([self ruleThickness]-(4+sizeOfZero.width*cardinality),
                                                      NSMaxY(boundingRect)-visibleRect.origin.y-sizeOfZero.height
                                                      -(boundingRect.size.height-sizeOfZero.height)/2.-1.) 
                           withAttributes:attributes];

        }
        lineRange=[text lineRangeForRange:NSMakeRange(characterIndex,0)];
        maxRange=NSMaxRange(lineRange);
        
        while (NSMaxY(previousBoundingRect)<NSMaxY(boundingRect) && 
               NSMaxY(boundingRect)<visibleRect.origin.y+NSMaxY(aRect)) {
            lineRange=[text lineRangeForRange:NSMakeRange(maxRange,0)];
            if (maxRange==NSMaxRange(lineRange)) {
                break;
            }
            maxRange=NSMaxRange(lineRange);
            lineNumber++;
            while (lineNumber>=cardinalityComparitor) {
                cardinalityComparitor*=10;
                cardinality++;
            }

            glyphIndex=[layoutManager glyphRangeForCharacterRange:NSMakeRange(lineRange.location,1) 
                                             actualCharacterRange:nil].location;
            boundingRect  =[layoutManager lineFragmentRectForGlyphAtIndex:glyphIndex 
                                                           effectiveRange:nil];
            lineNumberString=[NSString stringWithFormat:@"%u",lineNumber];
            [lineNumberString drawAtPoint:NSMakePoint([self ruleThickness]-(4+sizeOfZero.width*cardinality),
                                                      NSMaxY(boundingRect)-visibleRect.origin.y-sizeOfZero.height
                                                      -(boundingRect.size.height-sizeOfZero.height)/2.-1.) 
                           withAttributes:attributes];
        }
        
        float potentialNewWidth=8.+sizeOfZero.width*cardinality;
        if ([self ruleThickness]<potentialNewWidth) {
            [self setRuleThickness:potentialNewWidth];
        }
    }
}

@end
