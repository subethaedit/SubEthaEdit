//
//  TextStorage.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Thu Mar 25 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TextStorage : NSTextStorage {
    // MetaData on lineStarts
    NSMutableArray *I_lineStarts;
    unsigned int I_lineStartsValidUpTo;
    NSMutableAttributedString *I_contents;
}

- (int)lineNumberForLocation:(unsigned)location;
- (NSMutableArray *)lineStarts;
- (void)setLineStartsOnlyValidUpTo:(unsigned int)aLocation;

@end


@interface NSObject (TextStorageDelegateAdditions)
- (void)textStorage:(NSTextStorage *)aTextStorage didReplaceCharactersInRange:(NSRange)aRange withString:(NSString *)aString;
@end