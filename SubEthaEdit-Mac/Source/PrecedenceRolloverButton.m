//  PrecedenceRolloverButton.m
//  SubEthaEdit
//
//  Created by Martin Pittenauer on 01.10.07.

#import "PrecedenceRolloverButton.h"


@implementation PrecedenceRolloverButton {
    NSTrackingRectTag trackingTag;
    BOOL mouseIsIn;
}

- (void)configure {
    mouseIsIn = NO;	
	trackingTag = 0;
}

- (id)initWithFrame:(NSRect)frame  {
    self = [super initWithFrame:frame];
    if (self) {
		[self configure];
    }
    
	return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
		[self configure];
    }
	
    return self;
}

- (void)updateImageHighlight {
    if (mouseIsIn) {
        if (@available(macOS 10.14, *)) {
            self.contentTintColor = NSColor.controlTextColor;
        }
    } else {
        if (@available(macOS 10.14, *)) {
            self.contentTintColor = nil;
        }
    }
}

- (void)mouseEntered:(NSEvent*)anEvent {
	if ([self isEnabled]) {
		mouseIsIn = YES;
        [self updateImageHighlight];
	}
}


- (void)mouseExited:(NSEvent*)theEvent {
	if ([self isEnabled]) {
		mouseIsIn = NO;
        [self updateImageHighlight];
	}
}


- (void)resetCursorRects  {
	[self removeTrackingRect:trackingTag];
	trackingTag = [self addTrackingRect:[self bounds] owner:self userData:nil assumeInside:NO];
}

@end
