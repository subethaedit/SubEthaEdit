//
//  SyntaxStyle.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 11.10.04.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "SyntaxStyle.h"
#import "DocumentModeManager.h"

NSString * const SyntaxStyleBaseIdentifier = @"_Default";

static NSArray *S_possibleStyleColors;

@implementation SyntaxStyle

+ (void)initialize {
    S_possibleStyleColors=[[NSArray alloc] initWithObjects:@"color",@"inverted-color",@"background-color",@"inverted-background-color",nil];
}

+ (BOOL)style:(NSDictionary *)aStyle isEqualToStyle:(NSDictionary *)anotherStyle {
    NSString *colorKey=nil;
    NSEnumerator *colorKeys=[S_possibleStyleColors objectEnumerator];
    while ((colorKey=[colorKeys nextObject])) {
        NSColor *color=[aStyle objectForKey:colorKey];
        if (color) {
            if (![[color HTMLString] isEqualToString:[[anotherStyle objectForKey:colorKey] HTMLString]]) {
                return NO;
            }
        }
    }
    if ([[aStyle objectForKey:@"font-trait"] unsignedIntValue] != 
        [[anotherStyle objectForKey:@"font-trait"]  unsignedIntValue]) {
        return NO;
    }
    return YES;
}

+ (NSIndexSet *)indexesWhereStyle:(SyntaxStyle *)aStyle isNotEqualToStyle:(SyntaxStyle *)anotherStyle {
    if ([[aStyle documentMode] isEqual:[anotherStyle documentMode]]) {
        NSMutableIndexSet *result=[NSMutableIndexSet indexSet];
        NSArray *allKeys=[aStyle allKeys];
        unsigned int i=0;
        unsigned int count=[allKeys count];
        for (i=0;i<count;i++) {
            NSString *styleID=[allKeys objectAtIndex:i];
            if (![SyntaxStyle style:[aStyle styleForKey:styleID] isEqualToStyle:[anotherStyle styleForKey:styleID]]) {
                [result addIndex:i];
            }
        }
        return result;
    } else {
        return nil;
    }
}

- (void)takeValuesFromModeSubtree:(CFXMLTreeRef)aModeTree {
    int childCount;
    int index;
    
    childCount = CFTreeGetChildCount(aModeTree);
    for (index = 0; index < childCount; index++) {
        CFXMLTreeRef xmlTree = CFTreeGetChildAtIndex(aModeTree, index);
        CFXMLNodeRef xmlNode = CFXMLTreeGetNode(xmlTree);
        NSDictionary *attributes = (NSDictionary *)((CFXMLElementInfo *)CFXMLNodeGetInfoPtr(xmlNode))->attributes;
        NSString *tag = (NSString *)CFXMLNodeGetString(xmlNode);
        if ([@"style" isEqualToString:tag]) {
            NSString *styleID=[attributes objectForKey:@"id"];
            NSMutableDictionary *style=[self styleForKey:styleID];
            if (style) {
                NSFontTraitMask mask = 0;
                if ([[attributes objectForKey:@"font-weight"] isEqualTo:@"bold"]) mask = mask | NSBoldFontMask;
                if ([[attributes objectForKey:@"font-style"] isEqualTo:@"italic"]) mask = mask | NSItalicFontMask;
                [style setObject:[NSNumber numberWithUnsignedInt:mask] forKey:@"font-trait"];
                NSEnumerator *colorKeys=[S_possibleStyleColors objectEnumerator];
                NSString *colorKey=nil;
                while ((colorKey=[colorKeys nextObject])) {
                    NSString *htmlColor=[attributes objectForKey:colorKey];
                    if (htmlColor) {
                        [style setObject:[NSColor colorForHTMLString:htmlColor] forKey:colorKey];
                    }
                }
            }
        }
    }
}

+ (SyntaxStyle *)syntaxStyleWithModeSubtree:(CFXMLTreeRef)aModeTree {
    SyntaxStyle *result=nil;
    CFXMLNodeRef node;
    CFXMLElementInfo *elementInfo;
    node = CFXMLTreeGetNode(aModeTree);
    elementInfo = (CFXMLElementInfo *)CFXMLNodeGetInfoPtr(node);
    NSString *modeIdentifier=[(NSDictionary *)elementInfo->attributes objectForKey:@"id"];
    if (modeIdentifier) {
        DocumentMode *mode=[[DocumentModeManager sharedInstance] documentModeForIdentifier:modeIdentifier];
        if (mode) {
            result = [[[mode defaultSyntaxStyle] copy] autorelease];
            [result takeValuesFromModeSubtree:aModeTree];
        }
    }
    return result;
}

