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
#import "NSColorTCMAdditions.h"
#import <objc/objc-runtime.h>
#import <CoreText/CoreText.h>
#import "NSObject+TCMArcLifecycleAdditions.h"

// this file needs arc - either project wide,
// or add -fobjc-arc on a per file basis in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

@implementation NSImage (NSImageTCMAdditions)

const void *TCMImageAdditionsPDFAssociationKey = &TCMImageAdditionsPDFAssociationKey;

+ (BOOL(^)(NSRect))TCM_drawingBlockForMissingUserImageWithSize:(NSSize)aSize initials:(NSString *)anInitialsString {
	//NSLog(@"%s %@",__FUNCTION__,anInitialsString);
	NSRect drawingRect = NSZeroRect;
	drawingRect.size = aSize;
	// draw placeholder image
	NSImage *unknownUserImage = [NSImage imageNamed:NSImageNameUser];
	NSRect imageBounds = NSZeroRect;
	imageBounds.size = unknownUserImage.size;
	NSRect imageSourceRect = NSInsetRect(imageBounds, 2.0, 2.0);

	CGFloat fontSize = floor(NSWidth(drawingRect) / 5.0);
	
	NSShadow *textShadow = [[NSShadow alloc] init];
	textShadow.shadowBlurRadius = 0.0;
	textShadow.shadowColor = [NSColor blackColor];
	textShadow.shadowOffset = NSMakeSize(0.0, -1.0);
	
	NSDictionary *stringAttributes = @{NSFontAttributeName: [NSFont fontWithName:@"HelveticaNeue" size:fontSize],
									   NSForegroundColorAttributeName: [[NSColor whiteColor] colorWithAlphaComponent:0.8],
									   NSShadowAttributeName: textShadow};
	
	NSSize textSize = [anInitialsString sizeWithAttributes:stringAttributes];
	NSRect textBounds = [anInitialsString boundingRectWithSize:textSize options:0 attributes:stringAttributes];

	NSPoint textDrawingCenterPoint = NSMakePoint(NSMidX(drawingRect), floor(NSHeight(drawingRect)/4.0));
	NSRect textDrawingRect = NSMakeRect(floor(textDrawingCenterPoint.x - NSWidth(textBounds) / 2.0),
										floor(textDrawingCenterPoint.y - NSHeight(textBounds) / 2.0),
										NSWidth(textBounds),
										NSHeight(textBounds));
	
	BOOL (^result)(NSRect) = ^(NSRect dstRect){
		
		[[NSColor clearColor] set];
		NSRectFill(dstRect);
		
		[unknownUserImage drawInRect:drawingRect
							fromRect:imageSourceRect
						   operation:NSCompositeSourceOver
							fraction:0.8
					  respectFlipped:YES
							   hints:nil];
		
		// draw initials string
		
		[anInitialsString drawWithRect:textDrawingRect
					   options:0
					attributes:stringAttributes];
		
		return YES;
	};
	return result;
}

+ (NSImage *)unknownUserImageWithSize:(NSSize)aSize initials:(NSString *)anInitialsString {
	NSImage *image = [NSImage imageWithSize:aSize flipped:NO drawingHandler:[self TCM_drawingBlockForMissingUserImageWithSize:aSize initials:anInitialsString]];
	
	return image;
}


