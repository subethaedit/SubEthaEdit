//  SEETabStyle.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 29.01.14.

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
#import "NSColor+SEEAdditions.h"

#import <PSMTabBarControl/PSMRolloverButton.h>
#import <PSMTabBarControl/PSMOverflowPopUpButton.h>

@implementation SEETabStyle

#pragma mark - PSMTabStyle protocol

+ (NSString *)name {
    return @"SubEthaEdit";
}

- (NSString *)name {
	return [[self class] name];
}


#pragma mark - Add tab button

- (NSImage *)addTabButtonImage {
	return [SEETabStyle imageForWindowActive:YES name:@"AddTabButton"];
}
- (NSImage *)addTabButtonPressedImage {
	NSImage *image = [NSImage imageWithSize:NSMakeSize(27.0, 24.0) flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
//		NSImage *rolloverBackground = [SEETabStyle imageForWindowActive:YES name:@"AddTabButtonRolloverBG_Pressed"];
		NSImage *rollover = [SEETabStyle imageForWindowActive:YES name:@"AddTabButtonRollover_Pressed"];
		NSImage *rolloverPlus = [SEETabStyle imageForWindowActive:YES name:@"AddTabButtonPushed"];

//		[rolloverBackground drawInRect:dstRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
		[rollover drawInRect:NSInsetRect(dstRect, 3.5, 1.0) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
		[rolloverPlus drawInRect:NSInsetRect(dstRect, 2.5, 0.5) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];

		return YES;
	}];
	return image;
}

- (NSImage *)addTabButtonRolloverImage {
	NSImage *image = [NSImage imageWithSize:NSMakeSize(27.0, 24.0) flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
//		NSImage *rolloverBackground = [SEETabStyle imageForWindowActive:YES name:@"AddTabButtonRolloverBG"];
		NSImage *rollover = [SEETabStyle imageForWindowActive:YES name:@"AddTabButtonRollover"];
		NSImage *rolloverPlus = [SEETabStyle imageForWindowActive:YES name:@"AddTabButtonRolloverPlus"];

//		[rolloverBackground drawInRect:dstRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
		[rollover drawInRect:NSInsetRect(dstRect, 3.5, 1.0) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
		[rolloverPlus drawInRect:NSInsetRect(dstRect, 2.5, 0.5) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];

		return YES;
	}];
	return image;
}


#pragma mark - Tab bar margins

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


#pragma mark - Cell values

+ (NSDictionary *)tabTitleAttributesForWindowActive:(BOOL)isActive {
	static NSDictionary *attributes = nil;
	if (!attributes) {
		NSShadow *shadow = [[NSShadow alloc] init];
		[shadow setShadowColor:[[NSColor whiteColor] colorWithAlphaComponent:0.5]];
		[shadow setShadowBlurRadius:0.25];
		[shadow setShadowOffset:NSMakeSize(0.0, -0.75)];

		NSMutableDictionary *baseAttributes = [NSMutableDictionary new];
        NSFont *font = [NSFont menuBarFontOfSize:11.0];
        font = [[NSFontManager sharedFontManager] convertFont:font toHaveTrait:NSBoldFontMask | NSCondensedFontMask];
        baseAttributes[NSFontAttributeName] = font;
		baseAttributes[NSForegroundColorAttributeName] = [NSColor colorWithWhite:0.3 alpha:1.0];
		baseAttributes[NSShadowAttributeName] = shadow;

		NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
		[paragraphStyle setAlignment:NSCenterTextAlignment];
		[paragraphStyle setLineBreakMode:NSLineBreakByTruncatingMiddle];
		baseAttributes[NSParagraphStyleAttributeName] = paragraphStyle;

		NSMutableDictionary *inactiveAttributes = [baseAttributes mutableCopy];
		inactiveAttributes[NSForegroundColorAttributeName] = [NSColor colorWithWhite:0.5 alpha:1.0];
		attributes = @{@"AW" : [baseAttributes copy], @"IW" : [inactiveAttributes copy]};
	};
	NSString *isActivePrefix = isActive ? @"AW" : @"IW";
	NSDictionary *result = attributes[isActivePrefix];
	return result;
}

