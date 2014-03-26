//
//  NSStringSEEAdditions.h
//  
//
//  Created by Martin Ott on Tue Feb 17 2004.
//  Copyright (c) 2004-2007 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum _LineEnding {
    LineEndingLF = 1,    // U+000A (\n or LF)
    LineEndingCR = 2,    // U+000D (\r or CR)
    LineEndingCRLF = 3,  // \r\n, in that order (also known as CRLF)
    LineEndingUnicodeLineSeparator = 4,  // U+2028
    LineEndingUnicodeParagraphSeparator = 5  // U+2029
} LineEnding;

@interface NSMutableString (NSStringSEEAdditions)

- (void)convertLineEndingsToLineEndingString:(NSString *)aNewLineEndingString;
- (NSMutableString *)addBRs;

@end

@interface NSString (NSStringSEEAdditions)

+ (NSString *)lineEndingStringForLineEnding:(LineEnding)aLineEnding;
- (BOOL)isValidSerial;
- (long)base36Value;
- (BOOL)isWhiteSpace;
- (unsigned)detabbedLengthForRange:(NSRange)aRange tabWidth:(int)aTabWidth;
- (NSRange)rangeOfLeadingWhitespaceStartingAt:(unsigned)location;
- (BOOL)detabbedLength:(unsigned)aLength fromIndex:(unsigned)aFromIndex 
                length:(unsigned *)rLength upToCharacterIndex:(unsigned *)rIndex
              tabWidth:(int)aTabWidth;
- (NSMutableString *)stringByReplacingEntitiesForUTF8:(BOOL)forUTF8;
- (BOOL)findIANAEncodingUsingExpression:(NSString*)regEx encoding:(NSStringEncoding*)outEncoding;
- (NSString *) stringByReplacingRegularExpressionOperators;
- (NSRange)TCM_fullLengthRange;
@end

@interface NSAttributedString (NSAttributedStringSEEAdditions)

- (NSMutableString *)XHTMLStringWithAttributeMapping:(NSDictionary *)anAttributeMapping forUTF8:(BOOL)forUTF8;
- (NSRange)TCM_fullLengthRange;
@end
