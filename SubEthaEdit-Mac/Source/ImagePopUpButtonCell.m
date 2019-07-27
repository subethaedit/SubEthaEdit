//  ImagePopUpButtonCell.m
//  SubEthaEdit
//
//  Created by Martin Ott on Tue Mar 30 2004.

#import "ImagePopUpButtonCell.h"

// this file needs arc - add -fobjc-arc in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

@implementation ImagePopUpButtonCell

- (void)dealloc {
    [self setImage:nil];
    [self setAlternateImage:nil];
}

- (void)drawBorderAndBackgroundWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    if ([self isHighlighted]) {
        [I_alternateImage drawInRect:cellFrame fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1.0 respectFlipped:YES hints:nil];
    } else {
        [I_image drawInRect:cellFrame fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1.0 respectFlipped:YES hints:nil];
    }
}

- (void)setImage:(NSImage *)anImage {
    I_image = anImage;
}

- (NSImage *)image {
    return I_image;
}

- (void)setAlternateImage:(NSImage *)anImage {
    I_alternateImage = anImage;
}

- (NSImage *)alternateImage {
    return I_alternateImage;
}

@end
