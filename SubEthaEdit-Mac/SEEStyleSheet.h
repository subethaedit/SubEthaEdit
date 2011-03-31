//
//  SEEStyleSheet.h
//  SubEthaEdit
//
//  Created by Martin Pittenauer on 05.11.10.
//  Copyright 2010 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SyntaxDefinition;


NSString * const SEEStyleSheetFontStyleKey;
NSString * const SEEStyleSheetFontWeightKey;
NSString * const SEEStyleSheetFontUnderlineKey;
NSString * const SEEStyleSheetFontStrikeThroughKey;
NSString * const SEEStyleSheetFontForegroundColorKey;
NSString * const SEEStyleSheetFontBackgroundColorKey;
NSString * const SEEStyleSheetValueNormal       ;
NSString * const SEEStyleSheetValueNone         ;
NSString * const SEEStyleSheetValueBold         ;
NSString * const SEEStyleSheetValueUnderline    ;
NSString * const SEEStyleSheetValueItalic       ;
NSString * const SEEStyleSheetValueStrikeThrough;
NSString * const SEEStyleSheetMetaDefaultScopeName;

NSString * const SEEStyleSheetFileExtension;


@interface SEEStyleSheet : NSObject {
	NSMutableDictionary *I_scopeStyleDictionary;
	NSDictionary *I_scopeStyleDictionaryPersistentState;
	NSMutableDictionary *I_scopeCache;
	NSArray *I_allScopes;
	NSString *I_styleSheetName;
}

@property (nonatomic, retain) NSMutableDictionary *scopeStyleDictionary;
@property (nonatomic, retain) NSMutableDictionary *scopeCache;
@property (nonatomic, retain, readonly) NSArray *allScopes;
@property (nonatomic, copy) NSString *styleSheetName; // defined as the file base name without the extension
@property (nonatomic, readonly) NSColor *documentBackgroundColor;
@property (nonatomic, readonly) NSColor *documentForegroundColor;

+ (NSDictionary *)textAttributesForStyleAttributes:(NSDictionary *)styleAttributes font:(NSFont *)font;

- (NSDictionary *)styleAttributesForScope:(NSString *)aScope;
- (void)importStyleSheetAtPath:(NSURL *)aPath;
- (NSString *)styleSheetSnippetForScope:(NSString *)aScope;
- (void)exportStyleSheetToPath:(NSURL *)aPath;

- (void)setStyleAttributes:(NSDictionary *)aStyleAttributeDictionary forScope:(NSString *)aScopeString;
- (void)removeStyleAttributesForScope:(NSString *)aScopeString;
- (NSDictionary *)styleAttributesForExactScope:(NSString *)anExactScopeString;

- (BOOL)hasChanges;
- (void)markCurrentStateAsPersistent;
- (void)revertToPersistentState;

@end