- (NSAttributedString *)attributedStringValueForTabCell:(PSMTabBarCell *)cell {
	NSString *titleString = cell.title;
	NSDictionary *attributesDict = [SEETabStyle tabTitleAttributesForWindowActive:[cell.controlView.window TCM_isActive]];
	return [[NSAttributedString alloc] initWithString:titleString attributes:attributesDict];
}

#pragma mark - Tab bar constraints

+ (CGFloat)desiredTabBarControlHeight {
	return 24.0;
}

- (CGFloat)minimumWidthOfTabCell:(PSMTabBarCell *)cell {
	return 140.;
}

- (CGFloat)desiredWidthOfTabCell:(PSMTabBarCell *)cell {
    CGFloat resultWidth = 0.0;

    // left margin
    resultWidth = MARGIN_X;

    // close button?
    if ([cell shouldDrawCloseButton]) {
        NSImage *image = [cell closeButtonImageOfType:PSMCloseButtonImageTypePressed];
        resultWidth += [image size].width + kPSMTabBarCellPadding;
    }

    // icon?
    if([cell hasIcon]) {
        resultWidth += kPSMTabBarIconWidth + kPSMTabBarCellPadding;
    }

    // the label
    resultWidth += [[cell attributedStringValue] size].width;

    // object counter?
    if([cell count] > 0) {
        resultWidth += [cell objectCounterSize].width + kPSMTabBarCellPadding;
    }

    // indicator?
    if([[cell indicator] isHidden] == NO) {
        resultWidth += kPSMTabBarCellPadding + kPSMTabBarIndicatorWidth;
    }

    // right margin
    resultWidth += MARGIN_X;

    return ceil(resultWidth);
}


#pragma mark - Providing images

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


- (NSImage *)closeButtonImageOfType:(PSMCloseButtonImageType)type forTabCell:(PSMTabBarCell *)cell {
	BOOL isActive = [cell.controlView.window TCM_isActive];
	switch (type) {
		case PSMCloseButtonImageTypeStandard:
			if ((cell.tabState & PSMTab_SelectedMask) == PSMTab_SelectedMask) {
				return [SEETabStyle imageForWindowActive:isActive name:@"ActiveTabClose"];
			} else {
				return nil;
			}
		case PSMCloseButtonImageTypeDirtyRollover:
		case PSMCloseButtonImageTypeRollover:
			return [SEETabStyle imageForWindowActive:isActive name:@"ActiveTabCloseRollover"];
		case PSMCloseButtonImageTypeDirtyPressed:
		case PSMCloseButtonImageTypePressed:
			return [SEETabStyle imageForWindowActive:isActive name:@"ActiveTabClosePressed"];
		default: return nil;
	}
}


#pragma mark - Cell drawing rects

- (CGFloat)heightOfTabCellsForTabBarControl:(PSMTabBarControl *)tabBarControl {
	return [SEETabStyle desiredTabBarControlHeight];
}

- (NSRect)titleRectForBounds:(NSRect)theRect ofTabCell:(PSMTabBarCell *)cell {
    //Don't bother calculating anything if we don't have a string
    NSAttributedString *attrString = [cell attributedStringValue];
    if ([attrString length] == 0)
        return NSZeroRect;

    NSRect drawingRect = [cell drawingRectForBounds:theRect];
    NSRect constrainedDrawingRect = drawingRect;

    NSRect closeButtonRect = [cell closeButtonRectForBounds:theRect];
	if (!NSEqualRects(closeButtonRect, NSZeroRect)) {
		CGFloat closeButtonWidth = NSWidth(closeButtonRect);
		constrainedDrawingRect.origin.x += closeButtonWidth + kPSMTabBarCellPadding;
		constrainedDrawingRect.size.width -= closeButtonWidth + kPSMTabBarCellPadding;

	    //Make sure there's enough padding between the close button and the text
		if (NSMinX(constrainedDrawingRect) - NSMaxX(closeButtonRect) <= kPSMTabBarCellPadding) {
			CGFloat missingGap = ABS(NSMinX(constrainedDrawingRect) - NSMaxX(closeButtonRect) - kPSMTabBarCellPadding);
			constrainedDrawingRect.origin.x += missingGap;
			constrainedDrawingRect.size.width -= missingGap;
		}
	} else {
		constrainedDrawingRect.origin.x += 11.0;
		constrainedDrawingRect.size.width -= 11.0;
	}

	NSInteger selectedCellIndex = 0;
	PSMTabBarControl *tabBarControl = (PSMTabBarControl *)cell.controlView;
	for (PSMTabBarCell *tabBarCell in [tabBarControl cells]) {
		if ((tabBarCell.tabState & PSMTab_SelectedMask) == PSMTab_SelectedMask) {
			break;
		}
		selectedCellIndex++;
	};
	NSInteger myIndex = [[tabBarControl cells] indexOfObject:cell];
	BOOL isLastVisibleCell = ([cell tabState] & PSMTab_PositionRightMask) == PSMTab_PositionRightMask;

	if (myIndex >= selectedCellIndex  || isLastVisibleCell ) {
		constrainedDrawingRect.size.width -= 11.0;
	}

    //Don't show a title if there's only enough space for a character
    if (constrainedDrawingRect.size.width <= 2)
        return NSZeroRect;

    NSSize stringSize = [attrString size];
    NSRect result = NSMakeRect(constrainedDrawingRect.origin.x, drawingRect.origin.y+ceil((drawingRect.size.height-stringSize.height)/2), constrainedDrawingRect.size.width, stringSize.height);

    return NSIntegralRect(result);
}

