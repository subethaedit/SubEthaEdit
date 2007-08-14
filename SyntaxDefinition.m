//
//  SyntaxDefinition.m
//  SyntaxTestBench
//
//  Created by Martin Pittenauer on Wed Mar 17 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "DocumentModeManager.h"
#import "SyntaxDefinition.h"
#import "NSColorTCMAdditions.h"
#import "TCMFoundation.h"


@implementation SyntaxDefinition
/*"A Syntax Definition"*/

#pragma mark - 
#pragma mark - Initizialisation
#pragma mark - 


/*"Initiates the Syntax Definition with an XML file"*/
- (id)initWithFile:(NSString *)aPath forMode:(DocumentMode *)aMode {
    self=[super init];
    if (self) {
        if (!aPath) {
            [self dealloc];
            return nil;
        }
        // Alloc & Init
        I_defaultState = [NSMutableDictionary new];
        I_importedModes = [NSMutableDictionary new];
        I_useSpellingDictionary = NO;
        I_allStates = [NSMutableDictionary new];
        I_name = [@"Not named" retain];
        [self setMode:aMode];
        everythingOkay = YES;
        
        I_defaultSyntaxStyle = [SyntaxStyle new]; 
        [I_defaultSyntaxStyle setDocumentMode:aMode];               
        // Parse XML File
        [self parseXMLFile:aPath];
        
        // Setup stuff <-> style dictionaries
        I_stylesForToken = [NSMutableDictionary new];
        I_stylesForRegex = [NSMutableDictionary new];
        I_combinedStateRegexReady = NO;
		I_combinedStateRegexCalculating = NO;
        I_cacheStylesReady = NO;
		I_cacheStylesCalculating = NO;
    }
    
//    NSLog([self description]);
    
    if (everythingOkay) return self;
    else {
        NSLog(@"Critical errors while loading syntax definition. Not loading syntax highlighter.");
        [self dealloc];
        return nil;
    }
}

- (void)dealloc {
    [I_name release];
    [I_allStates release];
    [I_defaultState release];
    [I_importedModes release];
    [I_stylesForToken release];
    [I_stylesForRegex release];
    [super dealloc];
}

#pragma mark - 
#pragma mark - XML parsing
#pragma mark - 

/*"Entry point for XML parsing, branches to according node functions"*/
-(void)parseXMLFile:(NSString *)aPath {

    NSError *err=nil;
    NSXMLDocument *syntaxDefinitionXML = [[NSXMLDocument alloc] initWithContentsOfURL:[NSURL fileURLWithPath:aPath] options:nil error:&err];

    if (err) {
        #warning Error should be presented
        NSLog(@"Error while loading '%@': %@", aPath, [err localizedDescription]);
        everythingOkay = NO;
        return;
    } 

    //Parse Headers
    
    [self setName:[[[syntaxDefinitionXML nodesForXPath:@"/syntax/head/name" error:&err] lastObject] stringValue]];

    NSString *charsInToken = [[[syntaxDefinitionXML nodesForXPath:@"/syntax/head/charsintokens" error:&err] lastObject] stringValue];
    NSString *charsDelimitingToken = [[[syntaxDefinitionXML nodesForXPath:@"/syntax/head/charsdelimitingtokens" error:&err] lastObject] stringValue];
    NSCharacterSet *tokenSet;
    
    if (charsInToken) {
        tokenSet = [NSCharacterSet characterSetWithCharactersInString:charsInToken];
    } else if (charsDelimitingToken) {
        tokenSet = [NSCharacterSet characterSetWithCharactersInString:charsDelimitingToken];
        tokenSet = [tokenSet invertedSet];
    }
    
    [self setTokenSet:tokenSet];

    NSString *charsInCompletion = [[[syntaxDefinitionXML nodesForXPath:@"/syntax/head/charsincompletion" error:&err] lastObject] stringValue];

    if (charsInCompletion) {
        [self setAutoCompleteTokenSet:[NSCharacterSet characterSetWithCharactersInString:charsInCompletion]];
    }

    I_useSpellingDictionary = [[[[syntaxDefinitionXML nodesForXPath:@"/syntax/head/autocompleteoptions/@use-spelling-dictionary" error:&err] lastObject] stringValue] isEqualTo:@"yes"];    

    
    // Parse states
    NSXMLElement *defaultStateNode = [[syntaxDefinitionXML nodesForXPath:@"/syntax/states/default" error:&err] lastObject];
    [self parseState:defaultStateNode addToState:I_defaultState];
    
    // For old-style, non-recursive modes
    NSArray *oldStyleStates = [syntaxDefinitionXML nodesForXPath:@"/syntax/states/state" error:&err];
    if ([oldStyleStates count]>0) {
        NSEnumerator *oldStyleStatesEnumerator = [oldStyleStates objectEnumerator];
        NSXMLElement *oldStyleState;
        while ((oldStyleState = [oldStyleStatesEnumerator nextObject])) {
            [self parseState:oldStyleState addToState:I_defaultState];
        }
        [I_allStates setObject:I_defaultState forKey:[I_defaultState objectForKey:@"id"]]; // Reread default mode
    }

    [syntaxDefinitionXML release];
}

