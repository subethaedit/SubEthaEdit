//
//  PopUpButton.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Tue Apr 20 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PopUpButton;

@protocol PopUpButtonDelegate <NSObject>
- (void)popUpWillShowMenu:(PopUpButton *)aButton;
@end

@interface PopUpButton : NSPopUpButton {
    id I_delegate;
}
- (void)setDelegate:(id <PopUpButtonDelegate>)aDelegate;
- (id)delegate;
@end