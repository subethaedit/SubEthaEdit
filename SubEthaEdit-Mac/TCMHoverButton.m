//
//  TCMHoverButton.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 09.05.14.
//  Copyright (c) 2014 TheCodingMonkeys. All rights reserved.
//

// this file needs arc - add -fobjc-arc in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif


#import "TCMHoverButton.h"


@implementation TCMHoverButton

- (void)setPressedImage:(NSImage *)pressedImage {
	self.alternateImage = pressedImage;
	_pressedImage = pressedImage;
}

- (void)setNormalImage:(NSImage *)normalImage {
	self.image = normalImage;
	_normalImage = normalImage;
}

- (void)setImagesByPrefix:(NSString *)aPrefix {
	self.normalImage = [NSImage imageNamed:[aPrefix stringByAppendingString:@"Normal"]];
	self.hoverImage = [NSImage imageNamed:[aPrefix stringByAppendingString:@"Hover"]];
	self.pressedImage = [NSImage imageNamed:[aPrefix stringByAppendingString:@"Pressed"]];
}

- (void)setAllImages:(NSImage *)anImage {
	self.normalImage = anImage;
	self.hoverImage = anImage;
	self.pressedImage = anImage;
}


#pragma mark -

- (void)mouseEntered:(NSEvent *)theEvent {
	[self setImage:self.hoverImage];
	[super mouseEntered:theEvent];
}

- (void)mouseExited:(NSEvent *)theEvent {
	[self setImage:self.normalImage];
	[super mouseExited:theEvent];
}


#pragma mark -

- (void)addTrackingAreasInRect:(NSRect)cellFrame withUserInfo:(NSDictionary *)userInfo mouseLocation:(NSPoint)mouseLocation {
	
    NSTrackingAreaOptions options = 0;
    BOOL mouseIsInside = NO;
    NSTrackingArea *area = nil;
	
    // ---- add tracking area for hover effect ----
    
    options = NSTrackingEnabledDuringMouseDrag | NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways;
	
    mouseIsInside = NSMouseInRect(mouseLocation, cellFrame, [self isFlipped]);
    if (mouseIsInside) {
        options |= NSTrackingAssumeInside;
    }
    
    // We make the view the owner, and it delegates the calls back to the cell after it is properly setup for the corresponding row/column in the outlineview
    area = [[NSTrackingArea alloc] initWithRect:cellFrame options:options owner:self userInfo:userInfo];
    [self addTrackingArea:area];
}

-(void)updateTrackingAreas {
	
    [super updateTrackingAreas];
    
    // remove all tracking rects
    for (NSTrackingArea *area in [self trackingAreas]) {
        // We have to uniquely identify our own tracking areas
        if ([area owner] == self) {
            [self removeTrackingArea:area];
            
            // restore usual image
            [self setImage:self.normalImage];
        }
    }
	
    // recreate tracking areas and tool tip rects
    NSPoint mouseLocation = [self convertPoint:[[self window] convertScreenToBase:[NSEvent mouseLocation]] fromView:nil];
    
    [self addTrackingAreasInRect:[self bounds] withUserInfo:nil mouseLocation:mouseLocation];
}


@end
