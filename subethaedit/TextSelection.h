//
//  TextSelection.h
//  SubEthaEdit
//
//  Created by Martin Ott on 2/21/06.
//  Copyright 2006 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PlainTextEditor, TextStorage;

@interface TextSelection : NSObject {
    PlainTextEditor *I_editor;
    TextStorage *I_subTextStorage;
}

+ (id)selectionForEditor:(id)editor;
- (id)initForEditor:(id)editor;

- (NSNumber *)scriptedLength;
- (NSNumber *)scriptedCharacterOffset;
- (NSNumber *)scriptedStartLine;
- (NSNumber *)scriptedEndLine;
- (id)contents;
- (void)setContents:(id)string;
- (id)objectSpecifier;

@end
