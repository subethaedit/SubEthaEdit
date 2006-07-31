//
//  TextView.m
//  CursorTest
//
//  Created by Dominik Wagner on 31.07.06.
//  Copyright 2006 TheCodingMonkeys. All rights reserved.
//

#import "TextView.h"


@implementation TextView
- (void)addCursorRect:(NSRect)aRect cursor:(NSCursor *)aCursor {
    NSLog(@"%s %@ %@",__FUNCTION__,NSStringFromRect(aRect),aCursor);
    [super addCursorRect:aRect cursor:aCursor];
}

- (void)mouseMoved:(NSEvent *)anEvent {
    // [super mouseMoved:anEvent];
    if ([NSCursor currentCursor] == [NSCursor IBeamCursor]) {
        [[NSCursor currentCursor] pop];
        [[NSCursor invertedIBeamCursor] set];
    }

}

@end
