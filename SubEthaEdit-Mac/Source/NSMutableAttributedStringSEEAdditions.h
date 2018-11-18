//  NSMutableAttributedStringSEEAdditions.h
//  SubEthaEdit
//
//  Created by Martin Ott on 3/19/07.

#import <Cocoa/Cocoa.h>

@interface NSMutableAttributedString (NSMutableAttributedStringSEEAdditions)

/* returns length change */
- (NSRange)detab:(BOOL)shouldDetab inRange:(NSRange)aRange tabWidth:(int)aTabWidth askingTextView:(NSTextView *)aTextView;
- (void)makeLeadingWhitespaceNonBreaking;

- (void)removeAttributes:(id)anObjectEnumerable range:(NSRange)aRange;

- (void)setContentByDictionaryRepresentation:(NSDictionary *)aRepresentation;

- (NSRange)blockChangeTextInRange:(NSRange)aRange replacementString:(NSString *)aReplacementString
                   paragraphRange:(NSRange)aParagraphRange inTextView:(NSTextView *)aTextView tabWidth:(unsigned)aTabWidth useTabs:(BOOL)aUseTabs;

- (void)replaceAttachmentsWithAttributedString:(NSAttributedString *)aString;

@end

@interface NSAttributedString (NSAttributedStringSeeAdditions)
- (NSMutableDictionary *)mutableDictionaryRepresentation;
- (NSDictionary *)attributeDictionaryByAddingStyleAttributesForInsertLocation:(unsigned int)inLocation toDictionary:(NSDictionary *)inBaseStyle;
- (NSDictionary *)dictionaryRepresentation;
- (NSDictionary *)dictionaryRepresentationUsingEncoding:(NSStringEncoding)anEncoding;
- (BOOL)lastLineIsEmpty;
- (NSMutableAttributedString *)attributedStringForXHTMLExportWithRange:(NSRange)aRange foregroundColor:(NSColor *)aForegroundColor backgroundColor:(NSColor *)aBackgroundColor;
@end
