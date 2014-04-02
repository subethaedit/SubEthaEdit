//
//  SyntaxHighlighter.h
//  SyntaxTestBench
//
//  Created by Martin Pittenauer on Thu Mar 04 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SyntaxDefinition.h"

extern NSString * const kSyntaxHighlightingIsCorrectAttributeName;
extern NSString * const kSyntaxHighlightingIsCorrectAttributeValue;
extern NSString * const kSyntaxHighlightingIsTrimmedStartAttributeName;
extern NSString * const kSyntaxHighlightingIsTrimmedStartAttributeValue;
extern NSString * const kSyntaxHighlightingStyleIDAttributeName;
extern NSString * const kSyntaxHighlightingStackName;
extern NSString * const kSyntaxHighlightingStateDelimiterName;
extern NSString * const kSyntaxHighlightingStateDelimiterStartValue;
extern NSString * const kSyntaxHighlightingStateDelimiterEndValue;
extern NSString * const kSyntaxHighlightingFoldDelimiterName;
extern NSString * const kSyntaxHighlightingTypeAttributeName;
extern NSString * const kSyntaxHighlightingScopenameAttributeName;
extern NSString * const kSyntaxHighlightingParentModeForSymbolsAttributeName;
extern NSString * const kSyntaxHighlightingParentModeForAutocompleteAttributeName;
extern NSString * const kSyntaxHighlightingFoldDelimiterName;
extern NSString * const kSyntaxHighlightingFoldingDepthAttributeName;
extern NSString * const kSyntaxHighlightingAutocompleteEndName;
extern NSString * const kSyntaxHighlightingIndentLevelName;

extern NSString * const kSyntaxHighlightingTypeComment;
extern NSString * const kSyntaxHighlightingTypeString;

@interface SyntaxHighlighter : NSObject {
    SyntaxDefinition *I_syntaxDefinition;
    NSMutableArray *I_parseStack;
	NSLock *I_stringLock;
}

/*"Initizialisation"*/
- (id)initWithSyntaxDefinition:(SyntaxDefinition *)aSyntaxDefinition;

/*"Accessors"*/
- (SyntaxDefinition *)syntaxDefinition;
- (void)setSyntaxDefinition:(SyntaxDefinition *)aSyntaxDefinition;
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
