//
//  NSScreenTCMAdditions.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 23.05.07.
//  Copyright (c) 2007 TheCodingMonkeys. All rights reserved.
//

#import "NSScreenTCMAdditions.h"

@implementation NSScreen (NSScreenTCMAdditions)
+ (NSScreen *)menuBarContainingScreen {
    NSArray *screens = [NSScreen screens];
    if ([screens count] > 0) {
        return [screens objectAtIndex:0];
    } else {
        return nil;
    }
}

+ (NSScreen *)screenContainingPoint:(NSPoint)aPoint {
    NSArray *screens = [NSScreen screens];
    int count = [screens count];
    int i=0;
    for (i=0;i<count;i++) {
        NSScreen *screen = [screens objectAtIndex:i];
        if (NSPointInRect(aPoint,[screen frame])) {
            return screen;
        }
    }
    return nil;
}

@end
