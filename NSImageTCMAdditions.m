//
//  NSImageTCMAdditions.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Mon Mar 08 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "NSImageTCMAdditions.h"


@implementation NSImage (NSImageTCMAdditions)

+ (NSImage *)clearedImageWithSize:(NSSize)aSize {
    NSImage *image=[[[NSImage alloc] initWithSize:aSize] autorelease];
    [image setCacheMode:NSImageCacheNever];
    [image lockFocus];
    [[NSColor clearColor] set];
    [[NSBezierPath bezierPathWithRect:(NSMakeRect(0.,0.,aSize.width,aSize.height))] fill];
    [image unlockFocus];
    return image;
}

- (NSImage *)resizedImageWithSize:(NSSize)aSize {
    
    NSImage *workImage=[self copy];
    
    [workImage setScalesWhenResized:YES];
    NSSize originalSize=[workImage size];
    NSSize newSize=aSize;
    if (originalSize.width>originalSize.height) {
        newSize.height=(int)(originalSize.height/originalSize.width*newSize.width);
        if (newSize.height<=0) newSize.height=1;
    } else {
        newSize.width=(int)(originalSize.width/originalSize.height*newSize.height);            
        if (newSize.width <=0) newSize.width=1;
    }
    [workImage setSize:newSize];
    NSImage *image=[NSImage clearedImageWithSize:newSize];
    [image lockFocus];
    NSGraphicsContext *context=[NSGraphicsContext currentContext];
    NSImageInterpolation oldInterpolation=[context imageInterpolation];
    [context setImageInterpolation:NSImageInterpolationHigh];
    [workImage compositeToPoint:NSMakePoint(0.+(aSize.width-newSize.width )/2.,
                                       0.+(aSize.height-newSize.height)/2.)
                 operation:NSCompositeSourceOver];
    [context setImageInterpolation:oldInterpolation];
    [image unlockFocus];
    
    [workImage release];
    return image;
}

- (NSImage *)dimmedImage {
    
    NSSize mysize=[self size];
    NSImage *image=[[NSImage alloc] initWithSize:mysize];
    [image setCacheMode:NSImageCacheNever];
    [image lockFocus];
    NSGraphicsContext *context=[NSGraphicsContext currentContext];
    NSImageInterpolation oldInterpolation=[context imageInterpolation];
    [context setImageInterpolation:NSImageInterpolationHigh];
    [[NSColor clearColor] set];
    [[NSBezierPath bezierPathWithRect:(NSMakeRect(0.,0.,mysize.width,mysize.height))] fill];
    [self compositeToPoint:NSMakePoint(0.,0.)
                 operation:NSCompositeSourceOver fraction:.5];
    [context setImageInterpolation:oldInterpolation];
    [image unlockFocus];
    
    return [image autorelease];
}


@end
