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
#import "SyntaxHighlighter.h"


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
        I_foldingTopLevel = 1;
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
		I_symbolAndAutocompleteInheritanceReady=NO;
		I_levelsForStyleIDs = [NSMutableDictionary new];
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
	[I_defaultSyntaxStyle release];
    [I_autocompleteTokenString release];
    [I_levelsForStyleIDs release];
    [I_charsInToken release];
    [I_charsDelimitingToken release];
    [self setTokenSet:nil];
    [self setAutoCompleteTokenSet:nil];
    [super dealloc];
}

#pragma mark - 
#pragma mark - XML parsing
#pragma mark - 

-(void) showWarning:(NSString *)title withDescription:(NSString *)description {
	NSLog(@"ERROR: %@: ",title, description);
	NSAlert *alert = [[[NSAlert alloc] init] autorelease];
	[alert setAlertStyle:NSWarningAlertStyle];
	[alert setMessageText:title];
	[alert setInformativeText:description];
	[alert addButtonWithTitle:@"OK"];
	[alert runModal];
	everythingOkay = NO;
}

/*"Entry point for XML parsing, branches to according node functions"*/
-(void)parseXMLFile:(NSString *)aPath {

    NSError *err=nil;
    NSXMLDocument *syntaxDefinitionXML = [[[NSXMLDocument alloc] initWithData:[NSData dataWithContentsOfFile:aPath] options:0 error:&err] autorelease];

    if (err) {
		[self showWarning:NSLocalizedString(@"XML Structure Error",@"XML Structure Error Title")  withDescription:[NSString stringWithFormat:NSLocalizedString(@"Error while loading '%@': %@",@"Syntax XML Loading Error Informative Text"),aPath, [err localizedDescription]]];
        return;
    } 

    //Parse Headers
    
    [self setName:[[[syntaxDefinitionXML nodesForXPath:@"/syntax/head/name" error:&err] lastObject] stringValue]];

    NSString *charsInToken = [[[syntaxDefinitionXML nodesForXPath:@"/syntax/head/charsintokens" error:&err] lastObject] stringValue];
    NSString *charsDelimitingToken = [[[syntaxDefinitionXML nodesForXPath:@"/syntax/head/charsdelimitingtokens" error:&err] lastObject] stringValue];
    NSCharacterSet *tokenSet = nil; // TODO: what should be the value if neither charsInToken nor charsDelimitingToken?
    
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

    
    // Parse states
    NSXMLElement *defaultStateNode = [[syntaxDefinitionXML nodesForXPath:@"/syntax/states/default" error:&err] lastObject];
	
	if (!defaultStateNode) {
		[self showWarning:NSLocalizedString(@"XML Structure Error",@"XML Structure Error Title")  withDescription:[NSString stringWithFormat:NSLocalizedString(@"Error while loading '%@': File has no default state defined",@"Syntax XML No Default State Error Informative Text"),aPath]];
	}
	
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
                if ((endRegex = [[[OGRegularExpression alloc] initWithString:regexEnd options:OgreFindNotEmptyOption] autorelease]))
                    [stateDictionary setObject:endRegex forKey:@"EndsWithRegex"];
                [stateDictionary setObject:regexEnd forKey:@"EndsWithRegexString"];
            } else {
                [self showWarning:NSLocalizedString(@"XML Regex Error",@"XML Regex Error Title")  withDescription:[NSString stringWithFormat:NSLocalizedString(@"State '%@' in %@ mode has a begin tag that is not a valid regex",@"Syntax State Malformed Begin Error Informative Text"), [stateDictionary objectForKey:@"id"], [self name]]];
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
    
    NSArray *keywordGroupsNodes = [stateNode nodesForXPath:@"./keywords" error:&err];
    
    NSEnumerator *keywordGroupEnumerator = [keywordGroupsNodes objectEnumerator];
    id keywordGroupNode;
    while ((keywordGroupNode = [keywordGroupEnumerator nextObject])) {
        NSMutableDictionary *keywordGroupDictionary = [NSMutableDictionary dictionary];
        [self addAttributes:[keywordGroupNode attributes] toDictionary:keywordGroupDictionary];
        NSString *keywordGroupName = [keywordGroupDictionary objectForKey:@"id"];
        if (keywordGroupName) [keywordGroups addObject:keywordGroupDictionary];
        
        // Add regexes for keyword group
        NSMutableArray *regexes = [NSMutableArray array];
        NSMutableArray *strings = [NSMutableArray array];
        NSMutableString *combindedRegexRegexString = [NSMutableString stringWithString:@"(?:"];
        
        [keywordGroupDictionary setObject:regexes forKey:@"RegularExpressions"];
        [keywordGroupDictionary setObject:strings forKey:@"PlainStrings"];
        
        NSArray *regexNodes = [keywordGroupNode nodesForXPath:@"./regex" error:&err];
        NSEnumerator *regexEnumerator = [regexNodes objectEnumerator];
        id regexNode;
        while ((regexNode = [regexEnumerator nextObject])) {
            [regexes addObject:[regexNode stringValue]];
            [combindedRegexRegexString appendFormat:@"%@|",[regexNode stringValue]];
        }
        if ([regexNodes count]>0) {
            [combindedRegexRegexString replaceCharactersInRange:NSMakeRange([combindedRegexRegexString length]-1, 1) withString:@")"];
            [keywordGroupDictionary setObject:[[[OGRegularExpression alloc] initWithString:combindedRegexRegexString options:OgreFindNotEmptyOption|OgreCaptureGroupOption] autorelease] forKey:@"CompiledRegEx"];            
        }
        
        
        // Add strings for keyword group
//        NSMutableString *combindedKeywordRegexString = [NSMutableString string];
//        if (I_charsInToken) {
//            [combindedKeywordRegexString appendFormat:@"(?<![%@])(",[I_charsInToken stringByReplacingRegularExpressionOperators]];
//        } else if (I_charsDelimitingToken) {
//            [combindedKeywordRegexString appendFormat:@"(?<=[%@])(",[I_charsDelimitingToken stringByReplacingRegularExpressionOperators]];
//        } else {
//            [combindedKeywordRegexString appendString:@"("]; 
//        }
                
        BOOL autocomplete = [[keywordGroupDictionary objectForKey:@"useforautocomplete"] isEqualToString:@"yes"];
        NSMutableArray *autocompleteDictionary = [[self mode] autocompleteDictionary];
        NSArray *stringNodes = [keywordGroupNode nodesForXPath:@"./string" error:&err];
        NSEnumerator *stringEnumerator = [stringNodes objectEnumerator];
        id stringNode;
        while ((stringNode = [stringEnumerator nextObject])) {
            [strings addObject:[stringNode stringValue]];
            //[combindedKeywordRegexString appendFormat:@"%@|",[[stringNode stringValue] stringByReplacingRegularExpressionOperators]];
            if (autocomplete) [autocompleteDictionary addObject:[stringNode stringValue]];
        }
//        if ([stringNodes count]>0) {
//            [combindedKeywordRegexString replaceCharactersInRange:NSMakeRange([combindedKeywordRegexString length]-1, 1) withString:@")"];
//            
//            if (I_charsInToken) {
//                [combindedKeywordRegexString appendFormat:@"(?![%@])",[I_charsInToken stringByReplacingRegularExpressionOperators]];
//            } else if (I_charsDelimitingToken) {
//                [combindedKeywordRegexString appendFormat:@"(?=[%@])",[I_charsDelimitingToken stringByReplacingRegularExpressionOperators]];
//            }        
//            
//            [keywordGroupDictionary setObject:[[[OGRegularExpression alloc] initWithString:combindedKeywordRegexString options:OgreFindNotEmptyOption|OgreCaptureGroupOption] autorelease] forKey:@"CompiledKeywords"];
//        }
    }
    
    if ([name isEqualToString:@"default"]) {        
        [stateDictionary setObject:[NSString stringWithFormat:@"/%@/%@", [self name], SyntaxStyleBaseIdentifier] forKey:@"id"];
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
	if (autocompleteFromMode) [stateDictionary setObject:symbolsFromMode forKey:@"switchtoautocompletefrommode"];
    
    // Get all nodes and preserve order
    NSArray *allStateNodes = [stateNode nodesForXPath:@"./state | ./import | ./state-link" error:&err];
    NSEnumerator *allStateNodesEnumerator = [allStateNodes objectEnumerator];
    id nextState;
    while ((nextState = [allStateNodesEnumerator nextObject])) {
        NSString *nodeName = [nextState name];
        if (![stateDictionary objectForKey:@"states"]) [stateDictionary setObject:[NSMutableArray array] forKey:@"states"];
     
        if ([nodeName isEqualToString:@"state"]) {  //Recursive descent into sub-states
            [self parseState:nextState addToState:stateDictionary];           
        } 
        else if ([nodeName isEqualToString:@"import"]) //Weak-link to imported states, for later copying
        {  
            NSMutableDictionary *weaklinks = [stateDictionary objectForKey:@"imports"];
            if (!weaklinks) {
                weaklinks = [NSMutableDictionary dictionary];
                [stateDictionary setObject:weaklinks forKey:@"imports"];
                
            }

            NSString *importMode, *importState;
            importMode = [[nextState attributeForName:@"mode"] stringValue];
            if (!importMode) importMode = [self name];
            
            importState = [[nextState attributeForName:@"state"] stringValue];
            if (!importState) importState = SyntaxStyleBaseIdentifier;
            
            NSString *importName = [NSString stringWithFormat:@"/%@/%@", importMode, importState];
            
            [I_importedModes setObject:@"import" forKey:importMode];
            [weaklinks setObject:nextState forKey:importName];
            
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
                NSString *styleID=[keywordGroup objectForKey:kSyntaxHighlightingStyleIDAttributeName];
                if ([keywordGroup objectForKey:@"CompiledRegEx"]) [newRegExArray addObject:[NSArray arrayWithObjects:[keywordGroup objectForKey:@"CompiledRegEx"], styleID, nil]];
                
                
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
                
            
            }

//            groupEnumerator = [keywordGroups objectEnumerator];
//            while ((keywordGroup = [groupEnumerator nextObject])) {
//                NSString *styleID=[keywordGroup objectForKey:kSyntaxHighlightingStyleIDAttributeName];
//                if ([keywordGroup objectForKey:@"CompiledKeywords"]) [newRegExArray addObject:[NSArray arrayWithObjects:[keywordGroup objectForKey:@"CompiledKeywords"], styleID, nil]];
//            }
            // First do the plainstring stuff
//                
//                // Then do the regex stuff
//                
//                if ((keywords = [keywordGroup objectForKey:@"RegularExpressions"])) {
//                    NSEnumerator *keywordEnumerator = [keywords objectEnumerator];
//                    NSString *keyword;
//                    NSString *aString;
//                    while ((keyword = [keywordEnumerator nextObject])) {
//                        OGRegularExpression *regex;
//                        unsigned regexOptions = OgreFindNotEmptyOption;
//                        if ((aString = [keywordGroup objectForKey:@"casesensitive"])) {       
//                            if (([aString isEqualTo:@"no"])) {
//                                regexOptions = regexOptions|OgreIgnoreCaseOption;
//                            }
//                        }
//                        if ([OGRegularExpression isValidExpressionString:keyword]) {
//                            if ((regex = [[[OGRegularExpression alloc] initWithString:keyword options:regexOptions] autorelease])) {
//                                [newRegExArray addObject:[NSArray arrayWithObjects:regex, styleID, nil]];
//                            }
//                        } else {
//							[self showWarning:NSLocalizedString(@"Regular Expression Error",@"Regular Expression Error Title") withDescription:[NSString stringWithFormat:NSLocalizedString(@"\"%@\" within state \"%@\" is not a valid regular expression. Please check your regular expression in Find Panel's Ruby mode.",@"Syntax Regular Expression Error Informative Text"),keyword, [keywordGroup objectForKey:@"id"]]];
//                        }
//                    }
//                }
//

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

- (OGRegularExpression *)tokenRegex
{
    return I_tokenRegex;
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

    NSDictionary *searchState = [self stateForID:aState];
    NSEnumerator *enumerator = [[searchState objectForKey:@"states"] objectEnumerator];
    id object;
    while ((object = [[enumerator nextObject] objectForKey:@"id"])) {
        if ([object isEqualToString:anotherState]) return YES;
    }

    return NO;
}

- (NSString *) keyForInheritedSymbols {
	return [NSString stringWithFormat:@"/%@/useSymbolsFrom", [self name]];
}

- (NSString *) keyForInheritedAutocomplete {
	return [NSString stringWithFormat:@"/%@/useAutocompleteFrom", [self name]];
}

- (NSString*)getModeNameFromState:(NSString*)aState
{
	NSRange aRange = [aState rangeOfString:@"/" options:NSLiteralSearch range:NSMakeRange(1, [aState length] - 1)];
	NSString *modeName = [aState substringWithRange:NSMakeRange(1, aRange.location - 1)];
	
	return modeName;
}

// Calculate inheritances recursivly
- (void) calculateSymbolInheritanceForState:(NSMutableDictionary *)state inheritedSymbols:(NSString *)oldSymbols inheritedAutocomplete:(NSString *)oldAutocomplete {
	NSString *symbols = nil;
	NSString *autocomplete = nil;
	
	if ([state objectForKey:@"switchtosymbolsfrommode"]) symbols = [[[state objectForKey:@"switchtosymbolsfrommode"] copy] autorelease];
    else symbols = [[oldSymbols copy] autorelease];
	if ([state objectForKey:@"switchtoautocompletefrommode"]) autocomplete = [[[state objectForKey:@"switchtoautocompletefrommode"] copy] autorelease];
    else autocomplete = [[oldAutocomplete copy] autorelease];
    

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
		if (![childState objectForKey:[self keyForInheritedSymbols]])
			[self calculateSymbolInheritanceForState:childState inheritedSymbols:symbols inheritedAutocomplete:autocomplete];
    }
}

- (void) getReady {
    if (!I_combinedStateRegexReady && !I_combinedStateRegexCalculating) [self calculateCombinedStateRegexes];
	[self addStyleIDsFromState:[self defaultState]];
    if (!I_cacheStylesReady && !I_cacheStylesCalculating) [self cacheStyles];
	if (!I_symbolAndAutocompleteInheritanceReady) {
		[self calculateSymbolInheritanceForState:[I_allStates objectForKey:[NSString stringWithFormat:@"/%@/%@", [self name], SyntaxStyleBaseIdentifier]] inheritedSymbols:[self name] inheritedAutocomplete:[self name]];
		I_symbolAndAutocompleteInheritanceReady = YES;
//		NSLog(@"Defaultstate: Sym:%@, Auto:%@", [[self defaultState] objectForKey:[self keyForInheritedSymbols]],[[self defaultState] objectForKey:[self keyForInheritedAutocomplete]]);
	}
	//NSLog(@"foo: %@", [I_defaultSyntaxStyle allKeys]);
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
    NSEnumerator *keywordGroups = [[aState objectForKey:@"KeywordGroups"] objectEnumerator];
    NSDictionary *keywordGroup = nil;
    while ((keywordGroup=[keywordGroups nextObject])) {
        if ([[keywordGroup objectForKey:kSyntaxHighlightingStyleIDAttributeName] isEqualToString:aStyleID]) {
            return aLevel;
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

    NSArray *aRegexDictionary;
    if ((aRegexDictionary = [I_stylesForRegex objectForKey:aState])) return aRegexDictionary;
    else return nil;
}

- (void)addStyleIDsFromState:(NSDictionary *)aState {
	aState = [self stateForID:[aState objectForKey:@"id"]]; // Refetch state to be sure to get the orignal and not a weak-link zombie
	if (![aState objectForKey:kSyntaxHighlightingStyleIDAttributeName]) return;
    [I_defaultSyntaxStyle takeValuesFromDictionary:aState];
    NSEnumerator *keywords = [[aState objectForKey:@"KeywordGroups"] objectEnumerator];
    id keyword;
    while ((keyword = [keywords nextObject])) {
        [I_defaultSyntaxStyle takeValuesFromDictionary:keyword];
    }
    
    NSEnumerator *subStates = [[aState objectForKey:@"states"] objectEnumerator];
    id subState;
    while ((subState = [subStates nextObject])) {
        if ((![I_defaultSyntaxStyle styleForKey:[subState objectForKey:kSyntaxHighlightingStyleIDAttributeName]])&&(![[aState objectForKey:@"id"] isEqualToString:[subState objectForKey:@"id"]])) [self addStyleIDsFromState:[self stateForID:[subState objectForKey:@"id"]]];
    }
    
}

- (void)setCombinedStateRegexForState:(NSMutableDictionary *)aState
{ 
	if ([aState objectForKey:@"imports"]) {
		
		NSEnumerator *enumerator = [[aState objectForKey:@"imports"] keyEnumerator];
		id importName;
		while ((importName = [enumerator nextObject])) {
			NSArray *components = [importName componentsSeparatedByString:@"/"];
			BOOL keywordsOnly = NO;
			
			NSXMLElement *importNode = [[aState objectForKey:@"imports"] objectForKey:importName];
			if ([[[importNode attributeForName:@"keywords-only"]stringValue] isEqualToString:@"yes"]) keywordsOnly = YES;
			
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
				if ([linkedState objectForKey:kSyntaxHighlightingStyleIDAttributeName])
					[aDictionary setObject:[linkedState objectForKey:kSyntaxHighlightingStyleIDAttributeName] forKey:kSyntaxHighlightingStyleIDAttributeName];
				if ([linkedState objectForKey:@"type"])
					[aDictionary setObject:[linkedState objectForKey:@"type"] forKey:@"type"];
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
          
            [testForGroups release];
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


    int combinedStringLength = [combinedString length];
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
				OGRegularExpression *filterGroupsRegex = [[[OGRegularExpression alloc] initWithString:@"(?<=\\(\\?#see-insert-start-group:)[^\\)]+" options:OgreFindNotEmptyOption|OgreCaptureGroupOption] autorelease];
				NSEnumerator *matchEnumerator = [[filterGroupsRegex allMatchesInString:endString] objectEnumerator];
				OGRegularExpressionMatch *aMatch;
				while ((aMatch = [matchEnumerator nextObject])) {
					[captureGroups addObject:[aMatch matchedString]];
				}
				
				[aState setObject:captureGroups forKey:@"Combined Delimiter String End Capture Groups"];
			} else {
				OGRegularExpression *combindedRegex = [[[OGRegularExpression alloc] initWithString:combinedString options:OgreFindNotEmptyOption|OgreCaptureGroupOption] autorelease];
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