+ (NSImage *)highResolutionImageWithSize:(NSSize)inSize usingDrawingBlock:(void (^)(void))drawingBlock
{
	NSImage * resultImage = [[NSImage alloc] initWithSize:inSize];
	if (resultImage)
	{
		// Save external graphic context
		NSGraphicsContext *currentContext = [NSGraphicsContext currentContext];

		// create @1x bitmap representation (72ppi)
		{
			NSBitmapImageRep *lowResBitmapImageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
																							 pixelsWide:inSize.width
																							 pixelsHigh:inSize.height
																						  bitsPerSample:8
																						samplesPerPixel:4
																							   hasAlpha:YES
																							   isPlanar:NO
																						 colorSpaceName:NSCalibratedRGBColorSpace
																						   bitmapFormat:NSAlphaFirstBitmapFormat
																							bytesPerRow:0
																						   bitsPerPixel:0];

			lowResBitmapImageRep = [lowResBitmapImageRep bitmapImageRepByRetaggingWithColorSpace:[NSColorSpace sRGBColorSpace]];

			NSGraphicsContext *lowResBitmapContext = [NSGraphicsContext graphicsContextWithBitmapImageRep:lowResBitmapImageRep];
			[NSGraphicsContext setCurrentContext:lowResBitmapContext];

			drawingBlock(); // your drawing code in points

			[resultImage addRepresentation:lowResBitmapImageRep];
		}

		// create @2x retina bitmap (144ppi)
		{
			NSBitmapImageRep *highResBitmapImageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
																							  pixelsWide:inSize.width * 2.0
																							  pixelsHigh:inSize.height * 2.0
																						   bitsPerSample:8
																						 samplesPerPixel:4
																								hasAlpha:YES
																								isPlanar:NO
																						  colorSpaceName:NSCalibratedRGBColorSpace
																							bitmapFormat:NSAlphaFirstBitmapFormat
																							 bytesPerRow:0
																							bitsPerPixel:0];

			highResBitmapImageRep = [highResBitmapImageRep bitmapImageRepByRetaggingWithColorSpace:[NSColorSpace sRGBColorSpace]];
			[highResBitmapImageRep setSize:inSize]; // this sets the image to be 144ppi

			NSGraphicsContext *highResBitmapContext = [NSGraphicsContext graphicsContextWithBitmapImageRep:highResBitmapImageRep];
			[NSGraphicsContext setCurrentContext:highResBitmapContext];

			drawingBlock(); // your drawing code in points

			[resultImage addRepresentation:highResBitmapImageRep];
		}

		// restore external graphic context
		[NSGraphicsContext setCurrentContext:currentContext];
	}
	return resultImage;
}


+ (NSImage *)pdfBasedImageNamed:(NSString *)aName {
	NSImage *result = [NSImage imageNamed:aName];
	if (!result) {
		NSArray *parts = [aName componentsSeparatedByString:@"_"];
		
		NSInteger pointWidth = [[parts objectAtIndex:1] integerValue];
		
		NSColor *normalColor   = [NSColor darkGrayColor];
		NSColor *selectedColor = [NSColor selectedMenuItemColor];
		NSColor *highlightColor = [NSColor whiteColor];
		
		if (parts.count > 3) {
			normalColor = [NSColor colorForHTMLString:parts[2]];
		}
		if (parts.count > 4) {
			selectedColor = [NSColor colorForHTMLString:parts[3]];
		}
		if (parts.count > 5) {
			highlightColor = [NSColor colorForHTMLString:parts[4]];
		}
		
		NSColor *fillColor = normalColor;
		NSString *pdfName = parts.firstObject;
		NSString *state = parts.lastObject;
		if ([state hasPrefix:TCM_PDFIMAGE_SELECTED]) {
			fillColor = selectedColor;
		} else if ([state hasPrefix:TCM_PDFIMAGE_HIGHLIGHTED]) {
			fillColor = highlightColor;
		}
		BOOL disabled = [state hasSuffix:TCM_PDFIMAGE_DISABLED];
		if (disabled) {
			fillColor = [fillColor blendedColorWithFraction:0.25 ofColor:[NSColor colorWithCalibratedWhite:0.856 alpha:1.000]];
		}

		NSURL *url = [[NSBundle mainBundle] URLForResource:pdfName withExtension:@"pdf"];
		CGDataProviderRef dataProvider = CGDataProviderCreateWithURL((__bridge CFURLRef)url);
		CGPDFDocumentRef pdfDocument = CGPDFDocumentCreateWithProvider(dataProvider);
		CFRelease(dataProvider);
		
		CGPDFPageRef page1 = CGPDFDocumentGetPage(pdfDocument, 1);
		NSRect boxRect = CGPDFPageGetBoxRect(page1,kCGPDFCropBox);
		
		CGRect fullRect = CGRectZero;
		fullRect.size = CGSizeMake(pointWidth, pointWidth);
		fullRect.size.height = round(boxRect.size.height * fullRect.size.width / boxRect.size.width);
		NSSize scaleFactors = NSMakeSize(fullRect.size.width / boxRect.size.width,
										 fullRect.size.height / boxRect.size.height);
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
			CGContextSetFillColorWithColor(layerContext, [fillColor CGColor]);
			CGContextFillRect(layerContext, layerRect);

			CGContextScaleCTM(context, 1/layerScale.width, 1/layerScale.height);
			CGContextSetShadowWithColor(context, CGSizeMake(0, -1.0), 0.5, [[NSColor colorWithCalibratedWhite:0.85 alpha:1.000] CGColor]);
			if (disabled) {
				CGContextSetAlpha(context, 0.9);
			}
			CGContextDrawLayerAtPoint(context, CGPointZero, layer);
			CGLayerRelease(layer);

/*			
			CGContextSetBlendMode(context, kCGBlendModeNormal);
			[[NSColor clearColor] set];
			NSRectFill(dstRect);
			CGContextClipToMask(context, fullRect, maskImage);
			[aFillColor set];
			NSRectFill(dstRect);
*/
			return YES;
		}];

		// need to hold onto the pdf document while image is living
		objc_setAssociatedObject(result, TCMImageAdditionsPDFAssociationKey, CFBridgingRelease(pdfDocument), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
		result.name = aName;
	}
	return result;
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

	NSImage *resultImage = [NSImage imageWithSize:newSize flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
		[[NSColor clearColor] set];
		NSRectFill(dstRect);
		NSGraphicsContext *context = [NSGraphicsContext currentContext];
		[context setImageInterpolation:NSImageInterpolationHigh];
		[self drawInRect:NSMakeRect(0.,0.,newSize.width, newSize.height)
					 fromRect:NSZeroRect
					operation:NSCompositeSourceOver
					 fraction:1.0];
		return YES;
	}];
    return resultImage;
}


