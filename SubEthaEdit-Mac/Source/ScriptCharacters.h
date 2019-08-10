//  ScriptCharacters.h
//  SubEthaEdit
//
//  Created by Martin Ott on 5/2/06.

#import <Cocoa/Cocoa.h>
#import "ScriptTextBase.h"

@class FoldableTextStorage;

@interface ScriptCharacters : ScriptTextBase {
    NSRange      I_characterRange;
}

+ (id)scriptCharactersWithTextStorage:(FullTextStorage *)aTextStorage characterRange:(NSRange)aCharacterRange;
- (instancetype)initWithTextStorage:(FullTextStorage *)aTextStorage characterRange:(NSRange)aCharacterRange;

@end
