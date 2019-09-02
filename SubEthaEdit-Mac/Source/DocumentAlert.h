//
//  ConsequentialAlert.h
//  SubEthaEdit
//
//  Created by Francisco Tolmasky on 8/30/19.
//  Copyright © 2019 SubEthaEdit Contributors. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef void (^AlertConsequence)(__kindof NSDocument *, NSModalResponse);

@interface DocumentAlert : NSObject

@property (readonly, strong) NSString *message;
@property (readonly) NSAlertStyle style;
@property (readonly, strong) NSString *details;
@property (readonly, copy) NSArray *buttons;
@property (readonly, copy) AlertConsequence then;

- (instancetype)initWithMessage:(NSString *)message
                          style:(NSAlertStyle)style
                        details:(NSString *)details
                        buttons:(NSArray *)buttons
                           then:(AlertConsequence)then;
- (NSAlert *)instantiateAlert;

@end
