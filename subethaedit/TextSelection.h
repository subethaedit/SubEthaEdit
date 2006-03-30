//
//  TextSelection.h
//  SubEthaEdit
//
//  Created by Martin Ott on 2/21/06.
//  Copyright 2006 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PlainTextEditor;

@interface TextSelection : NSObject {
    PlainTextEditor *I_editor;
}

+ (id)selectionForEditor:(id)editor;
- (id)initForEditor:(id)editor;

- (NSData *)characterRange;
- (id)contents;
- (void)setContents:(id)string;
- (id)objectSpecifier;

@end
