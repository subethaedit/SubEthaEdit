//
//  TabbedDocument.m
//  SubEthaEdit
//
//  Created by Francisco Tolmasky on 8/30/19.
//  Copyright © 2019 SubEthaEdit Contributors. All rights reserved.
//

#import "TabbedDocument.h"

#define IMMEDIATELY_DISPLAY_ALERT_IF_FRONTMOST_TAB NO

static __auto_type windowHasAttachedSheet =
 ^ (NSWindow *window, NSUInteger index, BOOL *stop) {
    return (BOOL)(window.attachedSheet != nil);
};

static __auto_type isSelectedWindowInTabGroup =
 ^ (NSWindow *window, NSDictionary * bindings) {
    return (BOOL)(window.tabGroup.selectedWindow != window);
};

@interface TabbedDocument () {
    NSMutableArray<DocumentAlert *> * _mutableAlerts;
}
@end

@implementation TabbedDocument

- (instancetype)init {
    self = [super init];

    if (self) {
        _mutableAlerts = [NSMutableArray new];
    }

    return self;
}

// There are two cases in which we could "have alerts": the trivial case is that our
// document alert queue has items in it. Alternatively, we also have to check if any
// of our associated windows has a sheet up. This is because we only "control" a
// subset of alerts: things such as the Save-As panel don't go through this system,
// but we still want background tabs to show an icon notifying the user that the tab
// requires the user's attention.
- (BOOL)hasAlerts {
    return  _mutableAlerts.count > 0 ||
            [self.windows indexOfObjectPassingTest:windowHasAttachedSheet] != NSNotFound;
}

// This is the method all other alert types get funneled through. If there is an
// available window to show this alert to, it will present it immediately. Otherwise
// it will queue it for later.
- (void)alert:(NSString *)message
        style:(NSAlertStyle)style
      details:(NSString *)details
      buttons:(NSArray *)buttons
         then:(AlertConsequence)then {
    DocumentAlert *alert =
        [[DocumentAlert alloc] initWithMessage:message
                                         style:style
                                       details:details
                                       buttons:buttons
                                          then:then];

    // Store this now since we'll be mutating the queue momentarily.
    BOOL alreadyHasAlerts = self.hasAlerts;

    [self willChangeValueForKey:@"hasAlerts"];
    [_mutableAlerts addObject:alert];
    [self didChangeValueForKey:@"hasAlerts"];

    // If we already have alerts in the queue (and thus either displaying
    // or waiting to display), then there is nothing left for us to do.
    // Once they get dismissed, it will be our turn.
    if (alreadyHasAlerts)
        return;

    NSWindow *initialWindow = self.bestWindowToInitiallyDisplayAlert;

    // If no current window is available to display the alert, we are
    // similarly done.
    if (initialWindow == nil)
        return;

    // Looks like we can actually present this one!
    [self presentCurrentAlertInWindow:initialWindow];
}

- (void)inform:(NSString *)message details:(NSString *)details {
    [self alert:message
          style:NSAlertStyleInformational
        details:details
        buttons:@[NSLocalizedString(@"OK", nil)]
           then:nil];
}

- (void)warn:(NSString *)message
     details:(NSString *)details
     buttons:(NSArray *)buttons
        then:(AlertConsequence)then {
    [self alert:message
          style:NSAlertStyleWarning
        details:details
        buttons:buttons
           then:then];
}

- (void)presentCurrentAlertInWindow:(NSWindow *)window {
    NSAlert *alert = [_mutableAlerts[0] instantiateAlert];
    AlertConsequence then = _mutableAlerts[0].then;

    __unsafe_unretained TabbedDocument *weakSelf = self;
    __auto_type completionHandler = ^(NSModalResponse returnCode) {
        // We receive NSModalResponseStop when the alert is canceled by endSheet:.
        if (returnCode == NSModalResponseStop)
            return;

        TabbedDocument *strongSelf = weakSelf;
        [strongSelf->_mutableAlerts removeObjectAtIndex:0];

        if (strongSelf && then) {
            then(strongSelf, returnCode);
        }

        for (NSWindow *window in strongSelf.windows)
            if (window.attachedSheet)// && window.attachedSheet)
                [window endSheet:window.attachedSheet];
    };

    [alert beginSheetModalForWindow:window completionHandler:completionHandler];
}

