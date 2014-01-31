//
//  SEETabStyle.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 29.01.14.
//  Copyright (c) 2014 TheCodingMonkeys. All rights reserved.
//

// this file needs arc - either project wide,
// or add -fobjc-arc on a per file basis in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

@interface NSWindow(TCMNSWindowAdditions)
- (BOOL)TCM_isActive;
@end

@implementation NSWindow(TCMNSWindowAdditions)
- (BOOL)TCM_isActive {
	return (self.isKeyWindow || self.isMainWindow);
}

@end


#import "SEETabStyle.h"

@implementation SEETabStyle

+ (CGFloat)desiredTabBarHeight {
	return 24.0;
}

+ (NSString *)name {
    return @"SubEthaEdit";
}

+ (NSImage *)imageForWindowActive:(BOOL)isActive name:(NSString *)aName {
	static NSDictionary *images = nil;
	if (!images) images = @{@"AW" : [NSMutableDictionary new], @"IW" : [NSMutableDictionary new]};
	NSString *isActivePrefix = isActive ? @"AW" : @"IW";
	NSMutableDictionary *subDictionary = images[isActivePrefix];
	NSImage *result = subDictionary[aName];
	if (!result) {
		result = [NSImage imageNamed:[NSString stringWithFormat:@"%@ %@",isActivePrefix,aName]];
		if (result) {
			subDictionary[aName] = result;
		}
	}
	return result;
}

- (NSString *)name {
	return [[self class] name];
}

- (NSImage *)addTabButtonImage {
	return [NSImage imageNamed:@"AddTab"];
}
- (NSImage *)addTabButtonPressedImage {
	return [NSImage imageNamed:@"AddTab"];
}
- (NSImage *)addTabButtonRolloverImage {
	return [NSImage imageNamed:@"AddTab"];
}

- (CGFloat)leftMarginForTabBarControl:(PSMTabBarControl *)tabBarControl {
	return 0;
}
- (CGFloat)rightMarginForTabBarControl:(PSMTabBarControl *)tabBarControl {
	return 0;
}
- (CGFloat)topMarginForTabBarControl:(PSMTabBarControl *)tabBarControl {
	return 0;
}
- (CGFloat)bottomMarginForTabBarControl:(PSMTabBarControl *)tabBarControl {
	return 0;
}


- (void)drawBezelOfTabBarControl:(PSMTabBarControl *)tabBarControl inRect:(NSRect)rect {
	[[NSColor redColor] set];
	NSRectFill(rect);
	[[NSColor greenColor] set];
	[[NSBezierPath bezierPathWithRect:rect] stroke];
	NSImage *backgroundImage = [SEETabStyle imageForWindowActive:[tabBarControl.window TCM_isActive] name:@"InactiveTabBG"];
	NSDrawThreePartImage(rect, nil, backgroundImage, nil, NO, NSCompositeSourceOver, 1.0, tabBarControl.isFlipped);
}

- (void)drawBezelOfTabCell:(PSMTabBarCell *)cell withFrame:(NSRect)frame inTabBarControl:(PSMTabBarControl *)tabBarControl {
	BOOL isActive = [tabBarControl.window TCM_isActive];
	NSImage *leftCap  = [SEETabStyle imageForWindowActive:isActive name:@"ActiveTabLeftCap"];
	NSImage *fill     = [SEETabStyle imageForWindowActive:isActive name:@"ActiveTabFill"];
	NSImage *rightCap = [SEETabStyle imageForWindowActive:isActive name:@"ActiveTabRightCap"];
	NSDrawThreePartImage(frame, leftCap, fill, rightCap, NO, NSCompositeSourceOver, 1.0, tabBarControl.isFlipped);
	
}


@end