+ (NSArray *)syntaxStylesWithXMLFile:(NSString *)aPath {
    NSMutableArray *result=[NSMutableArray array];
    CFXMLTreeRef cfXMLTree;
    CFDataRef xmlData;
    if (!(aPath)) {
        NSLog(@"ERROR: Can't parse nil syntax definition.");
        return result;
    }
    CFURLRef sourceURL = (CFURLRef)[NSURL fileURLWithPath:aPath];
    NSDictionary *errorDict;

    CFURLCreateDataAndPropertiesFromResource(kCFAllocatorDefault, sourceURL, &xmlData, NULL, NULL, NULL);

    cfXMLTree = CFXMLTreeCreateFromDataWithError(kCFAllocatorDefault,xmlData,sourceURL,kCFXMLParserSkipWhitespace|kCFXMLParserSkipMetaData,kCFXMLNodeCurrentVersion,(CFDictionaryRef *)&errorDict);

    if (!cfXMLTree) {
        return result;
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
            [@"seestyle" isEqualToString:(NSString *)CFXMLNodeGetString(xmlNode)]) {
            DEBUGLOG(@"SyntaxHighlighterDomain", AllLogLevel, @"Top level node: %@", (NSString *)CFXMLNodeGetString(xmlNode));
            DEBUGLOG(@"SyntaxHighlighterDomain", AllLogLevel, @"Childs: %d", CFTreeGetChildCount(xmlTree));
            break;
        }
    }

    if (xmlTree && xmlNode) {
        childCount = CFTreeGetChildCount(xmlTree);
        
        for (index = 0; index < childCount; index++) {
            CFXMLTreeRef xmlSubtree = CFTreeGetChildAtIndex(xmlTree, index);
            CFXMLNodeRef xmlSubNode = CFXMLTreeGetNode(xmlSubtree);
            DEBUGLOG(@"SyntaxHighlighterDomain", AllLogLevel, @"Found: %@", (NSString *)CFXMLNodeGetString(xmlSubNode));

            if ([@"mode" isEqualToString:(NSString *)CFXMLNodeGetString(xmlSubNode)]) {
                SyntaxStyle *style=[SyntaxStyle syntaxStyleWithModeSubtree:xmlSubtree];
                if (style) {
                    [result addObject:style];
                }
            }
            
        }
    }
    CFRelease(cfXMLTree);
    CFRelease(xmlData);
    return result;
}

- (id)init {
    self=[super init];
    if (self) {
        I_styleDictionary = [NSMutableDictionary new];
        I_documentMode =nil;
        I_keyArray = [NSMutableArray new];
        [I_keyArray addObject:SyntaxStyleBaseIdentifier];
        [self setStyle:[NSDictionary dictionaryWithObjectsAndKeys:
            [NSColor blackColor],@"color",[NSColor whiteColor],@"inverted-color",
            [NSColor whiteColor],@"background-color",[NSColor blackColor],@"inverted-background-color",
            [NSNumber numberWithUnsignedInt:0],@"font-trait",
            SyntaxStyleBaseIdentifier,@"styleID",nil]
              forKey:SyntaxStyleBaseIdentifier];
    }
    return self;
}

