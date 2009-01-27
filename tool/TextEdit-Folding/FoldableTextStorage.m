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

- (NSString *)foldedStringRepresentation {

	NSMutableString *result = [NSMutableString string];
	NSString *fullTextString = [I_fullTextStorage string];
	NSInteger currentIndex = 0;
	
	NSUInteger count = [I_sortedFoldedTextAttachments count];
	[result appendFormat:@"%d Foldings|",count];
	NSUInteger attachmentIndex = 0;
	while (attachmentIndex < count) {
		FoldedTextAttachment *attachment = [I_sortedFoldedTextAttachments objectAtIndex:attachmentIndex++];
		NSRange attachmentRange = [attachment foldedTextRange];
		if (currentIndex <= attachmentRange.location) {
			[result appendString:[fullTextString substringWithRange:NSMakeRange(currentIndex, attachmentRange.location - currentIndex)]];
		}
		[result appendFormat:@"\u02ea%@\u02e9", [fullTextString substringWithRange:attachmentRange]];
		currentIndex = NSMaxRange(attachmentRange);
	}
	if (currentIndex < [fullTextString length]) {
		[result appendString:[fullTextString substringFromIndex:currentIndex]];
	}
	return result;
}


// don't call this when there are no foldings
// TODO: this also has to work recursively for inner foldings once i implement them. it should be essentially the same cases without doubling the code - maybe i should implement this again from the viewpoint of a folding range thinking (foldingRange,replacementRange,replacementString) => (newFoldingRange) if that is possible - however then still the range of change in the folded textstorage needs to be determined
- (NSRange)foldedReplacementRangeForFullTextReplaceCharactersInRange:(NSRange)inRange withString:(NSString *)inString shouldInsertString:(BOOL *)outShouldInsertString {
	NSUInteger indexInFullText   = 0;
	NSUInteger indexAfterFolding = 0; // points to the first character after the current folding in the folded text
	NSUInteger attachmentIndex = 0;
	NSUInteger attachmentCount = [I_sortedFoldedTextAttachments count];
	NSUInteger previousAttachmentMaxRange = 0;
	*outShouldInsertString = YES; // initialize value
	FoldedTextAttachment *attachment = nil;
	FoldedTextAttachment *attachmentReplacementStartetIn = nil;
	NSRange attachmentRange = NSMakeRange(0,0);
	NSRange resultRange = NSMakeRange(0,0);
	
	// safeguard against misuse when there are no foldings
	if (attachmentCount == 0) {
		NSLog(@"%s ---------> should not be called without foldings! <----------",__FUNCTION__);
		return inRange;
	}
	
	NSInteger locationDifference = ((NSInteger)[inString length]) - inRange.length;

	// go to the start
	do {
		attachment = [I_sortedFoldedTextAttachments objectAtIndex:attachmentIndex];
		attachmentRange = [attachment foldedTextRange];
		indexInFullText = attachmentRange.location;
		indexAfterFolding += attachmentRange.location - previousAttachmentMaxRange + 1;
		previousAttachmentMaxRange = NSMaxRange(attachmentRange);
		attachmentIndex++;
	} while (inRange.location >= previousAttachmentMaxRange && attachmentIndex < attachmentCount);
	
	if (inRange.location >= previousAttachmentMaxRange) {
		// the replacement range is completely after all foldings
		NSLog(@"%s the replacement range is completely after all foldings",__FUNCTION__);
		resultRange = inRange;
		resultRange.location = indexAfterFolding + (inRange.location - NSMaxRange(attachmentRange));
		return resultRange;
	}

	// now we are either inside or before the attachment at --attachmentIndex or inside of it
	BOOL startInsideFolding = (inRange.location == attachmentRange.location && inRange.length > 0) || 
							   inRange.location  > attachmentRange.location;

	
	
	if (startInsideFolding) {
		// the folding should stay, maybe we need to remove characters after the folding.
		resultRange.location = indexAfterFolding;
		*outShouldInsertString = NO;
		attachmentReplacementStartetIn = attachment;
	} else {
		resultRange.location = indexAfterFolding - 1 - (indexInFullText - inRange.location);
	}
	
	BOOL endFound = NO;
	
	while (!endFound) {
		// check if the end is before the current foldingattachment, if so break
		if (NSMaxRange(inRange) <= attachmentRange.location) {
			// end is in front of the current folding
			resultRange.length = ( (indexAfterFolding - 1) - resultRange.location ) - (attachmentRange.location - NSMaxRange(inRange));
			if (startInsideFolding) {
				// as the end is not inside this folding, we need to adjust the folding so it now contains all characters of this textchange
				NSRange insideFoldingRange = [attachmentReplacementStartetIn foldedTextRange];
				insideFoldingRange.length = inRange.location - insideFoldingRange.location + [inString length];
				[attachmentReplacementStartetIn setFoldedTextRange:insideFoldingRange];
			}
			// decrement index so the current attachment gets adjusted as well in the final adjustment loop
			attachmentIndex--;
			endFound = YES;
			break;
		} else if (NSMaxRange(inRange) <= NSMaxRange(attachmentRange)) {
			// inRange ends inside of this current attachment
			if (startInsideFolding) {
				if (attachment == attachmentReplacementStartetIn) {
					if (NSEqualRanges(inRange,attachmentRange) && [inString length] == 0) {
						NSLog(@"%s go away attachment because you have been replaced completely (start and end attachment were equal)",__FUNCTION__);
						//attachment has to go
						resultRange.location -=1;
						resultRange.length = 1;
						endFound = YES;
						attachmentIndex--;
						[I_sortedFoldedTextAttachments removeObjectAtIndex:attachmentIndex];
						attachmentCount--;
						break;
					} else {
						// adjust attachmentRange
						NSLog(@"%s change attachmentrange (start and end attachment were equal)",__FUNCTION__);
						endFound = YES;
						attachmentRange.length += locationDifference;
						[attachment setFoldedTextRange:attachmentRange];
						*outShouldInsertString = NO; // don't insert text in that case
						break;
					}
				} else {
					// our change started in an attachment which is different from the current attachment
					// so the current attachment has to go and the original attachments length has to be adjusted
					NSLog(@"%s start and end attachment have been different, removing the current attachment and adjusting the first",__FUNCTION__);
					NSInteger leftOverLength = NSMaxRange(attachmentRange)-NSMaxRange(inRange);
					resultRange.length = indexAfterFolding - resultRange.location;
					NSRange originalAttachmentRange = [attachmentReplacementStartetIn foldedTextRange];
					originalAttachmentRange.length = leftOverLength + locationDifference + (NSMaxRange(inRange)-originalAttachmentRange.location);
					[attachmentReplacementStartetIn setFoldedTextRange:originalAttachmentRange];
					attachmentIndex--;
					[I_sortedFoldedTextAttachments removeObjectAtIndex:attachmentIndex];
					NSLog(@"%s removed attachment with range:%@",__FUNCTION__,NSStringFromRange([attachment foldedTextRange]));
					attachmentCount--;
					endFound = YES;
					break;
				}
			} else {
				// truncate the first part of the current folding that was chopped of
				NSLog(@"%s trimming the head of the current folding",__FUNCTION__);
				NSInteger truncatedCharacters = NSMaxRange(inRange)-attachmentRange.location;
				NSRange settingRange = NSMakeRange(attachmentRange.location + truncatedCharacters + locationDifference, attachmentRange.length - truncatedCharacters);
				if (settingRange.length == 0) {
					// remove this empty folding
					resultRange.length = indexAfterFolding - resultRange.location;
					attachmentIndex--;
					[I_sortedFoldedTextAttachments removeObjectAtIndex:attachmentIndex];
					NSLog(@"%s removed attachment with range:%@",__FUNCTION__,NSStringFromRange([attachment foldedTextRange]));
					attachmentCount--;
				} else {
					[attachment setFoldedTextRange:settingRange];
					resultRange.length = (indexAfterFolding -1) - resultRange.location;
				}
				endFound = YES;
				break;
			}
		} else if (attachment != attachmentReplacementStartetIn) {
			// current attachment is consumed by the replacement range - so kill the current attachment
			attachmentIndex--;
			[I_sortedFoldedTextAttachments removeObjectAtIndex:attachmentIndex];
			NSLog(@"%s removed attachment with range:%@",__FUNCTION__,NSStringFromRange([attachment foldedTextRange]));
			attachmentCount--;
		}
	
		if (attachmentIndex >= attachmentCount) {
			break;
		} else { // advance
			attachment = [I_sortedFoldedTextAttachments objectAtIndex:attachmentIndex];
			attachmentRange = [attachment foldedTextRange];
			indexInFullText = attachmentRange.location;
			indexAfterFolding += attachmentRange.location - previousAttachmentMaxRange + 1;
			previousAttachmentMaxRange = NSMaxRange(attachmentRange);
			attachmentIndex++;
		}
	}
	
	if (!endFound) {
		NSLog(@"%s end lies behind all attachments",__FUNCTION__);
		resultRange.length = (indexAfterFolding + NSMaxRange(inRange) - NSMaxRange(attachmentRange)) - resultRange.location;
		if (startInsideFolding) {
			// adjust folding to go up to the last inserted character
			NSRange settingRange = [attachmentReplacementStartetIn foldedTextRange];
			settingRange.length = ( (inRange.location + [inString length]) - settingRange.location );
			[attachmentReplacementStartetIn setFoldedTextRange:settingRange];
		}
	} else {
		// adjust the other attachment ranges according to the change being beforehand
		while (attachmentIndex < attachmentCount) {
			attachment = [I_sortedFoldedTextAttachments objectAtIndex:attachmentIndex++];
			attachmentRange = [attachment foldedTextRange];
			attachmentRange.location += locationDifference;
			[attachment setFoldedTextRange:attachmentRange];
		}
	}	
	return resultRange;
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

- (NSRange)fullRangeForFoldedRange:(NSRange)inRange
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
			NSRange fullRange = [self fullRangeForFoldedRange:aRange];
			[self adjustFoldedTextAttachmentsToReplacementOfFullRange:fullRange withString:aString];
			[I_fullTextStorage replaceCharactersInRange:fullRange withString:aString synchronize:NO];
		}
		[self edited:NSTextStorageEditedCharacters range:aRange 
			  changeInLength:[I_internalAttributedString length] - origLen];
	} else {
		unsigned origLen = [I_fullTextStorage length];
		[I_fullTextStorage replaceCharactersInRange:aRange withString:aString synchronize:YES];
//		[self edited:NSTextStorageEditedCharacters range:aRange 
//			  changeInLength:[I_fullTextStorage length] - origLen];
	}    
}

