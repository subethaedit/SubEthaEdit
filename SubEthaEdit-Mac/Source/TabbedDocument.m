//  TabbedDocument.m
//  SubEthaEdit
//

#import "TabbedDocument.h"
#import "PlainTextWindowController.h"
#import "PlainTextWindow.h"

@interface TabbedDocument ()
@property (nonatomic, strong) NSMutableArray<SEEAlertRecipe *> *alertRecipeQueue;
@property (nonatomic, strong) SEEAlertRecipe *currentAlertRecipe;
@property (nonatomic, readonly) BOOL hasAnyAttachedSheetInAnyDocumentWindow;
@property (nonatomic, strong) NSArray <PlainTextWindow *> *documentWindows;
@property (nonatomic, strong) NSArray <PlainTextWindow *> *orderedDocumentWindows;
@end

@implementation TabbedDocument

- (instancetype)init {
    if ((self = [super init])) {
        _alertRecipeQueue = [NSMutableArray new];
    }

    return self;
}

/**
 @return YES if alert recipes are queued, one is currently displayed, or any of our windows has an attached sheet
 */
- (BOOL)hasAlerts {
    return  (_currentAlertRecipe ||
             _alertRecipeQueue.count > 0 ||
             [self hasAnyAttachedSheetInAnyDocumentWindow]);
}

- (void)enqueueAlertRecipe:(SEEAlertRecipe *)recipe {
    [self willChangeValueForKey:@"hasAlerts"];
    [_alertRecipeQueue addObject:recipe];
    [self didChangeValueForKey:@"hasAlerts"];
}

// This is the method all other alert types get funneled through. If there is an
// available window to show this alert to, it will present it immediately. Otherwise
// it will queue it for later.
- (void)alert:(NSString *)message
        style:(NSAlertStyle)style
      details:(NSString *)details
      buttons:(NSArray *)buttons
completionHandler:(SEEAlertCompletionHandler)then {
    SEEAlertRecipe *alert =
    [[SEEAlertRecipe alloc] initWithMessage:message
                                      style:style
                                    details:details
                                    buttons:buttons
                          completionHandler:then];

    // Store this now since we'll be mutating the queue momentarily.
    BOOL alreadyHasAlerts = self.hasAlerts;
    
    NSWindow *window = [self windowForImmediateAlertDisplay];
    
    if (alreadyHasAlerts || !window) {
        // No need to act, things will happen by events when needed.
        [self enqueueAlertRecipe:alert];
    } else {
        self.currentAlertRecipe = alert;
        [self presentCurrentAlertInWindow:window];
    }
}

- (void)inform:(NSString *)message details:(NSString *)details {
    [self alert:message
          style:NSAlertStyleInformational
        details:details
        buttons:@[NSLocalizedString(@"OK", nil)]
completionHandler:nil];
}

- (void)warn:(NSString *)message
     details:(NSString *)details
     buttons:(NSArray *)buttons
        completionHandler:(SEEAlertCompletionHandler)then {
    [self alert:message
          style:NSAlertStyleWarning
        details:details
        buttons:buttons
           completionHandler:then];
}

- (void)presentCurrentAlertInWindow:(NSWindow *)window {
    SEEAlertRecipe *recipe = self.currentAlertRecipe;
    NSAlert *alert = [recipe instantiateAlert];
    SEEAlertCompletionHandler then = recipe.completionHandler;

    __weak TabbedDocument *weakSelf = self;
    __auto_type completionHandler = ^(NSModalResponse returnCode) {
        
        // We receive NSModalResponseStop when the alert is canceled by endSheet:.
        if (returnCode == NSModalResponseStop) {
            return;
        }
        
        TabbedDocument *strongSelf = weakSelf;
        if (strongSelf.currentAlertRecipe == recipe) {
            strongSelf.currentAlertRecipe = nil;
            for (NSWindow *window in self.documentWindows) {
                if (window.attachedSheet) {
                    [window endSheet:window.attachedSheet];
                }
            }
        }

        if (strongSelf && then) {
            then(strongSelf, returnCode);
        }
    };

    [alert beginSheetModalForWindow:window completionHandler:completionHandler];
}

