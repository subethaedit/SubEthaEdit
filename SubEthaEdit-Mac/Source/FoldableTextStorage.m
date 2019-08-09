//  FoldableTextStorage.m
//  TextEdit
//
//  Created by Dominik Wagner on 04.01.09.

#import "PlainTextDocument.h"
#import "FullTextStorage.h"
#import "FoldableTextStorage.h"
#import "SyntaxHighlighter.h"
#import "EncodingManager.h"
#import "PlainTextDocument.h"
#import "TCMMMUserManager.h"
#import "SelectionOperation.h"
#import "TCMMMUserSEEAdditions.h"
#import "GeneralPreferences.h"
#import "DocumentMode.h"
#import "NSMutableAttributedStringSEEAdditions.h"
#import "ScriptTextSelection.h"
#import "ScriptLine.h"
#import "ScriptCharacters.h"

// this file needs arc - add -fobjc-arc in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

static NSArray *S_nonSyncAttributes = nil;

NSString * const BlockeditAttributeName =@"Blockedit";
NSString * const BlockeditAttributeValue=@"YES";

@interface FoldableTextStorage (FoldableTextStoragePrivateAdditions)
- (void)removeInternalStorageString;
@end

@implementation FoldableTextStorage

+ (void)initialize {
	if (self == [FoldableTextStorage class]) {
		S_nonSyncAttributes = [[NSArray alloc] initWithObjects:kSyntaxHighlightingIsCorrectAttributeName,BlockeditAttributeName,nil];
	}
}

- (id)init {
    if ((self = [super init])) {
        I_internalAttributedString = nil;
        I_fullTextStorage = [[FullTextStorage alloc] initWithFoldableTextStorage:self];
		I_sortedFoldedTextAttachments = [NSMutableArray new];

		I_blockedit.hasBlockeditRanges=NO;
		I_blockedit.isBlockediting    =NO;
		I_blockedit.didBlockedit      =NO;
		I_blockedit.didBlockeditRange = NSMakeRange(NSNotFound,0);
		I_blockedit.didBlockeditLineRange = NSMakeRange(NSNotFound,0);
    }
    return self;
}


- (FullTextStorage *)fullTextStorage {
	return I_fullTextStorage;
}


typedef union {
	char bytes[8];
    struct {
		uint32_t location;
		uint32_t length;
    } range;
} uint32RangeUnion;


// compact direct format for saving and network transport
// just a series of ranges represented by pairs of uint32s (location,length) in network byte order that represent the current folding state
// this equals to 8bytes for a folding - nesting is implicid 
// this is from bottom to top, depth first so it can be quickly applied when loaded
- (void)appendDataRepresentationOfFoldings:(NSArray *)aFoldingAttachmentArray toData:(NSMutableData *)aData depth:(int)aRemainingDepth {
	if (aRemainingDepth == 0) return; // don't recurse when no additional depth left
	int recursionDepth = aRemainingDepth - 1;
	unsigned count = [aFoldingAttachmentArray count];
	while (count != 0) {
		count--;
		FoldedTextAttachment *attachment = [aFoldingAttachmentArray objectAtIndex:count];
		
		// recurse if necessary
		NSArray *innerAttachments = [attachment innerAttachments];
		if ([innerAttachments count]) {
			[self appendDataRepresentationOfFoldings:innerAttachments toData:aData depth:recursionDepth];
		}
		
		// add the attachment to the data
		NSRange foldedRange = [attachment foldedTextRange];
		
		uint32RangeUnion rangeUnion;
		
		rangeUnion.range.location = foldedRange.location;
		rangeUnion.range.length   = foldedRange.length;
		rangeUnion.range.location = CFSwapInt32HostToBig(rangeUnion.range.location);
		rangeUnion.range.length   = CFSwapInt32HostToBig(rangeUnion.range.length);
		
		// store in data
		[aData appendBytes:rangeUnion.bytes length:8];
	}
}

// maxDepth of -1 means endless depth
// maxDepth of 1 will only encode top level;

- (NSData *)dataRepresentationOfFoldedRangesWithMaxDepth:(int)aMaxDepth {
	NSMutableData *resultData = [NSMutableData data];
	[self appendDataRepresentationOfFoldings:I_sortedFoldedTextAttachments toData:resultData depth:aMaxDepth];
	
	return resultData;
}

- (void)foldAccordingToDataRepresentation:(NSData *)aData {
	[self beginEditing];
	uint32RangeUnion *rangeUnion;
	NSInteger length = [aData length];
	rangeUnion = (uint32RangeUnion *)[aData bytes];
	for (;length >= 8;length -= 8, rangeUnion++) {
		rangeUnion->range.location = CFSwapInt32BigToHost(rangeUnion->range.location);
		rangeUnion->range.length   = CFSwapInt32BigToHost(rangeUnion->range.length);
		NSRange foldingRange = NSMakeRange(rangeUnion->range.location,rangeUnion->range.length);
		[self foldRange:[self foldedRangeForFullRange:foldingRange]];
	}
	[self endEditing];
}


- (NSString *)foldedStringRepresentationOfRange:(NSRange)inRange foldings:(NSArray *)inFoldings level:(int)inLevel
{
	if (inLevel > 10) return @"RECURSION";
	inLevel++;
	NSMutableString *result = [NSMutableString string];
	NSString *fullTextString = [I_fullTextStorage string];
	int currentIndex = inRange.location;
	unsigned count = [inFoldings count];
	unsigned attachmentIndex = 0;
	FoldedTextAttachment *attachment = nil;
	while (attachmentIndex < count) {
		attachment = [inFoldings objectAtIndex:attachmentIndex++];
		NSRange attachmentRange = [attachment foldedTextRange];
		if (currentIndex < attachmentRange.location) {
			[result appendString:[fullTextString substringWithRange:NSMakeRange(currentIndex, attachmentRange.location - currentIndex)]];
		}
		[result appendFormat:@"\u02eaL%d|%@\u02e9", inLevel,[self foldedStringRepresentationOfRange:attachmentRange foldings:[attachment innerAttachments] level:inLevel]];
		currentIndex = NSMaxRange(attachmentRange);
	}
	if (currentIndex < NSMaxRange(inRange)) {
		[result appendString:[fullTextString substringWithRange:NSMakeRange(currentIndex,NSMaxRange(inRange) - currentIndex)]];
	}
	return result;
	
}

- (int)numberOfTopLevelFoldings {
	return [I_sortedFoldedTextAttachments count];
}

- (NSString *)foldedStringRepresentation {

	return [[self foldedStringRepresentationOfRange:NSMakeRange(0,[I_fullTextStorage length]) foldings:I_sortedFoldedTextAttachments level:0] stringByAppendingFormat:@"\n->%lu Foldings",(unsigned long)[I_sortedFoldedTextAttachments count]];
}


