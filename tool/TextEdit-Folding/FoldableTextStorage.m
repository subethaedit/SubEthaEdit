//
//  FoldableTextStorage.m
//  TextEdit
//
//  Created by Dominik Wagner on 04.01.09.
//  Copyright 2009 TheCodingMonkeys. All rights reserved.
//


#import "FullTextStorage.h"
#import "FoldableTextStorage.h"

@implementation FoldedTextAttachment
- (id)initWithFoldedTextRange:(NSRange)inFoldedTextRange
{
	if ((self = [super initWithFileWrapper:[[[NSFileWrapper alloc] initWithPath:[[NSBundle mainBundle] pathForResource:@"folded" ofType:@"tiff"]] autorelease]]))
	{
		I_foldedTextRange = inFoldedTextRange;
	}
	return self;
}

- (NSRange)foldedTextRange {
	return I_foldedTextRange;
}

- (void)setFoldedTextRange:(NSRange)inRange {
	I_foldedTextRange = inRange;
}


- (void)dealloc
{
	[super dealloc];
}

@end




@implementation FoldableTextStorage

- (id)init {
    if ((self = [super init])) {
        I_internalAttributedString = [NSMutableAttributedString new];
        I_fullTextStorage = [[FullTextStorage alloc] initWithFoldableTextStorage:self];
		I_sortedFoldedTextAttachments = [NSMutableArray new];
    }
    return self;
}

- (void)dealloc {
	[I_sortedFoldedTextAttachments release];
    [I_internalAttributedString release];
    [I_fullTextStorage release];
    [super dealloc];
}


- (FullTextStorage *)fullTextStorage {
	return I_fullTextStorage;
}

- (void)adjustFoldedTextAttachmentsToReplacementOfFullRange:(NSRange)inFullRange withString:(NSString *)aString
{
	NSUInteger count = [I_sortedFoldedTextAttachments count];
	NSInteger locationDifference = ((NSInteger)[aString length]) - inFullRange.length;
	while (count > 0) {
		FoldedTextAttachment *attachment = [I_sortedFoldedTextAttachments objectAtIndex:--count];
		NSRange attachmentRange = [attachment foldedTextRange];
		if (attachmentRange.location >= NSMaxRange(inFullRange)) {
			attachmentRange.location += locationDifference;
			[attachment setFoldedTextRange:attachmentRange];
		} else if (attachmentRange.location >= inFullRange.location && NSMaxRange(attachmentRange) <= NSMaxRange(inFullRange)) { // attachment was inside the replacement, so it has to die
			[I_sortedFoldedTextAttachments removeObjectAtIndex:count];
		} else { // nothing left to do so break out
			break;
		}
	}
}


- (NSRange)fullRangeForFoldableRange:(NSRange)inRange
{
	NSRange resultRange = inRange;
	NSUInteger index = 0;
	NSUInteger count = [I_sortedFoldedTextAttachments count];
	FoldedTextAttachment *attachment = nil;
	while (index < count) {
		attachment = [I_sortedFoldedTextAttachments objectAtIndex:index++];
		NSRange attachmentRange = [attachment foldedTextRange];
		if (resultRange.location > attachmentRange.location) {
			resultRange.location += attachmentRange.length-1;
		} else {
			break;
		}
	}
	
	while (index <= count && attachment) {
		NSRange attachmentRange = [attachment foldedTextRange];
		NSLog(@"%s    - comparing attachmentRange: %@ to  resultRange: %@",__FUNCTION__,NSStringFromRange(attachmentRange),NSStringFromRange(resultRange));
		// test if the attachment range lies inside our range
		if (NSLocationInRange(attachmentRange.location,resultRange)) {
			resultRange.length += attachmentRange.length - 1;
			
			if (index < count) {
				attachment = [I_sortedFoldedTextAttachments objectAtIndex:index++];
			} else {
				break;
			}
		} else {
			break;
		}
	}
	
	NSLog(@"%s converted: %@ to full range: %@",__FUNCTION__,NSStringFromRange(inRange),NSStringFromRange(resultRange));
	
	return resultRange;
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
    unsigned origLen = [I_internalAttributedString length];
    [I_internalAttributedString replaceCharactersInRange:aRange withString:aString];
    
    if (inSynchronizeFlag) {
    	NSRange fullRange = [self fullRangeForFoldableRange:aRange];
    	[self adjustFoldedTextAttachmentsToReplacementOfFullRange:fullRange withString:aString];
    	[I_fullTextStorage replaceCharactersInRange:fullRange withString:aString synchronize:NO];
    }
    
    [self edited:NSTextStorageEditedCharacters range:aRange 
          changeInLength:[I_internalAttributedString length] - origLen];
}

