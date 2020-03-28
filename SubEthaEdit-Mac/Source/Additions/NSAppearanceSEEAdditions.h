//  NSAppearanceSEEAdditions.h
//  SubEthaEdit
//
//  Created by dom on 10.10.18.

#import <Cocoa/Cocoa.h>

@interface NSApplication (NSAppearanceSEEAdditions)
- (BOOL)SEE_effectiveAppearanceIsDark;
@end

@interface NSAppearance (NSAppearanceSEEAdditions)
@property (nonatomic, readonly) BOOL SEE_isDark;
- (NSAppearance *)SEE_closestSystemNonVibrantAppearance;
@end
