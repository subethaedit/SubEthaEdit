//  SEEOverlayView.h
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 11.02.14.

// This view updates the cursor to pointer

#import <Cocoa/Cocoa.h>

@interface SEEOverlayView : NSView
@property (nonatomic, getter=isBackgroundBlurActive) BOOL backgroundBlurActive;
@property (nonatomic) CGFloat brightnessAdjustForInactiveWindowState;
@end
