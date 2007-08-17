//
//  NSDataTCMAdditions.h
//  TCMFoundation
//
//  Created by Dominik Wagner on Wed Apr 28 2004.
//  Copyright (c) 2004-2007 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <zlib.h>

@interface NSData (NSDataTCMAdditions)

+ (id)dataWithUUIDString:(NSString *)aUUIDString;
+ (NSData *)dataWithBase64EncodedString:(NSString *)inBase64String;
- (NSString *)base64EncodedStringWithLineLength:(int)lineLength;
- (id)dataPrefixedWithUTF8BOM;
- (BOOL)startsWithUTF8BOM;
- (NSData*)compressedDataWithLevel:(int)aLevel;
- (NSData*)uncompressedDataOfLength:(unsigned)aLength;
- (NSArray *)arrayOfCompressedDataWithLevel:(int)aLevel;
+ (NSData *)dataWithArrayOfCompressedData:(NSArray *)anArray;

@end
