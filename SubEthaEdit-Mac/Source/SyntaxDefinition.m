//  SyntaxDefinition.m
//  SyntaxTestBench
//
//  Created by Martin Pittenauer on Wed Mar 17 2004.

// this file needs arc - either project wide,
// or add -fobjc-arc on a per file basis in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif


#import "DocumentModeManager.h"
#import "SyntaxDefinition.h"
#import "NSColorTCMAdditions.h"
#import "TCMFoundation.h"
#import "SyntaxHighlighter.h"
#import "SEEStyleSheet.h"

static NSString * const StateDictionarySwitchToAutocompleteFromModeKey = @"switchtoautocompletefrommode";
static NSString * const StateDictionaryUseAutocompleteFromModeKey      = @"useautocompletefrommode";

@interface SyntaxDefinition (PrivateAdditions)
- (void)addAttributes:(NSArray *)attributes toDictionary:(NSMutableDictionary *)aDictionary;
@end

@implementation SyntaxDefinition
/*"A Syntax Definition"*/

#pragma mark - Initizialisation

@synthesize scopeStyleDictionary = I_scopeStyleDictionary;
@synthesize linkedStyleSheets = I_linkedStyleSheets;

/*"Initiates the Syntax Definition with an XML file"*/
- (id)initWithFile:(NSString *)aPath forMode:(DocumentMode *)aMode {
    self=[super init];
    if (self) {
        if (!aPath) {
            return nil;
        }
        // Alloc & Init
        I_defaultState = [NSMutableDictionary new];
        I_importedModes = [NSMutableDictionary new];
        I_allStates = [NSMutableDictionary new];
        I_defaultSyntaxStyle = [SyntaxStyle new];
		I_allScopesArray =  [[NSMutableArray alloc] initWithObjects:SEEStyleSheetMetaDefaultScopeName, nil];
		I_allLanguageContextsArray = [[NSMutableArray alloc] initWithObjects:[aMode scriptedName], nil];

		self.scopeStyleDictionary = [NSMutableDictionary dictionary];
		self.linkedStyleSheets = [NSMutableArray array];

        everythingOkay = YES;
        I_foldingTopLevel = 1;

        // Parse XML File
        [self setMode:aMode];
        [I_defaultSyntaxStyle setDocumentMode:aMode];
		[self parseXMLFile:aPath];

        // Setup stuff <-> style dictionaries
        I_stylesForToken = [NSMutableDictionary new];
        I_stylesForRegex = [NSMutableDictionary new];
        I_combinedStateRegexReady = NO;
		I_combinedStateRegexCalculating = NO;
        I_cacheStylesReady = NO;
		I_cacheStylesCalculating = NO;
		I_symbolAndAutocompleteInheritanceReady=NO;
		I_levelsForStyleIDs = [NSMutableDictionary new];
		I_keyForInheritedSymbols = nil;
		I_keyForInheritedAutocomplete = nil;

	    if (!everythingOkay) {
			NSLog(@"Critical errors while loading syntax definition. Not loading syntax highlighter.");
			return nil;
		}
	}
	return self;
}

#pragma mark - XML parsing

-(void) showWarning:(NSString *)title withDescription:(NSString *)description {
	NSLog(@"ERROR: %@: %@",title, description);
	NSAlert *alert = [[NSAlert alloc] init];
	[alert setAlertStyle:NSAlertStyleWarning];
	[alert setMessageText:title];
	[alert setInformativeText:description];
	[alert addButtonWithTitle:@"OK"];
	[alert runModal];
	everythingOkay = NO;
}

/*"Entry point for XML parsing, branches to according node functions"*/
-(void)parseXMLFile:(NSString *)aPath {

    NSError *err=nil;
    NSXMLDocument *syntaxDefinitionXML = [[NSXMLDocument alloc] initWithData:[NSData dataWithContentsOfFile:aPath] options:0 error:&err];

    if (err) {
		[self showWarning:NSLocalizedString(@"XML Structure Error",@"XML Structure Error Title")  withDescription:[NSString stringWithFormat:NSLocalizedString(@"Error while loading '%@': %@",@"Syntax XML Loading Error Informative Text"),aPath, [err localizedDescription]]];
        return;
    } 

    //Parse Headers
    [self setName:[[self mode] documentModeIdentifier]];

    NSString *charsInToken = [[[syntaxDefinitionXML nodesForXPath:@"/syntax/head/charsintokens" error:&err] lastObject] stringValue];
    NSString *charsDelimitingToken = [[[syntaxDefinitionXML nodesForXPath:@"/syntax/head/charsdelimitingtokens" error:&err] lastObject] stringValue];
    NSCharacterSet *tokenSet = nil; // TODO: what should be the value if neither charsInToken nor charsDelimitingToken?
    
	NSXMLNode *bracketMatchingBracketNode = [[syntaxDefinitionXML nodesForXPath:@"/syntax/head/bracketmatching/@brackets" error:&err] lastObject];
	if (bracketMatchingBracketNode) {
		self.bracketMatchingBracketString = [bracketMatchingBracketNode stringValue];
	}
	
    NSXMLNode *foldingTopLevel = [[syntaxDefinitionXML nodesForXPath:@"/syntax/head/folding/@toplevel" error:&err] lastObject];
    if (foldingTopLevel) {
    	I_foldingTopLevel = [[foldingTopLevel stringValue] intValue];
    }
    
    I_charsInToken = nil;
    I_charsDelimitingToken = nil;
    
    if (charsInToken) {
        tokenSet = [NSCharacterSet characterSetWithCharactersInString:charsInToken];
        I_charsInToken = [charsInToken copy];
    } else if (charsDelimitingToken) {
        tokenSet = [NSCharacterSet characterSetWithCharactersInString:charsDelimitingToken];
        tokenSet = [tokenSet invertedSet];
        I_charsDelimitingToken = [charsDelimitingToken copy];
    }
    
    [self setTokenSet:tokenSet];

    I_tokenRegex = nil;
    
    if (I_charsInToken) {
        I_tokenRegex = [[OGRegularExpression alloc] initWithString:[NSString stringWithFormat:@"[%@]+",[I_charsInToken stringByReplacingRegularExpressionOperators]] options:OgreFindNotEmptyOption|OgreCaptureGroupOption];
    } else if (I_charsDelimitingToken) {
        I_tokenRegex = [[OGRegularExpression alloc] initWithString:[NSString stringWithFormat:@"[^%@]+",[I_charsDelimitingToken stringByReplacingRegularExpressionOperators]] options:OgreFindNotEmptyOption|OgreCaptureGroupOption];
    }        
        
    NSString *charsInCompletion = [[[syntaxDefinitionXML nodesForXPath:@"/syntax/head/charsincompletion" error:&err] lastObject] stringValue];


    if (charsInCompletion) {
        [self setAutoCompleteTokenSet:[NSCharacterSet characterSetWithCharactersInString:charsInCompletion]];
        I_autocompleteTokenString = [charsInCompletion copy];
    }

    I_useSpellingDictionary = [[[[syntaxDefinitionXML nodesForXPath:@"/syntax/head/autocompleteoptions/@use-spelling-dictionary" error:&err] lastObject] stringValue] isEqualTo:@"yes"];    

	
	// Parse inline scopes
	
	NSArray *scopeNodes = [syntaxDefinitionXML nodesForXPath:@"/syntax/head/scopes/scope" error:&err];
	for (id scopeNode in scopeNodes) {
		NSMutableDictionary *scopeAttributes = [NSMutableDictionary dictionary];
		[self addAttributes:[scopeNode attributes] toDictionary:scopeAttributes];
		if ([scopeAttributes objectForKey:@"scopeid"])
			[self.scopeStyleDictionary setObject:scopeAttributes forKey:[scopeAttributes objectForKey:@"scopeid"]];
	}

	// Parse linked sheets

	NSArray *sheetNodes = [syntaxDefinitionXML nodesForXPath:@"/syntax/head/stylesheet" error:&err];
	for (id sheetNode in sheetNodes) {
		[self.linkedStyleSheets addObject:[sheetNode stringValue]];
	}
	
	
    // Parse states
    NSXMLElement *defaultStateNode = [[syntaxDefinitionXML nodesForXPath:@"/syntax/states/default" error:&err] lastObject];
	
	if (!defaultStateNode) {
		[self showWarning:NSLocalizedString(@"XML Structure Error",@"XML Structure Error Title")  withDescription:[NSString stringWithFormat:NSLocalizedString(@"Error while loading '%@': File has no default state defined",@"Syntax XML No Default State Error Informative Text"),aPath]];
	}
	
    [self parseState:defaultStateNode addToState:I_defaultState];
    
    // For old-style, non-recursive modes
    NSArray *oldStyleStates = [syntaxDefinitionXML nodesForXPath:@"/syntax/states/state" error:&err];
    if ([oldStyleStates count]>0) {
        NSXMLElement *oldStyleState;
        for (oldStyleState in oldStyleStates) {
            [self parseState:oldStyleState addToState:I_defaultState];
        }
        [I_allStates setObject:I_defaultState forKey:[I_defaultState objectForKey:@"id"]]; // Reread default mode
    }

}

