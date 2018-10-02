//
//  FirstClickCustomView.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 03.01.07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import "FirstClickCustomView.h"


@implementation FirstClickCustomView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent {
    return YES;
}
@end
