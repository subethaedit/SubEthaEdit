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


NSString * const DocumentModeShowTopStatusBarPreferenceKey     = @"ShowBottomStatusBar";
NSString * const DocumentModeShowBottomStatusBarPreferenceKey  = @"ShowTopStatusBar";
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
NSString * const DocumentModeSpellCheckingPreferenceKey        = @"CheckSpelling";
NSString * const DocumentModeUseDefaultViewPreferenceKey       = @"UseDefaultView";
NSString * const DocumentModeUseDefaultEditPreferenceKey       = @"UseDefaultEdit";
NSString * const DocumentModeUseDefaultFilePreferenceKey       = @"UseDefaultFile";
NSString * const DocumentModeUseDefaultFontPreferenceKey       = @"UseDefaultFont";
NSString * const DocumentModeForegroundColorPreferenceKey      = @"ForegroundColor"  ;
NSString * const DocumentModeBackgroundColorPreferenceKey      = @"BackgroundColor"  ;
NSString * const DocumentModePrintInfoPreferenceKey            = @"PrintInfo"  ;
NSString * const DocumentModeUseDefaultPrintPreferenceKey      = @"UseDefaultPrint";

NSString * const DocumentModeExportPreferenceKey               = @"Export";
NSString * const DocumentModeExportHTMLPreferenceKey           = @"HTML";
NSString * const DocumentModeHTMLExportAddCurrentDatePreferenceKey   = @"AddCurrentDate"; 
NSString * const DocumentModeHTMLExportHighlightSyntaxPreferenceKey  = @"HighlightSyntax"; 
NSString * const DocumentModeHTMLExportShowAIMAndEmailPreferenceKey  = @"ShowAIMAndEmail"; 
NSString * const DocumentModeHTMLExportShowChangeMarksPreferenceKey  = @"ShowChangeMarks"; 
NSString * const DocumentModeHTMLExportShowParticipantsPreferenceKey = @"ShowParticipants"; 
NSString * const DocumentModeHTMLExportShowUserImagesPreferenceKey   = @"ShowUserImages"; 
NSString * const DocumentModeHTMLExportShowVisitorsPreferenceKey     = @"ShowVisitors"; 
NSString * const DocumentModeHTMLExportWrittenByHoversPreferenceKey  = @"WrittenByHovers"; 

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
    [defaultablePreferenceKeys setObject:DocumentModeUseDefaultViewPreferenceKey
                                  forKey:DocumentModeForegroundColorPreferenceKey];
    [defaultablePreferenceKeys setObject:DocumentModeUseDefaultViewPreferenceKey
                                  forKey:DocumentModeBackgroundColorPreferenceKey];
                                  
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

    [defaultablePreferenceKeys setObject:DocumentModeUseDefaultPrintPreferenceKey
                                  forKey:DocumentModePrintInfoPreferenceKey];
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
            NSValueTransformer *transformer=[NSValueTransformer valueTransformerForName:NSUnarchiveFromDataTransformerName];
            NSColor *color=[transformer transformedValue:[dictionary objectForKey:DocumentModeForegroundColorPreferenceKey]];
            if (!color) color=[NSColor blackColor];
            [dictionary setObject:color forKey:DocumentModeForegroundColorPreferenceKey];
            color=[transformer transformedValue:[dictionary objectForKey:DocumentModeBackgroundColorPreferenceKey]];
            if (!color) color=[NSColor whiteColor];
            [dictionary setObject:color forKey:DocumentModeBackgroundColorPreferenceKey];
            [self setDefaults:dictionary];
            NSNumber *encodingNumber = [dictionary objectForKey:DocumentModeEncodingPreferenceKey];
            if (encodingNumber) {
                NSStringEncoding encoding = [encodingNumber unsignedIntValue];
                [[EncodingManager sharedInstance] registerEncoding:encoding];
            }
            // retrofit preferences for pre 2.1
            if (![dictionary objectForKey:DocumentModeUseDefaultPrintPreferenceKey]) {
                [I_defaults setObject:[NSNumber numberWithBool:YES] 
                               forKey:DocumentModeUseDefaultPrintPreferenceKey];
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
            [I_defaults setObject:[NSNumber numberWithBool:YES] forKey:DocumentModeIndentNewLinesPreferenceKey];
            [I_defaults setObject:[NSNumber numberWithUnsignedInt:DocumentModeWrapModeWords] forKey:DocumentModeWrapModePreferenceKey];
            [I_defaults setObject:[NSNumber numberWithInt:LineEndingLF] forKey:DocumentModeLineEndingPreferenceKey];
            [I_defaults setObject:[NSColor blackColor] forKey:DocumentModeForegroundColorPreferenceKey];
            [I_defaults setObject:[NSColor whiteColor] forKey:DocumentModeBackgroundColorPreferenceKey];
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
                [I_defaults setObject:[NSNumber numberWithBool:YES] 
                               forKey:DocumentModeUseDefaultPrintPreferenceKey];
            }
        }

        // augment pre 2.1 data if needed
        if ([self isBaseMode]) {
            if (![I_defaults objectForKey:DocumentModePrintInfoPreferenceKey]) {
                NSPrintInfo *printInfo=[NSPrintInfo sharedPrintInfo];
                NSMutableDictionary *printInfoDictionary=[printInfo dictionary];
                [printInfoDictionary setObject:[NSNumber numberWithInt:0]
                                        forKey:@"SEEUseCustomFont"];
                [printInfoDictionary setObject:[NSNumber numberWithBool:YES]
                                        forKey:@"SEEResizeDocumentFont"];
                [printInfoDictionary setObject:[NSNumber numberWithFloat:8.5]
                                        forKey:@"SEEResizeDocumentFontTo"];
                [printInfoDictionary setObject:[NSNumber numberWithBool:YES]
                                        forKey:@"SEEPageHeader"];
                [printInfoDictionary setObject:[NSNumber numberWithBool:YES]
                                        forKey:@"SEEPageHeaderFilename"];
                [printInfoDictionary setObject:[NSNumber numberWithBool:YES]
                                        forKey:@"SEEPageHeaderCurrentDate"];
                [printInfoDictionary setObject:[NSNumber numberWithBool:YES]
                                        forKey:@"SEEHighlightSyntax"];
                [printInfoDictionary setObject:[NSNumber numberWithBool:YES]
                                        forKey:@"SEEColorizeChangeMarks"];
                [printInfoDictionary setObject:[NSNumber numberWithBool:YES]
                                        forKey:@"SEEAnnotateChangeMarks"];
                [printInfoDictionary setObject:[NSNumber numberWithBool:NO]
                                        forKey:@"SEEColorizeWrittenBy"];
                [printInfoDictionary setObject:[NSNumber numberWithBool:YES]
                                        forKey:@"SEEAnnotateWrittenBy"];
                [printInfoDictionary setObject:[NSNumber numberWithBool:YES]
                                        forKey:@"SEEParticipants"];
                [printInfoDictionary setObject:[NSNumber numberWithBool:YES]
                                        forKey:@"SEEParticipantImages"];
                [printInfoDictionary setObject:[NSNumber numberWithBool:YES]
                                        forKey:@"SEEParticipantsAIMAndEmail"];
                [printInfoDictionary setObject:[NSNumber numberWithBool:YES]
                                        forKey:@"SEEParticipantsVisitors"];
                NSFont *font=[NSFont fontWithName:@"Times" size:8.5];
                if (!font) font=[NSFont systemFontOfSize:8.5];
                NSMutableDictionary *dict=[NSMutableDictionary dictionary];
                [dict setObject:[font fontName] 
                         forKey:NSFontNameAttribute];
                [dict setObject:[NSNumber numberWithFloat:8.5] 
                         forKey:NSFontSizeAttribute];
                [printInfoDictionary setObject:dict forKey:@"SEEFontAttributes"];
                float cmToPoints=28.3464567; // google
                [printInfo   setLeftMargin:2.5*cmToPoints]; // european punchholes are centered 1.2 cm and 0.5cm in diameter
                [printInfo  setRightMargin:1.0*cmToPoints];
                [printInfo    setTopMargin:1.0*cmToPoints];
                [printInfo setBottomMargin:1.0*cmToPoints];
                [I_defaults setObject:[NSKeyedArchiver archivedDataWithRootObject:printInfo]
                               forKey:DocumentModePrintInfoPreferenceKey];
            }
        }

        NSMutableDictionary *export=[I_defaults objectForKey:DocumentModeExportPreferenceKey];
        export = export?[[export mutableCopy] autorelease]:[NSMutableDictionary dictionary];
        [I_defaults setObject:export forKey:DocumentModeExportPreferenceKey];

        NSMutableDictionary *html=[export objectForKey:DocumentModeExportHTMLPreferenceKey];
        if (!html) {
            NSNumber *yes=[NSNumber numberWithBool:YES];
            html=[NSMutableDictionary dictionaryWithObjectsAndKeys:
                yes,DocumentModeHTMLExportAddCurrentDatePreferenceKey  ,
                yes,DocumentModeHTMLExportHighlightSyntaxPreferenceKey ,
                yes,DocumentModeHTMLExportShowAIMAndEmailPreferenceKey ,
                yes,DocumentModeHTMLExportShowChangeMarksPreferenceKey ,
                yes,DocumentModeHTMLExportShowParticipantsPreferenceKey,
                yes,DocumentModeHTMLExportShowUserImagesPreferenceKey  ,
                yes,DocumentModeHTMLExportShowVisitorsPreferenceKey    ,
                yes,DocumentModeHTMLExportWrittenByHoversPreferenceKey ,
                nil];
        } else {
            html=[[html mutableCopy] autorelease];
        }
        [export setObject:html forKey:DocumentModeExportHTMLPreferenceKey];
        
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

- (void)writeDefaults {
    NSMutableDictionary *defaults=[[self defaults] mutableCopy];
    NSValueTransformer *transformer=[NSValueTransformer valueTransformerForName:NSUnarchiveFromDataTransformerName];
    NSData *data=[transformer reverseTransformedValue:[defaults objectForKey:DocumentModeForegroundColorPreferenceKey]];
    if (!data) data=[transformer reverseTransformedValue:[NSColor blackColor]];
    [defaults setObject:data forKey:DocumentModeForegroundColorPreferenceKey];
    data=[transformer reverseTransformedValue:[defaults objectForKey:DocumentModeBackgroundColorPreferenceKey]];
    if (!data) data=[transformer reverseTransformedValue:[NSColor whiteColor]];
    [defaults setObject:data forKey:DocumentModeBackgroundColorPreferenceKey];
    [[NSUserDefaults standardUserDefaults] setObject:defaults forKey:[[self bundle] bundleIdentifier]];
}

#pragma mark -
#pragma mark ### Notification Handling ###

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [self writeDefaults];
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
