/*
HMBlkOutlineView.m

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
#import "HMBlkContentView.h"
#import "HMBlkOutlineView.h"
#import "HMBlkPanel.h"
#import "HMBlkTableHeaderCell.h"

static NSImage* _collapsedImage = nil;
static NSImage* _transientImage = nil;
static NSImage* _expandedImage = nil;

static NSRect   _collapsedRect = {{0, 0}, {0, 0}};
static NSRect   _transientRect = {{0, 0}, {0, 0}};
static NSRect   _expandedRect = {{0, 0}, {0, 0}};

@implementation HMBlkOutlineView

//--------------------------------------------------------------//
#pragma mark -- Initialize --
//--------------------------------------------------------------//

+ (void)load
{
    NSAutoreleasePool*  pool;
    pool = [[NSAutoreleasePool alloc] init];
    
    // Get resources
    if (!_collapsedImage) {
        NSBundle*   bundle;
        bundle = [NSBundle bundleForClass:self];
        
        _collapsedImage = [[NSImage alloc] initWithContentsOfFile:
                [bundle pathForImageResource:@"blkDiscCollapsed"]];
        _transientImage = [[NSImage alloc] initWithContentsOfFile:
                [bundle pathForImageResource:@"blkDiscTransient"]];
        _expandedImage = [[NSImage alloc] initWithContentsOfFile:
                [bundle pathForImageResource:@"blkDiscExpanded"]];
        
        _collapsedRect.size = [_collapsedImage size];
        _transientRect.size = [_transientImage size];
        _expandedRect.size = [_expandedImage size];
    }
    
    [pool release];
}

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
    
    // Configure corner view
    NSView*             oldCornerView;
    HMBlkContentView*   cornerView;
    oldCornerView = [self cornerView];
    [oldCornerView setHidden:YES];
    cornerView = [[HMBlkContentView alloc] initWithFrame:NSZeroRect];
    [self setCornerView:cornerView];
    [cornerView release];
    
    // Configure itself
    [self setAutoresizesOutlineColumn:NO];
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

- (void)_sendDelegateWillDisplayOutlineCell:(id)cell inOutlineTableColumnAtRow:(int)row
{
    [super _sendDelegateWillDisplayOutlineCell:cell inOutlineTableColumnAtRow:row];
    
    // Set cell image
    id  item;
    item = [self itemAtRow:row];
    if ([self isItemExpanded:item]) {
        [cell setImage:_expandedImage];
    }
    else {
        [cell setImage:_collapsedImage];
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
    marginRect.origin.x = marginRect.size.width - 4;
    marginRect.size.width = 4;
    
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