- (void)replaceCharactersInRange:(NSRange)aRange withString:(NSString *)aString {
	[self replaceCharactersInRange:aRange withString:aString synchronize:YES];
}


- (void)setAttributes:(NSDictionary *)attributes range:(NSRange)aRange synchronize:(BOOL)inSynchronizeFlag {
    [I_internalAttributedString setAttributes:attributes range:aRange];

    if (inSynchronizeFlag) {
    	[I_fullTextStorage setAttributes:attributes range:[self fullRangeForFoldableRange:aRange] synchronize:NO];
    }

    [self edited:NSTextStorageEditedAttributes range:aRange 
          changeInLength:0];
}

- (void)setAttributes:(NSDictionary *)attributes range:(NSRange)aRange {
	[self setAttributes:attributes range:aRange synchronize:YES];
}

// convenience method
- (void)replaceCharactersInRange:(NSRange)inRange withAttributedString:(NSAttributedString *)inAttributedString synchronize:(BOOL)inSynchronizeFlag 
{
	if (inSynchronizeFlag) { // fall back to the one of NSTextStorage, which in turn should call the primitives and synchronize
		[self replaceCharactersInRange:inRange withAttributedString:inAttributedString];
	} else { // do it ourselves with the primitives
	    unsigned origLen = [I_internalAttributedString length];
		[I_internalAttributedString replaceCharactersInRange:inRange withAttributedString:inAttributedString];
		[self edited:NSTextStorageEditedCharacters | NSTextStorageEditedAttributes range:inRange 
			  changeInLength:[I_internalAttributedString length] - origLen];
	}
}

#pragma mark folding

- (void)addFoldedTextAttachment:(FoldedTextAttachment *)inAttachment
{
	int index = 0;
	NSUInteger count = [I_sortedFoldedTextAttachments count];
	NSRange targetRange = [inAttachment foldedTextRange];
	for (index=0;index < count;index++) {
		if ([[I_sortedFoldedTextAttachments objectAtIndex:index] foldedTextRange].location > targetRange.location)
			break;
	}
	[I_sortedFoldedTextAttachments insertObject:inAttachment atIndex:index];
}

- (void)foldRange:(NSRange)inRange
{
	FoldedTextAttachment *attachment = [[[FoldedTextAttachment alloc] initWithFoldedTextRange:[self fullRangeForFoldableRange:inRange]] autorelease];
	NSAttributedString *collapsedString = [NSAttributedString attributedStringWithAttachment:attachment];
	NSLog(@"%s %@",__FUNCTION__,collapsedString);
	[self replaceCharactersInRange:inRange withAttributedString:collapsedString synchronize:NO];
	[self addFoldedTextAttachment:attachment];
}

- (void)unfoldAttachment:(FoldedTextAttachment *)inAttachment atCharacterIndex:(NSUInteger)inIndex
{
	NSAttributedString *string = [I_fullTextStorage attributedSubstringFromRange:[inAttachment foldedTextRange]];
	[self replaceCharactersInRange:NSMakeRange(inIndex,1) withAttributedString:string synchronize:NO];
	[I_sortedFoldedTextAttachments removeObject:inAttachment];
}



@end
