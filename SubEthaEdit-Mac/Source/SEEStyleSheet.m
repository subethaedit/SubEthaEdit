//  SEEStyleSheet.m
//  SubEthaEdit
//
//  Created by Martin Pittenauer on 05.11.10.

#import "SEEStyleSheet.h"
#import "SyntaxDefinition.h"
#import "PreferenceKeys.h"

#import "DocumentModeManager.h"

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

@interface SEEStyleSheet () {
    NSDictionary *_scopeStyleDictionaryPersistentState;
    NSMutableDictionary *_scopeExampleCache;
    NSArray *_allScopesWithExamples;
}
@property (nonatomic, strong, readwrite) NSArray *allScopes;
- (void)clearCache;
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
	
	// this may have inheritance issues

	/* we don't do background color in the styles, we just use it document wide
	if (backgroundColor) {
		[result setObject:backgroundColor forKey:NSBackgroundColorAttributeName];
	}
	 */
	NSNumber *strikeThroughStyle = [[aStyleAttributeDictionary objectForKey:SEEStyleSheetFontStrikeThroughKey] isEqualToString:SEEStyleSheetValueStrikeThrough] ? [NSNumber numberWithInteger:NSUnderlineStyleSingle] : [NSNumber numberWithInteger:0];
	[result setObject:strikeThroughStyle forKey:NSStrikethroughStyleAttributeName];
	
	NSNumber *underlineStyle = [[aStyleAttributeDictionary objectForKey:SEEStyleSheetFontUnderlineKey] isEqualToString:SEEStyleSheetValueUnderline] ? [NSNumber numberWithInteger:NSUnderlineStyleSingle] : [NSNumber numberWithInteger:0];
	[result setObject:underlineStyle forKey:NSUnderlineStyleAttributeName];

	return result;
	
}

- (id)init {
	if ((self = [super init])) {
		_scopeStyleDictionary = [NSMutableDictionary new];
		_scopeCache = [NSMutableDictionary new];
		_scopeExampleCache = [NSMutableDictionary new];
	}
	return self;
}

