//
//  SyntaxDefinition.h
//  SyntaxTestBench
//
//  Created by Martin Pittenauer on Wed Mar 17 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SyntaxDefinition : NSObject {
    NSString *I_name;
    NSCharacterSet *I_tokenSet;
    NSMutableArray *I_states;
    NSMutableDictionary *I_defaultState;
    NSMutableDictionary *I_styleForToken;
    NSMutableDictionary *I_styleForRegex;

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
- (NSDictionary *)styleForToken:(NSString *)aToken;
- (NSDictionary *)regularExpressions;

@end
