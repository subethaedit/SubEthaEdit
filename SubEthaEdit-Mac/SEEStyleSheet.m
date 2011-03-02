//
//  SEEStyleSheet.m
//  SubEthaEdit
//
//  Created by Martin Pittenauer on 05.11.10.
//  Copyright 2010 TheCodingMonkeys. All rights reserved.
//

#import "SEEStyleSheet.h"
#import "SyntaxDefinition.h"
#import "PreferenceKeys.h"
/*
 
 Every mode can has multiple style sheets encapsulating 
 scope/style pairs.
 
 */

@interface SEEStyleSheet ()
@property (nonatomic, retain, readwrite) NSArray *allScopes;
@end

@implementation SEEStyleSheet


+ (NSDictionary *)textAttributesForStyleAttributes:(NSDictionary *)aStyleAttributeDictionary font:(NSFont *)aFont {
	
	NSLog(@"%s %@",__FUNCTION__,aStyleAttributeDictionary);
	
//	check darkness of background for use in strokewidth bold synthesizing later on
	NSColor *backgroundColor=[aStyleAttributeDictionary objectForKey:@"background-color"];
	BOOL darkBackground = [backgroundColor isDark];
	
//	generate the font we'd like
	NSFontTraitMask traits = 0;
	if ([[aStyleAttributeDictionary objectForKey:@"font-style"] isEqualToString:@"italic"]) traits = traits | NSItalicFontMask;
	if ([[aStyleAttributeDictionary objectForKey:@"font-weight"] isEqualToString:@"bold"])  traits = traits | NSBoldFontMask;
	NSFont *font=[[NSFontManager sharedFontManager] convertFont:aFont toHaveTrait:traits];
	
//	synthesise it if needed (e.g. bold and italic can be created artificially)
	BOOL synthesise=[[NSUserDefaults standardUserDefaults] boolForKey:SynthesiseFontsPreferenceKey];
	float obliquenessFactor=0.;
	if (synthesise && (traits & NSItalicFontMask) && !([[NSFontManager sharedFontManager] traitsOfFont:font] & NSItalicFontMask)) {
		obliquenessFactor=.2;
	}
	float strokeWidth=.0;
	if (synthesise && (traits & NSBoldFontMask) && !([[NSFontManager sharedFontManager] traitsOfFont:font] & NSBoldFontMask)) {
		strokeWidth=darkBackground?-9.:-3.;
	}


	NSColor *foregroundColor = [aStyleAttributeDictionary objectForKey:@"color"];
	
	NSMutableDictionary *result=[NSMutableDictionary dictionaryWithObjectsAndKeys:font,NSFontAttributeName,
			foregroundColor,NSForegroundColorAttributeName,
			[NSNumber numberWithFloat:obliquenessFactor],NSObliquenessAttributeName,
			[NSNumber numberWithFloat:strokeWidth],NSStrokeWidthAttributeName,
			nil];
	
	if (backgroundColor) {
		[result setObject:backgroundColor forKey:NSBackgroundColorAttributeName];
	}
	
	if ([[aStyleAttributeDictionary objectForKey:@"font-strike-through"] isEqualToString:@"strike-through"])
		[result setObject:[NSNumber numberWithInteger:NSUnderlineStyleSingle] forKey:NSStrikethroughStyleAttributeName];
	
	if ([[aStyleAttributeDictionary objectForKey:@"font-underline"] isEqualToString:@"underline"])
		[result setObject:[NSNumber numberWithInteger:NSUnderlineStyleSingle] forKey:NSUnderlineStyleAttributeName];

	return result;
	
}


@synthesize scopeStyleDictionary = I_scopeStyleDictionary;
@synthesize scopeCache = I_scopeCache;
@synthesize allScopes = I_allScopes;

- (id)init {
	if ((self = [super init])) {
		I_scopeStyleDictionary = [NSMutableDictionary new];
		I_scopeCache = [NSMutableDictionary new];
	}
	return self;
}

