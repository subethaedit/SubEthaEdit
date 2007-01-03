//
//  AMRollOverButtonCell.m
//  PlateControl
//
//  Created by Andreas on Sat Jan 24 2004.
//  Copyright (c) 2004 Andreas Mayer. All rights reserved.
//
//	2004-02-01	- cleaned up layout code
//				- open menu instantly when user clicks on arrow
//	2004-03-15	- Don McConnel sent me a better formula for calculating
//				  the textInset which doesn't need trigonometric functions,
//				  so we don't need to include the libmx.dylib - thanks Don!
//	2004-07-08	- set textShadow to an empty NSShadow object instead
//				  of nil
//	2005-05-30	- hack to account for System Font xHeight change in 10.4:
//				  hard coded system font sizes
//	2005-06-02	- added shading support
//	2005-06-03	- modified calculation for text position to center on capHeight;
//				  (we keep the previous xHeight hack for calculating the horizontal inset)
//	2005-06-24	- honors the font set through -setFont:; will still adjust the font size
//				  when changing the control size
//	2005-07-11	- modified text positioning code again
//				- added second bezel style:
//				  NSShadowlessSquareBezelStyle will result in a button the shape of a
//				  rounded rectangle instead of the usual pill shape


//#import <Carbon/Carbon.h>
#import "AMRollOverButtonCell.h"
#import "NSBezierPath_AMAdditons.h"
#import "NSBezierPath_AMShading.h"
#import </usr/include/math.h>

static float am_backgroundInset = 1.5;
static float am_textInsetFactor = 1.3;
static float am_roundedRectCornerRadius = 4.3;
static float am_bezierPathFlatness = 0.2;


@interface NSFont (AMRollOverButton)
- (float)fixed_xHeight;
- (float)fixed_capHeight;
@end

@implementation NSFont (AMRollOverButton)

- (float)fixed_xHeight
{
	float result = [self xHeight];
	if ([[self familyName] isEqualToString:[[NSFont systemFontOfSize:[NSFont systemFontSize]] familyName]]) {
		switch (lrintf([self pointSize])) {
			case 9: // mini
			{
				result = 5.655762;
				break;
			}
			case 11: // small
			{
				result = 6.912598;
				break;
			}
			case 13: // regular
			{
				result = 8.169434;
				break;
			}
		}
	}
	return result;
}

- (float)fixed_capHeight
{
	float result = [self capHeight];
	if (result == [self ascender]) { // instead of checking for appkit version
		if ([[self familyName] isEqualToString:[[NSFont systemFontOfSize:[NSFont systemFontSize]] familyName]]) { // we do have this info for the system font only 
			switch (lrintf([self pointSize])) {
				case 9: // mini
				{
					result = 7.00;
					break;
				}
				case 11: // small
				{
					result = 8.00;
					break;
				}
				case 13: // regular
				{
					result = 9.50;
					break;
				}
			}
		}
	}
	return result;
}

@end

@interface NSShadow (AMRollOverButton)
+ (NSShadow *)amRollOverButtonDefaultControlShadow;
+ (NSShadow *)amRollOverButtonDefaultTextShadow;
@end

@implementation NSShadow (AMRollOverButton)

+ (NSShadow *)amRollOverButtonDefaultControlShadow
{
	NSShadow *result = [[[NSShadow alloc] init] autorelease];
	[result setShadowOffset:NSMakeSize(0.0, 1.0)];
	[result setShadowBlurRadius:1.0];
	[result setShadowColor:[NSColor controlDarkShadowColor]];
	return result;
}

+ (NSShadow *)amRollOverButtonDefaultTextShadow
{
	NSShadow *result = [[[NSShadow alloc] init] autorelease];
	[result setShadowOffset:NSMakeSize(0.0, -1.0)];
	[result setShadowBlurRadius:1.0];
	[result setShadowColor:[NSColor colorWithCalibratedWhite:0.3 alpha:1.0]];
	return result;
}

@end

@interface NSBezierPath (AMRollOverButton)
+ (NSBezierPath *)bezierPathForButtonWithRoundedRect:(NSRect)rect;
@end

@implementation NSBezierPath (AMRollOverButton)

+ (NSBezierPath *)bezierPathForButtonWithRoundedRect:(NSRect)rect
{
	return [NSBezierPath bezierPathWithRoundedRect:rect cornerRadius:am_roundedRectCornerRadius];
}

@end

@interface AMRollOverButtonCell (Private)
- (NSSize)lastFrameSize;
- (void)setLastFrameSize:(NSSize)newLastFrameSize;
- (float)calculateTextInsetForRadius:(float)radius font:(NSFont *)font;
- (void)finishInit;
@end


@implementation AMRollOverButtonCell

