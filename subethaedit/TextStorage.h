//
//  TextStorage.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Thu Mar 25 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TextStorage : NSTextStorage {
    NSMutableArray *I_lineStarts;
    unsigned int I_lineStartsValidUpTo;
    NSMutableAttributedString *I_contents;
    unsigned int I_encoding;
}

- (int)lineNumberForLocation:(unsigned)location;
- (NSMutableArray *)lineStarts;
- (NSRange)findLine:(int)aLineNumber;
- (void)setLineStartsOnlyValidUpTo:(unsigned int)aLocation;

- (unsigned int)encoding;
- (void)setEncoding:(unsigned int)anEncoding;

@end

#pragma mark -

@interface NSObject (TextStorageDelegateAdditions)

- (void)textStorage:(NSTextStorage *)aTextStorage didReplaceCharactersInRange:(NSRange)aRange withString:(NSString *)aString;

@end