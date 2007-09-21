//
//  DWRoundedTransparentView.m
//  Glasnost
//
//  Created by Dominik Wagner on 07.05.05.
//  Copyright 2005 TheCodingMonkeys. All rights reserved.
//

#import "DWRoundedTransparentView.h"

#define TITLEBARHEIGHT 19.0

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
    [(I_titleString?[NSBezierPath bezierPathWithBottomCapOfRoundedRect:bounds radius:radius]:[NSBezierPath bezierPathWithRoundedRect:bounds radius:radius]) fill];

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
