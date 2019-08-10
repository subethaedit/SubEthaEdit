//  FontForwardingView.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 01.12.08.

#import "FontForwardingTextField.h"

// this file needs arc - add -fobjc-arc in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

@implementation FontForwardingTextField

- (void)changeFont:(id)aSender {
	if ([_fontDelegate respondsToSelector:@selector(changeFont:)]) {
		[_fontDelegate changeFont:aSender];
	}
}

- (BOOL)acceptsFirstResponder{
	return YES;
}

- (BOOL)becomeFirstResponder {
	BOOL result = [super becomeFirstResponder];
	I_isFirstResponder = YES;
	return result;
}

- (BOOL)resignFirstResponder {
	BOOL result = [super resignFirstResponder];
	I_isFirstResponder = NO;
	
	return result;
}


- (void)drawRect:(NSRect)aRect {
	[[self cell] setHighlighted:I_isFirstResponder];
	
	[super drawRect:aRect];
}

@end
