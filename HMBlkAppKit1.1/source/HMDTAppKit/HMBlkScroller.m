/*
HMBlkScroller.m

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

#import "HMBlkScroller.h"
#import "HMBlkPanel.h"

static NSImage* _backHLImage = nil;
static NSImage* _backHMImage = nil;
static NSImage* _backHRLeftImage = nil;
static NSImage* _backHRRightImage = nil;
static NSImage* _backVTImage = nil;
static NSImage* _backVMImage = nil;
static NSImage* _backVBUpImage = nil;
static NSImage* _backVBUpSelectedImage = nil;
static NSImage* _backVBDownImage = nil;
static NSImage* _backVBDownSelectedImage = nil;
static NSImage* _knobHLImage = nil;
static NSImage* _knobHMImage = nil;
static NSImage* _knobHRImage = nil;
static NSImage* _knobVTImage = nil;
static NSImage* _knobVMImage = nil;
static NSImage* _knobVBImage = nil;

static NSRect   _backHLRect = {{0, 0}, {0, 0}};
static NSRect   _backHMRect = {{0, 0}, {0, 0}};
static NSRect   _backHRLeftRect = {{0, 0}, {0, 0}};
static NSRect   _backHRRightRect = {{0, 0}, {0, 0}};
static NSRect   _backVTRect = {{0, 0}, {0, 0}};
static NSRect   _backVMRect = {{0, 0}, {0, 0}};
static NSRect   _backVBUpRect = {{0, 0}, {0, 0}};
static NSRect   _backVBDownRect = {{0, 0}, {0, 0}};
static NSRect   _knobHLRect = {{0, 0}, {0, 0}};
static NSRect   _knobHMRect = {{0, 0}, {0, 0}};
static NSRect   _knobHRRect = {{0, 0}, {0, 0}};
static NSRect   _knobVTRect = {{0, 0}, {0, 0}};
static NSRect   _knobVMRect = {{0, 0}, {0, 0}};
static NSRect   _knobVBRect = {{0, 0}, {0, 0}};

enum {
    NSScrollerPartWhole = 0, 
    NSScrollerPartUpperExtra = 1, 
    NSScrollerPartKnob = 2, 
    NSScrollerPartLowerExtra = 3, 
    NSScrollerPartUpArrow = 4, 
    NSScrollerPartDownArrow = 5, 
    NSScrollerPartWithoutArrow = 6, 
};

@implementation HMBlkScroller

//--------------------------------------------------------------//
#pragma mark -- Initialize --
//--------------------------------------------------------------//

+ (void)load
{
    NSAutoreleasePool*  pool;
    pool = [[NSAutoreleasePool alloc] init];
    
    // Get resources
    if (!_backHLImage) {
        NSBundle*   bundle;
        bundle = [NSBundle bundleForClass:[self class]];
    
        _backHLImage = [[NSImage alloc] initWithContentsOfFile:
                [bundle pathForImageResource:@"blkScrollerBackHL"]];
        _backHMImage = [[NSImage alloc] initWithContentsOfFile:
                [bundle pathForImageResource:@"blkScrollerBackHM"]];
        _backHRLeftImage = [[NSImage alloc] initWithContentsOfFile:
                [bundle pathForImageResource:@"blkScrollerBackHRLeft"]];
        _backHRRightImage = [[NSImage alloc] initWithContentsOfFile:
                [bundle pathForImageResource:@"blkScrollerBackHRRight"]];
        _backVTImage = [[NSImage alloc] initWithContentsOfFile:
                [bundle pathForImageResource:@"blkScrollerBackVT"]];
        _backVMImage = [[NSImage alloc] initWithContentsOfFile:
                [bundle pathForImageResource:@"blkScrollerBackVM"]];
        _backVBUpImage = [[NSImage alloc] initWithContentsOfFile:
                [bundle pathForImageResource:@"blkScrollerBackVBUp"]];
        _backVBUpSelectedImage = [[NSImage alloc] initWithContentsOfFile:
                [bundle pathForImageResource:@"blkScrollerBackVBUpSelected"]];
        _backVBDownImage = [[NSImage alloc] initWithContentsOfFile:
                [bundle pathForImageResource:@"blkScrollerBackVBDown"]];
        _backVBDownSelectedImage = [[NSImage alloc] initWithContentsOfFile:
                [bundle pathForImageResource:@"blkScrollerBackVBDownSelected"]];
        _knobHLImage = [[NSImage alloc] initWithContentsOfFile:
                [bundle pathForImageResource:@"blkScrollerKnobHL"]];
        _knobHMImage = [[NSImage alloc] initWithContentsOfFile:
                [bundle pathForImageResource:@"blkScrollerKnobHM"]];
        _knobHRImage = [[NSImage alloc] initWithContentsOfFile:
                [bundle pathForImageResource:@"blkScrollerKnobHR"]];
        _knobVTImage = [[NSImage alloc] initWithContentsOfFile:
                [bundle pathForImageResource:@"blkScrollerKnobVT"]];
        _knobVMImage = [[NSImage alloc] initWithContentsOfFile:
                [bundle pathForImageResource:@"blkScrollerKnobVM"]];
        _knobVBImage = [[NSImage alloc] initWithContentsOfFile:
                [bundle pathForImageResource:@"blkScrollerKnobVB"]];
        
        _backHLRect.size = [_backHLImage size];
        _backHMRect.size = [_backHMImage size];
        _backHRLeftRect.size = [_backHRLeftImage size];
        _backHRRightRect.size = [_backHRRightImage size];
        _backVTRect.size = [_backVTImage size];
        _backVMRect.size = [_backVMImage size];
        _backVBUpRect.size = [_backVBUpImage size];
        _backVBDownRect.size = [_backVBDownImage size];
        _knobHLRect.size = [_knobHLImage size];
        _knobHMRect.size = [_knobHMImage size];
        _knobHRRect.size = [_knobHRImage size];
        _knobVTRect.size = [_knobVTImage size];
        _knobVMRect.size = [_knobVMImage size];
        _knobVBRect.size = [_knobVBImage size];
    }
    
    [pool release];
}

//--------------------------------------------------------------//
#pragma mark -- Drawing --
//--------------------------------------------------------------//

- (void)drawArrow:(NSScrollerArrow)arrow highlightPart:(int)part
{
    // Get bounds
    NSRect  bounds;
    bounds = [self bounds];
    
    // Check flip
    BOOL    flipped;
    flipped = [self isFlipped];
    
    static NSColor* _dividerColor = nil;
    if (!_dividerColor) {
        _dividerColor = [[NSColor colorWithCalibratedWhite:0.522 alpha:1.0f] retain];
    }
    
    // Draw back
    NSRect  rect, imageRect;
    if (arrow == NSScrollerIncrementArrow) {
        // Down arrow
        NSImage*    image;
        if (part == 0) {
            image = _backVBDownSelectedImage;
        }
        else {
            image = _backVBDownImage;
        }
        
        rect.origin.x = 0;
        rect.origin.y = bounds.size.height - _backVBDownRect.size.height;
        rect.size = _backVBDownRect.size;
        imageRect.origin = NSZeroPoint;
        imageRect.size = _backVBDownRect.size;
        if ([image isFlipped] != flipped) {
            [image setFlipped:flipped];
        }
        [image drawInRect:rect fromRect:imageRect operation:NSCompositeCopy fraction:1.0f];
        
        // Divider
        [_dividerColor set];
        NSFrameRect(NSMakeRect(0, rect.origin.y - 1, bounds.size.width, 1));
        
        // Up arrow
        if (part == 1) {
            image = _backVBUpSelectedImage;
        }
        else {
            image = _backVBUpImage;
        }
        
        rect.origin.y -= _backVBUpRect.size.height + 1;
        rect.size = _backVBUpRect.size;
        imageRect.origin = NSZeroPoint;
        imageRect.size = _backVBUpRect.size;
        if ([image isFlipped] != flipped) {
            [image setFlipped:flipped];
        }
        [image drawInRect:rect fromRect:imageRect operation:NSCompositeCopy fraction:1.0f];
    }
    else if (arrow == NSScrollerDecrementArrow) {
        rect.origin.x = 0;
        rect.origin.y = 0;
        rect.size = [_backVTImage size];
        imageRect.origin = NSZeroPoint;
        imageRect.size = _backVTRect.size;
        if ([_backVTImage isFlipped] != flipped) {
            [_backVTImage setFlipped:flipped];
        }
        [_backVTImage drawInRect:rect fromRect:imageRect operation:NSCompositeCopy fraction:1.0f];
    }
}

- (void)drawKnob
{
    // Check flip
    BOOL    flipped;
    flipped = [self isFlipped];
    
    NSRect  rect, imageRect;
    
    //
    // Draw knob
    //
    
    // Get knob rect
    rect = [self rectForPart:NSScrollerPartKnob];
    
    // Draw knob bottom
    imageRect.origin.x = rect.origin.x + 1;
    imageRect.origin.y = flipped ? rect.origin.y + rect.size.height - _knobVBRect.size.height - 4 : rect.origin.y + 4;
    imageRect.size = _knobVBRect.size;
    if ([_knobVBImage isFlipped] != flipped) {
        [_knobVBImage setFlipped:flipped];
    }
    [_knobVBImage drawInRect:imageRect fromRect:_knobVBRect operation:NSCompositeSourceOver fraction:1.0f];
    
    // Draw knob middle
    imageRect.origin.x = rect.origin.x + 1;
    imageRect.origin.y = flipped ? 
            rect.origin.y + _knobVTRect.size.height + 2 : 
            rect.origin.y + rect.size.height - _knobVTRect.size.height;
    imageRect.size.width = _knobVMRect.size.width;
    imageRect.size.height = rect.size.height - _knobVBRect.size.height - _knobVTRect.size.height - 6;
    if ([_knobVMImage isFlipped] != flipped) {
        [_knobVMImage setFlipped:flipped];
    }
    [_knobVMImage drawInRect:imageRect fromRect:_knobVMRect operation:NSCompositeSourceOver fraction:1.0f];
    
    // Draw knob top
    imageRect.origin.x = rect.origin.x + 1;
    imageRect.origin.y = flipped ? rect.origin.y + 2 : rect.origin.y + rect.size.height - _knobVTRect.size.height - 2;
    imageRect.size = _knobVTRect.size;
    if ([_knobVTImage isFlipped] != flipped) {
        [_knobVTImage setFlipped:flipped];
    }
    [_knobVTImage drawInRect:imageRect fromRect:_knobVTRect operation:NSCompositeSourceOver fraction:1.0f];
}

- (void)drawKnobSlotInRect:(NSRect)rect highlight:(BOOL)highlight
{
    // Get frame
    NSRect  frame;
    frame = [self frame];
    
    // Check flip
    BOOL    flipped;
    flipped = [self isFlipped];
    
    NSRect  imageRect;
    
#if 1
    // Draw background image
    imageRect.origin = NSZeroPoint;
    imageRect.size = [_backVMImage size];
    [_backVMImage drawInRect:rect fromRect:imageRect operation:NSCompositeCopy fraction:1.0f];
#else
    // Fill background
    NSImage*    backImage;
    backImage = [HMBlkPanel contentBackgroundImage];
    imageRect.origin = NSZeroPoint;
    imageRect.size = [backImage size];
    [backImage drawInRect:rect fromRect:imageRect operation:NSCompositeCopy fraction:1.0f];
    
    // Draw background bottom
    imageRect.origin.x = 0;
    imageRect.origin.y = flipped ? frame.size.height - _backBottomRect.size.height : 0;
    imageRect.size = _backBottomRect.size;
    if (NSIntersectsRect(imageRect, rect)) {
        if ([_backBottomImage isFlipped] != flipped) {
            [_backBottomImage setFlipped:flipped];
        }
        [_backBottomImage drawInRect:imageRect fromRect:_backBottomRect operation:NSCompositeCopy fraction:1.0f];
    }
    
    // Draw background middle
    imageRect.origin.x = 0;
    imageRect.origin.y = flipped ? _backTopRect.size.height : _backBottomRect.size.height;
    imageRect.size.width = _backMiddleRect.size.width;
    imageRect.size.height = frame.size.height - _backTopRect.size.height - _backBottomRect.size.height;
    if (NSIntersectsRect(imageRect, rect)) {
        if ([_backMiddleImage isFlipped] != flipped) {
            [_backMiddleImage setFlipped:flipped];
        }
        [_backMiddleImage drawInRect:imageRect fromRect:_backMiddleRect operation:NSCompositeCopy fraction:1.0f];
    }
    
    // Draw background top
    imageRect.origin.x = 0;
    imageRect.origin.y = flipped ? 0 : frame.size.height - _backTopRect.size.height;
    imageRect.size = _backTopRect.size;
    if (NSIntersectsRect(imageRect, rect)) {
        if ([_backTopImage isFlipped] != flipped) {
            [_backTopImage setFlipped:flipped];
        }
        [_backTopImage drawInRect:imageRect fromRect:_backTopRect operation:NSCompositeCopy fraction:1.0f];
    }
#endif
}

@end
