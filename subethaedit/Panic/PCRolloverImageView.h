#import <Cocoa/Cocoa.h>

@interface PCRolloverImageView : NSImageView
{
	NSTrackingRectTag	trackingTag;
	NSImage				*altImage;
	BOOL mouseIsIn;
}

- (void)configure;
- (NSImage *)realImage;

@end
