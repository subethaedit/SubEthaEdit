/*
HMBlkTableView.m

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

#import "HMAppKitEx.h"
#import "HMBlkTableView.h"
#import "HMBlkPanel.h"
#import "HMBlkTableHeaderCell.h"

@implementation HMBlkTableView

//--------------------------------------------------------------//
#pragma mark -- Initialize --
//--------------------------------------------------------------//

- (void)_init
{
    // Configure table header cell
    NSEnumerator*   enumerator;
    NSTableColumn*  column;
    enumerator = [[self tableColumns] objectEnumerator];
    while (column = [enumerator nextObject]) {
        // Get old cell
        id  oldCell;
        oldCell = [column headerCell];
        
        // Swap cell
        HMBlkTableHeaderCell*   cell;
        cell = [[HMBlkTableHeaderCell alloc] init];
        [cell setStringValue:[oldCell stringValue]];
        [cell setFont:[oldCell font]];
        
        [column setHeaderCell:cell];
        [cell release];
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
#pragma mark -- Cell attributes --
//--------------------------------------------------------------//

- (void)_sendDelegateWillDisplayCell:(id)cell forColumn:(id)column row:(int)row
{
    [super _sendDelegateWillDisplayCell:cell forColumn:column row:row];
    
    // Set text color
    if ([cell respondsToSelector:@selector(setTextColor:)]) {
        [cell setTextColor:[NSColor whiteColor]];
    }
}

- (id)_alternatingRowBackgroundColors
{
    return [HMBlkPanel alternatingRowBackgroundColors];
}

- (id)_highlightColorForCell:(id)cell
{
    return [HMBlkPanel highlighedCellColor];
}

//--------------------------------------------------------------//
#pragma mark -- Drawing --
//--------------------------------------------------------------//

#if 0
- (void)drawBackgroundInClipRect:(NSRect)rect
{
    // Fill background
    NSImage*    backImage;
    NSRect      imageRect;
    backImage = [HMBlkPanel contentBackgroundImage];
    imageRect.origin = NSZeroPoint;
    imageRect.size = [backImage size];
    [backImage drawInRect:rect fromRect:imageRect operation:NSCompositeCopy fraction:1.0f];
}
#endif

#if 0
- (void)drawGridInClipRect:(NSRect)rect
{
    // Invoke super
    [super drawGridInClipRect:rect];
    
    // Get frame
    NSRect  frame;
    frame = [self frame];
    
    // Make margin
    NSRect  marginRect;
    marginRect = frame;
    marginRect.origin.x = marginRect.size.width - 8;
    marginRect.size.width = 8;
    
    // Fill margin
    if (NSIntersectsRect(marginRect, rect)) {
        NSImage*    backImage;
        NSRect      imageRect;
        backImage = [HMBlkPanel contentBackgroundImage];
        imageRect.origin = NSZeroPoint;
        imageRect.size = [backImage size];
        [backImage drawInRect:NSIntersectionRect(marginRect, rect) 
                fromRect:imageRect operation:NSCompositeCopy fraction:1.0f];
    }
}
#endif

@end
