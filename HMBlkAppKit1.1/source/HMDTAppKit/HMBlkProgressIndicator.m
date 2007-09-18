/*
HMBlkProgressIndicator.m

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

#import "HMBlkPanel.h"
#import "HMBlkProgressIndicator.h"

struct NSProgressIndicator_t {
    @defs(NSProgressIndicator)
};

@implementation HMBlkProgressIndicator

//--------------------------------------------------------------//
#pragma mark -- Drawing --
//--------------------------------------------------------------//

- (void)_drawThemeBackground
{
    // Do nothing
}

- (void)_drawThemeProgressArea:(BOOL)flag
{
    // Save graphics state
    [[NSGraphicsContext currentContext] saveGraphicsState];
    
    NSImage*    image;
    NSRect      srcRect, destRect;
    
    // Get bounds
    NSRect  bounds;
    bounds = [self bounds];
    
    // Fill background
    image = [HMBlkPanel contentBackgroundImage];
    
    srcRect.origin = NSZeroPoint;
    srcRect.size = [image size];
    
    [image drawInRect:bounds fromRect:srcRect operation:NSCompositeCopy fraction:1.0f];
    
    // Draw frame
    [[NSColor whiteColor] set];
    NSFrameRect(bounds);
    
    // Clip rect
    [NSBezierPath clipRect:NSInsetRect(bounds, 1.0f, 1.0f)];
    
    // Get bundle
    NSBundle*   bundle;
    bundle = [NSBundle bundleForClass:[self class]];
    
    // For indeterminate
    if ([self isIndeterminate]) {
        image = [[[NSImage alloc] initWithContentsOfFile:
                [bundle pathForImageResource:@"blkProgressIndeterminate"]] autorelease];
        [image setFlipped:[self isFlipped]];
        
        srcRect.origin = NSZeroPoint;
        srcRect.size = [image size];
        
        NSPoint point;
        point.y = 1;
        point.x = -32 + ((struct NSProgressIndicator_t*)self)->_animationIndex;
        while (point.x < bounds.size.width) {
            [image drawAtPoint:point fromRect:srcRect 
                    operation:NSCompositeSourceOver fraction:1.0f];
            point.x += 16;
        }
    }
    
    // For progress bar
    else {
        // Calc progress
        float   progress = 0.0f;
        if ([self maxValue] - [self minValue] > 0) {
            progress = ([self doubleValue] - [self minValue]) / 
                    ([self maxValue] - [self minValue]);
        }
        
        // Draw background
        image = [[[NSImage alloc] initWithContentsOfFile:
                [bundle pathForImageResource:@"blkProgressBack"]] autorelease];
        [image setFlipped:[self isFlipped]];
        
        srcRect.origin = NSZeroPoint;
        srcRect.size = [image size];
        
        destRect.origin.x = 1;
        destRect.origin.y = 1;
        destRect.size.width = bounds.size.width - 2;
        destRect.size.height = srcRect.size.height - 2;
        
        [image drawInRect:destRect fromRect:srcRect 
                operation:NSCompositeSourceOver fraction:1.0f];
        
        // Draw progress
        image = [[[NSImage alloc] initWithContentsOfFile:
                [bundle pathForImageResource:@"blkProgressBar"]] autorelease];
        [image setFlipped:[self isFlipped]];
        
        srcRect.origin = NSZeroPoint;
        srcRect.size = [image size];
        
        destRect.origin.x = 1;
        destRect.origin.y = 1;
        destRect.size.width = (bounds.size.width - 2) * progress;
        destRect.size.height = srcRect.size.height;
        
        [image drawInRect:destRect fromRect:srcRect 
                operation:NSCompositeSourceOver fraction:1.0f];
    }
    
    // Restore graphics state
    [[NSGraphicsContext currentContext] restoreGraphicsState];
}

@end
