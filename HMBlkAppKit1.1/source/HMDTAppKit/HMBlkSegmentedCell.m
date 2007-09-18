/*
HMBlkSegmentedCell.m

Author: Makoto Kinoshita

Copyright 2004-2006 The Shiira Project. All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted 
provided that the following conditions are met:

  1. Redistributions of source code must retain the above copyright notice, this list of conditions 
  and the following disclaimer.

  2. Redistributions in binary form must reproduce the above copyright notice, this list of 
  conditions and the following disclaimer in the documentation and/or other materials provided 
  with the distribution.

THIS SOFTWARE IS PROVIDED BY THE SHIIRA PROJECT ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, 
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR 
PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE SHIIRA PROJECT OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, 
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING 
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
POSSIBILITY OF SUCH DAMAGE.
*/

#import "HMBlkSegmentedCell.h"

static NSImage* _segmentLeftImage = nil;
static NSImage* _segmentMiddleImage = nil;
static NSImage* _segmentRightImage = nil;
static NSImage* _segmentSelectedLeftImage = nil;
static NSImage* _segmentSelectedMiddleImage = nil;
static NSImage* _segmentSelectedRightImage = nil;
static NSImage* _segmentDividerImage = nil;

static NSRect   _segmentLeftRect = {{0, 0}, {0, 0}};
static NSRect   _segmentMiddleRect = {{0, 0}, {0, 0}};
static NSRect   _segmentRightRect = {{0, 0}, {0, 0}};
static NSRect   _segmentSelectedLeftRect = {{0, 0}, {0, 0}};
static NSRect   _segmentSelectedMiddleRect = {{0, 0}, {0, 0}};
static NSRect   _segmentSelectedRightRect = {{0, 0}, {0, 0}};
static NSRect   _segmentDividerRect = {{0, 0}, {0, 0}};

static NSDictionary*    _labelAttr = nil;
static NSDictionary*    _selectedLabelAttr = nil;

@interface NSSegmentedCell (private)
- (int)_trackingSegment;
- (NSRect)_rectForSegment:(int)segment inFrame:(NSRect)frame;
@end

@implementation HMBlkSegmentedCell

//--------------------------------------------------------------//
#pragma mark -- Initialize --
//--------------------------------------------------------------//

+ (void)load
{
    NSAutoreleasePool*  pool;
    pool = [[NSAutoreleasePool alloc] init];
    
    // Get resources
    if (!_segmentLeftImage) {
        NSBundle*   bundle;
        bundle = [NSBundle bundleForClass:[self class]];
    
        _segmentLeftImage = [[NSImage alloc] initWithContentsOfFile:
                [bundle pathForImageResource:@"blkSegmentL"]];
        _segmentMiddleImage = [[NSImage alloc] initWithContentsOfFile:
                [bundle pathForImageResource:@"blkSegmentM"]];
        _segmentRightImage = [[NSImage alloc] initWithContentsOfFile:
                [bundle pathForImageResource:@"blkSegmentR"]];
        _segmentSelectedLeftImage = [[NSImage alloc] initWithContentsOfFile:
                [bundle pathForImageResource:@"blkSegmentSelectedL"]];
        _segmentSelectedMiddleImage = [[NSImage alloc] initWithContentsOfFile:
                [bundle pathForImageResource:@"blkSegmentSelectedM"]];
        _segmentSelectedRightImage = [[NSImage alloc] initWithContentsOfFile:
                [bundle pathForImageResource:@"blkSegmentSelectedR"]];
        _segmentDividerImage = [[NSImage alloc] initWithContentsOfFile:
                [bundle pathForImageResource:@"blkSegmentDivider"]];
        
        _segmentLeftRect.size = [_segmentLeftImage size];
        _segmentMiddleRect.size = [_segmentMiddleImage size];
        _segmentRightRect.size = [_segmentRightImage size];
        _segmentSelectedLeftRect.size = [_segmentSelectedLeftImage size];
        _segmentSelectedMiddleRect.size = [_segmentSelectedMiddleImage size];
        _segmentSelectedRightRect.size = [_segmentSelectedRightImage size];
        _segmentDividerRect.size = [_segmentDividerImage size];
        
        // Create attributes
        NSShadow*   shadow;
        shadow = [[NSShadow alloc] init];
        [shadow setShadowColor:[NSColor blackColor]];
        [shadow setShadowBlurRadius:0.0f];
        [shadow setShadowOffset:NSMakeSize(0, 1.0)];
        
        NSMutableParagraphStyle*    paragraph;
        paragraph = [[NSMutableParagraphStyle alloc] init];
        [paragraph setLineBreakMode:NSLineBreakByTruncatingTail];
        [paragraph setAlignment:NSCenterTextAlignment];
        
        _labelAttr = [[NSDictionary dictionaryWithObjectsAndKeys:
                [NSFont systemFontOfSize:[NSFont smallSystemFontSize]], NSFontAttributeName, 
                [NSColor whiteColor], NSForegroundColorAttributeName, 
                //shadow, NSShadowAttributeName, 
                paragraph, NSParagraphStyleAttributeName, nil] retain];
        [shadow release];
        
        shadow = [[NSShadow alloc] init];
        [shadow setShadowColor:[NSColor grayColor]];
        [shadow setShadowBlurRadius:0.0f];
        [shadow setShadowOffset:NSMakeSize(0, -1.0)];
        
        _selectedLabelAttr = [[NSDictionary dictionaryWithObjectsAndKeys:
                [NSFont systemFontOfSize:[NSFont smallSystemFontSize]], NSFontAttributeName, 
                [NSColor whiteColor], NSForegroundColorAttributeName, 
                //shadow, NSShadowAttributeName, 
                paragraph, NSParagraphStyleAttributeName, nil] retain];
        [shadow release];
        [paragraph release];
    }
    
    [pool release];
}

