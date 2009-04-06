//
//  TextStorage.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Thu Mar 25 2004.
//  Copyright (c) 2004-2006 TheCodingMonkeys. All rights reserved.
//

#import "TextStorage.h"
#import "EncodingManager.h"
#import "PlainTextDocument.h"
#import "PlainTextWindowController.h"
#import "TCMMMUserManager.h"
#import "SelectionOperation.h"
#import "TCMMMUserSEEAdditions.h"
#import "GeneralPreferences.h"
#import "ScriptTextSelection.h"
#import "ScriptLine.h"
#import "ScriptCharacters.h"
#import "DocumentMode.h"


NSString * const TextStorageLineEndingDidChange =
               @"TextStorageLineEndingDidChange";
NSString * const TextStorageHasMixedLineEndingsDidChange =
               @"TextStorageHasMixedLineEndingsDidChange";

static NSString * S_LineEndingLFRegExPart;
static NSString * S_LineEndingCRRegExPart;
static NSString * S_LineEndingCRLFRegExPart;
static NSString * S_LineEndingUnicodeLineSeparatorRegExPart;
static NSString * S_LineEndingUnicodeParagraphSeparatorRegExPart;
static NSArray  * S_AllLineEndingRegexPartsArray;

@implementation TextStorage

- (void)TCM_initHelper {
    I_internalAttributedString=[NSMutableAttributedString new];
}


- (id)init {
    self = [super init];
    if (self) {
        [self TCM_initHelper];
        I_containerTextStorage = nil;
    }
    return self;
}

- (void)dealloc {
    // maybe fixed:
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [I_internalAttributedString release];
    [super dealloc];
}

+ (void)initialize {
    static NSString *sUnicodeLSEP=nil;
    static NSString *sUnicodePSEP=nil;
    if (sUnicodeLSEP==nil) {
        unichar seps[2];
        seps[0]=0x2028;
        seps[1]=0x2029;
        sUnicodeLSEP=[[NSString stringWithCharacters:seps   length:1] retain];
        sUnicodePSEP=[[NSString stringWithCharacters:seps+1 length:1] retain];
    }
    S_LineEndingLFRegExPart = @"(?:(?<!\r)\n)";
    S_LineEndingCRRegExPart = @"(?:\r(?!\n))";
    S_LineEndingCRLFRegExPart = @"(?:\r\n)";
    S_LineEndingUnicodeLineSeparatorRegExPart = [[NSString alloc] initWithFormat:@"(?:%@)", sUnicodeLSEP];
    S_LineEndingUnicodeParagraphSeparatorRegExPart = [[NSString alloc] initWithFormat:@"(?:%@)", sUnicodePSEP];
    S_AllLineEndingRegexPartsArray = [[NSArray alloc] initWithObjects:S_LineEndingLFRegExPart,S_LineEndingCRRegExPart,S_LineEndingCRLFRegExPart,S_LineEndingUnicodeLineSeparatorRegExPart,S_LineEndingUnicodeParagraphSeparatorRegExPart,nil];
}

- (NSRange)doubleClickAtIndex:(unsigned)index {
    NSRange result=[super doubleClickAtIndex:index];
    NSRange colonRange;
    NSString *string=[self string];
    while (((colonRange = [string rangeOfString:@":" options:NSLiteralSearch range:result]).location != NSNotFound)) {
        if (index <= colonRange.location) {
            result.length = colonRange.location-result.location;
            break;
        } else {
            result = NSMakeRange(NSMaxRange(colonRange),NSMaxRange(result)-NSMaxRange(colonRange));
        }
    }
    // NSLog(@"doubleClickAtIndex:%d returned: %@",index,NSStringFromRange(result));
    return result;
}

- (NSArray *)selectionOperationsForRangesUnconvertableToEncoding:(NSStringEncoding)encoding {
//    NSLog(@"%s beginning",__FUNCTION__);
    NSMutableArray *array = [NSMutableArray array];
    NSString *string = [self string];
    unsigned length = [string length];
    unsigned i;
    for (i = 0; i < length; i++) {
        unichar character = [string characterAtIndex:i];
        NSString *charString = [[NSString alloc] initWithCharactersNoCopy:&character length:1 freeWhenDone:NO];
        if (![charString canBeConvertedToEncoding:encoding]) {
            [array addObject:[SelectionOperation selectionOperationWithRange:NSMakeRange(i, 1) userID:[TCMMMUserManager myUserID]]];
        }
        [charString release];
    }
    
    // combinde adjacent selection operations
    int count = [array count];
    while (--count>0) {
        NSRange lowerRange  = [[array objectAtIndex:count-1] selectedRange];
        NSRange higherRange = [[array objectAtIndex:count] selectedRange];
        if (NSMaxRange(lowerRange) == higherRange.location) {
            [[array objectAtIndex:count-1] setSelectedRange:NSUnionRange(lowerRange,higherRange)];
            [array removeObjectAtIndex:count];
        }
    }
    
//    NSLog(@"%s end",__FUNCTION__);
    return array;
}


