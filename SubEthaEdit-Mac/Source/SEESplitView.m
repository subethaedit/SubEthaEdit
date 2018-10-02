//
//  SEESplitView.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 10.04.14.
//  Copyright (c) 2014 TheCodingMonkeys. All rights reserved.
//

#import "SEESplitView.h"

@implementation SEESplitView

- (NSColor *)dividerColor {
	NSColor *result = [super dividerColor];
	if ([self.delegate respondsToSelector:@selector(dividerColorForSplitView:)]) {
		result = [(id<SEESplitViewDelegate>)self.delegate dividerColorForSplitView:self];
	}
	return result;
}

@end
