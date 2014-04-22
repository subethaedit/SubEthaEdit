//
//  DocumentMode.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Mon Mar 22 2004.
//  Copyright (c) 2004-2006 TheCodingMonkeys. All rights reserved.
//

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
#import "NSMenuTCMAdditions.h"
#import <Carbon/Carbon.h>
#import "ScriptWrapper.h"

#ifdef SUBETHAEDIT
	#import "AppController.h"
#endif

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
#define SEEENGINEVERSION 3.5

+ (BOOL)canParseModeVersionOfBundle:(NSBundle *)aBundle { 
    double requiredEngineVersion = 0; 
    
    CFURLRef url = CFURLCreateWithFileSystemPath(NULL, (CFStringRef) [aBundle bundlePath], kCFURLPOSIXPathStyle, 1);
    CFDictionaryRef infodict = CFBundleCopyInfoDictionaryInDirectory(url);
    NSDictionary *infoDictionary = (NSDictionary *) infodict;    
    NSString *minEngine = [infoDictionary objectForKey:@"SEEMinimumEngineVersion"]; 

    if ( minEngine != nil ) // nil check prevents bug on 10.4, where doubleValue returns garbage 
        requiredEngineVersion = [minEngine doubleValue]; 
    
    CFRelease(url);
    CFRelease(infodict);

    return (requiredEngineVersion<=SEEENGINEVERSION); 
}


