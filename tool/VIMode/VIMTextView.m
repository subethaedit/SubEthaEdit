//
//  VIMTextView.m
//  VIMode
//
//  Created by Martin Pittenauer on 25.04.05.
//  Copyright 2005 TheCodingMonkeys. All rights reserved.
//


// This is just a skeleton class that stands for SEE's textview
// and not part of the actual VIMode. Please mostly ignore this class.

#import "VIMTextView.h"

#define ESCAPE_KEY 27

@implementation VIMTextView

- (id)init {
    self = [super init];
    if (self) {
        I_viController = [[TCMVIController alloc] initWithTextView:self];
    }
    return self;
}

- (void) awakeFromNib {
    I_viController = [[TCMVIController alloc] initWithTextView:self];
}

- (void) dealloc {
    [I_viController release];
    [super dealloc];
}

- (void) keyDown:(NSEvent *) event {

    unichar c = [[event characters] characterAtIndex:0];
    //NSLog([event description]);

    if (c == ESCAPE_KEY) [I_viController toggleMode];
    else [I_viController keyDown:event];
}

- (void) superKeyDown:(NSEvent *) event {
    [super keyDown:event];
}

@end
