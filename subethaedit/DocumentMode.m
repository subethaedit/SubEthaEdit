//
//  DocumentMode.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Mon Mar 22 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "DocumentMode.h"
#import "DocumentModeManager.h"
#import "SyntaxHighlighter.h"
#import "SyntaxDefinition.h"
#import "EncodingManager.h"
#import "SymbolTableEntry.h"
#import "RegexSymbolParser.h"


NSString * const DocumentModeEncodingPreferenceKey             = @"Encoding";
NSString * const DocumentModeFontAttributesPreferenceKey       = @"FontAttributes";
NSString * const DocumentModeHighlightSyntaxPreferenceKey      = @"HighlightSyntax";
NSString * const DocumentModeIndentNewLinesPreferenceKey       = @"IndentNewLines";
NSString * const DocumentModeLineEndingPreferenceKey           = @"LineEnding";
NSString * const DocumentModeShowLineNumbersPreferenceKey      = @"ShowLineNumbers";
NSString * const DocumentModeShowMatchingBracketsPreferenceKey = @"ShowMatchingBrackets";
NSString * const DocumentModeShowInvisibleCharactersPreferenceKey = @"ShowInvisibleCharacters";
NSString * const DocumentModeTabWidthPreferenceKey             = @"TabWidth";
NSString * const DocumentModeUseTabsPreferenceKey              = @"UseTabs";
NSString * const DocumentModeWrapLinesPreferenceKey            = @"WrapLines";
NSString * const DocumentModeWrapModePreferenceKey             = @"WrapMode";
NSString * const DocumentModeUseDefaultViewPreferenceKey       = @"UseDefaultView";
NSString * const DocumentModeUseDefaultEditPreferenceKey       = @"UseDefaultEdit";
NSString * const DocumentModeUseDefaultFilePreferenceKey       = @"UseDefaultFile";
NSString * const DocumentModeUseDefaultFontPreferenceKey       = @"UseDefaultFont";

static NSMutableDictionary *defaultablePreferenceKeys = nil;

@implementation DocumentMode

+ (void)initialize {
    defaultablePreferenceKeys=[NSMutableDictionary new];
    [defaultablePreferenceKeys setObject:DocumentModeUseDefaultViewPreferenceKey
                                  forKey:DocumentModeHighlightSyntaxPreferenceKey];
    [defaultablePreferenceKeys setObject:DocumentModeUseDefaultViewPreferenceKey
                                  forKey:DocumentModeShowMatchingBracketsPreferenceKey];
    [defaultablePreferenceKeys setObject:DocumentModeUseDefaultViewPreferenceKey
                                  forKey:DocumentModeShowInvisibleCharactersPreferenceKey];
    [defaultablePreferenceKeys setObject:DocumentModeUseDefaultViewPreferenceKey
                                  forKey:DocumentModeWrapLinesPreferenceKey];
    [defaultablePreferenceKeys setObject:DocumentModeUseDefaultViewPreferenceKey
                                  forKey:DocumentModeWrapModePreferenceKey];
    [defaultablePreferenceKeys setObject:DocumentModeUseDefaultViewPreferenceKey
                                  forKey:DocumentModeShowLineNumbersPreferenceKey];
                                  
    [defaultablePreferenceKeys setObject:DocumentModeUseDefaultEditPreferenceKey
                                  forKey:DocumentModeUseTabsPreferenceKey];
    [defaultablePreferenceKeys setObject:DocumentModeUseDefaultEditPreferenceKey
                                  forKey:DocumentModeIndentNewLinesPreferenceKey];
    [defaultablePreferenceKeys setObject:DocumentModeUseDefaultEditPreferenceKey
                                  forKey:DocumentModeTabWidthPreferenceKey];

    [defaultablePreferenceKeys setObject:DocumentModeUseDefaultFilePreferenceKey
                                  forKey:DocumentModeEncodingPreferenceKey];
    [defaultablePreferenceKeys setObject:DocumentModeUseDefaultFilePreferenceKey
                                  forKey:DocumentModeLineEndingPreferenceKey];

    [defaultablePreferenceKeys setObject:DocumentModeUseDefaultFontPreferenceKey
                                  forKey:DocumentModeFontAttributesPreferenceKey];
}

