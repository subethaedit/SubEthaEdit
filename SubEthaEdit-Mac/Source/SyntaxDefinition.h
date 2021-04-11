//  SyntaxDefinition.h
//
//  Created by Martin Pittenauer on Wed Mar 17 2004.

#include <AvailabilityMacros.h>
#import <Foundation/Foundation.h>
#import <OgreKit/OgreKit.h>
#import "DocumentMode.h"
#import "SyntaxStyle.h"

extern NSNotificationName const SyntaxDefinitionDidEncounterErrorNotification;

@interface SyntaxDefinition : NSObject

@property (nonatomic, strong) NSMutableDictionary *scopeStyleDictionary;
@property (nonatomic, copy) NSString *bracketMatchingBracketString;

@property (nonatomic, strong) NSString *name;
@property (nonatomic, readonly) SyntaxStyle *defaultSyntaxStyle;
@property (nonatomic, weak) DocumentMode *mode;

@property (nonatomic, strong) NSArray<NSError *> *parseErrors;

/*"Initialisation"*/
- (instancetype)initWithURL:(NSURL *)aURL forMode:(DocumentMode *)aMode;

/*"XML parsing"*/
- (void)parseXMLFile:(NSURL *)aFileURL;
- (void)parseState:(NSXMLElement *)stateNode addToState:(NSMutableDictionary *)aState;

/*"Caching and Precalculation"*/
- (void)cacheStyles;
- (void)getReady;
- (void)addStyleIDsFromState:(NSDictionary *)aState;

/*"Accessors"*/
- (NSArray *)allScopes;
- (NSArray *)allLanguageContexts;
- (NSString *)mainLanguageContext;
- (NSString *)keyForInheritedSymbols;
- (NSString *)keyForInheritedAutocomplete;

- (NSMutableDictionary *)stateForID:(NSString *)aString;
- (NSMutableDictionary *)defaultState;
- (NSDictionary *)importedModes;

@property (nonatomic, strong) NSCharacterSet *tokenSet;
@property (nonatomic, strong) NSCharacterSet *autoCompleteTokenSet;
@property (nonatomic, strong, readonly) NSCharacterSet *invertedTokenSet;
@property (nonatomic, strong) NSString *autocompleteTokenString;

- (BOOL)state:(NSString *)aState includesState:(NSString *)anotherState;
- (BOOL)hasTokensForState:(NSString *)aState;
- (NSString *)styleForToken:(NSString *)aToken inState:(NSString *)aState;
- (NSArray *)regularExpressionsInState:(NSString *)aState;
- (void)setCombinedStateRegexForState:(NSMutableDictionary *)aState;
- (SyntaxStyle *)defaultSyntaxStyle;
@property (nonatomic) BOOL useSpellingDictionary;

- (int)levelForStyleID:(NSString *)aStyleID;

- (int)foldingTopLevel;

@end

