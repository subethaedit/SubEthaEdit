//
//  SyntaxStyle.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 11.10.04.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "SyntaxStyle.h"

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
    return [NSString stringWithFormat:@"<mode id=\"%@\">\n%@</mode>",[[self documentMode] documentModeIdentifier],result];

}

- (NSString *)xmlFileRepresentation {
    return [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<seestyle>\n%@\n</seestyle>",[self xmlRepresentation]];
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
