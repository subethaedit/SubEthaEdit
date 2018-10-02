//  SEEStyleSheet.h
//  SubEthaEdit
//
//  Created by Martin Pittenauer on 05.11.10.

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
	NSDictionary *I_scopeExamples;
	NSMutableDictionary *I_scopeExampleCache;
	NSArray *I_allScopesWithExamples;
}

@property (nonatomic, retain) NSMutableDictionary *scopeStyleDictionary;
@property (nonatomic, retain) NSMutableDictionary *scopeCache;
@property (nonatomic, retain, readonly) NSArray *allScopes;
@property (nonatomic, retain, readonly) NSArray *allScopesWithExamples;
@property (nonatomic, copy) NSString *styleSheetName; // defined as the file base name without the extension
@property (nonatomic, readonly) NSColor *documentBackgroundColor;
@property (nonatomic, readonly) NSColor *documentForegroundColor;
@property (nonatomic, copy) NSDictionary *scopeExamples;


+ (NSDictionary *)textAttributesForStyleAttributes:(NSDictionary *)styleAttributes font:(NSFont *)font;

- (NSDictionary *)styleAttributesForScope:(NSString *)aScope;
- (void)importStyleSheetAtPath:(NSURL *)aPath;
- (NSString *)styleSheetSnippetForScope:(NSString *)aScope;
- (void)exportStyleSheetToPath:(NSURL *)aPath;

- (void)setStyleAttributes:(NSDictionary *)aStyleAttributeDictionary forScope:(NSString *)aScopeString;
- (void)removeStyleAttributesForScope:(NSString *)aScopeString;
- (NSDictionary *)styleAttributesForExactScope:(NSString *)anExactScopeString;

- (NSString *)exampleForScope:(NSString *)aScopeString;

/* returns an array with added scope names, nil if it was not updated */
- (NSArray *)updateScopesWithChangesDictionary:(NSDictionary *)aChangesDictionary;
- (void)appendStyleSheetSnippetsForScopes:(NSArray *)aScopeArray toSheetAtURL:(NSURL *)aURL;

- (BOOL)hasChanges;
- (void)markCurrentStateAsPersistent;
- (void)revertToPersistentState;

@end
