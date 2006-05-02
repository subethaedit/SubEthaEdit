//
//  ScriptLine.h
//  SubEthaEdit
//
//  Created by Martin Ott on 5/2/06.
//  Copyright 2006 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TextStorage;

@interface ScriptLine : NSObject{
    TextStorage *I_textStorage;
    int I_lineNumber;
}

+ (id)scriptLineWithTextStorage:(TextStorage *)aTextStorage lineNumber:(int)aLineNumber;
- (id)initWithTextStorage:(TextStorage *)aTextStorage lineNumber:(int)aLineNumber;

- (NSRange)lineRangeWithoutLineFeed;
- (NSNumber *)scriptedLength;
- (NSNumber *)scriptedCharacterOffset;
- (NSNumber *)scriptedStartLine;
- (NSNumber *)scriptedEndLine;
- (NSString *)text;
- (void)setText:(id)value;

@end
