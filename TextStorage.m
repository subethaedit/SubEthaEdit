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


NSString * const BlockeditAttributeName =@"Blockedit";
NSString * const BlockeditAttributeValue=@"YES";

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
    I_blockedit.hasBlockeditRanges=NO;
    I_blockedit.isBlockediting    =NO;
    I_blockedit.didBlockedit      =NO;
    I_blockedit.didBlockeditRange = NSMakeRange(NSNotFound,0);
    I_blockedit.didBlockeditLineRange = NSMakeRange(NSNotFound,0);

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
- (BOOL)lastLineIsEmpty {
    unsigned lineStartIndex, lineEndIndex;
    [[self string] getLineStart:&lineStartIndex end:&lineEndIndex contentsEnd:NULL forRange:NSMakeRange([self length],0)];
    return lineStartIndex == lineEndIndex;
}

- (void)fixParagraphStyleAttributeInRange:(NSRange)aRange {
    [super fixParagraphStyleAttributeInRange:aRange];

    NSDictionary *blockeditAttributes=[[self delegate] blockeditAttributesForTextStorage:self];

    NSString *string=[self string];
    NSRange lineRange=[string lineRangeForRange:aRange];
    NSRange blockeditRange;
    id value;
    unsigned position=lineRange.location;
    while (position<NSMaxRange(lineRange)) {
        value=[self attribute:BlockeditAttributeName atIndex:position
                            longestEffectiveRange:&blockeditRange inRange:lineRange];
        if (value) {
            NSRange blockLineRange=[string lineRangeForRange:blockeditRange];
            if (!NSEqualRanges(blockLineRange,blockeditRange)) {
                blockeditRange=blockLineRange;
                [self addAttributes:blockeditAttributes range:blockeditRange];
            }
        }
        position=NSMaxRange(blockeditRange);
    }
    
    if ([[[[self delegate] documentMode] defaultForKey:DocumentModeIndentWrappedLinesPreferenceKey] boolValue]) {
        NSFont *font=[[self delegate] fontWithTrait:0];
        int tabWidth=[[self delegate] tabWidth];
        float characterWidth=[font widthOfString:@" "];
        int indentWrappedCharacterAmount = [[[[self delegate] documentMode] defaultForKey:DocumentModeIndentWrappedLinesCharacterAmountPreferenceKey] intValue];
        // look at all the lines and fixe the indention
        NSRange myRange = NSMakeRange(aRange.location,0);
        do {
            myRange = [string lineRangeForRange:NSMakeRange(NSMaxRange(myRange),0)];
            if (myRange.length>0) {
                NSParagraphStyle *style=[self attribute:NSParagraphStyleAttributeName atIndex:myRange.location effectiveRange:NULL];
                if (style) {
                    float desiredHeadIndent = characterWidth*[string detabbedLengthForRange:[string rangeOfLeadingWhitespaceStartingAt:myRange.location] tabWidth:tabWidth] + [style firstLineHeadIndent] + indentWrappedCharacterAmount * characterWidth;
                    
                    if (ABS([style headIndent]-desiredHeadIndent)>0.01) {
                        NSMutableParagraphStyle *newStyle=[style mutableCopy];
                        [newStyle setHeadIndent:desiredHeadIndent];
                        [self addAttribute:NSParagraphStyleAttributeName value:newStyle range:myRange];
                        [newStyle release];
                    }
                }
            }
        } while (NSMaxRange(myRange)<NSMaxRange(aRange)); 
    }
}


