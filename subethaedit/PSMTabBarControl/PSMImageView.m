//
//  PSMImageView.m
//  PSMTabBarControl
//
//  Created by Martin Ott on 12/19/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "PSMImageView.h"


@implementation PSMImageView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)dealloc
{
    [_image release];
    [super dealloc];
}

- (BOOL)isOpaque
{
    return NO;
}

- (void)drawRect:(NSRect)rect
{
    [[NSColor clearColor] set];
    [NSBezierPath fillRect:[self frame]];
    [_image compositeToPoint:NSZeroPoint operation:NSCompositeSourceOver];

}

- (NSImage *)image
{
    return _image;
}

- (void)setImage:(NSImage *)image
{
    [image retain];
    [_image release];
    _image = image;
}

@end
