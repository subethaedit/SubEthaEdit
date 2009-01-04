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
    }
    return self;
}

- (void)dealloc {
    [I_internalAttributedString release];
    [I_fullTextStorage release];
    [super dealloc];
}


- (FullTextStorage *)fullTextStorage {
	return I_fullTextStorage;
}

- (NSRange)fullRangeForFoldableRange:(NSRange)inRange
{
	return inRange;
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
    	[I_fullTextStorage replaceCharactersInRange:[self fullRangeForFoldableRange:aRange] withString:aString synchronize:NO];
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

- (void)foldRange:(NSRange)inRange
{
	NSTextAttachment *attachment = [[[FoldedTextAttachment alloc] initWithFoldedTextRange:[self fullRangeForFoldableRange:inRange]] autorelease];
	NSAttributedString *collapsedString = [NSAttributedString attributedStringWithAttachment:attachment];
	NSLog(@"%s %@",__FUNCTION__,collapsedString);
	[self replaceCharactersInRange:inRange withAttributedString:collapsedString synchronize:NO];
}

- (void)unfoldAttachment:(FoldedTextAttachment *)inAttachment atIndex:(NSUInteger)inIndex
{
	// actually we should do this without copying the string again - e.g. by directly copying the stuff from the fullTextStorage by range
	NSAttributedString *string = [I_fullTextStorage attributedSubstringFromRange:[inAttachment foldedTextRange]];
	[self replaceCharactersInRange:NSMakeRange(inIndex,1) withAttributedString:string synchronize:NO];
}



@end
