//  RadarScroller.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Mon Feb 17 2003.

#import "RadarScroller.h"


@implementation RadarScroller

+ (BOOL)isCompatibleWithOverlayScrollers {
	BOOL result = (self == [RadarScroller class]);
    return result;
}

- (id)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
	if (self) {
		I_maxHeight=5.;
		I_marks=[NSMutableDictionary new];
	}
    return self;
}

- (void)dealloc {
    [I_marks release];
    [super dealloc];
}

- (void)setMaxHeight:(int)maxHeight {
    if (maxHeight>5.) {
        I_maxHeight=maxHeight;
    } else {
        I_maxHeight=5.;
    }
    [self setNeedsDisplay:YES];
}

- (void)setMarkFor:(NSString *)aIdentifier withColor:(NSColor *)aColor forMinLocation:(float)aMinLocation andMaxLocation:(float)aMaxLocation {
    [I_marks setObject:[NSDictionary dictionaryWithObjectsAndKeys:
                        [aColor colorWithAlphaComponent:0.5],@"Color",
                        [NSNumber numberWithFloat:aMinLocation],@"minLocation",
                        [NSNumber numberWithInt:aMaxLocation],@"maxLocation",nil]
               forKey:aIdentifier];
    [self setNeedsDisplay:YES];
}

- (void)removeMarkFor:(NSString *)aIdentifier {
    [I_marks removeObjectForKey:aIdentifier];
    [self setNeedsDisplay:YES];
}


- (void)drawKnobSlotInRect:(NSRect)aRect highlight:(BOOL)flag {

    [super drawKnobSlotInRect:aRect highlight:flag];

	if ([self usableParts] == NSAllScrollerParts) {
        NSRect scroller = [self rectForPart:NSScrollerKnobSlot];
        NSRect scrollerKnob = [self rectForPart:NSScrollerKnob];
        scrollerKnob.origin.y += 3.5;
        scrollerKnob.size.height -= 7.;

        NSBezierPath *clippingMask = [NSBezierPath bezierPathWithRect:scroller];
        [clippingMask appendBezierPath:[[NSBezierPath bezierPathWithRect:scrollerKnob] bezierPathByReversingPath]];
        [clippingMask addClip];

        scroller.origin.y+=8.5;
        scroller.size.height-=8.5*2;

        NSEnumerator *marks=[I_marks objectEnumerator];
        NSDictionary *mark;
        while ((mark=(NSDictionary*)[marks nextObject])) {
            NSRect markRect=scroller;
            markRect.size.width-=5.;
            markRect.origin.x+=2.5;
            float locationFactor=[[mark objectForKey:@"minLocation"] floatValue]/(float)I_maxHeight;
            markRect.origin.y+=round(locationFactor*markRect.size.height);
            markRect.size.height=round(([[mark objectForKey:@"maxLocation"] floatValue]
                                  -[[mark objectForKey:@"minLocation"] floatValue])
                                 /(float)I_maxHeight*markRect.size.height);  
            if (markRect.size.height<2.) markRect.size.height=2.;

            [((NSColor *)[mark objectForKey:@"Color"]) set];
            NSBezierPath *bezierPath=[NSBezierPath bezierPathWithRect:NSIntersectionRect(scroller,markRect)];
            [bezierPath fill];
            [[[mark objectForKey:@"Color"] shadowWithLevel:0.3] set];
            [bezierPath stroke];
        }
    }
}

@end
