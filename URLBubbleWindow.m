//
//  URLBubbleWindow.m
//  SubEthaEdit
//
//  Created by dom on 13.07.09.
//  Copyright 2009 TheCodingMonkeys. All rights reserved.
//

#import "URLBubbleWindow.h"

static URLBubbleWindow *S_sharedInstance;


@implementation URLBubbleWindow

+ (URLBubbleWindow *)sharedURLBubbleWindow {
	if (!S_sharedInstance) {
		S_sharedInstance = [[self alloc] initAsBubble]; 
	}
	return S_sharedInstance;
}

- (id)initAsBubble {
	// load nib
	[NSBundle loadNibNamed:@"URLBubbleWindow" owner:self];
	
	if ((self = [self initWithView:O_openURLView 
					attachedToPoint:NSMakePoint(0,0)])) {
		[self setBorderWidth:1.0];
		[self setBorderColor:[NSColor colorWithCalibratedWhite:1.0 alpha:0.60]];
		[self setViewMargin:0];
	}
	return self;
}

- (BOOL)canBecomeMainWindow {
	return NO;
}

- (BOOL)canBecomeKeyWindow {
	return NO;
}

- (IBAction)openURLAction:(id)aSender {
	NSLog(@"%s now i would open: %@",__FUNCTION__,I_URLToOpen);
	[[NSWorkspace sharedWorkspace] openURL:I_URLToOpen];
	[self setVisible:NO animated:YES];
}

- (IBAction)hideWindow:(id)aSender {
	[self setVisible:NO animated:YES];
}

- (void)hideIfNecessary {
	if ([self alphaValue] > 0) {
		[self setVisible:NO animated:YES];
	}
}


- (void)setURLToOpen:(NSURL *)inURL {
	[I_URLToOpen autorelease];
	 I_URLToOpen = [inURL copy];
}

- (void)setPosition:(NSPoint)inPosition inWindow:(NSWindow *)inWindow {
	if (inWindow != [self parentWindow]) {
		if ([self parentWindow]) {
			[[self parentWindow] removeChildWindow:self];
		}
		[inWindow addChildWindow:self ordered:NSWindowAbove];
	}
	[self setPoint:[inWindow convertBaseToScreen:inPosition] side:NSMaxYEdge];
}

- (void)setVisible:(BOOL)inVisible animated:(BOOL)inAnimated {
	id target = self;
	if (inAnimated && [self respondsToSelector:@selector(animator)]) {
		target = [self performSelector:@selector(animator)];
	}
	if (inVisible) {
		[target setAlphaValue:1.0];
	} else {
		[target setAlphaValue:0.0];
	}
}


@end
