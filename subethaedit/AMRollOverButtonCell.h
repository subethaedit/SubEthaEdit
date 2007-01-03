//
//  AMRollOverButtonCell.h
//  PlateControl
//
//  Created by Andreas on Sat Jan 24 2004.
//  Copyright (c) 2004 Andreas Mayer. All rights reserved.
//
//	2004-08-07	- changed superclass from NSActionCell to NSButtonCell.
//				  not sure if this makes any difference at all though ... :)
//	2005-06-02	- added shading support


#import <AppKit/AppKit.h>

typedef enum {
	am_rollOverButtonShadingNone = 0,
	am_rollOverButtonShadingLinear,
	am_rollOverButtonShadingBilinear
} AMRollOverButtonShadingMode;

@interface AMRollOverButtonCell : NSButtonCell {
	NSColor *am_controlColor;
	NSColor *am_frameColor;
	NSColor *am_textColor;
	NSColor *am_arrowColor;
	NSColor *am_shadingColor;
	NSColor *am_mouseoverControlColor;
	NSColor *am_mouseoverFrameColor;
	NSColor *am_mouseoverTextColor;
	NSColor *am_mouseoverArrowColor;
	NSColor *am_mouseoverShadingColor;
	NSColor *am_highlightedControlColor;
	NSColor *am_highlightedFrameColor;
	NSColor *am_highlightedTextColor;
	NSColor *am_highlightedArrowColor;
	NSColor *am_highlightedShadingColor;
	NSShadow *am_textShadow;
	NSShadow *am_mouseoverTextShadow;
	NSShadow *am_highlightedTextShadow;
	NSShadow *am_highlightedControlShadow;
	AMRollOverButtonShadingMode am_shadingMode;
	double am_popUpMenuDelay;
	BOOL am_showArrow;
	BOOL am_mouseOver;
	// private: basic layout and geometry data
	NSBezierPath *am_backgroundPath;
	NSBezierPath *am_highlightedBackgroundPath;
	NSBezierPath *am_arrowPath;
	NSSize am_lastFrameSize;
	NSRect am_textRect;
	SEL am_getBackgroundSelector;
}

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


// show menu arrow even if mouse is not over control
- (BOOL)showArrow;
- (void)setShowArrow:(BOOL)newShowArrow;

- (BOOL)mouseOver;
- (void)setMouseOver:(BOOL)newMouseOver;

- (float)widthForFrame:(NSRect)frameRect;


@end
