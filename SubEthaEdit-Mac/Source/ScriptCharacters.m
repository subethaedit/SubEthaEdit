//  ScriptCharacters.m
//  SubEthaEdit
//
//  Created by Martin Ott on 5/2/06.

#import "ScriptCharacters.h"
#import "FoldableTextStorage.h"
#import "PlainTextDocument.h"

// this file needs arc - add -fobjc-arc in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

@implementation ScriptCharacters

+ (id)scriptCharactersWithTextStorage:(FullTextStorage *)aTextStorage characterRange:(NSRange)aCharacterRange {
    return [[ScriptCharacters alloc] initWithTextStorage:aTextStorage characterRange:aCharacterRange];
}

- (id)initWithTextStorage:(FullTextStorage *)aTextStorage characterRange:(NSRange)aCharacterRange
{
    if ((self = [super initWithTextStorage:aTextStorage])) {
        I_characterRange = aCharacterRange;
    }
    return self;
}

- (NSRange)rangeRepresentation {
    return RangeConfinedToRange(I_characterRange,NSMakeRange(0,[I_textStorage length]));
}

- (id)objectSpecifier
{
    // NSLog(@"%s", __FUNCTION__);

    NSScriptClassDescription *containerClassDesc = (NSScriptClassDescription *)[NSScriptClassDescription classDescriptionForClass:[FoldableTextStorage class]];
    NSScriptObjectSpecifier *containerSpecifier = [I_textStorage objectSpecifier];
    
    if (I_characterRange.length > 1) {
        NSIndexSpecifier *startSpecifier = 
            [[NSIndexSpecifier alloc] initWithContainerClassDescription:containerClassDesc
                                                      containerSpecifier:nil
                                                                     key:@"scriptedCharacters"
                                                                   index:I_characterRange.location];
        [startSpecifier setContainerIsRangeContainerObject:YES];

        NSIndexSpecifier *endSpecifier = 
            [[NSIndexSpecifier alloc] initWithContainerClassDescription:containerClassDesc
                                                      containerSpecifier:nil
                                                                     key:@"scriptedCharacters"
                                                                   index:NSMaxRange(I_characterRange) - 1];
        [endSpecifier setContainerIsRangeContainerObject:YES];

        NSRangeSpecifier *rangeSpecifier = 
            [[NSRangeSpecifier alloc] initWithContainerClassDescription:containerClassDesc
                                                      containerSpecifier:containerSpecifier
                                                                     key:@"scriptedCharacters"
                                                          startSpecifier:startSpecifier
                                                            endSpecifier:endSpecifier];

        return rangeSpecifier;
    } else {
        NSIndexSpecifier *indexSpecifier = 
            [[NSIndexSpecifier alloc] initWithContainerClassDescription:containerClassDesc
                                                      containerSpecifier:containerSpecifier
                                                                     key:@"scriptedCharacters"
                                                                   index:I_characterRange.location];

        return indexSpecifier;
    }
}

@end
