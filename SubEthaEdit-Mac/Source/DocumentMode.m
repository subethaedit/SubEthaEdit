//  DocumentMode.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Mon Mar 22 2004.

#import "DocumentMode.h"
#import "DocumentModeManager.h"
#import "ModeSettings.h"
#import "SyntaxHighlighter.h"
#import "SyntaxDefinition.h"
#import "SEEStyleSheet.h"
#import "SyntaxStyle.h"
#import "EncodingManager.h"
#import "SymbolTableEntry.h"
#import "RegexSymbolParser.h"
#import "RegexSymbolDefinition.h"
#import "SEEWebPreview.h"
#import "NSMenuTCMAdditions.h"
#import "ScriptWrapper.h"
#import "AppController.h"

NSString * const DocumentModeDocumentInfoTypePreferenceKey     = @"DocumentInfoType";
NSString * const DocumentModeShowTopStatusBarPreferenceKey     = @"ShowBottomStatusBar";
NSString * const DocumentModeShowBottomStatusBarPreferenceKey  = @"ShowTopStatusBar";
NSString * const DocumentModeEncodingPreferenceKey             = @"Encoding";
NSString * const DocumentModeUTF8BOMPreferenceKey              = @"UTF8BOM";
NSString * const DocumentModeFontAttributesPreferenceKey       = @"FontAttributes";
NSString * const DocumentModeHighlightSyntaxPreferenceKey      = @"HighlightSyntax";
NSString * const DocumentModeIndentNewLinesPreferenceKey       = @"IndentNewLines";
NSString * const DocumentModeTabKeyReplacesSelectionPreferenceKey  = @"TabKeyReplacesSelection";
NSString * const DocumentModeTabKeyMovesToIndentPreferenceKey  = @"TabKeyMovesToIndent";
NSString * const DocumentModeLineEndingPreferenceKey           = @"LineEnding";
NSString * const DocumentModeShowLineNumbersPreferenceKey      = @"ShowLineNumbers";
NSString * const DocumentModeShowMatchingBracketsPreferenceKey = @"ShowMatchingBrackets";
NSString * const DocumentModeShowInvisibleCharactersPreferenceKey = @"ShowInvisibleCharacters";
NSString * const DocumentModeShowInconsistentIndentationPreferenceKey = @"ShowInconsistentIndentation";
NSString * const DocumentModeTabWidthPreferenceKey             = @"TabWidth";
NSString * const DocumentModeUseTabsPreferenceKey              = @"UseTabs";
NSString * const DocumentModeWrapLinesPreferenceKey            = @"WrapLines";
NSString * const DocumentModeIndentWrappedLinesPreferenceKey   = @"IndentWrappedLines";
NSString * const DocumentModeIndentWrappedLinesCharacterAmountPreferenceKey   = @"IndentWrappedLinesCharacterAmount";
NSString * const DocumentModeShowPageGuidePreferenceKey        = @"ShowPageGuide";
NSString * const DocumentModePageGuideWidthPreferenceKey       = @"PageGuideWidth";
NSString * const DocumentModeWrapModePreferenceKey             = @"WrapMode";
NSString * const DocumentModeRowsPreferenceKey                 = @"Rows";
NSString * const DocumentModeColumnsPreferenceKey              = @"Columns";
NSString * const DocumentModeSpellCheckingPreferenceKey        = @"CheckSpelling";

// snow leopard additions
NSString * const DocumentModeGrammarCheckingPreferenceKey             = @"CheckGrammar";
NSString * const DocumentModeAutomaticLinkDetectionPreferenceKey      = @"AutomaticLinkDetection";
NSString * const DocumentModeAutomaticDashSubstitutionPreferenceKey   = @"AutomaticDashSubstitution";
NSString * const DocumentModeAutomaticQuoteSubstitutionPreferenceKey  = @"AutomaticQuoteSubstitution";
NSString * const DocumentModeAutomaticTextReplacementPreferenceKey    = @"AutomaticTextReplacement";
NSString * const DocumentModeAutomaticSpellingCorrectionPreferenceKey = @"AutomaticSpellingCorrection";