- (NSImage *)imageTintedWithColor:(NSColor *)tint invert:(BOOL)aFlag
{
    if (tint != nil) {
    	NSImage *tintedImage = [NSImage imageWithSize:self.size flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
			CIFilter *colorGenerator = [CIFilter filterWithName:@"CIConstantColorGenerator"];
			CIColor *color = [[CIColor alloc] initWithColor:tint];
			[colorGenerator setDefaults];
			[colorGenerator setValue:color forKey:@"inputColor"];

			CIFilter *monochromeFilter = [CIFilter filterWithName:@"CIColorMonochrome"];
			CIImage *baseImage = [CIImage imageWithData:[self TIFFRepresentation]];
			[monochromeFilter setDefaults];
			[monochromeFilter setValue:baseImage forKey:@"inputImage"];
			[monochromeFilter setValue:[CIColor colorWithRed:0.75 green:0.75 blue:0.75] forKey:@"inputColor"];
			[monochromeFilter setValue:[NSNumber numberWithFloat:1.0] forKey:@"inputIntensity"];
			CIImage *monochromeImage = [monochromeFilter valueForKey:@"outputImage"];
			if (aFlag) {
				CIFilter *invertFilter = [CIFilter filterWithName:@"CIColorInvert"];
				[invertFilter setDefaults];
				[invertFilter setValue:[monochromeFilter valueForKey:@"outputImage"] forKey:@"inputImage"];
				monochromeImage = [invertFilter valueForKey:@"outputImage"];
			}

			CIFilter *compositingFilter = [CIFilter filterWithName:@"CIMultiplyCompositing"];
			[compositingFilter setDefaults];
			[compositingFilter setValue:[colorGenerator valueForKey:@"outputImage"] forKey:@"inputImage"];
			[compositingFilter setValue:monochromeImage forKey:@"inputBackgroundImage"];

			CIImage *outputImage = [compositingFilter valueForKey:@"outputImage"];

			[outputImage drawInRect:dstRect fromRect:(NSRect)outputImage.extent operation:NSCompositeCopy fraction:1.0];

			return YES;
		}];

    	return tintedImage;
    } else {
    	return [self copy];
    }
}


- (NSImage *)dimmedImage {

	NSImage *resultImage = [NSImage imageWithSize:self.size flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
		NSGraphicsContext *context = [NSGraphicsContext currentContext];
		[context setImageInterpolation:NSImageInterpolationHigh];
		[[NSColor clearColor] set];
		[[NSBezierPath bezierPathWithRect:dstRect] fill];
		[self drawInRect:dstRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:0.5 respectFlipped:YES hints:nil];
		return YES;
	}];
	return resultImage;
}