- (id)initWithBundle:(NSBundle *)aBundle {
    self = [super init];
    if (self) {
        I_bundle = [aBundle retain];
        SyntaxDefinition *synDef = [[[SyntaxDefinition alloc] initWithFile:[aBundle pathForResource:@"SyntaxDefinition" ofType:@"xml"]] autorelease];
        I_syntaxHighlighter = [[SyntaxHighlighter alloc] initWithSyntaxDefinition:synDef];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:NSApplicationWillTerminateNotification object:nil];
        NSMutableDictionary *dictionary=[[[[NSUserDefaults standardUserDefaults] objectForKey:[[self bundle] bundleIdentifier]] mutableCopy] autorelease];
        if (dictionary) {
            [self setDefaults:dictionary];
            NSNumber *encodingNumber = [dictionary objectForKey:DocumentModeEncodingPreferenceKey];
            if (encodingNumber) {
                NSStringEncoding encoding = [encodingNumber unsignedIntValue];
                [[EncodingManager sharedInstance] registerEncoding:encoding];
            }
        } else {
            I_defaults = [NSMutableDictionary new];
            [I_defaults setObject:[NSNumber numberWithInt:4] forKey:DocumentModeTabWidthPreferenceKey];
            NSFont *font=[NSFont userFixedPitchFontOfSize:0.0];
            NSMutableDictionary *dict=[NSMutableDictionary dictionary];
            [dict setObject:[font fontName] 
                     forKey:NSFontNameAttribute];
            [dict setObject:[NSNumber numberWithFloat:[font pointSize]] 
                     forKey:NSFontSizeAttribute];
            [I_defaults setObject:dict forKey:DocumentModeFontAttributesPreferenceKey];
            [I_defaults setObject:[NSNumber numberWithUnsignedInt:NoStringEncoding] forKey:DocumentModeEncodingPreferenceKey];
            [I_defaults setObject:[NSNumber numberWithBool:YES] forKey:DocumentModeHighlightSyntaxPreferenceKey];
            [I_defaults setObject:[NSNumber numberWithBool:NO]  forKey:DocumentModeShowLineNumbersPreferenceKey];
            [I_defaults setObject:[NSNumber numberWithBool:NO]  forKey:DocumentModeShowInvisibleCharactersPreferenceKey];
            [I_defaults setObject:[NSNumber numberWithBool:YES] forKey:DocumentModeShowMatchingBracketsPreferenceKey];
            [I_defaults setObject:[NSNumber numberWithBool:YES] forKey:DocumentModeWrapLinesPreferenceKey];
            [I_defaults setObject:[NSNumber numberWithUnsignedInt:DocumentModeWrapModeWords] forKey:DocumentModeWrapModePreferenceKey];
            [I_defaults setObject:[NSNumber numberWithInt:LineEndingLF] forKey:DocumentModeLineEndingPreferenceKey];
            [[EncodingManager sharedInstance] registerEncoding:NoStringEncoding];
            if (![self isBaseMode]) {
                // read frome modefile? for now use defaults
                [I_defaults setObject:[NSNumber numberWithBool:YES] 
                               forKey:DocumentModeUseDefaultViewPreferenceKey];
                [I_defaults setObject:[NSNumber numberWithBool:YES] 
                               forKey:DocumentModeUseDefaultEditPreferenceKey];
                [I_defaults setObject:[NSNumber numberWithBool:YES] 
                               forKey:DocumentModeUseDefaultFilePreferenceKey];
                [I_defaults setObject:[NSNumber numberWithBool:YES] 
                               forKey:DocumentModeUseDefaultFontPreferenceKey];
            }
        }
        
        [I_defaults addObserver:self
                     forKeyPath:DocumentModeEncodingPreferenceKey
                        options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
                        context:NULL];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [I_defaults release];
    [I_syntaxHighlighter release];
    [I_bundle release];
    [super dealloc];
}

- (NSBundle *)bundle {
    return I_bundle;
}

- (NSString *)documentModeIdentifier {
    return [[I_bundle infoDictionary] objectForKey:@"CFBundleIdentifier"];
}

- (NSString *)displayName {
    return [[I_bundle localizedInfoDictionary] objectForKey:@"CFBundleName"];
}