- (id)initWithSyntaxStyle:(SyntaxStyle *)aStyle {
    self=[self init];
    if (self) {
        NSString *key=nil;
        NSEnumerator *keys=[[aStyle allKeys] objectEnumerator];
        while ((key=[keys nextObject])) {
            [self addKey:key];
            [self setStyle:[aStyle styleForKey:key] forKey:key];
        }
        [self setDocumentMode:[aStyle documentMode]];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    SyntaxStyle *result=[[SyntaxStyle allocWithZone:zone] initWithSyntaxStyle:self];
    return result;
}

- (void)dealloc {
    [I_styleDictionary release];
    [super dealloc];
}

- (void)takeStylesFromDefaultsDictionary:(NSDictionary *)aDictionary {
    NSString *key=nil;
    NSEnumerator *keys=[[self allKeys] objectEnumerator];
    while ((key=[keys nextObject])) {
        NSDictionary *value=[aDictionary objectForKey:key];
        if (value) {
            NSMutableDictionary *style=[value mutableCopy];
            NSString *colorKey=nil;
            NSEnumerator *colorKeys=[S_possibleStyleColors objectEnumerator];
            while ((colorKey=[colorKeys nextObject])) {
                NSString *colorString=[style objectForKey:colorKey];
                if (colorString) {
                    [style setObject:[NSColor colorForHTMLString:colorString] forKey:colorKey];
                }
            }
            [self setStyle:style forKey:key];
            [style release];
        }
    }
}

- (void)setDocumentMode:(DocumentMode *)aMode {
    I_documentMode = aMode;
}

- (DocumentMode *)documentMode {
    return I_documentMode;
}


- (NSArray *)allKeys {
    return I_keyArray;
}

- (void)addKey:(NSString *)aKey {
    if (![SyntaxStyleBaseIdentifier isEqualTo:aKey]) 
        [I_keyArray addObject:aKey];
}


- (NSMutableDictionary *)styleForKey:(NSString *)aKey {
    return [I_styleDictionary objectForKey:aKey];
}

- (void)setStyle:(NSDictionary *)aStyle forKey:(NSString *)aKey {
    [I_styleDictionary setObject:[[aStyle mutableCopy] autorelease] forKey:aKey];
}

- (NSString *)localizedStringForKey:(NSString *)aKey {
    if ([aKey isEqualToString:SyntaxStyleBaseIdentifier]) {
        return NSLocalizedString(@"BaseStyleName",@"Name of base style appearing in Style Preferences");
    }
    NSBundle *bundle = [I_documentMode bundle];
    if (bundle) {
        NSString *localizeKey=[[aKey componentsSeparatedByString:@"."] lastObject];
        NSString *result=[bundle localizedStringForKey:localizeKey value:localizeKey table:nil];
        return [localizeKey isEqualToString:aKey]?result:[NSString stringWithFormat:@"  %@",result];
    } else {
        return aKey;
    }
}

- (NSDictionary *)defaultsDictionary {
    NSMutableDictionary *dictionary=[NSMutableDictionary dictionary];
    SyntaxStyle *defaultStyle=[[self documentMode] defaultSyntaxStyle];
    NSString *key=nil;
    NSEnumerator *keys=[[self allKeys] objectEnumerator];
    while ((key=[keys nextObject])) {
        if (![SyntaxStyle style:[self styleForKey:key] isEqualToStyle:[defaultStyle styleForKey:key]]) {
            NSMutableDictionary *style=[[self styleForKey:key] mutableCopy];
            NSString *colorKey=nil;
            NSEnumerator *colorKeys=[S_possibleStyleColors objectEnumerator];
            while ((colorKey=[colorKeys nextObject])) {
                NSColor *color=[style objectForKey:colorKey];
                if (color) {
                    [style setObject:[color HTMLString] forKey:colorKey];
                }
            }
            [dictionary setObject:style forKey:key];
            [style release];
        }
    }
    return dictionary;
}


- (NSString *)xmlRepresentation {
    NSMutableString *result=[NSMutableString string];
    NSString *key=nil;
    NSEnumerator *keys=[I_keyArray objectEnumerator];
    int later=0;
    while ((key=[keys nextObject])) {
        NSDictionary *style=[I_styleDictionary objectForKey:key];
        NSFontTraitMask traits=[[style objectForKey:@"font-trait"] unsignedIntValue];
        if (later++) {
            [result appendFormat:@"  <style id=\"%@\"\n    color=\"%@\" inverted-color=\"%@\"  font-style=\"%@\" font-weight=\"%@\" />\n",
                key,[[style objectForKey:@"color"] HTMLString],[[style objectForKey:@"inverted-color"] HTMLString],
                traits & NSItalicFontMask?@"italic":@"normal",
                traits & NSBoldFontMask  ?@"bold"  :@"normal"];
        } else {
            [result appendFormat:@"  <style id=\"%@\"\n    color=\"%@\" inverted-color=\"%@\"  font-style=\"%@\" font-weight=\"%@\" background-color=\"%@\" inverted-background-color=\"%@\" />\n",
                key,[[style objectForKey:@"color"] HTMLString],[[style objectForKey:@"inverted-color"] HTMLString],
                traits & NSItalicFontMask?@"italic":@"normal",
                traits & NSBoldFontMask  ?@"bold"  :@"normal",
                [[style objectForKey:@"background-color"]          HTMLString],
                [[style objectForKey:@"inverted-background-color"] HTMLString]];
        }
    }
    return [NSString stringWithFormat:@"<mode id=\"%@\">\n%@</mode>\n",[[self documentMode] documentModeIdentifier],result];

}

- (NSString *)xmlFileRepresentation {
    return [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<seestyle>\n%@</seestyle>\n",[self xmlRepresentation]];
}


- (NSString *)description {
    NSMutableString *result=[NSMutableString string];
    NSString *key=nil;
    NSEnumerator *keys=[I_keyArray objectEnumerator];
    while ((key=[keys nextObject])) {
        [result appendFormat:@"%@ (%@): %@\n",[self localizedStringForKey:key],key,[[I_styleDictionary objectForKey:key] description]];
    }
    return [NSString stringWithFormat:@"SyntaxStyle: \n%@",[self xmlFileRepresentation]];
}


@end
