//
//  AMRollOverButton.h
//  PlateControl
//
//  Created by Andreas on Sat Jan 24 2004.
//  Copyright (c) 2004 Andreas Mayer. All rights reserved.
//
//	2005-06-02	- added shading support
//	2005-07-09	- added -tracksMouseInside and -setTracksMouseInside:
//				  (default is YES for compatibility reasons)


#import <AppKit/AppKit.h>
#import "AMRollOverButtonCell.h"


@interface AMRollOverButton : NSButton {
	NSTrackingRectTag am_trackingRect;
	BOOL am_doesNotTrackMouseInside;
}

- (id)initWithFrame:(NSRect)frameRect andTitle:(NSString *)title;

- (BOOL)tracksMouseInside;
- (void)setTracksMouseInside:(BOOL)flag;
// in case you don't need the roll over effect, set this to NO

// these are convienience methods that invoke the equally named cell methods

- (NSString *)title;
- (IBAction)setTitle:(NSString *)newTitle;

- (NSControlSize)controlSize;
- (void)setControlSize:(NSControlSize)newControlSize;

- (NSColor *)controlColor;
- (void)setControlColor:(NSColor *)newControlColor;

- (NSColor *)shadingColor;
- (void)setShadingColor:(NSColor *)newShadingColor;

- (NSColor *)frameColor;
- (void)setFrameColor:(NSColor *)newFrameColor;

- (NSColor *)textColor;
- (void)setTextColor:(NSColor *)newTextColor;

- (NSColor *)arrowColor;
- (void)setArrowColor:(NSColor *)newArrowColor;

- (NSColor *)mouseoverControlColor;
- (void)setMouseoverControlColor:(NSColor *)newMouseoverControlColor;

- (NSColor *)mouseoverShadingColor;
- (void)setMouseoverShadingColor:(NSColor *)newMouseoverShadingColor;

- (NSColor *)mouseoverFrameColor;
- (void)setMouseoverFrameColor:(NSColor *)newMouseoverFrameColor;

- (NSColor *)mouseoverTextColor;
- (void)setMouseoverTextColor:(NSColor *)newMouseoverTextColor;

- (NSColor *)mouseoverArrowColor;
- (void)setMouseoverArrowColor:(NSColor *)newMouseoverArrowColor;

- (NSColor *)highlightedControlColor;
- (void)setHighlightedControlColor:(NSColor *)newHighlightedControlColor;

- (NSColor *)highlightedShadingColor;
- (void)setHighlightedShadingColor:(NSColor *)newHighlightedShadingColor;

- (NSColor *)highlightedFrameColor;
- (void)setHighlightedFrameColor:(NSColor *)newHighlightedFrameColor;

- (NSColor *)highlightedTextColor;
- (void)setHighlightedTextColor:(NSColor *)newHighlightedTextColor;

- (NSColor *)highlightedArrowColor;
- (void)setHighlightedArrowColor:(NSColor *)newHighlightedArrowColor;

- (NSShadow *)textShadow;
- (void)setTextShadow:(NSShadow *)newTextShadow;

- (NSShadow *)mouseoverTextShadow;
- (void)setMouseoverTextShadow:(NSShadow *)newMouseoverTextShadow;

- (NSShadow *)highlightedTextShadow;
- (void)setHighlightedTextShadow:(NSShadow *)newHighlightedTextShadow;

- (NSShadow *)highlightedControlShadow;
- (void)setHighlightedControlShadow:(NSShadow *)newHighlightedControlShadow;

- (double)popUpMenuDelay;
- (void)setPopUpMenuDelay:(double)newPopUpMenuDelay;

- (AMRollOverButtonShadingMode)shadingMode;
- (void)setShadingMode:(AMRollOverButtonShadingMode)newShadingMode;


@end