- (id)initWithDefinition:(SyntaxDefinition*)aDefinition {
    if ((self = [self init])) {
		if (aDefinition) {
			[aDefinition getReady];
			[self.scopeStyleDictionary addEntriesFromDictionary:[aDefinition scopeStyleDictionary]];
			NSArray *styleSheets = [aDefinition linkedStyleSheets];
			
			for (NSString *sheet in styleSheets) {
				[self importStyleSheetAtPath:[[[NSURL alloc] initFileURLWithPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:[NSString stringWithFormat:@"Modes/Styles/%@.sss",sheet]]] autorelease]];
			}
		}		
//		NSLog(@"scopes: %@", scopeStyleDictionary);
//		NSLog(@"inherit: %@", [self styleAttributesForScope:@"meta.block.directives.objective-c"]);
// FIXME autoexport still active
		[self exportStyleSheetToPath:[[[NSURL alloc]initFileURLWithPath:[NSString stringWithFormat:@"/tmp/%@.sss",[aDefinition name]]] autorelease]];
		
	}
	return self;
}

- (void)dealloc {
	self.scopeCache = nil;
	self.scopeStyleDictionary = nil;
	[super dealloc];
}


- (void)importStyleSheetAtPath:(NSURL *)aPath {
	NSError *err;
	NSString *importString = [NSString stringWithContentsOfURL:aPath encoding:NSUTF8StringEncoding error:&err];
	
	importString = [[[[OGRegularExpression alloc] initWithString:@"\\/\\/[^\\n]+" options:OgreFindNotEmptyOption] autorelease] replaceAllMatchesInString:importString withString:@"" options:OgreNoneOption];
	importString = [[[[OGRegularExpression alloc] initWithString:@"\\/\\*.*?\\*\\/" options:OgreFindNotEmptyOption|OgreMultilineOption] autorelease] replaceAllMatchesInString:importString withString:@"" options:OgreNoneOption];	
		
	NSArray *scopeStrings = [importString componentsSeparatedByString:@"}"];
	
	for (NSString *scopeString in scopeStrings) {
	
		NSArray *scopeAndAttributes = [scopeString componentsSeparatedByString:@"{"];
		if ([scopeAndAttributes count] !=2) continue;
		NSString *scope = [[scopeAndAttributes objectAtIndex:0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		NSArray *attributes = [[scopeAndAttributes objectAtIndex:1] componentsSeparatedByString:@";"];
		NSMutableDictionary *scopeDictionary = [NSMutableDictionary dictionary];
		for (NSString *attribute in attributes) {
			NSArray *keysAndValues = [attribute componentsSeparatedByString:@":"];
			if ([keysAndValues count] !=2) continue;
			NSString *key = [[keysAndValues objectAtIndex:0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
			id value = [[keysAndValues objectAtIndex:1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
			if ([key rangeOfString:@"color"].location != NSNotFound) {
				value = [NSColor colorForHTMLString:value];
			}
			if ([key isEqualToString:@"font-trait"]) {
				value = [NSNumber numberWithInt:[value intValue]];
			}
			
			[scopeDictionary setObject:value forKey:key];
		}

		if (scope && [scopeDictionary count]>0)
		[self.scopeStyleDictionary setObject:scopeDictionary forKey:scope];
	
	}
	//Clear Cache
	[self.scopeCache removeAllObjects];

}

- (void) exportStyleSheetToPath:(NSURL *)aPath{
	
	NSMutableString *exportString = [NSMutableString string];
	for (NSString *scope in self.allScopes) {
		[exportString appendString:[NSString stringWithFormat:@"%@ {\n", scope]];
		
		for(NSString *attribute in [[[self.scopeStyleDictionary objectForKey:scope] allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]) {
			id value = [[self.scopeStyleDictionary objectForKey:scope] objectForKey:attribute];
			if ([value isKindOfClass:[NSColor class]]) value = [(NSColor*)value HTMLString];
			[exportString appendString:[NSString stringWithFormat:@"   %@:%@;\n", attribute, value]];
		}
		
		[exportString appendString:@"}\n\n"];
		
	}
	
	NSError *err;
	if (aPath) [exportString writeToURL:aPath atomically:YES encoding:NSUTF8StringEncoding error:&err];
	else NSLog(@"%@",exportString);
}

- (NSDictionary *)styleAttributesForScope:(NSString *)aScope {
	
	//Delete language specific part
	
	NSDictionary *computedStyle = [I_scopeCache objectForKey:aScope];
	
	
	if (!computedStyle) {

//	Start with a base style
		NSMutableDictionary *styleResult = [NSMutableDictionary dictionaryWithObjectsAndKeys:
			[NSColor colorWithCalibratedWhite:0.0 alpha:1.0],@"color",
			[NSColor colorWithCalibratedWhite:1.0 alpha:1.0],@"background-color",
			@"normal",@"font-weight",
			@"normal",@"font-style",
			@"none",@"font-underline",
			@"none",@"font-strike-through",
			nil];

//	Use the meta.default to augment the baseline
		NSDictionary *metaDefaultDictionary = [I_scopeStyleDictionary objectForKey:@"meta.default"];
		if (metaDefaultDictionary) {
			// might want to exclude other things here
			[styleResult addEntriesFromDictionary:metaDefaultDictionary];
		}
		
//	check all our possible ancestors and incorporate them
		NSArray *components = [aScope componentsSeparatedByString:@"."];
		NSString *combinedComponents = nil;
		for (NSString *component in components) {
			if (combinedComponents) combinedComponents = [combinedComponents stringByAppendingPathExtension:component];
			else combinedComponents = component;
			
			NSDictionary *styleToInheritFrom = [I_scopeStyleDictionary objectForKey:combinedComponents];
			if (styleToInheritFrom) {
				[styleResult addEntriesFromDictionary:styleToInheritFrom];
			}
		}

//  cache the result
		[I_scopeCache setObject:styleResult forKey:aScope];
		computedStyle = styleResult;

//	Sorry, didn't get the mechanics here…
//		NSString *newScope = [NSString stringWithString:aScope];
//		newScope = [newScope stringByDeletingPathExtension];
//		// Search for optimal style
////		 NSLog(@"Asked for %@", aScope);
//		// First try full matching
//		if (!(computedStyle = [self.scopeStyleDictionary objectForKey:newScope])||[computedStyle objectForKey:@"inherit"]) {
//			while([newScope rangeOfString:@"."].location != NSNotFound) {
//				newScope = [newScope stringByDeletingPathExtension];
////				NSLog(@"Looking for %@", newScope);
//				if ((computedStyle = [self.scopeStyleDictionary objectForKey:newScope])) {
//					[self.scopeCache setObject:computedStyle forKey:aScope];
////					NSLog(@"Returned %@", newScope);
//					return computedStyle;
//				}
//			}
//		}
//		
//		// last, fall back to inheritence and language specifics
//		
//		if (!computedStyle) computedStyle = [self.scopeStyleDictionary objectForKey:aScope];
//		if ([computedStyle objectForKey:@"inherit"]) {
//			while ([computedStyle objectForKey:@"inherit"]) {
//				if ([aScope isEqualToString:[computedStyle objectForKey:@"inherit"]]) {
//					NSLog(@"WARNING: Endless inheritance for %@", aScope);
//					break;
//				}
//				aScope = [computedStyle objectForKey:@"inherit"];
//				computedStyle = [self.scopeStyleDictionary objectForKey:aScope];
//			}
//		} 
//		
//		if (!computedStyle) return nil;
////		NSLog(@"Returned %@", aScope);


//		[I_scopeCache setObject:computedStyle forKey:aScope];
	}
	
	return computedStyle;
}

- (void)setStyleAttributes:(NSDictionary *)aStyleAttributeDictionary forScope:(NSString *)aScopeString {
	[self.scopeStyleDictionary setObject:aStyleAttributeDictionary forKey:aScopeString];
	[I_scopeCache removeAllObjects]; //invalidate caching
	self.allScopes = nil;
}

- (NSDictionary *)styleAttributesForExactScope:(NSString *)anExactScopeString {
	return [self.scopeStyleDictionary objectForKey:anExactScopeString];
}

- (NSArray *)allScopes {
	if (!I_allScopes) {
		I_allScopes = [[[self.scopeStyleDictionary allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] copy];
	}
	return I_allScopes;
}


@end


