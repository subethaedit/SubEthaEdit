//
//  GlassButton.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 18.09.06.
//  Copyright 2006 TheCodingMonkeys. All rights reserved.
//

#import "GlassButtonCell.h"

static NSImage *s_pressed[]={nil,nil,nil};
static NSImage *s_normal[]={nil,nil,nil};

@implementation GlassButtonCell

- (BOOL)isBordered {
    return NO;
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    if (s_pressed[0] == nil) {
        s_pressed[0] = [NSImage imageNamed:@"glass-normal-pressed-cap-left"];
        s_pressed[1] = [NSImage imageNamed:@"glass-normal-pressed-fill"];
        s_pressed[2] = [NSImage imageNamed:@"glass-normal-pressed-cap-right"];
        s_normal[0]  = [NSImage imageNamed:@"glass-normal-cap-left"];
        s_normal[1]  = [NSImage imageNamed:@"glass-normal-fill"];
        s_normal[2]  = [NSImage imageNamed:@"glass-normal-cap-right"];
    }
    int i = 0;
    BOOL isFlipped = [controlView isFlipped];
    for (i=0;i<3;i++) {
        [s_pressed[i] setFlipped:isFlipped];
        [s_normal[i]  setFlipped:isFlipped];
    }
    
    NSImage **tiles=([self isHighlighted]?s_pressed:s_normal);

    NSSize beginSize =[tiles[0] size];
    NSSize middleSize=[tiles[1] size];
    NSSize endSize   =[tiles[2] size];
    NSRect bounds=NSInsetRect(cellFrame,5.,2.);;
    NSRect middleRect=bounds;
    middleRect.origin.x   += beginSize.width;
    middleRect.size.width -= beginSize.width+endSize.width;
    NSRect drawRect=NSMakeRect(bounds.origin.x,bounds.origin.y,beginSize.width,beginSize.height);
    [tiles[0] drawInRect:drawRect 
                fromRect:NSMakeRect(0,0,beginSize.width,beginSize.height) 
               operation:NSCompositeSourceOver fraction:1.0];

    drawRect=NSMakeRect(NSMaxX(middleRect),bounds.origin.y,endSize.width,endSize.height);
    [tiles[2] drawInRect:drawRect 
                fromRect:NSMakeRect(0,0,endSize.width,endSize.height) 
               operation:NSCompositeSourceOver fraction:1.0];
               
    drawRect=NSMakeRect(middleRect.origin.x,middleRect.origin.y,middleRect.size.width,middleSize.height);
    [tiles[1] drawInRect:drawRect 
                fromRect:NSMakeRect(0,0,middleSize.width,middleSize.height) 
               operation:NSCompositeSourceOver fraction:1.0];
    [super drawInteriorWithFrame:cellFrame inView:controlView];
}

@end
