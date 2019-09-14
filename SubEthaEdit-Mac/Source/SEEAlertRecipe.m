//  SEEAlertRecipe.m
//  SubEthaEdit
//
//  Created by Francisco Tolmasky on 8/30/19.

#import "SEEAlertRecipe.h"

@implementation SEEAlertRecipe

- (instancetype)initWithMessage:(NSString *)message
                          style:(NSAlertStyle)style
                        details:(NSString *)details
                        buttons:(NSArray *)buttons
              completionHandler:(SEEAlertCompletionHandler)then {

    if ((self = [super init])) {
        _message = message;
        _style = style;
        _details = details;
        _buttons = buttons;
        _completionHandler = then;
    }

    return self;
}

+ (instancetype)warningWithMessage:(NSString *)message details:(NSString *)details buttons:(NSArray <NSString *>*)buttonTitles completionHandler:(SEEAlertCompletionHandler)completion {
    SEEAlertRecipe *result = [[SEEAlertRecipe alloc] initWithMessage:message style:NSAlertStyleWarning details:details buttons:buttonTitles completionHandler:completion];
    return result;
}

+ (instancetype)informationWithMessage:(NSString *)message details:(NSString *)details {
    SEEAlertRecipe *result = [[SEEAlertRecipe alloc] initWithMessage:message style:NSAlertStyleInformational details:details buttons:@[NSLocalizedString(@"OK", nil)] completionHandler:nil];
    return result;
}

- (NSAlert *)instantiateAlert {
    NSAlert *alert = [[NSAlert alloc] init];

    alert.alertStyle = _style;
    alert.messageText = _message;
    alert.informativeText = _details;

    for (NSString *button in _buttons) {
        [alert addButtonWithTitle:button];
    }
    
    if (_alertAdjustment) {
        _alertAdjustment(alert);
    }
    
    return alert;
}

@end
