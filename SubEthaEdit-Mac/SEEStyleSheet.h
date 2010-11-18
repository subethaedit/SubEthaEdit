//
//  SEEStyleSheet.h
//  SubEthaEdit
//
//  Created by Martin Pittenauer on 05.11.10.
//  Copyright 2010 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SyntaxDefinition;

@interface SEEStyleSheet : NSObject {
	NSMutableDictionary * I_ScopeStyleDictionary;
	NSMutableDictionary * I_scopeCache;
}

@property (nonatomic, retain) NSMutableDictionary * scopeStyleDictionary;
@property (nonatomic, retain) NSMutableDictionary * scopeCache;


- (SEEStyleSheet*)initWithDefinition:(SyntaxDefinition*)aDefinition; 
- (NSDictionary *)styleAttributesForScope:(NSString *)aScope;
- (void) importStyleSheetAtPath:(NSURL *)aPath;
- (void) exportStyleSheetToPath:(NSURL *)aPath;



@end
