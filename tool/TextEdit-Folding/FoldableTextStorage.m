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
        I_internalAttributedString = nil;//[NSMutableAttributedString new];
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
//		NSLog(@"%s    - comparing attachmentRange: %@ to  resultRange: %@",__FUNCTION__,NSStringFromRange(attachmentRange),NSStringFromRange(resultRange));
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
	
//	NSLog(@"%s converted: %@ to full range: %@",__FUNCTION__,NSStringFromRange(inRange),NSStringFromRange(resultRange));
	
	return resultRange;
}


- (NSMutableAttributedString *)internalMutableAttributedString {
	return I_internalAttributedString;
}


#pragma mark -
#pragma mark ### Abstract Primitives of NSTextStorage ###

- (NSString *)string {
	NSAttributedString *attributedString = I_internalAttributedString ? I_internalAttributedString : I_fullTextStorage;
    return [attributedString string];
}

- (NSDictionary *)attributesAtIndex:(unsigned)aIndex 
                     effectiveRange:(NSRangePointer)aRange {
	if ([self length]==0) return nil;
	NSAttributedString *attributedString = I_internalAttributedString ? I_internalAttributedString : I_fullTextStorage;
    return [attributedString attributesAtIndex:aIndex effectiveRange:aRange];
}

- (void)replaceCharactersInRange:(NSRange)aRange withString:(NSString *)aString synchronize:(BOOL)inSynchronizeFlag {

	if (I_internalAttributedString) {
		unsigned origLen = [I_internalAttributedString length];
		[I_internalAttributedString replaceCharactersInRange:aRange withString:aString];
		
		if (inSynchronizeFlag) {
			NSRange fullRange = [self fullRangeForFoldableRange:aRange];
			[self adjustFoldedTextAttachmentsToReplacementOfFullRange:fullRange withString:aString];
			[I_fullTextStorage replaceCharactersInRange:fullRange withString:aString synchronize:NO];
		}
		[self edited:NSTextStorageEditedCharacters range:aRange 
			  changeInLength:[I_internalAttributedString length] - origLen];
	} else {
		unsigned origLen = [I_fullTextStorage length];
		[I_fullTextStorage replaceCharactersInRange:aRange withString:aString synchronize:NO];
		[self edited:NSTextStorageEditedCharacters range:aRange 
			  changeInLength:[I_fullTextStorage length] - origLen];
	}    
}

- (void)replaceCharactersInRange:(NSRange)aRange withString:(NSString *)aString {
	[self replaceCharactersInRange:aRange withString:aString synchronize:YES];
}

- (void)setAttributes:(NSDictionary *)attributes range:(NSRange)aRange synchronize:(BOOL)inSynchronizeFlag {
	if (I_internalAttributedString) {
		[I_internalAttributedString setAttributes:attributes range:aRange];
	
		if (inSynchronizeFlag && !I_fixingCounter) {
			[I_fullTextStorage setAttributes:attributes range:[self fullRangeForFoldableRange:aRange] synchronize:NO];
		}
	} else {
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
	NSLog(@"%s",__FUNCTION__);
	[self beginEditing];
	if (I_internalAttributedString) {
		unsigned origLen = [I_internalAttributedString length];

		if (inSynchronizeFlag) {
			[I_fullTextStorage replaceCharactersInRange:[self fullRangeForFoldableRange:inRange] withAttributedString:inAttributedString synchronize:NO];
		}

		[I_internalAttributedString replaceCharactersInRange:inRange withAttributedString:inAttributedString];
		[self edited:NSTextStorageEditedCharacters | NSTextStorageEditedAttributes range:inRange 
			  changeInLength:[I_internalAttributedString length] - origLen];
	} else { // no foldings - no double data
		unsigned origLen = [I_fullTextStorage length];
		[I_fullTextStorage replaceCharactersInRange:inRange withAttributedString:inAttributedString synchronize:NO];
		[self edited:NSTextStorageEditedCharacters | NSTextStorageEditedAttributes range:inRange 
			  changeInLength:[I_fullTextStorage length] - origLen];
	}
	[self endEditing];
}


- (void)replaceCharactersInRange:(NSRange)inRange withAttributedString:(NSAttributedString *)inAttributedString 
{
	[self replaceCharactersInRange:inRange withAttributedString:inAttributedString synchronize:YES];
}

// performance optimization
- (void)beginEditing {
	//if (!I_internalAttributedString) 
	[I_fullTextStorage beginEditing];
	[super beginEditing];
}

- (void)endEditing {
	//if (!I_internalAttributedString) 
	[I_fullTextStorage endEditing];
	[super endEditing];
}

#pragma mark methods for upstream synchronization
- (void)fullTextDidReplaceCharactersinRange:(NSRange)inRange withString:(NSString *)inString {
	// lots of cases have to be considered here
	// - changed range does not intersect with any folding -> straight through
	// - changed range is inside a folding -> just adjust folding ranges
	// - changed range starts inside a folding and ends outside of it -> unfold all foldings that are concerned and apply the changes.
	// - changed range contains foldings -> remove the foldings
}

- (void)fullTextDidSetAttributes:(NSDictionary *)inAttributes range:(NSRange)inRange {

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
//	NSLog(@"%s %@",__FUNCTION__,collapsedString);
	if (!I_internalAttributedString) { // generate it on first fold
		I_internalAttributedString = [I_fullTextStorage mutableCopy];
		NSLog(@"%s ------------------------------> generated mutable string storage",__FUNCTION__);
	}
	[self replaceCharactersInRange:inRange withAttributedString:collapsedString synchronize:NO];
	[self addFoldedTextAttachment:attachment];
}

- (void)unfoldAttachment:(FoldedTextAttachment *)inAttachment atCharacterIndex:(NSUInteger)inIndex
{
	NSAttributedString *string = [I_fullTextStorage attributedSubstringFromRange:[inAttachment foldedTextRange]];
	NSLog(@"%s unfolding: %@",__FUNCTION__,[string description]);
	[self replaceCharactersInRange:NSMakeRange(inIndex,1) withAttributedString:string synchronize:NO];
	[I_sortedFoldedTextAttachments removeObject:inAttachment];
	if ([I_sortedFoldedTextAttachments count] == 0) {
		[I_internalAttributedString release];
		I_internalAttributedString = nil;
		NSLog(@"%s ------------------------------> killed mutable string storage",__FUNCTION__);
	}
}



@end
