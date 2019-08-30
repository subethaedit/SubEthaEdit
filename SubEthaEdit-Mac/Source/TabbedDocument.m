//
//  TabbedDocument.m
//  SubEthaEdit
//
//  Created by Francisco Tolmasky on 8/30/19.
//  Copyright © 2019 SubEthaEdit Contributors. All rights reserved.
//

#import "TabbedDocument.h"

@implementation TabbedDocument

- (void)alert:(NSString *)message
        style:(NSAlertStyle)style
      details:(NSString *)details
      buttons:(NSArray *)buttons
         then:(nullable AlertConsequence)then {
    NSAlert *alert = [[NSAlert alloc] init];

    [alert setAlertStyle:style];
    [alert setMessageText:message];
    [alert setInformativeText:details];

    for (NSString * button in buttons) {
        [alert addButtonWithTitle: button];
    }

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
    NSArray *orderedWindows = NSApp.orderedWindows;
    NSSet *candidateWindows = [NSSet setWithArray:[self.windowControllers valueForKey:@"window"]];

    NSUInteger index = [orderedWindows indexOfObjectPassingTest:
                        ^(NSWindow *window, NSUInteger idx, BOOL *_stop) {
                            return [candidateWindows containsObject:window];
                        }];

    NSWindow *window = orderedWindows[index];
    NSArray *windowControllers = self.windowControllers;

    // Temporary code to test style of alert icon
    for (NSWindowController *controller in windowControllers) {
        //controller.showsCautionSymbolInTab = YES;
    }

    completionHandler = ^(NSModalResponse returnCode) {
        for (NSWindowController *controller in windowControllers) {
            //controller.showsCautionSymbolInTab = NO;
        }
        if (completionHandler) {
            completionHandler(returnCode);
        }
    };

    [window makeKeyAndOrderFront:self];
    [alert beginSheetModalForWindow:window completionHandler:completionHandler];
}

@end
