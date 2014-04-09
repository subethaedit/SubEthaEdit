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

@interface SEEOverlayView ()
@property (strong) NSTrackingArea *cursorTrackingArea;
@end

@implementation SEEOverlayView

/*! also sets the default values */
+ (CIFilter *)TCM_filterWithName:(NSString *)aFilterName settings:(NSDictionary *)aSettingsArray {
	CIFilter *result = [CIFilter filterWithName:aFilterName];
	[result setDefaults];
	[result setValuesForKeysWithDictionary:aSettingsArray];
	return result;
}

/*! nice background blur background filter chain to be used anywhere*/
+ (NSArray *)TCM_backgroundBlurFilters {
	NSArray *result = @[
						[self TCM_filterWithName:@"CIColorControls" settings:@{
																			   kCIInputSaturationKey:@0.9,
																			   kCIInputBrightnessKey:@0.1,
																			   kCIInputContrastKey:@0.7,
																			   }],
						[self TCM_filterWithName:@"CIUnsharpMask" settings:@{
																			 kCIInputRadiusKey:@7.0,
																			 kCIInputIntensityKey:@-1
																			 }],
						];
	
	return result;
}


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
    }
    return self;
}

- (void)dealloc {
    [self removeTrackingArea:self.cursorTrackingArea];
}

- (void)cursorUpdate:(NSEvent *)event {
	[[NSCursor arrowCursor] set];
}

- (void)setBackgroundBlurActive:(BOOL)backgroundBlurActive {
	[self setLayerUsesCoreImageFilters:backgroundBlurActive]; // needed although docu states it isn't
	self.layer.backgroundFilters = backgroundBlurActive ? [SEEOverlayView TCM_backgroundBlurFilters] : nil;
	[self.layer setNeedsDisplay];
}

- (BOOL)isBackgroundBlurActive {
	BOOL result = [self.layer.backgroundFilters count] > 0;
	return result;
}

@end