- (id)initTextCell:(NSString *)aString
{
	if (self = [super initTextCell:aString]) {
		[self finishInit];
	}
	return self;
}

- (void)finishInit
{
	[self setControlColor:[NSColor clearColor]];
	[self setFrameColor:[NSColor clearColor]];
	[self setTextColor:[NSColor colorWithCalibratedWhite:0.25 alpha:1.0]];
	[self setArrowColor:[NSColor colorWithCalibratedWhite:0.25 alpha:1.0]];
	[self setShadingColor:nil];
	[self setMouseoverControlColor:[NSColor colorWithCalibratedWhite:0.6 alpha:1.0]];
	[self setMouseoverFrameColor:[NSColor clearColor]];
	[self setMouseoverTextColor:[NSColor whiteColor]];
	[self setMouseoverArrowColor:[NSColor whiteColor]];
	[self setMouseoverShadingColor:nil];
	[self setHighlightedControlColor:[NSColor colorWithCalibratedWhite:0.5 alpha:1.0]];
	[self setHighlightedFrameColor:[NSColor clearColor]];
	[self setHighlightedTextColor:[NSColor whiteColor]];
	[self setHighlightedArrowColor:[NSColor whiteColor]];
	[self setHighlightedShadingColor:nil];
	[self setTextShadow:[[[NSShadow alloc] init] autorelease]];
	[self setMouseoverTextShadow:[NSShadow amRollOverButtonDefaultTextShadow]];
	[self setHighlightedTextShadow:[self mouseoverTextShadow]];
	[self setHighlightedControlShadow:[NSShadow amRollOverButtonDefaultControlShadow]];
	[self setPopUpMenuDelay:0.6];
	[self setBezelStyle:NSRoundedBezelStyle];
}

- (id)initWithCoder:(NSCoder *)decoder
{
	self = [super initWithCoder:decoder];
	[self setControlColor:[decoder decodeObject]];
	[self setFrameColor:[decoder decodeObject]];
	[self setTextColor:[decoder decodeObject]];
	[self setArrowColor:[decoder decodeObject]];
	[self setMouseoverControlColor:[decoder decodeObject]];
	[self setMouseoverFrameColor:[decoder decodeObject]];
	[self setMouseoverTextColor:[decoder decodeObject]];
	[self setMouseoverArrowColor:[decoder decodeObject]];
	[self setHighlightedControlColor:[decoder decodeObject]];
	[self setHighlightedFrameColor:[decoder decodeObject]];
	[self setHighlightedTextColor:[decoder decodeObject]];
	[self setHighlightedArrowColor:[decoder decodeObject]];
	[self setTextShadow:[decoder decodeObject]];
	[self setMouseoverTextShadow:[decoder decodeObject]];
	[self setHighlightedTextShadow:[decoder decodeObject]];
	[self setHighlightedControlShadow:[decoder decodeObject]];
	[decoder decodeValueOfObjCType:@encode(double) at:&am_popUpMenuDelay];
	[self setShadingColor:[decoder decodeObject]];
	[self setMouseoverShadingColor:[decoder decodeObject]];
	[self setHighlightedShadingColor:[decoder decodeObject]];
	[decoder decodeValueOfObjCType:@encode(int) at:&am_shadingMode];
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	[super encodeWithCoder:coder];
	[coder encodeObject:am_controlColor];
	[coder encodeObject:am_frameColor];
	[coder encodeObject:am_textColor];
	[coder encodeObject:am_arrowColor];
	[coder encodeObject:am_mouseoverControlColor];
	[coder encodeObject:am_mouseoverFrameColor];
	[coder encodeObject:am_mouseoverTextColor];
	[coder encodeObject:am_mouseoverArrowColor];
	[coder encodeObject:am_highlightedControlColor];
	[coder encodeObject:am_highlightedFrameColor];
	[coder encodeObject:am_highlightedTextColor];
	[coder encodeObject:am_highlightedArrowColor];
	[coder encodeObject:am_textShadow];
	[coder encodeObject:am_mouseoverTextShadow];
	[coder encodeObject:am_highlightedTextShadow];
	[coder encodeObject:am_highlightedControlShadow];
	[coder encodeValueOfObjCType:@encode(double) at:&am_popUpMenuDelay];
	[coder encodeObject:am_shadingColor];
	[coder encodeObject:am_mouseoverShadingColor];
	[coder encodeObject:am_highlightedShadingColor];
	[coder encodeValueOfObjCType:@encode(int) at:&am_shadingMode];
}

