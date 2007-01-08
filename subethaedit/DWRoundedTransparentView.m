//
//  DWRoundedTransparentView.m
//  Glasnost
//
//  Created by Dominik Wagner on 07.05.05.
//  Copyright 2005 TheCodingMonkeys. All rights reserved.
//

#import "DWRoundedTransparentView.h"

#define TITLEBARHEIGHT 19.0

@implementation NSBezierPath(BezierPathDWAdditions)
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
        float minY = NSMinY( irect );
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


@implementation DWRoundedTransparentView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        I_titleString = [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"] copy];
    }
    return self;
}

- (NSString *)title {
    return I_titleString;
}

- (void)setTitle:(NSString *)aTitle {
    [I_titleString autorelease];
    I_titleString = [aTitle copy];
}


- (void)dealloc {
    [I_titleString autorelease];
    [super dealloc];
}

- (BOOL)isOpaque {
    return NO;
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent {
    return YES;
}

- (void)drawRect:(NSRect)rect {
    NSRect bounds=[self bounds];
//    [[NSColor clearColor] set];
//    [NSBezierPath fillRect:bounds];
    
    float radius=6.f;
    [[NSColor colorWithCalibratedWhite:0.1 alpha:.75] set];
    [[NSBezierPath bezierPathWithBottomCapOfRoundedRect:bounds radius:radius] fill];

    [[NSImage imageNamed:@"SmallGrowBoxRight3"] compositeToPoint:NSMakePoint(bounds.size.width-18.,6) operation:NSCompositeSourceOver fraction:1.0];

    if (I_titleString) {
        [[NSColor colorWithCalibratedWhite:0. alpha:.40] set];
        static NSDictionary *s_titleAttributes=nil;
        if (!s_titleAttributes) {
            NSMutableParagraphStyle *paragraphStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
            [paragraphStyle setAlignment:NSCenterTextAlignment];
            [paragraphStyle setLineBreakMode:NSLineBreakByTruncatingMiddle];
            NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
            [shadow setShadowOffset:NSMakeSize(0.0f, -2.0f)];
            [shadow setShadowBlurRadius:3.0f];
            [shadow setShadowColor:[NSColor blackColor]];
            s_titleAttributes = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                [NSColor whiteColor], NSForegroundColorAttributeName,
//                shadow, NSShadowAttributeName,
                paragraphStyle, NSParagraphStyleAttributeName,
                [NSFont systemFontOfSize:[NSFont smallSystemFontSize]], NSFontAttributeName, nil];
        }
        NSBezierPath *path = [NSBezierPath bezierPathWithTopCapOfRoundedRect:bounds radius:radius];
        [[NSColor colorWithCalibratedWhite:0.25 alpha:.75] set];
        [path fill];
        bounds.origin.y+=bounds.size.height-TITLEBARHEIGHT-2.;
        bounds.size.height=TITLEBARHEIGHT;
        bounds = NSInsetRect(bounds,23.,0.);
        bounds.origin.x += 6.;
        [I_titleString drawInRect:bounds withAttributes:s_titleAttributes];
    }

}

@end
