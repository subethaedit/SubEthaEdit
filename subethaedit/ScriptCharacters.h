//
//  ScriptCharacters.h
//  SubEthaEdit
//
//  Created by Martin Ott on 5/2/06.
//  Copyright 2006 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ScriptTextBase.h"

@class TextStorage;

@interface ScriptCharacters : ScriptTextBase {
    TextStorage *I_textStorage;
    NSRange      I_characterRange;
}

+ (id)scriptCharactersWithTextStorage:(TextStorage *)aTextStorage characterRange:(NSRange)aCharacterRange;
- (id)initWithTextStorage:(TextStorage *)aTextStorage characterRange:(NSRange)aCharacterRange;

@end
