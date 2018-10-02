//  NSColor+SEEAdditions.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 08.04.14.

#import <Cocoa/Cocoa.h>

@interface NSColor (SEEAdditions)

+ (NSColor *)brightOverlayBackgroundColorBackgroundIsDark:(BOOL)isDark;
+ (NSColor *)brightOverlaySeparatorColorBackgroundIsDark:(BOOL)isDark;

+ (NSColor *)darkOverlayBackgroundColorBackgroundIsDark:(BOOL)isDark;
+ (NSColor *)darkOverlaySeparatorColorBackgroundIsDark:(BOOL)isDark;

+ (NSColor *)searchScopeBaseColor;
+ (NSColor *)insertionsStatisticsColor;
+ (NSColor *)deletionsStatisticsColor;
+ (NSColor *)selectionsStatisticsColor;

@end