- (void)dealloc
{
	[am_arrowPath release];
	[am_controlColor release];
	[am_shadingColor release];
	[am_frameColor release];
	[am_textColor release];
	[am_arrowColor release];
	[am_mouseoverControlColor release];
	[am_mouseoverShadingColor release];
	[am_mouseoverFrameColor release];
	[am_mouseoverTextColor release];
	[am_mouseoverArrowColor release];
	[am_highlightedControlColor release];
	[am_highlightedShadingColor release];
	[am_highlightedFrameColor release];
	[am_highlightedTextColor release];
	[am_highlightedArrowColor release];
	[am_textShadow release];
	[am_mouseoverTextShadow release];
	[am_highlightedTextShadow release];
	[am_highlightedControlShadow release];
	[am_backgroundPath release];
	[am_highlightedBackgroundPath release];
	[super dealloc];
}

- (void)setMenu:(NSMenu *)menu
{
	[super setMenu:menu];
	am_lastFrameSize.width = 0.0;
}

- (NSColor *)controlColor
{
    return am_controlColor;
}

- (void)setControlColor:(NSColor *)newControlColor
{
    id old = nil;

    if (newControlColor != am_controlColor) {
        old = am_controlColor;
        am_controlColor = [newControlColor retain];
        [old release];
    }
}

- (NSColor *)frameColor
{
    return am_frameColor;
}

- (void)setFrameColor:(NSColor *)newFrameColor
{
    id old = nil;

    if (newFrameColor != am_frameColor) {
        old = am_frameColor;
        am_frameColor = [newFrameColor retain];
        [old release];
    }
}

- (NSColor *)textColor
{
    return am_textColor;
}

- (void)setTextColor:(NSColor *)newTextColor
{
    id old = nil;

    if (newTextColor != am_textColor) {
        old = am_textColor;
        am_textColor = [newTextColor retain];
        [old release];
    }
}

- (NSColor *)arrowColor
{
    return am_arrowColor;
}

- (void)setArrowColor:(NSColor *)newArrowColor
{
    id old = nil;

    if (newArrowColor != am_arrowColor) {
        old = am_arrowColor;
        am_arrowColor = [newArrowColor retain];
        [old release];
    }
}

- (NSColor *)shadingColor
{
	return am_shadingColor;
}

- (void)setShadingColor:(NSColor *)newShadingColor
{
	id old = nil;
	
	if (newShadingColor != am_shadingColor) {
		old = am_shadingColor;
		am_shadingColor = [newShadingColor retain];
		[old release];
	}
}


- (NSColor *)mouseoverControlColor
{
    return am_mouseoverControlColor;
}

- (void)setMouseoverControlColor:(NSColor *)newMouseoverControlColor
{
    id old = nil;

    if (newMouseoverControlColor != am_mouseoverControlColor) {
        old = am_mouseoverControlColor;
        am_mouseoverControlColor = [newMouseoverControlColor retain];
        [old release];
    }
}

- (NSColor *)mouseoverFrameColor
{
    return am_mouseoverFrameColor;
}

- (void)setMouseoverFrameColor:(NSColor *)newMouseoverFrameColor
{
    id old = nil;

    if (newMouseoverFrameColor != am_mouseoverFrameColor) {
        old = am_mouseoverFrameColor;
        am_mouseoverFrameColor = [newMouseoverFrameColor retain];
        [old release];
    }
}

- (NSColor *)mouseoverTextColor
{
    return am_mouseoverTextColor;
}

- (void)setMouseoverTextColor:(NSColor *)newMouseoverTextColor
{
    id old = nil;

    if (newMouseoverTextColor != am_mouseoverTextColor) {
        old = am_mouseoverTextColor;
        am_mouseoverTextColor = [newMouseoverTextColor retain];
        [old release];
    }
}

- (NSColor *)mouseoverArrowColor
{
    return am_mouseoverArrowColor;
}

- (void)setMouseoverArrowColor:(NSColor *)newMouseoverArrowColor
{
    id old = nil;

    if (newMouseoverArrowColor != am_mouseoverArrowColor) {
        old = am_mouseoverArrowColor;
        am_mouseoverArrowColor = [newMouseoverArrowColor retain];
        [old release];
    }
}

- (NSColor *)mouseoverShadingColor
{
	return am_mouseoverShadingColor;
}

- (void)setMouseoverShadingColor:(NSColor *)newMouseoverShadingColor
{
	id old = nil;
	
	if (newMouseoverShadingColor != am_mouseoverShadingColor) {
		old = am_mouseoverShadingColor;
		am_mouseoverShadingColor = [newMouseoverShadingColor retain];
		[old release];
	}
}


- (NSColor *)highlightedControlColor
{
    return am_highlightedControlColor;
}

- (void)setHighlightedControlColor:(NSColor *)newHighlightedControlColor
{
    id old = nil;

    if (newHighlightedControlColor != am_highlightedControlColor) {
        old = am_highlightedControlColor;
        am_highlightedControlColor = [newHighlightedControlColor retain];
        [old release];
    }
}

