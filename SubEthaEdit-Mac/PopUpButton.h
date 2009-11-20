//
//  PopUpButton.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Tue Apr 20 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PopUpButton : NSPopUpButton {
    id I_delegate;
}
- (void)setDelegate:(id)aDelegate;
- (id)delegate;
@end

@interface NSObject(PopUpButtonDelegateAdditions) 
- (void)popUpWillShowMenu:(PopUpButton *)aButton;
@end