//
//  TextStorage.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Thu Mar 25 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "TextStorage.h"
#import "EncodingManager.h"


@implementation TextStorage

- (id)init {
    self=[super init];
    if (self) {
        I_contents=[NSMutableAttributedString new];
        I_lineStarts=[NSMutableArray new];
        [I_lineStarts addObject:[NSNumber numberWithUnsignedInt:0]];
        I_lineStartsValidUpTo=0;
        I_encoding=CFStringConvertEncodingToNSStringEncoding(CFStringGetSystemEncoding());
        [[EncodingManager sharedInstance] registerEncoding:I_encoding];
    }
    return self;
}

- (void)dealloc {
    // maybe fixed:
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [I_contents release];
    [I_lineStarts  release];
    [super dealloc];
}

- (unsigned int)encoding {
    return I_encoding;
}

- (void)setEncoding:(unsigned int)anEncoding {
    [[EncodingManager sharedInstance] unregisterEncoding:I_encoding];
    I_encoding = anEncoding;
    [[EncodingManager sharedInstance] registerEncoding:anEncoding];
}

#pragma mark -
#pragma mark ### Line Numbers ###

- (int)lineNumberForLocation:(unsigned)aLocation {

    // validate I_lineStarts array
    int i;
    for (i=[I_lineStarts count]-1;i>=0;i--) {
        if ([[I_lineStarts objectAtIndex:i] unsignedIntValue]<=I_lineStartsValidUpTo) {
            break;
        } else {
            [I_lineStarts removeObjectAtIndex:i];    
        }
    }
    NSAssert(i>=0,@"Failure in lineNumberForLocation");
    int result=0;
    if (!(aLocation<=I_lineStartsValidUpTo)) {
        NSString *string=[self string];
        i=[I_lineStarts count]-1;
        unsigned lineStart=[[I_lineStarts objectAtIndex:i] intValue];
        NSRange lineRange=[string lineRangeForRange:NSMakeRange(lineStart,0)];
        I_lineStartsValidUpTo=NSMaxRange(lineRange)-1;
        while (NSMaxRange(lineRange)<[string length] && I_lineStartsValidUpTo<aLocation) {
            lineRange=[string lineRangeForRange:NSMakeRange(NSMaxRange(lineRange),0)];
            [I_lineStarts addObject:[NSNumber numberWithUnsignedInt:lineRange.location]];
            I_lineStartsValidUpTo=NSMaxRange(lineRange)-1;
        }
    }
    for (i=[I_lineStarts count]-1;i>=0;i--) {
        if ([[I_lineStarts objectAtIndex:i] unsignedIntValue]<=aLocation) {
            result=i+1;
            break;
        }
    }
    return result;
}

- (NSMutableArray *)lineStarts {
    return I_lineStarts;
}

- (void)setLineStartsOnlyValidUpTo:(unsigned int)aLocation {
    if (aLocation<I_lineStartsValidUpTo) {
        I_lineStartsValidUpTo=aLocation;
    }
}

- (void)fixParagraphStyleAttributeInRange:(NSRange)aRange {
//    [super fixParagraphStyleAttributeInRange:aRange];
//
//    NSDictionary *blockeditAttributes=[[PreferenceController sharedInstance] blockeditAttributes];
//
//    NSString *string=[self string];
//    NSRange lineRange=[string lineRangeForRange:aRange];
//    NSRange blockeditRange;
//    id value;
//    unsigned position=lineRange.location;
//    while (position<NSMaxRange(lineRange)) {
//        value=[self attribute:kBlockeditAttributeName atIndex:position
//                            longestEffectiveRange:&blockeditRange inRange:lineRange];
//        if (value) {
//            NSRange blockLineRange=[string lineRangeForRange:blockeditRange];
//            if (!NSEqualRanges(blockLineRange,blockeditRange)) {
//                blockeditRange=blockLineRange;
//                [self addAttributes:blockeditAttributes range:blockeditRange];
//            }
//        }
//        position=NSMaxRange(blockeditRange);
//    }
}


#pragma mark -
#pragma mark ### Abstract Primitives of NSTextStorage ###

- (NSString *)string {
    return [I_contents string];
}

- (NSDictionary *)attributesAtIndex:(unsigned)aIndex 
                     effectiveRange:(NSRangePointer)aRange {
    return [I_contents attributesAtIndex:aIndex effectiveRange:aRange];
}

- (void)replaceCharactersInRange:(NSRange)aRange withString:(NSString *)aString {
    unsigned origLen = [I_contents length];
    [I_contents replaceCharactersInRange:aRange withString:aString];
    id delegate = [self delegate];
    [self edited:NSTextStorageEditedCharacters range:aRange 
          changeInLength:[I_contents length] - origLen];
    if ([delegate respondsToSelector:@selector(textStorage:didReplaceCharactersInRange:withString:)]) {
        [delegate textStorage:self didReplaceCharactersInRange:aRange withString:aString];
    }
}

- (void)setAttributes:(NSDictionary *)attributes range:(NSRange)aRange {
    [I_contents setAttributes:attributes range:aRange];
    [self edited:NSTextStorageEditedAttributes range:aRange 
          changeInLength:0];
}


@end
