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

// Constraints
- (CGFloat)minimumWidthOfTabCell:(PSMTabBarCell *)cell {
	return 140.;
}

- (CGFloat)desiredWidthOfTabCell:(PSMTabBarCell *)cell {
	return 300.;
}

- (NSRect)closeButtonRectForBounds:(NSRect)theRect ofTabCell:(PSMTabBarCell *)cell {
	NSRect result = theRect;
	result.size = NSMakeSize(12, 13);
	result.origin.x += 11;
	result.origin.y += 6;
	return result;
}


- (CGFloat)heightOfTabCellsForTabBarControl:(PSMTabBarControl *)tabBarControl {
	return [SEETabStyle desiredTabBarHeight];
}

- (void)drawBezelOfTabBarControl:(PSMTabBarControl *)tabBarControl inRect:(NSRect)rect {
	[[NSColor redColor] set];
	NSRectFill(rect);
	[[NSColor greenColor] set];
	[[NSBezierPath bezierPathWithRect:rect] stroke];
	NSImage *backgroundImage = [SEETabStyle imageForWindowActive:[tabBarControl.window TCM_isActive] name:@"InactiveTabBG"];
	NSDrawThreePartImage(rect, nil, backgroundImage, nil, NO, NSCompositeSourceOver, 1.0, tabBarControl.isFlipped);
}

- (NSImage *)closeButtonImageOfType:(PSMCloseButtonImageType)type forTabCell:(PSMTabBarCell *)cell {
	BOOL isActive = [cell.controlView.window TCM_isActive];
	switch (type) {
		case PSMCloseButtonImageTypeDirtyRollover:
		case PSMCloseButtonImageTypeRollover:
			return [SEETabStyle imageForWindowActive:isActive name:@"ActiveTabCloseRollover"];
		case PSMCloseButtonImageTypeDirtyPressed:
		case PSMCloseButtonImageTypePressed:
			return [SEETabStyle imageForWindowActive:isActive name:@"ActiveTabClosePressed"];
		default: return nil;
	}
}

- (void)drawBezelOfTabCell:(PSMTabBarCell *)cell withFrame:(NSRect)frame inTabBarControl:(PSMTabBarControl *)tabBarControl {
	BOOL isWindowActive = [tabBarControl.window TCM_isActive];
	BOOL isActive = [cell tabState] & PSMTab_SelectedMask;
	BOOL isLeft = [cell tabState] & PSMTab_PositionLeftMask;
	BOOL isRight = [cell tabState] & PSMTab_PositionRightMask;
	
	NSInteger selectedCellIndex = 0;
	for (PSMTabBarCell *tabBarCell in [tabBarControl cells]) {
		if (tabBarCell.tabState & PSMTab_SelectedMask) {
			break;
		}
		selectedCellIndex++;
	};
	NSInteger myIndex = [[tabBarControl cells] indexOfObject:cell];
	
	BOOL isLeftOfSelected  = [cell tabState] & PSMTab_RightIsSelectedMask;
	BOOL isRightOfSelected  = [cell tabState] & PSMTab_LeftIsSelectedMask;
	isLeftOfSelected = myIndex < selectedCellIndex;
	isRightOfSelected = myIndex > selectedCellIndex;
	
	NSImage *leftCap  = [SEETabStyle imageForWindowActive:isWindowActive name:@"ActiveTabLeftCap"];
	NSImage *fill     = [SEETabStyle imageForWindowActive:isWindowActive name:@"ActiveTabFill"];
	NSImage *rightCap = [SEETabStyle imageForWindowActive:isWindowActive name:@"ActiveTabRightCap"];
	
	if (!isActive) {
		leftCap  = [SEETabStyle imageForWindowActive:isWindowActive name:@"InactiveTabLeftCap"];
		fill     = nil;
		rightCap = [SEETabStyle imageForWindowActive:isWindowActive name:@"InactiveTabRightCap"];
	}
	
	NSDrawThreePartImage(CGRectInset(frame,8,0), nil, fill, nil, NO, NSCompositeSourceOver, 1.0, tabBarControl.isFlipped);
	NSRect leftRect = frame;
	leftRect.size.width = leftCap.size.width;
	if (isActive || isLeftOfSelected) {
		[leftCap drawInRect:leftRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0 respectFlipped:YES hints:nil];
	}
	NSRect rightRect = frame;
	rightRect.size.width = rightCap.size.width;
	rightRect.origin.x = CGRectGetMaxX(frame) - rightRect.size.width;
	if (isActive || isRightOfSelected) {
		[rightCap drawInRect:rightRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0 respectFlipped:YES hints:nil];
	}
}


@end
