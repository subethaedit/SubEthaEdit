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
#import "RegexSymbolDefinition.h"


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
NSString * const DocumentModeRowsPreferenceKey                 = @"Rows";
NSString * const DocumentModeColumnsPreferenceKey              = @"Columns";
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
    [defaultablePreferenceKeys setObject:DocumentModeUseDefaultViewPreferenceKey
                                  forKey:DocumentModeRowsPreferenceKey];
    [defaultablePreferenceKeys setObject:DocumentModeUseDefaultViewPreferenceKey
                                  forKey:DocumentModeColumnsPreferenceKey];
                                  
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
        I_autocompleteDictionary = [NSMutableArray new];
        I_bundle = [aBundle retain];
        SyntaxDefinition *synDef = [[[SyntaxDefinition alloc] initWithFile:[aBundle pathForResource:@"SyntaxDefinition" ofType:@"xml"] forMode:self] autorelease];
        RegexSymbolDefinition *symDef = [[[RegexSymbolDefinition alloc] initWithFile:[aBundle pathForResource:@"RegexSymbols" ofType:@"xml"] forMode:self] autorelease];
        
        if (synDef)
            I_syntaxHighlighter = [[SyntaxHighlighter alloc] initWithSyntaxDefinition:synDef];
        if (symDef)
            I_symbolParser = [[RegexSymbolParser alloc] initWithSymbolDefinition:symDef];
        
        // Add autocomplete additions
        NSString *autocompleteAdditionsPath = [aBundle pathForResource:@"AutocompleteAdditions" ofType:@"txt"];
        if (autocompleteAdditionsPath) {
            NSString *autocompleteAdditions = [NSString stringWithContentsOfFile:autocompleteAdditionsPath];
            [[self autocompleteDictionary] addObjectsFromArray:[autocompleteAdditions componentsSeparatedByString:@"\n"]];
        }
        
        // Sort the autocomplete dictionary
        [[self autocompleteDictionary] sortUsingSelector:@selector(caseInsensitiveCompare:)];
        
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
            [I_defaults setObject:[NSNumber numberWithInt:80] forKey:DocumentModeColumnsPreferenceKey];
            [I_defaults setObject:[NSNumber numberWithInt:40] forKey:DocumentModeRowsPreferenceKey];
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
    [I_symbolParser release];
    [I_autocompleteDictionary release];
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

- (RegexSymbolParser *)symbolParser {
    return I_symbolParser;
}

- (NSMutableArray *) autocompleteDictionary {
    return I_autocompleteDictionary;
}

- (BOOL)hasSymbols {
    return ![self isBaseMode];
}

- (NSArray *)symbolArrayForTextStorage:(NSTextStorage *)aTextStorage {
    RegexSymbolParser *symbolParser = [self symbolParser];
    NSArray *returnArray = [symbolParser symbolsForTextStorage:aTextStorage];
    return returnArray;
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