- (void)addAttributes:(NSArray *)attributes toDictionary:(NSMutableDictionary *)aDictionary {
    NSXMLNode *attribute;
    for (attribute in attributes) {
        NSString *attributeName = [attribute name];
        id attributeValue = [attribute stringValue];
        
        // Parse colors
        if ([attributeName isEqualToString:@"color"]||[attributeName isEqualToString:@"inverted-color"]||[attributeName isEqualToString:@"background-color"]||[attributeName isEqualToString:@"inverted-background-color"]) {
            NSColor *aColor = [NSColor colorForHTMLString:attributeValue];
            if (aColor) attributeValue = aColor;
            else {
                [aDictionary removeObjectForKey:attributeValue];
				if (![attributeValue isEqualToString:@"none"])
					[self showWarning:NSLocalizedString(@"XML Color Error",@"XML Color Error Title")  withDescription:[NSString stringWithFormat:NSLocalizedString(@"Cannot parse color '%@' in %@ mode",@"Syntax XML Color Error Informative Text"), attributeValue, [self name]]];
                continue;
            }
        }        
        
        [aDictionary setObject:attributeValue forKey:attributeName];
    }
    
    // Calculate font-trait
    NSFontTraitMask mask = 0;
    if ([[aDictionary objectForKey:@"font-weight"] isEqualTo:@"bold"]) mask = mask | NSBoldFontMask;
    if ([[aDictionary objectForKey:@"font-style"] isEqualTo:@"italic"]) mask = mask | NSItalicFontMask;
    [aDictionary setObject:[NSNumber numberWithUnsignedInt:mask] forKey:@"font-trait"];

    
    // Calculate inverted color if not present
    NSColor *invertedColor = [aDictionary objectForKey:@"inverted-color"];
    if (!invertedColor) {
        invertedColor = [[aDictionary objectForKey:@"color"] brightnessInvertedColor];
        if (invertedColor) [aDictionary setObject:invertedColor forKey:@"inverted-color"];
    }
    
    // Same for background color and inverted background color
    NSColor *backgroundColor = [aDictionary objectForKey:@"background-color"];
    if (!backgroundColor) {
        backgroundColor = [NSColor whiteColor];
        [aDictionary setObject:backgroundColor forKey:@"background-color"];
    }
    if (![aDictionary objectForKey:@"inverted-background-color"]) {
        [aDictionary setObject:[backgroundColor brightnessInvertedColor] forKey:@"inverted-background-color"];
    }
    
    if ([aDictionary objectForKey:@"scope"]) {
        [aDictionary setObject:[NSString stringWithFormat:@"%@.%@", [aDictionary objectForKey:@"scope"], [[self name] lowercaseString]] forKey:@"scope"];
    } else {
        [aDictionary setObject:[NSString stringWithFormat:@"meta.unknown.%@.%@", [aDictionary objectForKey:@"id"], [[self name] lowercaseString]] forKey:@"scope"];
		NSLog(@"DEBUG: No scope specified, assuming %@", [NSString stringWithFormat:@"meta.unknown.%@.%@", [[aDictionary objectForKey:@"id"] lowercaseString], [[self name] lowercaseString]]);
	}
    
    NSString *stateID = [NSString stringWithFormat:@"/%@/%@", [self name], [aDictionary objectForKey:@"id"]];
    if (stateID) {
        [aDictionary setObject:stateID forKey:@"id"];
        [aDictionary setObject:stateID forKey:kSyntaxHighlightingStyleIDAttributeName];
    }
}

