//  SyntaxStyle.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 11.10.04.

#import "SyntaxStyle.h"
#import "SyntaxDefinition.h"
#import "DocumentModeManager.h"
#import "SyntaxHighlighter.h"

// this file needs arc - add -fobjc-arc in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

NSString * const SyntaxStyleBaseIdentifier = @"_Default";

static NSArray *S_possibleStyleColors;

@implementation SyntaxStyle

+ (void)initialize {
    S_possibleStyleColors=[[NSArray alloc] initWithObjects:@"color",@"inverted-color",@"background-color",@"inverted-background-color",nil];
}

+ (BOOL)style:(NSDictionary *)aStyle isEqualToStyle:(NSDictionary *)anotherStyle {
    NSString *colorKey=nil;
    for (colorKey in S_possibleStyleColors) {
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
        NSUInteger i=0;
        NSUInteger count=[allKeys count];
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

- (void)takeValuesFromDictionary:(NSDictionary *)aDictionary {
    NSString *styleID = [aDictionary objectForKey:kSyntaxHighlightingStyleIDAttributeName];
    NSMutableDictionary *styleDictionary = [NSMutableDictionary dictionary];
    NSMutableArray *possibleKeys = [NSMutableArray array];
    [possibleKeys addObjectsFromArray:S_possibleStyleColors];
    [possibleKeys addObjectsFromArray:[NSArray arrayWithObjects:@"font-trait",@"type",kSyntaxHighlightingStyleIDAttributeName,nil]];
    
    id key;
    for (key in possibleKeys) {
        id object = [aDictionary objectForKey:key];
        if (object) [styleDictionary setObject:object forKey:key];
    }

	if ([aDictionary objectForKey:@"text-decoration"]) {
		if ([[aDictionary objectForKey:@"text-decoration"] isEqualToString:@"line-through"]) {
			[styleDictionary setObject:[NSNumber numberWithInteger:(NSUnderlineStyleSingle|NSUnderlinePatternSolid)] forKey:NSStrikethroughStyleAttributeName];
		}
		if ([[aDictionary objectForKey:@"text-decoration"] isEqualToString:@"underline"]) {
			[styleDictionary setObject:[NSNumber numberWithInteger:(NSUnderlineStyleSingle|NSUnderlinePatternSolid)] forKey:NSUnderlineStyleAttributeName];
		}
		if ([[aDictionary objectForKey:@"text-decoration"] isEqualToString:@"dotted"]) {
			[styleDictionary setObject:[NSNumber numberWithInteger:(NSUnderlineStyleSingle|NSUnderlinePatternDot)] forKey:NSUnderlineStyleAttributeName];
		}
	}

	if ([aDictionary objectForKey:@"scope"]) {
		[styleDictionary setObject:[aDictionary objectForKey:@"scope"] forKey:@"scope"];
	}
	
	
	
    if ([styleDictionary objectForKey:@"color"]) {
        [self addKey:styleID];
        [self setStyle:styleDictionary forKey:styleID];            
    }

	

}

//- (void)takeValuesFromModeSubtree:(CFXMLTreeRef)aModeTree {
//	NSDictionary *styleIDTransitionDictionary = [I_documentMode styleIDTransitionDictionary];
//    int childCount;
//    int index;
//    childCount = CFTreeGetChildCount(aModeTree);
//    for (index = 0; index < childCount; index++) {
//        CFXMLTreeRef xmlTree = CFTreeGetChildAtIndex(aModeTree, index);
//        CFXMLNodeRef xmlNode = CFXMLTreeGetNode(xmlTree);
//        NSDictionary *attributes = (NSDictionary *)((CFXMLElementInfo *)CFXMLNodeGetInfoPtr(xmlNode))->attributes;
//        NSString *tag = (NSString *)CFXMLNodeGetString(xmlNode);
//        if ([@"style" isEqualToString:tag]) {
//            NSString *styleID=[attributes objectForKey:@"id"];
//            
//            NSMutableArray *styleIDs = [NSMutableArray arrayWithObject:styleID];
//            NSEnumerator *enumerator = [styleIDTransitionDictionary keyEnumerator];
//            NSString *key = nil;
//            while ((key = [enumerator nextObject])) {
//            	if ([styleID isEqualToString:[styleIDTransitionDictionary objectForKey:key]]) {
//            		[styleIDs addObject:key];
//            	}
//            }
//            
//            enumerator = [styleIDs objectEnumerator];
//            while ((styleID = [enumerator nextObject])) {
//				NSMutableDictionary *style=[self styleForKey:styleID];
//				if (style) {
//					NSFontTraitMask mask = 0;
//					if ([[attributes objectForKey:@"font-weight"] isEqualTo:@"bold"]) mask = mask | NSBoldFontMask;
//					if ([[attributes objectForKey:@"font-style"] isEqualTo:@"italic"]) mask = mask | NSItalicFontMask;
//					[style setObject:[NSNumber numberWithUnsignedInt:mask] forKey:@"font-trait"];
//					NSEnumerator *colorKeys=[S_possibleStyleColors objectEnumerator];
//					NSString *colorKey=nil;
//					while ((colorKey=[colorKeys nextObject])) {
//						NSString *htmlColor=[attributes objectForKey:colorKey];
//						if (htmlColor) {
//							[style setObject:[NSColor colorForHTMLString:htmlColor] forKey:colorKey];
//						}
//					}
//				}
//            }
//        }
//    }
//}
//
//+ (SyntaxStyle *)syntaxStyleWithModeSubtree:(CFXMLTreeRef)aModeTree {
//    SyntaxStyle *result=nil;
//    CFXMLNodeRef node;
//    CFXMLElementInfo *elementInfo;
//    node = CFXMLTreeGetNode(aModeTree);
//    elementInfo = (CFXMLElementInfo *)CFXMLNodeGetInfoPtr(node);
//    NSString *modeIdentifier=[(NSDictionary *)elementInfo->attributes objectForKey:@"id"];
//    if (modeIdentifier) {
//        DocumentMode *mode=[[DocumentModeManager sharedInstance] documentModeForIdentifier:modeIdentifier];
//        if (mode) {
//            result = [[[mode defaultSyntaxStyle] copy] autorelease];
//            [result takeValuesFromModeSubtree:aModeTree];
//        }
//    }
//    return result;
//}
//
//// SEEStyle import helper method
//+ (NSArray *)syntaxStylesWithXMLFile:(NSString *)aPath {
//    NSMutableArray *result=[NSMutableArray array];
//    CFXMLTreeRef cfXMLTree;
//    if (!(aPath)) {
//        NSLog(@"ERROR: Can't parse nil syntax style.");
//        return result;
//    }
//    NSURL *sourceURL = [NSURL fileURLWithPath:aPath];
//	NSData *xmlData = [[[NSData alloc] initWithContentsOfURL:sourceURL options:0 error:nil] autorelease];
//    NSDictionary *errorDict;
//
//    cfXMLTree = CFXMLTreeCreateFromDataWithError(kCFAllocatorDefault,(CFDataRef)xmlData,(CFURLRef)sourceURL,kCFXMLParserSkipWhitespace|kCFXMLParserSkipMetaData,kCFXMLNodeCurrentVersion,(CFDictionaryRef *)&errorDict);
//
//    if (!cfXMLTree) {
//        return result;
//    }
//    
//    CFXMLTreeRef    xmlTree = NULL;
//    CFXMLNodeRef    xmlNode = NULL;
//    int             childCount;
//    int             index;
//
//    // Get a count of the top level node's children.
//    childCount = CFTreeGetChildCount(cfXMLTree);
//
//    // Print the data string for each top-level node.
//    for (index = 0; index < childCount; index++) {
//        xmlTree = CFTreeGetChildAtIndex(cfXMLTree, index);
//        xmlNode = CFXMLTreeGetNode(xmlTree);
//        if ((CFXMLNodeGetTypeCode(xmlNode) == kCFXMLNodeTypeElement) &&
//            [@"seestyle" isEqualToString:(NSString *)CFXMLNodeGetString(xmlNode)]) {
//            DEBUGLOG(@"SyntaxHighlighterDomain", AllLogLevel, @"Top level node: %@", (NSString *)CFXMLNodeGetString(xmlNode));
//            DEBUGLOG(@"SyntaxHighlighterDomain", AllLogLevel, @"Childs: %ld", CFTreeGetChildCount(xmlTree));
//            break;
//        }
//    }
//
//    if (xmlTree && xmlNode) {
//        childCount = CFTreeGetChildCount(xmlTree);
//        
//        for (index = 0; index < childCount; index++) {
//            CFXMLTreeRef xmlSubtree = CFTreeGetChildAtIndex(xmlTree, index);
//            CFXMLNodeRef xmlSubNode = CFXMLTreeGetNode(xmlSubtree);
//            DEBUGLOG(@"SyntaxHighlighterDomain", AllLogLevel, @"Found: %@", (NSString *)CFXMLNodeGetString(xmlSubNode));
//
//            if ([@"mode" isEqualToString:(NSString *)CFXMLNodeGetString(xmlSubNode)]) {
//                SyntaxStyle *style=[SyntaxStyle syntaxStyleWithModeSubtree:xmlSubtree];
//                if (style) {
//                    [result addObject:style];
//                }
//            }
//            
//        }
//    }
//    CFRelease(cfXMLTree);
//    return result;
//}

- (id)init {
    self=[super init];
    if (self) {
        I_styleDictionary = [NSMutableDictionary new];
        _documentMode =nil;
        I_keyArray = [NSMutableArray new];
        [I_keyArray addObject:SyntaxStyleBaseIdentifier];
        [self setStyle:[NSDictionary dictionaryWithObjectsAndKeys:
            [NSColor blackColor],@"color",[NSColor whiteColor],@"inverted-color",
            [NSColor whiteColor],@"background-color",[NSColor blackColor],@"inverted-background-color",
            [NSNumber numberWithUnsignedInt:0],@"font-trait",
            SyntaxStyleBaseIdentifier,kSyntaxHighlightingStyleIDAttributeName,nil]
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

- (void)writeOutAllStylesDictionaryToHome
{
	NSMutableDictionary *allStylesDictionary = [NSMutableDictionary dictionary];
    NSEnumerator *keys=[[self allKeys] objectEnumerator];
    NSString *key = nil;
    while ((key=[keys nextObject])) {
		[allStylesDictionary setObject:key forKey:key];
	}
	[allStylesDictionary writeToFile:[[NSString stringWithFormat:@"~/%@.StyleIDTransition.plist", [_documentMode documentModeIdentifier]] stringByStandardizingPath] atomically:YES];
}

- (void)takeStylesFromDefaultsDictionary:(NSDictionary *)aDictionary {
    NSString *key=nil;

	// this is for writing out inital plists for modes to change with the corresponding keys wanted for the styleIDTransitionDictionary
	//[self writeOutAllStylesDictionaryToHome];
	

    NSDictionary *styleIDTransitionDictionary = [_documentMode styleIDTransitionDictionary];
    NSEnumerator *keys=[[self allKeys] objectEnumerator];
    while ((key=[keys nextObject])) {
        NSDictionary *value=[aDictionary objectForKey:key];
        if (!value && styleIDTransitionDictionary) {
        	NSString *otherKey = [styleIDTransitionDictionary objectForKey:key];
        	if (otherKey)
        	{
        		value = [aDictionary objectForKey:otherKey];
        		//NSLog(@"%s found transition %@->%@ : %@",__FUNCTION__,otherKey,key,value);
        	}
        }
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
        }
    }
    
    
}


- (NSArray *)allKeys {
    return I_keyArray;
}

- (void)addKey:(NSString *)aKey {
    if (![SyntaxStyleBaseIdentifier isEqualTo:aKey]) {
        if (![I_keyArray containsObject:aKey]) [I_keyArray addObject:aKey];
    }
}

- (NSMutableDictionary *)styleForScope:(NSString *)aScope {
    return [NSMutableDictionary dictionaryWithObjectsAndKeys:
            [NSColor redColor],@"color",[NSColor redColor],@"inverted-color",
            [NSColor whiteColor],@"background-color",[NSColor blackColor],@"inverted-background-color",
            [NSNumber numberWithUnsignedInt:0],@"font-trait",
            aScope,@"scope",
            aScope,kSyntaxHighlightingStyleIDAttributeName,nil];
// FIXME currently scope style is hardcoded, until there's UI
}

- (NSMutableDictionary *)styleForKey:(NSString *)aKey {
    return [I_styleDictionary objectForKey:aKey];
}

- (void)setStyle:(NSDictionary *)aStyle forKey:(NSString *)aKey {
    [I_styleDictionary setObject:[aStyle mutableCopy] forKey:aKey];
}

- (NSString *)localizedStringForKey:(NSString *)aKey {
    if ([aKey isEqualToString:SyntaxStyleBaseIdentifier]) {
        return NSLocalizedString(@"BaseStyleName",@"Name of base style appearing in Style Preferences");
    }
    NSBundle *bundle = [_documentMode bundle];
    if (bundle) {
        SyntaxDefinition *definition = [_documentMode syntaxDefinition];
        NSString *localizeKey = aKey;
        NSString *prefixString = [NSString stringWithFormat:@"/%@/",[definition name]];
        if ([aKey hasPrefix:prefixString]) {
            localizeKey = [aKey substringFromIndex:[prefixString length]];
        }
        NSString *result=[bundle localizedStringForKey:localizeKey value:localizeKey table:nil];
        int level = [definition levelForStyleID:aKey];
        return level?[NSString stringWithFormat:@"%@%@",[@"" stringByPaddingToLength:level*2 withString:@"                         " startingAtIndex:0],result]:result;
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
        }
    }
    return dictionary;
}


- (NSString *)xmlRepresentation {
    NSMutableString *result=[NSMutableString string];
    NSString *key=nil;
    int later=0;
    for (key in I_keyArray) {
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
    for (key in I_keyArray) {
        [result appendFormat:@"%@ (%@): %@\n",[self localizedStringForKey:key],key,[[I_styleDictionary objectForKey:key] description]];
    }
    return [NSString stringWithFormat:@"SyntaxStyle: \n%@",[self xmlFileRepresentation]];
}


@end
