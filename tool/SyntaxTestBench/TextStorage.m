//
//  TextStorage.m
//  SubEthaEdit
//
//  Created by Martin Ott on Fri May 02 2003.
//  Copyright (c) 2003 TheCodingMonkeys. All rights reserved.
//

#import "TextStorage.h"


@implementation TextStorage

- (id)init {
    self=[super init];
    _contents=[NSMutableAttributedString new];
    _lineStarts=[NSMutableArray new];
    [_lineStarts addObject:[NSNumber numberWithUnsignedInt:0]];
    _lineStartsValidUpTo=0;
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_contents release];
    [_lineStarts  release];
    [super dealloc];
}

#pragma mark ### Line Numbers ###

- (int)lineNumberForLocation:(unsigned)aLocation {

    // validate _lineStarts array
    int i;
    for (i=[_lineStarts count]-1;i>=0;i--) {
        if ([[_lineStarts objectAtIndex:i] unsignedIntValue]<=_lineStartsValidUpTo) {
            break;
        } else {
            [_lineStarts removeObjectAtIndex:i];    
        }
    }
    NSAssert(i>=0,@"Failure in lineNumberForLocation");
    int result=0;
    if (!(aLocation<=_lineStartsValidUpTo)) {
        NSString *string=[self string];
        i=[_lineStarts count]-1;
        unsigned lineStart=[[_lineStarts objectAtIndex:i] intValue];
        NSRange lineRange=[string lineRangeForRange:NSMakeRange(lineStart,0)];
        _lineStartsValidUpTo=NSMaxRange(lineRange)-1;
        while (NSMaxRange(lineRange)<[string length] && _lineStartsValidUpTo<aLocation) {
            lineRange=[string lineRangeForRange:NSMakeRange(NSMaxRange(lineRange),0)];
            [_lineStarts addObject:[NSNumber numberWithUnsignedInt:lineRange.location]];
            _lineStartsValidUpTo=NSMaxRange(lineRange)-1;
        }
    }
    for (i=[_lineStarts count]-1;i>=0;i--) {
        if ([[_lineStarts objectAtIndex:i] unsignedIntValue]<=aLocation) {
            result=i+1;
            break;
        }
    }
    return result;
}

- (NSMutableArray *)lineStarts {
    return _lineStarts;
}

- (void)setLineStartsOnlyValidUpTo:(unsigned int)aLocation {
    if (aLocation<_lineStartsValidUpTo) {
        _lineStartsValidUpTo=aLocation;
    }
}

// - (void)fixParagraphStyleAttributeInRange:(NSRange)aRange {
//     [super fixParagraphStyleAttributeInRange:aRange];
// 
//     NSDictionary *blockeditAttributes=[[PreferenceController sharedInstance] blockeditAttributes];
// 
//     NSString *string=[self string];
//     NSRange lineRange=[string lineRangeForRange:aRange];
//     NSRange blockeditRange;
//     id value;
//     unsigned position=lineRange.location;
//     while (position<NSMaxRange(lineRange)) {
//         value=[self attribute:kBlockeditAttributeName atIndex:position
//                             longestEffectiveRange:&blockeditRange inRange:lineRange];
//         if (value) {
//             NSRange blockLineRange=[string lineRangeForRange:blockeditRange];
//             if (!NSEqualRanges(blockLineRange,blockeditRange)) {
//                 blockeditRange=blockLineRange;
//                 [self addAttributes:blockeditAttributes range:blockeditRange];
//             }
//         }
//         position=NSMaxRange(blockeditRange);
//     }
// }


#pragma mark -
#pragma mark ### Abstract Primitives of NSTextStorage ###
- (NSString *)string {
    return [_contents string];
}

- (NSDictionary *)attributesAtIndex:(unsigned)aIndex 
                     effectiveRange:(NSRangePointer)aRange {
    return [_contents attributesAtIndex:aIndex effectiveRange:aRange];
}

- (void)replaceCharactersInRange:(NSRange)aRange withString:(NSString *)aString {
    unsigned origLen = [_contents length];
    [_contents replaceCharactersInRange:aRange withString:aString];
    [self edited:NSTextStorageEditedCharacters range:aRange 
          changeInLength:[_contents length] - origLen];
}

- (void)setAttributes:(NSDictionary *)attributes range:(NSRange)aRange {
    [_contents setAttributes:attributes range:aRange];
    [self edited:NSTextStorageEditedAttributes range:aRange 
          changeInLength:0];
}

@end
