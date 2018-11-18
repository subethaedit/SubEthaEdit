//  TCMSystemConfiguration.h
//  TCMPortMapper
//

@import Foundation;

@class TCMSystemConfiguration;
typedef void (^TCMSystemConfigurationDidChangeCallback)(TCMSystemConfiguration *config, NSArray<NSString *> *changedKeys);

NS_ASSUME_NONNULL_BEGIN
@interface TCMSystemConfiguration : NSObject
+ (instancetype)sharedConfiguration;

- (id)observeConfigurationKeys:(NSArray<NSString *> *)keys observationBlock:(TCMSystemConfigurationDidChangeCallback)callbackBlock;
- (void)removeConfigurationKeyObservation:(id)observation;

@end

NS_ASSUME_NONNULL_END
