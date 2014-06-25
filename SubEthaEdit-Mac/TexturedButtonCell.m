//
//  TexturedButtonCell.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Wed May 26 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "TexturedButtonCell.h"


@implementation TexturedButtonCell

- (void)setTextureImage:(NSImage *)aImage {
    [I_textureImage release];
    I_textureImage=[aImage copy];
}

- (void)dealloc {
    [self setTextureImage:nil];
    [super dealloc];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    NSImage *image=I_textureImage;
    if (image) {
        NSSize imageSize=[image size];
        [image drawInRect:NSMakeRect(cellFrame.origin.x,cellFrame.origin.y,1,cellFrame.size.height) 
               fromRect:NSMakeRect(0,0,1,imageSize.height) 
               operation:NSCompositeSourceOver fraction:1.0 respectFlipped:YES hints:nil];
        [image drawInRect:NSMakeRect(cellFrame.origin.x+1,cellFrame.origin.y,cellFrame.size.width,cellFrame.size.height) 
               fromRect:NSMakeRect(1,0,imageSize.width-2,imageSize.height) 
               operation:NSCompositeSourceOver fraction:1.0 respectFlipped:YES hints:nil];
        [image drawInRect:NSMakeRect(cellFrame.origin.x+cellFrame.size.width-1,cellFrame.origin.y,1,cellFrame.size.height) 
               fromRect:NSMakeRect(imageSize.width-1,0,1,imageSize.height) 
               operation:NSCompositeSourceOver fraction:1.0 respectFlipped:YES hints:nil];
    }
    if ([self isHighlighted]) {
        [[NSColor colorWithDeviceWhite:.2 alpha:.4] set];
        [[NSBezierPath bezierPathWithRect:NSInsetRect(cellFrame,1,2)] fill];
    } else if ([self isEnabled]!=YES) {
        [[NSColor colorWithDeviceWhite:.95 alpha:.35] set];
        [[NSBezierPath bezierPathWithRect:cellFrame] fill];
    }
    [super drawWithFrame:cellFrame inView:controlView];
}

@end
