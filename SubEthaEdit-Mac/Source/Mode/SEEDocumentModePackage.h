//  SEEDocumentModePackage.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 2021-04-07

#import <Foundation/Foundation.h>
#import "ModeSettings.h"

@interface SEEDocumentModePackage : NSObject

@property (nonatomic, readonly) NSURL *packageURL;
@property (nonatomic, readonly) NSString *modeIdentifier;
@property (nonatomic, readonly) NSString *modeName;
@property (nonatomic, readonly) NSString *modeVersion;
@property (nonatomic, readonly) ModeSettings *modeSettings;

- (instancetype)initWithURL:(NSURL *)packageURL error:(NSError **)error;

@end
