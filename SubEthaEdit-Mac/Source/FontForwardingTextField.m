//
//  FontForwardingView.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 01.12.08.
//  Copyright 2008 TheCodingMonkeys. All rights reserved.
//

#import "FontForwardingTextField.h"


@implementation FontForwardingTextField

- (void)setFontDelegate:(id)aDelegate {
	I_delegate = aDelegate;
}

- (void)changeFont:(id)aSender {
	if ([I_delegate respondsToSelector:@selector(changeFont:)]) {
		[I_delegate changeFont:aSender];
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