- (void)parseState:(NSXMLElement *)stateNode addToState:(NSMutableDictionary *)aState {
    NSError *err;
    NSString *name = [stateNode name];
    NSMutableDictionary *stateDictionary = [NSMutableDictionary dictionary];
    
    [self addAttributes:[stateNode attributes] toDictionary:stateDictionary];

    BOOL isContainerState = [[[stateNode attributeForName:@"containerState"] stringValue] isEqualToString:@"yes"];

    if (isContainerState) {
        [stateDictionary setObject:@"yes" forKey:@"containerState"];
    } else {
        // Parse and prepare begin/end
        NSString *regexBegin = [[[stateNode nodesForXPath:@"./begin/regex" error:&err] lastObject] stringValue];
        NSString *stringBegin = [[[stateNode nodesForXPath:@"./begin/string" error:&err] lastObject] stringValue];
        NSString *regexEnd = [[[stateNode nodesForXPath:@"./end/regex" error:&err] lastObject] stringValue];
        NSString *stringEnd = [[[stateNode nodesForXPath:@"./end/string" error:&err] lastObject] stringValue];

		NSString *autoendBegin = [[[stateNode nodesForXPath:@"./begin/autoend" error:&err] lastObject] stringValue];
		if (autoendBegin) [stateDictionary setObject:autoendBegin forKey:@"AutoendReplacementString"];
		
        if (regexBegin) {
            // Begins get compiled later en-block, so just store a string now.
            [stateDictionary setObject:regexBegin forKey:@"BeginsWithRegexString"];
        } else if (stringBegin) {
            [stateDictionary setObject:stringBegin forKey:@"BeginsWithPlainString"];
        } else {
            if (![name isEqualToString:@"default"])
                [self showWarning:NSLocalizedString(@"XML Structure Error",@"XML Structure Error Title")  withDescription:[NSString stringWithFormat:NSLocalizedString(@"State '%@' in %@ mode has no begin tag",@"Syntax State No Begin Error Informative Text"), [stateDictionary objectForKey:@"id"], [self name]]];
        }
        
        if (regexEnd) {
            OGRegularExpression *endRegex;
            if ([OGRegularExpression isValidExpressionString:regexEnd]) {
                if ((endRegex = [[OGRegularExpression alloc] initWithString:regexEnd options:OgreFindNotEmptyOption]))
                    [stateDictionary setObject:endRegex forKey:@"EndsWithRegex"];
                [stateDictionary setObject:regexEnd forKey:@"EndsWithRegexString"];
            } else {
                [self showWarning:NSLocalizedString(@"XML Regex Error",@"XML Regex Error Title")  withDescription:[NSString stringWithFormat:NSLocalizedString(@"State '%@' in %@ mode has a end tag that is not a valid regex",@"Syntax State Malformed Begin Error Informative Text"), [stateDictionary objectForKey:@"id"], [self name]]];
            }
        } else if (stringEnd) {
            [stateDictionary setObject:stringEnd forKey:@"EndsWithPlainString"];
        } else {
            if (![name isEqualToString:@"default"])
                [self showWarning:NSLocalizedString(@"XML Structure Error",@"XML Structure Error Title")  withDescription:[NSString stringWithFormat:NSLocalizedString(@"State '%@' in %@ mode has no end tag",@"Syntax State No End Error Informative Text"), [stateDictionary objectForKey:@"id"], [self name]]];
        }
    }

    // Add keywords
    NSMutableArray *keywordGroups = [NSMutableArray array];
    [stateDictionary setObject:keywordGroups forKey:@"KeywordGroups"];
    
    NSArray *keywordGroupsNodes = [stateNode nodesForXPath:@"./keywords | ./import" error:&err];
    
    for (id xmlNode in keywordGroupsNodes) {
        NSString *nodeName = [xmlNode name];
		if ([nodeName isEqualToString:@"import"]) //Weak-link to imported states, for later copying
        {  
            NSMutableArray *weaklinks = [stateDictionary objectForKey:@"imports"];
            if (!weaklinks) {
                weaklinks = [NSMutableArray array];
                [stateDictionary setObject:weaklinks forKey:@"imports"];
            }
			
            NSString *importMode, *importState;
            importMode = [[xmlNode attributeForName:@"mode"] stringValue];
            if (!importMode) importMode = [self name];
            
            importState = [[xmlNode attributeForName:@"state"] stringValue];
            if (!importState) importState = SyntaxStyleBaseIdentifier;
            
            NSString *importName = [NSString stringWithFormat:@"/%@/%@", importMode, importState];
            
            [I_importedModes setObject:@"import" forKey:importMode];
            [weaklinks addObject:[NSDictionary dictionaryWithObjectsAndKeys:xmlNode,@"importNode",importName,@"importName",[NSNumber numberWithUnsignedInteger:keywordGroups.count],@"importPosition",nil]];            
        } 
		else if ([nodeName isEqualToString:@"keywords"]) {
			
			NSMutableDictionary *keywordGroupDictionary = [NSMutableDictionary dictionary];
			[self addAttributes:[xmlNode attributes] toDictionary:keywordGroupDictionary];

			NSString *keywordGroupName = [keywordGroupDictionary objectForKey:@"id"];
			if (keywordGroupName) [keywordGroups addObject:keywordGroupDictionary];

			NSMutableArray *regexes = [NSMutableArray array];
			NSMutableArray *strings = [NSMutableArray array];

			// Add regexes for keyword group
			NSMutableString *combinedRegexRegexString = [NSMutableString stringWithString:@"(?:"];

			[keywordGroupDictionary setObject:regexes forKey:@"RegularExpressions"];
			[keywordGroupDictionary setObject:strings forKey:@"PlainStrings"];

			NSArray *regexNodes = [xmlNode nodesForXPath:@"./regex" error:&err];
			NSEnumerator *regexEnumerator = [regexNodes objectEnumerator];
			id regexNode;
			while ((regexNode = [regexEnumerator nextObject])) {
				NSString *regexString = [regexNode stringValue];
				[regexes addObject:regexString];
				[combinedRegexRegexString appendFormat:@"%@|",regexString];
			}
			if ([regexNodes count]>0) {
				[combinedRegexRegexString replaceCharactersInRange:NSMakeRange([combinedRegexRegexString length]-1, 1) withString:@")"];

				@try {
					OGRegularExpression *combinedRegularExpression = [[OGRegularExpression alloc] initWithString:combinedRegexRegexString options:OgreFindNotEmptyOption|OgreCaptureGroupOption];
					if (combinedRegularExpression) {
						[keywordGroupDictionary setObject:combinedRegularExpression forKey:@"CompiledRegEx"];
					}
				}
				@catch (NSException *exception) {
					NSLog(@"Creating regex with %@ did throw exception %@", combinedRegexRegexString, exception);
				}
			}

			// Add strings for keyword group
			NSMutableString *combinedKeywordRegexString = [NSMutableString string];
			if (I_charsInToken) {
				[combinedKeywordRegexString appendFormat:@"(?<![%@])(",[I_charsInToken stringByReplacingRegularExpressionOperators]];
			} else if (I_charsDelimitingToken) {
				[combinedKeywordRegexString appendFormat:@"(?<=[%@]|^)(",[I_charsDelimitingToken stringByReplacingRegularExpressionOperators]];
			} else {
				[combinedKeywordRegexString appendString:@"("];
			}

			BOOL autocomplete = [[keywordGroupDictionary objectForKey:@"useforautocomplete"] isEqualToString:@"yes"];
			NSMutableArray *autocompleteDictionary = [[self mode] autocompleteDictionary];
			NSArray *stringNodes = [xmlNode nodesForXPath:@"./string" error:&err];
			NSEnumerator *stringEnumerator = [stringNodes objectEnumerator];
			id stringNode;
			while ((stringNode = [stringEnumerator nextObject])) {
				[strings addObject:[stringNode stringValue]];
				[combinedKeywordRegexString appendFormat:@"%@|",[[stringNode stringValue] stringByReplacingRegularExpressionOperators]];
				if (autocomplete) [autocompleteDictionary addObject:[stringNode stringValue]];
			}
			if ([stringNodes count]>0) {
				[combinedKeywordRegexString replaceCharactersInRange:NSMakeRange([combinedKeywordRegexString length]-1, 1) withString:@")"];

				if (I_charsInToken) {
					[combinedKeywordRegexString appendFormat:@"(?![%@])",[I_charsInToken stringByReplacingRegularExpressionOperators]];
				} else if (I_charsDelimitingToken) {
					[combinedKeywordRegexString appendFormat:@"(?=[%@]|$)",[I_charsDelimitingToken stringByReplacingRegularExpressionOperators]];
				}

				BOOL caseInsensitiveKeywordGroup = [[keywordGroupDictionary objectForKey:@"casesensitive"] isEqualToString:@"no"];
				unsigned keywordGroupSettings = OgreFindNotEmptyOption|OgreCaptureGroupOption;
				if (caseInsensitiveKeywordGroup) keywordGroupSettings |= OgreIgnoreCaseOption;

				@try {
					OGRegularExpression *combinedKeywordRegularExpression = [[OGRegularExpression alloc] initWithString:combinedKeywordRegexString options:keywordGroupSettings];
					if (combinedKeywordRegexString) {
						[keywordGroupDictionary setObject:combinedKeywordRegularExpression forKey:@"CompiledKeywords"];
					}
				}
				@catch (NSException *exception) {
					NSLog(@"Creating regex with %@ did throw exception %@", combinedRegexRegexString, exception);
				}
			}
		}
	}

    NSString *useSpellChecking = [[stateNode attributeForName:@"usespellchecking"] stringValue];
	if ([[useSpellChecking lowercaseString] isEqualToString:@"yes"]) {
        [stateDictionary setObject:@"yes" forKey:@"usespellchecking"];
    } else {
        [stateDictionary setObject:@"no" forKey:@"usespellchecking"];
    }

    if ([name isEqualToString:@"default"]) {        
        [stateDictionary setObject:[NSString stringWithFormat:@"/%@/%@", [self name], SyntaxStyleBaseIdentifier] forKey:@"id"];
		[stateDictionary setObject:[NSString stringWithFormat:@"%@.%@", SEEStyleSheetMetaDefaultScopeName, [[self name] lowercaseString]] forKey:@"scope"];
        [stateDictionary setObject:SyntaxStyleBaseIdentifier forKey:kSyntaxHighlightingStyleIDAttributeName];
        [I_defaultState addEntriesFromDictionary:stateDictionary];
    } else {
        if (![aState objectForKey:@"states"]) [aState setObject:[NSMutableArray array] forKey:@"states"];
        [[aState objectForKey:@"states"] addObject:stateDictionary];
    }

    // Set symbols and autocomplete hints

    NSString *symbolsFromMode = [[stateNode attributeForName:@"usesymbolsfrommode"] stringValue];
	if (symbolsFromMode) [stateDictionary setObject:symbolsFromMode forKey:@"switchtosymbolsfrommode"];
	
	NSString *autocompleteFromMode = [[stateNode attributeForName:@"useautocompletefrommode"] stringValue];
	if (autocompleteFromMode) {
		if (symbolsFromMode) [stateDictionary setObject:symbolsFromMode forKey:StateDictionarySwitchToAutocompleteFromModeKey];
		if (![I_allLanguageContextsArray containsObject:autocompleteFromMode]) {
			[I_allLanguageContextsArray addObject:autocompleteFromMode];
			//NSLog(@"%s added %@ -> %@",__FUNCTION__, autocompleteFromMode, I_allLanguageContextsArray);
		}
	}


    // Get all nodes and preserve order
    NSArray *allStateNodes = [stateNode nodesForXPath:@"./state | ./state-link" error:&err];
    for (id nextState in allStateNodes) {
        NSString *nodeName = [nextState name];
        if (![stateDictionary objectForKey:@"states"]) [stateDictionary setObject:[NSMutableArray array] forKey:@"states"];
     
        if ([nodeName isEqualToString:@"state"]) {  //Recursive descent into sub-states
            [self parseState:nextState addToState:stateDictionary];           
        } 
        else if ([nodeName isEqualToString:@"state-link"]) 	// Hard-link state-links
        {
            NSMutableArray *hardlinks = [stateDictionary objectForKey:@"links"];
            if (!hardlinks) {
                hardlinks = [NSMutableArray array];
                [stateDictionary setObject:hardlinks forKey:@"links"];
            }

            NSString *linkMode, *linkState;
            linkMode = [[nextState attributeForName:@"mode"] stringValue];
            if (!linkMode) linkMode = [self name];
            
            linkState = [[nextState attributeForName:@"state"] stringValue];
            
            if (linkState) {
                NSString *linkName = [NSString stringWithFormat:@"/%@/%@", linkMode, linkState];
                [hardlinks addObject:linkName];
                [I_importedModes setObject:@"import" forKey:linkMode];
                [[stateDictionary objectForKey:@"states"] addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:linkName, @"id", @"yes", @"hardlink", [stateDictionary objectForKey:@"id"], @"parentState", nil]];
            }
        }        
    }
	
    // Put the stuff into the dictionary

    [I_allStates setObject:stateDictionary forKey:[stateDictionary objectForKey:@"id"]]; // Used for easy caching and precalculating

}

