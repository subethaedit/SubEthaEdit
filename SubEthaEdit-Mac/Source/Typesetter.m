//
//  Typesetter.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 10.04.06.
//  Copyright 2006 TheCodingMonkeys. All rights reserved.
//

#import "Typesetter.h"

static Typesetter *S_sharedInstance=nil;

@implementation Typesetter

+ (id)sharedInstance {
    if (!S_sharedInstance) S_sharedInstance=[self new];
    return S_sharedInstance;
}

- (NSTypesetterControlCharacterAction)actionForControlCharacterAtIndex:(unsigned)charIndex {
    // take care of ASCII 11:
    unichar character = [[[self attributedString] string] characterAtIndex:charIndex];
    NSLog(@"control character was: %d",character);
    NSTypesetterControlCharacterAction result = [super actionForControlCharacterAtIndex:charIndex];
    NSLog(@"result:%d",result);
    switch (result) {
        case NSTypesetterZeroAdvancementAction: 
     NSLog(@"NSTypesetterZeroAdvancementAction"); break;
        case NSTypesetterParagraphBreakAction: 
     NSLog(@"NSTypesetterParagraphBreakAction"); break;
        case NSTypesetterContainerBreakAction: 
     NSLog(@"NSTypesetterContainerBreakAction"); break;
        case NSTypesetterLineBreakAction: 
     NSLog(@"NSTypesetterLineBreakAction"); break;
        case NSTypesetterWhitespaceAction: 
     NSLog(@"NSTypesetterWhitespaceAction"); break;
        case NSTypesetterHorizontalTabAction: 
     NSLog(@"NSTypesetterHorizontalTabAction"); break;
        default:
            NSLog(@"don't know");
    }
    if (character == 11) return NSTypesetterWhitespaceAction;
    return result;
}

- (NSRect)boundingBoxForControlGlyphAtIndex:(unsigned)glyphIndex 
                           forTextContainer:(NSTextContainer *)textContainer 
                       proposedLineFragment:(NSRect)proposedRect 
                              glyphPosition:(NSPoint)glyphPosition 
                             characterIndex:(unsigned)charIndex {
    NSRect result = NSZeroRect;
//    if ([super respondsToSelector:@selector(boundingBoxForControlGlyphAtIndex:forTextContainer:proposedLineFragment:glyphPosition:characterIndex:)]) {
//        result = [super boundingBoxForControlGlyphAtIndex:glyphIndex 
//                                         forTextContainer:textContainer 
//                                     proposedLineFragment:proposedRect 
//                                            glyphPosition:glyphPosition 
//                                           characterIndex:charIndex];
//    }
    unichar character = [[[self attributedString] string] characterAtIndex:charIndex];
    if (character = 11) { 
        NSLog(@"%@", NSStringFromRect(result));
        NSDictionary *attributes = [[self attributedString] attributesAtIndex:charIndex effectiveRange:NULL];
        result.size.width += [@"W" sizeWithAttributes:attributes].width;
        NSLog(@"after %@", NSStringFromRect(result));
        result.origin = glyphPosition;
        result.size.height = 1;
    }
    return result;
}

@end
