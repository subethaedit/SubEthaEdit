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

@interface NSArray (NSArrayTextStorageAdditions) 
- (NSArray *)arrayByRemovingObject:(id)anObject;
- (OGRegularExpression *)combinedRegex;
@end

@implementation NSArray (NSArrayTextStorageAdditions) 
- (NSArray *)arrayByRemovingObject:(id)anObject {
    NSMutableArray *result=[[self mutableCopy] autorelease];
    [result removeObject:anObject];
    return (NSArray *)result;
}
- (OGRegularExpression *)combinedRegex {
    return [OGRegularExpression regularExpressionWithString:[self componentsJoinedByString:@"|"]];
}
@end

@implementation TextStorage

- (void)TCM_initHelper {
    I_blockedit.hasBlockeditRanges=NO;
    I_blockedit.isBlockediting    =NO;
    I_blockedit.didBlockedit      =NO;
    I_blockedit.didBlockeditRange = NSMakeRange(NSNotFound,0);
    I_blockedit.didBlockeditLineRange = NSMakeRange(NSNotFound,0);

    I_flags.shouldWatchLineEndings = YES;
    I_flags.hasMixedLineEndings    = NO;
    I_lineEnding = LineEndingLF;
    I_contents=[NSMutableAttributedString new];
    I_lineStarts=[NSMutableArray new];
    [I_lineStarts addObject:[NSNumber numberWithUnsignedInt:0]];
    I_lineStartsValidUpTo=0;
    I_encoding=CFStringConvertEncodingToNSStringEncoding(CFStringGetSystemEncoding());
    [[EncodingManager sharedInstance] registerEncoding:I_encoding];
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
    
    [[EncodingManager sharedInstance] unregisterEncoding:I_encoding];
    [I_contents release];
    [I_lineStarts  release];
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

+ (OGRegularExpression *)wrongLineEndingRegex:(LineEnding)aLineEnding {
    switch(aLineEnding) {
        case LineEndingCR: {
            static OGRegularExpression *sWrong;
            if (!sWrong)
                sWrong=
                    [[[S_AllLineEndingRegexPartsArray arrayByRemovingObject:S_LineEndingCRRegExPart] combinedRegex] retain];
            return sWrong;
        }
        case LineEndingCRLF: {
            static OGRegularExpression *sWrong;
            if (!sWrong)
                sWrong=
                    [[[S_AllLineEndingRegexPartsArray arrayByRemovingObject:S_LineEndingCRLFRegExPart] combinedRegex] retain];
            return sWrong;
        }
        case LineEndingUnicodeLineSeparator: {
            static OGRegularExpression *sWrong;
            if (!sWrong)
                sWrong=
                    [[[S_AllLineEndingRegexPartsArray arrayByRemovingObject:S_LineEndingUnicodeLineSeparatorRegExPart] combinedRegex] retain];
            return sWrong;
        }
        case LineEndingUnicodeParagraphSeparator:{
            static OGRegularExpression *sWrong;
            if (!sWrong)
                sWrong=
                    [[[S_AllLineEndingRegexPartsArray arrayByRemovingObject:S_LineEndingUnicodeParagraphSeparatorRegExPart] combinedRegex] retain];
            return sWrong;
        }
        case LineEndingLF: 
        default: {
            static OGRegularExpression *sWrong;
            if (!sWrong)
                sWrong=
                    [[[S_AllLineEndingRegexPartsArray arrayByRemovingObject:S_LineEndingLFRegExPart] combinedRegex] retain];
            return sWrong;
        }
    }
}

- (void)setHasMixedLineEndings:(BOOL)aFlag {
    if (aFlag!=I_flags.hasMixedLineEndings) {
        I_flags.hasMixedLineEndings = aFlag;
//        NSLog(@"hasMixedLineEndings: %@",aFlag?@"YES":@"NO");
        [[NSNotificationQueue defaultQueue] 
            enqueueNotification:
                [NSNotification notificationWithName:TextStorageHasMixedLineEndingsDidChange object:self] 
                   postingStyle:NSPostWhenIdle 
                   coalesceMask:NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender 
                       forModes:nil];
    }
}

- (void)setShouldWatchLineEndings:(BOOL)aFlag {
    I_flags.shouldWatchLineEndings = aFlag;
}

- (BOOL)hasMixedLineEndingsInRange:(NSRange)aRange {
    static int limit = 0;
    if (limit==0) limit = [[NSUserDefaults standardUserDefaults] integerForKey:@"ByteLengthToUseForModeRecognitionAndEncodingGuessing"];
    if (aRange.length > limit && limit != -1) aRange.length = limit;

    OGRegularExpression *wrongExpression = [TextStorage wrongLineEndingRegex:[self lineEnding]];
    OGRegularExpressionMatch *match = [wrongExpression matchInString:[self string] range:aRange];
    return [match count]!=0;
}

- (void)validateHasMixedLineEndings {
    [self setHasMixedLineEndings:[self hasMixedLineEndingsInRange:NSMakeRange(0, [self length])]];
}

- (LineEnding)lineEnding {
    return I_lineEnding;
}
- (void)setLineEnding:(LineEnding)newLineEnding {
    if (I_lineEnding!= newLineEnding) {
        I_lineEnding = newLineEnding;
        [self validateHasMixedLineEndings];
        [[NSNotificationQueue defaultQueue] 
            enqueueNotification:
                [NSNotification notificationWithName:TextStorageLineEndingDidChange object:self] 
                   postingStyle:NSPostASAP 
                   coalesceMask:NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender 
                       forModes:nil];
    }
}

- (BOOL)hasMixedLineEndings {
    return I_flags.hasMixedLineEndings;
}

- (unsigned int)encoding {
    return I_encoding;
}

- (void)setEncoding:(unsigned int)anEncoding {
    [[EncodingManager sharedInstance] unregisterEncoding:I_encoding];
    I_encoding = anEncoding;
    [[EncodingManager sharedInstance] registerEncoding:anEncoding];
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

- (NSString *)positionStringForRange:(NSRange)aRange {
    int lineNumber=[self lineNumberForLocation:aRange.location];
    unsigned lineStartLocation=[[[self lineStarts] objectAtIndex:lineNumber-1] intValue];
    int positionInLine = aRange.location-lineStartLocation;
    NSString *string=[NSString stringWithFormat:@"%d:%d",lineNumber, positionInLine];
    if (aRange.length>0) string=[string stringByAppendingFormat:@" (%d)",aRange.length];
    return string;
}


- (unsigned)numberOfLines {
    return [self lineNumberForLocation:[self length]];
}
- (unsigned)numberOfCharacters {
    return [self length];
}
- (unsigned)numberOfWords {
    static int limit = 0;
    if (limit==0) limit = [[NSUserDefaults standardUserDefaults] integerForKey:@"ByteLengthToUseForModeRecognitionAndEncodingGuessing"];
    
    if (I_numberOfWords == 0 && limit>[self length]) {
        static OGRegularExpression *s_wordCountRegex = nil;
        if (!s_wordCountRegex) {
            s_wordCountRegex = [[OGRegularExpression regularExpressionWithString:@"[\\w']+"] retain];
        }
        I_numberOfWords  = [[s_wordCountRegex allMatchesInString:[self string]] count];
    }
    return I_numberOfWords;
}


- (int)lineNumberForLocation:(unsigned)aLocation {

    if (I_lineStartsValidUpTo == 0 && [I_lineStarts count] > 1) {
        [I_lineStarts removeAllObjects];
        [I_lineStarts addObject:[NSNumber numberWithUnsignedInt:0]];
    } else {
        while ([[I_lineStarts lastObject] unsignedIntValue] > I_lineStartsValidUpTo) {
            [I_lineStarts removeLastObject];
        }
    }

    int i;
    int result=0;
    if (!(aLocation<=I_lineStartsValidUpTo)) {
        NSString *string=[self string];
        unsigned int length = [string length];
        i=[I_lineStarts count]-1;
        unsigned lineStart=[[I_lineStarts objectAtIndex:i] unsignedIntValue];
        NSRange lineRange=[string lineRangeForRange:NSMakeRange(lineStart,0)];
        I_lineStartsValidUpTo=NSMaxRange(lineRange)-1;
        while (NSMaxRange(lineRange)<length && I_lineStartsValidUpTo<aLocation) {
            lineRange=[string lineRangeForRange:NSMakeRange(NSMaxRange(lineRange),0)];
            [I_lineStarts addObject:[NSNumber numberWithUnsignedInt:lineRange.location]];
            I_lineStartsValidUpTo=NSMaxRange(lineRange)-1;
        }
        if (NSMaxRange(lineRange)==length) {
            NSRange lastRange=[string lineRangeForRange:NSMakeRange(length,0)];
            if (lastRange.location == length && [[I_lineStarts lastObject] intValue] != length) {
                [I_lineStarts addObject:[NSNumber numberWithUnsignedInt:length]];
                I_lineStartsValidUpTo=length;
            }
        }

    }
    for (i=[I_lineStarts count]-1;i>=0;i--) {
        if ([[I_lineStarts objectAtIndex:i] unsignedIntValue]<=aLocation) {
            result=i+1;
            break;
        }
    }
    return result;
}

- (NSMutableArray *)lineStarts {
    return I_lineStarts;
}

- (void)setLineStartsOnlyValidUpTo:(unsigned int)aLocation {
    [self willChangeValueForKey:@"numberOfLines"];
    if (aLocation<I_lineStartsValidUpTo) {
        I_lineStartsValidUpTo=aLocation;
    }
    I_numberOfWords = 0;
    [self didChangeValueForKey:@"numberOfLines"];
}

- (NSRange)findLine:(int)aLineNumber {
    NSString *string=[self string];
    NSRange lineRange=NSMakeRange(NSNotFound,0);
    unsigned length = [string length];
    if (aLineNumber < 1) return lineRange;

    if (I_lineStartsValidUpTo == 0 && [I_lineStarts count] > 1) {
        [I_lineStarts removeAllObjects];
        [I_lineStarts addObject:[NSNumber numberWithUnsignedInt:0]];
    } else {
        while ([[I_lineStarts lastObject] unsignedIntValue] > I_lineStartsValidUpTo) {
            [I_lineStarts removeLastObject];
        }
    }

    if ([I_lineStarts count]<aLineNumber) {
        int lineNumber=[I_lineStarts count];
        lineRange=[string lineRangeForRange:NSMakeRange([[I_lineStarts objectAtIndex:lineNumber-1] unsignedIntValue],0)];
        while (lineNumber<aLineNumber && NSMaxRange(lineRange)<length) {
            lineRange=[string lineRangeForRange:NSMakeRange(NSMaxRange(lineRange),0)];
            [I_lineStarts addObject:[NSNumber numberWithUnsignedInt:lineRange.location]];
            I_lineStartsValidUpTo=NSMaxRange(lineRange)-1;
            lineNumber++;
        }
        if (NSMaxRange(lineRange)==length) {
            NSRange lastRange=[string lineRangeForRange:NSMakeRange(length,0)];
            if (lastRange.location == length && [[I_lineStarts lastObject] intValue] != length) {
                lineRange = lastRange;
                [I_lineStarts addObject:[NSNumber numberWithUnsignedInt:length]];
                I_lineStartsValidUpTo=length;
            }
        }
    } else {
        lineRange=[string lineRangeForRange:NSMakeRange([[I_lineStarts objectAtIndex:aLineNumber-1] unsignedIntValue],0)];
    }
    // NSLog(@"%@ %s %d",NSStringFromRange(lineRange), __FUNCTION__, aLineNumber);
    return lineRange;
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

- (NSDictionary *)attributeDictionaryByAddingStyleAttributesForInsertLocation:(unsigned int)inLocation toDictionary:(NSDictionary *)inBaseStyle
{
	unsigned int length = [self length];
	if (inLocation > length || inLocation < 1) return inBaseStyle; // do nothing if document is empty, or the proposed insertion point is beyond the current size
	
	// if this is not the case, copy the appropriate styles
	inLocation = inLocation - 1; // select the style from the character in front of the insertion, range validity was checked above
	NSDictionary *attributes = [self attributesAtIndex:inLocation effectiveRange:NULL];
	NSMutableDictionary *resultDictionary = [[inBaseStyle mutableCopy] autorelease];
	
	// currently visual style means font and color so copy these
	NSFont *font = [attributes objectForKey:NSFontAttributeName];
	if (font && [[[resultDictionary objectForKey:NSFontAttributeName] familyName] isEqualToString:[font familyName]]) [resultDictionary setObject:font forKey:NSFontAttributeName];
	NSColor *foregroundColor = [attributes objectForKey:NSForegroundColorAttributeName];
	if (foregroundColor) [resultDictionary setObject:foregroundColor forKey:NSForegroundColorAttributeName];

	
	return resultDictionary;
}


#pragma mark -
#pragma mark ### Abstract Primitives of NSTextStorage ###

- (NSString *)string {
    return [I_contents string];
}

- (NSDictionary *)attributesAtIndex:(unsigned)aIndex 
                     effectiveRange:(NSRangePointer)aRange {
	if ([self length]==0) return nil;
    return [I_contents attributesAtIndex:aIndex effectiveRange:aRange];
}

- (void)replaceCharactersInRange:(NSRange)aRange withString:(NSString *)aString {
    id delegate = [self delegate];
    if ([delegate respondsToSelector:@selector(textStorage:willReplaceCharactersInRange:withString:)]) {
        [delegate textStorage:self willReplaceCharactersInRange:aRange withString:aString];
    }
    BOOL needsCompleteValidation = NO;
    if (I_flags.shouldWatchLineEndings && I_flags.hasMixedLineEndings && aRange.length && [self hasMixedLineEndingsInRange:aRange]) {
        needsCompleteValidation = YES;
    }
    unsigned origLen = [I_contents length];
    [I_contents replaceCharactersInRange:aRange withString:aString];
    [self edited:NSTextStorageEditedCharacters range:aRange 
          changeInLength:[I_contents length] - origLen];
    if ([delegate respondsToSelector:@selector(textStorage:didReplaceCharactersInRange:withString:)]) {
        [delegate textStorage:self didReplaceCharactersInRange:aRange withString:aString];
    }
    [self setLineStartsOnlyValidUpTo:aRange.location];
    if (I_flags.shouldWatchLineEndings && [aString length] > 0 && (!I_flags.hasMixedLineEndings || needsCompleteValidation)) {
        if ([self hasMixedLineEndingsInRange:NSMakeRange(aRange.location, [aString length])]) {
            [self setHasMixedLineEndings:YES];
            needsCompleteValidation=NO;
        }
    }
    if (needsCompleteValidation) {
        [self validateHasMixedLineEndings];
    }
}

- (void)setAttributes:(NSDictionary *)attributes range:(NSRange)aRange {
    [I_contents setAttributes:attributes range:aRange];
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