#pragma mark - Caching and precalculating

- (void)registerScope:(NSString *)aScope {
	if (aScope && ![I_allScopesArray containsObject:aScope]) {
		[I_allScopesArray addObject:aScope];
	}
}

/*"calls addStylesForKeywordGroups: for defaultState and states"*/
-(void)cacheStyles
{
	I_cacheStylesCalculating = YES;
    NSMutableDictionary *state;
    
	NSMutableArray *keywordGroups = [NSMutableArray new];
    NSEnumerator *statesEnumerator = [I_allStates objectEnumerator];
    while ((state = [statesEnumerator nextObject])) {
		[keywordGroups removeAllObjects];
		[keywordGroups addObjectsFromArray:[state objectForKey:@"ImportedKeywordGroups"]];
		[keywordGroups addObjectsFromArray:[state objectForKey:@"KeywordGroups"]];
		// fill the keywords in in reverse order at the import position so the final array has the correct order.
		for (NSDictionary *importDict in [[state objectForKey:@"ImportedKeywordGroups"] reverseObjectEnumerator]) {
			NSUInteger importPosition = [[importDict objectForKey:@"importPosition"] unsignedIntegerValue];
			NSArray *keywordGroupsToImport = [importDict objectForKey:@"keywordGroups"];
			for (id keywordGroup in [keywordGroupsToImport reverseObjectEnumerator]) {
				[keywordGroups insertObject:keywordGroup atIndex:importPosition];
			}
		}

        
		if (keywordGroups.count > 0) {

            NSMutableDictionary *newPlainCaseDictionary = [NSMutableDictionary dictionary];
            NSMutableDictionary *newPlainIncaseDictionary = [NSMutableDictionary caseInsensitiveDictionary];
            NSMutableArray *newPlainArray = [NSMutableArray array];
            NSMutableArray *newRegExArray = [NSMutableArray array];
            [newPlainArray addObject:newPlainCaseDictionary];
            [newPlainArray addObject:newPlainIncaseDictionary];
            [I_stylesForToken setObject:newPlainArray forKey:[state objectForKey:@"id"]];
            [I_stylesForRegex setObject:newRegExArray forKey:[state objectForKey:@"id"]];
        
			int sortedInsertPoint = 0;
            for (NSDictionary *keywordGroup in keywordGroups) {
                NSString *styleID=[keywordGroup objectForKey:kSyntaxHighlightingStyleIDAttributeName];
                if ([keywordGroup objectForKey:@"CompiledRegEx"]) {
					[newRegExArray insertObject:[NSArray arrayWithObjects:[keywordGroup objectForKey:@"CompiledRegEx"], styleID, keywordGroup, nil] atIndex:sortedInsertPoint];
					sortedInsertPoint++;	
				}
				if ([(NSArray*)[keywordGroup objectForKey:@"PlainStrings"] count]>0) [newRegExArray addObject:[NSArray arrayWithObjects:[keywordGroup objectForKey:@"CompiledKeywords"], styleID, keywordGroup, nil]];
            }
        }
    }
    
    DEBUGLOG(@"SyntaxHighlighterDomain", AllLogLevel, @"Finished caching plainstrings:%@",[I_stylesForToken description]);
    DEBUGLOG(@"SyntaxHighlighterDomain", AllLogLevel, @"Finished caching regular expressions:%@",[I_stylesForRegex description]);
	I_cacheStylesReady = YES;
}

