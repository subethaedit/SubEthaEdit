//  ImagePopUpButtonCell.m
//  SubEthaEdit
//
//  Created by Martin Ott on Tue Mar 30 2004.

#import "ImagePopUpButtonCell.h"


@implementation ImagePopUpButtonCell

- (void)dealloc {
    [self setImage:nil];
    [self setAlternateImage:nil];
    [super dealloc];
}

- (void)drawBorderAndBackgroundWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    if ([self isHighlighted]) {
        [I_alternateImage drawInRect:cellFrame fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0 respectFlipped:YES hints:nil];
    } else {
        [I_image drawInRect:cellFrame fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0 respectFlipped:YES hints:nil];
    }
}

- (void)setImage:(NSImage *)anImage {
    [I_image autorelease];
    I_image = [anImage retain];
}

- (NSImage *)image {
    return I_image;
}

- (void)setAlternateImage:(NSImage *)anImage {
    [I_alternateImage autorelease];
    I_alternateImage = [anImage retain];
}

- (NSImage *)alternateImage {
    return I_alternateImage;
}

@end
