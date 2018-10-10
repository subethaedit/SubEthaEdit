//  SEESplitView.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 10.04.14.

#import "SEESplitView.h"

@implementation SEESplitView

- (void)viewDidChangeEffectiveAppearance {
    if ([self.delegate respondsToSelector:@selector(splitViewEffectiveAppearanceDidChange:)]) {
        [(id<SEESplitViewDelegate>)self.delegate splitViewEffectiveAppearanceDidChange:self];
    }
}

- (NSColor *)dividerColor {
	NSColor *result = [super dividerColor];
	if ([self.delegate respondsToSelector:@selector(dividerColorForSplitView:)]) {
		result = [(id<SEESplitViewDelegate>)self.delegate dividerColorForSplitView:self];
	}
	return result;
}

@end
