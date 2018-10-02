//  NSScreenTCMAdditions.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 23.05.07.

#import <Cocoa/Cocoa.h>


@interface NSScreen (NSScreenTCMAdditions)
+ (NSScreen *)menuBarContainingScreen;
+ (NSScreen *)screenContainingPoint:(NSPoint)aPoint;
@end
