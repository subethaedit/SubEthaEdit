//
//  PSMPFTabStyle.m
//  --------------------
//
//  Created by Dominik Wagner on 17/11/2006.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "PSMPFTabStyle.h"
#import "PSMTabBarCell.h"
#import "PSMTabBarControl.h"
#import "NSBezierPath_AMShading.h"

#define kPSMUnifiedObjectCounterRadius 7.0
#define kPSMUnifiedCounterMinWidth 20

@interface PSMPFTabStyle (Private)
- (void)drawInteriorWithTabCell:(PSMTabBarCell *)cell inView:(NSView*)controlView;
@end

@implementation PSMPFTabStyle

- (NSString *)name
{
    return @"PF";
}

#pragma mark -
#pragma mark Creation/Destruction

- (id) init
{
    if((self = [super init]))
    {
        unifiedCloseButton = [[NSImage alloc] initByReferencingFile:[[PSMTabBarControl bundle] pathForImageResource:@"AquaTabClose_Front"]];
        unifiedCloseButtonDown = [[NSImage alloc] initByReferencingFile:[[PSMTabBarControl bundle] pathForImageResource:@"AquaTabClose_Front_Pressed"]];
        unifiedCloseButtonOver = [[NSImage alloc] initByReferencingFile:[[PSMTabBarControl bundle] pathForImageResource:@"AquaTabClose_Front_Rollover"]];
        
        unifiedCloseDirtyButton = [[NSImage alloc] initByReferencingFile:[[PSMTabBarControl bundle] pathForImageResource:@"AquaTabCloseDirty_Front"]];
        unifiedCloseDirtyButtonDown = [[NSImage alloc] initByReferencingFile:[[PSMTabBarControl bundle] pathForImageResource:@"AquaTabCloseDirty_Front_Pressed"]];
        unifiedCloseDirtyButtonOver = [[NSImage alloc] initByReferencingFile:[[PSMTabBarControl bundle] pathForImageResource:@"AquaTabCloseDirty_Front_Rollover"]];
        
        _addTabButtonImage = [[NSImage alloc] initByReferencingFile:[[PSMTabBarControl bundle] pathForImageResource:@"AquaTabNew"]];
        _addTabButtonPressedImage = [[NSImage alloc] initByReferencingFile:[[PSMTabBarControl bundle] pathForImageResource:@"AquaTabNewPressed"]];
        _addTabButtonRolloverImage = [[NSImage alloc] initByReferencingFile:[[PSMTabBarControl bundle] pathForImageResource:@"AquaTabNewRollover"]];
    
		leftMargin = 5.0;
	}
    return self;
}

- (void)dealloc
{
    [unifiedCloseButton release];
    [unifiedCloseButtonDown release];
    [unifiedCloseButtonOver release];
    [unifiedCloseDirtyButton release];
    [unifiedCloseDirtyButtonDown release];
    [unifiedCloseDirtyButtonOver release];    
    [_addTabButtonImage release];
    [_addTabButtonPressedImage release];
    [_addTabButtonRolloverImage release];
    
    [super dealloc];
}

#pragma mark -
#pragma mark Control Specific

- (void)setLeftMarginForTabBarControl:(float)margin
{
	leftMargin = margin;
}

- (float)leftMarginForTabBarControl
{
    return leftMargin;
}

- (float)rightMarginForTabBarControl
{
    return 24.0f;
}

- (float)topMarginForTabBarControl
{
	return 10.0f;
}

#pragma mark -
#pragma mark Add Tab Button

- (NSImage *)addTabButtonImage
{
    return _addTabButtonImage;
}

- (NSImage *)addTabButtonPressedImage
{
    return _addTabButtonPressedImage;
}

- (NSImage *)addTabButtonRolloverImage
{
    return _addTabButtonRolloverImage;
}

#pragma mark -
#pragma mark Cell Specific

- (NSRect)dragRectForTabCell:(PSMTabBarCell *)cell orientation:(PSMTabBarOrientation)orientation
{
	NSRect dragRect = [cell frame];
	dragRect.size.width++;
	return dragRect;
}

- (NSRect)closeButtonRectForTabCell:(PSMTabBarCell *)cell
{
    NSRect cellFrame = [cell frame];
    
    if ([cell hasCloseButton] == NO) {
        return NSZeroRect;
    }
    
    NSRect result;
    result.size = [unifiedCloseButton size];
    result.origin.x = cellFrame.origin.x + MARGIN_X;
    result.origin.y = cellFrame.origin.y + MARGIN_Y + 3.0;
    
    return result;
}

- (NSRect)iconRectForTabCell:(PSMTabBarCell *)cell
{
    NSRect cellFrame = [cell frame];
    
    if ([cell hasIcon] == NO) {
        return NSZeroRect;
    }
    
    NSRect result;
    result.size = NSMakeSize(kPSMTabBarIconWidth, kPSMTabBarIconWidth);
    result.origin.x = cellFrame.origin.x + MARGIN_X;
    result.origin.y = cellFrame.origin.y + MARGIN_Y + 1.0;
    
    if([cell hasCloseButton] && ![cell isCloseButtonSuppressed])
        result.origin.x += [unifiedCloseButton size].width + kPSMTabBarCellPadding;

    return result;
}

