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
- (NSMutableString *)addBRs;

@end

@interface NSString (NSStringTCMAdditions)

+ (NSString *)stringWithUUIDData:(NSData *)aData;
+ (NSString *)stringWithAddressData:(NSData *)aData;
+ (NSString *)stringWithData:(NSData *)aData encoding:(NSStringEncoding)aEncoding;
+ (NSString *)UUIDString;

- (BOOL)isValidSerial;
- (long)base36Value;

- (BOOL)isWhiteSpace;
- (unsigned)detabbedLengthForRange:(NSRange)aRange tabWidth:(int)aTabWidth;
- (BOOL)detabbedLength:(unsigned)aLength fromIndex:(unsigned)aFromIndex 
                length:(unsigned *)rLength upToCharacterIndex:(unsigned *)rIndex
              tabWidth:(int)aTabWidth;
- (NSMutableString *)stringByReplacingEntities;
@end

@interface NSAttributedString (NSAttributedStringTCMAdditions)

- (NSMutableString *)XHTMLStringWithAttributeMapping:(NSDictionary *)anAttributeMapping;

@end

@interface NSMutableAttributedString (NSMutableAttributedStringTCMAdditions) 

/* returns length change */
- (NSRange)detab:(BOOL)shouldDetab inRange:(NSRange)aRange tabWidth:(int)aTabWidth askingTextView:(NSTextView *)aTextView;
- (void)makeLeadingWhitespaceNonBreaking;
- (void)appendString:(NSString *)aString;

@end