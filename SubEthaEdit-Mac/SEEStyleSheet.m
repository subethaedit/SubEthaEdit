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
		
//		NSLog(@"scopes: %@", scopeStyleDictionary);
//		NSLog(@"inherit: %@", [self styleAttributesForScope:@"meta.block.directives.objective-c"]);

		
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
		
		// last, fall back to inheritence
		while ([computedStyle objectForKey:@"inherit"]) {
			if ([aScope isEqualToString:[computedStyle objectForKey:@"inherit"]]) {
				NSLog(@"WARNING: Endless inheritance for %@", aScope);
				break;
			}
			aScope = [computedStyle objectForKey:@"inherit"];
			computedStyle = [scopeStyleDictionary objectForKey:aScope];
		}

		[scopeCache setObject:computedStyle forKey:aScope];
	}
	
	return computedStyle;
}


@end


