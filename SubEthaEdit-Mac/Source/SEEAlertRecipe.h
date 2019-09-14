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
@property (nonatomic, strong) NSString *coalescingIdentifier;
@property (nonatomic, strong) void (^alertAdjustment)(NSAlert *alert);
@property (nonatomic) BOOL requiresImmediacy;

- (instancetype)initWithMessage:(NSString *)message
                          style:(NSAlertStyle)style
                        details:(NSString *)details
                        buttons:(NSArray *)buttons
              completionHandler:(SEEAlertCompletionHandler)then;

+ (instancetype)warningWithMessage:(NSString *)message details:(NSString *)details buttons:(NSArray <NSString *>*)buttonTitles completionHandler:(SEEAlertCompletionHandler)completion;
+ (instancetype)informationWithMessage:(NSString *)message details:(NSString *)details;

- (NSAlert *)instantiateAlert;


@end
