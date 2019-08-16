//  PopUpButtonCell.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Tue Apr 20 2004.

#import "PullDownButtonCell.h"

@implementation PullDownButtonCell

+ (NSString *)description {
    return @"PullDownButtonCell";
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    cellFrame.size.width=MIN([self desiredWidth],cellFrame.size.width);
    [super drawWithFrame:cellFrame inView:controlView];
}
/*
- (void)drawTitleWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    [super drawTitleWithFrame:cellFrame inView:controlView];
}

- (NSRect)drawingRectForBounds:(NSRect)theRect {
    NSRect oldRect=theRect;
    theRect.size.width=[self desiredWidth];
    NSLog(@"drawingRectForBounds:%@ is %@",NSStringFromRect(oldRect),NSStringFromRect(theRect));
    return theRect;
}
*/
- (NSRect)titleRectForBounds:(NSRect)cellFrame {
    NSRect blah=[super titleRectForBounds:cellFrame];
    blah.size.width=cellFrame.size.width-blah.origin.x-6.;
    blah.origin.y=cellFrame.origin.y+1;
    blah.size.height=cellFrame.size.height-1;
    return blah;
}

- (CGFloat)titleWidth {
    NSMenuItem *item=[self itemAtIndex:0];
    NSAttributedString *title=[item attributedTitle];
    float width;
    if (title) {
        width=[title size].width;
    } else {
        width=[[item title]
                    sizeWithAttributes:[NSDictionary dictionaryWithObject:[self font] 
                                                                   forKey:NSFontAttributeName]].width;
    }
    return width;
}


- (float)desiredWidth {
    return [self titleWidth]+22.;
}

@end
