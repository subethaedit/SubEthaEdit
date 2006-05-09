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
- (NSNumber *)scriptedLength;
- (NSNumber *)scriptedStartCharacterIndex;
- (NSNumber *)scriptedNextCharacterIndex;
- (NSNumber *)scriptedStartLine;
- (NSNumber *)scriptedEndLine;
- (NSArray *)scriptedLines;
- (NSArray *)scriptedCharacters;

@end
