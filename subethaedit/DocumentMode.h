//
//  DocumentMode.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Mon Mar 22 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SyntaxHighlighter;

@interface DocumentMode : NSObject {
    NSBundle *I_bundle;
    SyntaxHighlighter *I_syntaxHighlighter;
    NSMutableDictionary *I_defaults;
}

- (id)initWithBundle:(NSBundle *)aBundle;

- (SyntaxHighlighter *)syntaxHighlighter;
- (NSBundle *)bundle;

- (NSMutableDictionary *)defaults;
- (void)setDefaults:(NSMutableDictionary *)defaults;

- (BOOL)isBaseMode;
@end
