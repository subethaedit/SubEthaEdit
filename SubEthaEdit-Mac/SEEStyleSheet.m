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
 scope/style pairs. A Style sheet represents a color scheme.
 The user can set one Style Sheet per Language Scope in a Mode.
 Which currently is identical with the useautocompletefrom of a state.
 
 */

NSString * const SEEStyleSheetFontStyleKey			 = @"font-style";
NSString * const SEEStyleSheetFontWeightKey			 = @"font-weight";
NSString * const SEEStyleSheetFontUnderlineKey		 = @"font-underline";
NSString * const SEEStyleSheetFontStrikeThroughKey	 = @"font-strike-through";
NSString * const SEEStyleSheetFontForegroundColorKey = @"color";
NSString * const SEEStyleSheetFontBackgroundColorKey = @"background-color";
NSString * const SEEStyleSheetValueNormal            = @"normal";
NSString * const SEEStyleSheetValueNone              = @"none";
NSString * const SEEStyleSheetValueBold              = @"bold";
NSString * const SEEStyleSheetValueUnderline         = @"underline";
NSString * const SEEStyleSheetValueItalic            = @"italic";
NSString * const SEEStyleSheetValueStrikeThrough     = @"strike-through";

NSString * const SEEStyleSheetMetaDefaultScopeName   = @"meta.default";

NSString * const SEEStyleSheetFileExtension = @"sss";

@interface SEEStyleSheet ()
@property (nonatomic, retain, readwrite) NSArray *allScopes;
@end

@implementation SEEStyleSheet


+ (NSDictionary *)textAttributesForStyleAttributes:(NSDictionary *)aStyleAttributeDictionary font:(NSFont *)aFont {
	
//	NSLog(@"%s %@",__FUNCTION__,aStyleAttributeDictionary);
	
//	check darkness of background for use in strokewidth bold synthesizing later on
	NSColor *backgroundColor=[aStyleAttributeDictionary objectForKey:SEEStyleSheetFontBackgroundColorKey];
	BOOL darkBackground = [backgroundColor isDark];
	
//	generate the font we'd like
	NSFontTraitMask traits = 0;
	if ([[aStyleAttributeDictionary objectForKey:SEEStyleSheetFontStyleKey] isEqualToString:SEEStyleSheetValueItalic]) traits = traits | NSItalicFontMask;
	if ([[aStyleAttributeDictionary objectForKey:SEEStyleSheetFontWeightKey] isEqualToString:SEEStyleSheetValueBold])  traits = traits | NSBoldFontMask;
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


	NSColor *foregroundColor = [aStyleAttributeDictionary objectForKey:SEEStyleSheetFontForegroundColorKey];
	
	NSMutableDictionary *result=[NSMutableDictionary dictionaryWithObjectsAndKeys:font,NSFontAttributeName,
			foregroundColor,NSForegroundColorAttributeName,
			[NSNumber numberWithFloat:obliquenessFactor],NSObliquenessAttributeName,
			[NSNumber numberWithFloat:strokeWidth],NSStrokeWidthAttributeName,
			nil];
	
	if (backgroundColor) {
		[result setObject:backgroundColor forKey:NSBackgroundColorAttributeName];
	}
	
	if ([[aStyleAttributeDictionary objectForKey:SEEStyleSheetFontStrikeThroughKey] isEqualToString:SEEStyleSheetValueStrikeThrough])
		[result setObject:[NSNumber numberWithInteger:NSUnderlineStyleSingle] forKey:NSStrikethroughStyleAttributeName];
	
	if ([[aStyleAttributeDictionary objectForKey:SEEStyleSheetFontUnderlineKey] isEqualToString:SEEStyleSheetValueUnderline])
		[result setObject:[NSNumber numberWithInteger:NSUnderlineStyleSingle] forKey:NSUnderlineStyleAttributeName];

	return result;
	
}


@synthesize scopeStyleDictionary = I_scopeStyleDictionary;
@synthesize scopeCache = I_scopeCache;
@synthesize allScopes = I_allScopes;
@synthesize styleSheetName = I_styleSheetName;


