//  SEEStringEncodingHelper.m
//  SubEthaEdit
//
//  Created by dom on 18.03.2021.

#import "SEEStringEncodingHelper.h"

#import <UniversalDetector/UniversalDetector.h>

#import "EncodingManager.h"
#import "UKXattrMetadataStore.h"

@implementation SEEStringEncodingHelper

+ (NSStringEncoding)bestGuessStringEncodingForFileAtURL:(NSURL *)url error:(NSError **)error data:(NSData **)outData {
    // first things first, try xattrs
    NSString *encodingXattrKey = @"com.apple.TextEncoding";
    NSString *xattrEncoding = [UKXattrMetadataStore stringForKey:encodingXattrKey atPath:[url path] traverseLink:YES];
    if (xattrEncoding) {
        __auto_type elements = [xattrEncoding componentsSeparatedByString:@";"];
        NSStringEncoding xEncoding = NoStringEncoding;
        if (elements.count > 0) {
            // test first part if its an IANA encoding
            NSString *ianaEncodingString = elements[0];
            if ([ianaEncodingString length]>0) {
                CFStringEncoding cfEncoding = CFStringConvertIANACharSetNameToEncoding((__bridge CFStringRef)ianaEncodingString);
                if (cfEncoding != kCFStringEncodingInvalidId) {
                    xEncoding = CFStringConvertEncodingToNSStringEncoding(cfEncoding);
                }
            }
            if (xEncoding == NoStringEncoding && elements.count>1) {
                NSScanner *scanner = [NSScanner scannerWithString:elements[1]];
                int scannedCFEncoding = 0;
                if ([scanner scanInt:&scannedCFEncoding]) {
                    xEncoding = CFStringConvertEncodingToNSStringEncoding(scannedCFEncoding);
                }
            }
            
            if (xEncoding != NoStringEncoding) {
                return xEncoding;
            }
        }
    }
    
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
//    float confidence = [detector confidence];
//    NSLog(@"UD: Encoding:%@ confidence:%f", [SEEStringEncodingHelper debugDescriptionForStringEncoding:udEncoding], confidence);
    return udEncoding;
}

+ (void)writeStringEncoding:(NSStringEncoding)encoding toXattrsOfURL:(NSURL *)url {
    // write the xtended attribute for encoding
    CFStringEncoding cfEncoding = CFStringConvertNSStringEncodingToEncoding(encoding);
    CFStringRef encodingIANACharSetName = CFStringConvertEncodingToIANACharSetName(cfEncoding);
    NSString *encodingMetadata = [NSString stringWithFormat:@"%@;%u", encodingIANACharSetName, (unsigned int)cfEncoding];
    
    [UKXattrMetadataStore setString:encodingMetadata
                             forKey:@"com.apple.TextEncoding"
                             atPath:url.path
                       traverseLink:YES];
}

@end
