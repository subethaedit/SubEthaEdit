//
//  TextView.m
//  TextEdit
//
//  Created by Dominik Wagner on 04.01.09.
//  Copyright 2009 TheCodingMonkeys. All rights reserved.
//

#import "TextView.h"

@implementation FoldedTextAttachment
- (id)initWithFoldedText:(NSAttributedString *)inFoldedText
{
	if ((self = [super initWithFileWrapper:[[[NSFileWrapper alloc] initWithPath:[[NSBundle mainBundle] pathForResource:@"folded" ofType:@"tiff"]] autorelease]]))
	{
		I_foldedText = [inFoldedText copy];
	}
	return self;
}

- (NSAttributedString *)foldedText {
	return I_foldedText;
}

- (void)dealloc
{
	[I_foldedText autorelease];
	I_foldedText = nil;
	[super dealloc];
}

@end


@implementation TextView

- (void)collapseRange:(NSRange)inRange
{
	NSTextAttachment *attachment = [[[FoldedTextAttachment alloc] initWithFoldedText:[[self textStorage] attributedSubstringFromRange:inRange]] autorelease];
	NSAttributedString *collapsedString = [NSAttributedString attributedStringWithAttachment:attachment];
	// for undo
	[self setSelectedRange:inRange];
	[self insertText:collapsedString];

//	[[self textStorage] replaceCharactersInRange:inRange withAttributedString:collapsedString];
}

- (void)collapseSelection:(id)inSender
{
	NSRange selectedRange = [self selectedRange];
	[self collapseRange:selectedRange];
}

- (void)unfoldAttachment:(FoldedTextAttachment *)inAttachment atIndex:(NSUInteger)inIndex
{
	NSAttributedString *string = [inAttachment foldedText];
	// for undo
	[self setSelectedRange:NSMakeRange(inIndex,1)];
	[self insertText:string];
	
//	[[self textStorage] replaceCharactersInRange:NSMakeRange(inIndex,1) withAttributedString:string];
}


@end
