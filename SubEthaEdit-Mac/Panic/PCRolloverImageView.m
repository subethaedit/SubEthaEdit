#import "PCRolloverImageView.h"
#import "NSBezierPath-Arrow.h"
#import "NSImage-States.h"
#import "NSImageTCMAdditions.h"

@implementation PCRolloverImageView

- (id)initWithFrame:(NSRect)frame 
{
    self = [super initWithFrame:frame];
    if (self) 
	{
		[self configure];
    }
    
	return self;
}


- (id)initWithCoder:(NSCoder*)coder
{
    self = [super initWithCoder:coder];
    if (self) 
	{
		[self configure];
    }
	
    return self;
}


- (void)configure
{
    mouseIsIn = NO;
	[self setImageFrameStyle:NSImageFrameGrayBezel];
	[self setPostsFrameChangedNotifications:YES];
	
	trackingTag = 0;
}


- (void)drawRect:(NSRect)rect 
{
	[super drawRect:rect];
	
	if ( [[self cell] isHighlighted] )
	{
		NSBezierPath *path = [NSBezierPath arrowInRect:NSMakeRect(rect.size.width - 19, 9, 10, 8) pointEdge:NSMinYEdge];
		
		[[NSColor whiteColor] set];
		
		[[NSGraphicsContext currentContext] saveGraphicsState];
		
		NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
		
		[shadow setShadowColor:[NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.0 alpha:.4]];
		[shadow setShadowOffset:NSMakeSize(0.0, -1.0)];
		[shadow setShadowBlurRadius:2.0];
		
		[shadow set];
		[path fill];
		
		[[NSGraphicsContext currentContext] restoreGraphicsState];
	
	}
	

}


- (void)mouseDown:(NSEvent*)anEvent
{
	NSMenu	*menu = [self menu];
	
	if ( menu )
	{
		NSPoint	location = [anEvent locationInWindow];
		NSPoint localPoint = [self convertPoint:location fromView:nil];

		location.x -= localPoint.x;
		location.y -= localPoint.y;
	
		NSEvent *newEvent = [NSEvent mouseEventWithType:[anEvent type] location:location
						modifierFlags:[anEvent modifierFlags] 
						timestamp:[anEvent timestamp] windowNumber:[anEvent windowNumber] context:[anEvent context] 
						eventNumber:[anEvent eventNumber]
						clickCount:[anEvent clickCount] pressure:[anEvent pressure]];
	
		[NSMenu popUpContextMenu:menu withEvent:newEvent forView:self];
	}
}


- (void)mouseEntered:(NSEvent*)anEvent
{
	if ( [self isEnabled] )
	{
	   mouseIsIn = YES;
		[[self cell] setHighlighted:YES];
		
		NSImage	*curImage = [[self image] retain];
		[altImage setFlipped:NO];
		[super setImage:altImage];

		[altImage release];
		altImage = curImage;
	}
}


- (void)mouseExited:(NSEvent*)theEvent
{
	if ( [self isEnabled] )
	{
	   mouseIsIn = NO;
		[[self cell] setHighlighted:NO];

		NSImage	*curImage = [[self image] retain];
		[altImage setFlipped:NO];
		[super setImage:altImage];

		[altImage release];
		altImage = curImage;
	}
}


- (void)resetCursorRects 
{
	[self removeTrackingRect:trackingTag];
	
	trackingTag = [self addTrackingRect:[self bounds] owner:self userData:nil assumeInside:NO];
}

#define MAXSIZE 256
- (void)setImage:(NSImage*)inImage
{
    if ([inImage size].width > MAXSIZE || [inImage size].height > MAXSIZE) {
        inImage = [inImage resizedImageWithSize:NSMakeSize(MAXSIZE,MAXSIZE)];
    }
	[altImage release];
	
	altImage = [[inImage pressedImage] retain];

	[[self cell] setHighlighted:NO];
	if (!mouseIsIn) {
    	[super setImage:inImage];
    } else {
        [super setImage:[altImage autorelease]];
        altImage = [inImage retain];
    }
}

- (NSImage *)realImage {
    if (mouseIsIn) return altImage;
    else return [self image];
}

- (void)dealloc
{
	[altImage release];
	
	[super dealloc];

}


@end
