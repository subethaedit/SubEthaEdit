//
//  SyntaxManager.h
//  XXP
//
//  Created by Martin Pittenauer on Tue Mar 04 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kSyntaxColoringIsDirtyAttributeValue  @"SyntaxDirty"
#define kSyntaxColoringIsDirtyAttribute		  @"SyntaxDirty"

@protocol SyntaxHighlighter 
- (id)initWithFile:(NSString *)synfile;

- (BOOL)colorizeDirtyRanges:(NSMutableAttributedString*)aString;
- (NSArray*)symbolsInAttributedString:(NSAttributedString*)aString;
- (BOOL)hasSymbols;
- (void)cleanup:(NSMutableAttributedString*)aString;

@end


@interface SyntaxManager : NSObject {
    NSMutableArray      *I_definitions;
    NSMutableDictionary *I_availableSyntaxNames;
    Class I_highlighterClass;
}

+ (SyntaxManager *)sharedInstance;
- (void) reloadSyntaxDefinitions;

// Public API:
- (NSDictionary *) availableSyntaxNames;
- (NSString *) syntaxDefinitionForExtension:(NSString *) anExtension;
- (NSString *) syntaxDefinitionForName:(NSString *) aName;
- (id <SyntaxHighlighter>)syntaxHighlighterForExtension:(NSString *)anExtension;
- (id <SyntaxHighlighter>)syntaxHighlighterForName:(NSString *)aName;


@end
