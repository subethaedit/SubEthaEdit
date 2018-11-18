//  PullDownButton.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Fri May 28 2004.

#import "PullDownButton.h"
#import "PullDownButtonCell.h"


@implementation PullDownButton

- (void)mouseDown:(NSEvent *)aEvent {
    NSPoint location=[self convertPoint:[aEvent locationInWindow] fromView:nil];
    if (location.x>=7 && location.x<=[(PullDownButtonCell *)[self cell] desiredWidth]+5) {
        [super mouseDown:aEvent];
    }
}

@end
