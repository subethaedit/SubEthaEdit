//
//  SyntaxDefinition.m
//  SyntaxTestBench
//
//  Created by Martin Pittenauer on Wed Mar 17 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "SyntaxDefinition.h"
#import "NSColorTCMAdditions.h"

@implementation SyntaxDefinition

#pragma mark - 
#pragma mark - Initizialisation
#pragma mark - 


/*"Initiates the Syntax Definition with an XML file"*/
- (id)initWithFile:(NSString *)aPath {
    self=[super init];
    if (self) {
        // Alloc & Init
        I_defaultState = [NSMutableDictionary new];
        I_states = [NSMutableArray new];
        I_name = [@"Not named" retain];
        
        // Parse XML File
        [self parseXMLFile:aPath];
        
        // Setup stuff <-> style dictionaries
        I_styleForToken = [NSMutableDictionary new];
        I_styleForRegex = [NSMutableDictionary new];
        [self cacheStyles]; 
        
        // Compile RegExs
        
    }
    DEBUGLOG(@"SyntaxHighlighterDomain", AllLogLevel, @"Initiated new SyntaxDefinition:%@",[self description]);
    return self;
}

- (void)dealloc {
    [I_name release];
    [I_states release];
    [I_defaultState release];
    [I_styleForToken release];
    [I_styleForRegex release];
    [super dealloc];
}

#pragma mark - 
#pragma mark - XML parsing
#pragma mark - 

/*"Entry point for XML parsing, branches to according node functions"*/
-(void)parseXMLFile:(NSString *)aPath {
    CFXMLTreeRef cfXMLTree;
    CFDataRef xmlData;
    CFURLRef sourceURL = (CFURLRef)[NSURL fileURLWithPath:aPath];
    NSDictionary *errorDict;

    CFURLCreateDataAndPropertiesFromResource(kCFAllocatorDefault, sourceURL, &xmlData, NULL, NULL, NULL);

    cfXMLTree = CFXMLTreeCreateFromDataWithError(kCFAllocatorDefault,xmlData,sourceURL,kCFXMLParserSkipWhitespace,kCFXMLNodeCurrentVersion,(CFDictionaryRef *)&errorDict);

    if (!cfXMLTree) {
        NSLog(@"Error parsing syntax definition \"%@\":\n%@", aPath, [errorDict description]);
        CFRelease(cfXMLTree);
        return;
    }        

    
    CFXMLTreeRef    xmlTree = NULL;
    CFXMLNodeRef    xmlNode = NULL;
    int             childCount;
    int             index;

    // Get a count of the top level node’s children.
    childCount = CFTreeGetChildCount(cfXMLTree);

    // Print the data string for each top-level node.
    for (index = 0; index < childCount; index++) {
        xmlTree = CFTreeGetChildAtIndex(cfXMLTree, index);
        xmlNode = CFXMLTreeGetNode(xmlTree);
        if ((CFXMLNodeGetTypeCode(xmlNode) == kCFXMLNodeTypeElement) &&
            [@"syntax" isEqualToString:(NSString *)CFXMLNodeGetString(xmlNode)]) {
            NSLog(@"Top level node: %@", (NSString *)CFXMLNodeGetString(xmlNode));
            NSLog(@"Childs: %d", CFTreeGetChildCount(xmlTree));
            break;
        }
    }

    if (xmlTree && xmlNode) {
        childCount = CFTreeGetChildCount(xmlTree);
        
        for (index = 0; index < childCount; index++) {
            CFXMLTreeRef xmlSubTree = CFTreeGetChildAtIndex(xmlTree, index);
            CFXMLNodeRef xmlSubNode = CFXMLTreeGetNode(xmlSubTree);
            NSLog(@"Found: %@", (NSString *)CFXMLNodeGetString(xmlSubNode));

            if ([@"head" isEqualToString:(NSString *)CFXMLNodeGetString(xmlSubNode)]) {
                [self parseHeaders:xmlSubTree];

            } else if ([@"states" isEqualToString:(NSString *)CFXMLNodeGetString(xmlSubNode)]) {
                [self parseStatesForTreeNode:xmlSubTree];

            }
        }
    }
    CFRelease(cfXMLTree);
}