- (NSRect)indicatorRectForTabCell:(PSMTabBarCell *)cell
{
    NSRect cellFrame = [cell frame];
    
    if ([[cell indicator] isHidden]) {
        return NSZeroRect;
    }
    
    NSRect result;
    result.size = NSMakeSize(kPSMTabBarIndicatorWidth, kPSMTabBarIndicatorWidth);
    result.origin.x = cellFrame.origin.x + cellFrame.size.width - MARGIN_X - kPSMTabBarIndicatorWidth;
    result.origin.y = cellFrame.origin.y + MARGIN_Y + 1.0;
     
    return result;
}

- (NSRect)objectCounterRectForTabCell:(PSMTabBarCell *)cell
{
    NSRect cellFrame = [cell frame];
    
    if ([cell count] == 0) {
        return NSZeroRect;
    }
    
    float countWidth = [[self attributedObjectCountValueForTabCell:cell] size].width;
    countWidth += (2 * kPSMUnifiedObjectCounterRadius - 6.0);
    if(countWidth < kPSMUnifiedCounterMinWidth)
        countWidth = kPSMUnifiedCounterMinWidth;
    
    NSRect result;
    result.size = NSMakeSize(countWidth, 2 * kPSMUnifiedObjectCounterRadius); // temp
    result.origin.x = cellFrame.origin.x + cellFrame.size.width - MARGIN_X - result.size.width;
    result.origin.y = cellFrame.origin.y + MARGIN_Y + 3.0;
    
    if(![[cell indicator] isHidden])
        result.origin.x -= kPSMTabBarIndicatorWidth + kPSMTabBarCellPadding;
    
    return result;
}


- (float)minimumWidthOfTabCell:(PSMTabBarCell *)cell
{
    float resultWidth = 0.0;
    
    // left margin
    resultWidth = MARGIN_X;
    
    // close button?
    if([cell hasCloseButton] && ![cell isCloseButtonSuppressed])
        resultWidth += [unifiedCloseButton size].width + kPSMTabBarCellPadding;
    
    // icon?
    if([cell hasIcon])
        resultWidth += kPSMTabBarIconWidth + kPSMTabBarCellPadding;
    
    // the label
    resultWidth += kPSMMinimumTitleWidth;
    
    // object counter?
    if([cell count] > 0)
        resultWidth += [self objectCounterRectForTabCell:cell].size.width + kPSMTabBarCellPadding;
    
    // indicator?
    if ([[cell indicator] isHidden] == NO)
        resultWidth += kPSMTabBarCellPadding + kPSMTabBarIndicatorWidth;
    
    // right margin
    resultWidth += MARGIN_X;
    
    return ceil(resultWidth);
}

- (float)desiredWidthOfTabCell:(PSMTabBarCell *)cell
{
    float resultWidth = 0.0;
    
    // left margin
    resultWidth = MARGIN_X;
    
    // close button?
    if ([cell hasCloseButton] && ![cell isCloseButtonSuppressed])
        resultWidth += [unifiedCloseButton size].width + kPSMTabBarCellPadding;
    
    // icon?
    if([cell hasIcon])
        resultWidth += kPSMTabBarIconWidth + kPSMTabBarCellPadding;
    
    // the label
    resultWidth += [[cell attributedStringValue] size].width;
    
    // object counter?
    if([cell count] > 0)
        resultWidth += [self objectCounterRectForTabCell:cell].size.width + kPSMTabBarCellPadding;
    
    // indicator?
    if ([[cell indicator] isHidden] == NO)
        resultWidth += kPSMTabBarCellPadding + kPSMTabBarIndicatorWidth;
    
    // right margin
    resultWidth += MARGIN_X;
    
    return ceil(resultWidth);
}

#pragma mark -
#pragma mark Cell Values

- (NSAttributedString *)attributedObjectCountValueForTabCell:(PSMTabBarCell *)cell
{
    NSMutableAttributedString *attrStr;
    NSFontManager *fm = [NSFontManager sharedFontManager];
    NSNumberFormatter *nf = [[[NSNumberFormatter alloc] init] autorelease];
    [nf setLocalizesFormat:YES];
    [nf setFormat:@"0"];
    [nf setHasThousandSeparators:YES];
    NSString *contents = [nf stringFromNumber:[NSNumber numberWithInt:[cell count]]];
    attrStr = [[[NSMutableAttributedString alloc] initWithString:contents] autorelease];
    NSRange range = NSMakeRange(0, [contents length]);
    
    // Add font attribute
    [attrStr addAttribute:NSFontAttributeName value:[fm convertFont:[NSFont fontWithName:@"Helvetica" size:11.0] toHaveTrait:NSBoldFontMask] range:range];
    [attrStr addAttribute:NSForegroundColorAttributeName value:[[NSColor whiteColor] colorWithAlphaComponent:0.85] range:range];
    
    return attrStr;
}