NSString * const DocumentModeUseDefaultViewPreferenceKey       = @"UseDefaultView";
NSString * const DocumentModeUseDefaultEditPreferenceKey       = @"UseDefaultEdit";
NSString * const DocumentModeUseDefaultFilePreferenceKey       = @"UseDefaultFile";
NSString * const DocumentModeUseDefaultFontPreferenceKey       = @"UseDefaultFont";
NSString * const DocumentModePrintInfoPreferenceKey            = @"PrintInfo"  ;
NSString * const DocumentModePrintOptionsPreferenceKey         = @"PrintOptions"  ;
NSString * const DocumentModeUseDefaultStylePreferenceKey      = @"UseDefaultStyle";
NSString * const DocumentModeSyntaxStylePreferenceKey          = @"SyntaxStyle";
NSString * const DocumentModeUseDefaultStyleSheetPreferenceKey = @"UseDefaultStyleSheet";
NSString * const DocumentModeStyleSheetsPreferenceKey          = @"StyleSheets";
NSString * const DocumentModeStyleSheetsDefaultLanguageContextKey = @"DocumentModeStyleSheetDefaultLanguageContext";

NSString * const DocumentModeBackgroundColorIsDarkPreferenceKey= @"BackgroundColorIsDark"  ;
NSString * const DocumentModeCurrentLineHighlightColorPreferenceKey = @"CurrentLineHighlightColor"  ;
// depricated
NSString * const DocumentModeForegroundColorPreferenceKey      = @"ForegroundColor"  ;
NSString * const DocumentModeBackgroundColorPreferenceKey      = @"BackgroundColor"  ;


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

NSString * const DocumentModeApplyEditPreferencesNotification  =
               @"DocumentModeApplyEditPreferencesNotification";
NSString * const DocumentModeApplyStylePreferencesNotification =
               @"DocumentModeApplyStylePreferencesNotification";

static NSMutableDictionary *defaultablePreferenceKeys = nil;

@interface DocumentMode ()
@property (nonatomic, readwrite) BOOL isBaseMode;
@end

@implementation DocumentMode

+ (void)initialize {
	if (self == [DocumentMode class]) {
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
                                      forKey:DocumentModeShowInconsistentIndentationPreferenceKey];
		[defaultablePreferenceKeys setObject:DocumentModeUseDefaultViewPreferenceKey
									  forKey:DocumentModeIndentWrappedLinesPreferenceKey];
		[defaultablePreferenceKeys setObject:DocumentModeUseDefaultViewPreferenceKey
									  forKey:DocumentModeIndentWrappedLinesCharacterAmountPreferenceKey];
		[defaultablePreferenceKeys setObject:DocumentModeUseDefaultViewPreferenceKey
									  forKey:DocumentModeShowPageGuidePreferenceKey];
		[defaultablePreferenceKeys setObject:DocumentModeUseDefaultViewPreferenceKey
									  forKey:DocumentModePageGuideWidthPreferenceKey];
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
		[defaultablePreferenceKeys setObject:DocumentModeUseDefaultEditPreferenceKey
									  forKey:DocumentModeTabKeyMovesToIndentPreferenceKey];
		[defaultablePreferenceKeys setObject:DocumentModeUseDefaultEditPreferenceKey
									  forKey:DocumentModeTabKeyReplacesSelectionPreferenceKey];
	
		[defaultablePreferenceKeys setObject:DocumentModeUseDefaultFilePreferenceKey
									  forKey:DocumentModeEncodingPreferenceKey];
		[defaultablePreferenceKeys setObject:DocumentModeUseDefaultFilePreferenceKey
									  forKey:DocumentModeLineEndingPreferenceKey];
		[defaultablePreferenceKeys setObject:DocumentModeUseDefaultFilePreferenceKey
									  forKey:DocumentModeUTF8BOMPreferenceKey];
	
		[defaultablePreferenceKeys setObject:DocumentModeUseDefaultFontPreferenceKey
									  forKey:DocumentModeFontAttributesPreferenceKey];
	
		[defaultablePreferenceKeys setObject:DocumentModeUseDefaultStylePreferenceKey
									  forKey:DocumentModeBackgroundColorIsDarkPreferenceKey];

		[defaultablePreferenceKeys setObject:DocumentModeUseDefaultStylePreferenceKey
									  forKey:DocumentModeCurrentLineHighlightColorPreferenceKey];

		[defaultablePreferenceKeys setObject:DocumentModeUseDefaultStyleSheetPreferenceKey
									  forKey:DocumentModeStyleSheetsPreferenceKey];		
	}
}

