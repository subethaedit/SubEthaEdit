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


NSString * const DocumentModeEncodingPreferenceKey             = @"Encoding";
NSString * const DocumentModeFontAttributesPreferenceKey       = @"FontAttributes";
NSString * const DocumentModeHighlightSyntaxPreferenceKey      = @"HighlightSyntax";
NSString * const DocumentModeIndentNewLinesPreferenceKey       = @"IndentNewLines";
NSString * const DocumentModeLineEndingPreferenceKey           = @"LineEnding";
NSString * const DocumentModeShowLineNumbersPreferenceKey      = @"ShowLineNumbers";
NSString * const DocumentModeShowMatchingBracketsPreferenceKey = @"ShowMatchingBrackets";
NSString * const DocumentModeTabWidthPreferenceKey             = @"TabWidth";
NSString * const DocumentModeUseTabsPreferenceKey              = @"UseTabs";
NSString * const DocumentModeWrapLinesPreferenceKey            = @"WrapLines";
NSString * const DocumentModeUseDefaultSyntaxPreferenceKey     = @"UseDefaultSyntax";
NSString * const DocumentModeUseDefaultEditPreferenceKey       = @"UseDefaultEdit";
NSString * const DocumentModeUseDefaultFilePreferenceKey       = @"UseDefaultFile";
NSString * const DocumentModeUseDefaultFontPreferenceKey       = @"UseDefaultFont";

static NSMutableDictionary *defaultablePreferenceKeys = nil;

@implementation DocumentMode

+ (void) initialize {
    defaultablePreferenceKeys=[NSMutableDictionary new];
    [defaultablePreferenceKeys setObject:DocumentModeUseDefaultSyntaxPreferenceKey
                                  forKey:DocumentModeHighlightSyntaxPreferenceKey];
                                  
    [defaultablePreferenceKeys setObject:DocumentModeUseDefaultEditPreferenceKey
                                  forKey:DocumentModeUseTabsPreferenceKey];
    [defaultablePreferenceKeys setObject:DocumentModeUseDefaultEditPreferenceKey
                                  forKey:DocumentModeIndentNewLinesPreferenceKey];
    [defaultablePreferenceKeys setObject:DocumentModeUseDefaultEditPreferenceKey
                                  forKey:DocumentModeShowMatchingBracketsPreferenceKey];
    [defaultablePreferenceKeys setObject:DocumentModeUseDefaultEditPreferenceKey
                                  forKey:DocumentModeWrapLinesPreferenceKey];
    [defaultablePreferenceKeys setObject:DocumentModeUseDefaultEditPreferenceKey
                                  forKey:DocumentModeShowLineNumbersPreferenceKey];
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
            [I_defaults setObject:[NSNumber numberWithInt:3] forKey:DocumentModeTabWidthPreferenceKey];
            NSFont *font=[NSFont userFixedPitchFontOfSize:0.0];
            NSMutableDictionary *dict=[NSMutableDictionary dictionary];
            [dict setObject:[font fontName] 
                     forKey:NSFontNameAttribute];
            [dict setObject:[NSNumber numberWithFloat:[font pointSize]] 
                     forKey:NSFontSizeAttribute];
            [I_defaults setObject:dict forKey:DocumentModeFontAttributesPreferenceKey];
            [I_defaults setObject:[NSNumber numberWithUnsignedInt:NoStringEncoding] forKey:DocumentModeEncodingPreferenceKey];
            [[EncodingManager sharedInstance] registerEncoding:NoStringEncoding];
            if (![self isBaseMode]) {
                // read frome modefile? for now use defaults
                [I_defaults setObject:[NSNumber numberWithBool:YES] 
                               forKey:DocumentModeUseDefaultSyntaxPreferenceKey];
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

- (SyntaxHighlighter *)syntaxHighlighter {
    return I_syntaxHighlighter;
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
