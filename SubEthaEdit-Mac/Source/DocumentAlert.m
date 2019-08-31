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
        _message = message;
        _style = style;
        _details = details;
        _buttons = buttons;
        _then = [then copy];
    }

    return self;
}

- (NSAlert *)instantiateAlert {
    NSAlert *alert = [[NSAlert alloc] init];

    alert.alertStyle = _style;
    alert.messageText = _message;
    alert.informativeText = _details;

    for (NSString *button in _buttons)
        [alert addButtonWithTitle:button];

    return alert;
}

@end
