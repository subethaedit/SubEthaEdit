//
//  NSStringTCMAdditions.h
//  
//
//  Created by Martin Ott on Tue Feb 17 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum _LineEnding {
    LineEndingLF = 1,    // U+000A (\n or LF)
    LineEndingCR = 2,    // U+000D (\r or CR)
    LineEndingCRLF = 3,  // \r\n, in that order (also known as CRLF)
    LineEndingUnicodeLineSeparator = 4,  // U+2028
    LineEndingUnicodeParagraphSeparator = 5  // U+2029
} LineEnding;

@interface NSMutableString (NSStringTCMAdditions)

- (void)convertLineEndingsToLineEndingString:(NSString *)aNewLineEndingString;
- (void)convertLineEndingsToLF;
- (void)convertLineEndingsToCR;
- (void)convertLineEndingsToCRLF;

@end

@interface NSString (NSStringTCMAdditions)

+ (NSString *)stringWithAddressData:(NSData *)aData;
+ (NSString *)stringWithData:(NSData *)aData encoding:(NSStringEncoding)aEncoding;
+ (NSString *)UUIDString;

- (BOOL) isValidSerial;
- (long) base36Value;

- (BOOL)isWhiteSpace;
- (unsigned) detabbedLengthForRange:(NSRange)aRange tabWidth:(int)aTabWidth;
- (BOOL)detabbedLength:(unsigned)aLength fromIndex:(unsigned)aFromIndex 
                length:(unsigned *)rLength upToCharacterIndex:(unsigned *)rIndex
              tabWidth:(int)aTabWidth;

@end