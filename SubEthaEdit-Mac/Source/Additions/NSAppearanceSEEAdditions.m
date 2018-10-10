//  NSAppearanceSEEAdditions.m
//  SubEthaEdit
//
//  Created by dom on 10.10.18.

#import "NSAppearanceSEEAdditions.h"

@implementation NSAppearance (NSAppearanceSEEAdditions)

- (BOOL)SEE_isDark {
    BOOL result = NO;
    
    if (@available(macOS 10.14, *)) {
        if ([[self bestMatchFromAppearancesWithNames:@[NSAppearanceNameDarkAqua, NSAppearanceNameAqua]] isEqualToString:NSAppearanceNameDarkAqua]) {
            result = YES;
        }
    }
    return result;
}

@end
