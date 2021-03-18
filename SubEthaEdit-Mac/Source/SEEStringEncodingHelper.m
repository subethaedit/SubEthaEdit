//  SEEStringEncodingHelper.m
//  SubEthaEdit
//
//  Created by dom on 18.03.2021.

#import "SEEStringEncodingHelper.h"

#import <UniversalDetector/UniversalDetector.h>

@implementation SEEStringEncodingHelper

+ (NSStringEncoding)bestGuessStringEncodingForFileAtURL:(NSURL *)url error:(NSError **)error data:(NSData **)outData {
    NSData *data = [NSData dataWithContentsOfURL:url options:0 error:error];
    if (outData && data) {
        *outData = data;
    }
    return [self bestGuessStringEncodingForData:data];
}

+ (NSStringEncoding)bestGuessStringEncodingForData:(NSData *)contentData {
    NSStringEncoding result = [NSString stringEncodingForData:contentData encodingOptions:@{
        NSStringEncodingDetectionAllowLossyKey : @NO,
    } convertedString:nil usedLossyConversion:nil];
    if (result == 0) {
        // try some fallbacks here
        NSLog(@"%s could not determine encoding here", __PRETTY_FUNCTION__);
    }
    return result;
}

+ (NSString *)debugDescriptionForStringEncoding:(NSStringEncoding)encoding {
    return [NSString stringWithFormat:@"%@|(%lu: %@)", [self IANACharsetNameOfStringEncoding:encoding], (unsigned long)encoding, [NSString localizedNameOfStringEncoding:encoding]];
}

+ (NSString *)IANACharsetNameOfStringEncoding:(NSStringEncoding)encoding {
    NSString *result = (__bridge NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(encoding));
    return result;
}

+ (NSStringEncoding)universalDetectorStringEncodingForData:(NSData *)contentData {
    NSStringEncoding udEncoding=NSUTF8StringEncoding;
    // guess encoding based on character sniffing
    UniversalDetector  *detector = [[UniversalDetector alloc] init];
    NSData *checkData = contentData;
    [detector analyzeData:checkData];
    udEncoding = [detector encoding];
    float confidence = [detector confidence];
//    NSLog(@"UD: Encoding:%@ confidence:%f", [SEEStringEncodingHelper debugDescriptionForStringEncoding:udEncoding], confidence);
    return udEncoding;
}


@end