- (NSRect)closeButtonRectForBounds:(NSRect)theRect ofTabCell:(PSMTabBarCell *)cell {

    if ([cell shouldDrawCloseButton] == NO) {
        return NSZeroRect;
    }

    // ask style for image
    NSImage *image = [cell closeButtonImageOfType:PSMCloseButtonImageTypeRollover];
    if (!image)
        return NSZeroRect;

    // calculate rect
    NSRect drawingRect = [cell drawingRectForBounds:theRect];

    NSSize imageSize = [image size];

    NSSize scaledImageSize = [cell scaleImageWithSize:imageSize toFitInSize:NSMakeSize(imageSize.width, drawingRect.size.height - 5.0) scalingType:NSImageScaleProportionallyDown];


	NSInteger selectedCellIndex = 0;
	PSMTabBarControl *tabBarControl = (PSMTabBarControl *)cell.controlView;
	for (PSMTabBarCell *tabBarCell in [tabBarControl cells]) {
		if ((tabBarCell.tabState & PSMTab_SelectedMask) == PSMTab_SelectedMask) {
			break;
		}
		selectedCellIndex++;
	};
	NSInteger myIndex = [[tabBarControl cells] indexOfObject:cell];

	CGFloat leftTabCapWidth = kPSMTabBarCellPadding + 2.0;
	if (myIndex > selectedCellIndex) {
		leftTabCapWidth = 0.0;
	}

    NSRect result = NSMakeRect(NSMinX(drawingRect) + leftTabCapWidth, drawingRect.origin.y , scaledImageSize.width, scaledImageSize.height);

    if(scaledImageSize.height < drawingRect.size.height) {
        result.origin.y += ceil((drawingRect.size.height - scaledImageSize.height) / 2.0);
    }

    return NSIntegralRect(result);
}

- (NSSize)addTabButtonSizeForTabBarControl:(PSMTabBarControl *)tabBarControl {
	NSRect bounds = tabBarControl.bounds;
	return NSMakeSize(NSHeight(bounds), NSHeight(bounds));
}

- (NSRect)addTabButtonRectForTabBarControl:(PSMTabBarControl *)tabBarControl {
    if ([[tabBarControl addTabButton] isHidden])
        return NSZeroRect;

    NSRect theRect = NSZeroRect;
	NSRect bounds = tabBarControl.bounds;
    NSSize buttonSize = [tabBarControl addTabButtonSize];

	theRect = NSMakeRect(NSMaxX(bounds) - [tabBarControl rightMargin] - buttonSize.width -kPSMTabBarCellPadding, NSMinY(bounds), buttonSize.width, buttonSize.height);

    return theRect;
}

- (NSSize)overflowButtonSizeForTabBarControl:(PSMTabBarControl *)tabBarControl {
	NSRect bounds = tabBarControl.bounds;
	return NSMakeSize(NSHeight(bounds), NSHeight(bounds));
}