/*"Parse the <head> tag"*/
- (void)parseHeaders:(CFXMLTreeRef)aTree
{
    int childCount;
    int index;

    childCount = CFTreeGetChildCount(aTree);
    for (index = 0; index < childCount; index++) {
        CFXMLTreeRef xmlTree = CFTreeGetChildAtIndex(aTree, index);
        CFXMLNodeRef xmlNode = CFXMLTreeGetNode(xmlTree);
        if (CFXMLNodeGetTypeCode(xmlNode) == kCFXMLNodeTypeElement) {
            NSString *tag     = (NSString *)CFXMLNodeGetString(xmlNode);
            // Text Content
            if ([@"name" isEqualToString:tag]) {
                if (CFTreeGetChildCount(xmlTree) == 1) { 
                    CFXMLNodeRef textNode=CFXMLTreeGetNode(CFTreeGetFirstChild(xmlTree));
                    if (CFXMLNodeGetTypeCode(textNode) == kCFXMLNodeTypeText) {
                        [self setName:(NSString *)CFXMLNodeGetString(textNode)];
                    }
                }
            // CData Content
            } else if ([@"charsintokens" isEqualToString:tag] || 
                       [@"charsdelimitingtokens" isEqualToString:tag]) {
                int childCount = CFTreeGetChildCount(xmlTree);
                int childIndex = 0;
                for (childIndex = 0; childIndex < childCount; childIndex++) {
                    CFXMLNodeRef node = CFXMLTreeGetNode(CFTreeGetChildAtIndex(xmlTree, childIndex));
                    if (CFXMLNodeGetTypeCode(node) == kCFXMLNodeTypeCDATASection) {
                        NSString *content = (NSString *)CFXMLNodeGetString(node);
                        NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:content];
                        if ([@"charsdelimitingtokens" isEqualToString:tag]) {
                            set = [set invertedSet];
                        }
                        [self setTokenSet:set];
                        break;
                    }
                }
            } 
        }
    }
}

/*"Parse the <states> tag"*/
- (void)parseStatesForTreeNode:(CFXMLTreeRef)aTree
{
    int childCount;
    int index;
    
    childCount = CFTreeGetChildCount(aTree);
    for (index = 0; index < childCount; index++) {
        CFXMLTreeRef xmlTree = CFTreeGetChildAtIndex(aTree, index);
        CFXMLNodeRef xmlNode = CFXMLTreeGetNode(xmlTree);
        CFXMLElementInfo eInfo = *(CFXMLElementInfo *)CFXMLNodeGetInfoPtr(xmlNode);
        NSDictionary *attributes = (NSDictionary *)eInfo.attributes;
        NSString *tag = (NSString *)CFXMLNodeGetString(xmlNode);
        NSLog(@"Found: %@", tag);
        if ([@"state" isEqualToString:tag]) {
            NSMutableDictionary *aDictionary = [NSMutableDictionary dictionary];
            [I_states addObject:aDictionary];
            [aDictionary addEntriesFromDictionary:attributes];

            [self stateForTreeNode:xmlTree toDictionary:aDictionary];
        } else if ([@"default" isEqualToString:tag]) {
            [I_defaultState addEntriesFromDictionary:attributes];
            [self stateForTreeNode:xmlTree toDictionary:I_defaultState];
        }
    }
}