- (NSAttributedString *)attributedStringValueForTabCell:(PSMTabBarCell *)cell
{
    NSMutableAttributedString *attrStr;
    NSString * contents = [cell stringValue];
    attrStr = [[[NSMutableAttributedString alloc] initWithString:contents] autorelease];
    NSRange range = NSMakeRange(0, [contents length]);
    
    [attrStr addAttribute:NSFontAttributeName value:[NSFont boldSystemFontOfSize:10.0] range:range];
    
    // Paragraph Style for Truncating Long Text
    static NSMutableParagraphStyle *TruncatingTailParagraphStyle = nil;
    if (!TruncatingTailParagraphStyle) {
        TruncatingTailParagraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        [TruncatingTailParagraphStyle setLineBreakMode:NSLineBreakByTruncatingMiddle];
        if ([TruncatingTailParagraphStyle respondsToSelector:@selector(setTighteningFactorForTruncation:)]) {
            [TruncatingTailParagraphStyle setTighteningFactorForTruncation:0.2];
        }
    }
    [attrStr addAttribute:NSParagraphStyleAttributeName value:TruncatingTailParagraphStyle range:range];
    
    return attrStr;	
}

#pragma mark -
#pragma mark ---- drawing ----

- (NSImage *)dragImageForCell:(PSMTabBarCell *)cell
{
    NSImage *dragImage = [[[NSImage alloc] initWithSize:[cell frame].size] autorelease];
    [dragImage setFlipped:YES];
    [dragImage lockFocus];
    
    NSRect cellFrame = [cell frame];
    cellFrame.origin = NSZeroPoint;
	
	NSToolbar *toolbar = [[[cell controlView] window] toolbar];
	BOOL showsBaselineSeparator = (toolbar && [toolbar respondsToSelector:@selector(showsBaselineSeparator)] && [toolbar showsBaselineSeparator]);
	if (!showsBaselineSeparator) {
		cellFrame.origin.y += 1.0;
		cellFrame.size.height -= 1.0;
	}
	
    NSColor * lineColor = nil;
    NSBezierPath* bezier = [NSBezierPath bezierPath];
    lineColor = [NSColor colorWithCalibratedWhite:0.576 alpha:1.0];

    // frame
    NSRect aRect = NSMakeRect(cellFrame.origin.x+0.5, cellFrame.origin.y+1.5, cellFrame.size.width-1.0, cellFrame.size.height-2.);
    float radius = MIN(6.0, 0.5f * MIN(NSWidth(aRect), NSHeight(aRect)));
    NSRect rect = NSInsetRect(aRect, radius, radius);
    
    [bezier appendBezierPathWithArcWithCenter:NSMakePoint(NSMinX(rect), NSMinY(rect)) radius:radius startAngle:180.0 endAngle:270.0];
    
    [bezier appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(rect), NSMinY(rect)) radius:radius startAngle:270.0 endAngle:360.0];
    
    NSPoint cornerPoint = NSMakePoint(NSMaxX(aRect), NSMaxY(aRect));
    [bezier appendBezierPathWithPoints:&cornerPoint count:1];
    
    cornerPoint = NSMakePoint(NSMinX(aRect), NSMaxY(aRect));
    [bezier appendBezierPathWithPoints:&cornerPoint count:1];
    
    [bezier closePath];

    if (!showsBaselineSeparator || [cell state] == NSOnState)
	{
        // selected tab
        
		
		//[[NSColor windowBackgroundColor] set];
		//[bezier fill];
		static NSShadow *s_shadow = nil, *s_noshadow = nil;
		if (!s_shadow) {
		  s_noshadow = [NSShadow new];
		  s_shadow = [NSShadow new];
		  [s_shadow setShadowOffset:NSMakeSize(0.,-3.)];
		  [s_shadow setShadowColor:[NSColor blackColor]];
		  [s_shadow setShadowBlurRadius:4.];
		}
		[s_shadow set];
        static NSColor *color;
        if (!color) {
            if ([NSColor respondsToSelector:@selector(_controlColor)]) {
                color = [[NSColor performSelector:@selector(_controlColor)] retain];
            } else {
                color = [[NSColor colorWithCalibratedWhite:0.8841 alpha:1.0] retain];
            }
        }
		[color set];
		[bezier fill];
		if ([NSApp isActive]) {
			if ([cell state] == NSOnState) {
				[bezier linearGradientFillWithStartColor:[NSColor colorWithCalibratedWhite:0.99 alpha:1.0]
												endColor:[NSColor colorWithCalibratedWhite:0.841 alpha:1.0]];
			} else if ([cell isHighlighted]) {
				[bezier linearGradientFillWithStartColor:[NSColor colorWithCalibratedWhite:0.75 alpha:1.0]
												endColor:[NSColor colorWithCalibratedWhite:0.70 alpha:1.0]];
			} else {
				[bezier linearGradientFillWithStartColor:[NSColor colorWithCalibratedWhite:0.835 alpha:1.0]
												endColor:[NSColor colorWithCalibratedWhite:0.843 alpha:1.0]];
			}
		} 
		[s_noshadow set];
		[lineColor set];
        [bezier stroke];
    }
	else
	{
        // unselected tab
        NSRect aRect = NSMakeRect(cellFrame.origin.x, cellFrame.origin.y, cellFrame.size.width, cellFrame.size.height);
        aRect.origin.y += 0.5;
        aRect.origin.x += 1.5;
        aRect.size.width -= 1;
		
		aRect.origin.x -= 1;
        aRect.size.width += 1;
        
        // rollover
        [[NSColor colorWithCalibratedWhite:0.0 alpha:0.1] set];
        [bezier fill];
	}
    [dragImage unlockFocus];
    
    [dragImage setFlipped:YES];
    [dragImage lockFocus];
    
    // draw interior
    
    cellFrame = [cell frame];
    cellFrame.origin = NSZeroPoint;
    float labelPosition = cellFrame.origin.x + MARGIN_X;
    
    // close button
    if ([cell hasCloseButton] && ![cell isCloseButtonSuppressed]) {
        NSSize closeButtonSize = NSZeroSize;
        //NSRect closeButtonRect = [cell closeButtonRectForFrame:cellFrame];
        NSRect closeButtonRect;
        NSRect cellFrame2 = [cell frame];
        cellFrame2.origin = NSZeroPoint;
        if ([cell hasCloseButton] == NO) {
            closeButtonRect = NSZeroRect;
        } else {
            closeButtonRect.size = [unifiedCloseButton size];
            closeButtonRect.origin.x = cellFrame2.origin.x + MARGIN_X;
            closeButtonRect.origin.y = cellFrame2.origin.y + MARGIN_Y + 3.0;
        }
        NSImage * closeButton = nil;
        
        closeButton = [cell isEdited] ? unifiedCloseDirtyButton : unifiedCloseButton;

        if ([cell closeButtonOver]) closeButton = [cell isEdited] ? unifiedCloseDirtyButtonOver : unifiedCloseButtonOver;
        if ([cell closeButtonPressed]) closeButton = [cell isEdited] ? unifiedCloseDirtyButtonDown : unifiedCloseButtonDown;
        
        closeButtonSize = [closeButton size];
        if ([[cell controlView] isFlipped]) {
            closeButtonRect.origin.y += closeButtonRect.size.height;
        }
        
        [closeButton compositeToPoint:closeButtonRect.origin operation:NSCompositeSourceOver fraction:1.0];
        
        // scoot label over
        labelPosition += closeButtonSize.width + kPSMTabBarCellPadding;
    }
    
    // icon
    if([cell hasIcon]) {
    
        //NSRect iconRect = [self iconRectForTabCell:cell];
        NSRect cellFrame2 = [cell frame];
        cellFrame2.origin = NSZeroPoint;
        
        NSRect iconRect;
        iconRect.size = NSMakeSize(kPSMTabBarIconWidth, kPSMTabBarIconWidth);
        iconRect.origin.x = cellFrame2.origin.x + MARGIN_X;
        iconRect.origin.y = cellFrame2.origin.y + MARGIN_Y + 1.0;
        
        if([cell hasCloseButton] && ![cell isCloseButtonSuppressed])
            iconRect.origin.x += [unifiedCloseButton size].width + kPSMTabBarCellPadding;
                
                                
        NSImage *icon = [[[cell representedObject] identifier] icon];
        if ([[cell controlView] isFlipped]) {
            iconRect.origin.y += iconRect.size.height;
        }
        
        // center in available space (in case icon image is smaller than kPSMTabBarIconWidth)
        if([icon size].width < kPSMTabBarIconWidth)
            iconRect.origin.x += (kPSMTabBarIconWidth - [icon size].width)/2.0;
        if([icon size].height < kPSMTabBarIconWidth)
            iconRect.origin.y -= (kPSMTabBarIconWidth - [icon size].height)/2.0;
        
        [icon compositeToPoint:iconRect.origin operation:NSCompositeSourceOver fraction:1.0];
        
        // scoot label over
        labelPosition += iconRect.size.width + kPSMTabBarCellPadding;
    }
    
    // object counter
    if([cell count] > 0){
        [[NSColor colorWithCalibratedWhite:0.3 alpha:0.6] set];
        NSBezierPath *path = [NSBezierPath bezierPath];
        //NSRect myRect = [self objectCounterRectForTabCell:cell];
        NSRect myRect;
        NSRect cellFrame2 = [cell frame];
        cellFrame2.origin = NSZeroPoint;
        if ([cell count] == 0) {
            myRect = NSZeroRect;
        } else {
            float countWidth = [[self attributedObjectCountValueForTabCell:cell] size].width;
            countWidth += (2 * kPSMUnifiedObjectCounterRadius - 6.0);
            if(countWidth < kPSMUnifiedCounterMinWidth)
                countWidth = kPSMUnifiedCounterMinWidth;
            
            myRect.size = NSMakeSize(countWidth, 2 * kPSMUnifiedObjectCounterRadius); // temp
            myRect.origin.x = cellFrame2.origin.x + cellFrame.size.width - MARGIN_X - myRect.size.width;
            myRect.origin.y = cellFrame2.origin.y + MARGIN_Y + 3.0;
            
            if(![[cell indicator] isHidden])
                myRect.origin.x -= kPSMTabBarIndicatorWidth + kPSMTabBarCellPadding;
        }
        
		myRect.origin.y -= 1.0;
        [path moveToPoint:NSMakePoint(myRect.origin.x + kPSMUnifiedObjectCounterRadius, myRect.origin.y)];
        [path lineToPoint:NSMakePoint(myRect.origin.x + myRect.size.width - kPSMUnifiedObjectCounterRadius, myRect.origin.y)];
        [path appendBezierPathWithArcWithCenter:NSMakePoint(myRect.origin.x + myRect.size.width - kPSMUnifiedObjectCounterRadius, myRect.origin.y + kPSMUnifiedObjectCounterRadius) radius:kPSMUnifiedObjectCounterRadius startAngle:270.0 endAngle:90.0];
        [path lineToPoint:NSMakePoint(myRect.origin.x + kPSMUnifiedObjectCounterRadius, myRect.origin.y + myRect.size.height)];
        [path appendBezierPathWithArcWithCenter:NSMakePoint(myRect.origin.x + kPSMUnifiedObjectCounterRadius, myRect.origin.y + kPSMUnifiedObjectCounterRadius) radius:kPSMUnifiedObjectCounterRadius startAngle:90.0 endAngle:270.0];
        [path fill];
        
        // draw attributed string centered in area
        NSRect counterStringRect;
        NSAttributedString *counterString = [self attributedObjectCountValueForTabCell:cell];
        counterStringRect.size = [counterString size];
        counterStringRect.origin.x = myRect.origin.x + ((myRect.size.width - counterStringRect.size.width) / 2.0) + 0.25;
        counterStringRect.origin.y = myRect.origin.y + ((myRect.size.height - counterStringRect.size.height) / 2.0) + 0.5;
        [counterString drawInRect:counterStringRect];
    }
    
    // label rect
    NSRect labelRect;
    labelRect.origin.x = labelPosition;
    labelRect.size.width = cellFrame.size.width - (labelRect.origin.x - cellFrame.origin.x) - kPSMTabBarCellPadding;
	NSSize s = [[cell attributedStringValue] size];
	labelRect.origin.y = cellFrame.origin.y + (cellFrame.size.height-s.height)/2.0 + 2.0;
	labelRect.size.height = s.height;
    
    if(![[cell indicator] isHidden])
        labelRect.size.width -= (kPSMTabBarIndicatorWidth + kPSMTabBarCellPadding);
    
    if([cell count] > 0)
        labelRect.size.width -= ([self objectCounterRectForTabCell:cell].size.width + kPSMTabBarCellPadding);
    
    // label
    [[cell attributedStringValue] drawInRect:labelRect];
    
    
    [dragImage unlockFocus];
    
    if(![[cell indicator] isHidden]){
        NSImage *pi = [[NSImage alloc] initByReferencingFile:[[PSMTabBarControl bundle] pathForImageResource:@"pi"]];
        [dragImage setFlipped:NO];
        [dragImage lockFocus];
        NSPoint indicatorPoint = NSMakePoint([cell frame].size.width - MARGIN_X - kPSMTabBarIndicatorWidth, MARGIN_Y);
        [pi compositeToPoint:indicatorPoint operation:NSCompositeSourceOver fraction:1.0];
        [dragImage unlockFocus];
        [pi release];
    }
    
    return dragImage;
}

