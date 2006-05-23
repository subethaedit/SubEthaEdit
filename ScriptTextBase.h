//
//  ScriptTextBase.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 03.05.06.
//  Copyright 2006 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class TextStorage;

@interface ScriptTextBase : NSObject {
    TextStorage *I_textStorage;
}

- (id)initWithTextStorage:(TextStorage *)aTextStorage;
- (NSRange)rangeRepresentation;
- (int)scriptedLength;
- (int)scriptedStartCharacterIndex;
- (int)scriptedNextCharacterIndex;
- (int)scriptedStartLine;
- (int)scriptedEndLine;
- (NSArray *)scriptedLines;
- (NSArray *)scriptedCharacters;

@end
