//  NSStringSEEAdditions.h
//  
//
//  Created by Martin Ott on Tue Feb 17 2004.

#import <Foundation/Foundation.h>

typedef enum _LineEnding {
    LineEndingLF = 1,    // U+000A (\n or LF)
    LineEndingCR = 2,    // U+000D (\r or CR)
    LineEndingCRLF = 3,  // \r\n, in that order (also known as CRLF)
    LineEndingUnicodeLineSeparator = 4,  // U+2028
    LineEndingUnicodeParagraphSeparator = 5  // U+2029
} LineEnding;

@interface TCMBracketSettings : NSObject
/* for example @"{([])}" */
- (instancetype)initWithBracketString:(NSString *)aBracketString;
- (void)setBracketString:(NSString *)aBracketString;
@property (nonatomic, readonly) unichar *openingBrackets;
@property (nonatomic, readonly) unichar *closingBrackets;
@property (nonatomic, readonly) NSInteger bracketCount;
@property (nonatomic, strong) NSString *attributeNameToDisregard;
@property (nonatomic, strong) NSArray *attributeValuesToDisregard;

- (BOOL)charIsClosingBracket:(unichar)aPossibleBracket;
- (BOOL)charIsOpeningBracket:(unichar)aPossibleBracket;
- (BOOL)charIsBracket:(unichar)aPossibleBracket;
/*! @return matching bracket or (unichar)0 if wasn't a bracket*/
- (unichar)matchingBracketForChar:(unichar)aBracketCharacter;
- (BOOL)shouldIgnoreBracketAtIndex:(NSUInteger)aPosition attributedString:(NSAttributedString *)anAttributedString;
- (BOOL)shouldIgnoreBracketAtRangeBoundaries:(NSRange)aRange attributedString:(NSAttributedString *)anAttributedString;
@end

@interface NSMutableString (NSStringSEEAdditions)

- (void)convertLineEndingsToLineEndingString:(NSString *)aNewLineEndingString;
- (NSMutableString *)addBRs;

@end

@interface NSString (NSStringSEEAdditions)

+ (NSString *)lineEndingStringForLineEnding:(LineEnding)aLineEnding;
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
- (NSString *)stringWithInitials;

- (NSString *)lossyStringUsingEncoding:(NSStringEncoding)encoding;

@end

@interface NSAttributedString (NSAttributedStringSEEAdditions)

- (NSMutableString *)XHTMLStringWithAttributeMapping:(NSDictionary *)anAttributeMapping forUTF8:(BOOL)forUTF8;
- (NSRange)TCM_fullLengthRange;
- (NSUInteger)TCM_positionOfMatchingBracketToPosition:(NSUInteger)position bracketSettings:(TCMBracketSettings *)aBracketSettings;

@end