#define SCRIPTMODEMENUTAGBASE 4000
#define SEEENGINEVERSION 4.0

+ (BOOL)canParseModeVersionOfBundle:(NSBundle *)aBundle { 
    double requiredEngineVersion = 0; 
    
    CFURLRef url = CFURLCreateWithFileSystemPath(NULL, (CFStringRef) [aBundle bundlePath], kCFURLPOSIXPathStyle, 1);
    CFDictionaryRef infodict = CFBundleCopyInfoDictionaryInDirectory(url);
    NSDictionary *infoDictionary = (NSDictionary *) CFBridgingRelease(infodict);
    NSString *minEngine = [infoDictionary objectForKey:@"SEEMinimumEngineVersion"]; 

    if ( minEngine != nil ) // nil check prevents bug on 10.4, where doubleValue returns garbage 
        requiredEngineVersion = [minEngine doubleValue]; 
    
    CFRelease(url);

    return (requiredEngineVersion<=SEEENGINEVERSION); 
}


- (instancetype)initWithBundle:(NSBundle *)aBundle {
    self = [super init];
    if (self) {
        _autocompleteDictionary = [NSMutableArray new];
        _bundle = aBundle;

		self.isBaseMode = [BASEMODEIDENTIFIER isEqualToString:[[self bundle] bundleIdentifier]];
		
		_styleIDTransitionDictionary = [[NSMutableDictionary alloc] initWithContentsOfFile:[aBundle pathForResource:@"StyleIDTransition" ofType:@"plist"]];

        _modeSettings = [[ModeSettings alloc] initWithFile:[aBundle pathForResource:@"ModeSettings" ofType:@"xml"]];
		if (!_modeSettings) { // Fall back to info.plist
			_modeSettings = [[ModeSettings alloc] initWithPlist:[aBundle bundlePath]];
		}
		
		// already puts some autocomplete in the autocomplete dict
        _syntaxDefinition = [[SyntaxDefinition alloc] initWithFile:[aBundle pathForResource:@"SyntaxDefinition" ofType:@"xml"] forMode:self];
        
        RegexSymbolDefinition *symDef = [[RegexSymbolDefinition alloc] initWithFile:[aBundle pathForResource:@"RegexSymbols" ofType:@"xml"] forMode:self];
        
        if (_syntaxDefinition && ![self isBaseMode]) {
            _syntaxHighlighter = [[SyntaxHighlighter alloc] initWithSyntaxDefinition:_syntaxDefinition];
		}
        if (symDef) {
            _symbolParser = [[RegexSymbolParser alloc] initWithSymbolDefinition:symDef];
		}
        
        // Add autocomplete additions
		NSURL *autocompleteAdditionsURL = [aBundle URLForResource:@"AutocompleteAdditions" withExtension:@"txt"];
		if (autocompleteAdditionsURL) {
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
				// TODO: do a more performant read of this instead of reading it completely and then chopping it up again
				NSString *autocompleteAdditions = [NSString stringWithContentsOfFile:autocompleteAdditionsURL.path encoding:NSUTF8StringEncoding error:nil];
				if (autocompleteAdditions) {
					NSArray *additions = [autocompleteAdditions componentsSeparatedByString:@"\n"];
					[NSOperationQueue TCM_performBlockOnMainThreadIsAsynchronous:^{
						[self addAutocompleteEntrysFromArray:additions];
					}];
				}
			});
		}
        
        // Sort the autocomplete dictionary
        [_autocompleteDictionary sortUsingSelector:@selector(caseInsensitiveCompare:)];


		NSURL *scopeExamplesURL = [_bundle URLForResource:@"ScopeExamples" withExtension:@"plist"];
		if (scopeExamplesURL) {
			_scopeExamples = [[NSDictionary alloc] initWithContentsOfURL:scopeExamplesURL];
			_availableScopes = [[_scopeExamples allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
		}


        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        // Load web preview
        NSURL *webPreviewURL = [aBundle URLForResource:@"WebPreview" withExtension:@"js"];
        _webPreview = [[SEEWebPreview alloc] initWithURL:webPreviewURL];

        
        // Load scripts
        I_scriptsByFilename = [NSMutableDictionary new];
        NSString *scriptFolder = [[aBundle resourcePath] stringByAppendingPathComponent:@"Scripts"];
        NSFileManager *fm = [NSFileManager defaultManager];
        NSEnumerator *filenames = [[fm contentsOfDirectoryAtPath:scriptFolder error:nil] objectEnumerator];
        NSString     *filename  = nil;
        while ((filename=[filenames nextObject])) {
            // skip hidden files and directory entries
            if (![filename hasPrefix:@"."]) {
                NSURL *fileURL=[NSURL fileURLWithPath:[scriptFolder stringByAppendingPathComponent:filename]];
                ScriptWrapper *script = [ScriptWrapper scriptWrapperWithContentsOfURL:fileURL];
                if (script) {
                    [I_scriptsByFilename setObject:script forKey:[filename stringByDeletingPathExtension]];
                }
            }
        }
        
         I_scriptOrderArray = [[[I_scriptsByFilename allKeys] sortedArrayUsingSelector:@selector(compare:)] mutableCopy];

        I_menuItemArray = [NSMutableArray new];
        I_contextMenuItemArray = [NSMutableArray new];
        int i=0;
        for (i=0;i<[I_scriptOrderArray count];i++) {
            NSString *filename = [I_scriptOrderArray objectAtIndex:i];
            ScriptWrapper *script = [I_scriptsByFilename objectForKey:filename];
            NSDictionary *settingsDictionary = [script settingsDictionary];
            NSString *displayName = filename;
            if (settingsDictionary && [settingsDictionary objectForKey:ScriptWrapperDisplayNameSettingsKey]) {
                displayName = [settingsDictionary objectForKey:ScriptWrapperDisplayNameSettingsKey];
            }
            NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:displayName
                                                          action:@selector(performScriptAction:) 
                                                   keyEquivalent:@""];
            if (settingsDictionary) {
                [item setKeyEquivalentBySettingsString:[settingsDictionary objectForKey:ScriptWrapperKeyboardShortcutSettingsKey]];
                if ([[[settingsDictionary objectForKey:ScriptWrapperInContextMenuSettingsKey] lowercaseString] isEqualToString:@"yes"]) {
                    [I_contextMenuItemArray addObject:item];
                }
            }
            [item setTarget:script];
            [I_menuItemArray addObject:item];

			/* legacy note: the toolbar item were loaded here once in the past */
        }
        
        // Preference Handling
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:NSApplicationWillTerminateNotification object:nil];
        NSMutableDictionary *dictionary=[[defaults objectForKey:[self documentModeIdentifier]] mutableCopy];
        if (dictionary) {
            // color is deprecated since 2.1 - so ignore it
            [self setDefaults:dictionary];
            NSNumber *encodingNumber = [dictionary objectForKey:DocumentModeEncodingPreferenceKey];
            if (encodingNumber) {
                NSStringEncoding encoding = [encodingNumber unsignedIntValue];
                if (encoding != NoStringEncoding) {
					[[EncodingManager sharedInstance] registerEncoding:encoding];
				}
            }
        } else {
            _defaults = [NSMutableDictionary new];
            [_defaults setObject:[NSNumber numberWithInt:4] forKey:DocumentModeTabWidthPreferenceKey];
            [_defaults setObject:[NSNumber numberWithInt:100] forKey:DocumentModeColumnsPreferenceKey];
            [_defaults setObject:[NSNumber numberWithInt:80] forKey:DocumentModePageGuideWidthPreferenceKey];
            [_defaults setObject:[NSNumber numberWithInt:0] forKey:DocumentModeIndentWrappedLinesCharacterAmountPreferenceKey];
            [_defaults setObject:[NSNumber numberWithInt:50] forKey:DocumentModeRowsPreferenceKey];
            NSFont *font=[NSFont userFixedPitchFontOfSize:0.0];
            NSMutableDictionary *dict=[NSMutableDictionary dictionary];
            [dict setObject:[font fontName] 
                     forKey:NSFontNameAttribute];
            [dict setObject:[NSNumber numberWithFloat:[font pointSize]] 
                     forKey:NSFontSizeAttribute];
            [_defaults setObject:dict forKey:DocumentModeFontAttributesPreferenceKey];
            [_defaults setObject:[NSNumber numberWithUnsignedInt:NSUTF8StringEncoding] forKey:DocumentModeEncodingPreferenceKey];
            [_defaults setObject:@YES forKey:DocumentModeHighlightSyntaxPreferenceKey];
            [_defaults setObject:@YES forKey:DocumentModeShowLineNumbersPreferenceKey];
            [_defaults setObject:@NO  forKey:DocumentModeShowInvisibleCharactersPreferenceKey];
            [_defaults setObject:@NO  forKey:DocumentModeShowInconsistentIndentationPreferenceKey];
            [_defaults setObject:@YES forKey:DocumentModeShowMatchingBracketsPreferenceKey];
            [_defaults setObject:@YES forKey:DocumentModeWrapLinesPreferenceKey];
            [_defaults setObject:@YES forKey:DocumentModeIndentNewLinesPreferenceKey];
            [_defaults setObject:@YES forKey:DocumentModeUseTabsPreferenceKey];
            [_defaults setObject:[NSNumber numberWithUnsignedInt:DocumentModeWrapModeWords] forKey:DocumentModeWrapModePreferenceKey];
            [_defaults setObject:[NSNumber numberWithInt:LineEndingLF] forKey:DocumentModeLineEndingPreferenceKey];
            [_defaults setObject:@NO forKey:DocumentModeUTF8BOMPreferenceKey];

			// ignore deprecated color settings, but still set them for backwards compatability
			NSValueTransformer *transformer=[NSValueTransformer valueTransformerForName:NSUnarchiveFromDataTransformerName];
			[_defaults setObject:[transformer reverseTransformedValue:[NSColor blackColor]] forKey:DocumentModeForegroundColorPreferenceKey];
            [_defaults setObject:[transformer reverseTransformedValue:[NSColor whiteColor]] forKey:DocumentModeBackgroundColorPreferenceKey];
            [[EncodingManager sharedInstance] registerEncoding:NoStringEncoding];
            if (![self isBaseMode]) {
                // read frome modefile? for now use defaults
                [_defaults setObject:@YES forKey:DocumentModeUseDefaultViewPreferenceKey];
                [_defaults setObject:@YES forKey:DocumentModeUseDefaultEditPreferenceKey];
                [_defaults setObject:@YES forKey:DocumentModeUseDefaultFilePreferenceKey];
                [_defaults setObject:@YES forKey:DocumentModeUseDefaultFontPreferenceKey];
                [_defaults setObject:@YES forKey:DocumentModeUseDefaultStylePreferenceKey];
                [_defaults setObject:@YES forKey:DocumentModeUseDefaultStyleSheetPreferenceKey];
            }
        }

        // add print settings to basemode
        if ([self isBaseMode]) {

            if (![_defaults objectForKey:DocumentModePrintOptionsPreferenceKey]) {
                NSMutableDictionary *printDictionary=[NSMutableDictionary dictionary];
                [printDictionary setObject:@0   forKey:@"SEEUseCustomFont"];
                [printDictionary setObject:@YES forKey:@"SEEResizeDocumentFont"];
                [printDictionary setObject:@8.0 forKey:@"SEEResizeDocumentFontTo"];
                [printDictionary setObject:@YES forKey:@"SEEPageHeader"];
                [printDictionary setObject:@YES forKey:@"SEEPageHeaderFilename"];
                [printDictionary setObject:@YES forKey:@"SEEPageHeaderCurrentDate"];
                [printDictionary setObject:@YES forKey:@"SEEWhiteBackground"];
                [printDictionary setObject:@YES forKey:@"SEEHighlightSyntax"];
                [printDictionary setObject:@NO  forKey:@"SEEColorizeChangeMarks"];
                [printDictionary setObject:@NO  forKey:@"SEEAnnotateChangeMarks"];
                [printDictionary setObject:@NO  forKey:@"SEEColorizeWrittenBy"];
                [printDictionary setObject:@NO  forKey:@"SEEAnnotateWrittenBy"];
                [printDictionary setObject:@NO  forKey:@"SEEParticipants"];
                [printDictionary setObject:@YES forKey:@"SEEParticipantImages"];
                [printDictionary setObject:@YES forKey:@"SEEParticipantsAIMAndEmail"];
                [printDictionary setObject:@YES forKey:@"SEEParticipantsVisitors"];
                NSFont *font=[NSFont fontWithName:@"Times" size:8];
                if (!font) font=[NSFont systemFontOfSize:8.5];
                NSMutableDictionary *dict=[NSMutableDictionary dictionary];
                [dict setObject:[font fontName] forKey:NSFontNameAttribute];
                [dict setObject:@8.5            forKey:NSFontSizeAttribute];
                [printDictionary setObject:dict forKey:@"SEEFontAttributes"];
                float cmToPoints=28.3464567; // google
                [printDictionary setObject:[NSNumber numberWithFloat:2.0*cmToPoints]
                                    forKey:NSPrintLeftMargin];
                [printDictionary setObject:[NSNumber numberWithFloat:1.0*cmToPoints]
                                    forKey:NSPrintRightMargin];
                [printDictionary setObject:[NSNumber numberWithFloat:1.0*cmToPoints]
                                    forKey:NSPrintTopMargin];
                [printDictionary setObject:[NSNumber numberWithFloat:1.0*cmToPoints]
                                    forKey:NSPrintBottomMargin];
                [_defaults setObject:printDictionary
                              forKey:DocumentModePrintOptionsPreferenceKey];
            }
        }

		// populate stylesheet prefs if not there already
		if (![self isBaseMode]) {
			if (![_defaults objectForKey:DocumentModeUseDefaultStyleSheetPreferenceKey]) {
                [_defaults setObject:@YES
                              forKey:DocumentModeUseDefaultStyleSheetPreferenceKey];
			}
		}

		// make the print options mutable
		NSMutableDictionary *printDictionary=[_defaults objectForKey:DocumentModePrintOptionsPreferenceKey];
        if (printDictionary) [_defaults setObject:[printDictionary mutableCopy] forKey:DocumentModePrintOptionsPreferenceKey];

		
        NSMutableDictionary *export=[_defaults objectForKey:DocumentModeExportPreferenceKey];
        export = export?[export mutableCopy]:[NSMutableDictionary dictionary];
        [_defaults setObject:export forKey:DocumentModeExportPreferenceKey];

        NSMutableDictionary *html=[export objectForKey:DocumentModeExportHTMLPreferenceKey];
        if (!html) {
            NSNumber *yes=@YES;
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
            html=[html mutableCopy];
        }
        [export setObject:html forKey:DocumentModeExportHTMLPreferenceKey];

        
        [_defaults addObserver:self
                     forKeyPath:DocumentModeEncodingPreferenceKey
                        options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
                        context:NULL];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (NSString *)documentModeIdentifier {
    return [[_bundle infoDictionary] objectForKey:@"CFBundleIdentifier"];
}

