//  NSDataTCMAdditions.h
//  TCMFoundation
//
//  Created by Dominik Wagner on Wed Apr 28 2004.

#import <Foundation/Foundation.h>
#import <zlib.h>

@interface NSData (NSDataTCMAdditions)

+ (id)dataWithUUIDString:(NSString *)aUUIDString;
+ (NSData *)dataWithBase64EncodedString:(NSString *)inBase64String;
- (NSString *)base64EncodedStringWithLineLength:(int)lineLength;
- (id)dataPrefixedWithUTF8BOM;
- (NSData *)compressedDataWithLevel:(int)aLevel;
- (NSData *)uncompressedDataOfLength:(unsigned)aLength;
- (NSArray *)arrayOfCompressedDataWithLevel:(int)aLevel;
+ (NSData *)dataWithArrayOfCompressedData:(NSArray *)anArray;

@property (nonatomic, readonly) BOOL startsWithUTF8BOM;
@property (nonatomic, readonly) NSData *md5Data;
@property (nonatomic, readonly) NSString *md5String;

@end
