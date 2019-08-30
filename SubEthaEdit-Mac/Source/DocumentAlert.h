//
//  ConsequentialAlert.h
//  SubEthaEdit
//
//  Created by Francisco Tolmasky on 8/30/19.
//  Copyright © 2019 SubEthaEdit Contributors. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^AlertConsequence)(__kindof NSDocument *, NSModalResponse);

@interface DocumentAlert : NSAlert

@property (readonly, copy) AlertConsequence then;

- (instancetype)initWithMessage:(NSString *)message
                          style:(NSAlertStyle)style
                        details:(NSString *)details
                        buttons:(NSArray *)buttons
                           then:(AlertConsequence)then;

@end

NS_ASSUME_NONNULL_END
