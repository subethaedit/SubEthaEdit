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
    return [I_styleDictionary allKeys];
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

- (NSString *)description {
    NSMutableString *localizedString=[NSMutableString string];
    NSString *key=nil;
    NSEnumerator *keys=[I_styleDictionary keyEnumerator];
    while ((key=[keys nextObject])) {
        [localizedString appendFormat:@"%@ (%@)\n",[self localizedStringForKey:key],key];
    }
    return [NSString stringWithFormat:@"SyntaxStyle: %@",localizedString];
}

@end
