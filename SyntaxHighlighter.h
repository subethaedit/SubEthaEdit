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
extern NSString * const kSyntaxHighlightingStyleIDAttributeName;

@interface SyntaxHighlighter : NSObject {
    SyntaxDefinition *I_syntaxDefinition;
    NSMutableArray *I_parseStack;
    id theDocument;
}

/*"Initizialisation"*/
- (id)initWithSyntaxDefinition:(SyntaxDefinition *)aSyntaxDefinition;

/*"Accessors"*/
- (SyntaxDefinition *)syntaxDefinition;
- (void)setSyntaxDefinition:(SyntaxDefinition *)aSyntaxDefinition;
- (SyntaxStyle *)defaultSyntaxStyle;

/*"Highlighting"*/
-(void)highlightAttributedString:(NSMutableAttributedString*)aString inRange:(NSRange)aRange;
-(void)highlightPlainStringsOfAttributedString:(NSMutableAttributedString*)aString inRange:(NSRange)aRange forState:(NSString *)aState;
-(void)highlightRegularExpressionsOfAttributedString:(NSMutableAttributedString*)aString inRange:(NSRange)aRange forState:(NSString *)aState;

/*"Document Interaction"*/
- (void)updateStylesInTextStorage:(NSTextStorage *)aTextStorage ofDocument:(id)aSender;
- (BOOL)colorizeDirtyRanges:(NSTextStorage *)aTextStorage ofDocument:(id)sender;
- (void)cleanUpTextStorage:(NSTextStorage *)aTextStorage;
- (void)cleanUpTextStorage:(NSTextStorage *)aTextStorage inRange:(NSRange)aRange;

@end

@interface NSObject (SyntaxHighlighterDocument) 
- (NSDictionary *)styleAttributesForStyleID:(NSString *)aStyleID;
@end
