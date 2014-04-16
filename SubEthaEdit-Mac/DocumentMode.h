//
//  DocumentMode.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Mon Mar 22 2004.
//  Copyright (c) 2004-2006 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SEEStyleSheetSettings.h"

enum {
    DocumentModeWrapModeWords = 0,
    DocumentModeWrapModeCharacters
};

extern NSString * const DocumentModeShowTopStatusBarPreferenceKey       ;
extern NSString * const DocumentModeShowBottomStatusBarPreferenceKey    ;
extern NSString * const DocumentModeEncodingPreferenceKey               ;
extern NSString * const DocumentModeUTF8BOMPreferenceKey                ;
extern NSString * const DocumentModeFontAttributesPreferenceKey         ;
extern NSString * const DocumentModeHighlightSyntaxPreferenceKey        ;
extern NSString * const DocumentModeIndentNewLinesPreferenceKey         ;
extern NSString * const DocumentModeTabKeyReplacesSelectionPreferenceKey;
extern NSString * const DocumentModeTabKeyMovesToIndentPreferenceKey    ;
extern NSString * const DocumentModeLineEndingPreferenceKey             ;
extern NSString * const DocumentModeShowLineNumbersPreferenceKey        ;
extern NSString * const DocumentModeShowMatchingBracketsPreferenceKey   ;
extern NSString * const DocumentModeTabWidthPreferenceKey               ;
extern NSString * const DocumentModeUseTabsPreferenceKey                ;
extern NSString * const DocumentModeWrapLinesPreferenceKey              ;
extern NSString * const DocumentModeIndentWrappedLinesPreferenceKey     ;
extern NSString * const DocumentModeIndentWrappedLinesCharacterAmountPreferenceKey;
extern NSString * const DocumentModeShowPageGuidePreferenceKey          ;
extern NSString * const DocumentModePageGuideWidthPreferenceKey         ;
extern NSString * const DocumentModeShowInvisibleCharactersPreferenceKey;
extern NSString * const DocumentModeWrapModePreferenceKey               ;
extern NSString * const DocumentModeColumnsPreferenceKey                ;
extern NSString * const DocumentModeRowsPreferenceKey                   ;

extern NSString * const DocumentModeSpellCheckingPreferenceKey          ;

// snow leopard additions
extern NSString * const DocumentModeGrammarCheckingPreferenceKey             ;
extern NSString * const DocumentModeAutomaticLinkDetectionPreferenceKey      ;
extern NSString * const DocumentModeAutomaticDashSubstitutionPreferenceKey   ;
extern NSString * const DocumentModeAutomaticQuoteSubstitutionPreferenceKey  ;
extern NSString * const DocumentModeAutomaticTextReplacementPreferenceKey    ;
extern NSString * const DocumentModeAutomaticSpellingCorrectionPreferenceKey ;



extern NSString * const DocumentModePrintOptionsPreferenceKey           ;

extern NSString * const DocumentModeBackgroundColorIsDarkPreferenceKey  ;
extern NSString * const DocumentModeSyntaxStylePreferenceKey            ;
// depricated
// extern NSString * const DocumentModeForegroundColorPreferenceKey        ;
// extern NSString * const DocumentModeBackgroundColorPreferenceKey        ;

extern NSString * const DocumentModeExportPreferenceKey                    ;
extern NSString * const DocumentModeExportHTMLPreferenceKey                ;
extern NSString * const DocumentModeHTMLExportAddCurrentDatePreferenceKey  ;
extern NSString * const DocumentModeHTMLExportHighlightSyntaxPreferenceKey ;
extern NSString * const DocumentModeHTMLExportShowAIMAndEmailPreferenceKey ;
extern NSString * const DocumentModeHTMLExportShowChangeMarksPreferenceKey ;
extern NSString * const DocumentModeHTMLExportShowParticipantsPreferenceKey;
extern NSString * const DocumentModeHTMLExportShowUserImagesPreferenceKey  ;
extern NSString * const DocumentModeHTMLExportShowVisitorsPreferenceKey    ;
extern NSString * const DocumentModeHTMLExportWrittenByHoversPreferenceKey ;
extern NSString * const DocumentModeUseDefaultStylePreferenceKey;
extern NSString * const DocumentModeUseDefaultFontPreferenceKey;
extern NSString * const DocumentModeUseDefaultViewPreferenceKey;
extern NSString * const DocumentModeUseDefaultEditPreferenceKey;
extern NSString * const DocumentModeUseDefaultFilePreferenceKey;

