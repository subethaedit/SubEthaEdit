//
//  NSImageTCMAdditions.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Mon Mar 08 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "NSImageTCMAdditions.h"
#import <Quartz/Quartz.h>

// this file needs arc - either project wide,
// or add -fobjc-arc on a per file basis in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

@implementation NSImage (NSImageTCMAdditions)

+ (NSImage *)pdfBasedImageNamed:(NSString *)aName fillColor:(NSColor *)aFillColor {
	NSImage *result = [NSImage imageNamed:aName];
	if (!result) {
		NSString *pdfName = aName;
		if ([aName hasSuffix:@"Selected"]) {
			pdfName = [aName substringToIndex:aName.length - @"Selected".length];
		}
		NSURL *url = [[NSBundle mainBundle] URLForResource:pdfName withExtension:@"pdf"];
		CGDataProviderRef dataProvider = CGDataProviderCreateWithURL((__bridge CFURLRef)url);
		CGPDFDocumentRef pdfDocument = CGPDFDocumentCreateWithProvider(dataProvider);
		CFRelease(dataProvider);
		
		CGPDFPageRef page1 = CGPDFDocumentGetPage(pdfDocument, 1);
		NSRect boxRect = CGPDFPageGetBoxRect(page1,kCGPDFCropBox);
		
		NSSize imageSize = boxRect.size;
		NSSize scaleFactors = NSMakeSize(0.25, 0.25);
		imageSize.width *= scaleFactors.width;
		imageSize.height *= scaleFactors.height;
		result = [NSImage imageWithSize:imageSize flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
			[[NSColor clearColor] set];
			NSRectFill(dstRect);
			CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
			CGContextScaleCTM(context, scaleFactors.width,
							  scaleFactors.height);
			CGContextTranslateCTM(context, -boxRect.origin.x, -boxRect.origin.y);
			CGContextSetShadow(context, CGSizeMake(0, -2./scaleFactors.width), 4/scaleFactors.width);
			CGContextDrawPDFPage(context, page1);
			return YES;
		}];
		
		result.name = aName;
	}
	return result;
}


+ (NSImage *)clearedImageWithSize:(NSSize)aSize {
    NSImage *image = [[NSImage alloc] initWithSize:aSize];
    [image setCacheMode:NSImageCacheNever];
    [image lockFocus];
    [[NSColor clearColor] set];
    [[NSBezierPath bezierPathWithRect:(NSMakeRect(0.,0.,aSize.width,aSize.height))] fill];
    [image unlockFocus];
    return image;
}

- (NSImage *)resizedImageWithSize:(NSSize)aSize {
    
    NSSize originalSize=[self size];
    NSSize newSize=aSize;
    if (originalSize.width>originalSize.height) {
        newSize.height=(int)(originalSize.height/originalSize.width*newSize.width);
        if (newSize.height<=0) newSize.height=1;
    } else {
        newSize.width=(int)(originalSize.width/originalSize.height*newSize.height);            
        if (newSize.width <=0) newSize.width=1;
    }
    [self setFlipped:NO];
    NSImage *image=[NSImage clearedImageWithSize:newSize];
    [image lockFocus];
    NSGraphicsContext *context=[NSGraphicsContext currentContext];
    NSImageInterpolation oldInterpolation=[context imageInterpolation];
    [context setImageInterpolation:NSImageInterpolationHigh];
    [self      drawInRect:NSMakeRect(0.,0.,newSize.width, newSize.height)
                 fromRect:NSMakeRect(0.,0.,originalSize.width,originalSize.height)
                operation:NSCompositeSourceOver
                 fraction:1.0];
    [context setImageInterpolation:oldInterpolation];
    [image unlockFocus];

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
	NSRect totalRect = NSMakeRect(0.,0.,mysize.width,mysize.height);
    [[NSBezierPath bezierPathWithRect:totalRect] fill];
	[self drawInRect:totalRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:0.5 respectFlipped:YES hints:nil];
	
    [context setImageInterpolation:oldInterpolation];
    [image unlockFocus];
    
    return image;
}


@end
