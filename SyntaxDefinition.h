//
//  SyntaxDefinition.h
//  SyntaxTestBench
//
//  Created by Martin Pittenauer on Wed Mar 17 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

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
    NSMutableDictionary *I_allStates;       /*"All states except the default state"*/
    NSMutableDictionary *I_defaultState;    /*"Default state"*/
    NSMutableDictionary *I_stylesForToken;   /*"Chached plainstrings"*/
    NSMutableDictionary *I_stylesForRegex;   /*"Chached regexs"*/
    NSMutableDictionary *I_importedModes;   /*"Chached regexs"*/
    OGRegularExpression *I_combinedStateRegex;     /*"All state-begins in one regex"*/
    BOOL everythingOkay;
    BOOL I_useSpellingDictionary;
    BOOL I_combinedStateRegexReady;
    BOOL I_combinedStateRegexCalculating;
	BOOL I_cacheStylesReady;
	BOOL I_cacheStylesCalculating;

    SyntaxStyle *I_defaultSyntaxStyle;
}

/*"Initizialisation"*/
- (id)initWithFile:(NSString *)aPath forMode:(DocumentMode *)aMode;

/*"XML parsing"*/
- (void)parseXMLFile:(NSString *)aPath;
- (void)parseState:(NSXMLElement *)stateNode addToState:(NSMutableDictionary *)aState;

/*"Caching and Precalculation"*/
-(void)cacheStyles;

/*"Accessors"*/
- (NSString *)name;
- (void)setName:(NSString *)aString;
//- (NSArray *)states;
- (NSDictionary *)stateForID:(NSString *)aString;
- (NSDictionary *)defaultState;
- (NSDictionary *)importedModes;
- (NSCharacterSet *)tokenSet;
- (NSCharacterSet *)invertedTokenSet;
- (NSCharacterSet *)autoCompleteTokenSet;
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

@end

