//
//  TabbedDocument.m
//  SubEthaEdit
//
//  Created by Francisco Tolmasky on 8/30/19.
//  Copyright © 2019 SubEthaEdit Contributors. All rights reserved.
//

#import "TabbedDocument.h"


static __auto_type windowHasAttachedSheet =
 ^ (NSWindow *window, NSUInteger index, BOOL *stop) {
    return (BOOL)(window.attachedSheet != nil);
};

static __auto_type isSelectedWindowInTabGroup =
 ^ (NSWindow *window, NSDictionary * bindings) {
    return (BOOL)(window.tabGroup.selectedWindow != window);
};

@interface TabbedDocument () {
    NSMutableArray * _mutableAlerts;
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

// As we have not implemented document-based alert queueing yet, this simply returns
// YES if any of it's associated windows has a sheet attached. The eventual theory is
// that if *any* window has a sheet, they (conceptually) *all should*. In a following
// commit, this will be expanded to the possibility that no window is *actively*
// showing a sheet, but may have one queued (in the case where every tab representing
// the document is hidden).
- (BOOL)hasAlerts {
    NSArray *windows = [self.windowControllers valueForKey:@"window"];
    NSUInteger index = [windows indexOfObjectPassingTest:windowHasAttachedSheet];
    BOOL anyWindowHasAttachedSheet = index != NSNotFound;

    return anyWindowHasAttachedSheet;
}

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

    __unsafe_unretained NSDocument *weakSelf = self;
    [self presentAlert:alert completionHandler:^(NSModalResponse returnCode) {
        NSDocument *strongSelf = weakSelf;
        if (strongSelf && then) {
            then(strongSelf, returnCode);
        }
    }];
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

- (void)presentAlert:(NSAlert *)alert completionHandler:(void (^)(NSModalResponse returnCode))completionHandler {
    NSWindow *window = [self bestWindowToInitiallyDisplayAlert];

    if (window) {
        [alert beginSheetModalForWindow:window completionHandler:completionHandler];
    }
}

- (NSWindow *)bestWindowToInitiallyDisplayAlert {
    // If the main window belongs to this document, then it is clear that
    // this window should initially display this alert. It's the one right
    // in front of the user, so there is no reason to suppress it, and it
    // is by definition the frontmost window (that matters).
    if (NSApp.mainWindow.windowController.document == self)
        return NSApp.mainWindow;

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
                 NSStringFromSelector(@selector(windowDidEndSheet:))
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
}

@end