#pragma mark -
#pragma mark ### Line Numbers ###



#pragma mark -
#pragma mark ### Abstract Primitives of NSTextStorage ###

- (NSString *)string {
    return [I_internalAttributedString string];
}

- (NSDictionary *)attributesAtIndex:(unsigned)aIndex 
                     effectiveRange:(NSRangePointer)aRange {
    // TODO: fix this elsewhere, as this is probably not a good performance choice (see r2436)
//	if ([self length]==0) return nil;
 
    return [I_internalAttributedString attributesAtIndex:aIndex effectiveRange:aRange];
}

- (void)replaceCharactersInRange:(NSRange)aRange withString:(NSString *)aString {
    id delegate = [self delegate];
    if ([delegate respondsToSelector:@selector(textStorage:willReplaceCharactersInRange:withString:)]) {
        [delegate textStorage:self willReplaceCharactersInRange:aRange withString:aString];
    }
    unsigned origLen = [I_internalAttributedString length];
    [I_internalAttributedString replaceCharactersInRange:aRange withString:aString];
    [self edited:NSTextStorageEditedCharacters range:aRange 
          changeInLength:[I_internalAttributedString length] - origLen];
    if ([delegate respondsToSelector:@selector(textStorage:didReplaceCharactersInRange:withString:)]) {
        [delegate textStorage:self didReplaceCharactersInRange:aRange withString:aString];
    }
}

- (void)setAttributes:(NSDictionary *)attributes range:(NSRange)aRange {
    [I_internalAttributedString setAttributes:attributes range:aRange];
    [self edited:NSTextStorageEditedAttributes range:aRange 
          changeInLength:0];
}

#pragma mark -
#pragma mark ### Dictionary Representation ###

/*"Data:
    "String" => NSString content
    "Encoding" => NSNumber with encoding
    "Attributes" => NSDictionary 
        ("<AttributeName>" => NSArray 
            (NSDictionaries 
                ("val"=>Value - this time no change into NSData...
                 "loc"=>location 
                 "len"=>length) 
            )
        )
"*/

- (NSDictionary *)dictionaryRepresentation {
    return [self dictionaryRepresentationUsingEncoding:[self encoding]];
}

- (void)setContentByDictionaryRepresentation:(NSDictionary *)aRepresentation {
    [super setContentByDictionaryRepresentation:aRepresentation];
    NSNumber *encoding=[aRepresentation objectForKey:@"Encoding"];
    if (encoding && [encoding isKindOfClass:[NSNumber class]]) {
        [self setEncoding:[encoding unsignedIntValue]];
    }
}


#pragma mark -
#pragma mark ### XHTML Export ###


