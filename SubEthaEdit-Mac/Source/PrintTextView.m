//  PrintTextView.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 15.09.04.

#import "PrintTextView.h"
#import "PlainTextDocument.h"
#import "TCMMMUserManager.h"


@implementation PrintTextView

- (id)initWithFrame:(NSRect)frame textContainer:(NSTextContainer *)aTextContainer{
    self = [super initWithFrame:frame textContainer:aTextContainer];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)drawViewBackgroundInRect:(NSRect)rect {    
    NSLayoutManager *layoutManager = [self layoutManager];
    NSTextStorage *textStorage=[self textStorage];
    NSString *textStorageString=[textStorage string];
    NSTextContainer *textContainer=[self textContainer];
    NSPoint containerOrigin = [self textContainerOrigin];
    NSRange completeGlyphRange, lineGlyphRange, lineCharRange;
    TCMMMUserManager *userManager=[TCMMMUserManager sharedInstance];
    static NSMutableDictionary *annotationAttributes=nil;
    if (!annotationAttributes) {
        NSFont *             annotationFont = [NSFont fontWithName:@"Helvetica" size:6.];
        if (!annotationFont) annotationFont = [NSFont systemFontOfSize:6.];
        NSMutableParagraphStyle *paragraphStyle=[[[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
        [paragraphStyle setAlignment:NSTextAlignmentLeft];
        [paragraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];
        annotationAttributes=[[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                annotationFont,NSFontAttributeName,
                                paragraphStyle,NSParagraphStyleAttributeName,
                                nil];
    }
    
    // Draw the background first
    [super drawViewBackgroundInRect:rect];

    NSColor *annotationColor=[[self backgroundColor] isDark]?[NSColor whiteColor]:[NSColor blackColor];
    [annotationAttributes setObject:annotationColor forKey:NSForegroundColorAttributeName];
    // Convert from view to container coordinates, then to the corresponding glyph and character ranges.
    rect.origin.x -= containerOrigin.x;
    rect.origin.y -= containerOrigin.y;
    completeGlyphRange = [layoutManager glyphRangeForBoundingRect:rect inTextContainer:textContainer];

    // Iterate through the GlyphRange, lineFragment by lineFragment
    lineGlyphRange=NSMakeRange(completeGlyphRange.location,0);
    while (NSMaxRange(lineGlyphRange)<NSMaxRange(completeGlyphRange)) {
        [layoutManager lineFragmentRectForGlyphAtIndex:NSMaxRange(lineGlyphRange) effectiveRange:&lineGlyphRange];
        lineCharRange=[layoutManager characterRangeForGlyphRange:lineGlyphRange actualGlyphRange:nil];
        int annotate=0;
        while (annotate<2) {
            id value=nil;
            NSString *IDAttributeName=annotate?@"AnnotateID":@"PrintBackgroundColour";
            NSRange foundRange=NSMakeRange(lineCharRange.location,0);
            while (NSMaxRange(foundRange)<NSMaxRange(lineCharRange)) {
                value=[textStorage attribute:IDAttributeName atIndex:NSMaxRange(foundRange) longestEffectiveRange:&foundRange inRange:lineCharRange];
                if (value) {
                    NSUInteger rectCount;
                    NSUInteger startIndex, lineEndIndex, contentsEndIndex;
                    [textStorageString getLineStart:&startIndex end:&lineEndIndex contentsEnd:&contentsEndIndex forRange:foundRange];
                    NSRange glyphRange=[layoutManager glyphRangeForCharacterRange:NSMaxRange(foundRange)==lineEndIndex?NSMakeRange(foundRange.location, contentsEndIndex-foundRange.location):foundRange actualCharacterRange:nil];
                    NSRectArray rects=[layoutManager rectArrayForGlyphRange:glyphRange withinSelectedGlyphRange:glyphRange inTextContainer:textContainer rectCount:&rectCount];
                    if (rectCount>0) {
                        NSRect drawRect=rects[0];
                        int i=1;
                        for (i=1;i<rectCount;i++) {
                            drawRect=NSUnionRect(drawRect,rects[i]);
                        }
                        
                        if (drawRect.size.width>0) { // this is needed cause zero width rects occur
                            drawRect.origin.x+=containerOrigin.x;
                            drawRect.origin.y+=containerOrigin.y;
                            if (annotate) {
                                NSString *annotateText=[[userManager userForUserID:value] name];
                            
                                drawRect.origin.y+=drawRect.size.height-10.;
                                drawRect.size.height=10.;
                                drawRect.size.width-=2.;
                                drawRect.origin.x+=1.;
                                [annotateText drawInRect:drawRect withAttributes:annotationAttributes];
                                drawRect.origin.y-=2.;
                                drawRect.size.height=2.;
                                [annotationColor set];
                                NSBezierPath *monochromePath=[NSBezierPath bezierPath];
                                [monochromePath moveToPoint:drawRect.origin];
                                [monochromePath relativeLineToPoint:NSMakePoint(0.,drawRect.size.height)];
                                [monochromePath relativeLineToPoint:NSMakePoint(drawRect.size.width,0.)];
                                [monochromePath relativeLineToPoint:NSMakePoint(0.,-drawRect.size.height)];
                                [monochromePath setLineWidth:0.2];
                                [monochromePath stroke];
                            } else {
                                [(NSColor *)value set]; // NSColor
                                NSRectFill(drawRect);
                            }
                            
                        } 
                    }
                }
            }
            
            annotate++;
        }
    }
}


@end
