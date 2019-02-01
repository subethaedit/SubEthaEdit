//  RegexSymbolParser.h
//  SubEthaEdit
//
//  Created by Martin Pittenauer on Fri Apr 16 2004.

#import <Foundation/Foundation.h>
#import "RegexSymbolDefinition.h"

@interface RegexSymbolParser : NSObject {
    RegexSymbolDefinition *I_symbolDefinition;
}
- (id)initWithSymbolDefinition:(RegexSymbolDefinition *)aSymbolDefinition;

@property (nonatomic, strong) RegexSymbolDefinition *symbolDefinition;

/*"Document Interaction"*/
- (NSArray *)symbolsForTextStorage:(NSTextStorage *)aTextStorage;
- (NSArray *)symbolsForTextStorage:(NSTextStorage *)aTextStorage inRange:(NSRange)aRange;

@end