- (id)initWithBundle:(NSBundle *)aBundle {
    self = [super init];
    if (self) {
        I_autocompleteDictionary = [NSMutableArray new];
        I_bundle = [aBundle retain];

		self.isBaseMode = [BASEMODEIDENTIFIER isEqualToString:[[self bundle] bundleIdentifier]];
		
		I_styleIDTransitionDictionary = [[NSMutableDictionary alloc] initWithContentsOfFile:[aBundle pathForResource:@"StyleIDTransition" ofType:@"plist"]];

        I_modeSettings = [[ModeSettings alloc] initWithFile:[aBundle pathForResource:@"ModeSettings" ofType:@"xml"]];
		if (!I_modeSettings) { // Fall back to info.plist
			I_modeSettings = [[ModeSettings alloc] initWithPlist:[aBundle bundlePath]];
		}
		
		// already puts some autocomplete in the autocomplete dict
        I_syntaxDefinition = [[SyntaxDefinition alloc] initWithFile:[aBundle pathForResource:@"SyntaxDefinition" ofType:@"xml"] forMode:self];
        
        RegexSymbolDefinition *symDef = [[[RegexSymbolDefinition alloc] initWithFile:[aBundle pathForResource:@"RegexSymbols" ofType:@"xml"] forMode:self] autorelease];
        
        if (I_syntaxDefinition && ![self isBaseMode]) {
            I_syntaxHighlighter = [[SyntaxHighlighter alloc] initWithSyntaxDefinition:I_syntaxDefinition];
		}
        if (symDef) {
            I_symbolParser = [[RegexSymbolParser alloc] initWithSymbolDefinition:symDef];
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
        [I_autocompleteDictionary sortUsingSelector:@selector(caseInsensitiveCompare:)];


		NSURL *scopeExamplesURL = [I_bundle URLForResource:@"ScopeExamples" withExtension:@"plist"];
		if (scopeExamplesURL) {
			I_scopeExamples = [[NSDictionary alloc] initWithContentsOfURL:scopeExamplesURL];
			I_availableScopes = [[[I_scopeExamples allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] retain];
		}


        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
#ifdef SUBETHAEDIT
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
        
        [I_scriptOrderArray release];
         I_scriptOrderArray = [[[I_scriptsByFilename allKeys] sortedArrayUsingSelector:@selector(compare:)] mutableCopy];

        NSArray *searchLocations = [NSArray arrayWithObjects:I_bundle,[NSBundle mainBundle],nil];
        I_menuItemArray = [NSMutableArray new];
        I_contextMenuItemArray = [NSMutableArray new];
        I_toolbarItemsByIdentifier     =[NSMutableDictionary new];
        I_toolbarItemIdentifiers       =[NSMutableArray new];
        I_defaultToolbarItemIdentifiers=[NSMutableArray new];
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
            [I_menuItemArray addObject:[item autorelease]];

            NSToolbarItem *toolbarItem=[script toolbarItemWithImageSearchLocations:searchLocations identifierAddition:[self documentModeIdentifier]];
            if (toolbarItem) {
                [I_toolbarItemsByIdentifier setObject:toolbarItem forKey:[toolbarItem itemIdentifier]];
                [I_toolbarItemIdentifiers  addObject:[toolbarItem itemIdentifier]];
                if ([[[settingsDictionary objectForKey:ScriptWrapperInDefaultToolbarSettingsKey] lowercaseString] isEqualToString:@"yes"]) {
                    [I_defaultToolbarItemIdentifiers addObject:[toolbarItem itemIdentifier]];
                }
            }
        }
#endif
        
        // Preference Handling
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:NSApplicationWillTerminateNotification object:nil];
        NSMutableDictionary *dictionary=[[[defaults objectForKey:[self documentModeIdentifier]] mutableCopy] autorelease];
        if (dictionary) {
            // color is deprecated since 2.1 - so ignore it
            [self setDefaults:dictionary];
            NSNumber *encodingNumber = [dictionary objectForKey:DocumentModeEncodingPreferenceKey];
            if (encodingNumber) {
                NSStringEncoding encoding = [encodingNumber unsignedIntValue];
                if ( encoding != NoStringEncoding ) 
					[[EncodingManager sharedInstance] registerEncoding:encoding];
            }
        } else {
            I_defaults = [NSMutableDictionary new];
            [I_defaults setObject:[NSNumber numberWithInt:4] forKey:DocumentModeTabWidthPreferenceKey];
            [I_defaults setObject:[NSNumber numberWithInt:80] forKey:DocumentModeColumnsPreferenceKey];
            [I_defaults setObject:[NSNumber numberWithInt:80] forKey:DocumentModePageGuideWidthPreferenceKey];
            [I_defaults setObject:[NSNumber numberWithInt:0] forKey:DocumentModeIndentWrappedLinesCharacterAmountPreferenceKey];
            [I_defaults setObject:[NSNumber numberWithInt:40] forKey:DocumentModeRowsPreferenceKey];
            NSFont *font=[NSFont userFixedPitchFontOfSize:0.0];
            NSMutableDictionary *dict=[NSMutableDictionary dictionary];
            [dict setObject:[font fontName] 
                     forKey:NSFontNameAttribute];
            [dict setObject:[NSNumber numberWithFloat:[font pointSize]] 
                     forKey:NSFontSizeAttribute];
            [I_defaults setObject:dict forKey:DocumentModeFontAttributesPreferenceKey];
            [I_defaults setObject:[NSNumber numberWithUnsignedInt:NSUTF8StringEncoding] forKey:DocumentModeEncodingPreferenceKey];
            [I_defaults setObject:[NSNumber numberWithBool:YES] forKey:DocumentModeHighlightSyntaxPreferenceKey];
            [I_defaults setObject:[NSNumber numberWithBool:NO]  forKey:DocumentModeShowLineNumbersPreferenceKey];
            [I_defaults setObject:[NSNumber numberWithBool:NO]  forKey:DocumentModeShowInvisibleCharactersPreferenceKey];
            [I_defaults setObject:[NSNumber numberWithBool:YES] forKey:DocumentModeShowMatchingBracketsPreferenceKey];
            [I_defaults setObject:[NSNumber numberWithBool:YES] forKey:DocumentModeWrapLinesPreferenceKey];
            [I_defaults setObject:[NSNumber numberWithBool:YES] forKey:DocumentModeIndentNewLinesPreferenceKey];
            [I_defaults setObject:[NSNumber numberWithBool:YES] forKey:DocumentModeUseTabsPreferenceKey];
            [I_defaults setObject:[NSNumber numberWithUnsignedInt:DocumentModeWrapModeWords] forKey:DocumentModeWrapModePreferenceKey];
            [I_defaults setObject:[NSNumber numberWithInt:LineEndingLF] forKey:DocumentModeLineEndingPreferenceKey];
            [I_defaults setObject:[NSNumber numberWithBool:NO] forKey:DocumentModeUTF8BOMPreferenceKey];

			// ignore deprecated color settings, but still set them for backwards compatability
			NSValueTransformer *transformer=[NSValueTransformer valueTransformerForName:NSUnarchiveFromDataTransformerName];
			[I_defaults setObject:[transformer reverseTransformedValue:[NSColor blackColor]] forKey:DocumentModeForegroundColorPreferenceKey];
            [I_defaults setObject:[transformer reverseTransformedValue:[NSColor whiteColor]] forKey:DocumentModeBackgroundColorPreferenceKey];
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
                               forKey:DocumentModeUseDefaultStylePreferenceKey];
                [I_defaults setObject:[NSNumber numberWithBool:YES] 
                               forKey:DocumentModeUseDefaultStyleSheetPreferenceKey];
            }
        }

        // augment pre 2.1 data if needed
        if ([self isBaseMode]) {

            if (![I_defaults objectForKey:DocumentModePrintOptionsPreferenceKey]) {
                NSMutableDictionary *printDictionary=[NSMutableDictionary dictionary];
                [printDictionary setObject:[NSNumber numberWithInt:0]
                                        forKey:@"SEEUseCustomFont"];
                [printDictionary setObject:[NSNumber numberWithBool:YES]
                                        forKey:@"SEEResizeDocumentFont"];
                [printDictionary setObject:[NSNumber numberWithFloat:8]
                                        forKey:@"SEEResizeDocumentFontTo"];
                [printDictionary setObject:[NSNumber numberWithBool:YES]
                                        forKey:@"SEEPageHeader"];
                [printDictionary setObject:[NSNumber numberWithBool:YES]
                                        forKey:@"SEEPageHeaderFilename"];
                [printDictionary setObject:[NSNumber numberWithBool:YES]
                                        forKey:@"SEEPageHeaderCurrentDate"];
                [printDictionary setObject:[NSNumber numberWithBool:YES]
                                        forKey:@"SEEWhiteBackground"];
                [printDictionary setObject:[NSNumber numberWithBool:YES]
                                        forKey:@"SEEHighlightSyntax"];
                [printDictionary setObject:[NSNumber numberWithBool:NO]
                                        forKey:@"SEEColorizeChangeMarks"];
                [printDictionary setObject:[NSNumber numberWithBool:NO]
                                        forKey:@"SEEAnnotateChangeMarks"];
                [printDictionary setObject:[NSNumber numberWithBool:NO]
                                        forKey:@"SEEColorizeWrittenBy"];
                [printDictionary setObject:[NSNumber numberWithBool:NO]
                                        forKey:@"SEEAnnotateWrittenBy"];
                [printDictionary setObject:[NSNumber numberWithBool:NO]
                                        forKey:@"SEEParticipants"];
                [printDictionary setObject:[NSNumber numberWithBool:YES]
                                        forKey:@"SEEParticipantImages"];
                [printDictionary setObject:[NSNumber numberWithBool:YES]
                                        forKey:@"SEEParticipantsAIMAndEmail"];
                [printDictionary setObject:[NSNumber numberWithBool:YES]
                                        forKey:@"SEEParticipantsVisitors"];
                NSFont *font=[NSFont fontWithName:@"Times" size:8];
                if (!font) font=[NSFont systemFontOfSize:8.5];
                NSMutableDictionary *dict=[NSMutableDictionary dictionary];
                [dict setObject:[font fontName] 
                         forKey:NSFontNameAttribute];
                [dict setObject:[NSNumber numberWithFloat:8.5] 
                         forKey:NSFontSizeAttribute];
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
                [I_defaults setObject:printDictionary
                               forKey:DocumentModePrintOptionsPreferenceKey];
            }
        }

        // new settings in 2.5.1 that need a default value
        if (![I_defaults objectForKey:DocumentModePageGuideWidthPreferenceKey]) {
            [I_defaults setObject:[NSNumber numberWithInt:80] forKey:DocumentModePageGuideWidthPreferenceKey];
        }
        if (![I_defaults objectForKey:DocumentModeIndentWrappedLinesCharacterAmountPreferenceKey]) {
            [I_defaults setObject:[NSNumber numberWithInt:0] forKey:DocumentModeIndentWrappedLinesCharacterAmountPreferenceKey];
        }

		if (![I_defaults objectForKey:DocumentModeTabKeyMovesToIndentPreferenceKey]) {
			[I_defaults setObject:[NSNumber numberWithBool:YES]
						   forKey:DocumentModeTabKeyMovesToIndentPreferenceKey];
		}

		// populate stylesheet prefs if not there already
		if (![I_defaults objectForKey:DocumentModeUseDefaultStyleSheetPreferenceKey]) {
			[I_defaults setObject:[NSNumber numberWithBool:YES] 
                           forKey:DocumentModeUseDefaultStyleSheetPreferenceKey];
        }
        if (![I_defaults objectForKey:DocumentModeStyleSheetsPreferenceKey]) {
	    	[I_defaults setObject:[NSDictionary dictionaryWithObjectsAndKeys:[DocumentModeManager defaultStyleSheetName],DocumentModeStyleSheetsDefaultLanguageContextKey,nil]
	    				   forKey:DocumentModeStyleSheetsPreferenceKey];
	    }


                NSMutableDictionary *printDictionary=[I_defaults objectForKey:DocumentModePrintOptionsPreferenceKey];
        if (printDictionary) [I_defaults setObject:[[printDictionary mutableCopy] autorelease] forKey:DocumentModePrintOptionsPreferenceKey];

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
    [I_styleIDTransitionDictionary release];
    [I_menuItemArray release];
    [I_contextMenuItemArray release];
    [I_scriptOrderArray release];
    [I_scriptsByFilename release];
    [I_toolbarItemIdentifiers release];
    [I_toolbarItemsByIdentifier release];
    [I_defaultToolbarItemIdentifiers release];

    [I_defaults release];
    [I_syntaxHighlighter release];
    [I_syntaxDefinition release];
    [I_symbolParser release];
    [I_autocompleteDictionary release];
    [I_bundle release];
    [I_syntaxStyle release];
    [I_defaultSyntaxStyle release];
    [I_modeSettings release];
    [I_scopeExamples release];
    [I_availableScopes release];
    [I_syntaxExampleString autorelease];
    [I_styleSheetSettings release];
    [super dealloc];
}

