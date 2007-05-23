//
//  NSScreenTCMAdditions.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 23.05.07.
//  Copyright (c) 2007 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSScreen (NSScreenTCMAdditions)
+ (NSScreen *)menuBarContainingScreen;
+ (NSScreen *)screenContainingPoint:(NSPoint)aPoint;
@end