- (void)drawTabCell:(PSMTabBarCell *)cell
{
    NSRect cellFrame = [cell frame];
	
	NSToolbar *toolbar = [[[cell controlView] window] toolbar];
	BOOL showsBaselineSeparator = (toolbar && (([toolbar respondsToSelector:@selector(showsBaselineSeparator)] && [toolbar showsBaselineSeparator]) || ![toolbar respondsToSelector:@selector(showsBaselineSeparator)]));
	if (!showsBaselineSeparator) {
		cellFrame.origin.y += 1.0;
		cellFrame.size.height -= 1.0;
	}
	
    NSColor * lineColor = nil;
    NSBezierPath* bezier = [NSBezierPath bezierPath];
    lineColor = [NSColor colorWithCalibratedWhite:0.576 alpha:1.0];

    // frame
    NSRect aRect = NSMakeRect(cellFrame.origin.x+0.5, cellFrame.origin.y+1.5, cellFrame.size.width, cellFrame.size.height-2.);
    float radius = MIN(6.0, 0.5f * MIN(NSWidth(aRect), NSHeight(aRect)));
    NSRect rect = NSInsetRect(aRect, radius, radius);
    
    [bezier appendBezierPathWithArcWithCenter:NSMakePoint(NSMinX(rect), NSMinY(rect)) radius:radius startAngle:180.0 endAngle:270.0];
    
    [bezier appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(rect), NSMinY(rect)) radius:radius startAngle:270.0 endAngle:360.0];
    
    NSPoint cornerPoint = NSMakePoint(NSMaxX(aRect), NSMaxY(aRect));
    [bezier appendBezierPathWithPoints:&cornerPoint count:1];
    
    cornerPoint = NSMakePoint(NSMinX(aRect), NSMaxY(aRect));
    [bezier appendBezierPathWithPoints:&cornerPoint count:1];
    
    [bezier closePath];

    static NSShadow *s_shadow = nil, *s_noshadow = nil;
    if (!showsBaselineSeparator || [cell state] == NSOnState)
	{
        // selected tab
        
		
		//[[NSColor windowBackgroundColor] set];
		//[bezier fill];
		if (!s_shadow) {
		  s_noshadow = [NSShadow new];
		  s_shadow = [NSShadow new];
		  [s_shadow setShadowOffset:NSMakeSize(0.,-3.)];
		  [s_shadow setShadowColor:[NSColor blackColor]];
		  [s_shadow setShadowBlurRadius:4.];
		}
		[s_shadow set];
        static NSColor *color;
        if (!color) {
            if ([NSColor respondsToSelector:@selector(_controlColor)]) {
                color = [[NSColor performSelector:@selector(_controlColor)] retain];
            } else {
                color = [[NSColor colorWithCalibratedWhite:0.8841 alpha:1.0] retain];
            }
        }
		[color set];
		[bezier fill];
		if ([NSApp isActive]) {
			if ([cell state] == NSOnState) {
				[bezier linearGradientFillWithStartColor:[NSColor colorWithCalibratedWhite:0.99 alpha:1.0]
												endColor:[NSColor colorWithCalibratedWhite:0.841 alpha:1.0]];
			} else if ([cell isHighlighted]) {
				[bezier linearGradientFillWithStartColor:[NSColor colorWithCalibratedWhite:0.75 alpha:1.0]
												endColor:[NSColor colorWithCalibratedWhite:0.70 alpha:1.0]];
			} else {
				[bezier linearGradientFillWithStartColor:[NSColor colorWithCalibratedWhite:0.835 alpha:1.0]
												endColor:[NSColor colorWithCalibratedWhite:0.843 alpha:1.0]];
			}
		} 
		[s_noshadow set];
		[lineColor set];
        [bezier stroke];
    }
	else
	{
        // unselected tab
        NSRect aRect = NSMakeRect(cellFrame.origin.x, cellFrame.origin.y, cellFrame.size.width, cellFrame.size.height);
        aRect.origin.y += 0.5;
        aRect.origin.x += 1.5;
        aRect.size.width -= 1;
		
		aRect.origin.x -= 1;
        aRect.size.width += 1;
        
        // rollover
        if ([cell isHighlighted])
		{
            [[NSColor colorWithCalibratedWhite:0.0 alpha:0.1] set];
            [bezier fill];
        }

        if ([cell isPlaceholder] && [cell frame].size.width >= 2.)
		{
		    [self drawBackgroundInRect:cellFrame];
		    /*
            [[NSColor colorWithCalibratedWhite:0.0 alpha:0.2] set];
            [bezier linearGradientFillWithStartColor:[NSColor colorWithCalibratedWhite:0.75 alpha:1.0]
			  								endColor:[NSColor colorWithCalibratedWhite:0.70 alpha:1.0]];
            */
        }

        
        // frame
		
//        [lineColor set];
//        [bezier moveToPoint:NSMakePoint(aRect.origin.x + aRect.size.width, aRect.origin.y-0.5)];
//		if(!([cell tabState] & PSMTab_RightIsSelectedMask)){
//            [bezier lineToPoint:NSMakePoint(NSMaxX(aRect), NSMaxY(aRect))];
//        }
//		 
//        [bezier stroke];
//		
//		// Create a thin lighter line next to the dividing line for a bezel effect
//		if(!([cell tabState] & PSMTab_RightIsSelectedMask)){
//			[[[NSColor whiteColor] colorWithAlphaComponent:0.5] set];
//			[NSBezierPath strokeLineFromPoint:NSMakePoint(NSMaxX(aRect)+1.0, aRect.origin.y-0.5)
//									  toPoint:NSMakePoint(NSMaxX(aRect)+1.0, NSMaxY(aRect)-2.5)];
//		}
//		
//		// If this is the leftmost tab, we want to draw a line on the left, too
//		if ([cell tabState] & PSMTab_PositionLeftMask)
//		{
//			[lineColor set];
//			[NSBezierPath strokeLineFromPoint:NSMakePoint(aRect.origin.x,aRect.origin.y-0.5)
//									  toPoint:NSMakePoint(aRect.origin.x,NSMaxY(aRect)-2.5)];
//			[[[NSColor whiteColor] colorWithAlphaComponent:0.5] set];
//			[NSBezierPath strokeLineFromPoint:NSMakePoint(aRect.origin.x+1.0,aRect.origin.y-0.5)
//									  toPoint:NSMakePoint(aRect.origin.x+1.0,NSMaxY(aRect)-2.5)];
//		}
	}

    [self drawInteriorWithTabCell:cell inView:[cell controlView]];
}