extern NSString * const DocumentModeApplyEditPreferencesNotification;
extern NSString * const DocumentModeApplyStylePreferencesNotification;

extern NSString * const DocumentModeUseDefaultStyleSheetPreferenceKey;
extern NSString * const DocumentModeStyleSheetsPreferenceKey         ;
extern NSString * const DocumentModeStyleSheetsDefaultLanguageContextKey;


@class ModeSettings;
@class SyntaxHighlighter;
@class SyntaxDefinition;
@class RegexSymbolParser;
@class SyntaxStyle;
@class SEEStyleSheet;
@class SEEStyleSheetSettings;

@interface DocumentMode : NSObject <NSToolbarDelegate> {
    NSBundle *I_bundle;
    ModeSettings *I_modeSettings;
    SyntaxDefinition *I_syntaxDefinition;
    SyntaxHighlighter *I_syntaxHighlighter;
    RegexSymbolParser *I_symbolParser;
    NSMutableArray *I_autocompleteDictionary;
    NSMutableDictionary *I_defaults;
    SyntaxStyle *I_syntaxStyle,*I_defaultSyntaxStyle;
	SEEStyleSheet *I_styleSheet;
    NSMutableDictionary *I_scriptsByFilename;
    NSMutableArray *I_menuItemArray;
    NSMutableArray *I_contextMenuItemArray;
    NSMutableArray *I_scriptOrderArray;
    NSMutableDictionary *I_toolbarItemsByIdentifier;
    NSMutableArray *I_toolbarItemIdentifiers;
    NSMutableArray *I_defaultToolbarItemIdentifiers;
    NSMutableDictionary *I_styleIDTransitionDictionary;
    NSDictionary *I_scopeExamples;
    NSArray *I_availableScopes;
    NSString *I_syntaxExampleString;
    SEEStyleSheetSettings *I_styleSheetSettings;
}

- (void)addAutocompleteEntrysFromArray:(NSArray *)aAutocompleteArray;

+ (BOOL)canParseModeVersionOfBundle:(NSBundle *)aBundle;

- (id)initWithBundle:(NSBundle *)aBundle;

- (NSDictionary *)scopeExamples;
- (NSArray *)availableScopes;

- (NSDictionary *)styleIDTransitionDictionary;
- (ModeSettings *)modeSettings;
- (SyntaxHighlighter *)syntaxHighlighter;
- (SyntaxDefinition *)syntaxDefinition;
@property (readonly) NSString *bracketMatchingBracketString;
- (RegexSymbolParser *)symbolParser;
- (NSString *)templateFileContent;
- (NSMutableArray *)autocompleteDictionary;

- (BOOL)hasSymbols;
- (NSArray *)symbolArrayForTextStorage:(NSTextStorage *)aTextStorage;

- (NSBundle *)bundle;
- (NSString *)documentModeIdentifier;
- (NSString *)displayName;
- (NSArray *)recognizedExtensions;

- (NSMutableDictionary *)defaults;
- (void)setDefaults:(NSMutableDictionary *)defaults;
- (id)defaultForKey:(NSString *)aKey;
- (SyntaxStyle *)syntaxStyle;
- (void)setSyntaxStyle:(SyntaxStyle *)aStyle;
- (SEEStyleSheetSettings *)styleSheetSettings;
- (SEEStyleSheetSettings *)styleSheetSettingsOfThisMode;
- (SyntaxStyle *)defaultSyntaxStyle;
- (SEEStyleSheet *)styleSheetForLanguageContext:(NSString *)aLanguageContext;

- (NSArray *)scriptMenuItemArray;
- (NSArray *)contextMenuItemArray;

- (NSString *)scriptedName;

- (NSString *)syntaxExampleString;

- (BOOL)isBaseMode;
@end
