//
//  ScriptCharacters.h
//  SubEthaEdit
//
//  Created by Martin Ott on 5/2/06.
//  Copyright 2006 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TextStorage;

@interface ScriptCharacters : NSObject {
    TextStorage *I_textStorage;
    NSRange      I_characterRange;
}

+ (id)scriptCharactersWithTextStorage:(TextStorage *)aTextStorage characterRange:(NSRange)aCharacterRange;
- (id)initWithTextStorage:(TextStorage *)aTextStorage characterRange:(NSRange)aCharacterRange;
- (NSRange)saveRange;
- (NSNumber *)scriptedLength;
- (NSNumber *)scriptedCharacterOffset;
- (NSNumber *)scriptedStartLine;
- (NSNumber *)scriptedEndLine;
- (NSString *)text;
- (void)setText:(id)value;

@end