- (NSRect)overflowButtonRectForTabBarControl:(PSMTabBarControl *)tabBarControl {
    if ([[tabBarControl overflowPopUpButton] isHidden])
        return NSZeroRect;

    NSRect theRect = NSZeroRect;
	NSRect bounds = tabBarControl.bounds;
    NSSize buttonSize = [tabBarControl overflowButtonSize];

	CGFloat xOffset = kPSMTabBarCellPadding;
	PSMTabBarCell *lastVisibleTab = [tabBarControl lastVisibleTab];
	if (lastVisibleTab) {
		xOffset += NSMaxX([lastVisibleTab frame]);
//		xOffset = NSMaxX([lastVisibleTab frame]) - buttonSize.width - kPSMTabBarCellPadding;
	}

	theRect = NSMakeRect(xOffset, NSMinY(bounds), buttonSize.width, buttonSize.height);

	return theRect;
}


#pragma mark - Drawing

- (void)drawBezelOfTabBarControl:(PSMTabBarControl *)tabBarControl inRect:(NSRect)rect {
    BOOL isWindowActive = [tabBarControl.window TCM_isActive];
	NSImage *backgroundImage = [SEETabStyle imageForWindowActive:isWindowActive name:@"InactiveTabBG"];
	NSDrawThreePartImage(rect, nil, backgroundImage, nil, NO, NSCompositeSourceOver, 1.0, tabBarControl.isFlipped);

	NSRect overflowButtonRect = tabBarControl.overflowButtonRect;
	if (! NSEqualRects(overflowButtonRect, NSZeroRect)) {
		PSMTabBarCell *lastVisibleTab = tabBarControl.lastVisibleTab;
		NSImage *rightCap = [SEETabStyle imageForWindowActive:isWindowActive name:@"InactiveTabRightCap"];

		NSRect rightRect = lastVisibleTab.frame;
		rightRect.size.width = rightCap.size.width;
		rightRect.origin.x = NSMaxX([lastVisibleTab frame]) + NSWidth(overflowButtonRect);
		[rightCap drawInRect:rightRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0 respectFlipped:YES hints:nil];
	}
}

- (void)drawBezelOfTabCell:(PSMTabBarCell *)cell withFrame:(NSRect)frame inTabBarControl:(PSMTabBarControl *)tabBarControl {
	BOOL isWindowActive = [tabBarControl.window TCM_isActive];
	BOOL isActive = ((cell.tabState & PSMTab_SelectedMask) == PSMTab_SelectedMask);
	
	NSInteger selectedCellIndex = 0;
	for (PSMTabBarCell *tabBarCell in [tabBarControl cells]) {
		if ((tabBarCell.tabState & PSMTab_SelectedMask) == PSMTab_SelectedMask) {
			break;
		}
		selectedCellIndex++;
	};

	NSInteger myIndex = [[tabBarControl cells] indexOfObject:cell];
	
//	BOOL isLeftOfSelected  = ([cell tabState] & PSMTab_RightIsSelectedMask) == PSMTab_RightIsSelectedMask;
//	BOOL isRightOfSelected  = ([cell tabState] & PSMTab_LeftIsSelectedMask) == PSMTab_LeftIsSelectedMask;
	BOOL isLastVisibleCell = ([cell tabState] & PSMTab_PositionRightMask) == PSMTab_PositionRightMask;
	BOOL isLeftOfSelected = myIndex < selectedCellIndex;
	BOOL isRightOfSelected = myIndex > selectedCellIndex;
	
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
	if (isActive || isRightOfSelected || isLastVisibleCell) {
		[rightCap drawInRect:rightRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0 respectFlipped:YES hints:nil];
	}
	
	if (NSHeight(tabBarControl.bounds) < [self.class desiredTabBarControlHeight]) {
		[[NSColor darkOverlaySeparatorColorBackgroundIsDark:YES] set];
		NSRect lineRect = tabBarControl.bounds;
		lineRect.origin.y = NSMaxY(lineRect) - 1.0;
		lineRect.size.height = 1.0;
		NSRectFill(lineRect);
	}
}

- (void)drawTitleOfTabCell:(PSMTabBarCell *)cell withFrame:(NSRect)frame inTabBarControl:(PSMTabBarControl *)tabBarControl {
    NSRect titleRect = [cell titleRectForBounds:frame];
    // draw title
    [[cell attributedStringValue] drawInRect:titleRect];
}

@end
