//
//  RegexSymbolDefinition.m
//  SubEthaEdit
//
//  Created by Martin Pittenauer on Thu Apr 22 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "RegexSymbolDefinition.h"

extern NSString *extractStringWithEntitiesFromTree(CFXMLTreeRef aTree);

@implementation RegexSymbolDefinition

/*"Initiates the Syntax Definition with an XML file"*/
- (id)initWithFile:(NSString *)aPath {
    if (!aPath) return nil;
    self=[super init];
    if (self) {
        I_symbols = [NSMutableArray new];
        I_block = nil;
        // Parse XML File
        [self parseXMLFile:aPath];
    }
    DEBUGLOG(@"SyntaxHighlighterDomain", AllLogLevel, @"Initiated new SyntaxDefinition:%@",[self description]);
    return self;
}

- (void)dealloc {
    [I_symbols release];
    [I_block release];
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

    cfXMLTree = CFXMLTreeCreateFromDataWithError(kCFAllocatorDefault,xmlData,sourceURL,kCFXMLParserSkipMetaData,kCFXMLNodeCurrentVersion,(CFDictionaryRef *)&errorDict);

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
            [@"symbols" isEqualToString:(NSString *)CFXMLNodeGetString(xmlNode)]) {
            break;
        }
    }

    if (xmlTree && xmlNode) {
        childCount = CFTreeGetChildCount(xmlTree);
        
        for (index = 0; index < childCount; index++) {
            CFXMLTreeRef xmlSubTree = CFTreeGetChildAtIndex(xmlTree, index);
            CFXMLNodeRef xmlSubNode = CFXMLTreeGetNode(xmlSubTree);

            if ([@"blocks" isEqualToString:(NSString *)CFXMLNodeGetString(xmlSubNode)]) {
                [self parseBlocks:xmlSubTree];

            } else if ([@"symbol" isEqualToString:(NSString *)CFXMLNodeGetString(xmlSubNode)]) {
            
                CFXMLElementInfo eInfo = *(CFXMLElementInfo *)CFXMLNodeGetInfoPtr(xmlSubNode);
                NSDictionary *attributes = (NSDictionary *)eInfo.attributes;

                I_currentSymbol = [NSMutableDictionary dictionary];
                [I_symbols addObject:I_currentSymbol];
                
                if ([attributes objectForKey:@"id"]) [I_currentSymbol setObject:[attributes objectForKey:@"id"] forKey:@"id"];
                
                if ([attributes objectForKey:@"image"]) {
                    NSImage *aImage = [NSImage imageNamed:[attributes objectForKey:@"image"]];
                    if (aImage) {
                        [I_currentSymbol setObject:aImage forKey:@"image"];
                    } else {
                        NSLog(@"Can't find image '%@'", [attributes objectForKey:@"image"]);
                    }
                }
                
                if ([attributes objectForKey:@"indentation"]) [I_currentSymbol setObject:[attributes objectForKey:@"indentation"] forKey:@"indentation"];
                if ([attributes objectForKey:@"ignoreblocks"]) [I_currentSymbol setObject:[attributes objectForKey:@"ignoreblocks"] forKey:@"ignoreblocks"];
                if ([attributes objectForKey:@"font-weight"]||[attributes objectForKey:@"font-weight"]) {
                    NSFontTraitMask mask = 0;
                    if ([[attributes objectForKey:@"font-weight"] isEqualTo:@"bold"]) mask = mask | NSBoldFontMask;
                    if ([[attributes objectForKey:@"font-style"] isEqualTo:@"italic"]) mask = mask | NSItalicFontMask;
                    [I_currentSymbol setObject:[[[NSNumber alloc] initWithUnsignedInt:mask] autorelease] forKey:@"font-trait"];
                }
                
                [self parseSymbol:xmlSubTree];
            }
        }
    }
    CFRelease(cfXMLTree);
}

