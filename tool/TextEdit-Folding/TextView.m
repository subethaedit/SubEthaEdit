//
//  TextView.m
//  TextEdit
//
//  Created by Dominik Wagner on 04.01.09.
//  Copyright 2009 TheCodingMonkeys. All rights reserved.
//

#import "TextView.h"
#import "FoldableTextStorage.h"

@implementation TextView


- (void)collapseSelection:(id)inSender
{
	NSRange selectedRange = [self selectedRange];
	[(FoldableTextStorage *)[self textStorage] foldRange:selectedRange];
}

- (void)logDebugOutput:(id)inSender
{
	NSLog(@"%s \nts:\n%@\n-------\nfts:\n%@",__FUNCTION__,[[self textStorage] string],[[(FoldableTextStorage *)[self textStorage] fullTextStorage] string]);
}

@end
