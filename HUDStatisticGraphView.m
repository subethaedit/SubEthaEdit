//
//  HUDStatisticGraphView.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 18.09.07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import "HUDStatisticGraphView.h"


@implementation HUDStatisticGraphView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (BOOL)isOpaque {
    return NO;
}

#define LEGENDHEIGHT 27.5
#define XMARKERSPACE 20.
#define YMARKERSPACE 27.5
#define YTOPPADDING   8.
#define DATAPOINTS   100

- (void)drawRect:(NSRect)rect {
    // Drawing code here
    
    NSRect bounds = [self bounds];
    [[[NSColor redColor] colorWithAlphaComponent:0.2] set];
//    [NSBezierPath fillRect:bounds];
//    NSFrameRect(bounds);
    [[NSColor whiteColor] set];
    [NSBezierPath strokeLineFromPoint:NSMakePoint(NSMinX(bounds),NSMinY(bounds)+LEGENDHEIGHT)
                  toPoint:NSMakePoint(NSMaxX(bounds),NSMinY(bounds)+LEGENDHEIGHT)];
    [NSBezierPath strokeLineFromPoint:NSMakePoint(NSMinX(bounds),NSMaxY(bounds))
                  toPoint:NSMakePoint(NSMaxX(bounds),NSMaxY(bounds))];
    
    NSRect graphRect = NSOffsetRect(bounds,YMARKERSPACE,XMARKERSPACE+LEGENDHEIGHT);
    graphRect.size.width -= YMARKERSPACE;
    graphRect.size.height -= XMARKERSPACE+LEGENDHEIGHT+YTOPPADDING;
    [NSBezierPath strokeRect:graphRect];
    [[NSColor colorWithCalibratedRed:69./255. green:80./255. blue:81./255. alpha:0.3] set];
    [NSBezierPath fillRect:graphRect];
    
    NSColor *deletionsColor  = [NSColor deletionsStatisticsColor];
    NSColor *insertionsColor = [NSColor insertionsStatisticsColor];
    NSColor *selectionsColor = [NSColor selectionsStatisticsColor];
    
    NSColor *colors[] = {deletionsColor,insertionsColor,selectionsColor};
    CGPoint sampledPoints[DATAPOINTS*3];
    int i=3;
    while (i--) {
        [colors[i] set];
        float x=NSMinX(graphRect);
        float y=NSMinY(graphRect);
        int count = 0;
        for (;x<NSMaxX(graphRect);x+=NSWidth(graphRect)/DATAPOINTS,count+=2) {
            sampledPoints[count].x=x;
            sampledPoints[count].y=y;
            y+=(random()%20-9.)/2.;
            y = MIN( NSMaxY(graphRect), y);
            y = MAX( y, NSMinY(graphRect)); 
            sampledPoints[count+1].x=x+NSWidth(graphRect)/DATAPOINTS;
            sampledPoints[count+1].y=y;
        }
        CGContextStrokeLineSegments([[NSGraphicsContext currentContext] graphicsPort], sampledPoints, count-2 );
    }
    
}

@end