// don't call this when there are no foldings
// TODO: this also has to work recursively for inner foldings once i implement them. it should be essentially the same cases without doubling the code - maybe i should implement this again from the viewpoint of a folding range thinking (foldingRange,replacementRange,replacementString) => (newFoldingRange) if that is possible - however then still the range of change in the folded textstorage needs to be determined
// this should totally move into the attachment object so the recursion isn't so awkward
- (NSRange)foldedReplacementRangeForFullTextReplaceCharactersInRange:(NSRange)inRange withString:(NSString *)inString shouldInsertString:(BOOL *)outShouldInsertString foldingAttachments:(NSMutableArray *)inFoldingAttachments {
	unsigned indexInFullText   = 0;
	unsigned indexAfterFolding = 0; // points to the first character after the current folding in the folded text
	unsigned attachmentIndex = 0;
	unsigned attachmentCount = [inFoldingAttachments count];
	unsigned previousAttachmentMaxRange = 0;
	*outShouldInsertString = YES; // initialize value
	FoldedTextAttachment *attachment = nil;
	FoldedTextAttachment *attachmentReplacementStartetIn = nil;
	NSRange attachmentRange; // = {NSNotFound, 0};
	NSRange resultRange = {NSNotFound, 0};
	
	// safeguard against misuse when there are no foldings
	if (attachmentCount == 0) {
		NSLog(@"%s ---------> should not be called without foldings! <----------",__FUNCTION__);
		return inRange;
	}
	
	int locationDifference = ((int)[inString length]) - inRange.length;

	// go to the start
	do {
		attachment = [inFoldingAttachments objectAtIndex:attachmentIndex];
		attachmentRange = [attachment foldedTextRange];
		indexInFullText = attachmentRange.location;
		indexAfterFolding += attachmentRange.location - previousAttachmentMaxRange + 1;
		previousAttachmentMaxRange = NSMaxRange(attachmentRange);
		attachmentIndex++;
	} while (inRange.location >= previousAttachmentMaxRange && attachmentIndex < attachmentCount);
	
	if (inRange.location >= previousAttachmentMaxRange) {
		// the replacement range is completely after all foldings
//		NSLog(@"%s the replacement range is completely after all foldings",__FUNCTION__);
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
//						NSLog(@"%s go away attachment because you have been replaced completely (start and end attachment were equal)",__FUNCTION__);
						//attachment has to go
						resultRange.location -=1;
						resultRange.length = 1;
						endFound = YES;
						attachmentIndex--;
						[inFoldingAttachments removeObjectAtIndex:attachmentIndex];
						attachmentCount--;
						break;
					} else {
						// adjust attachmentRange
//						NSLog(@"%s change attachmentrange (start and end attachment were equal)",__FUNCTION__);
						endFound = YES;
						attachmentRange.length += locationDifference;
						[attachment setFoldedTextRange:attachmentRange];
						*outShouldInsertString = NO; // don't insert text in that case
						break;
					}
				} else {
					// our change started in an attachment which is different from the current attachment
					// so the current attachment has to go and the original attachments length has to be adjusted
//					NSLog(@"%s start and end attachment have been different, removing the current attachment and adjusting the first",__FUNCTION__);
					int leftOverLength = NSMaxRange(attachmentRange)-NSMaxRange(inRange);
					resultRange.length = indexAfterFolding - resultRange.location;
					NSRange originalAttachmentRange = [attachmentReplacementStartetIn foldedTextRange];
					originalAttachmentRange.length = leftOverLength + locationDifference + (NSMaxRange(inRange)-originalAttachmentRange.location);
					[attachmentReplacementStartetIn setFoldedTextRange:originalAttachmentRange];
					attachmentIndex--;
//					NSLog(@"%s removed attachment with range:%@",__FUNCTION__,NSStringFromRange([attachment foldedTextRange]));
					[inFoldingAttachments removeObjectAtIndex:attachmentIndex];
					attachmentCount--;
					endFound = YES;
					break;
				}
			} else {
				// truncate the first part of the current folding that was chopped of
//				NSLog(@"%s trimming the head of the current folding",__FUNCTION__);
				int truncatedCharacters = NSMaxRange(inRange)-attachmentRange.location;
				NSRange settingRange = NSMakeRange(attachmentRange.location + truncatedCharacters + locationDifference, attachmentRange.length - truncatedCharacters);
				if (settingRange.length == 0) {
					// remove this empty folding
					resultRange.length = indexAfterFolding - resultRange.location;
					attachmentIndex--;
//					NSLog(@"%s removed attachment with range:%@",__FUNCTION__,NSStringFromRange([attachment foldedTextRange]));
					[inFoldingAttachments removeObjectAtIndex:attachmentIndex];
					attachmentCount--;
				} else {
					[attachment setFoldedTextRange:settingRange];
					resultRange.length = (indexAfterFolding -1) - resultRange.location;
					// do recursive treatment for this fellow
					BOOL ignore;
					NSMutableArray * innerAttachments = [attachment innerAttachments];
//					NSLog(@"%s doing a recursion for a trimmed attachment (%d inner Attachments)",__FUNCTION__,[innerAttachments count]);

					if ([innerAttachments count] > 0) {
						[self foldedReplacementRangeForFullTextReplaceCharactersInRange:inRange withString:inString shouldInsertString:&ignore foldingAttachments:innerAttachments];
					}

				}
				endFound = YES;
				break;
			}
		} else if (attachment != attachmentReplacementStartetIn) {
			// current attachment is consumed by the replacement range - so kill the current attachment
			attachmentIndex--;
//			NSLog(@"%s removed attachment with range:%@",__FUNCTION__,NSStringFromRange([attachment foldedTextRange]));
			[inFoldingAttachments removeObjectAtIndex:attachmentIndex];
			attachmentCount--;
		}
	
		if (attachmentIndex >= attachmentCount) {
			break;
		} else { // advance
			attachment = [inFoldingAttachments objectAtIndex:attachmentIndex];
			attachmentRange = [attachment foldedTextRange];
//			indexInFullText = attachmentRange.location;
			indexAfterFolding += attachmentRange.location - previousAttachmentMaxRange + 1;
			previousAttachmentMaxRange = NSMaxRange(attachmentRange);
			attachmentIndex++;
		}
	}
	
	if (!endFound) {
//		NSLog(@"%s end lies behind all attachments",__FUNCTION__);
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
			attachment = [inFoldingAttachments objectAtIndex:attachmentIndex++];
			[attachment moveAttachmentLocation:locationDifference];
		}
	}
	
	// adjust the inner attachments of the potentially changed attachments
	if (attachmentReplacementStartetIn) {
		BOOL ignore;
		NSMutableArray * innerAttachments = [attachmentReplacementStartetIn innerAttachments];
//		NSLog(@"%s doing a recursion for an attachment we started in (%d inner Attachments)",__FUNCTION__,[innerAttachments count]);
		if ([innerAttachments count] > 0) {
			[self foldedReplacementRangeForFullTextReplaceCharactersInRange:inRange withString:inString shouldInsertString:&ignore foldingAttachments:innerAttachments];
		}
	}	
	return resultRange;
}

// this is the quick one for changes that happen inside the foldable textstorage which makes sure that the range does not intersect with foldings
- (void)adjustFoldedTextAttachments:(NSMutableArray *)inAttachments toReplacementOfFullRange:(NSRange)inFullRange withString:(NSString *)aString
{
	int removedAttachments = 0;
	unsigned count = [inAttachments count];
	int locationDifference = ((int)[aString length]) - inFullRange.length;
	while (count > 0) {
		FoldedTextAttachment *attachment = [inAttachments objectAtIndex:--count];
		NSRange attachmentRange = [attachment foldedTextRange];
		if (attachmentRange.location >= NSMaxRange(inFullRange)) {
			[attachment moveAttachmentLocation:locationDifference];
		} else if (attachmentRange.location >= inFullRange.location && NSMaxRange(attachmentRange) <= NSMaxRange(inFullRange)) { // attachment was inside the replacement, so it has to die
			[inAttachments removeObjectAtIndex:count];
			removedAttachments++;
		} else { // nothing left to do so break out
			break;
		}
	}
	
	if (removedAttachments > 0) {
		id delegate = [self delegate];
		if ([delegate respondsToSelector:@selector(textStorageDidChangeNumberOfTopLevelFoldings:)]) {
			[delegate textStorageDidChangeNumberOfTopLevelFoldings:self];
		}
	}
}

