//
//  SyntaxDefinition.h
//  SyntaxTestBench
//
//  Created by Martin Pittenauer on Wed Mar 17 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SyntaxDefinition : NSObject {
    NSString *I_name;               /*"Name (obsolete?)"*/
    NSCharacterSet *I_tokenSet;     /*"Set for tokenizing"*/
    NSMutableArray *I_states;       /*"All states except the default state"*/
    NSMutableDictionary *I_defaultState;    /*"Default state"*/
    NSMutableArray *I_stylesForToken;   /*"Chached plainstrings"*/
    NSMutableArray *I_stylesForRegex;   /*"Chached regexs"*/
}

/*"Initizialisation"*/
- (id)initWithFile:(NSString *)synfile;

/*"XML parsing"*/
- (void)parseXMLFile:(NSString *)aPath;
- (void)parseHeaders:(CFXMLTreeRef)aTree;
- (void)parseStatesForTreeNode:(CFXMLTreeRef)aTree;
- (void)stateForTreeNode:(CFXMLTreeRef)aTree toDictionary:(NSMutableDictionary *)aDictionary;
- (void)addKeywordsForTreeNode:(CFXMLTreeRef)aTree toDictionary:(NSMutableDictionary *)aDictionary;

/*"Caching and Precalculation"*/
-(void)cacheStyles;
-(void)addStylesForKeywordGroups:(NSDictionary *)aDictionary;

/*"Accessors"*/
- (NSString *)name;
- (void)setName:(NSString *)aString;
- (NSCharacterSet *)tokenSet;
- (void)setTokenSet:(NSCharacterSet *)aCharacterSet;
- (NSDictionary *)styleForToken:(NSString *)aToken inState:(int)aState;
- (NSDictionary *)regularExpressions;

@end
