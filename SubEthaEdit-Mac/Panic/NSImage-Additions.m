#import "NSImage-Additions.h"

/*
#import "zlib.h"

#import <Carbon/Carbon.h>


BOOL
do_compress(unsigned char* inData, unsigned long inSize, unsigned char** outDataPtr, unsigned long* outSizePtr);

BOOL
do_decompress(unsigned char* sourceData, unsigned long sourceSize, unsigned char* data, int dataSize);
*/

@implementation NSImage (Additions)

/*
+ (NSImage*)imageWithCompressedData:(NSData*)data length:(unsigned long)size forWidth:(int)width
{
	NSImage *resultImage = nil;
	unsigned char* decompressedData = malloc(size);
	
	if ( do_decompress((unsigned char*)[data bytes], [data length], decompressedData, size) )
	{
		NSBitmapImageRep *aRep = [[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&decompressedData pixelsWide:width pixelsHigh:width bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace bytesPerRow:(4 * width) bitsPerPixel:0] autorelease];
		

		if ( aRep )
		{
			resultImage = [[[NSImage alloc] initWithSize:[aRep size]] autorelease];
			[resultImage addRepresentation: aRep];
		}
	}
	
	return resultImage;
}
*/

- (NSImage*)duplicateAsBitmapWithSize:(NSSize)size usingInterpolation:(NSImageInterpolation)interpolation
{
	NSImage *image = [self duplicateWithSize:size usingInterpolation:interpolation];

	return [image duplicateAsBitmap];
}


- (NSImage*)duplicateAsBitmapWithSize:(NSSize)size
{
	NSImage *image = [self duplicateWithSize:size];

	return [image duplicateAsBitmap];
}


- (NSImage*)duplicateAsBitmap
{
	 return [[[NSImage alloc] initWithData:[self TIFFRepresentation]] autorelease];
}


- (NSImage*)duplicateWithSize:(NSSize)size
{
	NSImage *resultImage = [[[NSImage alloc] initWithSize:size] autorelease];
	BOOL isFlipped = [self isFlipped];
	NSImageRep *aRep = [self repBestMatchingRect:NSMakeRect(0,0,size.width, size.height)];
	
	if ( isFlipped )
		[self setFlipped:NO];
	
	[resultImage lockFocus];
			[aRep drawInRect:NSMakeRect(0,0,size.width,size.height)];
	[resultImage unlockFocus];
		
	[self setFlipped:isFlipped];
	
	return resultImage;
}


- (NSImage*)duplicateWithSize:(NSSize)size usingInterpolation:(NSImageInterpolation)interpolation
{
	NSGraphicsContext* graphicsContext = [NSGraphicsContext currentContext];
	BOOL wasAntialiasing = [graphicsContext shouldAntialias];
    NSImageInterpolation previousImageInterpolation = [graphicsContext imageInterpolation];
	NSImage *resultImage = nil;

	[graphicsContext setShouldAntialias:YES];
	[graphicsContext setImageInterpolation:interpolation];

	resultImage = [self duplicateWithSize:size];

	[graphicsContext setShouldAntialias:wasAntialiasing];
	[graphicsContext setImageInterpolation:previousImageInterpolation];
	
	return resultImage;
}


- (NSImage*)duplicate
{
	NSImage *resultImage = [[[NSImage alloc] initWithSize:[self size]] autorelease];
		
	[resultImage lockFocus];
		[self dissolveToPoint:NSZeroPoint fraction:1.0];
	[resultImage unlockFocus];
	
	return resultImage;
}

/*
- (NSData*)compressedData:(unsigned long*)ioSize
{
	NSImageRep *aRep = [[self representations] objectAtIndex:0];
	NSSize 	repSize;
	NSData 	*returnData = nil;
	unsigned char *outData;
	unsigned long outSize;
	
	if ( ![aRep isKindOfClass:[NSBitmapImageRep class]] )
	{
		NSData *tiff = [self TIFFRepresentation];
		aRep = [NSBitmapImageRep imageRepWithData:tiff];
	}
	
	repSize = [aRep size];

	*ioSize = [(NSBitmapImageRep*)aRep bytesPerRow] * repSize.height;
	
	if ( do_compress([(NSBitmapImageRep*)aRep bitmapData], *ioSize, &outData, &outSize) )
		returnData = [NSData dataWithBytesNoCopy:outData length:outSize];
		
	return returnData;
}
*/

