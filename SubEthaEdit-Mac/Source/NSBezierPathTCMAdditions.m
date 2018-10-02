//  NSBezierPathTCMAdditions.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 21.09.07.

#import "NSBezierPathTCMAdditions.h"
#define TITLEBARHEIGHT 19.0

@implementation NSBezierPath(NSBezierPathTCMAdditions)
+ (NSBezierPath *)bezierPathWithRoundedRect:(NSRect)rect radius:(float)radius
{
        NSRect irect = NSInsetRect( rect, radius, radius );
        float minX = NSMinX( irect );
        float minY = NSMinY( irect );
        float maxX = NSMaxX( irect );
        float maxY = NSMaxY( irect );

        NSBezierPath *path = [NSBezierPath bezierPath];

        [path appendBezierPathWithArcWithCenter:NSMakePoint( minX, minY )
                                                                         radius:radius 
                                                                 startAngle:180.0f
                                                                   endAngle:270.0f];

        [path appendBezierPathWithArcWithCenter:NSMakePoint( maxX, minY ) 
                                                                         radius:radius 
                                                                 startAngle:270.0f
                                                                   endAngle:360.0f];

        [path appendBezierPathWithArcWithCenter:NSMakePoint( maxX, maxY )
                                                                         radius:radius 
                                                                 startAngle:0.0f
                                                                   endAngle:90.0f];

        [path appendBezierPathWithArcWithCenter:NSMakePoint( minX, maxY )
                                                                         radius:radius 
                                                                 startAngle:90.0f
                                                                   endAngle:180.0f];

        [path closePath];

        return path;
}

+ (NSBezierPath *)bezierPathWithBottomCapOfRoundedRect:(NSRect)rect radius:(float)radius {
        NSRect irect = NSInsetRect( rect, radius, radius );
        float minX = NSMinX( irect );
        float minY = NSMinY( irect );
        float maxX = NSMaxX( irect );
        float maxY = NSMaxY( irect );

        NSBezierPath *path = [NSBezierPath bezierPath];

        [path moveToPoint:NSMakePoint(minX-radius,maxY-TITLEBARHEIGHT+radius)];

        [path appendBezierPathWithArcWithCenter:NSMakePoint( minX, minY )
                                                                         radius:radius 
                                                                 startAngle:180.0f
                                                                   endAngle:270.0f];

        [path appendBezierPathWithArcWithCenter:NSMakePoint( maxX, minY ) 
                                                                         radius:radius 
                                                                 startAngle:270.0f
                                                                   endAngle:360.0f];

        [path lineToPoint:NSMakePoint(maxX+radius,maxY-TITLEBARHEIGHT+radius)];

        [path closePath];

        return path;
}

+ (NSBezierPath *)bezierPathWithTopCapOfRoundedRect:(NSRect)rect radius:(float)radius {
        NSRect irect = NSInsetRect( rect, radius, radius );
        float minX = NSMinX( irect );
        float maxX = NSMaxX( irect );
        float maxY = NSMaxY( irect );

        NSBezierPath *path = [NSBezierPath bezierPath];

        [path moveToPoint:NSMakePoint(maxX+radius,maxY-TITLEBARHEIGHT+radius)];

        [path appendBezierPathWithArcWithCenter:NSMakePoint( maxX, maxY )
                                                                         radius:radius 
                                                                 startAngle:0.0f
                                                                   endAngle:90.0f];

        [path appendBezierPathWithArcWithCenter:NSMakePoint( minX, maxY )
                                                                         radius:radius 
                                                                 startAngle:90.0f
                                                                   endAngle:180.0f];
        [path lineToPoint:NSMakePoint(minX-radius,maxY-TITLEBARHEIGHT+radius)];
        [path closePath];

        return path;
}


@end
