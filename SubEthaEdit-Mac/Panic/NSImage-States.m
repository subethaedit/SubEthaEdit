#import "NSImage-States.h"

@implementation NSImage (States)

- (NSImage*)disabledImage
{
	return [self lightenImageWithAlpha:.45];
}


- (NSImage*)pressedImage
{
	return [self darkenImageWithAlpha:.3];
}


- (NSImage*)selectedImage
{
	return [self darkenImageWithAlpha:.5];
}


- (NSImage*)selectedImageLighter
{
	return [self darkenImageWithAlpha:.4];
}


- (NSImage*)darkenImageWithAlpha:(float)alpha
{
	NSImage* image = [[self copy] autorelease];
	BOOL wasFlipped = [self isFlipped];
	
	if ( wasFlipped )
		[self setFlipped:NO];
	
	[image lockFocus];
			
	[[NSColor colorWithCalibratedWhite:0 alpha:alpha] set];  // make sure the color has an alpha component, or we'll get a solid rectangle
	NSRectFillUsingOperation(NSMakeRect(0, 0, [self size].width, [self size].height), NSCompositeSourceAtop); // start drawing on the new image.

	[image unlockFocus];
	
	if ( wasFlipped )
		[self setFlipped:YES];
	
	return image;
}


- (NSImage*)lightenImageWithAlpha:(float)alpha
{
	NSImage* image = [[self copy] autorelease]; 
	BOOL wasFlipped = [self isFlipped];
	
	if ( wasFlipped )
		[self setFlipped:NO];

	[image lockFocus];

	[[NSColor colorWithCalibratedWhite:1.0 alpha:alpha] set];  // make sure the color has an alpha component, or we'll get a solid rectangle
	NSRectFillUsingOperation(NSMakeRect(0, 0, [self size].width, [self size].height), NSCompositeSourceAtop); // start drawing on the new image.
	
	[image unlockFocus];

	if ( wasFlipped ) 
		[self setFlipped:YES];

	return image;
}
@end
