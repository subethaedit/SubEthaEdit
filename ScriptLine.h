//
//  ScriptLine.h
//  SubEthaEdit
//
//  Created by Martin Ott on 5/2/06.
//  Copyright 2006 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ScriptTextBase.h"

@class FoldableTextStorage;

@interface ScriptLine : ScriptTextBase {
    int I_lineNumber;
}

+ (id)scriptLineWithTextStorage:(FullTextStorage *)aTextStorage lineNumber:(int)aLineNumber;
- (id)initWithTextStorage:(FullTextStorage *)aTextStorage lineNumber:(int)aLineNumber;

@end