- (NSString *)displayName {
    return [_bundle objectForInfoDictionaryKey:@"CFBundleName"];
}

- (NSArray *)recognizedExtensions {
	return [[_modeSettings recognizedExtensions] arrayByAddingObjectsFromArray:_modeSettings.recognizedCasesensitveExtensions];
}

- (NSString *)bracketMatchingBracketString {
    return _syntaxDefinition.bracketMatchingBracketString ?: @"{[()]}";
}

- (void)addAutocompleteEntrysFromArray:(NSArray *)aAutocompleteArray {
	[_autocompleteDictionary addObjectsFromArray:aAutocompleteArray];
	[_autocompleteDictionary sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
}

- (NSString *)templateFileContent {
    NSString *templateFilename;
    if (_modeSettings) {
        templateFilename=[_modeSettings templateFile];
    } else {
        templateFilename=[[_bundle infoDictionary] objectForKey:@"TCMModeNewFileTemplate"];
    }

    if (templateFilename) {
        NSString *templatePath=[_bundle pathForResource:templateFilename ofType:nil];
        if (templatePath) {
            NSData *data=[NSData dataWithContentsOfFile:templatePath];
            if (data && [data length]>0) {
                return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            }
        }
    }
    return nil;
}

- (BOOL)hasSymbols {
    return ![self isBaseMode];
}

- (NSArray *)symbolArrayForTextStorage:(NSTextStorage *)aTextStorage {
    RegexSymbolParser *symbolParser = [self symbolParser];
    NSArray *returnArray = [symbolParser symbolsForTextStorage:aTextStorage];
    return returnArray;
}

- (id)defaultForKey:(NSString *)aKey {
    NSDictionary *defaultDefaults=[[[DocumentModeManager sharedInstance] baseMode] defaults];
    if (![self isBaseMode]) {
        NSString *defaultKey=[defaultablePreferenceKeys objectForKey:aKey];
        if (!defaultKey || ![[_defaults objectForKey:defaultKey] boolValue]) {
            id result=[_defaults objectForKey:aKey];
            if (! result) {
            	result = [defaultDefaults objectForKey:aKey];
            	if (result) [_defaults setObject:result forKey:aKey];
            }
            return result?result:[defaultDefaults objectForKey:aKey];
        }
    }
    return [defaultDefaults objectForKey:aKey];
}

- (void)reloadStyleSheetSettings {
	I_styleSheetSettings = nil;
}

- (SEEStyleSheetSettings *)styleSheetSettingsOfThisMode {
	if (!I_styleSheetSettings) {
		I_styleSheetSettings = [[SEEStyleSheetSettings alloc] initWithDocumentMode:self];
	}
	return I_styleSheetSettings;
}

- (SEEStyleSheetSettings *)styleSheetSettings {
	SEEStyleSheetSettings *result = nil;
	if ([[[self defaults] objectForKey:DocumentModeUseDefaultStyleSheetPreferenceKey] boolValue]) {
		result = [[[DocumentModeManager sharedInstance] baseMode] styleSheetSettingsOfThisMode];
	} else {
		result = [self styleSheetSettingsOfThisMode];
	}
	return result;
}

- (SEEStyleSheet *)styleSheetForLanguageContext:(NSString *)aLanguageContext {
	SEEStyleSheetSettings *styleSheetSettings = [self styleSheetSettings];
	return [styleSheetSettings styleSheetForLanguageContext:aLanguageContext];
}


// Depricated - only for backwars compatibilty
- (SyntaxStyle *)syntaxStyle {
    if (!I_syntaxStyle) {
        [self defaultSyntaxStyle];
    }
    return I_syntaxStyle;
}


// Depricated - only for backwars compatibilty
- (void)setSyntaxStyle:(SyntaxStyle *)aStyle {
    I_syntaxStyle=aStyle;
}

// Depricated - only for backwars compatibilty
- (SyntaxStyle *)defaultSyntaxStyle {
    if (!I_defaultSyntaxStyle) {
        I_defaultSyntaxStyle = [self syntaxHighlighter]?[[[self syntaxHighlighter] defaultSyntaxStyle] copy]:[SyntaxStyle new];
        [I_defaultSyntaxStyle setDocumentMode:self];

        SyntaxStyle *style=[I_defaultSyntaxStyle copy];
        NSDictionary *syntaxStyleDictionary=[_defaults objectForKey:DocumentModeSyntaxStylePreferenceKey];
        if (syntaxStyleDictionary) {
            [style takeStylesFromDefaultsDictionary:syntaxStyleDictionary];
        }        

		SEEStyleSheet *styleSheet = [self styleSheetForLanguageContext:nil];
		NSColor *highlightColor = styleSheet?[[styleSheet styleAttributesForScope:@"meta.highlight.currentline"] objectForKey:@"color"]:[NSColor yellowColor];
		[_defaults setObject:[[NSValueTransformer valueTransformerForName:NSUnarchiveFromDataTransformerName] reverseTransformedValue:highlightColor] forKey:DocumentModeCurrentLineHighlightColorPreferenceKey];
		
        if (![_defaults objectForKey:DocumentModeBackgroundColorIsDarkPreferenceKey]) {
            [_defaults setObject:@NO forKey:DocumentModeBackgroundColorIsDarkPreferenceKey];
            if ([self isBaseMode] && [_defaults objectForKey:DocumentModeBackgroundColorPreferenceKey]) {
                // take old background and foreground color settings
                NSValueTransformer *transformer=[NSValueTransformer valueTransformerForName:NSUnarchiveFromDataTransformerName];
                NSColor *color=nil;
                
                color=[transformer transformedValue:[_defaults objectForKey:DocumentModeBackgroundColorPreferenceKey]];
                if (!color) color=[NSColor whiteColor];
                BOOL isDark=[color isDark];
                [_defaults setObject:[NSNumber numberWithBool:isDark] forKey:DocumentModeBackgroundColorIsDarkPreferenceKey];
                [[style styleForKey:SyntaxStyleBaseIdentifier] setObject:color forKey:isDark?@"inverted-background-color":@"background-color"];

                color=[transformer transformedValue:[_defaults objectForKey:DocumentModeForegroundColorPreferenceKey]];
                if (!color) color=[NSColor blackColor];
                [[style styleForKey:SyntaxStyleBaseIdentifier] setObject:color forKey:isDark?@"inverted-color":@"color"];
            }
        }
        [self setSyntaxStyle:style];
    }
    return I_defaultSyntaxStyle;
}

- (void)writeDefaults {
    [[self styleSheetSettings] pushSettingsToModeDefaults];
    NSMutableDictionary *defaults=[[self defaults] mutableCopy];
//    [defaults setObject:[[self syntaxStyle] defaultsDictionary] forKey:DocumentModeSyntaxStylePreferenceKey]; no more syntaxStyle writing
    [[NSUserDefaults standardUserDefaults] setObject:defaults forKey:[[self bundle] bundleIdentifier]];
}

#pragma mark -
#pragma mark ### Script Handling ###

- (NSArray *)scriptMenuItemArray {
    return (NSArray *)I_menuItemArray;
}

- (NSArray *)contextMenuItemArray {
    return (NSArray *)I_contextMenuItemArray;
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
        if (oldEncodingNumber && ![oldEncodingNumber isKindOfClass:[NSNull class]]) {
            [[EncodingManager sharedInstance] unregisterEncoding:[oldEncodingNumber unsignedIntValue]];
        }
        NSNumber *newEncodingNumber = [change objectForKey:NSKeyValueChangeNewKey];
        if (newEncodingNumber && ![newEncodingNumber isKindOfClass:[NSNull class]]) {
            [[EncodingManager sharedInstance] registerEncoding:[newEncodingNumber unsignedIntValue]];
        }
    }
}

