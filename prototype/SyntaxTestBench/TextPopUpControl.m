//
//  TextPopUpControl.m
//  XXP
//
//  Created by Dominik Wagner on Sun Mar 02 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "TextPopUpControl.h"
#import "TextPopUpCell.h"

@implementation TextPopUpControl

+ (void)initialize {
    if (self == [TextPopUpControl class]) {
        [self setCellClass: [TextPopUpCell class]];
    }
}

+ (Class)cellClass {
    return [TextPopUpCell class];
}

- (id)initWithFrame:(NSRect)frameRect pullsDown:(BOOL)flag {   
    return [super initWithFrame:frameRect pullsDown:flag];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (id)delegate {
    return _delegate;
}

- (void)setDelegate:(id)aDelegate {
    _delegate=aDelegate;
}


@end
