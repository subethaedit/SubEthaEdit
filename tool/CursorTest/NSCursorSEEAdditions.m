//
//  NSCursorSEEAdditions.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 07.03.06.
//  Copyright 2006 TheCodingMonkeys. All rights reserved.
//

#import "NSCursorSEEAdditions.h"


@implementation NSCursor (NSCursorSEEAdditions)

+ (NSCursor *)invertedIBeamCursor {
//    NSLog(@"%s",__FUNCTION__);
    static NSCursor *s_invertedIBeamCursor;
    if (!s_invertedIBeamCursor) {
        s_invertedIBeamCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"InvertedIBeam"] hotSpot:NSMakePoint(4,6)];
    }
    return s_invertedIBeamCursor;
}

@end
