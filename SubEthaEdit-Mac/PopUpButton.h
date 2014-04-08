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
}

@property (nonatomic) CGRectEdge lineDrawingEdge; // defaults to CGRectMaxXEdge; possible values: CGRectMaxXEdge, CGRectMinXEdge

@property (nonatomic, weak) id<PopUpButtonDelegate>delegate;
@property (nonatomic, strong) NSColor *lineColor;

@end