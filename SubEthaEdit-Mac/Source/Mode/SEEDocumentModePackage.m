//  SEEDocumentModePackage.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 2021-04-07

#import "SEEDocumentModePackage.h"
#import "DocumentModeManager.h"
#import "LMPTOMLSerialization.h"

NSString * const SEEDocumentModeErrorDomain = @"SEEDocumentModeErrorDomain";

@interface SEEDocumentModePackage()
@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) NSBundle *bundle;
@end

@implementation SEEDocumentModePackage

- (instancetype)initWithURL:(NSURL *)packageURL error:(NSError **)error {
    if ((self = [super init])) {
        _url = packageURL;
        NSString *extension = packageURL.pathExtension;
        if ([extension isEqualToString:MODE_EXTENSION]) {
            _bundle = [NSBundle bundleWithURL:_url];
            if (!_bundle) {
                if (*error) {
                    *error = [NSError errorWithDomain:SEEDocumentModeErrorDomain
                                                 code:NSFileReadUnknownError
                                             userInfo:@{
                                                 NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Could not read bundle at '%@'", _url.absoluteURL],
                                                        }];
                }
                self = nil;
            }
        } else if ([extension isEqualToString:MODE5_EXTENSION]) {
            NSError *error;
            NSData *data = [NSData dataWithContentsOfURL:[_url URLByAppendingPathComponent:@"SEEMode.toml"] options:0 error:&error];
            if (data && !error) {
                NSDictionary *toml = [LMPTOMLSerialization TOMLObjectWithData:data error:&error];
                NSLog(@"%s, %@",__FUNCTION__,toml);
            }
            
            if (error) {
                NSLog(@"%s, %@",__FUNCTION__,error);
            }
            
            self = nil;
        } else {
            self = nil;
        }
    }
    return self;
}

- (NSURL *)packageURL {
    return _url;
}

- (NSString *)modeIdentifier {
    return _bundle.bundleIdentifier;
}

- (NSString *)modeName {
    return _bundle.infoDictionary[@"CFBundleName"];
}

- (ModeSettings *)modeSettings {
    return [[ModeSettings alloc] initWithFile:[_bundle pathForResource:@"ModeSettings" ofType:@"xml"]];
}

- (NSString *)modeVersion {
    return [_bundle objectForInfoDictionaryKey:@"CFBundleVersion"];
}

@end
