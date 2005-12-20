//
//  SyntaxDefinition.h
//  SyntaxTestBench
//
//  Created by Martin Pittenauer on Wed Mar 17 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

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
    NSMutableArray *I_states;       /*"All states except the default state"*/
    NSMutableDictionary *I_defaultState;    /*"Default state"*/
    NSMutableArray *I_stylesForToken;   /*"Chached plainstrings"*/
    NSMutableArray *I_stylesForRegex;   /*"Chached regexs"*/
    OGRegularExpression *I_combinedStateRegex;     /*"All state-begins in one regex"*/
    BOOL everythingOkay;
    SyntaxStyle *I_defaultSyntaxStyle;
}

/*"Initizialisation"*/
- (id)initWithFile:(NSString *)aPath forMode:(DocumentMode *)aMode;

/*"XML parsing"*/
- (void)parseXMLFile:(NSString *)aPath;
- (void)parseHeaders:(CFXMLTreeRef)aTree;
- (void)parseStatesForTreeNode:(CFXMLTreeRef)aTree;
- (void)stateForTreeNode:(CFXMLTreeRef)aTree toDictionary:(NSMutableDictionary *)aDictionary stateID:(NSString *)aStateID;
- (void)addKeywordsForTreeNode:(CFXMLTreeRef)aTree toDictionary:(NSMutableDictionary *)aDictionary;

/*"Caching and Precalculation"*/
-(void)cacheStyles;
-(void)addStylesForKeywordGroups:(NSDictionary *)aDictionary;

/*"Accessors"*/
- (NSString *)name;
- (void)setName:(NSString *)aString;
- (NSMutableArray *)states;
- (NSDictionary *)defaultState;
- (NSCharacterSet *)tokenSet;
- (NSCharacterSet *)invertedTokenSet;
- (NSCharacterSet *)autoCompleteTokenSet;
- (void)setTokenSet:(NSCharacterSet *)aCharacterSet;
- (void)setAutoCompleteTokenSet:(NSCharacterSet *)aCharacterSet;
- (NSString *)styleForToken:(NSString *)aToken inState:(int)aState;
- (NSArray *)regularExpressionsInState:(int)aState;
- (void)setCombinedStateRegex;
- (OGRegularExpression *)combinedStateRegex;
- (DocumentMode *)mode;
- (void)setMode:(DocumentMode *)aMode;
- (SyntaxStyle *)defaultSyntaxStyle;

@end
