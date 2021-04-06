//  SyntaxHighlighter.h
//
//  Created by Martin Pittenauer on Thu Mar 04 2004.

#import <Foundation/Foundation.h>
#import "SyntaxDefinition.h"

extern NSAttributedStringKey const kSyntaxHighlightingIsCorrectAttributeName;
extern NSString * const kSyntaxHighlightingIsCorrectAttributeValue;
extern NSAttributedStringKey const kSyntaxHighlightingIsTrimmedStartAttributeName;
extern NSString * const kSyntaxHighlightingIsTrimmedStartAttributeValue;
extern NSAttributedStringKey const kSyntaxHighlightingStyleIDAttributeName;
extern NSAttributedStringKey const kSyntaxHighlightingStackName;
extern NSAttributedStringKey const kSyntaxHighlightingStateDelimiterName;
extern NSString * const kSyntaxHighlightingStateDelimiterStartValue;
extern NSString * const kSyntaxHighlightingStateDelimiterEndValue;
extern NSAttributedStringKey const kSyntaxHighlightingFoldDelimiterName;
extern NSAttributedStringKey const kSyntaxHighlightingTypeAttributeName;
extern NSAttributedStringKey const kSyntaxHighlightingScopenameAttributeName;
extern NSAttributedStringKey const kSyntaxHighlightingParentModeForSymbolsAttributeName;
extern NSAttributedStringKey const kSyntaxHighlightingParentModeForAutocompleteAttributeName;
extern NSAttributedStringKey const kSyntaxHighlightingFoldDelimiterName;
extern NSAttributedStringKey const kSyntaxHighlightingFoldingDepthAttributeName;
extern NSAttributedStringKey const kSyntaxHighlightingAutocompleteEndName;
extern NSAttributedStringKey const kSyntaxHighlightingIndentLevelName;

extern NSString * const kSyntaxHighlightingTypeComment;
extern NSString * const kSyntaxHighlightingTypeString;

@interface SyntaxHighlighter : NSObject {
    SyntaxDefinition *_syntaxDefinition;
}

@property (nonatomic, readonly) SyntaxDefinition *syntaxDefinition;

/*"Initizialisation"*/
- (instancetype)initWithSyntaxDefinition:(SyntaxDefinition *)aSyntaxDefinition;

/*"Accessors"*/
- (SyntaxStyle *)defaultSyntaxStyle;

/*"Highlighting"*/
-(void)highlightAttributedString:(NSMutableAttributedString*)aString inRange:(NSRange)aRange ofDocument:(id)aDocument;
//-(void)highlightPlainStringsOfAttributedString:(NSMutableAttributedString*)aString inRange:(NSRange)aRange forState:(NSString *)aState;
//-(void)highlightRegularExpressionsOfAttributedString:(NSMutableAttributedString*)aString inRange:(NSRange)aRange forState:(NSString *)aState;

/*"Document Interaction"*/
- (void)updateStylesInTextStorage:(NSTextStorage *)aTextStorage ofDocument:(id)aSender;
- (BOOL)colorizeDirtyRanges:(NSTextStorage *)aTextStorage ofDocument:(id)sender;
- (void)cleanUpTextStorage:(NSTextStorage *)aTextStorage;
- (void)cleanUpTextStorage:(NSTextStorage *)aTextStorage inRange:(NSRange)aRange;

@end

@interface NSObject (SyntaxHighlighterDocument) 
- (NSDictionary *)styleAttributesForStyleID:(NSString *)aStyleID; // Old School
- (NSDictionary *)styleAttributesForScope:(NSString *)aScope languageContext:(NSString *)aLanguageContext; // Scope based
@end