/*"Parse <state> and <default> tags"*/
- (void)stateForTreeNode:(CFXMLTreeRef)aTree toDictionary:(NSMutableDictionary *)aDictionary
{
    int childCount;
    int index;
        
    childCount = CFTreeGetChildCount(aTree);
    for (index = 0; index < childCount; index++) {
        CFXMLTreeRef xmlTree = CFTreeGetChildAtIndex(aTree, index);
        CFXMLNodeRef node = CFXMLTreeGetNode(xmlTree);
        NSString *tag = (NSString *)CFXMLNodeGetString(node);
        if ([@"begin" isEqualToString:tag]) {
            DEBUGLOG(@"SyntaxHighlighterDomain", AllLogLevel, @"Found <begin> tag");
            CFXMLTreeRef firstTree = CFTreeGetFirstChild(xmlTree);
            CFXMLNodeRef firstNode = CFXMLTreeGetNode(firstTree);
            CFXMLTreeRef secondTree = CFTreeGetFirstChild(firstTree);
            CFXMLNodeRef secondNode = CFXMLTreeGetNode(secondTree);
            NSString *innerTag = (NSString *)CFXMLNodeGetString(firstNode);
            NSString *innerContent = (NSString *)CFXMLNodeGetString(secondNode);
            if ([innerTag isEqualTo:@"regex"]) {
                DEBUGLOG(@"SyntaxHighlighterDomain", AllLogLevel, @"<begin> tag is RegEx");
                [aDictionary setObject:innerContent forKey:@"BeginsWithRegexString"];
            } else if ([innerTag isEqualTo:@"string"]) {
                DEBUGLOG(@"SyntaxHighlighterDomain", AllLogLevel, @"<begin> tag is PlainString");
                [aDictionary setObject:innerContent forKey:@"BeginsWithPlainString"];
            }
        } else if ([@"end" isEqualToString:tag]) {
            DEBUGLOG(@"SyntaxHighlighterDomain", AllLogLevel, @"Found <end> tag");
            CFXMLTreeRef firstTree = CFTreeGetFirstChild(xmlTree);
            CFXMLNodeRef firstNode = CFXMLTreeGetNode(firstTree);
            CFXMLTreeRef secondTree = CFTreeGetFirstChild(firstTree);
            CFXMLNodeRef secondNode = CFXMLTreeGetNode(secondTree);
            NSString *innerTag = (NSString *)CFXMLNodeGetString(firstNode);
            NSString *innerContent = (NSString *)CFXMLNodeGetString(secondNode);
            if ([innerTag isEqualTo:@"regex"]) {
                DEBUGLOG(@"SyntaxHighlighterDomain", AllLogLevel, @"<end> tag is RegEx");
                [aDictionary setObject:innerContent forKey:@"EndsWithRegexString"];
            } else if ([innerTag isEqualTo:@"string"]) {
                DEBUGLOG(@"SyntaxHighlighterDomain", AllLogLevel, @"<end> tag is PlainString");
                [aDictionary setObject:innerContent forKey:@"EndsWithPlainString"];
            }
        } else if ([@"keywords" isEqualToString:tag]) {
            NSMutableDictionary *groups;

            if (!(groups = [aDictionary objectForKey:@"KeywordGroups"])) {
                [aDictionary setObject:[NSMutableDictionary dictionary] forKey:@"KeywordGroups"];
                groups = [aDictionary objectForKey:@"KeywordGroups"];
            }
            
            CFXMLElementInfo eInfo = *(CFXMLElementInfo *)CFXMLNodeGetInfoPtr(node);
            NSDictionary *attributes = (NSDictionary *)eInfo.attributes;

            NSString *keywordName = [attributes objectForKey:@"id"];
            [groups setObject:[NSMutableDictionary dictionary] forKey:keywordName];

            NSMutableDictionary *keywordGroup = [groups objectForKey:keywordName];
            [keywordGroup addEntriesFromDictionary:attributes];
            
            [self addKeywordsForTreeNode:xmlTree toDictionary:keywordGroup];
        }
    }
}

/*"Parse <string> and <regex> tags for keyword groups"*/
- (void)addKeywordsForTreeNode:(CFXMLTreeRef)aTree toDictionary:(NSMutableDictionary *)aDictionary
{
    int childCount;
    int index;
    
    childCount = CFTreeGetChildCount(aTree);
    for (index = 0; index < childCount; index++) {
        CFXMLTreeRef xmlTree = CFTreeGetChildAtIndex(aTree, index);
        CFXMLNodeRef node = CFXMLTreeGetNode(xmlTree);
        NSString *tag = (NSString *)CFXMLNodeGetString(node);
        NSString *content = (NSString *)CFXMLNodeGetString(CFXMLTreeGetNode(CFTreeGetFirstChild(xmlTree)));
        if ([@"regex" isEqualToString:tag]) {
            NSMutableSet *regexs;
            if (!(regexs = [aDictionary objectForKey:@"RegularExpressions"])) {
                [aDictionary setObject:[NSMutableSet set] forKey:@"RegularExpressions"];
                regexs = [aDictionary objectForKey:@"RegularExpressions"];
            }
            [regexs addObject:content];
        } else if ([@"string" isEqualToString:tag]) {
            NSMutableSet *plainStrings;
            if (!(plainStrings = [aDictionary objectForKey:@"PlainStrings"])) {
                [aDictionary setObject:[NSMutableSet set] forKey:@"PlainStrings"];
                plainStrings = [aDictionary objectForKey:@"PlainStrings"];
            }
            [plainStrings addObject:content];
        }
    }
}