- (int)blockChangeTextInRange:(NSRange)aRange replacementString:(NSString *)aReplacementString
           lineRange:(NSRange)aLineRange inTextView:(NSTextView *)aTextView tabWidth:(unsigned)aTabWidth useTabs:(BOOL)aUseTabs{
    int lengthChange=0;
    int tabWidth=aTabWidth;
    TextStorage *textStorage=self;
    NSRange aReplacementRange=aRange;
    NSString *string=[textStorage string];
    aReplacementRange.location+=aLineRange.location;
    // don't touch newlines
    {
        unsigned lineEnd,contentsEnd;
        [[textStorage string]  getLineStart:nil 
                                        end:&lineEnd 
                                contentsEnd:&contentsEnd 
                                   forRange:aLineRange];
        aLineRange.length-=lineEnd-contentsEnd;
    }
    unsigned detabbedLengthOfLine=[string detabbedLengthForRange:aLineRange tabWidth:tabWidth];
    if (detabbedLengthOfLine<=aRange.location) {
        // the line is to short, so just add whitespace
//        NSLog(@"line to short %u/%u",detabbedLengthOfLine,aRange.location);
        if ([aReplacementString length]>0) {
//            NSLog(@"no replacment length");
            if (detabbedLengthOfLine!=aRange.location) {
                if (aUseTabs) {
                    int lengthDifference=aRange.location-detabbedLengthOfLine;
                    int lengthOfFirstTab=tabWidth-(detabbedLengthOfLine%tabWidth);
                    if (lengthOfFirstTab>lengthDifference) {
                        aReplacementString=[NSString stringWithFormat:@"%@%@",
                                        [@"" stringByPaddingToLength:aRange.location-detabbedLengthOfLine
                                                         withString:@" " startingAtIndex:0],
                                        aReplacementString];
                    } else {
                        int numberOfTabs=(lengthDifference-lengthOfFirstTab)/tabWidth;
                        aReplacementString=[NSString stringWithFormat:@"\t%@%@%@",
                                        [@"" stringByPaddingToLength:numberOfTabs
                                                         withString:@"\t" startingAtIndex:0],
                                        [@"" stringByPaddingToLength:(lengthDifference-lengthOfFirstTab-tabWidth*numberOfTabs)
                                                         withString:@" " startingAtIndex:0],
                                        aReplacementString];
                    }
                } else {
                    aReplacementString=[NSString stringWithFormat:@"%@%@",
                                        [@"" stringByPaddingToLength:aRange.location-detabbedLengthOfLine
                                                         withString:@" " startingAtIndex:0],
                                        aReplacementString];
                }
            }
            aReplacementRange.location=NSMaxRange(aLineRange);
            aReplacementRange.length=0;
        } else {
            aReplacementRange.location=NSNotFound;
        }
    } else { // detabbedLengthOfLine>aRange.location
        // check if our location is character aligned
//        NSLog(@"line long enough %u/%u",detabbedLengthOfLine,aRange.location);
        unsigned length,index;
        if ([string detabbedLength:aRange.location fromIndex:aLineRange.location 
                            length:&length upToCharacterIndex:&index tabWidth:tabWidth]) {
            // we were character aligned
//            NSLog(@"location is aligned: %u - in line: %u",index,index-aLineRange.location);
            aReplacementRange.location=index;
            if (aReplacementRange.length>0) {
                if (NSMaxRange(aRange)>=detabbedLengthOfLine) {
                    //line is shorter than what we wanted to replace, so replace everything
                    aReplacementRange.length=NSMaxRange(aLineRange)-index;
                } else {
                    unsigned toIndex,toLength;
                    if ([string detabbedLength:NSMaxRange(aRange) fromIndex:aLineRange.location
                                        length:&toLength upToCharacterIndex:&toIndex tabWidth:tabWidth]) {
                        aReplacementRange.length=toIndex-index;
                    } else {
                    	aReplacementRange.length=toIndex-index+1;
                        int spacesTheTabTakes=tabWidth-(toLength)%tabWidth;
//                        NSLog(@"there tab took %d spaces, replacementRange: %@, replacmentString:%@",spacesTheTabTakes,NSStringFromRange(aReplacementRange),aReplacementString);
		                aReplacementString=[NSString stringWithFormat:@"%@%@",
		                                    aReplacementString,
		                                    [@" " stringByPaddingToLength:spacesTheTabTakes-(NSMaxRange(aRange)-toLength)
		                                                     withString:@" " startingAtIndex:0]];
                    }
                }
            }
        } else {
//            NSLog(@"location is not aligned: %u - in line: %u",index,index-aLineRange.location);
            // our location is not character aligned
            // so index points to a tab and length is shorter than wanted
            aReplacementRange.location=index;
            // apply padding spaces to the beginning and ending of your replacementString, 
            // according to the tab
            // aReplacementRange.length=0; // we don't replace the tab
            aReplacementString=[NSString stringWithFormat:@"%@%@",
                                [@" " stringByPaddingToLength:(aRange.location-length)
                                                 withString:@" " startingAtIndex:0],
                                aReplacementString];
            if (aReplacementRange.length!=0) {
                unsigned toIndex,toLength;
                if ([string detabbedLength:NSMaxRange(aRange) fromIndex:aLineRange.location
                                    length:&toLength upToCharacterIndex:&toIndex tabWidth:tabWidth]) {
                    aReplacementRange.length=toIndex-index;
                } else {           
                    	aReplacementRange.length=toIndex-index+1;
                        int spacesTheTabTakes=tabWidth-(toLength)%tabWidth;
                        int paddingLength = MAX(0,spacesTheTabTakes-(int)(NSMaxRange(aRange)-toLength));
		                aReplacementString=[NSString stringWithFormat:@"%@%@",
		                                    aReplacementString,
		                                    [@" " stringByPaddingToLength:paddingLength
		                                                     withString:@" " startingAtIndex:0]];
                }
            }
        }
    }


// change the stuff
    if (aReplacementRange.location!=NSNotFound) {
        if (NSMaxRange(aReplacementRange)>NSMaxRange(aLineRange)) {
            aReplacementRange.length=NSMaxRange(aLineRange)-aReplacementRange.location;
        }
        if ([aTextView shouldChangeTextInRange:aReplacementRange 
                             replacementString:aReplacementString]) {
            lengthChange+=[aReplacementString length]-aReplacementRange.length;
            [textStorage replaceCharactersInRange:aReplacementRange 
                                       withString:aReplacementString];
            [textStorage addAttributes:[aTextView typingAttributes] 
                                 range:NSMakeRange(aReplacementRange.location,[aReplacementString length])];
        }
    }

    return lengthChange;
}

