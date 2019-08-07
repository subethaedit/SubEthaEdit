//  PlainTextWindow.m
//  SubEthaEdit
//
//  Created by Martin Ott on 11/23/06.

#import "PlainTextWindow.h"
#import "PlainTextWindowController.h"
#import "PreferenceKeys.h"

@implementation PlainTextWindow

- (IBAction)performClose:(id)sender
{
    if ([[self windowController] isKindOfClass:[PlainTextWindowController class]]) {
        [(PlainTextWindowController *)[self windowController] closeAllTabs];
    } else {
        [super performClose:sender];
    }
}

- (void)sendEvent:(NSEvent *)event {
    // Handle ⌘ 1 ... ⌘ 9, ⌘ 0 shortcuts to select tabs
    if ([event type] == NSEventTypeKeyDown) {
        int flags = [event modifierFlags];
        if ((flags & NSEventModifierFlagCommand) &&
            !(flags & NSEventModifierFlagControl) &&
            [[event characters] length] == 1) {
            
            NSUInteger tabIndex = [@[@"1",@"2",@"3",@"4",@"5",@"6",@"7",@"8",@"9",@"0"] indexOfObject:event.characters];
            NSArray *tabbedWindows = self.tabbedWindows;
            if (tabIndex != NSNotFound &&
                tabIndex < tabbedWindows.count) {
                [[tabbedWindows objectAtIndex:tabIndex] makeKeyAndOrderFront:nil];
                return;
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
- (NSRect)constrainFrameRect:(NSRect)frameRect toScreen:(NSScreen *)screen {
    if (self.constrainingToScreenSuspended) {
        return frameRect;
    }
    else {
        return [super constrainFrameRect:frameRect toScreen:screen];
    }
}

- (IBAction)toggleTabBar:(id)sender {
    // Actual update is a side effect of the change
    SEEDocumentController.shouldAlwaysShowTabBar = !SEEDocumentController.shouldAlwaysShowTabBar;
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    if (menuItem.action == @selector(toggleTabBar:)) {
        BOOL alwaysShowTabBar = SEEDocumentController.shouldAlwaysShowTabBar;
        [menuItem setState:alwaysShowTabBar ? NSOnState : NSOffState];
        return YES;
    }
    return [super validateMenuItem:menuItem];
}

- (void)SEE_covered_toggleTabBar {
    // needed to actually switch the state if wrong, since cocoa doesn't expose any of this properly
    [super toggleTabBar:nil];
}

@end