/*"Parse the <blocks> tag"*/
- (void)parseBlocks:(CFXMLTreeRef)aTree
{
    int childCount;
    int index;
    NSString *blockStart;
    NSString *blockEnd;

    childCount = CFTreeGetChildCount(aTree);
    for (index = 0; index < childCount; index++) {
        CFXMLTreeRef xmlTree = CFTreeGetChildAtIndex(aTree, index);
        CFXMLNodeRef xmlNode = CFXMLTreeGetNode(xmlTree);
        if (CFXMLNodeGetTypeCode(xmlNode) == kCFXMLNodeTypeElement) {
            NSString *tag = (NSString *)CFXMLNodeGetString(xmlNode);
            if ([@"beginregex" isEqualToString:tag]) {
                blockStart = extractStringWithEntitiesFromTree(xmlTree);
            }  else if ([@"endregex" isEqualToString:tag]) {
                blockEnd = extractStringWithEntitiesFromTree(xmlTree);
            }  
            if (blockStart && blockEnd) {
                NSString *combined = [NSString stringWithFormat:@"(%@)|(%@)",blockStart,blockEnd];
                if ([OGRegularExpression isValidExpressionString:combined]) {
                    I_block = [[OGRegularExpression alloc] initWithString:combined options:OgreFindNotEmptyOption];
                } else NSLog(@"ERROR: %@ is not a valid Regex.", combined);
            }
        }
    }
}

/*"Parse the <symbol> tag"*/
- (void)parseSymbol:(CFXMLTreeRef)aTree
{
    int childCount;
    int index;

    childCount = CFTreeGetChildCount(aTree);
    for (index = 0; index < childCount; index++) {
        CFXMLTreeRef xmlTree = CFTreeGetChildAtIndex(aTree, index);
        CFXMLNodeRef xmlNode = CFXMLTreeGetNode(xmlTree);

        if (CFXMLNodeGetTypeCode(xmlNode) == kCFXMLNodeTypeElement) {
            NSString *tag = (NSString *)CFXMLNodeGetString(xmlNode);
            if ([@"regex" isEqualToString:tag]) {

                NSString *theString = extractStringWithEntitiesFromTree(xmlTree);
                if ([OGRegularExpression isValidExpressionString:theString]) {
                    OGRegularExpression *aRegex = [[[OGRegularExpression alloc] initWithString:theString options:OgreFindNotEmptyOption] autorelease];
                    [I_currentSymbol setObject:aRegex forKey:@"regex"];
                } else NSLog(@"ERROR: %@ is not a valid Regex.", theString);
            }  else if ([@"postprocess" isEqualToString:tag]) {
                I_currentPostprocess = [NSMutableArray array];
                [I_currentSymbol setObject:I_currentPostprocess forKey:@"postprocess"];
                [self parsePostprocess:xmlTree];
            }  
        }
    }
}

/*"Parse the <postprocess> tag"*/
- (void)parsePostprocess:(CFXMLTreeRef)aTree
{
    int childCount;
    int index;
    OGRegularExpression *findRegex;
    NSString *replaceString;

    childCount = CFTreeGetChildCount(aTree);
    for (index = 0; index < childCount; index++) {
        CFXMLTreeRef xmlTree = CFTreeGetChildAtIndex(aTree, index);
        CFXMLNodeRef xmlNode = CFXMLTreeGetNode(xmlTree);

        if (CFXMLNodeGetTypeCode(xmlNode) == kCFXMLNodeTypeElement) {
            //CFXMLElementInfo eInfo = *(CFXMLElementInfo *)CFXMLNodeGetInfoPtr(xmlNode);
            //NSDictionary *attributes = (NSDictionary *)eInfo.attributes;
            NSString *tag = (NSString *)CFXMLNodeGetString(xmlNode);
            if ([@"find" isEqualToString:tag]) {
                    NSString *aString = extractStringWithEntitiesFromTree(xmlTree);
                    if ([OGRegularExpression isValidExpressionString:aString]) {
                        findRegex = [[[OGRegularExpression alloc] initWithString:aString options:OgreFindNotEmptyOption] autorelease];
                    } else NSLog(@"ERROR: %@ is not a valid Regex.", aString);
            }  else if ([@"replace" isEqualToString:tag]) {
                    replaceString = extractStringWithEntitiesFromTree(xmlTree);
                    if (findRegex && replaceString) {
                        [I_currentPostprocess addObject:[NSArray arrayWithObjects:findRegex, replaceString, nil]];
                    }
                    findRegex = nil;
                    replaceString = nil;
            }  
        }
    }
}

- (NSArray *)symbols
{
    return I_symbols;
}

- (OGRegularExpression *)block
{
    return I_block;
}


@end
