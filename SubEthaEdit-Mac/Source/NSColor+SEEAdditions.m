//  NSColor+SEEAdditions.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 08.04.14.

#import "NSColor+SEEAdditions.h"

#define STATICVAR(TYPE,VARNAME) static TYPE *VARNAME = nil; \
if (!VARNAME) \
VARNAME

@implementation NSColor (SEEAdditions)

+ (NSColor *)brightOverlayBackgroundColorBackgroundIsDark:(BOOL)isDark {
	STATICVAR(NSColor, colorForDarkBackground)   = [NSColor colorWithCalibratedWhite:0.65 alpha:0.7];
	STATICVAR(NSColor, colorForBrightBackground) = [NSColor colorWithCalibratedWhite:0.95 alpha:0.55];
	NSColor *result = isDark ? colorForDarkBackground : colorForBrightBackground;
	return result;
}

+ (NSColor *)brightOverlaySeparatorColorBackgroundIsDark:(BOOL)isDark {
	STATICVAR(NSColor, colorForDarkBackground)   = [NSColor colorWithCalibratedWhite:0.35 alpha:1.0];
	STATICVAR(NSColor, colorForBrightBackground) = [NSColor colorWithCalibratedWhite:0.6 alpha:1.0];
	NSColor *result = isDark ? colorForDarkBackground : colorForBrightBackground;
	return result;
}

+ (NSColor *)darkOverlayBackgroundColorBackgroundIsDark:(BOOL)isDark {
	STATICVAR(NSColor, colorForDarkBackground)   = [NSColor colorWithCalibratedWhite:0.55 alpha:0.7];
	STATICVAR(NSColor, colorForBrightBackground) = [NSColor colorWithCalibratedWhite:0.65 alpha:0.55];
	NSColor *result = isDark ? colorForDarkBackground : colorForBrightBackground;
	return result;
}

+ (NSColor *)darkOverlaySeparatorColorBackgroundIsDark:(BOOL)isDark {
	STATICVAR(NSColor, colorForDarkBackground)   = [NSColor colorWithCalibratedWhite:0.35 alpha:1.0];
	STATICVAR(NSColor, colorForBrightBackground) = [NSColor colorWithCalibratedWhite:0.4 alpha:1.0];
	NSColor *result = isDark ? colorForDarkBackground : colorForBrightBackground;
	return result;
}


+ (NSColor *)searchScopeBaseColor {
	STATICVAR(NSColor, color) = [NSColor colorWithCalibratedHue:0.131 saturation:0.963 brightness:0.996 alpha:1.000];
	return color;
}

+ (NSColor *)insertionsStatisticsColor {
	STATICVAR(NSColor, color) = [NSColor colorWithCalibratedRed:117./255. green:243./255. blue:68./255. alpha:1.0];
	return color;
}
+ (NSColor *)deletionsStatisticsColor {
	STATICVAR(NSColor, color) = [NSColor colorWithCalibratedRed:221./255. green:43./255. blue:32./255. alpha:1.0];
	return color;
}
+ (NSColor *)selectionsStatisticsColor {
	STATICVAR(NSColor, color) = [NSColor colorWithCalibratedRed:251./255. green:249./255. blue:77./255. alpha:1.0];
	return color;
}


@end