- (void)importStyleSheetAtPath:(NSURL *)aPath {
    NSError *err;
    NSString *importString = [NSString stringWithContentsOfURL:aPath encoding:NSUTF8StringEncoding error:&err];
    
    OGRegularExpression *expression = [[OGRegularExpression alloc] initWithString:@"\\/\\/[^\\n]+" options:OgreFindNotEmptyOption];
    importString = [expression replaceAllMatchesInString:importString withString:@"" options:OgreNoneOption];
    expression = [[OGRegularExpression alloc] initWithString:@"\\/\\*.*?\\*\\/" options:OgreFindNotEmptyOption|OgreMultilineOption];
    importString = [expression replaceAllMatchesInString:importString withString:@"" options:OgreNoneOption];
    
    NSArray *scopeStrings = [importString componentsSeparatedByString:@"}"];
	
	for (NSString *scopeString in scopeStrings) {
	
		NSArray *scopeAndAttributes = [scopeString componentsSeparatedByString:@"{"];
        if ([scopeAndAttributes count] !=2) { continue; }
		NSString *scope = [[scopeAndAttributes objectAtIndex:0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		NSArray *attributes = [[scopeAndAttributes objectAtIndex:1] componentsSeparatedByString:@";"];
		NSMutableDictionary *scopeDictionary = [NSMutableDictionary dictionary];
		for (NSString *attribute in attributes) {
			NSArray *keysAndValues = [attribute componentsSeparatedByString:@":"];
            if ([keysAndValues count] !=2) { continue; }
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
	[self clearCache];
}

#pragma mark - Coda 2 Convert/Scope Rename
- (NSArray *)updateScopesWithChangesDictionary:(NSDictionary *)aChangesDictionary {
	NSArray *result = nil;

	NSArray *usedScopeNames = [self.scopeStyleDictionary allKeys]; // scopes used in the current sheet
	NSMutableDictionary *neededChangesDictionary = [NSMutableDictionary dictionary];
	
	for (NSString *key in aChangesDictionary) {
		if ([usedScopeNames containsObject:key]) {
			// the original scope name is in use
			NSString *changedScopeName = [aChangesDictionary objectForKey:key];
			if (![usedScopeNames containsObject:changedScopeName]) {
				// and the changed scope name does not exist
				[neededChangesDictionary setObject:changedScopeName forKey:key];
				
			} //  else -  there is already an entry for that other scope - don't overwrite that
		} // else - that key is not used by this sheet
	}
	
	if ([neededChangesDictionary count] > 0) {
		[self addUpdatedScopesToStyleSheet:neededChangesDictionary];
		result = [[neededChangesDictionary allValues] copy];
	}
	return result;
}

- (void)addUpdatedScopesToStyleSheet:(NSDictionary *)aChangesDictionary {
	NSDictionary *styleDictForOriginalKey;
	for (NSString *originalScope in aChangesDictionary) {
		NSString *changedScope = [aChangesDictionary objectForKey:originalScope];
		styleDictForOriginalKey = [self styleAttributesForExactScope:originalScope];
		[self setStyleAttributes:styleDictForOriginalKey forScope:changedScope];
	}
}

- (void)appendStyleSheetSnippetsForScopes:(NSArray *)aScopeArray toSheetAtURL:(NSURL *)aURL {
	if (aURL) {
		NSMutableString *appendString = [[NSMutableString alloc] init];
		[appendString appendString:@"\n/* The following Scopes were added automatically to accommodate scope-name changes for SEE 4.0 */\n\n"];
		NSString *styleString;
		for (NSString *scope in aScopeArray) {
			styleString = [self styleSheetSnippetForScope:scope];
			if (styleString) {
				[appendString appendString:styleString];
			} // else: something went wrong somewhere
		}
		
		NSError *error = nil;
		NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingToURL:aURL error:&error];
		if (!error && fileHandle) {
			@try {
				[fileHandle seekToEndOfFile];
				[fileHandle writeData:[appendString dataUsingEncoding:NSUTF8StringEncoding]];
			}
			@catch (NSException *exception) {
				NSLog(@"%@", exception);
			}
		}
	}
}

#pragma mark
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

- (void)exportStyleSheetToPath:(NSURL *)aPath {
	
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
		NSDictionary *metaDefaultDictionary = [_scopeStyleDictionary objectForKey:SEEStyleSheetMetaDefaultScopeName];
		if (metaDefaultDictionary) {
			// might want to exclude other things here
			[styleResult addEntriesFromDictionary:metaDefaultDictionary];
		}
	return styleResult;
}

- (NSDictionary *)styleAttributesForScope:(NSString *)aScope {
	
	//Delete language specific part
	
	NSDictionary *computedStyle = _scopeCache[aScope];
	
	if (!computedStyle) {

//	Start with a base style
		NSMutableDictionary *styleResult = [self metaDefaultStyleWithDefaults];
		
//	check all our possible ancestors and incorporate them
		NSArray *components = [aScope componentsSeparatedByString:@"."];
		NSString *combinedComponents = nil;
		for (NSString *component in components) {
			if (combinedComponents) combinedComponents = [combinedComponents stringByAppendingPathExtension:component];
			else combinedComponents = component;
			
			NSDictionary *styleToInheritFrom = [_scopeStyleDictionary objectForKey:combinedComponents];
			if (styleToInheritFrom) {
				[styleResult addEntriesFromDictionary:styleToInheritFrom];
			}
		}

//  cache the result
		_scopeCache[aScope] = styleResult;
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

- (void)clearCache {
	[_scopeCache removeAllObjects]; //invalidate caching
	[_scopeExampleCache removeAllObjects];
	self.allScopes = nil;
	_allScopesWithExamples = nil;
}

- (void)removeStyleAttributesForScope:(NSString *)aScopeString {
	[self.scopeStyleDictionary removeObjectForKey:aScopeString];
	[self clearCache];
}

- (void)setScopeExamples:(NSDictionary *)aDictionary {
	_scopeExamples = [aDictionary copy];
	[self clearCache];
}

- (void)setStyleAttributes:(NSDictionary *)aStyleAttributeDictionary forScope:(NSString *)aScopeString {
	[self.scopeStyleDictionary setObject:aStyleAttributeDictionary forKey:aScopeString];
	[self clearCache];
}

- (void)computeScopeExamples {
	NSMutableDictionary *examples = [self.scopeExamples mutableCopy];
	
	NSArray *longestFirstScopes = [[self.scopeStyleDictionary allKeys] sortedArrayUsingComparator:^(id obj1, id obj2){ 
		NSUInteger length1 = [(NSString *)obj1 length]; NSUInteger length2 = [(NSString *)obj2 length];
		return (NSComparisonResult)(length1 == length2 ? NSOrderedSame : (length1>length2 ? NSOrderedAscending : NSOrderedDescending));
	}];
//	NSLog(@"%s longestFirstScopes: %@",__FUNCTION__, longestFirstScopes);
	
	NSMutableArray *exampleCollector = [NSMutableArray array];
	for (NSString *scope in longestFirstScopes) {
		for (NSString *exampleScopeKey in [examples allKeys]) {
			if ([exampleScopeKey hasPrefix:scope]) {
				[exampleCollector addObject:[examples objectForKey:exampleScopeKey]];
				[examples removeObjectForKey:exampleScopeKey];
			}
		}
		if (exampleCollector.count) {
			[_scopeExampleCache setObject:[exampleCollector componentsJoinedByString:@" "] forKey:scope];
			[exampleCollector removeAllObjects];
		}
	}
	
	if (!_allScopesWithExamples) {
		_allScopesWithExamples = [[[[_scopeExampleCache allKeys] arrayByAddingObject:SEEStyleSheetMetaDefaultScopeName] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] copy];
	}
}

- (NSString *)exampleForScope:(NSString *)aScope {
	if ([_scopeExampleCache count] == 0 && [_scopeExamples count] > 0) {
		[self computeScopeExamples];
	}
	NSString *result = [_scopeExampleCache objectForKey:aScope];
	if (!result) result = @" - no example -";
	return result;
}

- (NSDictionary *)styleAttributesForExactScope:(NSString *)anExactScopeString {
	return [self.scopeStyleDictionary objectForKey:anExactScopeString];
}

- (NSArray *)allScopes {
	if (!_allScopes) {
		_allScopes = [[[self.scopeStyleDictionary allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] copy];
	}
	return _allScopes;
}

- (NSArray *)allScopesWithExamples {
	if (!_allScopesWithExamples) {
		[self computeScopeExamples];
	}
	return _allScopesWithExamples;
}

#pragma mark - Color Accessors
// convenience accesors for special values
- (NSColor *)documentBackgroundColor {
	return [[self styleAttributesForScope:SEEStyleSheetMetaDefaultScopeName] objectForKey:SEEStyleSheetFontBackgroundColorKey];
}

- (NSColor *)documentForegroundColor {
	return [[self styleAttributesForScope:SEEStyleSheetMetaDefaultScopeName] objectForKey:SEEStyleSheetFontForegroundColorKey];
}

#pragma mark - Persisted State
- (BOOL)hasChanges {
	return ![_scopeStyleDictionary isEqual:_scopeStyleDictionaryPersistentState];
}

- (void)markCurrentStateAsPersistent {
	 _scopeStyleDictionaryPersistentState = [_scopeStyleDictionary copy];
}

- (void)revertToPersistentState {
	self.scopeStyleDictionary = [_scopeStyleDictionaryPersistentState mutableCopy];
	[self clearCache];
}

@end


