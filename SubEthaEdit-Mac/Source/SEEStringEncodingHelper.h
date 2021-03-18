//  SEEStringEncodingHelper.h
//  SubEthaEdit
//
//  Created by dom on 18.03.2021.

#import <Foundation/Foundation.h>

@interface SEEStringEncodingHelper : NSObject
+ (NSStringEncoding)bestGuessStringEncodingForFileAtURL:(NSURL *)url error:(NSError **)error data:(NSData **)outData;
+ (NSStringEncoding)bestGuessStringEncodingForData:(NSData *)contentData;

+ (NSString *)debugDescriptionForStringEncoding:(NSStringEncoding)encoding;
+ (NSString *)IANACharsetNameOfStringEncoding:(NSStringEncoding)encoding;
@end