- (void) calculateCombinedStateRegexes {
	I_combinedStateRegexCalculating = YES;
    NSEnumerator *statesEnumerator = [I_allStates objectEnumerator];
    id state;
    while ((state = [statesEnumerator nextObject])) {
        [self setCombinedStateRegexForState:state];   
    }
    I_combinedStateRegexReady = YES;
}

#pragma mark - Accessors

- (NSDictionary *)importedModes {
    return I_importedModes;
}

- (void)addState:(NSString *)aStateID toString:(NSMutableString *)aString indentLevel:(NSUInteger)anIndentLevel visitedStates:(NSMutableSet *)aStateSet {
	if (anIndentLevel > 10) return; // safeguard for endless loops
	NSDictionary *state = [self stateForID:aStateID];
	anIndentLevel += 2;
	NSString *indentString = [@"" stringByPaddingToLength:anIndentLevel withString:@" " startingAtIndex:0];
	if (![aStateSet containsObject:state]) {
		[aStateSet addObject:state];
		[aString appendFormat:@"%@+%@ (%@)\n",[indentString substringToIndex:indentString.length-2], [state objectForKey:@"id"], [state objectForKey:@"scope"]];
		for (NSDictionary *keywordGroupDict in [state objectForKey:@"KeywordGroups"]) {
			[aString appendFormat:@"%@-%@ (%@)\n",indentString, [keywordGroupDict objectForKey:@"id"], [keywordGroupDict objectForKey:@"scope"]];
		}
		for (NSDictionary *keywordGroupToImport in [state objectForKey:@"ImportedKeywordGroups"]) {
			NSUInteger importPosition = [[keywordGroupToImport objectForKey:@"importPosition"] unsignedIntegerValue];
			for (NSDictionary *keywordGroupDict in [keywordGroupToImport objectForKey:@"keywordGroups"]) {
				[aString appendFormat:@"%@i-%lu-%@ (%@)\n",indentString, (unsigned long)importPosition, [keywordGroupDict objectForKey:@"id"], [keywordGroupDict objectForKey:@"scope"]];
			}
		}
		for (id substate in [state objectForKey:@"states"]) {
			if ([substate isKindOfClass:[NSDictionary class]]) {
				id substateID = [substate objectForKey:@"id"];
				[self addState:substateID toString:aString indentLevel:anIndentLevel visitedStates:aStateSet];
			} else {
				NSLog(@"substate was string: %@", substate);
			}
		}
	} else {
		[aString appendFormat:@"%@+%@ (%@) (repeated)\n",[indentString substringToIndex:indentString.length-2], [state objectForKey:@"id"], [state objectForKey:@"scope"]];
	}
}

- (NSString *)debugStatesAndKeywordGroups {
	NSMutableString *result = [NSMutableString string];
	[self addState:[I_defaultState objectForKey:@"id"] toString:result indentLevel:0 visitedStates:[NSMutableSet set]];
	return result;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"SyntaxDefinition, Name:%@ , TokenSet:%@, DefaultState: %@, Uses Spelling Dictionary: %@", [self name], [self tokenSet], [I_defaultState description], I_useSpellingDictionary?@"Yes.":@"No."];
}

- (OGRegularExpression *)tokenRegex
{
    return I_tokenRegex;
}

- (NSString *)name
{
	if (I_name) return I_name;
    
	NSString *idenifier = [[self mode] documentModeIdentifier];
    NSRange aRange = [idenifier rangeOfString:@"SEEMode." options:NSLiteralSearch range:NSMakeRange(0, [idenifier length] - 1)];
	NSString *modeName = [idenifier substringWithRange:NSMakeRange(aRange.length, [idenifier length] - aRange.length)];

	if (!I_name) I_name = [modeName copy];
	
    return modeName;
}

- (void)setName:(NSString *)aString
{
    NSRange aRange = [aString rangeOfString:@"SEEMode." options:NSLiteralSearch range:NSMakeRange(0, [aString length] - 1)];
	NSString *modeName = [aString substringWithRange:NSMakeRange(aRange.length, [aString length] - aRange.length)];
	I_name = [modeName copy];
}

- (NSMutableDictionary *)defaultState
{
    return I_defaultState;
}

- (NSCharacterSet *)tokenSet
{
    return I_tokenSet;
}

- (int)foldingTopLevel {
	return I_foldingTopLevel;
}

- (NSString *)autocompleteTokenString {
    return I_autocompleteTokenString;
}

- (NSCharacterSet *)autoCompleteTokenSet
{
    return I_autoCompleteTokenSet;
}

- (NSCharacterSet *)invertedTokenSet
{
    return I_invertedTokenSet;
}

- (void)setAutoCompleteTokenSet:(NSCharacterSet *)aCharacterSet
{
     I_autoCompleteTokenSet = [aCharacterSet copy];
}

- (void)setTokenSet:(NSCharacterSet *)aCharacterSet
{
     I_tokenSet = [aCharacterSet copy];
     I_invertedTokenSet = [[aCharacterSet invertedSet] copy];
}

- (BOOL)state:(NSString *)aState includesState:(NSString *)anotherState {

    NSDictionary *searchState = [self stateForID:aState];
    NSEnumerator *enumerator = [[searchState objectForKey:@"states"] objectEnumerator];
    id object;
    while ((object = [[enumerator nextObject] objectForKey:@"id"])) {
        if ([object isEqualToString:anotherState]) return YES;
    }

    return NO;
}

- (NSString *) keyForInheritedSymbols {
	if ( !I_keyForInheritedSymbols ) I_keyForInheritedSymbols = [[NSString alloc] initWithFormat:@"/%@/useSymbolsFrom", [self name]];
	return I_keyForInheritedSymbols;
}

- (NSString *) keyForInheritedAutocomplete {
	if ( !I_keyForInheritedAutocomplete ) I_keyForInheritedAutocomplete = [[NSString alloc] initWithFormat:@"/%@/useAutocompleteFrom", [self name]];
	return I_keyForInheritedAutocomplete;
}

- (NSString*)getModeNameFromState:(NSString*)aState
{
	NSRange aRange = [aState rangeOfString:@"/" options:NSLiteralSearch range:NSMakeRange(1, [aState length] - 1)];
	NSString *modeName = [aState substringWithRange:NSMakeRange(1, aRange.location - 1)];
	
	return modeName;
}

