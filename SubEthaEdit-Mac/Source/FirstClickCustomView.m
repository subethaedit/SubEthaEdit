//  FirstClickCustomView.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 03.01.07.

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
