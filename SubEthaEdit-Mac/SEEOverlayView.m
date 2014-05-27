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
+ (NSArray *)TCM_backgroundBlurFiltersForAdjustedBrightness:(CGFloat)anAdjustmentFactor {
	NSArray *result = @[
						[self TCM_filterWithName:@"CIColorControls" settings:@{
																			   kCIInputSaturationKey:@(0.9 - anAdjustmentFactor),
																			   kCIInputBrightnessKey:@(0.1 + anAdjustmentFactor),
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

		NSTrackingAreaOptions options = NSTrackingCursorUpdate | NSTrackingInVisibleRect | NSTrackingActiveInKeyWindow;

		NSPoint mouseLocationInBounds = [self convertPoint:[[self window] convertScreenToBase:[NSEvent mouseLocation]] fromView:nil];
		BOOL mouseIsInside = NSMouseInRect(mouseLocationInBounds, self.bounds, self.isFlipped);
		if (mouseIsInside) {
			options |= NSTrackingAssumeInside;
		}

		NSTrackingArea *trackingArea = [[NSTrackingArea alloc] initWithRect:NSZeroRect
																	options:options
																	  owner:self
																   userInfo:nil];

		[self addTrackingArea:trackingArea];
		self.cursorTrackingArea = trackingArea;
    }
    return self;
}

- (void)dealloc {
	[self setBrightnessAdjustForInactiveWindowState:0.0]; // deregister from notification
    [self removeTrackingArea:self.cursorTrackingArea];
}

- (void)cursorUpdate:(NSEvent *)event {
	[[NSCursor arrowCursor] set];
}

- (void)setBrightnessAdjustForInactiveWindowState:(CGFloat)brightnessAdjustForInactiveWindowState {
	NSArray *notificationNames = @[NSApplicationDidBecomeActiveNotification, NSApplicationDidResignActiveNotification, NSWindowDidBecomeMainNotification];
	for (NSString *name in notificationNames) {
		[[NSNotificationCenter defaultCenter] removeObserver:self name:name object:nil];
	}
	_brightnessAdjustForInactiveWindowState = brightnessAdjustForInactiveWindowState;
	if (_brightnessAdjustForInactiveWindowState != 0.0) {
		for (NSString *name in notificationNames) {
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeActivenessNotification:) name:name object:nil];
		}
	}
}

- (void)changeActivenessNotification:(NSNotification *)aNotification {
	[self setBackgroundBlurActive:self.isBackgroundBlurActive]; // update the filter chain
}

- (void)setBackgroundBlurActive:(BOOL)backgroundBlurActive {
	BOOL windowIsActive = self.window.isMainWindow && [NSApp isActive];
	self.backgroundFilters = backgroundBlurActive ? [SEEOverlayView TCM_backgroundBlurFiltersForAdjustedBrightness:windowIsActive ? 0.0 : self.brightnessAdjustForInactiveWindowState] : nil;
	[self.layer setNeedsDisplay];
}

- (BOOL)isBackgroundBlurActive {
	BOOL result = [self.layer.backgroundFilters count] > 0;
	return result;
}

@end
