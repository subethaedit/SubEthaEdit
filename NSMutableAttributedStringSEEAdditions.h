//
//  NSMutableAttributedStringSEEAdditions.h
//  SubEthaEdit
//
//  Created by Martin Ott on 3/19/07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSMutableAttributedString (NSMutableAttributedStringSEEAdditions)

#ifndef TCM_ISSEED
/* returns length change */
- (NSRange)detab:(BOOL)shouldDetab inRange:(NSRange)aRange tabWidth:(int)aTabWidth askingTextView:(NSTextView *)aTextView;
- (void)makeLeadingWhitespaceNonBreaking;
#endif

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