- (void)drawInteriorWithTabCell:(PSMTabBarCell *)cell inView:(NSView*)controlView
{
    NSRect cellFrame = [cell frame];
    float labelPosition = cellFrame.origin.x + MARGIN_X;
    
    // close button
    if ([cell hasCloseButton] && ![cell isCloseButtonSuppressed] && ![cell isPlaceholder]) {
        NSSize closeButtonSize = NSZeroSize;
        NSRect closeButtonRect = [cell closeButtonRectForFrame:cellFrame];
        NSImage * closeButton = nil;
        
        closeButton = [cell isEdited] ? unifiedCloseDirtyButton : unifiedCloseButton;

        if ([cell closeButtonOver]) closeButton = [cell isEdited] ? unifiedCloseDirtyButtonOver : unifiedCloseButtonOver;
        if ([cell closeButtonPressed]) closeButton = [cell isEdited] ? unifiedCloseDirtyButtonDown : unifiedCloseButtonDown;

        closeButtonSize = [closeButton size];
        if ([controlView isFlipped]) {
            closeButtonRect.origin.y += closeButtonRect.size.height;
        }
        
        [closeButton compositeToPoint:closeButtonRect.origin operation:NSCompositeSourceOver fraction:1.0];
        
        // scoot label over
        labelPosition += closeButtonSize.width + kPSMTabBarCellPadding;
    }
    
    // icon
    if([cell hasIcon]){
        NSRect iconRect = [self iconRectForTabCell:cell];
        NSImage *icon = [[[cell representedObject] identifier] icon];
        if ([controlView isFlipped]) {
            iconRect.origin.y += iconRect.size.height;
        }
        
        // center in available space (in case icon image is smaller than kPSMTabBarIconWidth)
        if([icon size].width < kPSMTabBarIconWidth)
            iconRect.origin.x += (kPSMTabBarIconWidth - [icon size].width)/2.0;
        if([icon size].height < kPSMTabBarIconWidth)
            iconRect.origin.y -= (kPSMTabBarIconWidth - [icon size].height)/2.0;
        
        [icon compositeToPoint:iconRect.origin operation:NSCompositeSourceOver fraction:1.0];
        
        // scoot label over
        labelPosition += iconRect.size.width + kPSMTabBarCellPadding;
    }
    
    // object counter
    if([cell count] > 0){
        [[NSColor colorWithCalibratedWhite:0.3 alpha:0.6] set];
        NSBezierPath *path = [NSBezierPath bezierPath];
        NSRect myRect = [self objectCounterRectForTabCell:cell];
		myRect.origin.y -= 1.0;
        [path moveToPoint:NSMakePoint(myRect.origin.x + kPSMUnifiedObjectCounterRadius, myRect.origin.y)];
        [path lineToPoint:NSMakePoint(myRect.origin.x + myRect.size.width - kPSMUnifiedObjectCounterRadius, myRect.origin.y)];
        [path appendBezierPathWithArcWithCenter:NSMakePoint(myRect.origin.x + myRect.size.width - kPSMUnifiedObjectCounterRadius, myRect.origin.y + kPSMUnifiedObjectCounterRadius) radius:kPSMUnifiedObjectCounterRadius startAngle:270.0 endAngle:90.0];
        [path lineToPoint:NSMakePoint(myRect.origin.x + kPSMUnifiedObjectCounterRadius, myRect.origin.y + myRect.size.height)];
        [path appendBezierPathWithArcWithCenter:NSMakePoint(myRect.origin.x + kPSMUnifiedObjectCounterRadius, myRect.origin.y + kPSMUnifiedObjectCounterRadius) radius:kPSMUnifiedObjectCounterRadius startAngle:90.0 endAngle:270.0];
        [path fill];
        
        // draw attributed string centered in area
        NSRect counterStringRect;
        NSAttributedString *counterString = [self attributedObjectCountValueForTabCell:cell];
        counterStringRect.size = [counterString size];
        counterStringRect.origin.x = myRect.origin.x + ((myRect.size.width - counterStringRect.size.width) / 2.0) + 0.25;
        counterStringRect.origin.y = myRect.origin.y + ((myRect.size.height - counterStringRect.size.height) / 2.0) + 0.5;
        [counterString drawInRect:counterStringRect];
    }
    
    // label rect
    NSRect labelRect;
    labelRect.origin.x = labelPosition;
    labelRect.size.width = cellFrame.size.width - (labelRect.origin.x - cellFrame.origin.x) - kPSMTabBarCellPadding;
	NSSize s = [[cell attributedStringValue] size];
	labelRect.origin.y = cellFrame.origin.y + (cellFrame.size.height-s.height)/2.0 + 2.0;
	labelRect.size.height = s.height;
    
    if(![[cell indicator] isHidden])
        labelRect.size.width -= (kPSMTabBarIndicatorWidth + kPSMTabBarCellPadding);
    
    if([cell count] > 0)
        labelRect.size.width -= ([self objectCounterRectForTabCell:cell].size.width + kPSMTabBarCellPadding);
    
    // label
    [[cell attributedStringValue] drawInRect:labelRect];
}

