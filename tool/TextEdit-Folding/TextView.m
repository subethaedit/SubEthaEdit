//
//  TextView.m
//  TextEdit
//
//  Created by Dominik Wagner on 04.01.09.
//  Copyright 2009 TheCodingMonkeys. All rights reserved.
//

#import "TextView.h"
#import "FoldableTextStorage.h"
#import "FullTextStorage.h"

#define MyRandomInRange(minInt,maxInt) ( (random() % (((maxInt) +1) - (minInt))) + (minInt) )

@implementation TextView


- (void)collapseSelection:(id)inSender
{
	NSRange selectedRange = [self selectedRange];
	[(FoldableTextStorage *)[self textStorage] foldRange:selectedRange];
}

- (void)makeRandomChangeInFullStorage:(id)inSender {
	NSTextStorage *fullText = [(FoldableTextStorage *)[self textStorage] fullTextStorage];
	NSRange fullLength = NSMakeRange(0,[fullText length]);
	NSRange changeRange = NSMakeRange(MyRandomInRange(0,fullLength.length),0);
	if (changeRange.location < fullLength.length) {
		changeRange.length = MyRandomInRange(0,MIN(80,NSMaxRange(fullLength)-NSMaxRange(changeRange)));
	}
	NSString *replacementString = [@"" stringByPaddingToLength:MyRandomInRange(0,80) withString:@"Lorem Ipsum blah blah \n foo bar\r\n zwar tralalala ma pa asdf asdfk asdf  asdfa this is real text but random nevertheless you know because this is ugly \n really ugly asödlfkj aösldkfj asöldkfj aölsdkfjalöksdjf asdfiaspdfapfewifj pfoasdijf asßdf aßsdf ßasdßf ßasdf asdflkj adsölkfj asöldfjkals öjdflö and not meaningfull. All work and no play makes jack a dull boy. " startingAtIndex:0];
	[fullText replaceCharactersInRange:changeRange withString:replacementString];
}

- (void)logDebugOutput:(id)inSender
{
	NSLog(@"%s \nts:\n%@\n-------\nfts:\n%@",__FUNCTION__,[[self textStorage] string],[[(FoldableTextStorage *)[self textStorage] fullTextStorage] string]);
	NSLog(@"%s %@",__FUNCTION__,[(FoldableTextStorage *)[self textStorage] foldedStringRepresentation]);
}

@end