- (void)replaceCharactersInRange:(NSRange)aRange withString:(NSString *)aString {
	[self replaceCharactersInRange:aRange withString:aString synchronize:YES];
}

- (void)setAttributes:(NSDictionary *)attributes range:(NSRange)aRange synchronize:(BOOL)inSynchronizeFlag {
	if (I_internalAttributedString) {
		[I_internalAttributedString setAttributes:attributes range:aRange];
	
		if (inSynchronizeFlag && !I_fixingCounter) {
			[I_fullTextStorage setAttributes:attributes range:[self fullRangeForFoldedRange:aRange] synchronize:NO];
		}
	} else {
		[I_fullTextStorage setAttributes:attributes range:[self fullRangeForFoldedRange:aRange] synchronize:YES];
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
			[I_fullTextStorage replaceCharactersInRange:[self fullRangeForFoldedRange:inRange] withAttributedString:inAttributedString synchronize:NO];
		}

		[I_internalAttributedString replaceCharactersInRange:inRange withAttributedString:inAttributedString];
		[self edited:NSTextStorageEditedCharacters | NSTextStorageEditedAttributes range:inRange 
			  changeInLength:[I_internalAttributedString length] - origLen];
	} else { // no foldings - no double data
		unsigned origLen = [I_fullTextStorage length];
		[I_fullTextStorage replaceCharactersInRange:inRange withAttributedString:inAttributedString synchronize:YES];
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
//	[I_fullTextStorage beginEditing];
	[super beginEditing];
}