- (BOOL)isPDF
{	
	NSArray *reps = [self representations];
	BOOL result = NO;
	
	if ( reps && [reps count] > 0 )
	{
		if ( [[reps objectAtIndex:0] isKindOfClass:[NSPDFImageRep class]] )
			result = YES;
	}
	
	return result;
}


- (void)putOnPasteboardAsPDF
{
	NSSize size = [self size];
	NSImageView *tempView = [[[NSImageView alloc] initWithFrame:NSMakeRect(0,0,size.width,size.height)] autorelease];

	[tempView setImageFrameStyle:NSImageFrameNone];
	[tempView setImageScaling:NSScaleNone];
	
	[tempView setImage:self];
	
	NSData *PDFData = [tempView dataWithPDFInsideRect:[tempView bounds]];
	NSPasteboard *pboard = [NSPasteboard generalPasteboard];
	
	[pboard declareTypes:[NSArray arrayWithObject:NSPDFPboardType] owner:nil];
	[pboard setData:PDFData forType:NSPDFPboardType];
}


- (void)putOnPasteboardAsPDFandTIFF
{
	NSBitmapImageRep *bitmapRep = nil;
	NSImageRep *rep = [[self representations] objectAtIndex:0];
	NSPasteboard *pboard = [NSPasteboard generalPasteboard];
		
	// put TIFF data on clipboard
	
	if ( [rep isKindOfClass:[NSBitmapImageRep class]] )
		bitmapRep = (NSBitmapImageRep*)rep;
	else
	{
		NSData *tiff = [self TIFFRepresentation];
		bitmapRep = [NSBitmapImageRep imageRepWithData:tiff];
	}
	
	NSData *scrapData = [bitmapRep representationUsingType:NSTIFFFileType properties:nil];
	
	[pboard declareTypes:[NSArray arrayWithObjects:NSTIFFPboardType, NSPDFPboardType, nil] owner:nil];

	if ( scrapData )
		[pboard setData:scrapData forType:NSTIFFPboardType];
		
	// put PDF data on clipboard
	
	NSSize size = [self size];
	NSImageView *tempView = [[[NSImageView alloc] initWithFrame:NSMakeRect(0,0,size.width,size.height)] autorelease];

	[tempView setImageFrameStyle:NSImageFrameNone];
	[tempView setImageScaling:NSScaleNone];
	
	[tempView setImage:self];
	
	NSData *PDFData = [tempView dataWithPDFInsideRect:[tempView bounds]];
	
	if ( PDFData )
		[pboard setData:PDFData forType:NSPDFPboardType];
}


- (NSImageRep*) repBestMatchingRect:(NSRect)rect
{
    NSEnumerator* repEnum = [[self representations] objectEnumerator];
    NSImageRep*	currentRep = nil;
    NSImageRep* bestRep = nil;
    NSImageRep* largestRep = nil;
    float sizeDiff = 1000000000.0; //large num ;-)
    float largestRepSize = 0.0;
    
    while( (currentRep = [repEnum nextObject]) != nil )
    {
        NSSize currentRepSize = [currentRep size];
        
        if( abs(currentRepSize.width - NSWidth(rect)) < sizeDiff && currentRepSize.width - NSWidth(rect) >= 0 )
        {
            sizeDiff = currentRepSize.width - NSWidth(rect);
            bestRep = currentRep;
        }
        
        if( currentRepSize.width > largestRepSize )
        {
            largestRepSize = currentRepSize.width;
            largestRep = currentRep;
        }
    }
    
    if( !bestRep )
    {
        bestRep = largestRep;
    }
    
    return bestRep;
}


