//  ScriptTextBase.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 03.05.06.

#import <Cocoa/Cocoa.h>
#import "FoldableTextStorage.h"
#import "FullTextStorage.h"
@class FullTextStorage;

@interface ScriptTextBase : NSObject {
    @protected
    FullTextStorage *I_textStorage;
}

- (instancetype)initWithTextStorage:(FullTextStorage *)aTextStorage;
- (NSRange)rangeRepresentation;
- (int)scriptedLength;
- (int)scriptedStartCharacterIndex;
- (int)scriptedNextCharacterIndex;
- (int)scriptedStartLine;
- (int)scriptedEndLine;
- (NSArray *)scriptedLines;
//- (NSArray *)scriptedCharacters;

@end
