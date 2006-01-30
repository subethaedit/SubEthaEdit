//
//  TCMBezelView.m
//  VIMode
//
//  Created by Martin Pittenauer on 25.04.05.
//  Copyright 2005 TheCodingMonkeys. All rights reserved.
//

#import "TCMVIBezelView.h"


@implementation TCMVIBezelView


- (id)init {
    self = [super init];
    if (self) {
        I_description = [NSString new];
        I_command = [NSString new];
    }
    return self;
}


- (void)drawRect:(NSRect)rect {
       NSRect bounds = [self bounds];

        // clear the window
        [[NSColor clearColor] set];
        NSRectFill( [self frame] );

        // draw the bezel
        NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:bounds radius:20.0f];
        [[NSColor colorWithCalibratedRed:0.0f green:0.0f blue:0.0f alpha:(40 * 0.01f)] set];
        [path fill];

        // draw command string

        NSString *aString; 
        NSRect stringRect;
        NSMutableParagraphStyle *parStyle;
        NSShadow *shadow; 
        NSMutableDictionary *attributes;
        int fontSize = 42;
        
        aString = I_command;
        
        parStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
        [parStyle setAlignment:NSCenterTextAlignment];
        
        shadow = [[[NSShadow alloc] init] autorelease];
        [shadow setShadowOffset:NSMakeSize(0.0f, -2.0f)];
        [shadow setShadowBlurRadius:3.0f];
        [shadow setShadowColor:[NSColor blackColor]];

         attributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:
            [NSColor whiteColor], NSForegroundColorAttributeName,
            shadow, NSShadowAttributeName,
            parStyle, NSParagraphStyleAttributeName,
            [NSFont boldSystemFontOfSize:fontSize], NSFontAttributeName, nil];

        NSSize stringSize = [aString sizeWithAttributes:attributes];

        while ((stringSize.width>bounds.size.width-20)&&(fontSize>10)) {
            fontSize--;
            [attributes setObject:[NSFont boldSystemFontOfSize:fontSize] forKey:NSFontAttributeName];
            stringSize = [aString sizeWithAttributes:attributes];
        }

        stringRect = NSMakeRect(0, bounds.size.height/2-stringSize.height/2, bounds.size.width, stringSize.height); 

        [aString drawInRect:stringRect withAttributes:attributes];

        // draw description string

        aString = I_description;
        
        parStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
        [parStyle setAlignment:NSLeftTextAlignment];
        
        shadow = [[[NSShadow alloc] init] autorelease];
        [shadow setShadowOffset:NSMakeSize(0.0f, -2.0f)];
        [shadow setShadowBlurRadius:1.5f];
        [shadow setShadowColor:[NSColor blackColor]];

         attributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:
            [NSColor colorWithCalibratedBlack:1 alpha:0.85], NSForegroundColorAttributeName,
            shadow, NSShadowAttributeName,
            parStyle, NSParagraphStyleAttributeName,
            [NSFont boldSystemFontOfSize:11], NSFontAttributeName, nil];

        stringSize = [aString sizeWithAttributes:attributes];

        stringRect = NSMakeRect(15, 7, bounds.size.width, stringSize.height); 

        [aString drawInRect:stringRect withAttributes:attributes];

}

- (void) showCommand:(NSString *)command withDescription:(NSString *)description {
    [I_command autorelease];
    I_command = [command copy];
    [I_description autorelease];
    I_description = [description copy];
    [self setNeedsDisplay:YES];
}

@end


@implementation NSBezierPath(BezelViewBezierPathAdditions)
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

@end
