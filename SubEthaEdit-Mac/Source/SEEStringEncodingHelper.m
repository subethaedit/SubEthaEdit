//  SEEStringEncodingHelper.m
//  SubEthaEdit
//
//  Created by dom on 18.03.2021.

#import "SEEStringEncodingHelper.h"

@implementation SEEStringEncodingHelper

+ (NSStringEncoding)bestGuessStringEncodingForFileAtURL:(NSURL *)url error:(NSError **)error data:(NSData **)outData {
    NSData *data = [NSData dataWithContentsOfURL:url options:0 error:error];
    if (outData && data) {
        *outData = data;
    }
    return [self bestGuessStringEncodingForData:data];
}

+ (NSStringEncoding)bestGuessStringEncodingForData:(NSData *)contentData {
    return [NSString stringEncodingForData:contentData encodingOptions:nil convertedString:nil usedLossyConversion:nil];
}

+ (NSString *)debugDescriptionForStringEncoding:(NSStringEncoding)encoding {
    return [NSString stringWithFormat:@"%@|(%lu: %@)", [self IANACharsetNameOfStringEncoding:encoding], (unsigned long)encoding, [NSString localizedNameOfStringEncoding:encoding]];
}

+ (NSString *)IANACharsetNameOfStringEncoding:(NSStringEncoding)encoding {
    NSString *result = (__bridge NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(encoding));
    return result;
}

@end
