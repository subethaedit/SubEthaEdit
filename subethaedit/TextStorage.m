//
//  TextStorage.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Thu Mar 25 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "TextStorage.h"
#import "EncodingManager.h"
#import "PlainTextDocument.h"

NSString * const BlockeditAttributeName =@"Blockedit";
NSString * const BlockeditAttributeValue=@"YES";


@implementation TextStorage

- (id)init {
    self=[super init];
    if (self) {
        I_blockedit.hasBlockeditRanges=NO;
        I_blockedit.isBlockediting    =NO;
        I_blockedit.didBlockedit      =NO;
        I_blockedit.didBlockeditRange = NSMakeRange(NSNotFound,0);
        I_blockedit.didBlockeditLineRange = NSMakeRange(NSNotFound,0);


        I_contents=[NSMutableAttributedString new];
        I_lineStarts=[NSMutableArray new];
        [I_lineStarts addObject:[NSNumber numberWithUnsignedInt:0]];
        I_lineStartsValidUpTo=0;
        I_encoding=CFStringConvertEncodingToNSStringEncoding(CFStringGetSystemEncoding());
        [[EncodingManager sharedInstance] registerEncoding:I_encoding];
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

- (unsigned int)encoding {
    return I_encoding;
}

- (void)setEncoding:(unsigned int)anEncoding {
    [[EncodingManager sharedInstance] unregisterEncoding:I_encoding];
    I_encoding = anEncoding;
    [[EncodingManager sharedInstance] registerEncoding:anEncoding];
}

#pragma mark -
#pragma mark ### Line Numbers ###

- (NSString *)positionStringForRange:(NSRange)aRange {
    int lineNumber=[self lineNumberForLocation:aRange.location];
    unsigned lineStartLocation=[[[self lineStarts] objectAtIndex:lineNumber-1] intValue];
    NSString *string=[NSString stringWithFormat:@"%d:%d",lineNumber, aRange.location-lineStartLocation];
    if (aRange.length>0) string=[string stringByAppendingFormat:@" (%d)",aRange.length];
    return string;
}


- (int)lineNumberForLocation:(unsigned)aLocation {

    // validate I_lineStarts array
    int i;
    for (i=[I_lineStarts count]-1;i>=0;i--) {
        if ([[I_lineStarts objectAtIndex:i] unsignedIntValue]<=I_lineStartsValidUpTo) {
            break;
        } else {
            [I_lineStarts removeObjectAtIndex:i];    
        }
    }
    NSAssert(i>=0,@"Failure in lineNumberForLocation");
    int result=0;
    if (!(aLocation<=I_lineStartsValidUpTo)) {
        NSString *string=[self string];
        i=[I_lineStarts count]-1;
        unsigned lineStart=[[I_lineStarts objectAtIndex:i] unsignedIntValue];
        NSRange lineRange=[string lineRangeForRange:NSMakeRange(lineStart,0)];
        I_lineStartsValidUpTo=NSMaxRange(lineRange)-1;
        while (NSMaxRange(lineRange)<[string length] && I_lineStartsValidUpTo<aLocation) {
            lineRange=[string lineRangeForRange:NSMakeRange(NSMaxRange(lineRange),0)];
            [I_lineStarts addObject:[NSNumber numberWithUnsignedInt:lineRange.location]];
            I_lineStartsValidUpTo=NSMaxRange(lineRange)-1;
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
    if (aLocation<I_lineStartsValidUpTo) {
        I_lineStartsValidUpTo=aLocation;
    }
}

- (NSRange)findLine:(int)aLineNumber {
    NSString *string=[self string];
    NSRange lineRange=NSMakeRange(NSNotFound,0);
    if (aLineNumber < 1) return lineRange;
    if ([I_lineStarts count]<aLineNumber) {
        int lineNumber=[I_lineStarts count];
        lineRange=[string lineRangeForRange:NSMakeRange([[I_lineStarts objectAtIndex:lineNumber-1] unsignedIntValue],0)];
        while (lineNumber<aLineNumber && NSMaxRange(lineRange)<[string length]) {
            lineRange=[string lineRangeForRange:NSMakeRange(NSMaxRange(lineRange),0)];
            [I_lineStarts addObject:[NSNumber numberWithUnsignedInt:lineRange.location]];
            I_lineStartsValidUpTo=NSMaxRange(lineRange)-1;
            lineNumber++;
        }
    } else {
        lineRange=[string lineRangeForRange:NSMakeRange([[I_lineStarts objectAtIndex:aLineNumber-1] unsignedIntValue],0)];
    }
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
}


- (int)blockChangeTextInRange:(NSRange)aRange replacementString:(NSString *)aReplacementString
           lineRange:(NSRange)aLineRange inTextView:(NSTextView *)aTextView {
    int lengthChange=0;
    int tabWidth=[(PlainTextDocument *)[[[aTextView window] windowController] document] tabWidth];
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
            // issue: add tabs when tab mode
            if (detabbedLengthOfLine!=aRange.location) {
                aReplacementString=[NSString stringWithFormat:@"%@%@",
                                    [@" " stringByPaddingToLength:aRange.location-detabbedLengthOfLine
                                                     withString:@" " startingAtIndex:0],
                                    aReplacementString];
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
		                aReplacementString=[NSString stringWithFormat:@"%@%@",
		                                    aReplacementString,
		                                    [@" " stringByPaddingToLength:spacesTheTabTakes-(NSMaxRange(aRange)-toLength)
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
            [textStorage setAttributes:[aTextView typingAttributes] 
                                 range:NSMakeRange(aReplacementRange.location,[aReplacementString length])];
        }
    }

    return lengthChange;
}

- (NSRange)blockChangeTextInRange:(NSRange)aRange replacementString:(NSString *)aReplacementString
        paragraphRange:(NSRange)aParagraphRange inTextView:(NSTextView *)aTextView {
 
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
                     lineRange:lineRange inTextView:aTextView];
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

#pragma mark -
#pragma mark ### Abstract Primitives of NSTextStorage ###

- (NSString *)string {
    return [I_contents string];
}

- (NSDictionary *)attributesAtIndex:(unsigned)aIndex 
                     effectiveRange:(NSRangePointer)aRange {
    return [I_contents attributesAtIndex:aIndex effectiveRange:aRange];
}

- (void)replaceCharactersInRange:(NSRange)aRange withString:(NSString *)aString {
    unsigned origLen = [I_contents length];
    [I_contents replaceCharactersInRange:aRange withString:aString];
    id delegate = [self delegate];
    [self edited:NSTextStorageEditedCharacters range:aRange 
          changeInLength:[I_contents length] - origLen];
    if ([delegate respondsToSelector:@selector(textStorage:didReplaceCharactersInRange:withString:)]) {
        [delegate textStorage:self didReplaceCharactersInRange:aRange withString:aString];
    }
    [self setLineStartsOnlyValidUpTo:aRange.location];
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
    NSMutableDictionary *dictionary=[NSMutableDictionary dictionary];
    [dictionary setObject:[[[self string] copy] autorelease] forKey:@"String"];
    [dictionary setObject:[NSNumber numberWithUnsignedInt:[self encoding]] forKey:@"Encoding"];
    NSMutableDictionary *attributeDictionary=[NSMutableDictionary new];
    NSEnumerator *attributeNames=[[NSArray arrayWithObjects:WrittenByUserIDAttributeName,ChangedByUserIDAttributeName,nil] objectEnumerator];
    NSString *attributeName;
    NSRange wholeRange=NSMakeRange(0,[self length]);
    if (wholeRange.length) {
        while ((attributeName=[attributeNames nextObject])) {
            NSMutableArray *attributeArray=[NSMutableArray new];
            NSRange searchRange=NSMakeRange(0,0);
            while (NSMaxRange(searchRange)<wholeRange.length) {
                id value=[self attribute:attributeName atIndex:NSMaxRange(searchRange) 
                       longestEffectiveRange:&searchRange inRange:wholeRange];
                if (value) {
                    [attributeArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                        value,@"val",
                        [NSNumber numberWithUnsignedInt:searchRange.location],@"loc",
                        [NSNumber numberWithUnsignedInt:searchRange.length],@"len",
                        nil]];
                }
            }
            if ([attributeArray count]) {
                [attributeDictionary setObject:attributeArray forKey:attributeName];
            }
            [attributeArray release];
        }
    }
    [dictionary setObject:attributeDictionary forKey:@"Attributes"];
    [attributeDictionary release];
    return dictionary;
}

- (void)setContentByDictionaryRepresentation:(NSDictionary *)aRepresentation {
    [self beginEditing];
    NSString *string=[aRepresentation objectForKey:@"String"];
    if (string && [string isKindOfClass:[NSString class]]) {
        [self replaceCharactersInRange:NSMakeRange(0,[self length]) withString:@""];
        [self replaceCharactersInRange:NSMakeRange(0,[self length]) withString:string];
        NSRange wholeRange=NSMakeRange(0,[self length]);
        NSNumber *encoding=[aRepresentation objectForKey:@"Encoding"];
        if (encoding && [encoding isKindOfClass:[NSNumber class]]) {
            [self setEncoding:[encoding unsignedIntValue]];
        }
        NSDictionary *attributes=[aRepresentation objectForKey:@"Attributes"];
        if (attributes && [attributes isKindOfClass:[NSDictionary class]]) {
            NSEnumerator *attributeNames=[attributes keyEnumerator];
            NSString *attributeName=nil;
            while ((attributeName=[attributeNames nextObject])) {
                NSArray *attributeArray=[attributes objectForKey:attributeName];
                if ([attributeArray isKindOfClass:[NSArray class]]) {
                    NSEnumerator *attributeRuns=[attributeArray objectEnumerator];
                    NSDictionary *attributeRun=nil;
                    while ((attributeRun=[attributeRuns nextObject])) {
                        id value=[attributeRun objectForKey:@"val"];
                        NSNumber *location=[attributeRun objectForKey:@"loc"];
                        NSNumber *length=[attributeRun objectForKey:@"len"];
                        if (location && length && value && 
                            [location isKindOfClass:[NSNumber class]] &&
                            [length   isKindOfClass:[NSNumber class]]) {
                            NSRange attributeRange=NSMakeRange([location unsignedIntValue],[length unsignedIntValue]);
                            attributeRange=NSIntersectionRange(attributeRange,wholeRange);
                            if (attributeRange.length>0) {
                                [self addAttribute:attributeName value:value range:attributeRange];
                            }
                        }
                    }
                }
            }
        }
    }
    [self endEditing];
}



@end