- (void)addAttributes:(NSArray *)attributes toDictionary:(NSMutableDictionary *)aDictionary {
    NSEnumerator *attributeEnumerator = [attributes objectEnumerator];
    NSXMLNode *attribute;
    while ((attribute = [attributeEnumerator nextObject])) {
        NSString *attributeName = [attribute name];
        id attributeValue = [attribute stringValue];
        
        // Parse colors
        if ([attributeName isEqualToString:@"color"]||[attributeName isEqualToString:@"inverted-color"]||[attributeName isEqualToString:@"background-color"]||[attributeName isEqualToString:@"inverted-background-color"]) {
            NSColor *aColor = [NSColor colorForHTMLString:attributeValue];
            if (aColor) attributeValue = aColor;
            else {
                [aDictionary removeObjectForKey:attributeValue];
                continue;
                #warning Handle Color error.
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
        [aDictionary setObject:invertedColor forKey:@"inverted-color"];
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
    
    NSString *stateID = [NSString stringWithFormat:@"/%@/%@", [self name], [aDictionary objectForKey:@"id"]];
    if (stateID) {
        [aDictionary setObject:stateID forKey:@"id"];
        [aDictionary setObject:stateID forKey:@"styleID"];
    }
}

- (void)parseState:(NSXMLElement *)stateNode addToState:(NSMutableDictionary *)aState {
    NSError *err;
    NSString *name = [stateNode name];
    NSMutableDictionary *stateDictionary = [NSMutableDictionary dictionary];
    
    [self addAttributes:[stateNode attributes] toDictionary:stateDictionary];

    // Parse and prepare begin/end
    NSString *regexBegin = [[[stateNode nodesForXPath:@"./begin/regex" error:&err] lastObject] stringValue];
    NSString *stringBegin = [[[stateNode nodesForXPath:@"./begin/string" error:&err] lastObject] stringValue];
    NSString *regexEnd = [[[stateNode nodesForXPath:@"./end/regex" error:&err] lastObject] stringValue];
    NSString *stringEnd = [[[stateNode nodesForXPath:@"./end/string" error:&err] lastObject] stringValue];

    if (regexBegin) {
        // Begins get compiled later en-block, so just store a string now.
        [stateDictionary setObject:regexBegin forKey:@"BeginsWithRegexString"];
    } else if (stringBegin) {
        [stateDictionary setObject:stringBegin forKey:@"BeginsWithPlainString"];
    } else {
        #warning Handle Error: No Begin.
    }

    if (regexEnd) {
        OGRegularExpression *endRegex;
        if ([OGRegularExpression isValidExpressionString:regexEnd]) {
            if ((endRegex = [[[OGRegularExpression alloc] initWithString:regexEnd options:OgreFindLongestOption|OgreFindNotEmptyOption] autorelease]))
                [stateDictionary setObject:endRegex forKey:@"EndsWithRegex"];
                [stateDictionary setObject:regexEnd forKey:@"EndsWithRegexString"];
        } else {
            NSLog(@"Not a regex end");
            #warning Handle Not a Regex Error.
        }
    } else if (stringEnd) {
        [stateDictionary setObject:stringEnd forKey:@"EndsWithPlainString"];
    } else {
        #warning Handle Error: No End.
    }

    // Add keywords
    NSMutableArray *keywordGroups = [NSMutableArray array];
    [stateDictionary setObject:keywordGroups forKey:@"KeywordGroups"];
    
    NSArray *keywordGroupsNodes = [stateNode nodesForXPath:@"./keywords" error:&err];
    
    NSEnumerator *keywordGroupEnumerator = [keywordGroupsNodes objectEnumerator];
    id keywordGroupNode;
    while ((keywordGroupNode = [keywordGroupEnumerator nextObject])) {
        NSMutableDictionary *keywordGroupDictionary = [NSMutableDictionary dictionary];
        [self addAttributes:[keywordGroupNode attributes] toDictionary:keywordGroupDictionary];
        NSString *keywordGroupName = [keywordGroupDictionary objectForKey:@"id"];
        if (keywordGroupName) [keywordGroups addObject:keywordGroupDictionary];
        [I_defaultSyntaxStyle takeValuesFromDictionary:keywordGroupDictionary];
        
        // Add regexes for keyword group
        NSMutableArray *regexes = [NSMutableArray array];
        NSMutableArray *strings = [NSMutableArray array];
        [keywordGroupDictionary setObject:regexes forKey:@"RegularExpressions"];
        [keywordGroupDictionary setObject:strings forKey:@"PlainStrings"];
        
        NSArray *regexNodes = [keywordGroupNode nodesForXPath:@"./regex" error:&err];
        NSEnumerator *regexEnumerator = [regexNodes objectEnumerator];
        id regexNode;
        while ((regexNode = [regexEnumerator nextObject])) {
            [regexes addObject:[regexNode stringValue]];
        }
                
        // Add strings for keyword group
        BOOL autocomplete = [[keywordGroupDictionary objectForKey:@"useforautocomplete"] isEqualToString:@"yes"];
        NSMutableArray *autocompleteDictionary = [[self mode] autocompleteDictionary];
        NSArray *stringNodes = [keywordGroupNode nodesForXPath:@"./string" error:&err];
        NSEnumerator *stringEnumerator = [stringNodes objectEnumerator];
        id stringNode;
        while ((stringNode = [stringEnumerator nextObject])) {
            [strings addObject:[stringNode stringValue]];
            if (autocomplete) [autocompleteDictionary addObject:[stringNode stringValue]];
        }
        
    }

    //Recursive descent into sub-states
    
    NSArray *subStates = [stateNode nodesForXPath:@"./state" error:&err];
    if ([subStates count]>0) {
        [stateDictionary setObject:[NSMutableArray array] forKey:@"states"];
        NSEnumerator *subStateEnumerator = [subStates objectEnumerator];
        id subState;
        while ((subState = [subStateEnumerator nextObject])) {
            [self parseState:subState addToState:stateDictionary];           
        }
    }
    
    if ([name isEqualToString:@"default"]) {        
        [stateDictionary setObject:[NSString stringWithFormat:@"/%@/%@", [self name], SyntaxStyleBaseIdentifier] forKey:@"id"];
        [stateDictionary setObject:SyntaxStyleBaseIdentifier forKey:@"styleID"];
        [I_defaultState addEntriesFromDictionary:stateDictionary];
    } else {
        if (![aState objectForKey:@"states"]) [aState setObject:[NSMutableArray array] forKey:@"states"];
        [[aState objectForKey:@"states"] addObject:stateDictionary];
    }
	
	//Weak-link to imported states, for later copying
    
    NSArray *importedStates = [stateNode nodesForXPath:@"./import" error:&err];
    if ([importedStates count]>0) {
        if (![stateDictionary objectForKey:@"states"]) [stateDictionary setObject:[NSMutableArray array] forKey:@"states"];

        NSMutableArray *weaklinks = [NSMutableArray array];
        [stateDictionary setObject:weaklinks forKey:@"imports"];
        NSEnumerator *importedStateEnumerator = [importedStates objectEnumerator];
        NSXMLElement *import;
        while ((import = [importedStateEnumerator nextObject])) {
            NSString *importMode, *importState;
            importMode = [[import attributeForName:@"mode"] stringValue];
			if (!importMode) importMode = [self name];
				
			importState = [[import attributeForName:@"state"] stringValue];
			if (!importState) importState = SyntaxStyleBaseIdentifier;
			
			BOOL keywordsOnly = NO;
			NSXMLNode *keywordsOnlyAttribute = [import attributeForName:@"keywords-only"];
			if ([[keywordsOnlyAttribute stringValue] isEqualToString:@"yes"]) keywordsOnly = YES;
			
			NSString *importName = [NSString stringWithFormat:@"/%@/%@", importMode, importState];
			
			if (keywordsOnly) importName = [NSString stringWithFormat:@"%@/%@", importName, @"keywords-only"];
				
			[I_importedModes setObject:@"import" forKey:importMode];
			[weaklinks addObject:importName];
        }
    }

	// Hard-link state-links
    NSArray *linkedStates = [stateNode nodesForXPath:@"./state-link" error:&err];
    if ([linkedStates count]>0) {
        if (![stateDictionary objectForKey:@"states"]) [stateDictionary setObject:[NSMutableArray array] forKey:@"states"];
        NSMutableArray *hardlinks = [NSMutableArray array];
        [stateDictionary setObject:hardlinks forKey:@"links"];
        NSEnumerator *linkedStateEnumerator = [linkedStates objectEnumerator];
        NSXMLElement *link;

        while ((link = [linkedStateEnumerator nextObject])) {
            NSString *linkMode, *linkState;
            linkMode = [[link attributeForName:@"mode"] stringValue];
			if (!linkMode) linkMode = [self name];
			
			linkState = [[link attributeForName:@"state"] stringValue];
			
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

    [I_defaultSyntaxStyle takeValuesFromDictionary:stateDictionary];    
}

#pragma mark - 
#pragma mark - Caching and precalculating
#pragma mark - 

/*"calls addStylesForKeywordGroups: for defaultState and states"*/
-(void)cacheStyles
{
	I_cacheStylesCalculating = YES;
    NSMutableDictionary *state;
    NSMutableDictionary *keywordGroups;
    
    NSEnumerator *statesEnumerator = [I_allStates objectEnumerator];
    while ((state = [statesEnumerator nextObject])) {
        if ((keywordGroups = [state objectForKey:@"KeywordGroups"])) {

            NSEnumerator *groupEnumerator = [keywordGroups objectEnumerator];
            NSDictionary *keywordGroup;
            
            NSMutableDictionary *newPlainCaseDictionary = [NSMutableDictionary dictionary];
            NSMutableDictionary *newPlainIncaseDictionary = [NSMutableDictionary caseInsensitiveDictionary];
            NSMutableArray *newPlainArray = [NSMutableArray array];
            NSMutableArray *newRegExArray = [NSMutableArray array];
            [newPlainArray addObject:newPlainCaseDictionary];
            [newPlainArray addObject:newPlainIncaseDictionary];
            [I_stylesForToken setObject:newPlainArray forKey:[state objectForKey:@"id"]];
            [I_stylesForRegex setObject:newRegExArray forKey:[state objectForKey:@"id"]];
        
            while ((keywordGroup = [groupEnumerator nextObject])) {
                NSString *styleID=[keywordGroup objectForKey:@"styleID"];
                
                // First do the plainstring stuff
                
                NSDictionary *keywords;
                if ((keywords = [keywordGroup objectForKey:@"PlainStrings"])) {
                    NSEnumerator *keywordEnumerator = [keywords objectEnumerator];
                    NSString *keyword;
                    while ((keyword = [keywordEnumerator nextObject])) {
                        if([[keywordGroup objectForKey:@"casesensitive"] isEqualToString:@"no"]) {
                            [newPlainIncaseDictionary setObject:styleID forKey:keyword];
                        } else {
                            [newPlainCaseDictionary setObject:styleID forKey:keyword];                
                        }
                    }
                }
                // Then do the regex stuff
                
                if ((keywords = [keywordGroup objectForKey:@"RegularExpressions"])) {
                    NSEnumerator *keywordEnumerator = [keywords objectEnumerator];
                    NSString *keyword;
                    NSString *aString;
                    while ((keyword = [keywordEnumerator nextObject])) {
                        OGRegularExpression *regex;
                        unsigned regexOptions = OgreFindLongestOption|OgreFindNotEmptyOption;
                        //unsigned regexOptions = OgreFindNotEmptyOption;
                        if ((aString = [keywordGroup objectForKey:@"casesensitive"])) {       
                            if (([aString isEqualTo:@"no"])) {
                                regexOptions = regexOptions|OgreIgnoreCaseOption;
                            }
                        }
                        if ([OGRegularExpression isValidExpressionString:keyword]) {
                            if ((regex = [[[OGRegularExpression alloc] initWithString:keyword options:regexOptions] autorelease])) {
                                [newRegExArray addObject:[NSArray arrayWithObjects:regex, styleID, nil]];
                            }
                        } else {
                            NSLog(@"ERROR: %@ in \"%@\" is not a valid regular expression", keyword, [keywordGroup objectForKey:@"id"]);
                            NSAlert *alert = [[[NSAlert alloc] init] autorelease];
                            [alert setAlertStyle:NSWarningAlertStyle];
                            [alert setMessageText:NSLocalizedString(@"Regular Expression Error",@"Regular Expression Error Title")];
                            [alert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"\"%@\" within state \"%@\" is not a valid regular expression. Please check your regular expression in Find Panel's Ruby mode.",@"Syntax Regular Expression Error Informative Text"),keyword, [keywordGroup objectForKey:@"id"]]];
                            [alert addButtonWithTitle:@"OK"];
                            [alert runModal];
                            everythingOkay = NO;
                        }
                    }
                }
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

#pragma mark - 
#pragma mark - Accessors
#pragma mark - 

- (NSDictionary *)importedModes {
    return I_importedModes;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"SyntaxDefinition, Name:%@ , TokenSet:%@, DefaultState: %@, Uses Spelling Dcitionary: %@", [self name], [self tokenSet], [I_defaultState description], I_useSpellingDictionary?@"Yes.":@"No."];
}

- (NSString *)name
{
    return I_name;
}

- (void)setName:(NSString *)aString
{
    [I_name autorelease];
     I_name = [aString copy];
}

- (NSDictionary *)defaultState
{
    return I_defaultState;
}

- (NSCharacterSet *)tokenSet
{
    return I_tokenSet;
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
    [I_autoCompleteTokenSet autorelease];
     I_autoCompleteTokenSet = [aCharacterSet copy];
}

- (void)setTokenSet:(NSCharacterSet *)aCharacterSet
{
    [I_tokenSet autorelease];
     I_tokenSet = [aCharacterSet copy];
    [I_invertedTokenSet autorelease];
     I_invertedTokenSet = [[aCharacterSet invertedSet] copy];
}

- (BOOL)state:(NSString *)aState includesState:(NSString *)anotherState {

    #warning Optimize this via caching/hashing
    NSDictionary *searchState = [self stateForID:aState];
    NSEnumerator *enumerator = [[searchState objectForKey:@"states"] objectEnumerator];
    id object;
    while ((object = [[enumerator nextObject] objectForKey:@"id"])) {
        if ([object isEqualToString:anotherState]) return YES;
    }

    return NO;
}


//- (NSArray *)states {
//    return [I_allStates allValues];
//}

- (NSDictionary *)stateForID:(NSString *)aString {
	NSArray *components = [aString componentsSeparatedByString:@"/"];
	NSString *modeName = [components objectAtIndex:1];
	
	if (![modeName isEqualToString:[self name]]) {
		return [[[[DocumentModeManager sharedInstance] documentModeForName:modeName] syntaxDefinition] stateForID:aString];
	} 
	
    if (!I_combinedStateRegexReady && !I_combinedStateRegexCalculating) [self calculateCombinedStateRegexes];
    if (!I_cacheStylesReady && !I_cacheStylesCalculating) [self cacheStyles];
    if ([aString isEqualToString:SyntaxStyleBaseIdentifier]) return I_defaultState;
    return [I_allStates objectForKey:aString];
}

- (NSString *)styleForToken:(NSString *)aToken inState:(NSString *)aState 
{
//	NSLog(@"%s:%d: %@",__PRETTY_FUNCTION__,__LINE__, aState);
	NSArray *components = [aState componentsSeparatedByString:@"/"];
	NSString *modeName = [components objectAtIndex:1];
	
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
	NSArray *components = [aState componentsSeparatedByString:@"/"];
	NSString *modeName = [components objectAtIndex:1];
	
	if (![modeName isEqualToString:[self name]]) {
		return [[[[DocumentModeManager sharedInstance] documentModeForName:modeName] syntaxDefinition] hasTokensForState:aState];
	} 
	
    return (([[[I_stylesForToken objectForKey:aState] objectAtIndex:0] count]>0)||([[[I_stylesForToken objectForKey:aState] objectAtIndex:1] count]>0));
}

- (NSArray *)regularExpressionsInState:(NSString *)aState
{
//	NSLog(@"%s:%d: %@",__PRETTY_FUNCTION__,__LINE__, aState);
	NSArray *components = [aState componentsSeparatedByString:@"/"];
	NSString *modeName = [components objectAtIndex:1];
	
	if (![modeName isEqualToString:[self name]]) {
		return [[[[DocumentModeManager sharedInstance] documentModeForName:modeName] syntaxDefinition] regularExpressionsInState:aState];
	} 

    NSArray *aRegexDictionary;
    if ((aRegexDictionary = [I_stylesForRegex objectForKey:aState])) return aRegexDictionary;
    else return nil;
}

- (void)setCombinedStateRegexForState:(NSMutableDictionary *)aState
{ 
	if ([aState objectForKey:@"imports"]) {
		
		NSEnumerator *enumerator = [[aState objectForKey:@"imports"] objectEnumerator];
		id importName;
		while ((importName = [enumerator nextObject])) {
			NSArray *components = [importName componentsSeparatedByString:@"/"];
			BOOL keywordsOnly = NO;
			if ([components count]>3) {
				if ([[components objectAtIndex:1] isEqualToString:@"keywords-only"]) keywordsOnly = YES;
			}
			
			SyntaxDefinition *linkedDefinition = [[[DocumentModeManager sharedInstance] documentModeForName:[components objectAtIndex:1]] syntaxDefinition];
			NSDictionary *linkedState = [linkedDefinition stateForID:importName];
			
			if (linkedState) {
				if (!keywordsOnly) {
					if (![aState objectForKey:@"states"]) [aState setObject:[NSMutableArray array] forKey:@"states"];
					[[aState objectForKey:@"states"] addObjectsFromArray:[linkedState objectForKey:@"states"]];
				}
				
				if (![aState objectForKey:@"KeywordGroups"]) [aState setObject:[NSMutableArray array] forKey:@"KeywordGroups"];
				[[aState objectForKey:@"KeywordGroups"] addObjectsFromArray:[linkedState objectForKey:@"KeywordGroups"]];
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
            NSArray *components = [linkedName componentsSeparatedByString:@"/"];
			
            SyntaxDefinition *linkedDefinition = [[[DocumentModeManager sharedInstance] documentModeForName:[components objectAtIndex:1]] syntaxDefinition];
            NSDictionary *linkedState = [linkedDefinition stateForID:linkedName];
			
            if (linkedState) {
				if ([linkedState objectForKey:@"BeginsWithRegexString"])
					[aDictionary setObject:[linkedState objectForKey:@"BeginsWithRegexString"] forKey:@"BeginsWithRegexString"];
				if ([linkedState objectForKey:@"BeginsWithPlainString"])
					[aDictionary setObject:[linkedState objectForKey:@"BeginsWithPlainString"] forKey:@"BeginsWithPlainString"];
				if ([linkedState objectForKey:@"EndsWithRegexString"])
					[aDictionary setObject:[linkedState objectForKey:@"EndsWithRegexString"] forKey:@"EndsWithRegexString"];
				if ([linkedState objectForKey:@"EndsWithPlainString"])
					[aDictionary setObject:[linkedState objectForKey:@"EndsWithPlainString"] forKey:@"EndsWithPlainString"];
				if ([linkedState objectForKey:@"styleID"])
					[aDictionary setObject:[linkedState objectForKey:@"styleID"] forKey:@"styleID"];
            }
        }
		
		
        if ((beginString = [aDictionary objectForKey:@"BeginsWithRegexString"])) {
            DEBUGLOG(@"SyntaxHighlighterDomain", AllLogLevel, @"Found regex string state start:%@",beginString);
            // Warn if begin contains unnamed group
            OGRegularExpression *testForGroups = [[OGRegularExpression alloc] initWithString:beginString options:OgreFindLongestOption|OgreFindNotEmptyOption|OgreCaptureGroupOption];

            if ([testForGroups numberOfGroups]>[testForGroups numberOfNames]) {
                NSLog(@"ERROR: Captured group in <begin>:%@",[aDictionary description]);
                NSAlert *alert = [[[NSAlert alloc] init] autorelease];
                [alert setAlertStyle:NSWarningAlertStyle];
                [alert setMessageText:NSLocalizedString(@"XML Group Error",@"XML Group Error Title")];
                [alert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"The <begin> tag of <state> \"%@\" contains a regex that has captured groups. This is currently not allowed. Please escape all groups to be not-captured with (?:).",@"Syntax XML Group Error Informative Text"),[aDictionary objectForKey:@"id"]]];
                [alert addButtonWithTitle:@"OK"];
                [alert runModal];
                everythingOkay = NO;
            }
          
            [testForGroups release];
        } else if ((beginString = [aDictionary objectForKey:@"BeginsWithPlainString"])) {
            DEBUGLOG(@"SyntaxHighlighterDomain", AllLogLevel, @"Found plain string state start:%@",beginString);
        } else {
            NSLog(@"ERROR: State without begin:%@",[aDictionary description]);
            NSAlert *alert = [[[NSAlert alloc] init] autorelease];
            [alert setAlertStyle:NSWarningAlertStyle];
            [alert setMessageText:NSLocalizedString(@"XML Structure Error",@"XML Structure Error Title")];
            [alert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"<state> \"%@\" has no <begin>. This confuses me. Please check your syntax definition.",@"Syntax XML Structure Error Informative Text"),[aDictionary objectForKey:@"id"]]];
            [alert addButtonWithTitle:@"OK"];
            [alert runModal];
            everythingOkay = NO;
        }
        if (beginString) {
            [combinedString appendString:[NSString stringWithFormat:@"(?<seeinternalgroup%d>%@)|",i,beginString]];
        }
    }


    int combinedStringLength = [combinedString length];
    if ((combinedStringLength>1)||(endString)) {
        if (endString) { // Any states except the default
            [combinedString appendString:[NSString stringWithFormat:@"(?<seeinternalgroup4242>%@)",endString]];
        } else {
            [combinedString deleteCharactersInRange:NSMakeRange(combinedStringLength-1,1)];      
        }

        if ([OGRegularExpression isValidExpressionString:combinedString]) {
            OGRegularExpression *combindedRegex = [[OGRegularExpression alloc] initWithString:combinedString options:OgreFindNotEmptyOption|OgreCaptureGroupOption];
            [aState setObject:combindedRegex forKey:@"Combined Delimiter Regex"];
        } else {
            NSLog(@"ERROR: %@ (begins of all states) is not a valid regular expression", combinedString);
            NSAlert *alert = [[[NSAlert alloc] init] autorelease];
            [alert setAlertStyle:NSWarningAlertStyle];
            [alert setMessageText:NSLocalizedString(@"Regular Expression Error",@"Regular Expression Error Title")];
            [alert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"One of the specified state <begin>'s is not a valid regular expression. Therefore the Combined Delimiter Regex \"%@\" could not be compiled. Please check your regular expression in Find Panel's Ruby mode.",@"Syntax Regular Expression Error Informative Text"),combinedString]];
            [alert addButtonWithTitle:@"OK"];
            [alert runModal];
            everythingOkay = NO;
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
