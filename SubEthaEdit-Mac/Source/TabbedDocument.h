//
//  TabbedDocument.h
//  SubEthaEdit
//
//  Created by Francisco Tolmasky on 8/30/19.
//  Copyright © 2019 SubEthaEdit Contributors. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SEEAlertRecipe.h"


@interface TabbedDocument : NSDocument

@property (nonatomic, readonly) BOOL hasAlerts;

- (void)alert:(NSString *)message
        style:(NSAlertStyle)style
      details:(NSString *)details
      buttons:(NSArray *)buttons
completionHandler:(SEEAlertCompletionHandler)then;

- (void)inform:(NSString *)message details:(NSString *)details;

- (void)warn:(NSString *)message
     details:(NSString *)details
     buttons:(NSArray *)buttons
completionHandler:(SEEAlertCompletionHandler)then;

@end