- (id)init {
	if ((self = [super init])) {
		I_scopeStyleDictionary = [NSMutableDictionary new];
		I_scopeCache = [NSMutableDictionary new];
	}
	return self;
}

- (void)dealloc {
	self.scopeCache = nil;
	self.scopeStyleDictionary = nil;
	[I_scopeStyleDictionaryPersistentState release];
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
			if ([key rangeOfString:SEEStyleSheetFontForegroundColorKey].location != NSNotFound) {
				value = [NSColor colorForHTMLString:value];
			}
			// deprecated
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

- (NSString *)styleSheetSnippetForScope:(NSString *)aScope {
	NSMutableArray *attributes = [NSMutableArray array];
	NSDictionary *style = [self styleAttributesForExactScope:aScope];
	for (NSString *attribute in [[style allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]) {
			id value = [style objectForKey:attribute];
			if ([value isKindOfClass:[NSColor class]]) value = [(NSColor*)value HTMLString];
			[attributes addObject:[NSString stringWithFormat:@"%@:%@;", attribute, value]];
	}
	return [NSString stringWithFormat:@"%@ {\n  %@\n}\n\n", aScope, [attributes componentsJoinedByString:@"\n  "]];
}

- (void)exportStyleSheetToPath:(NSURL *)aPath{
	
	NSMutableString *exportString = [NSMutableString string];
	for (NSString *scope in self.allScopes) {
		[exportString appendString:[self styleSheetSnippetForScope:scope]];
	}
	
	NSError *err;
	if (aPath) [exportString writeToURL:aPath atomically:YES encoding:NSUTF8StringEncoding error:&err];
	else NSLog(@"%@",exportString);
}

- (NSMutableDictionary *)metaDefaultStyleWithDefaults {
	NSMutableDictionary *styleResult = [NSMutableDictionary dictionaryWithObjectsAndKeys:
		[NSColor colorWithCalibratedWhite:0.0 alpha:1.0],SEEStyleSheetFontForegroundColorKey,
		[NSColor colorWithCalibratedWhite:1.0 alpha:1.0],SEEStyleSheetFontBackgroundColorKey,
		@"normal",SEEStyleSheetFontWeightKey,
		@"normal",SEEStyleSheetFontStyleKey,
		@"none",SEEStyleSheetFontUnderlineKey,
		@"none",SEEStyleSheetFontStrikeThroughKey,
		nil];
		NSDictionary *metaDefaultDictionary = [I_scopeStyleDictionary objectForKey:SEEStyleSheetMetaDefaultScopeName];
		if (metaDefaultDictionary) {
			// might want to exclude other things here
			[styleResult addEntriesFromDictionary:metaDefaultDictionary];
		}
	return styleResult;
}

- (NSDictionary *)styleAttributesForScope:(NSString *)aScope {
	
	//Delete language specific part
	
	NSDictionary *computedStyle = [I_scopeCache objectForKey:aScope];
	
	if (!computedStyle) {

//	Start with a base style
		NSMutableDictionary *styleResult = [self metaDefaultStyleWithDefaults];
		
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


// convenience accesors for special values
- (NSColor *)documentBackgroundColor {
	return [[self styleAttributesForScope:SEEStyleSheetMetaDefaultScopeName] objectForKey:SEEStyleSheetFontBackgroundColorKey];
}

- (NSColor *)documentForegroundColor {
	return [[self styleAttributesForScope:SEEStyleSheetMetaDefaultScopeName] objectForKey:SEEStyleSheetFontForegroundColorKey];
}

- (BOOL)hasChanges {
	return ![I_scopeStyleDictionary isEqual:I_scopeStyleDictionaryPersistentState];
}

- (void)markCurrentStateAsPersistent {
	[I_scopeStyleDictionaryPersistentState release];
	 I_scopeStyleDictionaryPersistentState = [I_scopeStyleDictionary copy];
}


@end


