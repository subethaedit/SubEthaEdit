//  NSColor+SEEAdditions.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 08.04.14.

#import <Cocoa/Cocoa.h>

@interface NSColor (SEEAdditions)

+ (NSColor *)brightOverlayBackgroundColorBackgroundIsDark:(BOOL)isDark appearanceIsDark:(BOOL)darkAppearance;
+ (NSColor *)brightOverlaySeparatorColorBackgroundIsDark:(BOOL)isDark appearanceIsDark:(BOOL)darkAppearance;

+ (NSColor *)darkOverlayBackgroundColorBackgroundIsDark:(BOOL)isDark appearanceIsDark:(BOOL)darkAppearance;
+ (NSColor *)darkOverlaySeparatorColorBackgroundIsDark:(BOOL)isDark appearanceIsDark:(BOOL)darkAppearance;

+ (NSColor *)searchScopeBaseColor;
+ (NSColor *)insertionsStatisticsColor;
+ (NSColor *)deletionsStatisticsColor;
+ (NSColor *)selectionsStatisticsColor;

@end
