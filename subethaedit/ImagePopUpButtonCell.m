//
//  ImagePopUpButtonCell.m
//  SubEthaEdit
//
//  Created by Martin Ott on Tue Mar 30 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "ImagePopUpButtonCell.h"


@implementation ImagePopUpButtonCell

- (void)dealloc {
    [I_image release];
    [I_alternateImage release];
    [super dealloc];
}

- (void)drawBorderAndBackgroundWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    if ([self isHighlighted]) {
        [I_alternateImage drawAtPoint:cellFrame.origin fromRect:NSMakeRect(0.0, 0.0, [I_alternateImage size].width, [I_alternateImage size].height) operation:NSCompositeSourceOver fraction:1.0];
    } else {
        [I_image drawAtPoint:cellFrame.origin fromRect:NSMakeRect(0.0, 0.0, [I_image size].width, [I_image size].height) operation:NSCompositeSourceOver fraction:1.0];
    }
}

- (void)setImage:(NSImage *)anImage {
    [I_image autorelease];
    I_image = [anImage retain];
    [I_image setFlipped:YES];
}

- (NSImage *)image {
    return I_image;
}

- (void)setAlternateImage:(NSImage *)anImage {
    [I_alternateImage autorelease];
    I_alternateImage = [anImage retain];
    [I_alternateImage setFlipped:YES];
}

- (NSImage *)alternateImage {
    return I_alternateImage;
}

@end
