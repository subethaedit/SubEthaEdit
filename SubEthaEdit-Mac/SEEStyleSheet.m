//
//  SEEStyleSheet.m
//  SubEthaEdit
//
//  Created by Martin Pittenauer on 05.11.10.
//  Copyright 2010 TheCodingMonkeys. All rights reserved.
//

#import "SEEStyleSheet.h"
#import "SyntaxDefinition.h"


/*
 
 Every mode can has multiple style sheets encapsulating 
 scope/style pairs.
 
 */


@implementation SEEStyleSheet

@synthesize scopeStyleDictionary;
@synthesize scopeCache;

- (SEEStyleSheet*)initWithDefinition:(SyntaxDefinition*)aDefinition {
    self=[super init];
    if (self) {

		scopeStyleDictionary = [NSMutableDictionary new];
		scopeCache = [NSMutableDictionary new];
		[aDefinition getReady];
		[scopeStyleDictionary addEntriesFromDictionary:[aDefinition scopeStyleDictionary]];
		
		
		
		NSLog(@"foo %@",scopeStyleDictionary);
	}
	return self;
}

- (void)dealloc {
	scopeCache = nil;
	scopeStyleDictionary = nil;
	[super dealloc];
}



- (void) importStyleSheetAtPath:(NSURL *)aPath;
{
	
}

- (void) exportStyleSheetToPath:(NSURL *)aPath;
{
	
}

- (NSDictionary *)styleAttributesForScope:(NSString *)aScope {

	NSDictionary *computedStyle = [scopeCache objectForKey:aScope];
	if (!computedStyle) {
		// Search for optimal style
		
		// First try full matching
		if (!(computedStyle = [scopeStyleDictionary objectForKey:aScope])) {
		
			
			
		}
		
		
		[scopeCache setObject:computedStyle forKey:aScope];
	}
	
	return computedStyle;
}


@end