- (NSColor *)highlightedFrameColor
{
    return am_highlightedFrameColor;
}

- (void)setHighlightedFrameColor:(NSColor *)newHighlightedFrameColor
{
    id old = nil;

    if (newHighlightedFrameColor != am_highlightedFrameColor) {
        old = am_highlightedFrameColor;
        am_highlightedFrameColor = [newHighlightedFrameColor retain];
        [old release];
    }
}

- (NSColor *)highlightedTextColor
{
    return am_highlightedTextColor;
}

- (void)setHighlightedTextColor:(NSColor *)newHighlightedTextColor
{
    id old = nil;

    if (newHighlightedTextColor != am_highlightedTextColor) {
        old = am_highlightedTextColor;
        am_highlightedTextColor = [newHighlightedTextColor retain];
        [old release];
    }
}

- (NSColor *)highlightedArrowColor
{
    return am_highlightedArrowColor;
}

- (void)setHighlightedArrowColor:(NSColor *)newHighlightedArrowColor
{
    id old = nil;

    if (newHighlightedArrowColor != am_highlightedArrowColor) {
        old = am_highlightedArrowColor;
        am_highlightedArrowColor = [newHighlightedArrowColor retain];
        [old release];
    }
}

- (NSColor *)highlightedShadingColor
{
	return am_highlightedShadingColor;
}

- (void)setHighlightedShadingColor:(NSColor *)newHighlightedShadingColor
{
	id old = nil;
	
	if (newHighlightedShadingColor != am_highlightedShadingColor) {
		old = am_highlightedShadingColor;
		am_highlightedShadingColor = [newHighlightedShadingColor retain];
		[old release];
	}
}


- (NSShadow *)textShadow
{
    return am_textShadow;
}

- (void)setTextShadow:(NSShadow *)newTextShadow
{
    id old = nil;

    if (newTextShadow != am_textShadow) {
        old = am_textShadow;
        am_textShadow = [newTextShadow retain];
        [old release];
    }
}

- (NSShadow *)mouseoverTextShadow
{
    return am_mouseoverTextShadow;
}

- (void)setMouseoverTextShadow:(NSShadow *)newMouseoverTextShadow
{
    id old = nil;

    if (newMouseoverTextShadow != am_mouseoverTextShadow) {
        old = am_mouseoverTextShadow;
        am_mouseoverTextShadow = [newMouseoverTextShadow retain];
        [old release];
    }
}

- (NSShadow *)highlightedTextShadow
{
    return am_highlightedTextShadow;
}

- (void)setHighlightedTextShadow:(NSShadow *)newHighlightedTextShadow
{
    id old = nil;

    if (newHighlightedTextShadow != am_highlightedTextShadow) {
        old = am_highlightedTextShadow;
        am_highlightedTextShadow = [newHighlightedTextShadow retain];
        [old release];
    }
}

- (NSShadow *)highlightedControlShadow
{
    return am_highlightedControlShadow;
}

- (void)setHighlightedControlShadow:(NSShadow *)newHighlightedControlShadow
{
    id old = nil;

    if (newHighlightedControlShadow != am_highlightedControlShadow) {
        old = am_highlightedControlShadow;
        am_highlightedControlShadow = [newHighlightedControlShadow retain];
        [old release];
    }
}

- (double)popUpMenuDelay
{
    return am_popUpMenuDelay;
}

- (void)setPopUpMenuDelay:(double)newPopUpMenuDelay
{
    am_popUpMenuDelay = newPopUpMenuDelay;
}

- (AMRollOverButtonShadingMode)shadingMode
{
	return am_shadingMode;
}

- (void)setShadingMode:(AMRollOverButtonShadingMode)newShadingMode
{
	am_shadingMode = newShadingMode;
}


- (NSBezierPath *)backgroundPath
{
    return am_backgroundPath;
}

- (void)setBackgroundPath:(NSBezierPath *)newBackgroundPath
{
    id old = nil;

    if (newBackgroundPath != am_backgroundPath) {
        old = am_backgroundPath;
        am_backgroundPath = [newBackgroundPath retain];
        [old release];
    }
}

- (NSBezierPath *)highlightedBackgroundPath
{
    return am_highlightedBackgroundPath;
}

- (void)setHighlightedBackgroundPath:(NSBezierPath *)newHighlightedBackgroundPath
{
    id old = nil;

    if (newHighlightedBackgroundPath != am_highlightedBackgroundPath) {
        old = am_highlightedBackgroundPath;
        am_highlightedBackgroundPath = [newHighlightedBackgroundPath retain];
        [old release];
    }
}

- (NSBezierPath *)arrowPath
{
	return am_arrowPath;
}

- (void)setArrowPath:(NSBezierPath *)newArrowPath
{
	id old = nil;
	
	if (newArrowPath != am_arrowPath) {
		old = am_arrowPath;
		am_arrowPath = [newArrowPath retain];
		[old release];
	}
}