- (NSMutableAttributedString *)attributedStringForXHTMLExportWithRange:(NSRange)aRange foregroundColor:(NSColor *)aForegroundColor backgroundColor:(NSColor *)aBackgroundColor {
    NSString *htmlForgreoundColor=[aForegroundColor HTMLString];
    NSMutableAttributedString *result=[[[NSMutableAttributedString alloc] initWithString:[[self string] substringWithRange:aRange]] autorelease];
    unsigned int index;
    NSFontManager *fontManager=[NSFontManager sharedFontManager];
    
    index=aRange.location;
    do {
        NSRange foundRange;
        NSFont *font=[self attribute:NSFontAttributeName atIndex:index longestEffectiveRange:&foundRange inRange:aRange];
        index=NSMaxRange(foundRange);
        if (font) {
            unsigned traitMask=[fontManager traitsOfFont:font] & (NSBoldFontMask | NSItalicFontMask);
            if (traitMask) {
                foundRange.location=foundRange.location-aRange.location;
                [result addAttribute:@"FontTraits" 
                    value:[NSNumber numberWithUnsignedInt:traitMask]
                    range:foundRange];
                if (traitMask & NSBoldFontMask) {
                    [result addAttribute:@"Bold" value:[NSNumber numberWithBool:YES] range:foundRange];
                }
                if (traitMask & NSItalicFontMask) {
                    [result addAttribute:@"Italic" value:[NSNumber numberWithBool:YES] range:foundRange];
                }
            }
        }
    } while (index<NSMaxRange(aRange));

    index=aRange.location;
    do {
        NSRange foundRange;
        NSNumber *number=[self attribute:NSObliquenessAttributeName atIndex:index longestEffectiveRange:&foundRange inRange:aRange];
        index=NSMaxRange(foundRange);
        if (number && [number floatValue] != 0.0) {
            [result addAttribute:@"Italic" value:[NSNumber numberWithBool:YES] range:foundRange];
        }
    } while (index<NSMaxRange(aRange));

    index=aRange.location;
    do {
        NSRange foundRange;
        NSNumber *number=[self attribute:NSStrokeWidthAttributeName atIndex:index longestEffectiveRange:&foundRange inRange:aRange];
        index=NSMaxRange(foundRange);
        if (number && [number floatValue] != 0.0) {
            [result addAttribute:@"Bold" value:[NSNumber numberWithBool:YES] range:foundRange];
        }
    } while (index<NSMaxRange(aRange));

    index=aRange.location;
    do {
        NSRange foundRange;
        NSColor *color=[self attribute:NSForegroundColorAttributeName atIndex:index longestEffectiveRange:&foundRange inRange:aRange];
        index=NSMaxRange(foundRange);
        if (color) {
            NSString *xhtmlColor=[color HTMLString];
            if (![xhtmlColor isEqualToString:htmlForgreoundColor]) {
                foundRange.location=foundRange.location-aRange.location;
                [result addAttribute:@"ForegroundColor" 
                    value:xhtmlColor
                    range:foundRange];
            }
        }
    } while (index<NSMaxRange(aRange));

    index=aRange.location;
    do {
        NSRange foundRange;
        NSString *author=[self attribute:WrittenByUserIDAttributeName atIndex:index longestEffectiveRange:&foundRange inRange:aRange];
        index=NSMaxRange(foundRange);
        if (author) {
            foundRange.location=foundRange.location-aRange.location;
            [result addAttribute:@"WrittenBy" value:[[[[TCMMMUserManager sharedInstance] userForUserID:author] name] stringByReplacingEntitiesForUTF8:NO] range:foundRange];
            [result addAttribute:@"WrittenByUserID" value:author range:foundRange];
        }
    } while (index<NSMaxRange(aRange));

    index=aRange.location;
    do {
        NSRange foundRange;
        NSString *author=[self attribute:ChangedByUserIDAttributeName atIndex:index longestEffectiveRange:&foundRange inRange:aRange];
        index=NSMaxRange(foundRange);
        if (author) {
            foundRange.location=foundRange.location-aRange.location;
            [result addAttribute:@"ChangedBy" value:author range:foundRange];
            NSColor *changeColor=[[[TCMMMUserManager sharedInstance] userForUserID:author] changeColor];
            NSColor *userBackgroundColor=[aBackgroundColor blendedColorWithFraction:
                                [[NSUserDefaults standardUserDefaults] floatForKey:ChangesSaturationPreferenceKey]/100.
                             ofColor:changeColor];
            [result addAttribute:@"BackgroundColor" value:[userBackgroundColor HTMLString] range:foundRange];
            [result addAttribute:@"ChangedByUserID" value:author range:foundRange];
        }
    } while (index<NSMaxRange(aRange));
    
    return result;
}
 
@end

#pragma mark -

@implementation TextStorage (TextStorageScriptingAdditions)

- (NSRange)rangeRepresentation {
    return NSMakeRange(0,[self length]);
}

- (NSArray *)scriptedCharacters {
    // NSLog(@"%s", __FUNCTION__);
    NSMutableArray *result=[NSMutableArray array];
    int length=[self length];
    int index=0;
    while (index<length) {
        [result addObject:[ScriptCharacters scriptCharactersWithTextStorage:self characterRange:NSMakeRange(index++,1)]];
    }
    return result;
}

- (unsigned int)countOfScriptedCharacters {
    return [self length];
}

- (id)valueInScriptedCharactersAtIndex:(unsigned)index
{
    // NSLog(@"%s: %d", __FUNCTION__, index);
    return [ScriptCharacters scriptCharactersWithTextStorage:self characterRange:NSMakeRange(index,1)];
}

- (void)insertObject:(id)anObject inScriptedCharactersAtIndex:(unsigned)anIndex {
    // has to be there for KVC not to mourn
}

- (void)removeObjectFromScriptedCharactersAtIndex:(unsigned)anIndex {
//    NSLog(@"%s: %d", __FUNCTION__, anIndex);
    [[self valueInScriptedCharactersAtIndex:anIndex] setScriptedContents:@""];
}

