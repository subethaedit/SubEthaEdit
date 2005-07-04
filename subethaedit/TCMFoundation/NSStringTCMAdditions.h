//
//  NSStringTCMAdditions.h
//  
//
//  Created by Martin Ott on Tue Feb 17 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSString (NSStringTCMAdditions)

+ (NSString *)stringWithUUIDData:(NSData *)aData;
+ (NSString *)stringWithData:(NSData *)aData encoding:(NSStringEncoding)aEncoding;
+ (NSString *)UUIDString;

+ (NSString *)stringWithAddressData:(NSData *)aData;

- (NSData *)UTF8DataWithMaximumLength:(unsigned)aLength;

@end


@interface NSMutableAttributedString (NSMutableAttributedStringTCMAdditions) 

- (void)appendString:(NSString *)aString;

@end