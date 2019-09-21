//  TCMDragImageView.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 28.03.14.

#import "TCMDragImageView.h"

@interface TCMDragImageView ()
@property (nonatomic) NSPoint dragStartPoint;
@end


@implementation TCMDragImageView

- (instancetype)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

- (void)performDragDelegateCallbackWithSelector:(SEL)selector event:(NSEvent *)anEvent {
	id <TCMDragImageDelegate> dragDelegate = self.dragDelegate;
	if (dragDelegate &&
		[dragDelegate respondsToSelector:selector]) {
		[dragDelegate performSelector:selector withObject:self withObject:anEvent];
	}
}

#pragma clang diagnostic pop


- (void)mouseDown:(NSEvent *)theEvent {
	self.dragStartPoint = [theEvent locationInWindow];
	[self performDragDelegateCallbackWithSelector:@selector(dragImage:mouseDown:) event:theEvent];
}

- (void)mouseDragged:(NSEvent *)theEvent {
	NSPoint currentLocation = theEvent.locationInWindow;
	self.dragDelta = TCMPointDifference(currentLocation, self.dragStartPoint);
	[self performDragDelegateCallbackWithSelector:@selector(dragImage:mouseDragged:) event:theEvent];
	
}

- (void)mouseUp:(NSEvent *)theEvent {
	[self performDragDelegateCallbackWithSelector:@selector(dragImage:mouseUp:) event:theEvent];
}

@end
