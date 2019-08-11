//
//  SEPDocument.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 09.04.09.
//  Copyright 2009 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DocumentMode.h"
#import "SyntaxHighlighter.h"

@interface SEPDocument : NSObject {
	id textStorage;
	DocumentMode *I_documentMode;

    struct {
        NSFont *plainFont;
        NSFont *boldFont;
        NSFont *italicFont;
        NSFont *boldItalicFont;
    } I_fonts;
    NSMutableDictionary *I_styleCacheDictionary;
}

@property (strong) id textStorage;

- (void)setPlainFont:(NSFont *)aFont;

- (instancetype)initWithURL:(NSURL *)inURL;
- (DocumentMode *)documentMode;
- (NSTimeInterval)timedHighlightAll;

- (void)changeToFoldableTextStorage;
- (void)addOneFolding;
- (void)foldEveryOtherLine;


@end
