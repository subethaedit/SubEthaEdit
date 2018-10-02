//
//  PlainTextWindow.m
//  SubEthaEdit
//
//  Created by Martin Ott on 11/23/06.
//  Copyright 2006 TheCodingMonkeys. All rights reserved.
//

#import "PlainTextWindow.h"
#import "PlainTextWindowController.h"

@implementation PlainTextWindow

- (IBAction)performClose:(id)sender
{
    if ([[self windowController] isKindOfClass:[PlainTextWindowController class]]) {
        [(PlainTextWindowController *)[self windowController] closeAllTabs];
    } else {
        [super performClose:sender];
    }
}

- (void)setDocumentEdited:(BOOL)flag
{
    NSDocument *document = [[self windowController] document];
    if (document) {
        [super setDocumentEdited:[document isDocumentEdited]];
    } else {
        [super setDocumentEdited:flag];
    }
}

- (NSPoint)cascadeTopLeftFromPoint:(NSPoint)aPoint {
    static NSPoint offsetPoint = {0.,0.};
    if (NSEqualPoints(offsetPoint,NSZeroPoint)) {
        NSPoint firstPoint = [super cascadeTopLeftFromPoint:NSZeroPoint];
        NSPoint secondPoint = [super cascadeTopLeftFromPoint:firstPoint];
        offsetPoint.x = MAX(10.,MIN(ABS(secondPoint.x-firstPoint.x),70.));
        offsetPoint.y = MAX(10.,MIN(ABS(secondPoint.y-firstPoint.y),70.));
    }

    NSScreen *screen = [NSScreen screenContainingPoint:aPoint];
    if (!screen) screen = [NSScreen menuBarContainingScreen];
    
    // check if the top window is on the same screen, if not, cascading from the top window
    NSArray *orderedWindows = [NSApp orderedWindows];
    for (NSWindow *window in orderedWindows) {
        if ([window isKindOfClass:[PlainTextWindow class]]) {
            if ([window screen] != screen) {
                screen = [window screen];
                aPoint = NSMakePoint(NSMinX([window frame]),NSMaxY([window frame]));
                NSRect visibleFrame = [screen visibleFrame];
                if (aPoint.x < NSMinX(visibleFrame)) aPoint.x = NSMinX(visibleFrame);
            }
            break;
        }
    }

    NSRect visibleFrame = [screen visibleFrame];
    if (NSEqualPoints(aPoint,NSZeroPoint)) {
        aPoint = NSMakePoint(visibleFrame.origin.x,NSMaxY(visibleFrame));
    }
    if (aPoint.y > NSMaxY(visibleFrame)) aPoint.y = NSMaxY(visibleFrame) + offsetPoint.y;

    NSPoint result = aPoint;
    result.x += offsetPoint.x;
    result.y -= offsetPoint.y;
    if (result.x + [self frame].size.width > NSMaxX(visibleFrame)) {
        result.x = visibleFrame.origin.x;
    }
    
    // oops we forgot to take care of the fact that the window should not be to far left
    if (result.x < NSMinX(visibleFrame)) {
        result.x = NSMinX(visibleFrame);
    }

    float toHighDifference = visibleFrame.origin.y - (result.y - [self frame].size.height);
    if (toHighDifference > 0) {
        result.y = NSMaxY(visibleFrame);
    }
    return result;
}

// This window has its usual -constrainFrameRect:toScreen: behavior temporarily suppressed.
// This enables our window's custom Full Screen Exit animations to avoid being constrained by the
// top edge of the screen and the menu bar.
//
- (NSRect)constrainFrameRect:(NSRect)frameRect toScreen:(NSScreen *)screen
{
    if (self.constrainingToScreenSuspended)
    {
        return frameRect;
    }
    else
    {
        return [super constrainFrameRect:frameRect toScreen:screen];
    }
}


@end
