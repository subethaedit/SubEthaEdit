//
//  SyntaxHighlighter.h
//  SyntaxHighlighter
//
//  Created by Martin Pittenauer on Tue Feb 25 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <regex.h>

#define kHeaderKey              		@"Header"
#define kStylesKey           		   	@"Styles"
#define kExtensionsKey        		  	@"Extensions"
#define kNameKey              		  	@"Name"
#define kColorKey            		   	@"Color"
#define kPlainStringsKey      		  	@"Plain Strings" 
#define kRegularExpressionsKey 		 	@"Regular Expressions"
#define kFunctionsRegExKey     		 	@"Functions Regular Expression"
#define kFunctionsModifersKey			@"Function Modifiers"
#define kNotKeywordKey				@"Valid Characters for Variables"
#define kMultilineKey				@"Multiline"
#define kCommentAttribute			@"Comment"
#define kSyntaxColoringIsDirtyAttributeValue 	@"SyntaxDirty"
#define kSyntaxColoringIsDirtyAttribute		@"SyntaxDirty"
#define kMultilineAttribute			@"Mulitline"
#define kInsertedByUserAttribute		@"InsertedByUser"
#define kHighlightFromUserAttribute		@"HighlightFromUser"



@interface SyntaxHighlighter : NSObject {
    NSMutableDictionary *definition;
    NSCharacterSet *notKeyword;
    NSMutableArray *simples,*multilines;
    NSMutableDictionary *regularExpressions;
}

// Initalizer
- (id)init; // Returns nil: No Syntax, no Highlight
- (id)initWithFile:(NSString *)synfile;
- (id)initWithName:(NSString *)aName;
- (id)initWithExtension:(NSString *)anExtension;

// Public
- (BOOL) colorizeDirtyRanges:(NSMutableAttributedString*)aString;
- (NSArray*)symbolsInAttributedString:(NSAttributedString*)aString;
- (BOOL) hasSymbols;
- (void) cleanup:(NSMutableAttributedString*)aString;

@end
