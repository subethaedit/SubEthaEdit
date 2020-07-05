//  DocumentMode.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Mon Mar 22 2004.

#import <Cocoa/Cocoa.h>
#import "SEEStyleSheetSettings.h"

enum {
    DocumentModeWrapModeWords = 0,
    DocumentModeWrapModeCharacters,
};

enum {
	DocumentModeDocumentInfoCharacters = 0,
	DocumentModeDocumentInfoLines = 1,
	DocumentModeDocumentInfoWords = 2,
	DocumentModeDocumentInfoModulo,
};

extern NSString * const DocumentModeDocumentInfoTypePreferenceKey       ;
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
extern NSString * const DocumentModeShowInconsistentIndentationPreferenceKey;
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

extern NSString * const DocumentModeFontNameSystemFontValue;


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
@class SEEWebPreview;

@interface DocumentMode : NSObject {
    SyntaxStyle *I_syntaxStyle,*I_defaultSyntaxStyle;
    NSMutableDictionary *I_scriptsByFilename;
    NSMutableArray *I_menuItemArray;
    NSMutableArray *I_contextMenuItemArray;
    NSMutableArray *I_scriptOrderArray;
    NSString *I_syntaxExampleString;
    SEEStyleSheetSettings *I_styleSheetSettings;
}

@property (readonly) BOOL isBaseMode;
@property (nonatomic, strong) NSMutableDictionary *defaults;
@property (nonatomic, strong, readonly) NSArray *availableScopes;
@property (nonatomic, strong, readonly) NSDictionary *scopeExamples;
@property (nonatomic, strong, readonly) NSDictionary *styleIDTransitionDictionary;
@property (nonatomic, strong, readonly) ModeSettings *modeSettings;
@property (nonatomic, strong, readonly) SyntaxHighlighter *syntaxHighlighter;
@property (nonatomic, strong, readonly) SyntaxDefinition *syntaxDefinition;
@property (nonatomic, strong, readonly) NSMutableArray *autocompleteDictionary;
@property (nonatomic, strong, readonly) RegexSymbolParser *symbolParser;
@property (nonatomic, strong, readonly) SEEWebPreview *webPreview;
@property (nonatomic, strong, readonly) NSBundle *bundle;

- (void)addAutocompleteEntrysFromArray:(NSArray *)aAutocompleteArray;

+ (BOOL)canParseModeVersionOfBundle:(NSBundle *)aBundle;

- (instancetype)initWithBundle:(NSBundle *)aBundle;

@property (nonatomic, strong, readonly) NSString *bracketMatchingBracketString;

- (NSString *)templateFileContent;

- (BOOL)hasSymbols;
- (NSArray *)symbolArrayForTextStorage:(NSTextStorage *)aTextStorage;

- (NSString *)documentModeIdentifier;
- (NSString *)displayName;
- (NSArray *)recognizedExtensions;

- (id)defaultForKey:(NSString *)aKey;
- (SyntaxStyle *)syntaxStyle;
- (void)setSyntaxStyle:(SyntaxStyle *)aStyle;
- (SEEStyleSheetSettings *)styleSheetSettings;
- (SEEStyleSheetSettings *)styleSheetSettingsOfThisMode;
- (void)reloadStyleSheetSettings;
- (SyntaxStyle *)defaultSyntaxStyle;
- (SEEStyleSheet *)styleSheetForLanguageContext:(NSString *)aLanguageContext;

- (NSFont *)plainFontBase;

- (NSArray *)scriptMenuItemArray;
- (NSArray *)contextMenuItemArray;

- (NSString *)scriptedName;

- (NSString *)syntaxExampleString;

- (BOOL)isBaseMode;

+ (NSFont *)fontForAttributeDict:(NSDictionary *)fontAttributes;
@end