// Calculate inheritances recursivly
- (void) calculateSymbolInheritanceForState:(NSMutableDictionary *)state inheritedSymbols:(NSString *)oldSymbols inheritedAutocomplete:(NSString *)oldAutocomplete {
	static int counter = 0;
	NSString *symbols = nil;
	NSString *autocomplete = nil;
	
	counter ++;
	if ([state objectForKey:@"switchtosymbolsfrommode"]) {
		symbols = [[state objectForKey:@"switchtosymbolsfrommode"] copy];
	} else {
		symbols = [oldSymbols copy];
	}
	if ([state objectForKey:StateDictionarySwitchToAutocompleteFromModeKey]) {
		autocomplete = [[state objectForKey:StateDictionarySwitchToAutocompleteFromModeKey] copy];
	} else {
		autocomplete = [oldAutocomplete copy];
	}
    

    BOOL isLinked = ([state objectForKey:@"hardlink"]!=nil);
    state = [self stateForID:[state objectForKey:@"id"]];
    BOOL isLocal = [[self getModeNameFromState:[state objectForKey:@"id"]] isEqualToString:[self name]];
    
    if (!(isLocal&&isLinked)) // If it's a local state, then resolve in the non-linked instance.
    {
        if (![state objectForKey:[self keyForInheritedSymbols]]) [state setObject:symbols forKey:[self keyForInheritedSymbols]];
        if (![state objectForKey:[self keyForInheritedAutocomplete]]) [state setObject:autocomplete forKey:[self keyForInheritedAutocomplete]];
        //NSLog(@"%@ calculated %@, Sym:%@, Auto:%@", [self name], [state objectForKey:@"id"], [state objectForKey:[self keyForInheritedSymbols]],[state objectForKey:[self keyForInheritedAutocomplete]]);	
    } 
        
	NSEnumerator *enumerator = [[state objectForKey:@"states"] objectEnumerator];
    id childState;
    while ((childState = [enumerator nextObject])) {
        id realChildState = [self stateForID:[childState objectForKey:@"id"]];
        if (![realChildState objectForKey:@"color"] && isLocal) {
            [realChildState setObject:[state objectForKey:kSyntaxHighlightingStyleIDAttributeName] forKey:kSyntaxHighlightingStyleIDAttributeName]; // Inherit color if n/a
// FIXME handle failure for backwards comp.
			//if(![state objectForKey:@"scope"]) NSLog(@"OIUDOINDAO %@",[state objectForKey:@"id"]);
			//if(![realChildState objectForKey:@"scope"]) NSLog(@"UDIOBOIDN %@",[realChildState objectForKey:@"id"]);
			NSString *currentScope = [state objectForKey:@"scope"];
			NSString *childScope = [realChildState objectForKey:@"scope"];
			if (currentScope && childScope && ![currentScope isEqualToString:childScope]) {
				[self.scopeStyleDictionary setObject:[NSDictionary dictionaryWithObject:currentScope forKey:@"inherit"] forKey:childScope];
			}
        }
		if (counter > 100) { 
			NSLog(@"%s counter %d", __FUNCTION__, counter);
		}
		if (![childState objectForKey:[self keyForInheritedSymbols]]) {
			if ([[state objectForKey:@"id"] isEqual:[realChildState objectForKey:@"id"]]) {
				// don't recurse into one self
				//				NSLog(@"%s self recursion for %@ isLinked %@", __FUNCTION__, [state objectForKey:@"id"], isLinked ? @"YES": @"NO");
			} else {
				[self calculateSymbolInheritanceForState:childState inheritedSymbols:symbols inheritedAutocomplete:autocomplete];
			}
		}
    }
	counter--;
}

- (void)getReady {
	@synchronized(self) {
//		BOOL wasntReady = NO;
		if (!I_combinedStateRegexReady && !I_combinedStateRegexCalculating) {
			[self calculateCombinedStateRegexes];
//			wasntReady = YES;
		}
		if (!I_cacheStylesReady && !I_cacheStylesCalculating) {
			//Moved addStyles in here, which should speed up type-and-color performance significantly.
			[self addStyleIDsFromState:[self defaultState]];
			[self cacheStyles];
//			wasntReady = YES;
		}
		if (!I_symbolAndAutocompleteInheritanceReady) {
			[self calculateSymbolInheritanceForState:[I_allStates objectForKey:[NSString stringWithFormat:@"/%@/%@", [self name], SyntaxStyleBaseIdentifier]] inheritedSymbols:[self name] inheritedAutocomplete:[self name]];
			I_symbolAndAutocompleteInheritanceReady = YES;
			//		NSLog(@"Defaultstate: Sym:%@, Auto:%@", [[self defaultState] objectForKey:[self keyForInheritedSymbols]],[[self defaultState] objectForKey:[self keyForInheritedAutocomplete]]);
//			wasntReady = YES;
		}
//		NSArray *allScopes = [self.scopeStyleDictionary.allKeys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
//		NSLog(@"%s all scopes?: \n%@",__FUNCTION__, allScopes);
			//NSLog(@"foo: %@", [I_defaultSyntaxStyle allKeys]);
//		NSMutableArray *reducedScopes = [NSMutableArray array];
//		[allScopes enumerateObjectsUsingBlock:^(id object, NSUInteger idx, BOOL *stop) { [reducedScopes addObject:[object stringByDeletingPathExtension]];}];
//		NSLog(@"all scopes user visible: %@", reducedScopes);


		//if (wasntReady) NSLog(@"%s\n%@",__FUNCTION__, [self debugStatesAndKeywordGroups]); // For Debugging purposes
	}
}

- (NSArray *)allScopes {
	if (!I_combinedStateRegexReady) [self getReady];
	return I_allScopesArray;
}

- (NSString *)mainLanguageContext {
	if (!I_combinedStateRegexReady) [self getReady];
	NSString *result = [I_defaultState objectForKey:StateDictionaryUseAutocompleteFromModeKey]; // use the language scope from the default state (so that the outermost state is the main language context, not the mode name. Important for modes like PHP-HTML
	if (!result) result = [I_mode scriptedName]; // fallback to mode name if no language scope is given
//	NSLog(@"%s %@ %@",__FUNCTION__, result, I_defaultState);
	return result;
}

- (NSArray *)allLanguageContexts {
	if (!I_combinedStateRegexReady) [self getReady];
	return I_allLanguageContextsArray;
}


- (NSMutableDictionary *)stateForID:(NSString *)aString {
    if (!I_combinedStateRegexReady && !I_combinedStateRegexCalculating) [self getReady];
	NSString *modeName = [self getModeNameFromState:aString];
	
	if (![modeName isEqualToString:[self name]]) {
		return [[[[DocumentModeManager sharedInstance] documentModeForName:modeName] syntaxDefinition] stateForID:aString];
	} 
	
    if ([aString isEqualToString:SyntaxStyleBaseIdentifier]) return [self defaultState];
    return [I_allStates objectForKey:aString];
}

- (int)levelForStyleID:(NSString *)aStyleID currentLevel:(int)aLevel maxLevel:(int)aMaxLevel inState:(NSDictionary *)aState {
    if (aMaxLevel == aLevel) return aLevel;
    aState = [self stateForID:[aState objectForKey:@"id"]];
    if ([[aState objectForKey:kSyntaxHighlightingStyleIDAttributeName] isEqualToString:aStyleID]) return aLevel;
    for (NSDictionary *keywordGroup in [aState objectForKey:@"KeywordGroups"]) {
        if ([[keywordGroup objectForKey:kSyntaxHighlightingStyleIDAttributeName] isEqualToString:aStyleID]) {
            return aLevel;
        }
    }
	for (NSDictionary *keywordGroupToImport in [aState objectForKey:@"ImportedKeywordGroups"]) {
		for (NSDictionary *keywordGroup in [keywordGroupToImport objectForKey:@"keywordGroups"]) {
			if ([[keywordGroup objectForKey:kSyntaxHighlightingStyleIDAttributeName] isEqualToString:aStyleID]) {
				return aLevel;
			}
		}
	}
    NSEnumerator *subStates = [[aState objectForKey:@"states"] objectEnumerator];
    NSDictionary *subState = nil;
    if (!subStates) return aLevel;
    while ((subState=[subStates nextObject])) {
        if ([[subState objectForKey:kSyntaxHighlightingStyleIDAttributeName] isEqualToString:aStyleID]) return aLevel;
    }

    int result = aMaxLevel;
    subStates = [[aState objectForKey:@"states"] objectEnumerator];
    subState = nil;
    while ((subState=[subStates nextObject])) {
        result = MIN(result,[self levelForStyleID:aStyleID currentLevel:aLevel+1 maxLevel:aMaxLevel inState:subState]);
    }    
    
    return result;
}

