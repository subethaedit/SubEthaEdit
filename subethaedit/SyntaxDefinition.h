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

}

- (id)initWithFile:(NSString *)synfile;

- (void)parseXMLFile:(NSString *)aPath;
- (void)parseHeaders:(CFXMLTreeRef)aTree;
- (void)parseStatesForTreeNode:(CFXMLTreeRef)aTree;
- (void)stateForTreeNode:(CFXMLTreeRef)aTree toDictionary:(NSMutableDictionary *)aDictionary;
- (void)addKeywordsForTreeNode:(CFXMLTreeRef)aTree toDictionary:(NSMutableDictionary *)aDictionary;

- (NSString *)name;
- (void)setName:(NSString *)aString;
- (NSCharacterSet *)tokenSet;
- (void)setTokenSet:(NSCharacterSet *)aCharacterSet;

@end
