#import <AppKit/AppKit.h>


@interface NSImage (States)

- (NSImage*)disabledImage;
- (NSImage*)pressedImage;
- (NSImage*)selectedImage;
- (NSImage*)selectedImageLighter;

- (NSImage*)darkenImageWithAlpha:(float)alpha;
- (NSImage*)lightenImageWithAlpha:(float)alpha;

@end
