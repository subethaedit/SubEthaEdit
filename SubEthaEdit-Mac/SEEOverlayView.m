//
//  SEEOverlayView.m
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 11.02.14.
//  Copyright (c) 2014 TheCodingMonkeys. All rights reserved.
//

// this file needs arc - either project wide,
// or add -fobjc-arc on a per file basis in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

#import "SEEOverlayView.h"
#import <QuartzCore/QuartzCore.h>

@interface SEECustomBlurFilter : CIFilter
@property (retain, nonatomic) CIImage *inputImage;
@end

@implementation SEECustomBlurFilter
@synthesize inputImage=inputImage;

- (CIImage *) outputImage
{
	CIImage *theInputImage = [self valueForKeyPath:kCIInputImageKey];
//	CIVector *extent = [CIVector vectorWithCGRect:theInputImage.extent];

//	CIFilter *blurFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
//	[blurFilter setDefaults];
//	[blurFilter setValuesForKeysWithDictionary:@{
//												 kCIInputImageKey:theInputImage,
//												 kCIInputRadiusKey:@10.0}];
//	
//	CIFilter *cropFilter = [CIFilter filterWithName:@"CropFilter"];
//	[cropFilter setDefaults];
//	[cropFilter setValue:[blurFilter valueForKey:kCIOutputImageKey] forKey:kCIInputImageKey];
//	[cropFilter setValue:extent forKey:@"inputRectangle"];
	

	CIImage *image = theInputImage;
//	image = ({
//		CIFilter *filter = [CIFilter filterWithName:@"CIBumpDistortion"];
//		[filter setDefaults];
//		[filter setValue:image forKey:kCIInputImageKey];
//		[filter setValue:[CIVector vectorWithCGPoint:image.extent.origin] forKey:@"inputCenter"];
//		
//		[filter valueForKey:kCIOutputImageKey];
//	});

//	image = ({
//		CIFilter *filter = [CIFilter filterWithName:@"CIBumpDistortion"];
//		[filter setDefaults];
//		[filter setValue:image forKey:kCIInputImageKey];
//		[filter setValue:[CIVector vectorWithCGPoint:image.extent.origin] forKey:@"inputCenter"];
//		
//		[filter valueForKey:kCIOutputImageKey];
//	});

	image = ({
		CIFilter *filter = [CIFilter filterWithName:@"CIUnsharpMask"];
		[filter setDefaults];
		[filter setValue:image forKey:kCIInputImageKey];
		[filter setValue:@10.0 forKey:kCIInputRadiusKey];
		[filter setValue:@-0.9 forKey:kCIInputIntensityKey];
		[filter valueForKey:kCIOutputImageKey];
	});

	
	
	CIImage *result = image;
	
	//	NSLog(@"%s inputExtent:%@ outputExtent:%@",__FUNCTION__,NSStringFromRect(theInputImage.extent), NSStringFromRect(result.extent));
	return result;
}
@end


@interface SEEOverlayView ()
@property (strong) NSTrackingArea *cursorTrackingArea;
@end

@implementation SEEOverlayView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		[self setWantsLayer:YES];
		self.layer.masksToBounds = YES;
		NSTrackingArea *trackingArea = [[NSTrackingArea alloc] initWithRect:NSZeroRect
																	options:NSTrackingCursorUpdate|NSTrackingInVisibleRect|NSTrackingActiveInKeyWindow
																	  owner:self userInfo:nil];
		[self addTrackingArea:trackingArea];
		self.cursorTrackingArea = trackingArea;
		//		[self setPostsFrameChangedNotifications:YES];
		//[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(TCM_boundsDidChange:) name:NSViewFrameDidChangeNotification object:self];
    }
    return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewBoundsDidChangeNotification object:self];
    [self removeTrackingArea:self.cursorTrackingArea];
}

- (void)cursorUpdate:(NSEvent *)event {
	[[NSCursor arrowCursor] set];
}

- (CIFilter *)TCM_filterWithName:(NSString *)aFilterName settings:(NSDictionary *)aSettingsArray {
	CIFilter *result = [CIFilter filterWithName:aFilterName];
	[result setDefaults];
	[result setValuesForKeysWithDictionary:aSettingsArray];
	return result;
}

- (NSArray *)TCM_backgroundBlurFilters {
	NSArray *result = @[
//						[self TCM_filterWithName:@"CILanczosScaleTransform" settings:@{
//																			   kCIInputScaleKey:@0.7,
//																			   }],
//						[CIFilter filterWithName:@"CIAffineClamp" keysAndValues:
//						 kCIInputTransformKey, [NSValue valueWithCATransform3D:CATransform3DIdentity],
//						 nil],
						[self TCM_filterWithName:@"CIColorControls" settings:@{
							kCIInputSaturationKey:@0.9,
							kCIInputBrightnessKey:@0.1,
							kCIInputContrastKey:@0.7,
						 }],
						[self TCM_filterWithName:@"CIUnsharpMask" settings:@{
							kCIInputRadiusKey:@7.0,
							kCIInputIntensityKey:@-1
						 }],
//						[self TCM_filterWithName:@"CIGaussianBlur" settings:@{
//							kCIInputRadiusKey:@10.0,
//						 }],
						];
	
	return result;
}

- (void)setBackgroundBlurActive:(BOOL)backgroundBlurActive {
	self.layer.backgroundFilters = backgroundBlurActive ? [self TCM_backgroundBlurFilters] : nil;
	[self.layer setNeedsDisplay];
}

- (BOOL)isBackgroundBlurActive {
	BOOL result = [self.layer.backgroundFilters count] > 0;
	return result;
}

- (void)TCM_boundsDidChange:(NSNotification *)aNotification {
	if (self.isBackgroundBlurActive) {
		self.layer.backgroundFilters = [self TCM_backgroundBlurFilters];
		[self.layer setNeedsDisplay];
	}
}



@end