#pragma mark -
#pragma mark ### Scripting ###

+ (id)coerceValue:(id)value toClass:(Class)toClass {
    if ([value isKindOfClass:[DocumentMode class]] && [toClass isSubclassOfClass:[NSString class]]) {
        return [value documentModeIdentifier];
    } else {
        return nil;
    }
}

- (NSScriptObjectSpecifier *)objectSpecifier {
    NSScriptClassDescription *containerClassDesc = (NSScriptClassDescription *)[NSScriptClassDescription classDescriptionForClass:[NSApp class]];

    // We can either return a name or a uniqueID specifier.
    /*
    return [[[NSNameSpecifier alloc] initWithContainerClassDescription:containerClassDesc
                                                    containerSpecifier:nil 
                                                                   key:@"scriptedModes"
                                                                  name:[self scriptedName]] autorelease];
    */
    return [[NSUniqueIDSpecifier alloc] initWithContainerClassDescription:containerClassDesc
                                                        containerSpecifier:nil
                                                                       key:@"scriptedModes"
                                                                  uniqueID:[self documentModeIdentifier]];
}

- (NSString *)scriptedResourcePath {
    return [[self bundle] resourcePath];
}

// document mode identifier without the leading SEEMode.
- (NSString *)scriptedName {
    NSString *identifier = [self documentModeIdentifier];
    if ([identifier hasPrefix:@"SEEMode."] && [identifier length] > 8) {
        return [identifier substringFromIndex:8];
    }
    return identifier;
}


- (NSString *)syntaxExampleString {
	if (!I_syntaxExampleString) {
		NSURL *exampleURL = [_bundle URLForResource:@"ExampleSyntax" withExtension:@"txt"];
		if (!exampleURL) {
			for (NSString *extension in self.recognizedExtensions) {
				exampleURL = [_bundle URLForResource:@"ExampleSyntax" withExtension:extension];
				if (exampleURL) {
					break;
				}
			}
		}
		if (exampleURL) {
			I_syntaxExampleString = [[NSString alloc] initWithContentsOfURL:exampleURL encoding:NSUTF8StringEncoding error:NULL];
		}
		if (!I_syntaxExampleString && ![self isBaseMode]) {
			I_syntaxExampleString = [[[DocumentModeManager baseMode] syntaxExampleString] copy];
		}
	}
	return I_syntaxExampleString;
}


@end
