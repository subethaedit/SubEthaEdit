//
//  ScriptCharacters.m
//  SubEthaEdit
//
//  Created by Martin Ott on 5/2/06.
//  Copyright 2006 TheCodingMonkeys. All rights reserved.
//

#import "ScriptCharacters.h"
#import "TextStorage.h"
#import "PlainTextDocument.h"


@implementation ScriptCharacters

+ (void)initialize {
    NSLog(@"%s", __FUNCTION__);
    [[NSScriptCoercionHandler sharedCoercionHandler] registerCoercer:self selector:@selector(coerceString:toClass:) toConvertFromClass:[NSString class] toClass:[NSArray class]];
}

+ (id)coerceString:(NSString *)aString toClass:(Class)aClass {
    NSLog(@"%s", __FUNCTION__);
    return [NSArray arrayWithObject:aString];
}

+ (id)scriptCharactersWithTextStorage:(TextStorage *)aTextStorage characterRange:(NSRange)aCharacterRange {
    return [[[ScriptCharacters alloc] initWithTextStorage:aTextStorage characterRange:aCharacterRange] autorelease];
}

- (id)initWithTextStorage:(TextStorage *)aTextStorage characterRange:(NSRange)aCharacterRange
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
    return NSIntersectionRange(NSMakeRange(0,[I_textStorage length]),I_characterRange);
}

- (id)objectSpecifier
{
    NSLog(@"%s", __FUNCTION__);

    NSScriptClassDescription *containerClassDesc = (NSScriptClassDescription *)[NSScriptClassDescription classDescriptionForClass:[TextStorage class]];
    NSScriptObjectSpecifier *containerSpecifier = [I_textStorage objectSpecifier];
    
    if (I_characterRange.length > 1) {
        NSIndexSpecifier *startSpecifier = 
            [[[NSIndexSpecifier alloc] initWithContainerClassDescription:containerClassDesc
                                                      containerSpecifier:nil
                                                                     key:@"characters"
                                                                   index:I_characterRange.location] autorelease];
        [startSpecifier setContainerIsRangeContainerObject:YES];

        NSIndexSpecifier *endSpecifier = 
            [[[NSIndexSpecifier alloc] initWithContainerClassDescription:containerClassDesc
                                                      containerSpecifier:nil
                                                                     key:@"characters"
                                                                   index:NSMaxRange(I_characterRange) - 1] autorelease];
        [endSpecifier setContainerIsRangeContainerObject:YES];

        NSRangeSpecifier *rangeSpecifier = 
            [[[NSRangeSpecifier alloc] initWithContainerClassDescription:containerClassDesc
                                                      containerSpecifier:containerSpecifier
                                                                     key:@"characters"
                                                          startSpecifier:startSpecifier
                                                            endSpecifier:endSpecifier] autorelease];  

        return rangeSpecifier;
    } else {
        NSIndexSpecifier *indexSpecifier = 
            [[[NSIndexSpecifier alloc] initWithContainerClassDescription:containerClassDesc
                                                      containerSpecifier:containerSpecifier
                                                                     key:@"characters"
                                                                   index:I_characterRange.location] autorelease];

        return indexSpecifier;
    }
}

@end