- (NSRange)blockChangeTextInRange:(NSRange)aRange replacementString:(NSString *)aReplacementString
        paragraphRange:(NSRange)aParagraphRange inTextView:(NSTextView *)aTextView 
        tabWidth:(unsigned)aTabWidth useTabs:(BOOL)aUseTabs {
 
//    NSLog(@"blockChangeTextInRange: %@",NSStringFromRange(aRange));
    TextStorage *textStorage=self;
    NSString *string=[textStorage string];
    NSRange lineRange;
        
    aParagraphRange=[string lineRangeForRange:aParagraphRange];
    int lengthChange=0;
    
    [textStorage beginEditing];
    lineRange.location=NSMaxRange(aParagraphRange)-1;
    lineRange.length  =1;
    lineRange=[string lineRangeForRange:lineRange];        
    int result=0;
    while (!DisjointRanges(lineRange,aParagraphRange)) {
        result=[self blockChangeTextInRange:aRange replacementString:aReplacementString
                     lineRange:lineRange inTextView:aTextView tabWidth:(unsigned)aTabWidth useTabs:(BOOL)aUseTabs];
        lengthChange+=result;
        // special case
        if (lineRange.location==0) break;
        
        lineRange=[string lineRangeForRange:NSMakeRange(lineRange.location-1,1)];  
    }
    [textStorage endEditing];
    [aTextView didChangeText];

    return NSMakeRange(aParagraphRange.location,aParagraphRange.length+lengthChange);
}


- (BOOL)hasBlockeditRanges {
    return I_blockedit.hasBlockeditRanges;
}
- (void)setHasBlockeditRanges:(BOOL)aFlag {
    if (aFlag != I_blockedit.hasBlockeditRanges) {
        I_blockedit.hasBlockeditRanges=aFlag;
        id delegate=[self delegate];
        SEL selector=I_blockedit.hasBlockeditRanges?
                     @selector(textStorageDidStartBlockedit:):
                     @selector(textStorageDidStopBlockedit:);
        if ([delegate respondsToSelector:selector]) {
            [delegate performSelector:selector withObject:self];
        }
    }
}

- (BOOL)isBlockediting {
    return I_blockedit.isBlockediting;
}
- (void)setIsBlockediting:(BOOL)aFlag {
    I_blockedit.isBlockediting=aFlag;
}

- (BOOL)didBlockedit {
    return I_blockedit.didBlockedit;
}
- (void)setDidBlockedit:(BOOL)aFlag {
    I_blockedit.didBlockedit=aFlag;
}

- (NSRange)didBlockeditRange {
    return I_blockedit.didBlockeditRange;
}
- (void)setDidBlockeditRange:(NSRange)aRange {
    I_blockedit.didBlockeditRange=aRange;
}

- (NSRange)didBlockeditLineRange {
    return I_blockedit.didBlockeditLineRange;
}
- (void)setDidBlockeditLineRange:(NSRange)aRange {
    I_blockedit.didBlockeditLineRange=aRange;
}

- (void)stopBlockedit {
    NSDictionary *blockeditAttributes=[[self delegate] blockeditAttributesForTextStorage:self];
    NSArray *attributeNameArray=[blockeditAttributes allKeys];
    NSRange range;
    NSRange wholeRange=NSMakeRange(0,[self length]);
    [self beginEditing];
    unsigned position=wholeRange.location;
    while (position<wholeRange.length) {
        id value=[self attribute:BlockeditAttributeName atIndex:position 
                       longestEffectiveRange:&range inRange:wholeRange];
        if (value) {
            int i=0;
            for (i=0;i<[attributeNameArray count];i++) {
                [self removeAttribute:[attributeNameArray objectAtIndex:i]
                                range:range];
            }
        }
        position=NSMaxRange(range);
    }
    [self endEditing];
    [self setHasBlockeditRanges:NO];
}

- (void)removeAttributes:(id)anObjectEnumerable range:(NSRange)aRange {
    NSEnumerator *attributeNames=[anObjectEnumerable objectEnumerator];
    id attributeName=nil;
    while ((attributeName=[attributeNames nextObject])) {
        [self removeAttribute:attributeName
                        range:aRange];
    }
}

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
