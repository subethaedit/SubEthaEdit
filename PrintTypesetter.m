//
//  PrintTypesetter.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 15.09.04.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "PrintTypesetter.h"
#import "PlainTextDocument.h"


@implementation PrintTypesetter

- (void)willSetLineFragmentRect:(NSRect *)lineFragmentRect forGlyphRange:(NSRange)glyphRange 
        usedRect:(NSRect *)usedRect baselineOffset:(CGFloat *)baselineOffset {
    NSLayoutManager *layout = [self layoutManager];
    NSTextStorage *text = [layout textStorage];
    NSRange charRange;
    float spaceToAddBelow = -12.0;
    unsigned i;
    
    // Convert the glyph range to a character range.
    charRange = [layoutManager characterRangeForGlyphRange:glyphRange actualGlyphRange:NULL];
    NSUInteger startIndex, lineEndIndex, contentsEndIndex;
    [[text string] getLineStart:&startIndex end:&lineEndIndex contentsEnd:&contentsEndIndex forRange:charRange];
    if (NSMaxRange(charRange)>contentsEndIndex) {
        charRange.length=contentsEndIndex-charRange.location;
    }
    NSRange range;
    // Iterate through the character range.
    for (i = charRange.location; 
         i < NSMaxRange(charRange); 
         i = NSMaxRange(range)) {
        
        // If there are annotations, note the maximum space required.
        id bottomAnnotation = [text attribute:@"AnnotateID" atIndex:i longestEffectiveRange:&range inRange:charRange];
        if (bottomAnnotation) {
            spaceToAddBelow = 0.;
            break;
        }
    }
    
    // Adjust the line fragment accordingly.
    lineFragmentRect->size.height += spaceToAddBelow;
    usedRect->size.height += spaceToAddBelow;
}

@end
