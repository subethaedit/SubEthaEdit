//
//  TextSelection.h
//  SubEthaEdit
//
//  Created by Martin Ott on 2/21/06.
//  Copyright 2006 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ScriptTextBase.h"

@class PlainTextEditor, TextStorage;

@interface ScriptTextSelection : ScriptTextBase {
    PlainTextEditor *I_editor;
    int              I_startCharacterIndex;
}

+ (id)insertionPointWithTextStorage:(FoldableTextStorage *)aTextStorage index:(int)anIndex;
+ (id)scriptTextSelectionWithTextStorage:(FoldableTextStorage *)aTextStorage editor:(PlainTextEditor *)anEditor;
- (id)initWithTextStorage:(FoldableTextStorage *)aTextStorage editor:(PlainTextEditor *)anEditor;

- (id)objectSpecifier;

@end