- (NSSize)lastFrameSize
{
	return am_lastFrameSize;
}

- (void)setLastFrameSize:(NSSize)newLastFrameSize
{
	am_lastFrameSize = newLastFrameSize;
}

- (BOOL)showArrow
{
	return am_showArrow;
}

- (void)setShowArrow:(BOOL)newShowArrow
{
	am_showArrow = newShowArrow;
}

- (BOOL)mouseOver
{
    return am_mouseOver;
}

- (void)setMouseOver:(BOOL)newMouseOver
{
    am_mouseOver = newMouseOver;
}

- (void)setBezelStyle:(NSBezelStyle)newBezelStyle
{
	[super setBezelStyle:newBezelStyle];
	am_lastFrameSize.width = 0;
}

- (void)calculateLayoutForFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	// bezier path for plate background
	[self setLastFrameSize:cellFrame.size];
	NSRect innerRect = NSInsetRect(cellFrame, am_backgroundInset, am_backgroundInset);
	// text rect
	am_textRect = innerRect;
	//NSFont *font = [NSFont boldSystemFontOfSize:[NSFont systemFontSizeForControlSize:[self controlSize]]];
	NSFont *font = [self font];
	NSDictionary *stringAttributes = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, nil];
	NSAttributedString *string = [[[NSAttributedString alloc] initWithString:[self title] attributes:stringAttributes] autorelease];
	NSSize size = [string size];
	float radius = (am_lastFrameSize.height/2.0)-am_backgroundInset;
	// calculate minimum text inset
	float textInset = ([font ascender]-([font fixed_xHeight]/2.0));
	textInset = sqrt(radius*radius - textInset*textInset);
	// more does look better
	textInset *= am_textInsetFactor;
	am_textRect = NSInsetRect(am_textRect, textInset, 0);
	am_textRect.size.height = size.height;
	float capHeight = [font fixed_capHeight];
	float ascender = [font ascender];
	float descender = -[font descender];
	//float lineGap = size.height-ascender-descender;
	float yOrigin = innerRect.origin.y;
	if ([controlView isFlipped]) {
		// line gap below descender

		//NSLog(@"cellFrame height %f", cellFrame.size.height);
		//NSLog(@"innerRect height %f", innerRect.size.height);
		//NSLog(@"textRect height %f", am_textRect.size.height);
		//NSLog(@"capHeight %f", capHeight);
		//NSLog(@"ascender %f", ascender);
		//NSLog(@"descender %f", descender);
		//NSLog(@"lineGap %f", lineGap);
		//NSLog(@"asc+desc+gap %f", ascender+descender+lineGap);

		//NSLog(@"(innerRect.size.height-am_textRect.size.height) / 2.0 = %f", (innerRect.size.height-am_textRect.size.height) / 2.0);
		float offset = ((innerRect.size.height-am_textRect.size.height) / 2.0);
		//NSLog(@"((am_textRect.size.height-capHeight) / 2.0) = %f", ((am_textRect.size.height-capHeight) / 2.0));
		//NSLog(@"(ascender-capHeight)-((am_textRect.size.height-capHeight) / 2.0) = %f", (ascender-capHeight)-((am_textRect.size.height-capHeight) / 2.0));
		offset += (ascender-capHeight)-((am_textRect.size.height-capHeight) / 2.0);
		//NSLog(@"offset: %f", offset);
		yOrigin += ceilf(offset);
	} else {
		// line gap on top of ascender

		//NSLog(@"cellFrame height %f", cellFrame.size.height);
		//NSLog(@"innerRect height %f", innerRect.size.height);
		//NSLog(@"textRect height %f", am_textRect.size.height);
		//NSLog(@"capHeight %f", capHeight);
		//NSLog(@"ascender %f", ascender);
		//NSLog(@"descender %f", descender);
		//NSLog(@"lineGap %f", lineGap);
		//NSLog(@"asc+desc+gap %f", ascender+descender+lineGap);
		
		//NSLog(@"(innerRect.size.height-am_textRect.size.height) / 2.0 = %f", (innerRect.size.height-am_textRect.size.height) / 2.0);
		float offset = ceilf((innerRect.size.height-am_textRect.size.height) / 2.0);
		//NSLog(@"(am_textRect.size.height-capHeight) / 2.0 = %f", ((am_textRect.size.height-capHeight) / 2.0));
		//NSLog(@"((am_textRect.size.height-capHeight) / 2.0)-descender = %f", (((am_textRect.size.height-capHeight) / 2.0)-descender));
		offset += (((am_textRect.size.height-capHeight) / 2.0)-descender);
		//NSLog(@"offset: %f", offset);
		yOrigin += offset;
	}
	//am_textRect.origin.y = (yOrigin > am_textRect.origin.y ? yOrigin : am_textRect.origin.y);
	am_textRect.origin.y = yOrigin;

	// bezier path for button background
	innerRect.origin.x = 0;
	innerRect.origin.y = 0;

	if ([self bezelStyle] == NSShadowlessSquareBezelStyle) {
		am_getBackgroundSelector = @selector(bezierPathForButtonWithRoundedRect:);
	} else {
		am_getBackgroundSelector = @selector(bezierPathWithPlateInRect:);
	}
		
	id returnValue;
	NSInvocation *am_getBackgroundInvocation = [NSInvocation invocationWithMethodSignature:[NSBezierPath methodSignatureForSelector:@selector(bezierPathWithRect:)]];
	[am_getBackgroundInvocation setTarget:[NSBezierPath class]];
	[am_getBackgroundInvocation setSelector:am_getBackgroundSelector];
	[am_getBackgroundInvocation setArgument:&innerRect atIndex:2];
	[am_getBackgroundInvocation invoke];
	[am_getBackgroundInvocation getReturnValue:&returnValue];
	[self setBackgroundPath:returnValue];
	
	//[self setBackgroundPath:[NSBezierPath bezierPathWithPlateInRect:innerRect]];
	[am_backgroundPath setCachesBezierPath:YES];
	// bezier path for pressed button (with gap for shadow)
	innerRect.size.height--;
	if ([controlView isFlipped]) {
		innerRect.origin.y++;
	}

	[am_getBackgroundInvocation setArgument:&innerRect atIndex:2];
	[am_getBackgroundInvocation invoke];
	[am_getBackgroundInvocation getReturnValue:&returnValue];
	
	[self setHighlightedBackgroundPath:returnValue];

	//[self setHighlightedBackgroundPath:[NSBezierPath bezierPathWithPlateInRect:innerRect]];
	[am_highlightedBackgroundPath setCachesBezierPath:YES];
		
	// arrow path
	if ([self menu]) {
		float arrowWidth = [NSFont systemFontSizeForControlSize:[self controlSize]]*0.6;
		float arrowHeight = [NSFont systemFontSizeForControlSize:[self controlSize]]*0.5;
		// clip text rect
		am_textRect.size.width -= (radius*0.5)+(arrowWidth/2.0);
		float x = am_lastFrameSize.width-am_backgroundInset-am_textRect.origin.x-(arrowWidth/2.0);
		float y = am_backgroundInset+radius-arrowHeight/2.0;

		NSBezierPath *path = [NSBezierPath bezierPath];
		NSPoint point1;
		NSPoint point2;
		NSPoint point3;
		if ([controlView isFlipped]) {
			y += radius*0.05;
			point1 = NSMakePoint(x, y);
			point2 = NSMakePoint(x+arrowWidth, y);
			point3 = NSMakePoint(x+arrowWidth/2.0, y+arrowHeight);
		} else {
			y -= radius*0.05;
			point1 = NSMakePoint(x, y+arrowHeight);
			point2 = NSMakePoint(x+arrowWidth, y+arrowHeight);
			point3 = NSMakePoint(x+arrowWidth/2.0, y);
		}
		[path moveToPoint:point1];
		[path lineToPoint:point3];
		[path lineToPoint:point2];
		[path lineToPoint:point1];
		[path closePath];
		[self setArrowPath:path];
	}
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	if ((am_lastFrameSize.width != cellFrame.size.width) || (am_lastFrameSize.height != cellFrame.size.height)) {
		[self calculateLayoutForFrame:cellFrame inView:controlView];
	}
	if ([self isBordered]) {
		if ([self isHighlighted]) {
			[am_highlightedFrameColor set];
		} else if (am_mouseOver) {
			[am_mouseoverFrameColor set];
		} else {
			[am_frameColor set];
		}
		// translate to current origin
		NSBezierPath *path = [[am_backgroundPath copy] autorelease];
		NSAffineTransform *transformation = [NSAffineTransform transform];
		[transformation translateXBy:cellFrame.origin.x+am_backgroundInset yBy:cellFrame.origin.y+am_backgroundInset];
		[path transformUsingAffineTransform:transformation];
		//[path setLineWidth:am_backgroundInset];
		[path setLineWidth:1.0];
		[path setFlatness:am_bezierPathFlatness];
		[path stroke];
	}
	[self drawInteriorWithFrame:cellFrame inView:controlView];
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	NSBezierPath *path;
	NSColor *textColor;
	NSColor *arrowColor;
	NSShadow *textShadow;
	NSColor *shadingStartColor= nil;
	NSColor *shadingEndColor = nil;
	BOOL drawShading = NO;
	NSAffineTransform *transformation = [NSAffineTransform transform];
	[transformation translateXBy:cellFrame.origin.x+am_backgroundInset yBy:cellFrame.origin.y+am_backgroundInset];
	if ([self isHighlighted]) {
		[NSGraphicsContext saveGraphicsState];
		if (am_highlightedShadingColor) {
			drawShading = YES;
			shadingStartColor = am_highlightedShadingColor;
			shadingEndColor = am_highlightedControlColor;
		}
		[am_highlightedControlColor set];
		[am_highlightedControlShadow set];
		path = [[am_highlightedBackgroundPath copy] autorelease];
		textColor = am_highlightedTextColor;
		arrowColor = am_highlightedArrowColor;
		textShadow = am_highlightedTextShadow;
	} else if (am_mouseOver) {
		if (am_mouseoverShadingColor) {
			drawShading = YES;
			shadingStartColor = am_mouseoverShadingColor;
			shadingEndColor = am_mouseoverControlColor;
		}
		[am_mouseoverControlColor set];
		path = [[am_backgroundPath copy] autorelease];
		textColor = am_mouseoverTextColor;
		arrowColor = am_mouseoverArrowColor;
		textShadow = am_mouseoverTextShadow;
	} else {
		if (am_shadingColor) {
			drawShading = YES;
			shadingStartColor = am_shadingColor;
			shadingEndColor = am_controlColor;
		}
		[am_controlColor set];
		path = [[am_backgroundPath copy] autorelease];
		textColor = am_textColor;
		arrowColor = am_arrowColor;
		textShadow = am_textShadow;
	}
	[path transformUsingAffineTransform:transformation];
	[path setLineWidth:0.0];
	[path setFlatness:am_bezierPathFlatness];
	if (drawShading) {
		switch (am_shadingMode) { 
			case am_rollOverButtonShadingLinear: {
				if ([controlView isFlipped]) {
					[path linearGradientFillWithStartColor:shadingEndColor endColor:shadingStartColor];
				} else {
					[path linearGradientFillWithStartColor:shadingStartColor endColor:shadingEndColor];
				}
				break;
			}
			case am_rollOverButtonShadingBilinear: {
				[path bilinearGradientFillWithOuterColor:shadingStartColor innerColor:shadingEndColor];
				break;
			}
			default: // am_rollOverButtonShadingNone
			{
				[path fill];
			}
		}
	} else {
		[path fill];
	}

	if ([self isHighlighted]) {
		[NSGraphicsContext restoreGraphicsState];
	}
	[textShadow set];
	// menu arrow
	if (([self menu] && am_showArrow) || ([self menu] && am_mouseOver)) {
		// draw menu arrow
		[arrowColor set];
		[am_arrowPath fill];
	}
	// draw button title
	NSDictionary *stringAttributes;
	NSFont *font;
	NSMutableParagraphStyle *parapraphStyle = [[[NSMutableParagraphStyle alloc] init] autorelease];
	[parapraphStyle setAlignment:[self alignment]];
	//NSFont *font = [NSFont boldSystemFontOfSize:[NSFont systemFontSizeForControlSize:[self controlSize]]];
	font = [self font];
	stringAttributes = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, textColor, NSForegroundColorAttributeName, parapraphStyle, NSParagraphStyleAttributeName, nil];
	[[self title] drawInRect:am_textRect withAttributes:stringAttributes];
}

