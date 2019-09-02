//
//  TabbedDocument.h
//  SubEthaEdit
//
//  Created by Francisco Tolmasky on 8/30/19.
//  Copyright © 2019 SubEthaEdit Contributors. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef void (^AlertConsequence)(__kindof NSDocument *, NSModalResponse);

@interface TabbedDocument : NSDocument

@property (readonly) BOOL hasAlerts;

- (void)alert:(NSString *)message
        style:(NSAlertStyle)style
      details:(NSString *)details
      buttons:(NSArray *)buttons
         then:(AlertConsequence)then;

- (void)inform:(NSString *)message details:(NSString *)details;

- (void)warn:(NSString *)message
     details:(NSString *)details
     buttons:(NSArray *)buttons
        then:(AlertConsequence)then;

@end
