//  FontForwardingView.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 01.12.08.

#import <Cocoa/Cocoa.h>


@interface FontForwardingTextField : NSTextField {
	BOOL I_isFirstResponder;
}

@property (nonatomic, weak) id fontDelegate;
@end
