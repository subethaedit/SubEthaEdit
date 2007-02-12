//
//  GlassButton.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 18.09.06.
//  Copyright 2006 TheCodingMonkeys. All rights reserved.
//

#import "HUDButtonCell.h"
#import "DWRoundedTransparentView.h"

static NSImage *s_pressed[]={nil,nil,nil};
static NSImage *s_normal[]={nil,nil,nil};

@implementation HUDButtonCell

- (BOOL)isBordered {
    return NO;
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    if (s_pressed[0] == nil) {
        s_pressed[0] = [NSImage imageNamed:@"hud_buttonLeft-P" ];
        s_pressed[1] = [NSImage imageNamed:@"hud_buttonFill-P" ];
        s_pressed[2] = [NSImage imageNamed:@"hud_buttonRight-P"];
        s_normal[0]  = [NSImage imageNamed:@"hud_buttonLeft-N" ];
        s_normal[1]  = [NSImage imageNamed:@"hud_buttonFill-N" ];
        s_normal[2]  = [NSImage imageNamed:@"hud_buttonRight-N"];
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
    NSRect bounds=cellFrame;
    bounds.origin.y += (int)(bounds.size.height - middleSize.height)/2;
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

    NSMutableAttributedString *title=[[[self attributedTitle] mutableCopy] autorelease];
    [title addAttribute:NSForegroundColorAttributeName value:[NSColor whiteColor] range:NSMakeRange(0,[title length])];
    [self setAttributedTitle:title];
    [super drawInteriorWithFrame:cellFrame inView:controlView];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    [self drawInteriorWithFrame:cellFrame inView:controlView];
    [[NSColor keyboardFocusIndicatorColor] set];
    if ([self showsFirstResponder]) {     
         // showsFirstResponder is set for us by the NSControl that is drawing  us.  
        NSRect focusRingFrame = cellFrame;
        focusRingFrame.size.height -= 2.0; 
        [NSGraphicsContext saveGraphicsState];
        NSSetFocusRingStyle(NSFocusRingOnly);
        NSBezierPath *bezierPath=[NSBezierPath bezierPathWithRoundedRect:NSInsetRect(focusRingFrame,0,4) radius:(focusRingFrame.size.height-4)/2.];
        [bezierPath fill];
        [NSGraphicsContext restoreGraphicsState];
    }
}



@end
