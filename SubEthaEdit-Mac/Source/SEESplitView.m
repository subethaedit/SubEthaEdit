//  SEESplitView.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 10.04.14.

#import "SEESplitView.h"

// this file needs arc - add -fobjc-arc in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

@implementation SEESplitView

- (NSColor *)dividerColor {
	NSColor *result = [super dividerColor];
	if ([self.delegate respondsToSelector:@selector(dividerColorForSplitView:)]) {
		result = [(id<SEESplitViewDelegate>)self.delegate dividerColorForSplitView:self];
	}
	return result;
}

@end