//--------------------------------------------------------------//
#pragma mark -- Drawing --
//--------------------------------------------------------------//

- (void)drawWithFrame:(NSRect)frame inView:(NSView*)controlView
{
	// Check sement count
	if ([self segmentCount] == 0) {
		return;
	}
	
	// Check view filp
	BOOL	isViewFlipped;
	isViewFlipped = [controlView isFlipped];
	
	// Save graphics state
	[[NSGraphicsContext currentContext] saveGraphicsState];
	
	// Prepare for drawing
	NSRect	rect, srcRect;
	
	// Decide fraction
	float	fraction;
	fraction = 1.0f;
	if (![self isEnabled]) {
		fraction = 0.5f;
	}
    
	// Get tracking segment
	int	trackingSegment = 0;
	if ([self respondsToSelector:@selector(_trackingSegment)]) {
		trackingSegment = [self _trackingSegment];
	}
	
    //
    // Draw background
    //
    
	// Decide left image
	NSImage*	leftImage;
	leftImage = [self isSelectedForSegment:0] ? _segmentSelectedLeftImage : _segmentLeftImage;
	
	// Draw left
	if (leftImage) {
		// Check image filp
		if ([leftImage isFlipped] != isViewFlipped) {
			[leftImage setFlipped:isViewFlipped];
		}
		
		// Create highlighted image
#if 0
		if (trackingSegment == 0) {
			leftImage = ESCCHighlightImage(leftImage);
		}
#endif
		
		// Draw image
		rect.origin.x = frame.origin.x;
		rect.origin.y = frame.origin.y;
		rect.size = [leftImage size];
		srcRect.origin = NSZeroPoint;
		srcRect.size = rect.size;
		[leftImage drawInRect:rect fromRect:srcRect operation:NSCompositeSourceOver fraction:fraction];
	}
	
	// Decide right image
	int			segment;
	NSImage*	rightImage;
	segment = [self segmentCount] - 1;
	rightImage = [self isSelectedForSegment:segment] ? _segmentSelectedRightImage : _segmentRightImage;
	
	// Draw right
	if (rightImage) {
		// Get segment rect
		NSRect	segmentRect;
		segmentRect = [self _rectForSegment:segment inFrame:frame];
		
		// Check image filp
		if ([rightImage isFlipped] != isViewFlipped) {
			[rightImage setFlipped:isViewFlipped];
		}
		
		// Create highlighted image
#if 0
		if (trackingSegment == segment) {
			rightImage = ESCCHighlightImage(rightImage);
		}
#endif
		
		// Draw image
		rect.origin.x = segmentRect.origin.x + segmentRect.size.width - [rightImage size].width;
		rect.origin.y = segmentRect.origin.y;
		rect.size = [rightImage size];
		srcRect.origin = NSZeroPoint;
		srcRect.size = rect.size;
		[rightImage drawInRect:rect fromRect:srcRect operation:NSCompositeSourceOver fraction:fraction];
	}
	
	// Draw middle and segment
	int	i;
	for (i = 0; i < [self segmentCount]; i++) {
		NSImage*	image;
		
		// Get segment rect
		NSRect	segmentRect;
		segmentRect = [self _rectForSegment:i inFrame:frame];
		
		// Decide middle images
		image = [self isSelectedForSegment:i] ? _segmentSelectedMiddleImage : _segmentMiddleImage;
		
		// Draw middle
		if (image) {
			// Check image filp
			if ([image isFlipped] != isViewFlipped) {
				[image setFlipped:isViewFlipped];
			}
			
			// Create highlighted image
#if 0
			if (trackingSegment == i) {
				image = ESCCHighlightImage(image);
			}
#endif
			
			// Draw image
			rect = segmentRect;
			if (i == 0) {
				// Subtract left image width
				rect.origin.x += [leftImage size].width;
				rect.size.width -= [leftImage size].width;
			}
			
			if (i == [self segmentCount] - 1) {
				// Subtract right image width
				rect.size.width -= [rightImage size].width;
			}
			else {
				// For segment line
				rect.size.width -= 1;
			}
			
#if 0
			// Create highlighted image
			if (trackingSegment == i) {
				image = ESCCHighlightImage(image);
			}
#endif
			
			// Draw image
			rect.origin.y = frame.origin.y;
			rect.size.height = [image size].height;
			srcRect.origin = NSZeroPoint;
			srcRect.size = [image size];
			[image drawInRect:rect fromRect:srcRect operation:NSCompositeSourceOver fraction:fraction];
		}
		
		if (i == [self segmentCount] - 1) {
			continue;
		}
		
		// Decide divider image
		image = _segmentDividerImage;
		
		// Draw segment
		if (image) {
			// Check image filp
			if ([image isFlipped] != isViewFlipped) {
				[image setFlipped:isViewFlipped];
			}
			
			// Draw image
			rect.origin.x = segmentRect.origin.x + segmentRect.size.width - 1;
            rect.origin.y = segmentRect.origin.y;
			rect.size = [image size];
			srcRect.origin = NSZeroPoint;
			srcRect.size = rect.size;
			[image drawInRect:rect fromRect:srcRect operation:NSCompositeSourceOver fraction:fraction];
		}
	}
	
    //
    // Draw label
    //
    
    for (i = 0; i < [self segmentCount]; i++) {
        // Create attributed string
        NSString*           label;
        NSAttributedString* attrStr;
        label = [self labelForSegment:i];
        if ([self isSelectedForSegment:i]) {
            attrStr = [[NSAttributedString alloc] initWithString:label attributes:_selectedLabelAttr];
        }
        else {
            attrStr = [[NSAttributedString alloc] initWithString:label attributes:_labelAttr];
        }
        
        // Get segment rect
        NSRect  segmentRect;
        NSSize  textSize;
        segmentRect = [self _rectForSegment:i inFrame:frame];
        textSize = [attrStr size];
        segmentRect.origin.y += (segmentRect.size.height - textSize.height) / 2.0f - 3;
        segmentRect.size.height = textSize.height;
        
        // Draw text
        [attrStr drawInRect:segmentRect];
        [attrStr release];
    }
    
    // Draw interior
	//[self drawInteriorWithFrame:frame inView:controlView];
	
	// Restore graphics state
	[[NSGraphicsContext currentContext] restoreGraphicsState];
}

@end
