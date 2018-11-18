//  NSColorTCMAdditions.h
//  SubEthaEdit
//
//  Created by Martin Pittenauer on Mon Mar 22 2004.

#import <Foundation/Foundation.h>


@interface NSColor (NSColorTCMAdditions)

+ (NSColor *)colorForHTMLString:(NSString *)htmlString;
- (NSString *)shortHTMLString;
- (NSString *)HTMLString;
- (BOOL)isDark;
- (NSColor *)brightnessInvertedColor;
- (NSColor *)brightnessInvertedSelectionColor;
@end