- (NSRange)indexRangeOfFoldingAttachments:(NSArray *)inAttachmentArray fullyContainedInRange:(NSRange)inRange
{
	NSRange result = NSMakeRange(0,0);
	unsigned index = 0;
	unsigned count = [inAttachmentArray count];
	while (index < count) {
		FoldedTextAttachment *attachment = [inAttachmentArray objectAtIndex:index++];
		NSRange attachmentRange = [attachment foldedTextRange];
		if (inRange.location <= attachmentRange.location && NSMaxRange(inRange) >= NSMaxRange(attachmentRange)) {
			// this one is inside
			if (result.length == 0) {
				result.location = index-1;
			}
			result.length++;
		}
		if (NSMaxRange(attachmentRange) > NSMaxRange(inRange)) break;
	}
	return result;
}

- (NSRange)fullRangeForFoldedRange:(NSRange)inRange
{
	NSRange resultRange = inRange;
	unsigned index = 0;
	unsigned count = [I_sortedFoldedTextAttachments count];
	if (count == 0) return inRange; // quick path - no attachments no range difference

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

- (NSRange)foldedRangeForFullRange:(NSRange)inRange {
	return [self foldedRangeForFullRange:inRange expandIfFolded:NO];
}

// TODO: think about what exactly shold be returned in the edge cases
- (NSRange)foldedRangeForFullRange:(NSRange)inRange expandIfFolded:(BOOL)aFlag {
	unsigned index = 0;
	unsigned count = [I_sortedFoldedTextAttachments count];
	if (count == 0) return inRange; // quick path - no attachments no range difference

	
	NSRange resultRange = inRange;
	FoldedTextAttachment *attachment = nil;
	while (index < count) {
		attachment = [I_sortedFoldedTextAttachments objectAtIndex:index++];
		NSRange attachmentRange = [attachment foldedTextRange];
		if (attachmentRange.location > NSMaxRange(inRange)) {
			break; //finished here
		} else if (NSMaxRange(attachmentRange) <= inRange.location) {
			// attachment is before our interesting range - so move location accordingly
			resultRange.location -= attachmentRange.length - 1;
		} else if (attachmentRange.location <= inRange.location) {
			if ( NSMaxRange(attachmentRange) >= NSMaxRange(inRange) ) {
				// range was completely contained by an attachment
				if (aFlag) {
					goto expand;
				} else {
					resultRange.length = 1;
					resultRange.location -= (inRange.location - attachmentRange.location);
				}
			} else { 
				// attachmentRange ends before ending of the attachment
				if (aFlag) {
					goto expand;
				} else {
					// move location to the start of the folding
					// change length to remove the part inside the folding
					resultRange.location -= (inRange.location - attachmentRange.location);
					resultRange.length    = NSMaxRange(inRange)-NSMaxRange(attachmentRange) +1;
				}
			}
		} else if (attachmentRange.location <= NSMaxRange(inRange)) {
			if (aFlag) {
				goto expand;
			} else {
				// move the range in front of this attachment
				if (NSMaxRange(attachmentRange) <= NSMaxRange(inRange)) {
					// completely contained
					resultRange.length -= attachmentRange.length -1;
					// location stays because nothing is inbefore
				} else {
					// attachment is longer
					resultRange.length -= NSMaxRange(inRange) - attachmentRange.location - 1;
					break;
				}
			}
		}
		continue;
		expand:
			// expand this attachment
			[self unfoldAttachment:attachment atCharacterIndex:attachmentRange.location - (inRange.location - resultRange.location)];
			// then continue
			count = [I_sortedFoldedTextAttachments count]; index--;
			continue;

	}
	
	return resultRange;
}



- (NSMutableAttributedString *)internalMutableAttributedString {
	return I_internalAttributedString;
}

#pragma mark -
#pragma mark serialisation

- (NSDictionary *)dictionaryRepresentation {
	NSMutableDictionary *mutableRepresentation = (NSMutableDictionary *)[I_fullTextStorage mutableDictionaryRepresentation];
	[mutableRepresentation setObject:[NSNumber numberWithUnsignedInt:[self encoding]] forKey:@"Encoding"];
	NSData *foldingData = [self dataRepresentationOfFoldedRangesWithMaxDepth:-1];
	if (foldingData) {
		[mutableRepresentation setObject:foldingData forKey:@"FoldingData"];
	}
    return mutableRepresentation;
}

- (void)setContentByDictionaryRepresentation:(NSDictionary *)aRepresentation {
	[self beginEditing];
    [I_fullTextStorage setContentByDictionaryRepresentation:aRepresentation];
	NSData *foldingData = [aRepresentation objectForKey:@"FoldingData"];
	if (foldingData) {
		[self foldAccordingToDataRepresentation:foldingData];
	}
	[self endEditing];
}


#pragma mark -
#pragma mark ### Abstract Primitives of NSTextStorage ###

- (NSString *)string {
	NSAttributedString *attributedString = I_internalAttributedString ? I_internalAttributedString : I_fullTextStorage;
    return [attributedString string];
}

- (NSDictionary *)attributesAtIndex:(NSUInteger)aIndex 
                     effectiveRange:(NSRangePointer)aRange {
    if (self.length==0) { return @{}; }
	NSAttributedString *attributedString = I_internalAttributedString ? I_internalAttributedString : I_fullTextStorage;
    return [attributedString attributesAtIndex:aIndex effectiveRange:aRange];
}

- (void)replaceCharactersInRange:(NSRange)aRange withString:(NSString *)aString synchronize:(BOOL)inSynchronizeFlag {

	if (I_internalAttributedString) {
		unsigned origLen = [I_internalAttributedString length];
//		NSLog(@"%s replaced '%@' with '%@'",__FUNCTION__,[[I_internalAttributedString string] substringWithRange:aRange],aString);
		[I_internalAttributedString replaceCharactersInRange:aRange withString:aString];
		[self edited:NSTextStorageEditedCharacters | NSTextStorageEditedAttributes range:aRange 
			  changeInLength:[I_internalAttributedString length] - origLen];
		
		if (inSynchronizeFlag) {
			NSRange fullRange = [self fullRangeForFoldedRange:aRange];
			[self adjustFoldedTextAttachments:I_sortedFoldedTextAttachments toReplacementOfFullRange:fullRange withString:aString];
			[I_fullTextStorage replaceCharactersInRange:fullRange withString:aString synchronize:NO];
		}

	} else {
//		unsigned origLen = [I_fullTextStorage length];
		[I_fullTextStorage replaceCharactersInRange:aRange withString:aString synchronize:YES];
//		[self edited:NSTextStorageEditedCharacters range:aRange 
//			  changeInLength:[I_fullTextStorage length] - origLen];
	}    

	if (I_internalAttributedString && [I_sortedFoldedTextAttachments count] == 0) {
		[self removeInternalStorageString];
	}
}

- (void)replaceCharactersInRange:(NSRange)aRange withString:(NSString *)aString {
	[self replaceCharactersInRange:aRange withString:aString synchronize:YES];
}

- (void)setAttributes:(NSDictionary *)attributes range:(NSRange)aRange synchronize:(BOOL)inSynchronizeFlag {
	if (I_internalAttributedString) {
		[I_internalAttributedString setAttributes:attributes range:aRange];
		if (inSynchronizeFlag && !I_fixingCounter) {
			// if the attributes contain an attachment - don't sync
			if (![attributes objectForKey:NSAttachmentAttributeName]) {
				// sync most of the attributes, but not all
				NSMutableDictionary *filteredAttributes = [attributes mutableCopy];
				[filteredAttributes removeObjectsForKeys:S_nonSyncAttributes];
				[I_fullTextStorage setAttributes:filteredAttributes range:[self fullRangeForFoldedRange:aRange] synchronize:NO];
			}
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
//	NSLog(@"%s",__FUNCTION__);
	[self beginEditing];
	if (I_internalAttributedString) {
		unsigned origLen = [I_internalAttributedString length];
		NSRange fullRange = [self fullRangeForFoldedRange:inRange];

		[I_internalAttributedString replaceCharactersInRange:inRange withAttributedString:inAttributedString];
		[self edited:NSTextStorageEditedCharacters | NSTextStorageEditedAttributes range:inRange 
			  changeInLength:[I_internalAttributedString length] - origLen];

		if (inSynchronizeFlag) {
			[I_fullTextStorage replaceCharactersInRange:fullRange withAttributedString:inAttributedString synchronize:NO];
		}

	} else { // no foldings - no double data
//		unsigned origLen = [I_fullTextStorage length];
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
//	I_editingCount++;
//	if (I_editingCount == 1) {
//		NSLog(@"%s starting editing",__FUNCTION__);
//	}
	//if (!I_internalAttributedString) 
//	[I_fullTextStorage beginEditing];
	[super beginEditing];
}

- (void)endEditing {
	//if (!I_internalAttributedString) 
//	[I_fullTextStorage endEditing];
//	if (I_editingCount == 1) {
//		NSLog(@"%s ending editing",__FUNCTION__);
//	}
//	I_editingCount--;
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
		NSRange foldedReplacementRange = [self foldedReplacementRangeForFullTextReplaceCharactersInRange:inRange withString:inString shouldInsertString:&shouldInsertString foldingAttachments:I_sortedFoldedTextAttachments];
//		NSLog(@"%s replacing folded range %@ with %@", __FUNCTION__, NSStringFromRange(foldedReplacementRange), shouldInsertString ? @"inString" : @"NOTHING");
		if (foldedReplacementRange.length > 0 || shouldInsertString) {
			[self replaceCharactersInRange:foldedReplacementRange withString: (shouldInsertString ? inString : @"") synchronize:NO];
		}
//		NSLog(@"%s after: %@",__FUNCTION__,[self foldedStringRepresentation]);
	}
}

- (void)fullTextDidSetAttributes:(NSDictionary *)inAttributes range:(NSRange)inRange {
//	NSLog(@"%s %@",__FUNCTION__, NSStringFromRange(inRange));
	NSMutableDictionary *attributesPlusBlockedit = nil;
	if (!I_internalAttributedString) {
		[self edited:NSTextStorageEditedAttributes range:inRange changeInLength:0];
	} else {
		BOOL didBeginEditing = NO;
		// TODO: go through the range, set the attributes, and if folded areas are involved split the ranges up
		NSRange changeRange = [self foldedRangeForFullRange:inRange];
		NSRange attributeRange = NSMakeRange(changeRange.location,0);
		
		do {
			id attachment = [self attribute:NSAttachmentAttributeName atIndex:NSMaxRange(attributeRange) longestEffectiveRange:&attributeRange inRange:changeRange];
			if (!attachment) {
				// set Attributes
				if (!didBeginEditing) {
					[self beginEditing];
					didBeginEditing = YES;
				}
				
				// preserve blockedit attribute if there
				NSRange blockeditAttributeRange = NSMakeRange(attributeRange.location,0);
				do {
					id blockeditAttribute = [self attribute:BlockeditAttributeName atIndex:NSMaxRange(blockeditAttributeRange) longestEffectiveRange:&blockeditAttributeRange inRange:attributeRange];
					if (blockeditAttribute) {
						if (!attributesPlusBlockedit) {
							attributesPlusBlockedit = [inAttributes mutableCopy];
							[attributesPlusBlockedit setObject:BlockeditAttributeValue forKey:BlockeditAttributeName];

							NSDictionary *blockeditAttributes = nil;
							id delegate = self.delegate;
							if ([delegate respondsToSelector:@selector(blockeditAttributesForTextStorage:)]) {
								blockeditAttributes = [delegate blockeditAttributesForTextStorage:self];
							}
							if (blockeditAttributes) {
								[attributesPlusBlockedit addEntriesFromDictionary:blockeditAttributes];
							}
						}
						[self setAttributes:attributesPlusBlockedit range:blockeditAttributeRange synchronize:NO];
					} else {
						[self setAttributes:inAttributes range:blockeditAttributeRange synchronize:NO];
					}
				} while (NSMaxRange(blockeditAttributeRange) < NSMaxRange(attributeRange));
			}
		} while (NSMaxRange(attributeRange) < NSMaxRange(changeRange));
		
		
		if (didBeginEditing) [self endEditing];
	}
}

#pragma mark line numbers
- (int)lineNumberForLocation:(unsigned)location {
	int result = [I_fullTextStorage lineNumberForLocation:[self fullRangeForFoldedRange:NSMakeRange(location,0)].location];
	return result;
}

- (NSString *)positionStringForRange:(NSRange)aRange {
	return [I_fullTextStorage positionStringForRange:[self fullRangeForFoldedRange:aRange]];
}

- (NSRange)findLine:(int)aLineNumber {
	NSRange resultRange = [I_fullTextStorage findLine:aLineNumber];
	return [self foldedRangeForFullRange:resultRange];
}

#pragma mark - line endings and encoding
- (LineEnding)lineEnding {
	return [I_fullTextStorage lineEnding];
}

- (void)setLineEnding:(LineEnding)newLineEnding {
	[I_fullTextStorage setLineEnding:newLineEnding];
}

- (void)setShouldWatchLineEndings:(BOOL)aFlag {
	[I_fullTextStorage setShouldWatchLineEndings:aFlag];
}

- (BOOL)hasMixedLineEndings {
	return [I_fullTextStorage hasMixedLineEndings];
}

- (void)setHasMixedLineEndings:(BOOL)aFlag {
	[I_fullTextStorage setHasMixedLineEndings:aFlag];
}


- (NSStringEncoding)encoding {
	return [I_fullTextStorage encoding];
}

- (void)setEncoding:(NSStringEncoding)anEncoding {
	[I_fullTextStorage setEncoding:anEncoding];
}


#pragma mark folding

- (void)addFoldedTextAttachment:(FoldedTextAttachment *)inAttachment
{
	int index = 0;
	unsigned count = [I_sortedFoldedTextAttachments count];
	NSRange targetRange = [inAttachment foldedTextRange];
	for (index=0;index < count;index++) {
		if ([[I_sortedFoldedTextAttachments objectAtIndex:index] foldedTextRange].location > targetRange.location)
			break;
	}
	[I_sortedFoldedTextAttachments insertObject:inAttachment atIndex:index];
}

- (void)foldRange:(NSRange)inRange
{
	// first check if range is already a folding
	if ( inRange.length == 0 || 
		(inRange.length == 1 && [[self attribute:NSAttachmentAttributeName atIndex:inRange.location effectiveRange:NULL] isKindOfClass:[FoldedTextAttachment class]]) ) {
		// no fold
		return;
	}

	NSRange fullRange = [self fullRangeForFoldedRange:inRange];
	
	FoldedTextAttachment *attachment = [[FoldedTextAttachment alloc] initWithFoldedTextRange:fullRange];
	
	NSRange includedAttachmentsRange = [self indexRangeOfFoldingAttachments:I_sortedFoldedTextAttachments fullyContainedInRange:fullRange];
	
	if (includedAttachmentsRange.length > 0) {
		// put these attachments inside the new attachment
		NSMutableArray *innerAttachments = [attachment innerAttachments];
		while (includedAttachmentsRange.length > 0) {
			[innerAttachments addObject:[I_sortedFoldedTextAttachments objectAtIndex:includedAttachmentsRange.location]];
			[I_sortedFoldedTextAttachments removeObjectAtIndex:includedAttachmentsRange.location];
			includedAttachmentsRange.length--;
		}
	}
	
	NSMutableAttributedString *collapsedString = (NSMutableAttributedString *)[NSMutableAttributedString attributedStringWithAttachment:attachment];
//	NSLog(@"%s %@",__FUNCTION__,collapsedString);
	if (!I_internalAttributedString) { // generate it on first fold
		I_internalAttributedString = [I_fullTextStorage mutableCopy];
//		NSLog(@"%s ------------------------------> generated mutable string storage",__FUNCTION__);
	}
	[collapsedString addAttribute:NSToolTipAttributeName value:@"stub" range:NSMakeRange(0,[collapsedString length])];
	[self replaceCharactersInRange:inRange withAttributedString:collapsedString synchronize:NO];
	[self addFoldedTextAttachment:attachment];

	id delegate = [self delegate];
	if ([delegate respondsToSelector:@selector(textStorageDidChangeNumberOfTopLevelFoldings:)]) {
		[delegate textStorageDidChangeNumberOfTopLevelFoldings:self];
	}
}

- (NSMutableAttributedString *)attributedStringOfFolding:(FoldedTextAttachment *)inAttachment {
	NSMutableAttributedString *stringToInsert = nil;
	NSArray *innerAttachments = [inAttachment innerAttachments];
	NSRange foldedTextRange = [inAttachment foldedTextRange];
	unsigned index = 0;
	unsigned count = [innerAttachments count];
	if (count == 0) {
		stringToInsert = (NSMutableAttributedString *)[I_fullTextStorage attributedSubstringFromRange:foldedTextRange];
	} else {
		stringToInsert = [NSMutableAttributedString new];
		unsigned currentIndex = foldedTextRange.location;
		FoldedTextAttachment *attachment = nil;
		do {
			attachment = [innerAttachments objectAtIndex:index];
			NSRange attachmentRange = [attachment foldedTextRange];
			if (attachmentRange.location > foldedTextRange.location) {
				[stringToInsert appendAttributedString:[I_fullTextStorage attributedSubstringFromRange:NSMakeRange(currentIndex,attachmentRange.location - currentIndex)]];
			}
			[stringToInsert appendAttributedString:[NSAttributedString attributedStringWithAttachment:attachment]];
			[stringToInsert addAttribute:NSToolTipAttributeName value:@"stub" range:NSMakeRange([stringToInsert length] - 1,1)];
			currentIndex = NSMaxRange(attachmentRange);
			index++;
		} while (index < count);
		if (currentIndex < NSMaxRange(foldedTextRange)) {
			[stringToInsert appendAttributedString:[I_fullTextStorage attributedSubstringFromRange:NSMakeRange(currentIndex,NSMaxRange(foldedTextRange) - currentIndex)]];
		}
	}
	return stringToInsert;
}

- (void)removeInternalStorageString {
	I_internalAttributedString = nil;
	[self edited:NSTextStorageEditedCharacters | NSTextStorageEditedAttributes range:NSMakeRange(0,[I_internalAttributedString length]) changeInLength:0];
//	NSLog(@"%s ------------------------------> killed mutable string storage",__FUNCTION__);
}

- (void)unfoldAttachment:(FoldedTextAttachment *)inAttachment atCharacterIndex:(unsigned)inIndex {
	// first stop blockedit if there
	if ([self hasBlockeditRanges]) [self stopBlockedit];

	NSMutableAttributedString *stringToInsert = nil;
	NSArray *innerAttachments = [inAttachment innerAttachments];
	NSRange foldedTextRange = [inAttachment foldedTextRange];
	unsigned index = 0;
	unsigned count = [innerAttachments count];
	if (count == 0) {
		stringToInsert = (NSMutableAttributedString *)[I_fullTextStorage attributedSubstringFromRange:foldedTextRange];
	} else {
		stringToInsert = [NSMutableAttributedString new];
		unsigned currentIndex = foldedTextRange.location;
		FoldedTextAttachment *attachment = nil;
		do {
			attachment = [innerAttachments objectAtIndex:index];
			NSRange attachmentRange = [attachment foldedTextRange];
			if (attachmentRange.location > foldedTextRange.location) {
				[stringToInsert appendAttributedString:[I_fullTextStorage attributedSubstringFromRange:NSMakeRange(currentIndex,attachmentRange.location - currentIndex)]];
			}
			[stringToInsert appendAttributedString:[NSAttributedString attributedStringWithAttachment:attachment]];
			[stringToInsert addAttribute:NSToolTipAttributeName value:@"stub" range:NSMakeRange([stringToInsert length] - 1,1)];
			[self addFoldedTextAttachment:attachment];
			currentIndex = NSMaxRange(attachmentRange);
			index++;
		} while (index < count);
		if (currentIndex < NSMaxRange(foldedTextRange)) {
			[stringToInsert appendAttributedString:[I_fullTextStorage attributedSubstringFromRange:NSMakeRange(currentIndex,NSMaxRange(foldedTextRange) - currentIndex)]];
		}
	}
//	NSLog(@"%s unfolding: %@",__FUNCTION__,[self foldedStringRepresentationOfRange:[inAttachment foldedTextRange] foldings:innerAttachments level:1]);
	[self replaceCharactersInRange:NSMakeRange(inIndex,1) withAttributedString:stringToInsert synchronize:NO];
	[I_sortedFoldedTextAttachments removeObject:inAttachment];
	
	if ([I_sortedFoldedTextAttachments count] == 0) {
		[self removeInternalStorageString];
	}
	
	id delegate = [self delegate];
	if ([delegate respondsToSelector:@selector(textStorageDidChangeNumberOfTopLevelFoldings:)]) {
		[delegate textStorageDidChangeNumberOfTopLevelFoldings:self];
	}
}

- (BOOL)unfoldFoldingForPosition:(unsigned)aPosition {
	
	NSRange lineRange = [[self string] lineRangeForRange:NSMakeRange(aPosition,0)];
	NSRange attributeRange = NSMakeRange(lineRange.location,0);
	id attachment = nil;
	while (!attachment && NSMaxRange(attributeRange) < NSMaxRange(lineRange)) {
		attachment = [self attribute:NSAttachmentAttributeName atIndex:NSMaxRange(attributeRange) longestEffectiveRange:&attributeRange inRange:lineRange];
	}
	
	if (attachment) {
		// unfold
		[self unfoldAttachment:attachment atCharacterIndex:attributeRange.location];
		return YES;
	}
	
	return NO;
}

- (void)unfoldAll {
	[self beginEditing];
	// iterate and unfold all attachments - do so from bottom to top
	unsigned int length = [self length];
	if (length > 0 && [I_sortedFoldedTextAttachments count]) {
		NSRange iterationRange = NSMakeRange(length,0);
		id attachment = nil;
		do {
			attachment = [I_internalAttributedString attribute:NSAttachmentAttributeName atIndex:iterationRange.location-1 effectiveRange:&iterationRange];
			if (attachment && [attachment isKindOfClass:[FoldedTextAttachment class]]) {
				// remove attachment
				[self unfoldAttachment:attachment atCharacterIndex:iterationRange.location];
			}
		} while (iterationRange.location > 0 && [I_sortedFoldedTextAttachments count]);
	}
	[self endEditing];
}

- (void)foldAllWithFoldingLevel:(int)aFoldingLevel {
	if (aFoldingLevel <= 0 || [self length] == 0) return;

	FoldableTextStorage *textStorage = self;
	[textStorage beginEditing];

	// go to first location with that folding depth;
	
	NSRange startRange = NSMakeRange(0,0);
	NSString *foldingStateDelimiter = nil;
	// search for start delimiters
	NSRange wholeRange = NSMakeRange(0,[self length]);


    while (NSMaxRange(startRange) < wholeRange.length) {
    	// this is folding end search only, not delimiter end search
    	foldingStateDelimiter = [textStorage attribute:kSyntaxHighlightingFoldDelimiterName atIndex:NSMaxRange(startRange) longestEffectiveRange:&startRange inRange:wholeRange];
    	if ([foldingStateDelimiter isEqualToString:kSyntaxHighlightingStateDelimiterStartValue]) {
    		// now check this potential row of multiple starts for folding depth, begging from the end to the start
    		NSRange innerRange = NSMakeRange(NSMaxRange(startRange),0);
    		while (innerRange.location > startRange.location) {
				id foldingLevel = [textStorage attribute:kSyntaxHighlightingFoldingDepthAttributeName atIndex:innerRange.location-1 longestEffectiveRange:&innerRange inRange:startRange];
				if ([foldingLevel intValue] == aFoldingLevel) {
					// fetch folding area
					NSRange rangeForIndex = NSMakeRange(innerRange.location,0);
					rangeForIndex = [textStorage fullRangeForFoldedRange:rangeForIndex];
					NSRange rangeToFold = [I_fullTextStorage foldableRangeForCharacterAtIndex:rangeForIndex.location];
					if (rangeToFold.location != NSNotFound) {
						rangeToFold = [textStorage foldedRangeForFullRange:rangeToFold];
						
						// fold
						[textStorage foldRange:rangeToFold];
	
						// adjust whole Range
						wholeRange = NSMakeRange(0,[self length]);
						// adjust startRange to continue with the search after the folding
						startRange = NSMakeRange(rangeToFold.location,1);
						break; // continue with the outer loop searching for folding state delimiters
					}
				}
			}
    	}
    }

	[textStorage endEditing];
}

#define COMMENT_CHARACTER_COUNT_TO_START_FOLDING 80

- (NSRange)reducedFoldingRangeForCommentFoldingRange:(NSRange)inCommentRange {
	// check range to Fold for newlines if so fold beginning with the first newline to the end
	NSRange rangeToFold = inCommentRange;
	NSString *string = [self string];
	NSUInteger start, end, contentsEnd;
	[string getLineStart:&start end:&end contentsEnd:&contentsEnd forRange:NSMakeRange(rangeToFold.location,0)];
	if (NSMaxRange(rangeToFold) > end && NSMaxRange(rangeToFold) > contentsEnd) {
		rangeToFold = NSMakeRange(contentsEnd,NSMaxRange(rangeToFold) - contentsEnd);
	} else if (rangeToFold.length > COMMENT_CHARACTER_COUNT_TO_START_FOLDING + 5) {
		rangeToFold.location += COMMENT_CHARACTER_COUNT_TO_START_FOLDING;
		rangeToFold.length   -= COMMENT_CHARACTER_COUNT_TO_START_FOLDING;
	} else {
		// folding range not long enough so nothing to fold here.
		rangeToFold = NSMakeRange(NSNotFound,0);
	}
	return rangeToFold;
}

- (void)foldAllComments {
	[self beginEditing];
	NSRange wholeRange = NSMakeRange(0,[I_fullTextStorage length]);
	if (wholeRange.length > 0) {
		NSRange attributeRange = NSMakeRange(0,0);
		NSString *type = nil;
		
		do {
			type = [I_fullTextStorage attribute:kSyntaxHighlightingTypeAttributeName atIndex:NSMaxRange(attributeRange) longestEffectiveRange:&attributeRange inRange:wholeRange];
			if ([type isEqualToString:kSyntaxHighlightingTypeComment]) {
				attributeRange = [I_fullTextStorage continuousCommentRangeAtIndex:attributeRange.location];
//				NSLog(@"%s %@",__FUNCTION__,NSStringFromRange(attributeRange));
				NSRange continousCommentRange = [self foldedRangeForFullRange:attributeRange];
				continousCommentRange = [self reducedFoldingRangeForCommentFoldingRange:continousCommentRange];
				if (continousCommentRange.location != NSNotFound && continousCommentRange.length > 0) {
					[self foldRange:continousCommentRange];
				}
				// move ahead
				[I_fullTextStorage attribute:kSyntaxHighlightingTypeAttributeName atIndex:NSMaxRange(attributeRange) longestEffectiveRange:&attributeRange inRange:wholeRange];
			}
		} while (NSMaxRange(attributeRange) < NSMaxRange(wholeRange));
	}
	[self endEditing];
}

- (NSRange)foldableCommentRangeForCharacterAtIndex:(unsigned long int)anIndex {
	NSRange fullRange = [self fullRangeForFoldedRange:NSMakeRange(anIndex,0)];
	NSRange continousCommentRange = [I_fullTextStorage continuousCommentRangeAtIndex:fullRange.location];
	if (continousCommentRange.location != NSNotFound) {
		continousCommentRange = [self foldedRangeForFullRange:continousCommentRange];
		continousCommentRange = [self reducedFoldingRangeForCommentFoldingRange:continousCommentRange];
	}
	return continousCommentRange;
}


- (int)foldingDepthForLine:(int)aLineNumber {
	int maxDepth = 0;
	NSNumber *foldingDepth = nil;
	NSRange lineRange = [self findLine:aLineNumber];
	if (lineRange.length > 0) {
		NSRange attributeRange = NSMakeRange(lineRange.location,0);
		do {
			foldingDepth = [self attribute:kSyntaxHighlightingFoldingDepthAttributeName atIndex:NSMaxRange(attributeRange) longestEffectiveRange:&attributeRange inRange:lineRange];
			if ([foldingDepth isKindOfClass:[NSNumber class]]) {
				maxDepth = MAX([foldingDepth intValue],maxDepth);
			}
		} while (NSMaxRange(attributeRange) < NSMaxRange(lineRange));
	}
	return maxDepth;
}

- (NSRange)foldingRangeForLine:(int)aLineNumber {
	// todo return the correct folding range here
	int desiredFoldingDepth = [self foldingDepthForLine:aLineNumber];
	NSNumber *foldingDepth = nil;
	NSRange lineRange = [self findLine:aLineNumber];
	NSRange attributeRange = NSMakeRange(lineRange.location,0);
	if (lineRange.length > 0) {
		do {
			foldingDepth = [self attribute:kSyntaxHighlightingFoldingDepthAttributeName atIndex:NSMaxRange(attributeRange) longestEffectiveRange:&attributeRange inRange:lineRange];
		} while (NSMaxRange(attributeRange) < NSMaxRange(lineRange) && [foldingDepth intValue] != desiredFoldingDepth);
	}

	NSRange foldingRange = [self fullRangeForFoldedRange:attributeRange];
	foldingRange = [I_fullTextStorage foldableRangeForCharacterAtIndex:foldingRange.location];
	if (foldingRange.location == NSNotFound) return foldingRange;
	foldingRange = [self foldedRangeForFullRange:foldingRange];
//	NSLog(@"%s line:%d attributeRange:%@ foldingRange:%@",__FUNCTION__,aLineNumber, NSStringFromRange(attributeRange), NSStringFromRange(foldingRange));

	return foldingRange;
}


#pragma mark Blockedit

- (BOOL)hasBlockeditRanges {
    return I_blockedit.hasBlockeditRanges;
}
- (void)setHasBlockeditRanges:(BOOL)aFlag {
//	NSLog(@"%s %d",__FUNCTION__,aFlag);
    if (aFlag != I_blockedit.hasBlockeditRanges) {
        I_blockedit.hasBlockeditRanges=aFlag;
        id delegate=[self delegate];
        
        if (I_blockedit.hasBlockeditRanges && [delegate respondsToSelector:@selector(textStorageDidStartBlockedit:)]) {
            [delegate performSelector:@selector(textStorageDidStartBlockedit:) withObject:self];
        }
        
        if (!I_blockedit.hasBlockeditRanges && [delegate respondsToSelector:@selector(textStorageDidStopBlockedit:)]) {
            [delegate performSelector:@selector(textStorageDidStopBlockedit:) withObject:self];
        }
    }
}

- (BOOL)isBlockediting {
//	NSLog(@"%s %d",__FUNCTION__,I_blockedit.isBlockediting);
    return I_blockedit.isBlockediting;
}
- (void)setIsBlockediting:(BOOL)aFlag {
//	NSLog(@"%s %d",__FUNCTION__,aFlag);
    I_blockedit.isBlockediting=aFlag;
}

- (BOOL)didBlockedit {
//	NSLog(@"%s %d",__FUNCTION__,I_blockedit.didBlockedit);
    return I_blockedit.didBlockedit;
}
- (void)setDidBlockedit:(BOOL)aFlag {
//	NSLog(@"%s %d",__FUNCTION__,aFlag);
    I_blockedit.didBlockedit=aFlag;
}

- (NSRange)didBlockeditRange {
//	NSLog(@"%s %@",__FUNCTION__,NSStringFromRange(I_blockedit.didBlockeditRange));
    return I_blockedit.didBlockeditRange;
}
- (void)setDidBlockeditRange:(NSRange)aRange {
//	NSLog(@"%s %@",__FUNCTION__,NSStringFromRange(aRange));
    I_blockedit.didBlockeditRange=aRange;
}

- (NSRange)didBlockeditLineRange {
//	NSLog(@"%s %@",__FUNCTION__,NSStringFromRange(I_blockedit.didBlockeditLineRange));
    return I_blockedit.didBlockeditLineRange;
}
- (void)setDidBlockeditLineRange:(NSRange)aRange {
//	NSLog(@"%s %@",__FUNCTION__,NSStringFromRange(aRange));
    I_blockedit.didBlockeditLineRange=aRange;
}

- (void)stopBlockedit {
	//	NSLog(@"%s",__FUNCTION__);

	NSDictionary *blockeditAttributes = nil;
	id delegate = self.delegate;
	if ([delegate respondsToSelector:@selector(blockeditAttributesForTextStorage:)]) {
		blockeditAttributes = [delegate blockeditAttributesForTextStorage:self];
	}

	NSArray *attributeNameArray=[blockeditAttributes allKeys];
	NSRange range;
	NSRange wholeRange=NSMakeRange(0,[self length]);
	[self beginEditing];
	unsigned position=wholeRange.location;
	while (position<wholeRange.length) {
		id value=[self attribute:BlockeditAttributeName atIndex:position
		   longestEffectiveRange:&range inRange:wholeRange];
		if (value) {
			for (id loopItem in attributeNameArray) {
				[self removeAttribute:loopItem
								range:range];
			}
		}
		position=NSMaxRange(range);
	}
	[self endEditing];
	[self setHasBlockeditRanges:NO];
}


- (void)fixParagraphStyleAttributeInRange:(NSRange)aRange {
//	NSLog(@"%s %@",__FUNCTION__,NSStringFromRange(aRange));
    [super fixParagraphStyleAttributeInRange:aRange];

	NSDictionary *blockeditAttributes = nil;
	id delegate = self.delegate;
	if ([delegate respondsToSelector:@selector(blockeditAttributesForTextStorage:)]) {
		blockeditAttributes = [delegate blockeditAttributesForTextStorage:self];
	}

    NSString *string=[self string];
    NSRange lineRange=[string lineRangeForRange:aRange];
    NSRange blockeditRange;
    id value;
    unsigned position=lineRange.location;
    while (position<NSMaxRange(lineRange)) {
        value=[self attribute:BlockeditAttributeName atIndex:position
                            longestEffectiveRange:&blockeditRange inRange:lineRange];
        if (value) {
            NSRange blockLineRange=[string lineRangeForRange:blockeditRange];
            if (!NSEqualRanges(blockLineRange,blockeditRange)) {
                blockeditRange=blockLineRange;
                [self addAttributes:blockeditAttributes range:blockeditRange];
            }
        }
        position=NSMaxRange(blockeditRange);
    }
    
	id myDelegate = (id)self.delegate;
    if ([[[myDelegate documentMode] defaultForKey:DocumentModeIndentWrappedLinesPreferenceKey] boolValue]) {
        NSFont *font=[myDelegate fontWithTrait:0];
        int tabWidth=[myDelegate tabWidth];
        float characterWidth=[@" " sizeWithAttributes:[NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName]].width;
        int indentWrappedCharacterAmount = [[[myDelegate documentMode] defaultForKey:DocumentModeIndentWrappedLinesCharacterAmountPreferenceKey] intValue];
        // look at all the lines and fixe the indention
        NSRange myRange = NSMakeRange(aRange.location,0);
        do {
            myRange = [string lineRangeForRange:NSMakeRange(NSMaxRange(myRange),0)];
            if (myRange.length>0) {
                NSParagraphStyle *style=[self attribute:NSParagraphStyleAttributeName atIndex:myRange.location effectiveRange:NULL];
                if (style) {
                    float desiredHeadIndent = characterWidth*[string detabbedLengthForRange:[string rangeOfLeadingWhitespaceStartingAt:myRange.location] tabWidth:tabWidth] + [style firstLineHeadIndent] + indentWrappedCharacterAmount * characterWidth;
                    
                    if (ABS([style headIndent]-desiredHeadIndent)>0.01) {
                        NSMutableParagraphStyle *newStyle=[style mutableCopy];
                        [newStyle setHeadIndent:desiredHeadIndent];
                        [self addAttribute:NSParagraphStyleAttributeName value:newStyle range:myRange];
                    }
                }
            }
        } while (NSMaxRange(myRange)<NSMaxRange(aRange)); 
    }
}


- (NSRange)doubleClickAtIndex:(NSUInteger)index {
//	NSLog(@"atindex:%d",index);
    NSRange result=[super doubleClickAtIndex:index];
    NSRange colonRange;
    NSString *string=[self string];
    // now that we have a result we separate it using the colons so doubleClick don't selected over colons (especially important for Objective-C methods
    // we do this by searching the result range for colons and separate 3 cases:
    NSCharacterSet *characterSet = [NSCharacterSet characterSetWithCharactersInString:@":."];
    while (((colonRange = [string rangeOfCharacterFromSet:characterSet options:NSLiteralSearch range:result]).location != NSNotFound)) {
        if (index <= colonRange.location) {
			if (colonRange.location - result.location > 0) {
				result.length = MAX(colonRange.location,index+1)-result.location;
			}
            break;
        } else {
            result = NSMakeRange(NSMaxRange(colonRange),NSMaxRange(result)-NSMaxRange(colonRange));
        }
    }
//	NSLog(@"doubleClickAtIndex:%d returned: %@ (%@)",index,NSStringFromRange(result),[string substringWithRange:result]);
    return result;
}

- (NSArray *)selectionOperationsForRangesUnconvertableToEncoding:(NSStringEncoding)encoding {
	return [I_fullTextStorage selectionOperationsForRangesUnconvertableToEncoding:encoding];
}

@end


#pragma mark -

@implementation FoldableTextStorage (TextStorageScriptingAdditions)

- (NSRange)rangeRepresentation {
    return NSMakeRange(0,[self length]);
}

//- (NSArray *)scriptedCharacters {
//    NSLog(@"%s", __FUNCTION__);
//    NSMutableArray *result=[NSMutableArray array];
//    int length=[self length];
//    int index=0;
//    while (index<length) {
//        [result addObject:[ScriptCharacters scriptCharactersWithTextStorage:self characterRange:NSMakeRange(index++,1)]];
//    }
//    return result;
//}

- (unsigned int)countOfScriptedCharacters {
    return [[self fullTextStorage] length];
}

- (id)objectInScriptedCharactersAtIndex:(unsigned)index
{
//    NSLog(@"%s: %d", __FUNCTION__, index);
    return [ScriptCharacters scriptCharactersWithTextStorage:[self fullTextStorage] characterRange:NSMakeRange(index,1)];
}

- (void)insertObject:(id)anObject inScriptedCharactersAtIndex:(unsigned)anIndex {
    // has to be there for KVC not to mourn
}

- (void)removeObjectFromScriptedCharactersAtIndex:(unsigned)anIndex {
//    NSLog(@"%s: %d", __FUNCTION__, anIndex);
    [[self objectInScriptedCharactersAtIndex:anIndex] setScriptedContents:@""];
}

//- (NSArray *)scriptedLines
//{
//    // NSLog(@"%s", __FUNCTION__);
//    int lineCount = 1;
//    if ([self length]>0) {
//        lineCount = [self lineNumberForLocation:[self length]];
//    }
//    NSMutableArray *lines = [NSMutableArray array];
//    int lineNumber = 1;
//    for (lineNumber=1;lineNumber<=lineCount;lineNumber++) {
//        [lines addObject:[ScriptLine scriptLineWithTextStorage:self lineNumber:lineNumber]];
//    }
//    return lines;
//}

- (unsigned int)countOfScriptedLines {
    return [self lineNumberForLocation:[self length]];
}

- (id)objectInScriptedLinesAtIndex:(unsigned)index
{
    // NSLog(@"%s: %d", __FUNCTION__, index);
    return [ScriptLine scriptLineWithTextStorage:[self fullTextStorage] lineNumber:index+1];
}

- (void)insertObject:(id)anObject inScriptedLinesAtIndex:(unsigned)anIndex {
    // has to be there for KVC not to mourn
}

- (void)removeObjectFromScriptedLinesAtIndex:(unsigned)anIndex {
//    NSLog(@"%s: %d", __FUNCTION__, anIndex);
    [[self objectInScriptedLinesAtIndex:anIndex] setScriptedContents:@""];
}

- (NSString *)scriptedContents 
{
    // NSLog(@"%s", __FUNCTION__);
    return [[self fullTextStorage] string];
}

- (void)setScriptedContents:(id)value {
    // NSLog(@"%s: %d", __FUNCTION__, value);
    [(id)[self delegate] replaceTextInRange:NSMakeRange(0,[self length]) withString:value];
}

//- (id)insertionPoints
//{
//    NSMutableArray *resultArray=[NSMutableArray new];
//    int index=0;
//    int length=[self length];
//    for (index=0;index<=length;index++) {
//        [resultArray addObject:[ScriptTextSelection insertionPointWithTextStorage:[self fullTextStorage] index:index]];
//    }
//    return resultArray;
//}

- (unsigned int)countOfInsertionPoints {
	return [[self fullTextStorage] length] + 1;
}

- (id)objectInInsertionPointsAtIndex:(unsigned)anIndex {
    return [ScriptTextSelection insertionPointWithTextStorage:[self fullTextStorage] index:anIndex];
}


- (NSNumber *)scriptedLength
{
    return [NSNumber numberWithInt:[self length]];
}

- (NSNumber *)scriptedStartCharacterIndex
{
    return [NSNumber numberWithInt:1];
}

- (NSNumber *)scriptedNextCharacterIndex
{
    return [NSNumber numberWithInt:[self length]];
}


- (NSNumber *)scriptedStartLine
{
    return [NSNumber numberWithInt:1];
}

- (NSNumber *)scriptedEndLine
{
    int lineNumber;
    int length = [self length];
    if (length > 0) {
        lineNumber = [self lineNumberForLocation:length - 1];
    } else {
        lineNumber = 1;
    }
    return [NSNumber numberWithInt:lineNumber];
}

- (id)objectSpecifier
{
    NSScriptClassDescription *containerClassDesc = 
        (NSScriptClassDescription *)[NSScriptClassDescription classDescriptionForClass:[PlainTextDocument class]];
    
    NSScriptObjectSpecifier *containerSpecifier = [(id)[self delegate] objectSpecifier];
    NSPropertySpecifier *propertySpecifier = 
        [[NSPropertySpecifier alloc] initWithContainerClassDescription:containerClassDesc
                                                     containerSpecifier:containerSpecifier
                                                                    key:@"scriptedPlainContents"];

    return propertySpecifier;
}

@end

//#endif
