//  TextSelection.h
//  SubEthaEdit
//
//  Created by Martin Ott on 2/21/06.

#import <Cocoa/Cocoa.h>
#import "ScriptTextBase.h"

@class PlainTextEditor, TextStorage;

@interface ScriptTextSelection : ScriptTextBase {
    PlainTextEditor *I_editor;
    int              I_startCharacterIndex;
}

+ (id)insertionPointWithTextStorage:(FullTextStorage *)aTextStorage index:(int)anIndex;
+ (id)scriptTextSelectionWithTextStorage:(FullTextStorage *)aTextStorage editor:(PlainTextEditor *)anEditor;
- (id)initWithTextStorage:(FullTextStorage *)aTextStorage editor:(PlainTextEditor *)anEditor;

- (id)objectSpecifier;

@end
