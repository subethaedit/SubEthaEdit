//  TexturedButtonCell.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Wed May 26 2004.

#import "TexturedButtonCell.h"

// this file needs arc - add -fobjc-arc in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

@implementation TexturedButtonCell

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    NSImage *image = self.textureImage;
    if (image) {
        NSSize imageSize=[image size];
        [image drawInRect:NSMakeRect(cellFrame.origin.x,cellFrame.origin.y,1,cellFrame.size.height) 
               fromRect:NSMakeRect(0,0,1,imageSize.height) 
               operation:NSCompositingOperationSourceOver fraction:1.0 respectFlipped:YES hints:nil];
        [image drawInRect:NSMakeRect(cellFrame.origin.x+1,cellFrame.origin.y,cellFrame.size.width,cellFrame.size.height) 
               fromRect:NSMakeRect(1,0,imageSize.width-2,imageSize.height) 
               operation:NSCompositingOperationSourceOver fraction:1.0 respectFlipped:YES hints:nil];
        [image drawInRect:NSMakeRect(cellFrame.origin.x+cellFrame.size.width-1,cellFrame.origin.y,1,cellFrame.size.height) 
               fromRect:NSMakeRect(imageSize.width-1,0,1,imageSize.height) 
               operation:NSCompositingOperationSourceOver fraction:1.0 respectFlipped:YES hints:nil];
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