- (void)drawBackgroundInRect:(NSRect)rect
{
	NSRect gradientRect = rect;
	gradientRect.size.height -= 1.0;
    NSBezierPath *path = [NSBezierPath bezierPathWithRect:gradientRect];
    [path linearGradientFillWithStartColor:[NSColor colorWithCalibratedWhite:0.80 alpha:1.0]
                              endColor:[NSColor colorWithCalibratedWhite:0.84 alpha:1.0]];
    [[NSColor colorWithCalibratedWhite:0.576 alpha:1.0] set];
    [NSBezierPath strokeLineFromPoint:NSMakePoint(rect.origin.x, NSMaxY(rect) - 0.5)
                              toPoint:NSMakePoint(NSMaxX(rect), NSMaxY(rect) - 0.5)];
}

- (void)drawTabBar:(PSMTabBarControl *)bar inRect:(NSRect)rect
{
	tabBar = bar;
	[self drawBackgroundInRect:rect];
	
    // no tab view == not connected
    if(![bar tabView]){
        NSRect labelRect = rect;
        labelRect.size.height -= 4.0;
        labelRect.origin.y += 4.0;
        NSMutableAttributedString *attrStr;
        NSString *contents = @"PSMTabBarControl";
        attrStr = [[[NSMutableAttributedString alloc] initWithString:contents] autorelease];
        NSRange range = NSMakeRange(0, [contents length]);
        [attrStr addAttribute:NSFontAttributeName value:[NSFont systemFontOfSize:11.0] range:range];
        NSMutableParagraphStyle *centeredParagraphStyle = nil;
        if (!centeredParagraphStyle) {
            centeredParagraphStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] retain];
            [centeredParagraphStyle setAlignment:NSCenterTextAlignment];
        }
        [attrStr addAttribute:NSParagraphStyleAttributeName value:centeredParagraphStyle range:range];
        [attrStr drawInRect:labelRect];
        return;
    }
    
    // draw cells
    PSMTabBarCell *cell=nil;
    NSEnumerator *e = [[bar cells] objectEnumerator];
    while ( (cell = [e nextObject]) ) {
        if ([cell isPlaceholder]) {
            [cell drawWithFrame:[cell frame] inView:bar];
        }
    }
    e = [[bar cells] objectEnumerator];
    while ( (cell = [e nextObject]) ) {
        if (![cell isInOverflowMenu] && NSIntersectsRect([cell frame], rect) && ![cell isPlaceholder]) {
            [cell drawWithFrame:[cell frame] inView:bar];
        }
    }

}   	