+ (BOOL(^)(NSRect))TCM_drawingHandlerWithSize:(NSSize)aSize string:(NSString *)aString color:(NSColor *)aColor fontName:(NSString *)aFontName fontSize:(CGFloat)aFontSize {

	NSGradient *gradient = [[NSGradient alloc] initWithColors:@[[aColor blendedColorWithFraction:0.2 ofColor:[NSColor whiteColor]],[aColor blendedColorWithFraction:0.35 ofColor:[NSColor whiteColor]]]];
	NSRect baseRect = NSZeroRect;
	baseRect.size = aSize;
	CGFloat strokeWidth = ceil(NSWidth(baseRect) / 14.0);
	NSRect roundRect = NSInsetRect(baseRect, strokeWidth/2.0, strokeWidth/2.0);

	NSMutableDictionary *textAttributes = [({
		CTFontRef font = CTFontCreateWithName((__bridge CFStringRef)aFontName, aFontSize, NULL);
		CFTypeRef cgColor = CFRetain([aColor CGColor]);
		NSDictionary *result = @{
								 (id)kCTFontAttributeName : (__bridge id)font,
								 //								 (id)kCTForegroundColorFromContextAttributeName : @(YES),
								 //								 (id)kCTStrokeWidthAttributeName : @(strokeWidth),
								 //(id)kCTStrokeColorAttributeName : (__bridge id)cgColor,
								 (id)kCTForegroundColorAttributeName : (__bridge id)[[NSColor whiteColor] CGColor],
								 //								 (id)kCTLigatureAttributeName : @0,
								 };
		CFRelease(cgColor);
		CFRelease(font);
		result;
	}) mutableCopy];
	
	CFAttributedStringRef attributedString = CFAttributedStringCreate(nil, (__bridge CFStringRef)aString, (__bridge CFDictionaryRef)textAttributes);
	CTLineRef line = CTLineCreateWithAttributedString(attributedString);
	CFRelease(attributedString);
	NSArray *cfStuffToKeepAround = @[CFBridgingRelease(line)];
	
	BOOL(^handler)(NSRect) = ^BOOL(NSRect aRect) {
		BOOL result = YES;
		
		[[NSColor clearColor] set];
		NSRectFill(aRect);
		
		NSBezierPath *roundedRectanglePath = [NSBezierPath bezierPathWithRoundedRect:roundRect xRadius:strokeWidth * 1.5 yRadius:strokeWidth * 1.5];
		[gradient drawInBezierPath:roundedRectanglePath angle:90];
		
		[aColor set];
		[roundedRectanglePath stroke];
		
		CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
		
		[[NSColor whiteColor] setFill];
		CGContextSetLineCap(context, kCGLineCapRound);
		CGContextSetLineJoin(context, kCGLineJoinRound);
		CGContextSetLineWidth(context, 2.0);
		CGRect lineBounds = CTLineGetImageBounds(line, context);

		//		NSFrameRect(lineBounds);
		
		CGPoint textPoint = CGPointMake(CGRectGetMidX(aRect) - CGRectGetWidth(lineBounds)/2.0 - lineBounds.origin.x, CGRectGetMidY(aRect) - CGRectGetHeight(lineBounds)/2.0 - lineBounds.origin.y);
		CGContextSetTextDrawingMode(context, kCGTextStroke);
		CGContextSetTextPosition(context, textPoint.x, textPoint.y);
		CTLineDraw(line, context);
		CGContextSetTextPosition(context, textPoint.x, textPoint.y);
		CGContextSetTextDrawingMode(context, kCGTextFill);
		CTLineDraw(line, context);
		
		return result;
	};
	
	handler = [handler copy]; // make sure it is a non stack object
	[(id)handler TCM_setContextObject:cfStuffToKeepAround]; // attach hour CFValuables
	
	return handler;
}

+ (NSImage *)symbolImageNamed:(NSString *)aName {
	NSString *name = [@"SEESymbol_" stringByAppendingString:aName];
	NSImage *result = [NSImage imageNamed:name];
	if (!result) {
		NSArray *components = [aName componentsSeparatedByString:@"_"];
		NSString *string = components[0];
		NSColor *color = [NSColor colorForHTMLString:@"#2B50E8"];
		if (components.count > 1) {
			color = [NSColor colorForHTMLString:components[1]];
		}
		CGFloat fontSize = 11.0;
		if (components.count > 2) {
			fontSize = [components[2] doubleValue];
		}
		NSString *fontName = @"LucidaGrande";
		//@"LiGothicMed";
		//@"HelveticaNeue-Bold";
		if (components.count > 3) {
			fontName = components[3];
		}
		NSSize size = NSMakeSize(14, 14);
		result = [NSImage imageWithSize:size flipped:NO drawingHandler:[self TCM_drawingHandlerWithSize:size string:string color:color fontName:fontName fontSize:fontSize]];
		[result setName:name];
	}
	return result;
}

@end
