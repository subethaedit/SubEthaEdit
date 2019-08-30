//
//  ConsequentialAlert.m
//  SubEthaEdit
//
//  Created by Francisco Tolmasky on 8/30/19.
//  Copyright © 2019 SubEthaEdit Contributors. All rights reserved.
//

#import "DocumentAlert.h"

@implementation DocumentAlert

- (instancetype)initWithMessage:(NSString *)message
                          style:(NSAlertStyle)style
                        details:(NSString *)details
                        buttons:(NSArray *)buttons
                           then:(AlertConsequence)then
{
    self = [super init];

    if (self) {
        self.messageText = message;
        self.alertStyle = style;
        self.informativeText = details;

        for (NSString *button in buttons)
            [self addButtonWithTitle:button];

        _then = [then copy];
    }

    return self;
}

@end
