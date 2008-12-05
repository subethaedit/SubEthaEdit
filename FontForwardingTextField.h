//
//  FontForwardingView.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 01.12.08.
//  Copyright 2008 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface FontForwardingTextField : NSTextField {
	id I_delegate;
	BOOL I_isFirstResponder;
}

- (void)setFontDelegate:(id)aDelegate;

@end