- (float)widthForFrame:(NSRect)frameRect
{
	float result;
	//NSFont *font = [NSFont boldSystemFontOfSize:[NSFont systemFontSizeForControlSize:[self controlSize]]];
	NSFont *font = [self font];
	result = [font widthOfString:[self title]];
	float radius = (frameRect.size.height/2.0)-am_backgroundInset;
	float textInset = ([font ascender]-([font fixed_xHeight]/2.0));
	textInset = sqrt(radius*radius - textInset*textInset);
	textInset *= am_textInsetFactor;
	result += 2.0*(textInset+am_backgroundInset);
	if ([self menu] != nil) {
		float arrowSize = [NSFont systemFontSizeForControlSize:[self controlSize]]*0.3;
		result += (radius*0.5)+arrowSize;
	}
	return result;
}

- (NSPoint)menuPositionForFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	NSPoint result = [controlView convertPoint:cellFrame.origin toView:nil];
	result.x += 1.0;
	result.y -= am_backgroundInset+4.0;
	return result;
}

- (BOOL)trackMouse:(NSEvent *)theEvent inRect:(NSRect)cellFrame ofView:(NSView *)controlView untilMouseUp:(BOOL)untilMouseUp
{
	
	BOOL result = NO;
	//NSLog(@"trackMouse:inRect:ofView:untilMouseUp:");
	NSDate *endDate;
	NSPoint currentPoint = [theEvent locationInWindow];
	BOOL done = NO;
	if ([self menu]) {
		// check if mouse is over menu arrow
		NSPoint localPoint = [controlView convertPoint:currentPoint fromView:nil];
		if (localPoint.x >= (am_textRect.origin.x+am_textRect.size.width)) {
			done = YES;
			result = YES;
		NSPoint menuPosition = [self menuPositionForFrame:cellFrame inView:controlView];
		// create event for pop up menu with adjusted mouse position
		NSEvent *menuEvent = [NSEvent mouseEventWithType:[theEvent type] location:menuPosition modifierFlags:[theEvent modifierFlags] timestamp:[theEvent timestamp] windowNumber:[theEvent windowNumber] context:[theEvent context] eventNumber:[theEvent eventNumber] clickCount:[theEvent clickCount] pressure:[theEvent pressure]];
		/* tried to determine the menus size - no way  :-(
		void *carbonMenu = [[self menu] _menuImpl];
		NSLog(@"[self menu]: %@", [self menu]);
		NSLog(@"_menuImpl: %@", carbonMenu);
		NSLog(@"menu: %@", [carbonMenu menu]);
		int menuHeight = GetMenuHeight(carbonMenu);
		NSLog(@"height: %i", menuHeight);
		NSRect outRect;
		OSStatus status = HIViewGetBounds([[self menu] _menuImpl], &outRect);
		NSLog(@"status: %li", status);
		NSLog(@"width: %f height: %f", outRect.size.width, outRect.size.height);
		 */
		[NSMenu popUpContextMenu:[self menu] withEvent:menuEvent forView:controlView];
		}
	}
	BOOL trackContinously = [self startTrackingAt:currentPoint inView:controlView];
	// catch next mouse-dragged or mouse-up event until timeout
	BOOL mouseIsUp = NO;
	NSEvent *event;
	while (!done) { // loop ...
		NSPoint lastPoint = currentPoint;
		if ([self menu]) { // timeout for menu
			endDate = [NSDate dateWithTimeIntervalSinceNow:am_popUpMenuDelay];
		} else { // no timeout
			endDate = [NSDate distantFuture];
		}
		event = [NSApp nextEventMatchingMask:(NSLeftMouseUpMask|NSLeftMouseDraggedMask) untilDate:endDate inMode:NSEventTrackingRunLoopMode dequeue:YES];
		if (event) { // mouse event
			currentPoint = [event locationInWindow];
			if (trackContinously) { // send continueTracking.../stopTracking...
				if (![self continueTracking:lastPoint at:currentPoint inView:controlView]) {
					done = YES;
					[self stopTracking:lastPoint at:currentPoint inView:controlView mouseIsUp:mouseIsUp];
				}
				if ([self isContinuous]) {
					[NSApp sendAction:[self action] to:[self target] from:self];
				}
			}
			mouseIsUp = ([event type] == NSLeftMouseUp);
			done = done || mouseIsUp;
			if (untilMouseUp) {
				result = mouseIsUp;
			} else {
				// check, if the mouse left our cell rect
				result = NSPointInRect([controlView convertPoint:currentPoint fromView:nil], cellFrame);
				if (!result) {
					done = YES;
					[self setMouseOver:NO];
				} else {
					[self setMouseOver:YES];
				}
			}
			if (done && result && ![self isContinuous]) {
				[NSApp sendAction:[self action] to:[self target] from:self];
			}
		} else { // show menu
			done = YES;
			result = YES;
		NSPoint menuPosition = [self menuPositionForFrame:cellFrame inView:controlView];
		// create event for pop up menu with adjusted mouse position
		NSEvent *menuEvent = [NSEvent mouseEventWithType:[theEvent type] location:menuPosition modifierFlags:[theEvent modifierFlags] timestamp:[theEvent timestamp] windowNumber:[theEvent windowNumber] context:[theEvent context] eventNumber:[theEvent eventNumber] clickCount:[theEvent clickCount] pressure:[theEvent pressure]];
		/* tried to determine the menus size - no way  :-(
		void *carbonMenu = [[self menu] _menuImpl];
		NSLog(@"[self menu]: %@", [self menu]);
		NSLog(@"_menuImpl: %@", carbonMenu);
		NSLog(@"menu: %@", [carbonMenu menu]);
		int menuHeight = GetMenuHeight(carbonMenu);
		NSLog(@"height: %i", menuHeight);
		NSRect outRect;
		OSStatus status = HIViewGetBounds([[self menu] _menuImpl], &outRect);
		NSLog(@"status: %li", status);
		NSLog(@"width: %f height: %f", outRect.size.width, outRect.size.height);
		 */
		[NSMenu popUpContextMenu:[self menu] withEvent:menuEvent forView:controlView];
		}
	} // ... while (!done)
	return result;
}

@end


