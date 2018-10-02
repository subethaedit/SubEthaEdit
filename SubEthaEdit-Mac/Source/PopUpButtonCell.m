//  PopUpButtonCell.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Tue Apr 20 2004.

#import "PopUpButtonCell.h"


@implementation PopUpButtonCell

+ (NSString *)description {
    return @"PopUpButtonCell";
}

/*
- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    [super drawWithFrame:cellFrame inView:controlView];
}

- (void)drawTitleWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    [super drawTitleWithFrame:cellFrame inView:controlView];
}
*/
- (NSRect)titleRectForBounds:(NSRect)cellFrame {
    NSRect blah=[super titleRectForBounds:cellFrame];
    blah.size.width=cellFrame.size.width-blah.origin.x-13.;
    blah.origin.y=cellFrame.origin.y+2;
    blah.size.height=cellFrame.size.height-1;
    return blah;
}

- (CGFloat)titleWidth {
    NSMenuItem *item=[self selectedItem];
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

- (CGFloat)desiredWidth {
    return [self imageWidth]+[self titleWidth]+30.;
}


@end
