//  SyntaxDefinition.h
//  SyntaxTestBench
//
//  Created by Martin Pittenauer on Wed Mar 17 2004.

#include <AvailabilityMacros.h>
#import <Foundation/Foundation.h>
#import <OgreKit/OgreKit.h>
#import "DocumentMode.h"
#import "SyntaxStyle.h"

@interface SyntaxDefinition : NSObject {
    NSString *I_name;               /*"Name (obsolete?)"*/
    DocumentMode *I_mode;               
    NSCharacterSet *I_tokenSet;     /*"Set for tokenizing"*/
    NSCharacterSet *I_invertedTokenSet;     /*"Set for tokenizing"*/
    NSCharacterSet *I_autoCompleteTokenSet;     /*"Set for autocomplete tokenizing"*/
    NSString *I_autocompleteTokenString;
    NSMutableDictionary *I_allStates;       /*"All states except the default state"*/
    NSMutableDictionary *I_defaultState;    /*"Default state"*/
    NSMutableDictionary *I_stylesForToken;   /*"Chached plainstrings"*/
    NSMutableDictionary *I_stylesForRegex;   /*"Chached regexs"*/
    NSMutableDictionary *I_importedModes;   /*"Chached regexs"*/
    NSMutableDictionary *I_scopeStyleDictionary;
	NSMutableArray *I_linkedStyleSheets;
    BOOL everythingOkay;
    BOOL I_useSpellingDictionary;
    BOOL I_combinedStateRegexReady;
    BOOL I_combinedStateRegexCalculating;
	BOOL I_cacheStylesReady;
	BOOL I_cacheStylesCalculating;
	BOOL I_symbolAndAutocompleteInheritanceReady;
    NSMutableDictionary *I_levelsForStyleIDs;
    SyntaxStyle *I_defaultSyntaxStyle;
    NSString *I_charsInToken;
    NSString *I_charsDelimitingToken;
	NSString *I_keyForInheritedSymbols;
	NSString *I_keyForInheritedAutocomplete;
    OGRegularExpression *I_tokenRegex;
    int I_foldingTopLevel;
    
    NSMutableArray *I_allScopesArray;
    NSMutableArray *I_allLanguageContextsArray;
}

@property (nonatomic, retain) NSMutableDictionary * scopeStyleDictionary;
@property (nonatomic, retain) NSMutableArray * linkedStyleSheets;
@property (nonatomic, copy) NSString *bracketMatchingBracketString;

/*"Initizialisation"*/
- (id)initWithFile:(NSString *)aPath forMode:(DocumentMode *)aMode;

/*"XML parsing"*/
- (void)parseXMLFile:(NSString *)aPath;
- (void)parseState:(NSXMLElement *)stateNode addToState:(NSMutableDictionary *)aState;

/*"Caching and Precalculation"*/
- (void)cacheStyles;
- (void)getReady;
- (void)addStyleIDsFromState:(NSDictionary *)aState;

/*"Accessors"*/
- (NSArray *)allScopes;
- (NSArray *)allLanguageContexts;
- (NSString *)mainLanguageContext;
- (NSString *) keyForInheritedSymbols;
- (NSString *) keyForInheritedAutocomplete;	
- (OGRegularExpression *)tokenRegex;
- (NSString *)name;
- (void)setName:(NSString *)aString;
//- (NSArray *)states;
- (NSMutableDictionary *)stateForID:(NSString *)aString;
- (NSMutableDictionary *)defaultState;
- (NSDictionary *)importedModes;
- (NSCharacterSet *)tokenSet;
- (NSCharacterSet *)invertedTokenSet;
- (NSCharacterSet *)autoCompleteTokenSet;
- (NSString *)autocompleteTokenString;
- (void)setTokenSet:(NSCharacterSet *)aCharacterSet;
- (void)setAutoCompleteTokenSet:(NSCharacterSet *)aCharacterSet;
- (BOOL)state:(NSString *)aState includesState:(NSString *)anotherState;
- (BOOL) hasTokensForState:(NSString *)aState;
- (NSString *)styleForToken:(NSString *)aToken inState:(NSString *)aState;
- (NSArray *)regularExpressionsInState:(NSString *)aState;
- (void)setCombinedStateRegexForState:(NSMutableDictionary *)aState;
- (DocumentMode *)mode;
- (void)setMode:(DocumentMode *)aMode;
- (SyntaxStyle *)defaultSyntaxStyle;
- (BOOL)useSpellingDictionary;

- (int)levelForStyleID:(NSString *)aStyleID;

- (int)foldingTopLevel;

@end

