//  SEEOverlayView.h
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 11.02.14.

// This view updtaes the cursor to pointer

#import <Cocoa/Cocoa.h>

@interface SEEOverlayView : NSView
+ (NSArray *)TCM_backgroundBlurFiltersForAdjustedBrightness:(CGFloat)anAdjustmentFactor;
@property (nonatomic, getter=isBackgroundBlurActive) BOOL backgroundBlurActive;
@property (nonatomic) CGFloat brightnessAdjustForInactiveWindowState;
@end