#pragma mark - 
#pragma mark - Caching and precalculating
#pragma mark - 

/*"calls addStylesForKeywordGroups: for defaultState and states"*/
-(void)cacheStyles
{
    NSMutableDictionary *aDictionary;
    if (aDictionary = [I_defaultState objectForKey:@"KeywordGroups"]) [self addStylesForKeywordGroups:aDictionary];
    
    NSEnumerator *statesEnumerator = [I_states objectEnumerator];
    while (aDictionary = [statesEnumerator nextObject]) {
        if (aDictionary = [aDictionary objectForKey:@"KeywordGroups"]) [self addStylesForKeywordGroups:aDictionary];
    }
}

/*"Creates dictionaries which match styles (color, font, etc.) to plainstrings or regexs"*/
-(void)addStylesForKeywordGroups:(NSDictionary *)aDictionary
{
    NSEnumerator *groupEnumerator = [aDictionary objectEnumerator];
    NSDictionary *keywordGroup;
    while (keywordGroup = [groupEnumerator nextObject]) {
        NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
        NSColor *aColor;
        NSString *aString;
        if (aColor = [NSColor colorForHTMLString:[keywordGroup objectForKey:@"color"]])
            [attributes setObject:aColor forKey:@"color"];
        if (aColor = [NSColor colorForHTMLString:[keywordGroup objectForKey:@"background-color"]])        
            [attributes setObject:aColor forKey:@"background-color"];
        if (aString = [keywordGroup objectForKey:@"font-style"])        
            [attributes setObject:aString forKey:@"font-style"];
        if (aString = [keywordGroup objectForKey:@"font-weight"])        
            [attributes setObject:aString forKey:@"font-weight"];
        if (aString = [keywordGroup objectForKey:@"casesensitive"])        
            [attributes setObject:aString forKey:@"casesensitive"];
        
        // First do the plainstring stuff
        
        NSDictionary *keywords;
        if (keywords = [keywordGroup objectForKey:@"PlainStrings"]) {
            NSEnumerator *keywordEnumerator = [keywords objectEnumerator];
            NSString *keyword;
            while (keyword = [keywordEnumerator nextObject]) {
                [I_styleForToken setObject:attributes forKey:keyword];
            }
        }
        DEBUGLOG(@"SyntaxHighlighterDomain", AllLogLevel, @"Finished caching plainstrings:%@",[I_styleForToken description]);
        // Then do the regex stuff
        
        if (keywords = [keywordGroup objectForKey:@"RegularExpressions"]) {
            NSEnumerator *keywordEnumerator = [keywords objectEnumerator];
            NSString *keyword;
            while (keyword = [keywordEnumerator nextObject]) {
                //2DO Compile the regex
                //[I_styleForRegex setObject:attributes forKey:regex];
            }
        }
        DEBUGLOG(@"SyntaxHighlighterDomain", AllLogLevel, @"Finished caching regular expressions:%@",[I_styleForRegex description]);
    }
}

#pragma mark - 
#pragma mark - Accessors
#pragma mark - 

- (NSString *)description {
    return [NSString stringWithFormat:@"SyntaxDefinition, Name:%@ , TokenSet:%@, States: %@, DefaultState: %@", [self name], [self tokenSet], [I_states description], [I_defaultState description]];
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

- (NSCharacterSet *)tokenSet
{
    return I_tokenSet;
}

- (void)setTokenSet:(NSCharacterSet *)aCharacterSet
{
    [I_tokenSet autorelease];
     I_tokenSet = [aCharacterSet copy];
}

- (NSDictionary *)styleForToken:(NSString *)aToken 
{
    NSDictionary *aStyle;
    if (aStyle = [I_styleForToken objectForKey:aToken]) return aStyle;
    // FIXME: Handle caseinsensitive Tokens with CFDictionary
    else return nil;
}

- (NSDictionary *)regularExpressions
{
    return I_styleForRegex;
}



@end
