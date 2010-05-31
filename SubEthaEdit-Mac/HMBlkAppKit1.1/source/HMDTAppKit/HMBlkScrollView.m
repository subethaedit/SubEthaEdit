/*
HMBlkScrollView.m

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
#import "HMBlkScroller.h"
#import "HMBlkScrollView.h"

@implementation HMBlkScrollView

//--------------------------------------------------------------//
#pragma mark -- Initialize --
//--------------------------------------------------------------//

- (void)_init
{
    // Configure itself
    NSScroller*     scroller;
    HMBlkScroller*  blkScroller;
    if ([self hasHorizontalScroller]) {
        scroller = [self horizontalScroller];
        if (scroller) {
            blkScroller = [[HMBlkScroller alloc] initWithFrame:[scroller frame]];
            [blkScroller setArrowsPosition:NSScrollerArrowsMaxEnd];
            [self setHorizontalScroller:blkScroller];
            [blkScroller release];
        }
    }
    if ([self hasVerticalScroller]) {
        scroller = [self verticalScroller];
        if (scroller) {
            blkScroller = [[HMBlkScroller alloc] initWithFrame:[scroller frame]];
            [blkScroller setArrowsPosition:NSScrollerArrowsMaxEnd];
            [self setVerticalScroller:blkScroller];
            [blkScroller release];
        }
    }
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (!self) {
        return nil;
    }
    
    // Common init
    [self _init];
    
    return self;
}

- (id)initWithCoder:(NSCoder*)coder
{
    self = [super initWithCoder:coder];
    if (!self) {
        return nil;
    }
    
    // Common init
    [self _init];
    
    return self;
}

//--------------------------------------------------------------//
#pragma mark -- Drawing --
//--------------------------------------------------------------//

- (void)drawRect:(NSRect)rect
{
    // Get bounds
    NSRect  bounds;
    bounds = [self bounds];
    
    // Draw grid
    [[HMBlkPanel majorGridColor] set];
    
    NSRect  gridRect;
    gridRect.origin.x = bounds.origin.x + 1;
    gridRect.origin.y = bounds.origin.y;
    gridRect.size.width = bounds.size.width - 2;
    gridRect.size.height = 1;
    NSFrameRect(gridRect);
    
    gridRect.origin.x = bounds.origin.x + 1;
    gridRect.origin.y = bounds.origin.y + bounds.size.height - 1;
    gridRect.size.width = bounds.size.width - 2;
    gridRect.size.height = 1;
    NSFrameRect(gridRect);
}

@end
