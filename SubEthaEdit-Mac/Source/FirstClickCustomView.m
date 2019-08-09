//  FirstClickCustomView.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 03.01.07.

#import "FirstClickCustomView.h"

// this file needs arc - add -fobjc-arc in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

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
