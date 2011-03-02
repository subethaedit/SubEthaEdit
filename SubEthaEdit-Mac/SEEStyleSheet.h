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
	NSMutableDictionary *I_scopeStyleDictionary;
	NSMutableDictionary *I_scopeCache;
	NSArray *I_allScopes;
}

@property (nonatomic, retain) NSMutableDictionary *scopeStyleDictionary;
@property (nonatomic, retain) NSMutableDictionary *scopeCache;
@property (nonatomic, retain, readonly) NSArray *allScopes;

+ (NSDictionary *)textAttributesForStyleAttributes:(NSDictionary *)styleAttributes font:(NSFont *)font;

- (id)initWithDefinition:(SyntaxDefinition *)aDefinition; 
- (NSDictionary *)styleAttributesForScope:(NSString *)aScope;
- (void)importStyleSheetAtPath:(NSURL *)aPath;
- (void)exportStyleSheetToPath:(NSURL *)aPath;

- (void)setStyleAttributes:(NSDictionary *)aStyleAttributeDictionary forScope:(NSString *)aScopeString;
- (NSDictionary *)styleAttributesForExactScope:(NSString *)anExactScopeString;


@end