// Add a pound define for the only front behavior.
- (NSWindow *)bestWindowToInitiallyDisplayAlert {
    // If the main window belongs to this document, then it is clear that
    // this window should initially display this alert. It's the one right
    // in front of the user, so there is no reason to suppress it, and it
    // is by definition the frontmost window (that matters).
    if (NSApp.mainWindow.windowController.document == self)
        return NSApp.mainWindow;

#if !IMMEDIATELY_DISPLAY_ALERT_IF_FRONTMOST_TAB
    return nil;
#else
    NSArray *windows = [self.windowControllers valueForKey:@"window"];

    // Otherwise, to qualify as a candidate window, the window must currently
    // not be in a background tab in it's respective tab group.
    NSPredicate *isSelectedPredicate = [NSPredicate predicateWithBlock:isSelectedWindowInTabGroup];
    NSArray *candidateWindows = [windows filteredArrayUsingPredicate:isSelectedPredicate];

    // If there's no such window, then all possible windows are hidden and we must wait
    // for one of them to be activated before showing anything.
    if (candidateWindows.count == 0)
        return nil;

    // If there's only one such window, no need to calculate anything further.
    if (candidateWindows.count == 1)
        return candidateWindows[0];

    // If there's *multiple* windows, then choose the frontmost one. Unfortunately,
    // the only way to do this is to iterate over the global ordering of windows in
    // our app. Luckily though, we can at least put the candidates in a set so that
    // we can quickly return on the first one we find and do this in O(N).
    NSArray *orderedWindows = NSApp.orderedWindows;
    NSSet *candidateWindowSet = [NSSet setWithArray:candidateWindows];
    NSUInteger index = [orderedWindows indexOfObjectPassingTest:
                        ^(NSWindow *window, NSUInteger idx, BOOL *_stop) {
                            return [candidateWindowSet containsObject:window];
                        }];

    // Return the first one we find, which we know can't be NSNotFound since we'd
    // only make it this far if candidateWindows.count >= 2.
    return orderedWindows[index];
#endif
}

- (NSArray *)windows {
    return [self.windowControllers valueForKey:@"window"];
}

@end


@implementation TabbedDocument (SheetSynchronization)

// We collect all the notification names and selectors we care about in this method
// to avoid potential bugs of forgetting to remove an observer we've added.
- (NSDictionary *)windowNotifications {
    return @{
             NSWindowWillBeginSheetNotification:
                 NSStringFromSelector(@selector(windowWillBeginSheet:)),
             NSWindowDidEndSheetNotification:
                 NSStringFromSelector(@selector(windowDidEndSheet:)),
             NSWindowDidBecomeMainNotification:
                 NSStringFromSelector(@selector(windowDidBecomeMain:))
             };
}

- (void)addWindowController:(NSWindowController *)windowController {
    [super addWindowController:windowController];

    NSNotificationCenter *defaultCenter = NSNotificationCenter.defaultCenter;
    NSDictionary *notifications = self.windowNotifications;
    for (NSString *name in notifications) {
        [defaultCenter addObserver:self
                          selector:NSSelectorFromString(notifications[name])
                              name:name
                            object:windowController.window];
    }
}

- (void)removeWindowController:(NSWindowController *)windowController {
    [super removeWindowController:windowController];

    NSNotificationCenter *defaultCenter = NSNotificationCenter.defaultCenter;
    for (NSString *name in self.windowNotifications) {
        [defaultCenter removeObserver:self
                                 name:name
                               object:windowController.window];
    }
}


// We actually would like window*Did*BeginSheet:, but unfortunately that notification
// doesn't exist, so at this point window.attachedSheet is still nil. For this reason
// the willChangeValueForKey: is correct, but we have to delay the didChangeValueForKey:.
- (void)windowWillBeginSheet:(NSNotification *)notification {
    [self willChangeValueForKey:@"hasAlerts"];

    [NSOperationQueue TCM_performBlockOnMainQueue:^{
        [self didChangeValueForKey:@"hasAlerts"];
    } afterDelay:0.0];
}

- (void)windowDidEndSheet:(NSNotification *)notification {
    [self willChangeValueForKey:@"hasAlerts"];
    [self didChangeValueForKey:@"hasAlerts"];

    NSWindow *window = notification.object;
    // window.sheets?
    if (window == NSApp.mainWindow && _mutableAlerts.count > 0)
        [self presentCurrentAlertInWindow:window];
}

- (void)windowDidBecomeMain:(NSNotification *)notification {
    NSWindow *window = notification.object;
    if (!window.attachedSheet && self.hasAlerts) {
        // We need to delay this to get the proper animation, if not the sheet
        // just pops in.
        [NSOperationQueue TCM_performBlockOnMainQueue:^{
            [self presentCurrentAlertInWindow:window];
        } afterDelay:0.0];
    }
}

@end
