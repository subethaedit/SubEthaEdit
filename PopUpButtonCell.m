//
//  PopUpButtonCell.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Tue Apr 20 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "PopUpButtonCell.h"


@implementation PopUpButtonCell

+(NSString *)description {
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
    blah.size.width=cellFrame.size.width-blah.origin.x-6.;
    blah.origin.y=cellFrame.origin.y+1;
    blah.size.height=cellFrame.size.height-1;
    return blah;
}

- (float)titleWidth {
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

- (float)desiredWidth {
    return [self imageWidth]+[self titleWidth]+22.;
}


@end
