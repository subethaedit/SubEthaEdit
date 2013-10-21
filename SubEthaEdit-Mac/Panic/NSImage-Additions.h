#import <AppKit/AppKit.h>


@interface NSImage (Additions)

//+ (NSImage*)imageWithCompressedData:(NSData*)data length:(unsigned long)size forWidth:(int)width;
//- (NSData*)compressedData:(unsigned long*)ioSize;

- (NSImage*)duplicateWithSize:(NSSize)size usingInterpolation:(NSImageInterpolation)interpolation;
- (NSImage*)duplicateWithSize:(NSSize)size;

- (NSImage*)duplicateAsBitmapWithSize:(NSSize)size usingInterpolation:(NSImageInterpolation)interpolation;
- (NSImage*)duplicateAsBitmapWithSize:(NSSize)size;
- (NSImage*)duplicateAsBitmap;

- (void)putOnPasteboardAsPDF;
- (void)putOnPasteboardAsPDFandTIFF;
- (BOOL)isPDF;

- (NSImageRep*)repBestMatchingRect:(NSRect)rect;

- (NSSize)pixelSize;

- (void)drawFlippedInRect:(NSRect)dstRect fromRect:(NSRect)srcRect operation:(NSCompositingOperation)op fraction:(float)delta;
- (void)drawFlippedInRect:(NSRect)dstRect;

- (void)drawFlippedInRect:(NSRect)rect inView:(NSView*)aView operation:(NSCompositingOperation)op fraction:(float)delta;
- (void)drawFlippedInRect:(NSRect)rect inView:(NSView*)aView;

- (void)drawFlippedHorizontallyInRect:(NSRect)dstRect fromRect:(NSRect)srcRect operation:(NSCompositingOperation)op fraction:(float)delta;
- (void)drawFlippedHorizontallyInRect:(NSRect)dstRect;

@end
