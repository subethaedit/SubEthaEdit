//
//  PendingParticipantsTableView.m
//  SubEthaEdit
//
//  Created by Martin Ott on Thu Apr 29 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "PendingParticipantsTableView.h"


@implementation PendingParticipantsTableView

- (unsigned int)draggingSourceOperationMaskForLocal:(BOOL)isLocal
{
    if (!isLocal) {
        return NSDragOperationDelete;
    }
    
    return NSDragOperationMove;
}


- (void)draggedImage:(NSImage *)anImage endedAt:(NSPoint)aPoint operation:(NSDragOperation)operation {
    NSLog(@"draggedImage:endedAt:operation: %d", operation);
    [super draggedImage:anImage endedAt:aPoint operation:operation];
    if (operation == NSDragOperationNone) {
        NSPoint point;
        point.x = aPoint.x + [anImage size].width / 2;
        point.y = aPoint.y + [anImage size].height / 2;
        NSShowAnimationEffect(NSAnimationEffectDisappearingItemDefault, point, NSMakeSize(64, 64), nil, 0, NULL);
    }
}


@end
