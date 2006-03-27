//
//  DocumentMode.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Mon Mar 22 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>

enum {
    DocumentModeWrapModeWords = 0,
    DocumentModeWrapModeCharacters
};

extern NSString * const DocumentModeShowTopStatusBarPreferenceKey       ;
extern NSString * const DocumentModeShowBottomStatusBarPreferenceKey    ;
extern NSString * const DocumentModeEncodingPreferenceKey               ;
extern NSString * const DocumentModeFontAttributesPreferenceKey         ;
extern NSString * const DocumentModeHighlightSyntaxPreferenceKey        ;
extern NSString * const DocumentModeIndentNewLinesPreferenceKey         ;
extern NSString * const DocumentModeLineEndingPreferenceKey             ;
extern NSString * const DocumentModeShowLineNumbersPreferenceKey        ;
extern NSString * const DocumentModeShowMatchingBracketsPreferenceKey   ;
extern NSString * const DocumentModeTabWidthPreferenceKey               ;
extern NSString * const DocumentModeUseTabsPreferenceKey                ;
extern NSString * const DocumentModeWrapLinesPreferenceKey              ;
extern NSString * const DocumentModeShowInvisibleCharactersPreferenceKey;
extern NSString * const DocumentModeWrapModePreferenceKey               ;
extern NSString * const DocumentModeColumnsPreferenceKey                ;
extern NSString * const DocumentModeRowsPreferenceKey                   ;
extern NSString * const DocumentModeSpellCheckingPreferenceKey          ;
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
extern NSString * const DocumentModeUseDefaultPrintPreferenceKey;
extern NSString * const DocumentModeUseDefaultStylePreferenceKey;
extern NSString * const DocumentModeUseDefaultFontPreferenceKey;
extern NSString * const DocumentModeUseDefaultViewPreferenceKey;
extern NSString * const DocumentModeUseDefaultEditPreferenceKey;
extern NSString * const DocumentModeUseDefaultFilePreferenceKey;

extern NSString * const DocumentModeApplyEditPreferencesNotification;
extern NSString * const DocumentModeApplyStylePreferencesNotification;


@class SyntaxHighlighter;
@class RegexSymbolParser;
@class SyntaxStyle;

@interface DocumentMode : NSObject {
    NSBundle *I_bundle;
    SyntaxHighlighter *I_syntaxHighlighter;
    RegexSymbolParser *I_symbolParser;
    NSMutableArray *I_autocompleteDictionary;
    NSMutableDictionary *I_defaults;
    SyntaxStyle *I_syntaxStyle,*I_defaultSyntaxStyle;
    NSMutableDictionary *I_scriptsByFilename;
    NSMutableDictionary *I_scriptSettingsByFilename;
    NSMutableArray *I_menuItemArray;
    NSMutableArray *I_scriptOrderArray;
}

- (id)initWithBundle:(NSBundle *)aBundle;

- (SyntaxHighlighter *)syntaxHighlighter;
- (RegexSymbolParser *)symbolParser;
- (NSString *)newFileContent;
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
- (SyntaxStyle *)defaultSyntaxStyle;

- (NSArray *)scriptMenuItemArray;
- (IBAction)performScriptAction:(id)aSender;

- (BOOL)isBaseMode;
@end
