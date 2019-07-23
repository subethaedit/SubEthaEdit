//  PlainTextWindow.m
//  SubEthaEdit
//
//  Created by Martin Ott on 11/23/06.

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

-(void)sendEvent:(NSEvent *)event {
    // Handle ⌘ 1 ... ⌘ 9, ⌘ 0 shortcuts to select tabs
    // Todo: this behaviour should not be specific to PlainTextWindows
    if ([event type] == NSEventTypeKeyDown) {
        int flags = [event modifierFlags];
        if ((flags & NSEventModifierFlagCommand) &&
            !(flags & NSEventModifierFlagControl) &&
            [[event characters] length] == 1) {
            
            NSString *characters = [event characters];
            NSInteger tabIndex = [characters integerValue];
            if (tabIndex == 0) {
                // integerValue returns 0 for invalid strings. Return if characters isn't literally a '0'
                if (![characters isEqualToString:@"0"]) {
                    return [super sendEvent:event];
                }
            }
            
            // 1 will become 0, 2 will become 1 ... 0 will become 9
            tabIndex = (tabIndex+9) % 10;
            
            PlainTextWindowController *wc = [self windowController];
            if ([wc isKindOfClass:[PlainTextWindowController class]]) {
                
                NSArray *tabbedWindows = wc.window.tabbedWindows;
                if(tabIndex < tabbedWindows.count) {
                    [[tabbedWindows objectAtIndex:tabIndex] makeKeyAndOrderFront:nil];
                }
                
            }
        }
        
    }
    [super sendEvent:event];
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