#pragma mark -
#pragma mark Archiving

- (void)encodeWithCoder:(NSCoder *)aCoder 
{
    //[super encodeWithCoder:aCoder];
    if ([aCoder allowsKeyedCoding]) {
        [aCoder encodeObject:unifiedCloseButton forKey:@"unifiedCloseButton"];
        [aCoder encodeObject:unifiedCloseButtonDown forKey:@"unifiedCloseButtonDown"];
        [aCoder encodeObject:unifiedCloseButtonOver forKey:@"unifiedCloseButtonOver"];
        [aCoder encodeObject:unifiedCloseDirtyButton forKey:@"unifiedCloseDirtyButton"];
        [aCoder encodeObject:unifiedCloseDirtyButtonDown forKey:@"unifiedCloseDirtyButtonDown"];
        [aCoder encodeObject:unifiedCloseDirtyButtonOver forKey:@"unifiedCloseDirtyButtonOver"];
        [aCoder encodeObject:_addTabButtonImage forKey:@"addTabButtonImage"];
        [aCoder encodeObject:_addTabButtonPressedImage forKey:@"addTabButtonPressedImage"];
        [aCoder encodeObject:_addTabButtonRolloverImage forKey:@"addTabButtonRolloverImage"];
    }
}

- (id)initWithCoder:(NSCoder *)aDecoder 
{
   // self = [super initWithCoder:aDecoder];
    //if (self) {
        if ([aDecoder allowsKeyedCoding]) {
            unifiedCloseButton = [[aDecoder decodeObjectForKey:@"unifiedCloseButton"] retain];
            unifiedCloseButtonDown = [[aDecoder decodeObjectForKey:@"unifiedCloseButtonDown"] retain];
            unifiedCloseButtonOver = [[aDecoder decodeObjectForKey:@"unifiedCloseButtonOver"] retain];
            unifiedCloseDirtyButton = [[aDecoder decodeObjectForKey:@"unifiedCloseDirtyButton"] retain];
            unifiedCloseDirtyButtonDown = [[aDecoder decodeObjectForKey:@"unifiedCloseDirtyButtonDown"] retain];
            unifiedCloseDirtyButtonOver = [[aDecoder decodeObjectForKey:@"unifiedCloseDirtyButtonOver"] retain];
            _addTabButtonImage = [[aDecoder decodeObjectForKey:@"addTabButtonImage"] retain];
            _addTabButtonPressedImage = [[aDecoder decodeObjectForKey:@"addTabButtonPressedImage"] retain];
            _addTabButtonRolloverImage = [[aDecoder decodeObjectForKey:@"addTabButtonRolloverImage"] retain];
        }
    //}
    return self;
}

@end
