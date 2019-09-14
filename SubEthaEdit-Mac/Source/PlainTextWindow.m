//  PlainTextWindow.m
//  SubEthaEdit
//
//  Created by Martin Ott on 11/23/06.

#import "PlainTextWindow.h"
#import "PlainTextWindowController.h"
#import "PreferenceKeys.h"

@implementation PlainTextWindow

- (IBAction)performClose:(id)sender {
    if ([[self windowController] isKindOfClass:[PlainTextWindowController class]]) {
        [(PlainTextWindowController *)[self windowController] closeTab:sender];
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

- (void)setDocumentEdited:(BOOL)flag {
    NSDocument *document = [[self windowController] document];
    if (document) {
        [super setDocumentEdited:[document isDocumentEdited]];
    } else {
        [super setDocumentEdited:flag];
    }
}

static NSPoint placeWithCascadePoint(NSWindow *window, NSPoint cascadePoint) {
    NSScreen *screen = [NSScreen screenContainingPoint:cascadePoint] ?: [NSScreen menuBarContainingScreen];
    NSRect visibleFrame = [screen visibleFrame];

    // check if the top plain text window window is on the same screen, if not, cascading from the top window
    for (NSWindow *window in NSApp.orderedWindows) {
        if ([window isKindOfClass:[PlainTextWindow class]]) {
            if ([window screen] != screen) {
                screen = [window screen];
                visibleFrame = [screen visibleFrame];
                cascadePoint = NSMakePoint(MAX(NSMinX([window frame]), NSMinX(visibleFrame)),
                                               NSMaxY([window frame]));
            }
            break;
        }
    }
    
    NSPoint placementPoint = cascadePoint;
    
    NSRect currentFrame = window.frame;

    // Contstrain top to Visible frame
    placementPoint.y = MIN(placementPoint.y, NSMaxY(visibleFrame));
    
    // Wrap back to left edge if we would move out on the right
    if (placementPoint.x + NSWidth(currentFrame) > NSMaxX(visibleFrame)) {
        placementPoint.x = NSMinX(visibleFrame);
    }
    
    // Constrain left to visible Frame
    placementPoint.x = MAX(placementPoint.x,
                   NSMinX(visibleFrame));
    
    // Warp back to top if we shoot over the bottom
    if (placementPoint.y - NSHeight(currentFrame) < NSMinY(visibleFrame)) {
        placementPoint.y = NSMaxY(visibleFrame);
    }
    
    [window setFrameTopLeftPoint:placementPoint];
    return placementPoint;
}

- (NSPoint)cascadeTopLeftFromPoint:(NSPoint)cascadeFromPoint {
    // 0.0 is supposed to not cascade and just move/resize to visible
    if (NSEqualPoints(cascadeFromPoint, NSZeroPoint)) {
        return [super cascadeTopLeftFromPoint:cascadeFromPoint];
    }

    NSPoint placedPoint = placeWithCascadePoint(self, cascadeFromPoint);
    CGVector offset = (CGVector){.dx = 21, .dy = -23.};
    return (NSPoint){ .x = placedPoint.x + offset.dx, .y = placedPoint.y + offset.dy};
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

- (void)ensureTabBarVisiblity:(BOOL)shouldAlwaysBeVisible {
    NSWindowTabGroup *group = self.tabGroup;
    if (group.windows.count == 1) {
        BOOL isVisible = group.isTabBarVisible;
        if ((isVisible && !shouldAlwaysBeVisible) ||
            (!isVisible && shouldAlwaysBeVisible)) {
            [super toggleTabBar:nil];
        }
    }
}

- (void)awakeFromNib {
    self.tab.accessoryView = self.cautionView;
    self.cautionView.hidden = YES;
}

- (BOOL)showsCautionSymbolInTab {
    return !self.cautionView.hidden;
}

- (void)setShowsCautionSymbolInTab:(BOOL)showsCautionSymbolInTab {
    self.cautionView.hidden = !showsCautionSymbolInTab;
}


@end