- (NSBundle *)bundle {
    return I_bundle;
}

- (NSString *)documentModeIdentifier {
    return [[I_bundle infoDictionary] objectForKey:@"CFBundleIdentifier"];
}

- (NSString *)displayName {
    return [I_bundle objectForInfoDictionaryKey:@"CFBundleName"];
}

- (NSArray *)recognizedExtensions {
	return [I_modeSettings recognizedExtensions];
}

- (NSDictionary *)styleIDTransitionDictionary {
	return I_styleIDTransitionDictionary;
}


- (ModeSettings *)modeSettings {
    return I_modeSettings;
}

- (SyntaxDefinition *)syntaxDefinition {
    return I_syntaxDefinition;
}

- (NSString *)bracketMatchingBracketString {
	NSString *result = I_syntaxDefinition.bracketMatchingBracketString;
	if (!result) {
		result = @"{[()]}"; // default value
	}
	return result;
}

- (SyntaxHighlighter *)syntaxHighlighter {
    return I_syntaxHighlighter;
}

- (RegexSymbolParser *)symbolParser {
    return I_symbolParser;
}

- (NSMutableArray *)autocompleteDictionary {
    return I_autocompleteDictionary;
}

- (void)addAutocompleteEntrysFromArray:(NSArray *)aAutocompleteArray {
	[I_autocompleteDictionary addObjectsFromArray:aAutocompleteArray];
	[I_autocompleteDictionary sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
}

- (NSString *)templateFileContent {
    NSString *templateFilename;
    if (I_modeSettings) {
        templateFilename=[I_modeSettings templateFile];
    } else {
        templateFilename=[[I_bundle infoDictionary] objectForKey:@"TCMModeNewFileTemplate"];
    }

    if (templateFilename) {
        NSString *templatePath=[I_bundle pathForResource:templateFilename ofType:nil];
        if (templatePath) {
            NSData *data=[NSData dataWithContentsOfFile:templatePath];
            if (data && [data length]>0) {
                return [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
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

- (NSDictionary *)scopeExamples {
	return I_scopeExamples;
}

- (NSArray *)availableScopes {
	return I_availableScopes;
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
            id result=[I_defaults objectForKey:aKey];
            if (! result) {
            	result = [defaultDefaults objectForKey:aKey];
            	if (result) [I_defaults setObject:result forKey:aKey];
            }
            return result?result:[defaultDefaults objectForKey:aKey];
        }
    }
    return [defaultDefaults objectForKey:aKey];
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
    [I_syntaxStyle autorelease];
    I_syntaxStyle=[aStyle retain];
}

// Depricated - only for backwars compatibilty
- (SyntaxStyle *)defaultSyntaxStyle {
    if (!I_defaultSyntaxStyle) {
        I_defaultSyntaxStyle = [self syntaxHighlighter]?[[[self syntaxHighlighter] defaultSyntaxStyle] copy]:[SyntaxStyle new];
        [I_defaultSyntaxStyle setDocumentMode:self];

        SyntaxStyle *style=[I_defaultSyntaxStyle copy];
        NSDictionary *syntaxStyleDictionary=[I_defaults objectForKey:DocumentModeSyntaxStylePreferenceKey];
        if (syntaxStyleDictionary) {
            [style takeStylesFromDefaultsDictionary:syntaxStyleDictionary];
        }        

		SEEStyleSheet *styleSheet = [self styleSheetForLanguageContext:nil];
		NSColor *highlightColor = styleSheet?[[styleSheet styleAttributesForScope:@"meta.highlight.currentline"] objectForKey:@"color"]:[NSColor yellowColor];
		[I_defaults setObject:[[NSValueTransformer valueTransformerForName:NSUnarchiveFromDataTransformerName] reverseTransformedValue:highlightColor] forKey:DocumentModeCurrentLineHighlightColorPreferenceKey];
		
        if (![I_defaults objectForKey:DocumentModeBackgroundColorIsDarkPreferenceKey]) {
            [I_defaults setObject:[NSNumber numberWithBool:NO] forKey:DocumentModeBackgroundColorIsDarkPreferenceKey];
            if ([self isBaseMode] && [I_defaults objectForKey:DocumentModeBackgroundColorPreferenceKey]) {
                // take old background and foreground color settings
                NSValueTransformer *transformer=[NSValueTransformer valueTransformerForName:NSUnarchiveFromDataTransformerName];
                NSColor *color=nil;
                
                color=[transformer transformedValue:[I_defaults objectForKey:DocumentModeBackgroundColorPreferenceKey]];
                if (!color) color=[NSColor whiteColor];
                BOOL isDark=[color isDark];
                [I_defaults setObject:[NSNumber numberWithBool:isDark] forKey:DocumentModeBackgroundColorIsDarkPreferenceKey];
                [[style styleForKey:SyntaxStyleBaseIdentifier] setObject:color forKey:isDark?@"inverted-background-color":@"background-color"];

                color=[transformer transformedValue:[I_defaults objectForKey:DocumentModeForegroundColorPreferenceKey]];
                if (!color) color=[NSColor blackColor];
                [[style styleForKey:SyntaxStyleBaseIdentifier] setObject:color forKey:isDark?@"inverted-color":@"color"];
            }
        }
        [self setSyntaxStyle:style];
        [style release];
    }
    return I_defaultSyntaxStyle;
}

- (void)writeDefaults {
    [[self styleSheetSettings] pushSettingsToModeDefaults];
    NSMutableDictionary *defaults=[[self defaults] mutableCopy];
//    [defaults setObject:[[self syntaxStyle] defaultsDictionary] forKey:DocumentModeSyntaxStylePreferenceKey]; no more syntaxStyle writing
    [[NSUserDefaults standardUserDefaults] setObject:defaults forKey:[[self bundle] bundleIdentifier]];
    [defaults release];
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
#pragma mark ### Toolbar ###

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)willBeInserted {
    return [[[I_toolbarItemsByIdentifier objectForKey:itemIdentifier] copy] autorelease];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
    return I_defaultToolbarItemIdentifiers;
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar {
    return I_toolbarItemIdentifiers;
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
    return [[[NSUniqueIDSpecifier alloc] initWithContainerClassDescription:containerClassDesc
                                                        containerSpecifier:nil
                                                                       key:@"scriptedModes"
                                                                  uniqueID:[self documentModeIdentifier]] autorelease];
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
		NSURL *exampleURL = [I_bundle URLForResource:@"ExampleSyntax" withExtension:@"txt"];
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
