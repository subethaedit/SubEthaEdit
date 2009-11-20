//
//  ButtonScrollView.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Thu Apr 15 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "ButtonScrollView.h"


@implementation ButtonScrollView 

- (id)initWithFrame:(NSRect)rect {
    if ((self = [super initWithFrame:rect])) {

        I_button = [[NSButton alloc] initWithFrame:NSMakeRect(0.0,0.0,1.0,1.0)];
        [I_button setBordered:NO];
        [I_button setButtonType:NSSwitchButton];
        [I_button setTitle:@""];
        [I_button setImage:[NSImage imageNamed:@"SplitOpen"]];
        [I_button setAlternateImage:[NSImage imageNamed:@"SplitClose"]];
        [I_button setAction:@selector(toggleSplitView:)];
        [I_button setTarget:nil];
        [I_button sizeToFit];
        [I_button setHidden:YES];
        [self addSubview:I_button];
    }
    return self;
}

- (void)dealloc {
    [I_button release];
    [super dealloc];
}

- (void)tile {
    // Let the superclass do most of the work.
    [super tile];

    if (![self hasVerticalScroller]) {
        if (I_button) [I_button removeFromSuperview];
    } else {
        NSScroller *verticalScroller;
        NSRect verticalScrollerFrame, buttonFrame;
        
        verticalScroller = [self verticalScroller];
        verticalScrollerFrame = [verticalScroller frame];
        buttonFrame = [I_button frame];
    
        // Now we'll just adjust the vertical scroller size and set the button size and location.
        verticalScrollerFrame.size.height -= buttonFrame.size.height;
        verticalScrollerFrame.origin.y    += buttonFrame.size.height;
        [verticalScroller setFrame:verticalScrollerFrame];
    
        buttonFrame.origin.x =   verticalScrollerFrame.origin.x;
        buttonFrame.size.width = verticalScrollerFrame.size.width + 1.0;
        buttonFrame.origin.y = [self bounds].origin.y;
        [I_button setFrame:buttonFrame];
        [I_button setHidden:NO];
    }
}

- (NSButton *)button {
    return I_button;
}

@end