- (SyntaxHighlighter *)syntaxHighlighter {
    return I_syntaxHighlighter;
}

- (BOOL)hasSymbols {
    return ![self isBaseMode];
}

- (NSArray *)symbolArrayForTextStorage:(NSTextStorage *)aTextStorage {
    RegexSymbolParser *symbolParser = [[RegexSymbolParser init]alloc];
    NSArray *returnArray = [symbolParser symbolsForTextStorage:aTextStorage];
    [RegexSymbolParser release];
    return returnArray;

    /*NSMutableArray *array=[NSMutableArray array];
    [array addObject:
        [SymbolTableEntry symbolTableEntryWithName:@"@class MainClass" 
            fontTraitMask:NSBoldFontMask | NSItalicFontMask image:[NSImage imageNamed:@"SymbolC"] 
            type:@"Class" jumpRange:NSMakeRange (5,10) range:NSMakeRange(4,100)]];
    [array addObject:
        [SymbolTableEntry symbolTableEntryWithName:@"-blah:" 
            fontTraitMask:NSItalicFontMask image:[NSImage imageNamed:@"SymbolM"] 
            type:@"Method" jumpRange:NSMakeRange (14,10) range:NSMakeRange(14,20)]];
    [array addObject:
        [SymbolTableEntry symbolTableEntryWithName:@"-fasel:" 
            fontTraitMask:NSItalicFontMask image:[NSImage imageNamed:@"SymbolM"] 
            type:@"Method" jumpRange:NSMakeRange (36,10) range:NSMakeRange(36,20)]];
    [array addObject:
        [SymbolTableEntry symbolTableEntrySeparator]];
    [array addObject:
        [SymbolTableEntry symbolTableEntryWithName:@"@class MainClass" 
            fontTraitMask:NSBoldFontMask image:[NSImage imageNamed:@"SymbolC"] 
            type:@"Class" jumpRange:NSMakeRange (65,10) range:NSMakeRange(64,100)]];
    [array addObject:
        [SymbolTableEntry symbolTableEntryWithName:@"-blah:" 
            fontTraitMask:0 image:[NSImage imageNamed:@"SymbolM"] 
            type:@"Method" jumpRange:NSMakeRange (74,10) range:NSMakeRange(74,20)]];
    [array addObject:
        [SymbolTableEntry symbolTableEntryWithName:@"-fasel:" 
            fontTraitMask:0 image:[NSImage imageNamed:@"SymbolM"] 
            type:@"Method" jumpRange:NSMakeRange (106,10) range:NSMakeRange(106,20)]];
    return array;*/
}


- (NSMutableDictionary *)defaults {
    return I_defaults;
}
- (void)setDefaults:(NSMutableDictionary *)defaults {
    [I_defaults autorelease];
    I_defaults=[defaults retain];
}

- (id)defaultForKey:(NSString *)aKey {
    NSDictionary *defaultDefaults=[[[DocumentModeManager sharedInstance] baseMode] defaults];
    if (![self isBaseMode]) {
        NSString *defaultKey=[defaultablePreferenceKeys objectForKey:aKey];
        if (!defaultKey || ![[I_defaults objectForKey:defaultKey] boolValue]) {
            return [I_defaults objectForKey:aKey];
        }
    }
    return [defaultDefaults objectForKey:aKey];
}

- (BOOL)isBaseMode {
    return [BASEMODEIDENTIFIER isEqualToString:[[self bundle] bundleIdentifier]];
}

#pragma mark -
#pragma mark ### Notification Handling ###

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [[NSUserDefaults standardUserDefaults] setObject:[self defaults] forKey:[[self bundle] bundleIdentifier]];
}

#pragma mark -

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:DocumentModeEncodingPreferenceKey]) {
        NSNumber *oldEncodingNumber = [change objectForKey:NSKeyValueChangeOldKey];
        if (oldEncodingNumber) {
            [[EncodingManager sharedInstance] unregisterEncoding:[oldEncodingNumber unsignedIntValue]];
        }
        NSNumber *newEncodingNumber = [change objectForKey:NSKeyValueChangeNewKey];
        if (newEncodingNumber) {
            [[EncodingManager sharedInstance] registerEncoding:[newEncodingNumber unsignedIntValue]];
        }
    }
}

@end
