//  FontForwardingView.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 01.12.08.

#import <Cocoa/Cocoa.h>


@interface FontForwardingTextField : NSTextField {
	id I_delegate;
	BOOL I_isFirstResponder;
}

- (void)setFontDelegate:(id)aDelegate;

@end
