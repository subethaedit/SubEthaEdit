//  URLBubbleWindow.m
//  SubEthaEdit
//
//  Created by dom on 13.07.09.

#import "URLBubbleWindow.h"

static URLBubbleWindow *S_sharedInstance;


@implementation URLBubbleWindow

+ (URLBubbleWindow *)sharedURLBubbleWindow {
	if (!S_sharedInstance) {
		S_sharedInstance = [[self alloc] initAsBubble]; 
	}
	return S_sharedInstance;
}

- (instancetype)initAsBubble {
	// load nib
	[[NSBundle mainBundle] loadNibNamed:@"URLBubbleWindow" owner:self topLevelObjects:nil];
	
	if ((self = [self initWithView:self.openURLViewOutlet
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
	NSLog(@"%s now i would open: %@",__FUNCTION__,_URLToOpen);
	[[NSWorkspace sharedWorkspace] openURL:_URLToOpen];
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

- (void)setPosition:(NSPoint)inPosition inWindow:(NSWindow *)inWindow {
	if (inWindow != [self parentWindow]) {
		if ([self parentWindow]) {
			[[self parentWindow] removeChildWindow:self];
		}
		[inWindow addChildWindow:self ordered:NSWindowAbove];
	}

	NSRect positionRect = {inPosition, 1.0, 1.0};
	NSRect screenPositionRect = [inWindow convertRectToScreen:positionRect];
	
	[self setPoint:screenPositionRect.origin side:MAPositionTop];
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
