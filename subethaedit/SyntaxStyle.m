//
//  SyntaxStyle.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 11.10.04.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "SyntaxStyle.h"


@implementation SyntaxStyle

- (id)init {
    self=[super init];
    if (self) {
        I_styleDictionary = [NSMutableDictionary new];
        I_documentMode =nil;
        I_keyArray = [NSMutableArray new];
    }
    return self;
}

- (void)dealloc {
    [I_documentMode release];
    [I_styleDictionary release];
    [super dealloc];
}

- (void)setDocumentMode:(DocumentMode *)aMode {
    [I_documentMode autorelease];
     I_documentMode = [aMode retain];
}

- (DocumentMode *)documentMode {
    return I_documentMode;
}


- (NSArray *)allKeys {
    return I_keyArray;
}

- (void)addKey:(NSString *)aKey {
    [I_keyArray addObject:aKey];
}


- (NSMutableDictionary *)styleForKey:(NSString *)aKey {
    return [I_styleDictionary objectForKey:aKey];
}

- (void)setStyle:(NSDictionary *)aStyle forKey:(NSString *)aKey {
    [I_styleDictionary setObject:[[aStyle mutableCopy] autorelease] forKey:aKey];
}

- (NSString *)localizedStringForKey:(NSString *)aKey {
    NSBundle *bundle = [I_documentMode bundle];
    if (bundle) {
        NSString *localizeKey=[[aKey componentsSeparatedByString:@"."] lastObject];
        return [bundle localizedStringForKey:localizeKey value:localizeKey table:nil];
    } else {
        return aKey;
    }
}

- (NSString *)xmlRepresentation {
    NSMutableString *result=[NSMutableString string];
    NSString *key=nil;
    NSEnumerator *keys=[I_keyArray objectEnumerator];
    while ((key=[keys nextObject])) {
        NSDictionary *style=[I_styleDictionary objectForKey:key];
        NSFontTraitMask traits=[[style objectForKey:@"font-trait"] unsignedIntValue];
        [result appendFormat:@"  <style id=\"%@\"\n    color=\"%@\" inverted-color=\"%@\"  font-style=\"%@\" font-weight=\"%@\" />\n",
            key,[[style objectForKey:@"color"] HTMLString],[[style objectForKey:@"inverted-color"] HTMLString],
            traits & NSItalicFontMask?@"italic":@"normal",
            traits & NSBoldFontMask  ?@"bold"  :@"normal"];
    }
    return [NSString stringWithFormat:@"<mode id=\"%@\">\n%@</mode>",[[self documentMode] documentModeIdentifier],result];

}

- (NSString *)xmlFileRepresentation {
    return [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<seestyle>\n%@\n</seestyle>",[self xmlRepresentation]];
}


- (NSString *)description {
    NSMutableString *localizedString=[NSMutableString string];
    NSString *key=nil;
    NSEnumerator *keys=[I_keyArray objectEnumerator];
    while ((key=[keys nextObject])) {
        [localizedString appendFormat:@"%@ (%@): %@\n",[self localizedStringForKey:key],key,[[I_styleDictionary objectForKey:key] description]];
    }
    return [NSString stringWithFormat:@"SyntaxStyle: \n%@",[self xmlFileRepresentation]];
}


@end
