/*
        ScalingScrollView.m
        Copyright (c) 1995-2007 by Apple Computer, Inc., all rights reserved.
        Author: Mike Ferris
*/
/*
 IMPORTANT:  This Apple software is supplied to you by Apple Computer, Inc. ("Apple") in
 consideration of your agreement to the following terms, and your use, installation, 
 modification or redistribution of this Apple software constitutes acceptance of these 
 terms.  If you do not agree with these terms, please do not use, install, modify or 
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and subject to these 
 terms, Apple grants you a personal, non-exclusive license, under Apple's copyrights in 
 this original Apple software (the "Apple Software"), to use, reproduce, modify and 
 redistribute the Apple Software, with or without modifications, in source and/or binary 
 forms; provided that if you redistribute the Apple Software in its entirety and without 
 modifications, you must retain this notice and the following text and disclaimers in all 
 such redistributions of the Apple Software.  Neither the name, trademarks, service marks 
 or logos of Apple Computer, Inc. may be used to endorse or promote products derived from 
 the Apple Software without specific prior written permission from Apple. Except as expressly
 stated in this notice, no other rights or licenses, express or implied, are granted by Apple
 herein, including but not limited to any patent rights that may be infringed by your 
 derivative works or by other works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO WARRANTIES, 
 EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, 
 MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS 
 USE AND OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR CONSEQUENTIAL 
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS 
 OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, 
 REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND 
 WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR 
 OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import <Cocoa/Cocoa.h>
#import "ScalingScrollView.h"

/* For genstrings:
    NSLocalizedStringFromTable(@"10%", @"ZoomValues", @"Zoom popup entry")
    NSLocalizedStringFromTable(@"25%", @"ZoomValues", @"Zoom popup entry")
    NSLocalizedStringFromTable(@"50%", @"ZoomValues", @"Zoom popup entry")
    NSLocalizedStringFromTable(@"75%", @"ZoomValues", @"Zoom popup entry")
    NSLocalizedStringFromTable(@"100%", @"ZoomValues", @"Zoom popup entry")
    NSLocalizedStringFromTable(@"125%", @"ZoomValues", @"Zoom popup entry")
    NSLocalizedStringFromTable(@"150%", @"ZoomValues", @"Zoom popup entry")
    NSLocalizedStringFromTable(@"200%", @"ZoomValues", @"Zoom popup entry")
    NSLocalizedStringFromTable(@"400%", @"ZoomValues", @"Zoom popup entry")
    NSLocalizedStringFromTable(@"800%", @"ZoomValues", @"Zoom popup entry")
    NSLocalizedStringFromTable(@"1600%", @"ZoomValues", @"Zoom popup entry")
*/   
static NSString *_NSDefaultScaleMenuLabels[] = {/* @"Set...", */ @"10%", @"25%", @"50%", @"75%", @"100%", @"125%", @"150%", @"200%", @"400%", @"800%", @"1600%"};
static const CGFloat _NSDefaultScaleMenuFactors[] = {/* 0.0, */ 0.1, 0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 4.0, 8.0, 16.0};
static NSUInteger _NSDefaultScaleMenuSelectedItemIndex = 4;
static const CGFloat _NSScaleMenuFontSize = 10.0;

@implementation ScalingScrollView

- (id)initWithFrame:(NSRect)rect {
    if ((self = [super initWithFrame:rect])) {
        scaleFactor = 1.0;
    }
    return self;
}

- (void)makeScalePopUpButton {
    if (_scalePopUpButton == nil) {
        NSUInteger cnt, numberOfDefaultItems = (sizeof(_NSDefaultScaleMenuLabels) / sizeof(NSString *));
        id curItem;

        // create it
        _scalePopUpButton = [[NSPopUpButton allocWithZone:[self zone]] initWithFrame:NSMakeRect(0.0, 0.0, 1.0, 1.0) pullsDown:NO];
        [(NSPopUpButtonCell *)[_scalePopUpButton cell] setBezelStyle:NSShadowlessSquareBezelStyle];
        [[_scalePopUpButton cell] setArrowPosition:NSPopUpArrowAtBottom];
        
        // fill it
        for (cnt = 0; cnt < numberOfDefaultItems; cnt++) {
            [_scalePopUpButton addItemWithTitle:NSLocalizedStringFromTable(_NSDefaultScaleMenuLabels[cnt], @"ZoomValues", nil)];
            curItem = [_scalePopUpButton itemAtIndex:cnt];
            if (_NSDefaultScaleMenuFactors[cnt] != 0.0) {
                [curItem setRepresentedObject:[NSNumber numberWithDouble:_NSDefaultScaleMenuFactors[cnt]]];
            }
        }
        [_scalePopUpButton selectItemAtIndex:_NSDefaultScaleMenuSelectedItemIndex];

        // hook it up
        [_scalePopUpButton setTarget:self];
        [_scalePopUpButton setAction:@selector(scalePopUpAction:)];

        // set a suitable font
        [_scalePopUpButton setFont:[NSFont toolTipsFontOfSize:_NSScaleMenuFontSize]];

        // Make sure the popup is big enough to fit the cells.
        [_scalePopUpButton sizeToFit];

	// don't let it become first responder
	[_scalePopUpButton setRefusesFirstResponder:YES];

        // put it in the scrollview
        [self addSubview:_scalePopUpButton];
        [_scalePopUpButton release];
    }
}

