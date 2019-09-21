//  FontForwardingView.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 01.12.08.

#import "FontForwardingTextField.h"

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
