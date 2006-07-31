//
//  ScrollView.m
//  CursorTest
//
//  Created by Dominik Wagner on 31.07.06.
//  Copyright 2006 TheCodingMonkeys. All rights reserved.
//

#import "ScrollView.h"


@implementation ScrollView
- (void)addCursorRect:(NSRect)aRect cursor:(NSCursor *)aCursor {
    NSLog(@"%s %@ %@",__FUNCTION__,NSStringFromRect(aRect),aCursor);
    [super addCursorRect:aRect cursor:aCursor];
}
- (void)setDocumentCursor:(NSCursor *)aCursor {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSLog(@"%s %@",__FUNCTION__, aCursor);
    [super setDocumentCursor:aCursor];
}

@end
