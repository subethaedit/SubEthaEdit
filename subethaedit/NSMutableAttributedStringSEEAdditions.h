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

- (void)removeAttributes:(NSArray *)names range:(NSRange)aRange;
- (NSDictionary *)dictionaryRepresentationUsingEncoding:(NSStringEncoding)anEncoding;
- (void)setContentByDictionaryRepresentation:(NSDictionary *)aRepresentation;

@end