- (void)tile {
    // Let the superclass do most of the work.
    [super tile];

    if (![self hasHorizontalScroller]) {
        if (_scalePopUpButton) [_scalePopUpButton removeFromSuperview];
        _scalePopUpButton = nil;
    } else {
	NSScroller *horizScroller;
	NSRect horizScrollerFrame, buttonFrame;
	
        if (!_scalePopUpButton) [self makeScalePopUpButton];

        horizScroller = [self horizontalScroller];
        horizScrollerFrame = [horizScroller frame];
        buttonFrame = [_scalePopUpButton frame];

        // Now we'll just adjust the horizontal scroller size and set the button size and location.
        horizScrollerFrame.size.width = horizScrollerFrame.size.width - buttonFrame.size.width;
        [horizScroller setFrameSize:horizScrollerFrame.size];

        buttonFrame.origin.x = NSMaxX(horizScrollerFrame);
        buttonFrame.size.height = horizScrollerFrame.size.height + 1.0;
        buttonFrame.origin.y = [self bounds].size.height - buttonFrame.size.height + 1.0;
        [_scalePopUpButton setFrame:buttonFrame];
    }
}

- (void)drawRect:(NSRect)rect {
    NSRect verticalLineRect;
    
    [super drawRect:rect];

    if ([_scalePopUpButton superview]) {
        verticalLineRect = [_scalePopUpButton frame];
        verticalLineRect.origin.x -= 1.0;
        verticalLineRect.size.width = 1.0;
        if (NSIntersectsRect(rect, verticalLineRect)) {
            [[NSColor blackColor] set];
            NSRectFill(verticalLineRect);
        }
    }
}

- (void)scalePopUpAction:(id)sender {
    NSNumber *selectedFactorObject = [[sender selectedCell] representedObject];
    
    if (selectedFactorObject == nil) {
        NSLog(@"Scale popup action: setting arbitrary zoom factors is not yet supported.");
        return;
    } else {
        [self setScaleFactor:[selectedFactorObject doubleValue] adjustPopup:NO];
    }
}

- (CGFloat)scaleFactor {
    return scaleFactor;
}

- (void)setScaleFactor:(CGFloat)newScaleFactor {
    if (scaleFactor != newScaleFactor) {
	scaleFactor = newScaleFactor;

	NSView *clipView = [[self documentView] superview];
	
	// Get the frame.  The frame must stay the same.
	NSSize curDocFrameSize = [clipView frame].size;
	
	// The new bounds will be frame divided by scale factor
	NSSize newDocBoundsSize = {curDocFrameSize.width / scaleFactor, curDocFrameSize.height / scaleFactor};
	
	[clipView setBoundsSize:newDocBoundsSize];
    }
}

- (void)setScaleFactor:(CGFloat)newScaleFactor adjustPopup:(BOOL)flag {
    if (flag) {	// Coming from elsewhere, first validate it
	NSUInteger cnt = 0, numberOfDefaultItems = (sizeof(_NSDefaultScaleMenuFactors) / sizeof(CGFloat));

	// We only work with some preset zoom values, so choose one of the appropriate values (Fudge a little for floating point == to work)
	while (cnt < numberOfDefaultItems && newScaleFactor * .99 > _NSDefaultScaleMenuFactors[cnt]) cnt++;
	if (cnt == numberOfDefaultItems) cnt--;
	[_scalePopUpButton selectItemAtIndex:cnt];
	newScaleFactor = _NSDefaultScaleMenuFactors[cnt];
    }
    [self setScaleFactor:newScaleFactor];
}

- (void)setHasHorizontalScroller:(BOOL)flag {
    if (!flag) [self setScaleFactor:1.0 adjustPopup:NO];
    [super setHasHorizontalScroller:flag];
}

@end