- (void)endEditing {
	//if (!I_internalAttributedString) 
//	[I_fullTextStorage endEditing];
	[super endEditing];
}

#pragma mark methods for upstream synchronization
- (void)fullTextDidReplaceCharactersInRange:(NSRange)inRange withString:(NSString *)inString {
//	NSLog(@"%s %@ %@ lengthChange %d",__FUNCTION__, NSStringFromRange(inRange), inString, [inString length] - inRange.length);
	if (!I_internalAttributedString) {
		[self edited:NSTextStorageEditedCharacters range:inRange changeInLength:[inString length] - inRange.length];
	} else {
		// lots of cases have to be considered here
		// - changed range does not intersect with any folding -> straight through
		// - changed range is inside a folding -> just adjust folding ranges
		// - changed range starts inside a folding and ends outside of it -> unfold all foldings that are concerned and apply the changes.
		// - changed range contains foldings -> remove the foldings
		
		BOOL shouldInsertString = YES; 
		// this call also adjusts the foldings as necessary
		NSRange foldedReplacementRange = [self foldedReplacementRangeForFullTextReplaceCharactersInRange:inRange withString:inString shouldInsertString:&shouldInsertString];
		NSLog(@"%s replacing folded range %@ with %@", __FUNCTION__, NSStringFromRange(foldedReplacementRange), shouldInsertString ? @"inString" : @"NOTHING");
		if (foldedReplacementRange.length > 0 || shouldInsertString) {
			[self replaceCharactersInRange:foldedReplacementRange withString: (shouldInsertString ? inString : @"") synchronize:NO];
		}
		NSLog(@"%s after: %@",__FUNCTION__,[self foldedStringRepresentation]);
	}
}

- (void)fullTextDidSetAttributes:(NSDictionary *)inAttributes range:(NSRange)inRange {
	NSLog(@"%s %@",__FUNCTION__, NSStringFromRange(inRange));
	if (!I_internalAttributedString) {
		[self edited:NSTextStorageEditedAttributes range:inRange changeInLength:0];
	} else {
		// TODO: go through the range, set the attributes, and if folded areas are involved split the ranges up
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
	FoldedTextAttachment *attachment = [[[FoldedTextAttachment alloc] initWithFoldedTextRange:[self fullRangeForFoldedRange:inRange]] autorelease];
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
