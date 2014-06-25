//
//  GlassButton.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 18.09.06.
//  Copyright 2006 TheCodingMonkeys. All rights reserved.
//

#import "HUDButtonCell.h"
#import "NSBezierPathTCMAdditions.h"

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
    
	BOOL isHighlighted = [self isHighlighted];
    NSImage **tiles=(isHighlighted?s_pressed:s_normal);
	NSRect buttonBounds = cellFrame;
	buttonBounds.size.height = tiles[0].size.height;
	buttonBounds.origin.y += ceil((NSHeight(cellFrame) - NSHeight(buttonBounds)) / 2.0);
	NSDrawThreePartImage(buttonBounds, tiles[0], tiles[1], tiles[2], NO, NSCompositeSourceOver, 1.0, controlView.isFlipped);

	NSMutableAttributedString *title=[[[self attributedTitle] mutableCopy] autorelease];
    [title addAttribute:NSForegroundColorAttributeName value:[NSColor whiteColor] range:NSMakeRange(0,[title length])];
    [self setAttributedTitle:title];
	cellFrame.origin.y += isHighlighted ? 1.0 : 0.0;
    if ([super respondsToSelector:@selector(drawTitle:withFrame:inView:)]) {
        [super drawTitle:title withFrame:[self titleRectForBounds:cellFrame] inView:controlView];
    } else {
        [super drawInteriorWithFrame:cellFrame inView:controlView];
    }
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