- (int)levelForStyleID:(NSString *)aStyleID {
    NSNumber *level = [I_levelsForStyleIDs objectForKey:aStyleID];
    if (!level) {
        int intLevel = [self levelForStyleID:aStyleID currentLevel:0 maxLevel:5 inState:I_defaultState];
        level = [NSNumber numberWithInt:intLevel];
        [I_levelsForStyleIDs setObject:level forKey:aStyleID];
    }
    return [level intValue];
}

- (NSString *)styleForToken:(NSString *)aToken inState:(NSString *)aState 
{
//	NSLog(@"%s:%d: %@",__PRETTY_FUNCTION__,__LINE__, aState);
	NSString *modeName = [self getModeNameFromState:aState];
	
	if (![modeName isEqualToString:[self name]]) {
		return [[[[DocumentModeManager sharedInstance] documentModeForName:modeName] syntaxDefinition] styleForToken:aToken inState:aState];
	} 

    NSString *styleID;
    
    if ((styleID = [[[I_stylesForToken objectForKey:aState] objectAtIndex:0] objectForKey:aToken])) {
        return styleID;
    }
    if ((styleID = [[[I_stylesForToken objectForKey:aState] objectAtIndex:1] objectForKey:aToken])){
        return styleID;
    }
    
    return nil;
}

- (BOOL) hasTokensForState:(NSString *)aState {
//	NSLog(@"%s:%d: %@",__PRETTY_FUNCTION__,__LINE__, aState);
	NSString *modeName = [self getModeNameFromState:aState];
	
	if (![modeName isEqualToString:[self name]]) {
		return [[[[DocumentModeManager sharedInstance] documentModeForName:modeName] syntaxDefinition] hasTokensForState:aState];
	} 
	
    return (([(NSArray*)[[I_stylesForToken objectForKey:aState] objectAtIndex:0] count]>0)||([(NSArray*)[[I_stylesForToken objectForKey:aState] objectAtIndex:1] count]>0));
}

- (NSArray *)regularExpressionsInState:(NSString *)aState
{
//	NSLog(@"%s:%d: %@",__PRETTY_FUNCTION__,__LINE__, aState);
	NSString *modeName = [self getModeNameFromState:aState];
	
	if (![modeName isEqualToString:[self name]]) {
		return [[[[DocumentModeManager sharedInstance] documentModeForName:modeName] syntaxDefinition] regularExpressionsInState:aState];
	} 

    NSArray *aRegexArray;
    if ((aRegexArray = [I_stylesForRegex objectForKey:aState])) return aRegexArray;
    else return nil;
}

- (void)addStyleIDsFromState:(NSDictionary *)aState {
	aState = [self stateForID:[aState objectForKey:@"id"]]; // Refetch state to be sure to get the orignal and not a weak-link zombie
	if (![aState objectForKey:kSyntaxHighlightingStyleIDAttributeName]) return;

	NSArray *styleKeyArray = [NSArray arrayWithObjects:@"color",@"inverted-color",@"background-color",@"inverted-background-color",@"font-trait",nil];
	NSMutableDictionary *stateStyles;
	
	if ([aState objectForKey:@"scope"]) {
		stateStyles = [NSMutableDictionary dictionary];
		for (NSString *styleKey in styleKeyArray) {
			if ([aState objectForKey:styleKey]) [stateStyles setObject:[aState objectForKey:styleKey] forKey:styleKey];
		}
		[self.scopeStyleDictionary setObject:stateStyles forKey:[aState objectForKey:@"scope"]];
	}
	
	[I_defaultSyntaxStyle takeValuesFromDictionary:aState];
	NSMutableArray *keywordGroups = [NSMutableArray new];
	[keywordGroups addObjectsFromArray:[aState objectForKey:@"KeywordGroups"]];
	for (NSDictionary *keywordGroupToImport in [aState objectForKey:@"ImportedKeywordGroups"]) {
		for (NSDictionary *keywordGroup in [keywordGroupToImport objectForKey:@"keywordGroups"]) {
			[keywordGroups addObject:keywordGroup];
		}
	}
    for (NSDictionary *keywordGroup in keywordGroups) {
		
		if ([keywordGroup objectForKey:@"scope"]) {
			stateStyles = [NSMutableDictionary dictionary];
			for (NSString *styleKey in styleKeyArray) {
				if ([keywordGroup objectForKey:styleKey]) {
					[stateStyles setObject:[keywordGroup objectForKey:styleKey] forKey:styleKey];
				}
			}
			[self.scopeStyleDictionary setObject:stateStyles forKey:[keywordGroup objectForKey:@"scope"]];
		} else {
			NSLog(@"DEBUG: Missing scope for %@", [keywordGroup objectForKey:@"id"]);
		}
		
        [I_defaultSyntaxStyle takeValuesFromDictionary:keywordGroup];
    }
    
    NSEnumerator *subStates = [[aState objectForKey:@"states"] objectEnumerator];
    id subState;
    while ((subState = [subStates nextObject])) {
        if (([aState objectForKey:@"color"] &&
			 ![I_defaultSyntaxStyle styleForKey:[subState objectForKey:kSyntaxHighlightingStyleIDAttributeName]]) &&
			(![[aState objectForKey:@"id"] isEqualToString:[subState objectForKey:@"id"]])) {
			[self addStyleIDsFromState:[self stateForID:[subState objectForKey:@"id"]]];
		}
    }
    
}

