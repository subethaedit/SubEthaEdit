//
//  ScriptLine.h
//  SubEthaEdit
//
//  Created by Martin Ott on 5/2/06.
//  Copyright 2006 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ScriptTextBase.h"

@class TextStorage;

@interface ScriptLine : ScriptTextBase {
    TextStorage *I_textStorage; // geerbt
    int I_lineNumber;
}

+ (id)scriptLineWithTextStorage:(TextStorage *)aTextStorage lineNumber:(int)aLineNumber;
- (id)initWithTextStorage:(TextStorage *)aTextStorage lineNumber:(int)aLineNumber;

@end
