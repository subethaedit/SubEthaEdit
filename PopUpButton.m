//
//  PopUpButton.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Tue Apr 20 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "PopUpButton.h"
#import "PopUpButtonCell.h"

@implementation PopUpButton

+ (void)initialize {
    if (self == [PopUpButton class]) {
        [self setCellClass:[PopUpButtonCell class]];
    }
}

+ (Class)cellClass {
    return [PopUpButtonCell class];
}

- (id)initWithFrame:(NSRect)frameRect pullsDown:(BOOL)flag {   
    self=[super initWithFrame:frameRect pullsDown:flag];
//    NSLog(@"init and my cell is:%@",NSStringFromClass([[self cell] class]));
    return self;
}

- (void)dealloc {
    [self setDelegate:nil];
    [super dealloc];
}

- (void)mouseDown:(NSEvent *)theEvent {
    id delegate=[self delegate];
    if ([delegate respondsToSelector:@selector(popUpWillShowMenu:)]) {
        [delegate popUpWillShowMenu:self];
    }
    [super mouseDown:theEvent];
}

- (void)setDelegate:(id)aDelegate {
    I_delegate=aDelegate;
}

- (id)delegate {
    return I_delegate;
}


@end
