//
//  NSImageTCMAdditions.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Mon Mar 08 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "NSImageTCMAdditions.h"
#import <Quartz/Quartz.h>
#import <CoreGraphics/CoreGraphics.h>

// this file needs arc - either project wide,
// or add -fobjc-arc on a per file basis in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

@implementation NSImage (NSImageTCMAdditions)

+ (NSImage *)pdfBasedImageNamed:(NSString *)aName fillColor:(NSColor *)aFillColor scaleFactor:(CGFloat)aScaleFactor {
	NSImage *result = [NSImage imageNamed:aName];
	if (!result) {
		NSArray *parts = [aName componentsSeparatedByString:@"_"];
		NSString *pdfName = parts.firstObject;
		NSString *state = parts.lastObject;
		if ([state hasPrefix:@"Selected"]) {
			aFillColor = [NSColor selectedMenuItemColor];
		}
		BOOL disabled = [state hasSuffix:@"Disabled"];
		NSURL *url = [[NSBundle mainBundle] URLForResource:pdfName withExtension:@"pdf"];
		CGDataProviderRef dataProvider = CGDataProviderCreateWithURL((__bridge CFURLRef)url);
		CGPDFDocumentRef pdfDocument = CGPDFDocumentCreateWithProvider(dataProvider);
		CFRelease(dataProvider);
		
		CGPDFPageRef page1 = CGPDFDocumentGetPage(pdfDocument, 1);
		NSRect boxRect = CGPDFPageGetBoxRect(page1,kCGPDFCropBox);
		
		CGRect fullRect = CGRectZero;
		fullRect.size = boxRect.size;
		NSSize scaleFactors = NSMakeSize(aScaleFactor, aScaleFactor);
		fullRect.size.width *= scaleFactors.width;
		fullRect.size.height *= scaleFactors.height;
		fullRect = NSIntegralRect(fullRect); // only ganze pixel sind gute pixel
		result = [NSImage imageWithSize:fullRect.size flipped:NO drawingHandler:^BOOL(NSRect dstRect) {

			[[NSColor clearColor] set];
			NSRectFill(dstRect);
			
			CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
			
			CGSize layerScale = CGSizeMake(CGBitmapContextGetWidth(context) / fullRect.size.width,
										   CGBitmapContextGetHeight(context) / fullRect.size.height);
			
			CGRect layerRect = CGRectMake(0, 0, fullRect.size.width * layerScale.width, fullRect.size.height * layerScale.height);
			CGLayerRef layer = CGLayerCreateWithContext(context, layerRect.size, nil);
			CGContextRef layerContext = CGLayerGetContext(layer);
			CGContextSaveGState(layerContext);
			CGContextScaleCTM(layerContext, scaleFactors.width * layerScale.width,
							  scaleFactors.height * layerScale.height);
			CGContextTranslateCTM(layerContext, -boxRect.origin.x, -boxRect.origin.y);
			CGContextDrawPDFPage(layerContext, page1);
			CGContextRestoreGState(layerContext);
			
			CGContextSetBlendMode(layerContext, kCGBlendModeSourceIn);
			CGContextSetFillColorWithColor(layerContext, [aFillColor CGColor]);
			CGContextFillRect(layerContext, layerRect);

			
			CGContextSetShadow(context, CGSizeMake(0, -1.), 3.);
			CGContextScaleCTM(context, 1/layerScale.width, 1/layerScale.height);
			if (disabled) {
				CGContextSetAlpha(context, 0.6);
			}
			CGContextDrawLayerAtPoint(context, CGPointZero, layer);
/*			CGContextSetBlendMode(context, kCGBlendModeNormal);
			[[NSColor clearColor] set];
			NSRectFill(dstRect);
			CGContextClipToMask(context, fullRect, maskImage);
			[aFillColor set];
			NSRectFill(dstRect);
*/
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
