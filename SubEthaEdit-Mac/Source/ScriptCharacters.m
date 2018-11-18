//  ScriptCharacters.m
//  SubEthaEdit
//
//  Created by Martin Ott on 5/2/06.

#import "ScriptCharacters.h"
#import "FoldableTextStorage.h"
#import "PlainTextDocument.h"


@implementation ScriptCharacters

+ (id)scriptCharactersWithTextStorage:(FullTextStorage *)aTextStorage characterRange:(NSRange)aCharacterRange {
    return [[[ScriptCharacters alloc] initWithTextStorage:aTextStorage characterRange:aCharacterRange] autorelease];
}

- (id)initWithTextStorage:(FullTextStorage *)aTextStorage characterRange:(NSRange)aCharacterRange
{
    if ((self = [super initWithTextStorage:aTextStorage])) {
        I_characterRange = aCharacterRange;
    }
    return self;
}

- (void)dealloc
{
    [super dealloc];
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
            [[[NSIndexSpecifier alloc] initWithContainerClassDescription:containerClassDesc
                                                      containerSpecifier:nil
                                                                     key:@"scriptedCharacters"
                                                                   index:I_characterRange.location] autorelease];
        [startSpecifier setContainerIsRangeContainerObject:YES];

        NSIndexSpecifier *endSpecifier = 
            [[[NSIndexSpecifier alloc] initWithContainerClassDescription:containerClassDesc
                                                      containerSpecifier:nil
                                                                     key:@"scriptedCharacters"
                                                                   index:NSMaxRange(I_characterRange) - 1] autorelease];
        [endSpecifier setContainerIsRangeContainerObject:YES];

        NSRangeSpecifier *rangeSpecifier = 
            [[[NSRangeSpecifier alloc] initWithContainerClassDescription:containerClassDesc
                                                      containerSpecifier:containerSpecifier
                                                                     key:@"scriptedCharacters"
                                                          startSpecifier:startSpecifier
                                                            endSpecifier:endSpecifier] autorelease];  

        return rangeSpecifier;
    } else {
        NSIndexSpecifier *indexSpecifier = 
            [[[NSIndexSpecifier alloc] initWithContainerClassDescription:containerClassDesc
                                                      containerSpecifier:containerSpecifier
                                                                     key:@"scriptedCharacters"
                                                                   index:I_characterRange.location] autorelease];

        return indexSpecifier;
    }
}

@end