- (NSSize)pixelSize
{
	NSArray *reps = [self representations];
	NSSize imageSize;

	if ( [self isPDF] )
	{
		imageSize = [[reps objectAtIndex:0] bounds].size;
	}
	else
	{
		
		if ( [reps count] > 0 )
		{
			NSImageRep *rep = [reps objectAtIndex:0];
		
			imageSize.width = [rep pixelsWide];
			imageSize.height = [rep pixelsHigh];
		}
		else
			imageSize = [self size];
	}
	
	return imageSize;
}


- (void)drawFlippedInRect:(NSRect)dstRect fromRect:(NSRect)srcRect operation:(NSCompositingOperation)op fraction:(float)delta
{
	NSAffineTransform *flipTransform = [NSAffineTransform transform];
	NSRect translatedRect = dstRect;
	
	[NSGraphicsContext saveGraphicsState];

	[flipTransform translateXBy:dstRect.origin.x yBy:NSMaxY(dstRect)];
	[flipTransform scaleXBy:1.0 yBy:-1.0];
	[flipTransform concat];
	
	translatedRect.origin = NSZeroPoint;
	
	[self drawInRect:translatedRect fromRect:srcRect operation:op fraction:delta];

	[NSGraphicsContext restoreGraphicsState];
}


- (void)drawFlippedInRect:(NSRect)dstRect
{
	[self drawFlippedInRect:dstRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];	
}


- (void)drawFlippedInRect:(NSRect)rect inView:(NSView*)aView operation:(NSCompositingOperation)op fraction:(float)delta
{
	// This method should only be called if the image being drawn fits the view
	// completely, otherwise it won't work.
	
	NSRect translatedRect = rect;
	NSRect bounds = [aView bounds];

	translatedRect.origin.y = bounds.size.height - (rect.origin.y + rect.size.height);
	
	[self drawFlippedInRect:rect fromRect:translatedRect operation:op fraction:delta];
}


- (void)drawFlippedInRect:(NSRect)rect inView:(NSView*)aView
{
	// This method should only be called if the image being drawn fits the view
	// completely, otherwise it won't work.
	
	[self drawFlippedInRect:rect inView:aView operation:NSCompositeSourceOver fraction:1.0];
}


- (void)drawFlippedHorizontallyInRect:(NSRect)dstRect
{
	[self drawFlippedHorizontallyInRect:dstRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];	
}


- (void)drawFlippedHorizontallyInRect:(NSRect)dstRect fromRect:(NSRect)srcRect operation:(NSCompositingOperation)op fraction:(float)delta
{
	NSAffineTransform *flipTransform = [NSAffineTransform transform];
	NSRect translatedRect = dstRect;
	
	[NSGraphicsContext saveGraphicsState];

	[flipTransform translateXBy:NSMaxX(dstRect) yBy:dstRect.origin.y];
	[flipTransform scaleXBy:-1.0 yBy:1.0];
	[flipTransform concat];
	
	translatedRect.origin = NSZeroPoint;
	
	[self drawInRect:translatedRect fromRect:srcRect operation:op fraction:delta];

	[NSGraphicsContext restoreGraphicsState];
}


@end

/*
BOOL
do_compress(unsigned char* inData, unsigned long inSize, unsigned char** outDataPtr, unsigned long* outSizePtr)
{
	unsigned long outSize = (unsigned long)floor(inSize*1.01 + 12);
	unsigned char* outData = malloc(outSize);

	int res = compress2(outData, &outSize, inData, inSize, 7); // 9 is best, 0 is worst

	if ( res != Z_OK )
	{
		free(outData);
		return NO;
	}

	*outDataPtr = outData;
	*outSizePtr = outSize;

	return YES;
}


BOOL
do_decompress(unsigned char* sourceData, unsigned long sourceSize, unsigned char* data, int dataSize)
{
	unsigned long outSize = dataSize;

	int res = uncompress(data, &outSize, sourceData, sourceSize);

	return (res == Z_OK && outSize == dataSize);
}
*/