/**
 @return a window of the current document that is appropriate for immediate alert display, nil otherwise
 */
- (NSWindow *)windowForImmediateAlertDisplay {
    
    NSWindow *mainWindow = NSApp.mainWindow;
    if (mainWindow.windowController.document == self) {
        return mainWindow;
    }
    
    return [self.orderedDisplayedDocumentWindows firstObject];
}

- (BOOL)hasAnyAttachedSheetInAnyDocumentWindow {
    static __auto_type windowHasAttachedSheet =
    ^(NSWindow *window, NSUInteger index, BOOL *stop) {
        return (BOOL)(window.attachedSheet != nil);
    };
    

    return ([self.documentWindows indexOfObjectPassingTest:windowHasAttachedSheet] != NSNotFound);
}

- (NSArray <PlainTextWindow *>*)documentWindows {
    NSMutableArray *candidates = [NSMutableArray new];
    [self.windowControllers enumerateObjectsUsingBlock:^(NSWindowController *wc, NSUInteger _idx, BOOL *_stop) {
        if ([wc isKindOfClass:[PlainTextWindowController class]]) {
            NSWindow *window = wc.window;
            [candidates addObject:window];
        }
    }];
    
    if (candidates.count > 1) {
        // TODO: depth sort it
    }
    return candidates;
}

- (NSArray *)orderedDisplayedDocumentWindows {
    NSMutableArray *candidates = [NSMutableArray new];
    [self.windowControllers enumerateObjectsUsingBlock:^(NSWindowController *wc, NSUInteger _idx, BOOL *_stop) {
        if ([wc isKindOfClass:[PlainTextWindowController class]]) {
            NSWindow *window = wc.window;
            if (window.tabGroup.selectedWindow == window) {
                [candidates addObject:window];
            }
        }
    }];
    
    if (candidates.count > 1) {
        // TODO: depth sort it
    }
    return candidates;
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
    
    if ([windowController isKindOfClass:[PlainTextWindowController class]]) {
        NSNotificationCenter *defaultCenter = NSNotificationCenter.defaultCenter;
        NSDictionary *notifications = self.windowNotifications;
        for (NSString *name in notifications) {
            [defaultCenter addObserver:self
                              selector:NSSelectorFromString(notifications[name])
                                  name:name
                                object:windowController.window];
        }
    }
}

- (void)removeWindowController:(NSWindowController *)windowController {
    [super removeWindowController:windowController];

    if ([windowController isKindOfClass:[PlainTextWindowController class]]) {
        NSNotificationCenter *defaultCenter = NSNotificationCenter.defaultCenter;
        for (NSString *name in self.windowNotifications) {
            [defaultCenter removeObserver:self
                                     name:name
                                   object:windowController.window];
        }
    }
}

- (void)presentNextQueuedAlertIfPossibleInWindow:(NSWindow *)window {
    if (!self.currentAlertRecipe &&
        !window.attachedSheet &&
        self.alertRecipeQueue.count > 0 &&
        ![self hasAnyAttachedSheetInAnyDocumentWindow] ) {
        self.currentAlertRecipe = [_alertRecipeQueue firstObject];
        [_alertRecipeQueue removeObjectAtIndex:0];
        [self presentCurrentAlertInWindow:window];
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
    if (window == NSApp.mainWindow) {
        [self presentNextQueuedAlertIfPossibleInWindow:window];
    }
}

- (void)windowDidBecomeMain:(NSNotification *)notification {
    NSWindow *window = notification.object;
    if (!window.attachedSheet && self.currentAlertRecipe) {
        [NSOperationQueue TCM_performBlockOnMainQueue:^{
            [self presentCurrentAlertInWindow:window];
        } afterDelay:0.0];
    } else {
        [NSOperationQueue TCM_performBlockOnMainQueue:^{
            [self presentNextQueuedAlertIfPossibleInWindow:window];
        } afterDelay:0.0];
    }
}

@end
