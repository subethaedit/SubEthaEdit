/*
HMBlkContentView.m

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

#import "HMBlkContentView.h"

@implementation HMBlkContentView

static NSImage* _leftBottomImage = nil;
static NSImage* _leftMiddleImage = nil;
static NSImage* _leftTopImage = nil;
static NSImage* _middleBottomImage = nil;
static NSImage* _middleMiddleImage = nil;
static NSImage* _middleTopImage = nil;
static NSImage* _rightBottomImage = nil;
static NSImage* _rightMiddleImage = nil;
static NSImage* _rightTopImage = nil;

static NSRect   _leftBottomRect = {{0, 0}, {0, 0}};
static NSRect   _leftMiddleRect = {{0, 0}, {0, 0}};
static NSRect   _leftTopRect = {{0, 0}, {0, 0}};
static NSRect   _middleBottomRect = {{0, 0}, {0, 0}};
static NSRect   _middleMiddleRect = {{0, 0}, {0, 0}};
static NSRect   _middleTopRect = {{0, 0}, {0, 0}};
static NSRect   _rightBottomRect = {{0, 0}, {0, 0}};
static NSRect   _rightMiddleRect = {{0, 0}, {0, 0}};
static NSRect   _rightTopRect = {{0, 0}, {0, 0}};

//--------------------------------------------------------------//
#pragma mark -- Initialize --
//--------------------------------------------------------------//

+ (void)load
{
    NSAutoreleasePool*  pool;
    pool = [[NSAutoreleasePool alloc] init];
    
    // Get resources
    if (!_leftBottomImage) {
        NSBundle*   bundle;
        bundle = [NSBundle bundleForClass:self];
        
        _leftBottomImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForImageResource:@"blkPanelLB"]];
        _leftMiddleImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForImageResource:@"blkPanelLM"]];
        _leftTopImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForImageResource:@"blkPanelLT"]];
        _middleBottomImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForImageResource:@"blkPanelMB"]];
        _middleMiddleImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForImageResource:@"blkPanelMM"]];
        _middleTopImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForImageResource:@"blkPanelMT"]];
        _rightBottomImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForImageResource:@"blkPanelRB"]];
        _rightMiddleImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForImageResource:@"blkPanelRM"]];
        _rightTopImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForImageResource:@"blkPanelRT"]];
        
        _leftBottomRect.size = [_leftBottomImage size];
        _leftMiddleRect.size = [_leftMiddleImage size];
        _leftTopRect.size = [_leftTopImage size];
        _middleBottomRect.size = [_middleBottomImage size];
        _middleMiddleRect.size = [_middleMiddleImage size];
        _middleTopRect.size = [_middleTopImage size];
        _rightBottomRect.size = [_rightBottomImage size];
        _rightMiddleRect.size = [_rightMiddleImage size];
        _rightTopRect.size = [_rightTopImage size];
    }
    
    [pool release];
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (!self) {
        return nil;
    }
    
    // Initialize instance variables
    _isResizing = NO;
    _startWindowFrame = NSZeroRect;
    _startLocation = NSZeroPoint;
    
    return self;
}

//--------------------------------------------------------------//
#pragma mark -- Dragging --
//--------------------------------------------------------------//

- (void)mouseDown:(NSEvent*)event
{
    // Get window
    NSWindow*   window;
    window = [self window];
    
    // Store size information
    NSPoint mouseLocation;
    mouseLocation = [event locationInWindow];
    _startWindowFrame = [window frame];
    _startLocation = [window convertBaseToScreen:mouseLocation];
    
    // Get frame
    NSRect  frame;
    frame = [self frame];
    
    // Decide grow box region
    NSRect  growBoxRect;
    growBoxRect.origin.x = frame.size.width - 30;
    growBoxRect.origin.y = 18;
    growBoxRect.size.width = 16;
    growBoxRect.size.height = 16;
    
    // When click in the grow box
    NSPoint mousePoint;
    mousePoint = [self convertPoint:mouseLocation fromView:nil];
    if (NSPointInRect(mousePoint, growBoxRect)) {
        // Start resizing
        _isResizing = YES;
    }
    // Other place
    else {
        // Start dragging
        _isDragging = YES;
    }
    
    // Invoke super
    [super mouseDown:event];
}

- (void)mouseDragged:(NSEvent*)event
{
    // Get window
    NSWindow*   window;
    window = [self window];
    
    // Get cuurent mouse location
    NSPoint mouseLocation;
    mouseLocation = [window convertBaseToScreen:[event locationInWindow]];
    
    // Calc delta
    float   dx, dy;
    dx = mouseLocation.x - _startLocation.x;
    dy = _startLocation.y - mouseLocation.y;
    
    // For resizing
    if (_isResizing) {
        // Decide new window frame
        NSRect  newWindowFrame;
        newWindowFrame = _startWindowFrame;
        newWindowFrame.size.width += dx;
        newWindowFrame.size.height += dy;
        newWindowFrame.origin.y -= dy;
        
        // Constrain with min and max size
        NSSize  minSize, maxSize;
        minSize = [window minSize];
        maxSize = [window maxSize];
        if (minSize.width > 0 && newWindowFrame.size.width < minSize.width) {
            newWindowFrame.size.width = minSize.width;
        }
        if (maxSize.width > 0 && newWindowFrame.size.width > maxSize.width) {
            newWindowFrame.size.width = maxSize.width;
        }
        if (minSize.height > 0 && newWindowFrame.size.height < minSize.height) {
            newWindowFrame.origin.y += newWindowFrame.size.height - minSize.height;
            newWindowFrame.size.height = minSize.height;
        }
        if (maxSize.height > 0 && newWindowFrame.size.height > maxSize.height) {
            newWindowFrame.origin.y += newWindowFrame.size.height - minSize.height;
            newWindowFrame.size.height = maxSize.height;
        }
        
        // Set window frame
        if (!NSEqualRects(newWindowFrame, [window frame])) {
            [window setFrame:newWindowFrame display:YES animate:NO];
        }
    }
    // For dragging
    else if (_isDragging) {
        // Decide new window frame
        NSRect  newWindowFrame;
        newWindowFrame = _startWindowFrame;
        newWindowFrame.origin.x += dx;
        newWindowFrame.origin.y -= dy;
        
        // Set window frame
        if (!NSEqualRects(newWindowFrame, [window frame])) {
            [window setFrame:newWindowFrame display:YES animate:NO];
        }
    }
}

- (void)mouseUp:(NSEvent*)event
{
    // Clear size
    _startWindowFrame = NSZeroRect;
    _startLocation = NSZeroPoint;
    
    // For resizing
    if (_isResizing) {
        // Stop resizing
        _isResizing = NO;
    }
    // For dragging
    else if (_isDragging) {
        _isDragging = NO;
    }
}

//--------------------------------------------------------------//
#pragma mark -- Drawing --
//--------------------------------------------------------------//

- (void)drawRect:(NSRect)rect
{
    // Get frame
    NSRect  frame;
    frame = [self frame];
    
    NSRect  imageRect;
    
    //
    // Draw background
    //
    
    // Draw left bottom
    imageRect.origin = NSZeroPoint;
    imageRect.size = _leftBottomRect.size;
    if (NSIntersectsRect(imageRect, rect)) {
        [_leftBottomImage drawInRect:imageRect fromRect:_leftBottomRect operation:NSCompositeCopy fraction:1.0f];
    }
    
    // Draw left middle
    imageRect.origin.x = 0;
    imageRect.origin.y = _leftBottomRect.size.height;
    imageRect.size.width = _leftMiddleRect.size.width;
    imageRect.size.height = frame.size.height - _leftBottomRect.size.height - _leftTopRect.size.height;
    if (NSIntersectsRect(imageRect, rect)) {
        [_leftMiddleImage drawInRect:imageRect fromRect:_leftMiddleRect operation:NSCompositeCopy fraction:1.0f];
    }
    
    // Draw left top
    imageRect.origin.x = 0;
    imageRect.origin.y = frame.size.height - _leftTopRect.size.height;
    imageRect.size = _leftTopRect.size;
    if (NSIntersectsRect(imageRect, rect)) {
        [_leftTopImage drawInRect:imageRect fromRect:_leftTopRect operation:NSCompositeCopy fraction:1.0f];
    }
    
    // Draw middle bottom
    imageRect.origin.x = _leftBottomRect.size.width;
    imageRect.origin.y = 0;
    imageRect.size.width = frame.size.width - _leftBottomRect.size.width - _rightBottomRect.size.width;
    imageRect.size.height = _middleBottomRect.size.height;
    if (NSIntersectsRect(imageRect, rect)) {
        [_middleBottomImage drawInRect:imageRect fromRect:_middleBottomRect operation:NSCompositeCopy fraction:1.0f];
    }
    
    // Draw middle middle
    imageRect.origin.x = _leftMiddleRect.size.width;
    imageRect.origin.y = _middleBottomRect.size.height;
    imageRect.size.width = frame.size.width - _leftMiddleRect.size.width - _rightMiddleRect.size.width;
    imageRect.size.height = frame.size.height - _middleBottomRect.size.height - _middleTopRect.size.height;
    if (NSIntersectsRect(imageRect, rect)) {
        [_middleMiddleImage drawInRect:imageRect fromRect:_middleMiddleRect operation:NSCompositeCopy fraction:1.0f];
    }
    
    // Draw middle top
    imageRect.origin.x = _leftTopRect.size.width;
    imageRect.origin.y = frame.size.height - _middleTopRect.size.height;
    imageRect.size.width = frame.size.width - _leftTopRect.size.width - _rightTopRect.size.width;
    imageRect.size.height = _middleTopRect.size.height;
    if (NSIntersectsRect(imageRect, rect)) {
        [_middleTopImage drawInRect:imageRect fromRect:_middleTopRect operation:NSCompositeCopy fraction:1.0f];
    }
    
    // Draw right bottom
    imageRect.origin.x = frame.size.width - _rightBottomRect.size.width;
    imageRect.origin.y = 0;
    imageRect.size.width = _rightBottomRect.size.width;
    imageRect.size.height = _rightBottomRect.size.height;
    if (NSIntersectsRect(imageRect, rect)) {
        [_rightBottomImage drawInRect:imageRect fromRect:_rightBottomRect operation:NSCompositeCopy fraction:1.0f];
    }
    
    // Draw right middle
    imageRect.origin.x = frame.size.width - _rightMiddleRect.size.width;
    imageRect.origin.y = _rightBottomRect.size.height;
    imageRect.size.width = _rightMiddleRect.size.width;
    imageRect.size.height = frame.size.height - _rightBottomRect.size.height - _rightTopRect.size.height;
    if (NSIntersectsRect(imageRect, rect)) {
        [_rightMiddleImage drawInRect:imageRect fromRect:_rightMiddleRect operation:NSCompositeCopy fraction:1.0f];
    }
    
    // Draw right top
    imageRect.origin.x = frame.size.width - _rightTopRect.size.width;
    imageRect.origin.y = frame.size.height - _rightTopRect.size.height;
    imageRect.size.width = _rightTopRect.size.width;
    imageRect.size.height = _rightTopRect.size.height;
    if (NSIntersectsRect(imageRect, rect)) {
        [_rightTopImage drawInRect:imageRect fromRect:_rightTopRect operation:NSCompositeCopy fraction:1.0f];
    }
    
    //
    // Draw title
    //
    
    // Get title
    NSString*   title;
    title = [[self window] title];
    
    // Create attributed string
    static NSDictionary*    _attrs = nil;
    if (!_attrs) {
        NSMutableParagraphStyle*    paragraph;
        paragraph = [[NSMutableParagraphStyle alloc] init];
        [paragraph setAlignment:NSCenterTextAlignment];
        [paragraph setLineBreakMode:NSLineBreakByTruncatingTail];
        
        _attrs = [[NSDictionary dictionaryWithObjectsAndKeys:
                [NSFont systemFontOfSize:11.0f], NSFontAttributeName, 
                [NSColor colorWithCalibratedWhite:1.0f alpha:0.8f], NSForegroundColorAttributeName, 
                paragraph, NSParagraphStyleAttributeName, 
                nil] retain];
    }
    
    NSAttributedString* attrStr;
    attrStr = [[NSAttributedString alloc] initWithString:title attributes:_attrs];
    
    // Decide title rect
    NSRect  titleRect;
    titleRect.origin.x = 36;
    titleRect.origin.y = frame.size.height - 22;
    titleRect.size.width = frame.size.width - 72;
    titleRect.size.height = 16;
    
    // Draw title
    [attrStr drawInRect:titleRect];
    [attrStr release];
}

@end
