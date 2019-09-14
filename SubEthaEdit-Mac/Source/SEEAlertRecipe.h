//  SEEAlertRecipe.h
//  SubEthaEdit
//

#import <Cocoa/Cocoa.h>

typedef void (^SEEAlertCompletionHandler)(__kindof NSDocument *, NSModalResponse);

@interface SEEAlertRecipe : NSObject

@property (readonly, strong) NSString *message;
@property (readonly) NSAlertStyle style;
@property (readonly, strong) NSString *details;
@property (readonly, copy) NSArray *buttons;
@property (readonly, copy) SEEAlertCompletionHandler completionHandler;

- (instancetype)initWithMessage:(NSString *)message
                          style:(NSAlertStyle)style
                        details:(NSString *)details
                        buttons:(NSArray *)buttons
              completionHandler:(SEEAlertCompletionHandler)then;
- (NSAlert *)instantiateAlert;

@end