- (NSArray *)scriptedLines
{
    // NSLog(@"%s", __FUNCTION__);
    int lineCount = 1;
    if ([self length]>0) {
        lineCount = [self lineNumberForLocation:[self length]];
    }
    NSMutableArray *lines = [NSMutableArray array];
    int lineNumber = 1;
    for (lineNumber=1;lineNumber<=lineCount;lineNumber++) {
        [lines addObject:[ScriptLine scriptLineWithTextStorage:self lineNumber:lineNumber]];
    }
    return lines;
}

- (id)valueInScriptedLinesAtIndex:(unsigned)index
{
    // NSLog(@"%s: %d", __FUNCTION__, index);
    return [ScriptLine scriptLineWithTextStorage:self lineNumber:index+1];
}

- (void)insertObject:(id)anObject inScriptedLinesAtIndex:(unsigned)anIndex {
    // has to be there for KVC not to mourn
}

- (void)removeObjectFromScriptedLinesAtIndex:(unsigned)anIndex {
    NSLog(@"%s: %d", __FUNCTION__, anIndex);
    [[self valueInScriptedLinesAtIndex:anIndex] setScriptedContents:@""];
}

- (NSString *)scriptedContents
{
    // NSLog(@"%s", __FUNCTION__);
    return [self string];
}

- (void)setScriptedContents:(id)value {
    // NSLog(@"%s: %d", __FUNCTION__, value);
    [[self delegate] replaceTextInRange:NSMakeRange(0,[self length]) withString:value];
}

- (id)insertionPoints
{
    NSMutableArray *resultArray=[NSMutableArray new];
    int index=0;
    int length=[self length];
    for (index=0;index<=length;index++) {
        [resultArray addObject:[ScriptTextSelection insertionPointWithTextStorage:self index:index]];
    }
    return resultArray;
}

- (id)valueInInsertionPointsAtIndex:(unsigned)anIndex {
    return [ScriptTextSelection insertionPointWithTextStorage:self index:anIndex];
}


- (NSNumber *)scriptedLength
{
    return [NSNumber numberWithInt:[self length]];
}

- (NSNumber *)scriptedStartCharacterIndex
{
    return [NSNumber numberWithInt:1];
}

- (NSNumber *)scriptedNextCharacterIndex
{
    return [NSNumber numberWithInt:[self length]];
}


- (NSNumber *)scriptedStartLine
{
    return [NSNumber numberWithInt:1];
}

- (NSNumber *)scriptedEndLine
{
    int lineNumber;
    int length = [self length];
    if (length > 0) {
        lineNumber = [self lineNumberForLocation:length - 1];
    } else {
        lineNumber = 1;
    }
    return [NSNumber numberWithInt:lineNumber];
}

- (id)objectSpecifier
{
    NSScriptClassDescription *containerClassDesc = 
        (NSScriptClassDescription *)[NSScriptClassDescription classDescriptionForClass:[PlainTextDocument class]];
    
    NSScriptObjectSpecifier *containerSpecifier = [[self delegate] objectSpecifier];
    NSPropertySpecifier *propertySpecifier = 
        [[[NSPropertySpecifier alloc] initWithContainerClassDescription:containerClassDesc
                                                     containerSpecifier:containerSpecifier
                                                                    key:@"scriptedPlainContents"] autorelease];

    return propertySpecifier;
}

/*
- (void)replaceValueAtIndex:(unsigned)index inPropertyWithKey:(NSString *)key withValue:(id)value
{
    if ([key isEqual:@"characters"]) {
        TextStorage *character = [self valueInCharactersAtIndex:index];
        TextStorage *textStorage = self;
        if (I_containerTextStorage)
            textStorage = I_containerTextStorage;
        [[textStorage delegate] replaceTextInRange:NSMakeRange([[character scriptedCharacterOffset] intValue] - 1, 1) withString:value];
    } else if ([key isEqual:@"words"]) {
        NSArray *words = [self words];
        if ([words count] > index && [words count] > 0) {
            TextStorage *word = [words objectAtIndex:index];
            TextStorage *textStorage = self;
            if (I_containerTextStorage)
                textStorage = I_containerTextStorage;
            [[textStorage delegate] replaceTextInRange:NSMakeRange([[word scriptedCharacterOffset] intValue] - 1, [[word scriptedLength] intValue]) withString:value];
        }
    } else if ([key isEqual:@"paragraphs"]) {
        TextStorage *paragraph = [self valueInParagraphsAtIndex:index];
        TextStorage *textStorage = self;
        if (I_containerTextStorage)
            textStorage = I_containerTextStorage;
        [[textStorage delegate] replaceTextInRange:NSMakeRange([[paragraph scriptedCharacterOffset] intValue] - 1, [[paragraph scriptedLength] intValue]) withString:value];
    }
}
*/

@end
