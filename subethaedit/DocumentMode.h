//
//  DocumentMode.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Mon Mar 22 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>

enum {
    DocumentModeWrapModeWords = 0,
    DocumentModeWrapModeCharacters
};

extern NSString * const DocumentModeEncodingPreferenceKey               ;
extern NSString * const DocumentModeFontAttributesPreferenceKey         ;
extern NSString * const DocumentModeHighlightSyntaxPreferenceKey        ;
extern NSString * const DocumentModeIndentNewLinesPreferenceKey         ;
extern NSString * const DocumentModeLineEndingPreferenceKey             ;
extern NSString * const DocumentModeShowLineNumbersPreferenceKey        ;
extern NSString * const DocumentModeShowMatchingBracketsPreferenceKey   ;
extern NSString * const DocumentModeTabWidthPreferenceKey               ;
extern NSString * const DocumentModeUseTabsPreferenceKey                ;
extern NSString * const DocumentModeWrapLinesPreferenceKey              ;
extern NSString * const DocumentModeShowInvisibleCharactersPreferenceKey;
extern NSString * const DocumentModeWrapModePreferenceKey               ;
extern NSString * const DocumentModeColumnsPreferenceKey                ;
extern NSString * const DocumentModeRowsPreferenceKey                   ;

@class SyntaxHighlighter;
@class RegexSymbolParser;

@interface DocumentMode : NSObject {
    NSBundle *I_bundle;
    SyntaxHighlighter *I_syntaxHighlighter;
    RegexSymbolParser *I_symbolParser;
    NSMutableDictionary *I_defaults;
}

- (id)initWithBundle:(NSBundle *)aBundle;

- (SyntaxHighlighter *)syntaxHighlighter;
- (RegexSymbolParser *)symbolParser;

- (BOOL)hasSymbols;
- (NSArray *)symbolArrayForTextStorage:(NSTextStorage *)aTextStorage;

- (NSBundle *)bundle;
- (NSString *)documentModeIdentifier;
- (NSString *)displayName;

- (NSMutableDictionary *)defaults;
- (void)setDefaults:(NSMutableDictionary *)defaults;
- (id)defaultForKey:(NSString *)aKey;


- (BOOL)isBaseMode;
@end
