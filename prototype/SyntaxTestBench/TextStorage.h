//
//  TextStorage.h
//  SubEthaEdit
//
//  Created by Martin Ott on Fri May 02 2003.
//  Copyright (c) 2003 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface TextStorage : NSTextStorage {
    // MetaData on lineStarts
    NSMutableArray *_lineStarts;
    unsigned int _lineStartsValidUpTo;
    NSMutableAttributedString *_contents;
}

- (int)lineNumberForLocation:(unsigned)location;
- (NSMutableArray *)lineStarts;
- (void)setLineStartsOnlyValidUpTo:(unsigned int)aLocation;

@end