- (void)setCombinedStateRegexForState:(NSMutableDictionary *)aState
{ 
	if ([aState objectForKey:@"imports"]) {
		for (NSDictionary *import in [aState objectForKey:@"imports"]) {
			NSString *importName = [import objectForKey:@"importName"];
			NSXMLElement *importNode = [import objectForKey:@"importNode"];
			BOOL keywordsOnly = [[[importNode attributeForName:@"keywords-only"] stringValue] isEqualToString:@"yes"];
			NSString *modeName = [self getModeNameFromState:importName]; 
			
			SyntaxDefinition *linkedDefinition = [[[DocumentModeManager sharedInstance] documentModeForName:modeName] syntaxDefinition]; 
			NSDictionary *linkedState = [linkedDefinition stateForID:importName];

			if (linkedState) {
				if (!keywordsOnly) {
					if (![aState objectForKey:@"states"]) [aState setObject:[NSMutableArray array] forKey:@"states"];
					[[aState objectForKey:@"states"] addObjectsFromArray:[linkedState objectForKey:@"states"]];
				}
				// import does not import imported keyword groups. so we need to collect them in a different array otherwise some keywords cascade in importing, others don't depending on the kind of mode we are in.
				if (![aState objectForKey:@"ImportedKeywordGroups"]) [aState setObject:[NSMutableArray array] forKey:@"ImportedKeywordGroups"];
				[[aState objectForKey:@"ImportedKeywordGroups"] addObject:[NSDictionary dictionaryWithObjectsAndKeys:[linkedState objectForKey:@"KeywordGroups"],@"keywordGroups", [import objectForKey:@"importPosition"], @"importPosition",nil]];			
			}
		}
	} 

    NSMutableString *combinedString = [NSMutableString string];
    NSEnumerator *statesEnumerator = [[aState objectForKey:@"states"] objectEnumerator];
    NSMutableDictionary *aDictionary;
    int i = -1;
    NSString *endString = [aState objectForKey:@"EndsWithRegexString"];
    if (!endString) endString = [aState objectForKey:@"EndsWithPlainString"];
	
	while ((aDictionary = [statesEnumerator nextObject])) {
        i++;
        NSString *beginString;
		if ([aDictionary objectForKey:@"hardlink"]) {
            NSString *linkedName = [aDictionary objectForKey:@"id"];

			NSString *modeName = [self getModeNameFromState:linkedName]; 
            SyntaxDefinition *linkedDefinition = [[[DocumentModeManager sharedInstance] documentModeForName:modeName] syntaxDefinition];
            NSDictionary *linkedState = [linkedDefinition stateForID:linkedName];
			
            if (linkedState) {
				if ([linkedState objectForKey:@"AutoendReplacementString"])
					[aDictionary setObject:[linkedState objectForKey:@"AutoendReplacementString"] forKey:@"AutoendReplacementString"];
				if ([linkedState objectForKey:@"BeginsWithRegexString"])
					[aDictionary setObject:[linkedState objectForKey:@"BeginsWithRegexString"] forKey:@"BeginsWithRegexString"];
				if ([linkedState objectForKey:@"BeginsWithPlainString"])
					[aDictionary setObject:[linkedState objectForKey:@"BeginsWithPlainString"] forKey:@"BeginsWithPlainString"];
				if ([linkedState objectForKey:@"EndsWithRegexString"])
					[aDictionary setObject:[linkedState objectForKey:@"EndsWithRegexString"] forKey:@"EndsWithRegexString"];
				if ([linkedState objectForKey:@"EndsWithPlainString"])
					[aDictionary setObject:[linkedState objectForKey:@"EndsWithPlainString"] forKey:@"EndsWithPlainString"];
				if ([linkedState objectForKey:kSyntaxHighlightingStyleIDAttributeName])
					[aDictionary setObject:[linkedState objectForKey:kSyntaxHighlightingStyleIDAttributeName] forKey:kSyntaxHighlightingStyleIDAttributeName];
				if ([linkedState objectForKey:@"type"])
					[aDictionary setObject:[linkedState objectForKey:@"type"] forKey:@"type"];
				if ([linkedState objectForKey:@"scope"])
					[aDictionary setObject:[linkedState objectForKey:@"scope"] forKey:@"scope"];
                if ([linkedState objectForKey:@"containerState"])
					[aDictionary setObject:[linkedState objectForKey:@"containerState"] forKey:@"containerState"];
            }
		}
		
        if ((beginString = [aDictionary objectForKey:@"BeginsWithRegexString"])) {
            DEBUGLOG(@"SyntaxHighlighterDomain", AllLogLevel, @"Found regex string state start:%@",beginString);
            // Warn if begin contains unnamed group
            OGRegularExpression *testForGroups = [[OGRegularExpression alloc] initWithString:beginString options:OgreFindNotEmptyOption|OgreCaptureGroupOption];

            if ([testForGroups numberOfGroups]>[testForGroups numberOfNames]) {
                [self showWarning:NSLocalizedString(@"XML Group Error",@"XML Group Error Title") withDescription:[NSString stringWithFormat:NSLocalizedString(@"The <begin> tag of <state> \"%@\" contains a regex that has captured groups. This is currently not allowed. Please escape all groups to be not-captured with (?:).",@"Syntax XML Group Error Informative Text"),[aDictionary objectForKey:@"id"]]];
            }
          
        } else if ((beginString = [aDictionary objectForKey:@"BeginsWithPlainString"])) {
            DEBUGLOG(@"SyntaxHighlighterDomain", AllLogLevel, @"Found plain string state start:%@",beginString);
        } else if ([aDictionary objectForKey:@"containerState"]) {
            DEBUGLOG(@"SyntaxHighlighterDomain", AllLogLevel, @"Found a container state");
        } else {
			[self showWarning:NSLocalizedString(@"XML Structure Error",@"XML Structure Error Title") withDescription:[NSString stringWithFormat:NSLocalizedString(@"<state> \"%@\" has no <begin>. This confuses me. Please check your syntax definition.",@"Syntax XML Structure Error Informative Text"),[aDictionary objectForKey:@"id"]]];
        }
        if (beginString) {
            [combinedString appendString:[NSString stringWithFormat:@"(?<seeinternalgroup%d>%@)|",i,beginString]];
        }
    }


    NSUInteger combinedStringLength = [combinedString length];
    if ((combinedStringLength>1)||(endString)) {
        if (endString) { // Any states except the default
            [combinedString appendString:[NSString stringWithFormat:@"(?<seeinternalgroup4242>%@)",endString]];
        } else {
            [combinedString deleteCharactersInRange:NSMakeRange(combinedStringLength-1,1)];      
        }

        if ([OGRegularExpression isValidExpressionString:combinedString]) {
			if ((endString)&&([endString rangeOfString:@"(?#see-insert-start-group"].location!=NSNotFound)) {
				[aState setObject:combinedString forKey:@"Combined Delimiter String"];
					
				NSMutableArray *captureGroups = [NSMutableArray array];
				OGRegularExpression *filterGroupsRegex = [[OGRegularExpression alloc] initWithString:@"(?<=\\(\\?#see-insert-start-group:)[^\\)]+" options:OgreFindNotEmptyOption|OgreCaptureGroupOption];
				NSEnumerator *matchEnumerator = [[filterGroupsRegex allMatchesInString:endString] objectEnumerator];
				OGRegularExpressionMatch *aMatch;
				while ((aMatch = [matchEnumerator nextObject])) {
					[captureGroups addObject:[aMatch matchedString]];
				}
				
				[aState setObject:captureGroups forKey:@"Combined Delimiter String End Capture Groups"];
			} else {
				OGRegularExpression *combindedRegex = [[OGRegularExpression alloc] initWithString:combinedString options:OgreFindNotEmptyOption|OgreCaptureGroupOption];
				[aState setObject:combindedRegex forKey:@"Combined Delimiter Regex"];
			}
		} else {
			[self showWarning:NSLocalizedString(@"Regular Expression Error",@"Regular Expression Error Title") withDescription:[NSString stringWithFormat:NSLocalizedString(@"One of the specified state <begin>'s is not a valid regular expression. Therefore the Combined Delimiter Regex \"%@\" could not be compiled. Please check your regular expression in Find Panel's Ruby mode.",@"Syntax Regular Expression Error Informative Text"),combinedString]];
        }
    }
	// We might have new styles that got imported, so run caching again!
	I_cacheStylesReady = NO;
	I_cacheStylesCalculating = NO;
}

- (DocumentMode *)mode
{
    return I_mode;
}

- (void)setMode:(DocumentMode *)aMode {
    I_mode = aMode;
}

- (SyntaxStyle *)defaultSyntaxStyle {
    return I_defaultSyntaxStyle;
}

- (BOOL)useSpellingDictionary {
    return I_useSpellingDictionary;
}


@end
