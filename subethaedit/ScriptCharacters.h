//
//  ScriptCharacters.h
//  SubEthaEdit
//
//  Created by Martin Ott on 5/2/06.
//  Copyright 2006 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ScriptTextBase.h"

@class FoldableTextStorage;

@interface ScriptCharacters : ScriptTextBase {
    NSRange      I_characterRange;
}

+ (id)scriptCharactersWithTextStorage:(FoldableTextStorage *)aTextStorage characterRange:(NSRange)aCharacterRange;
- (id)initWithTextStorage:(FoldableTextStorage *)aTextStorage characterRange:(NSRange)aCharacterRange;

@end
