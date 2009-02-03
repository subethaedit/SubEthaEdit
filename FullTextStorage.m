//
//  FullTextStorage.m
//  TextEdit
//
//  Created by Dominik Wagner on 04.01.09.
//  Copyright 2009 TheCodingMonkeys. All rights reserved.
//


#import "FoldableTextStorage.h"
#import "FullTextStorage.h"


@implementation FullTextStorage

- (id)initWithFoldableTextStorage:(FoldableTextStorage *)inTextStorage {
    if ((self = [super init])) {
        I_internalAttributedString = [NSMutableAttributedString new];
        I_foldableTextStorage = inTextStorage; // no retain here - the foldableTextstorage owns us
        I_shouldNotSynchronize = 0;
    }
    return self;
}



- (NSMutableAttributedString *)internalMutableAttributedString {
	return I_internalAttributedString;
}

#pragma mark -
#pragma mark ### Abstract Primitives of NSTextStorage ###

- (NSString *)string {
    return [I_internalAttributedString string];
}

- (NSDictionary *)attributesAtIndex:(unsigned)aIndex 
                     effectiveRange:(NSRangePointer)aRange {
	if ([self length]==0) return nil;
    return [I_internalAttributedString attributesAtIndex:aIndex effectiveRange:aRange];
}

- (void)replaceCharactersInRange:(NSRange)aRange withString:(NSString *)aString synchronize:(BOOL)inSynchronizeFlag {
//    unsigned origLen = [I_internalAttributedString length];
//	NSString *foldingBefore = [I_foldableTextStorage foldedStringRepresentation];
//	NSLog(@"%s before: %@",__FUNCTION__,foldingBefore);
//	NSLog(@"%s %@ %@ %@",__FUNCTION__, NSStringFromRange(aRange), aString, inSynchronizeFlag ? @"YES" : @"NO");
    [I_internalAttributedString replaceCharactersInRange:aRange withString:aString];
//    [self edited:NSTextStorageEditedCharacters range:aRange 
//          changeInLength:[I_internalAttributedString length] - origLen];
    if (inSynchronizeFlag && !I_shouldNotSynchronize) [I_foldableTextStorage fullTextDidReplaceCharactersInRange:aRange withString:aString];
}

- (void)replaceCharactersInRange:(NSRange)aRange withString:(NSString *)aString {
	[self replaceCharactersInRange:aRange withString:aString synchronize:YES];
}


- (void)setAttributes:(NSDictionary *)attributes range:(NSRange)aRange synchronize:(BOOL)inSynchronizeFlag {
    [I_internalAttributedString setAttributes:attributes range:aRange];
//    [self edited:NSTextStorageEditedAttributes range:aRange 
//          changeInLength:0];
    if (inSynchronizeFlag && !I_shouldNotSynchronize && !I_fixingCounter) {
    	[I_foldableTextStorage fullTextDidSetAttributes:attributes range:aRange];
    }
}

- (void)setAttributes:(NSDictionary *)attributes range:(NSRange)aRange {
	[self setAttributes:attributes range:aRange synchronize:YES];
}

// convenience method
- (void)replaceCharactersInRange:(NSRange)inRange withAttributedString:(NSAttributedString *)inAttributedString synchronize:(BOOL)inSynchronizeFlag 
{
	if (!inSynchronizeFlag) I_shouldNotSynchronize++;
	[self replaceCharactersInRange:inRange withAttributedString:inAttributedString];
	if (!inSynchronizeFlag) I_shouldNotSynchronize--;
}


//- (void)replaceCharactersInRange:(NSRange)inRange withAttributedString:(NSAttributedString *)inAttributedString 
//{
//	[self replaceCharactersInRange:inRange withAttributedString:inAttributedString synchronize:YES];
//}

@end
