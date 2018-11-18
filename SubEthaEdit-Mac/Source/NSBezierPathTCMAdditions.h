//  NSBezierPathTCMAdditions.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 21.09.07.

#import <Cocoa/Cocoa.h>


@interface NSBezierPath(BezierPathTCMAdditions)
+ (NSBezierPath *)bezierPathWithRoundedRect:(NSRect)rect radius:(float)radius;
+ (NSBezierPath *)bezierPathWithTopCapOfRoundedRect:(NSRect)rect radius:(float)radius;
@end
