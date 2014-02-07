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
	NSImage *image = [NSImage imageWithSize:self.size flipped:self.isFlipped drawingHandler:^BOOL(NSRect dstRect) {
		[self drawInRect:dstRect fromRect:NSZeroRect operation:NSCompositeCopy fraction:1.0 respectFlipped:YES hints:nil];

		[[NSColor colorWithCalibratedWhite:0.0 alpha:alpha] set]; // make sure the color has an alpha component, or we'll get a solid rectangle
		NSRectFillUsingOperation(dstRect, NSCompositeSourceAtop); // start drawing on the new image.

		return YES;
	}];
	return image;
}


- (NSImage*)lightenImageWithAlpha:(float)alpha
{
	NSImage *image = [NSImage imageWithSize:self.size flipped:self.isFlipped drawingHandler:^BOOL(NSRect dstRect) {
		[self drawInRect:dstRect fromRect:NSZeroRect operation:NSCompositeCopy fraction:1.0 respectFlipped:YES hints:nil];

		[[NSColor colorWithCalibratedWhite:1.0 alpha:alpha] set]; // make sure the color has an alpha component, or we'll get a solid rectangle
		NSRectFillUsingOperation(dstRect, NSCompositeSourceAtop); // start drawing on the new image.

		return YES;
	}];
	return image;
}
@end
