//
//  NSMutableAttributedStringSEEAdditions.h
//  SubEthaEdit
//
//  Created by Martin Ott on 3/19/07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSMutableAttributedString (NSMutableAttributedStringSEEAdditions)

/* returns length change */
- (NSRange)detab:(BOOL)shouldDetab inRange:(NSRange)aRange tabWidth:(int)aTabWidth askingTextView:(NSTextView *)aTextView;
- (void)makeLeadingWhitespaceNonBreaking;
- (void)removeAttributes:(NSArray *)names range:(NSRange)aRange;

@end
