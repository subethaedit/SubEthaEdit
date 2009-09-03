//
//  FullTextStorage.m
//  TextEdit
//
//  Created by Dominik Wagner on 04.01.09.
//  Copyright 2009 TheCodingMonkeys. All rights reserved.
//


#import "FoldableTextStorage.h"
#import "FullTextStorage.h"
#import "EncodingManager.h"
#import "SyntaxHighlighter.h"
#import "SelectionOperation.h"
#import "TCMMMUserManager.h"

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


@implementation FullTextStorage

+ (void)initialize {
	if (self == [FullTextStorage class]) {
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

- (id)initWithFoldableTextStorage:(FoldableTextStorage *)inTextStorage {
    if ((self = [super init])) {
        I_internalAttributedString = [NSMutableAttributedString new];
        I_foldableTextStorage = inTextStorage; // no retain here - the foldableTextstorage owns us
        I_shouldNotSynchronize = 0;

		I_lineStarts=[NSMutableArray new];
		[I_lineStarts addObject:[NSNumber numberWithUnsignedInt:0]];
	    I_lineStartsValidUpTo=0;

		I_flags.shouldWatchLineEndings = YES;
		I_flags.hasMixedLineEndings    = NO;
		I_lineEnding = LineEndingLF;
		I_encoding=CFStringConvertEncodingToNSStringEncoding(CFStringGetSystemEncoding());
		[[EncodingManager sharedInstance] registerEncoding:I_encoding];
    }
    return self;
}

- (FoldableTextStorage *)foldableTextStorage {
	return I_foldableTextStorage;
}


- (void)dealloc {

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[EncodingManager sharedInstance] unregisterEncoding:I_encoding];
	[I_lineStarts  release];
	[I_internalAttributedString release];
	[super dealloc];
}

- (NSMutableAttributedString *)internalMutableAttributedString {
	return I_internalAttributedString;
}

#pragma mark -
#pragma mark ### Abstract Primitives of NSTextStorage ###

- (NSString *)string {
    return [I_internalAttributedString string];
}

- (NSDictionary *)attributesAtIndex:(unsigned)aIndex 
                     effectiveRange:(NSRangePointer)aRange {
	if ([self length]==0) return nil;
    return [I_internalAttributedString attributesAtIndex:aIndex effectiveRange:aRange];
}

- (void)replaceCharactersInRange:(NSRange)aRange withString:(NSString *)aString synchronize:(BOOL)inSynchronizeFlag {
//	[self beginEditing];

//	NSString *foldingBefore = [I_foldableTextStorage foldedStringRepresentation];
//	NSLog(@"%s before: %@",__FUNCTION__,foldingBefore);
//	NSLog(@"%s %@ %@ %@",__FUNCTION__, NSStringFromRange(aRange), aString, inSynchronizeFlag ? @"YES" : @"NO");


		BOOL needsCompleteValidation = NO;
    if (I_flags.shouldWatchLineEndings && I_flags.hasMixedLineEndings && aRange.length && [self hasMixedLineEndingsInRange:aRange]) {
        needsCompleteValidation = YES;
    }

	id delegate = [I_foldableTextStorage delegate];
	if ([delegate respondsToSelector:@selector(textStorage:willReplaceCharactersInRange:withString:)]) {
		[delegate textStorage:self willReplaceCharactersInRange:aRange withString:aString];
	}
//	unsigned origLen = [self length];

    [I_internalAttributedString replaceCharactersInRange:aRange withString:aString];
//    [self edited:NSTextStorageEditedCharacters range:aRange 
//          changeInLength:[I_internalAttributedString length] - origLen];

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

    if (inSynchronizeFlag && !I_shouldNotSynchronize) [I_foldableTextStorage fullTextDidReplaceCharactersInRange:aRange withString:aString];

	if ([delegate respondsToSelector:@selector(textStorage:didReplaceCharactersInRange:withString:)]) {
		[delegate textStorage:self didReplaceCharactersInRange:aRange withString:aString];
	}
//	[self endEditing];
}

- (void)replaceCharactersInRange:(NSRange)aRange withString:(NSString *)aString {
	[self replaceCharactersInRange:aRange withString:aString synchronize:YES];
}


- (void)setAttributes:(NSDictionary *)attributes range:(NSRange)aRange synchronize:(BOOL)inSynchronizeFlag {

	if ([attributes objectForKey:NSToolTipAttributeName]) {
		// here to break
//		NSLog(@"%s had tooltipattribute",__FUNCTION__);
	}

    [I_internalAttributedString setAttributes:attributes range:aRange];
//    [self edited:NSTextStorageEditedAttributes range:aRange 
//          changeInLength:0];
    if (inSynchronizeFlag && !I_shouldNotSynchronize && !I_fixingCounter) {
    	[I_foldableTextStorage fullTextDidSetAttributes:attributes range:aRange];
    } else if (I_linearAttributeChangeState) {
    	if (I_unionRangeOfLinearAttributeChanges.length == NSNotFound) {
    		I_unionRangeOfLinearAttributeChanges = aRange;
    	} else {
    		I_unionRangeOfLinearAttributeChanges = NSUnionRange(aRange, I_unionRangeOfLinearAttributeChanges);
    	}
    	I_linearAttributeChangesCount++;
    }
}

- (void)setAttributes:(NSDictionary *)attributes range:(NSRange)aRange {
	[self setAttributes:attributes range:aRange synchronize:YES];
}

// convenience method
- (void)replaceCharactersInRange:(NSRange)inRange withAttributedString:(NSAttributedString *)inAttributedString synchronize:(BOOL)inSynchronizeFlag 
{
	if (!inSynchronizeFlag) I_shouldNotSynchronize++;
	[self replaceCharactersInRange:inRange withAttributedString:inAttributedString];
	if (!inSynchronizeFlag) I_shouldNotSynchronize--;
}

- (void)removeAttribute:(NSString *)anAttribute range:(NSRange)aRange synchronize:(BOOL)aSynchronizeFlag {
	if (!aSynchronizeFlag) I_shouldNotSynchronize++;
//	NSLog(@"%s %@ %@",__FUNCTION__,anAttribute, NSStringFromRange(aRange));
	[self removeAttribute:anAttribute range:aRange];
	if (!aSynchronizeFlag) I_shouldNotSynchronize--;
}

//- (void)replaceCharactersInRange:(NSRange)inRange withAttributedString:(NSAttributedString *)inAttributedString 
//{
//	[self replaceCharactersInRange:inRange withAttributedString:inAttributedString synchronize:YES];
//}

#pragma mark ### Line Ranges


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

#pragma mark encodings and line endings

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
//	NSLog(@"%s %@",__FUNCTION__,NSStringFromRange(aRange));
    static int limit = 0;
    if (limit==0) limit = [[NSUserDefaults standardUserDefaults] integerForKey:@"ByteLengthToUseForModeRecognitionAndEncodingGuessing"];
    if (aRange.length > limit && limit != -1) aRange.length = limit;

    OGRegularExpression *wrongExpression = [FullTextStorage wrongLineEndingRegex:[self lineEnding]];
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


#pragma mark -
#pragma mark ### Dictionary Representation ###

/*"Data:
    "String" => NSString content in UTF8
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
// performance optimization
- (void)beginEditing {
	[I_foldableTextStorage beginEditing];
	[super beginEditing];
}

- (void)endEditing {
	[I_foldableTextStorage endEditing];
	[super endEditing];
}

- (NSRange)foldableRangeForCharacterAtIndex:(unsigned long int)index
{
    // Looks up the range of a folding
    // Search backwards for a start with matching stack, then forwards for an end.
    
    
    NSMutableAttributedString *textStorage = self;
    NSRange wholeRange = NSMakeRange(0,[textStorage length]);
    if (index <= wholeRange.length) {
		if (index == wholeRange.length) {
	    	index = index - 1;
	    }
   	} else {
		return NSMakeRange(NSNotFound, 0);
	}
    //NSString *kindOfFolding = [string attribute:kSyntaxHighlightingFoldingDepthAttributeName atIndex:index effectiveRange:nil];
    NSRange returnRange = NSMakeRange(NSNotFound, 0);
    int depth = [[textStorage attribute:kSyntaxHighlightingFoldingDepthAttributeName atIndex:index effectiveRange:NULL] intValue];
    
    if (depth == 0) return NSMakeRange(NSNotFound, 0); // Not foldable

	// new approach: find folding start for this level as range. then find folding end for this level as range. then return the intersection.


	// check to the left until we find our corresponding start
    NSRange startRange = NSMakeRange(index+1,0); // so we start at index with the statesearch
    NSString *stateDelimiter = nil;
    int foundDepth = -1;
    BOOL continueThisLoop = YES;
    BOOL didDoTrimJump = NO;
    while (startRange.location > 0 && continueThisLoop) {
    	// this is folding start search only, not delimiter start search
    	stateDelimiter = [textStorage attribute:kSyntaxHighlightingFoldDelimiterName atIndex:startRange.location-1 longestEffectiveRange:&startRange inRange:wholeRange];
    	if ([stateDelimiter isEqualToString:kSyntaxHighlightingStateDelimiterStartValue]) {
    		// now check folding depths in that range as it could be that multiple folding starts are next to each other
    		NSRange depthSubrange = NSMakeRange(NSMaxRange(startRange),0);
    		while (depthSubrange.location > startRange.location) {
//    			NSLog(@"%s %@",__FUNCTION__,NSStringFromRange(depthSubrange));
				foundDepth = [[textStorage attribute:kSyntaxHighlightingFoldingDepthAttributeName atIndex:depthSubrange.location-1 longestEffectiveRange:&depthSubrange inRange:startRange] intValue];
//				NSLog(@"%s searching for:%d found:%d with start: %@",__FUNCTION__, depth, foundDepth, [[self string] substringWithRange:depthSubrange]);
				if (foundDepth == depth) {
					// we found our start so we might be happy and break
					if (!didDoTrimJump) {
						NSRange trimmedStartRange = NSMakeRange(NSNotFound,0);
						id wasTrimmed = [textStorage attribute:kSyntaxHighlightingIsTrimmedStartAttributeName atIndex:depthSubrange.location longestEffectiveRange:&trimmedStartRange inRange:wholeRange];
						if ((wasTrimmed) && NSMaxRange(trimmedStartRange) > NSMaxRange(startRange)) {
							// jump to end of trimming and continue search there
							startRange = NSMakeRange(NSMaxRange(trimmedStartRange),0);
							didDoTrimJump = YES;
							break; 
						}
					}
					startRange = depthSubrange;
					continueThisLoop = NO;
					break;
				}
			}
    	}
    }
    // worst case: we found no start so we are now somewhere at the start of the document and very long
    if (![stateDelimiter isEqualToString:kSyntaxHighlightingStateDelimiterStartValue] || foundDepth != depth) {
    	// nope - the folding level we were in does not have a start. bad news, because this should not be happening, but at least return an nsnotfound folding range
    	return NSMakeRange(NSNotFound,0);
    }
    
    // now that we are happy and have our start, we search our end
    NSRange endRange = NSMakeRange(NSMaxRange(startRange),0);
    continueThisLoop = YES;
    while (NSMaxRange(wholeRange) > NSMaxRange(endRange) && continueThisLoop) {
    	// this is folding end search only, not delimiter end search
    	stateDelimiter = [textStorage attribute:kSyntaxHighlightingFoldDelimiterName atIndex:NSMaxRange(endRange) longestEffectiveRange:&endRange inRange:wholeRange];
    	if ([stateDelimiter isEqualToString:kSyntaxHighlightingStateDelimiterEndValue]) {
    		// now check folding depths in that range as it could be that multiple folding starts are next to each other
    		NSRange depthSubrange = NSMakeRange(NSMaxRange(endRange),0);
    		while (depthSubrange.location > endRange.location) {
//    			NSLog(@"%s %@",__FUNCTION__,NSStringFromRange(depthSubrange));
				foundDepth = [[textStorage attribute:kSyntaxHighlightingFoldingDepthAttributeName atIndex:depthSubrange.location-1 longestEffectiveRange:&depthSubrange inRange:endRange] intValue];
//				NSLog(@"%s searching for:%d found:%d with start: %@",__FUNCTION__, depth, foundDepth, [[self string] substringWithRange:depthSubrange]);
				if (foundDepth == depth) {
					// we found our start so we are happy and break
					endRange = depthSubrange;
					continueThisLoop = NO;
					break;
				}
			}
    	}
    }
    // worst case: we found no end so we are a potentially long range streching out till the end
    if (![stateDelimiter isEqualToString:kSyntaxHighlightingStateDelimiterEndValue]) {
		// we haven't found a suitable end - ergo we fold until document end
		endRange = NSMakeRange(wholeRange.length,0);
    }

	// now we return the differenceRange
	returnRange = NSMakeRange(NSMaxRange(startRange), endRange.location - NSMaxRange(startRange));
    
    
    return returnRange;
}

- (NSRange)continuousCommentRangeAtIndex:(unsigned long int)anIndex {
    NSMutableAttributedString *textStorage = self;

    NSRange returnRange = NSMakeRange(NSNotFound, 0);
    NSRange wholeRange = NSMakeRange(0, [textStorage length]);
    if (anIndex == wholeRange.length) {
    	if (anIndex == 0) return returnRange;
    	else anIndex--;
    }
    NSString *type = [textStorage attribute:kSyntaxHighlightingTypeAttributeName atIndex:anIndex longestEffectiveRange:&returnRange inRange:wholeRange];
    
    if (![type isEqualToString:kSyntaxHighlightingTypeComment]) {
    	return NSMakeRange(NSNotFound, 0); // Not foldable
    } else {
    
    	NSCharacterSet *invertedWhiteSpaceAndNewlineCharacterSet = [[NSCharacterSet whitespaceAndNewlineCharacterSet] invertedSet];
		NSString *textStorageString = [textStorage string];
		
		int isForwardSearch = 0;
		for (isForwardSearch = 0; isForwardSearch < 2; isForwardSearch++) {
			// do this exactly twice, once backward, once forward, and use the same code for recognition
			
			// check all ranges in front of the current range
			NSRange attributeRange = returnRange;
			while (attributeRange.location > 0 && NSMaxRange(attributeRange) < wholeRange.length) {
			
				type = [textStorage attribute:kSyntaxHighlightingTypeAttributeName 
									atIndex:isForwardSearch ? (NSMaxRange(attributeRange)) : (attributeRange.location - 1)
									longestEffectiveRange:&attributeRange 
									inRange:wholeRange];
				if ([type isEqualToString:kSyntaxHighlightingTypeComment]) {
					// add the range to the returnRange
					returnRange = NSUnionRange(attributeRange,returnRange);
				} else {
					// check the range for lineRanges since single line comments include the ending
					NSRange lineRange = [textStorageString lineRangeForRange:NSMakeRange(attributeRange.location,0)];
					if (NSMaxRange(lineRange) <= NSMaxRange(attributeRange)) {
						break;
					}
				
					// check the range for non-whitespace characters
					NSRange nonWhitespaceRange = [textStorageString rangeOfCharacterFromSet:invertedWhiteSpaceAndNewlineCharacterSet options:0 range:attributeRange];
					if (nonWhitespaceRange.location != NSNotFound) {
						break; // glue between the comments was no whitespace
					}
				}
			}
		}
		
		// Trim start and end
		if (returnRange.location!=NSNotFound) {
			NSRange stateStackRange;
			NSRange startRange, endRange;
			// get the max state stack range for the end
			[textStorage attribute:kSyntaxHighlightingStackName          atIndex:returnRange.location longestEffectiveRange:&stateStackRange inRange:returnRange];
			[textStorage attribute:kSyntaxHighlightingStateDelimiterName atIndex:returnRange.location longestEffectiveRange:&startRange      inRange:stateStackRange];
		
			// get the max state stack range for the end
			[textStorage attribute:kSyntaxHighlightingStackName          atIndex:NSMaxRange(returnRange)-1 longestEffectiveRange:&stateStackRange inRange:returnRange];
			[textStorage attribute:kSyntaxHighlightingStateDelimiterName atIndex:NSMaxRange(returnRange)-1 longestEffectiveRange:&endRange        inRange:stateStackRange];
			
			// safety check if end and startrange overlap or touch bail
			if (NSMaxRange(startRange) >= endRange.location) return NSMakeRange(NSNotFound,0);
			
			returnRange = NSMakeRange(NSMaxRange(startRange), endRange.location - NSMaxRange(startRange));
		}
		
		return returnRange;
    }
}


- (void)beginLinearAttributeChanges {
	I_shouldNotSynchronize++;
	if (I_linearAttributeChangeState == 0) {
		I_unionRangeOfLinearAttributeChanges = NSMakeRange(0,NSNotFound);
		I_linearAttributeChangesCount = 0;
	}
	I_linearAttributeChangeState++;
//	NSLog(@"%s",__FUNCTION__);
}

- (void)endLinearAttributeChanges {
//	NSLog(@"%s",__FUNCTION__);
	I_linearAttributeChangeState--;
	I_shouldNotSynchronize--;
	int aggregatedChangesCount = 0;
	if (I_linearAttributeChangeState == 0 && I_unionRangeOfLinearAttributeChanges.length != NSNotFound) {
		// propagate the whole area up to the foldableTextstorage
		NSRange attributeRange = NSMakeRange(I_unionRangeOfLinearAttributeChanges.location,0);
		do {
			NSDictionary *attributes = [I_internalAttributedString attributesAtIndex:NSMaxRange(attributeRange) longestEffectiveRange:&attributeRange inRange:I_unionRangeOfLinearAttributeChanges];
			[I_foldableTextStorage fullTextDidSetAttributes:attributes range:attributeRange];
			aggregatedChangesCount++;
		} while (NSMaxRange(attributeRange) < NSMaxRange(I_unionRangeOfLinearAttributeChanges));
//		NSLog(@"%s aggregated %d changes into %d changes (%2.1f%% reduction) in resulting range: %@",__FUNCTION__,I_linearAttributeChangesCount,aggregatedChangesCount,100.0 - ((((double)aggregatedChangesCount) / I_linearAttributeChangesCount)*100.0),NSStringFromRange(I_unionRangeOfLinearAttributeChanges));
	}
}

- (NSArray *)selectionOperationsForRangesUnconvertableToEncoding:(NSStringEncoding)encoding {
//    NSLog(@"%s beginning",__FUNCTION__);
    NSMutableArray *array = [NSMutableArray array];
    NSString *string = [self string];
    unsigned length = [string length];
    unsigned i;
    
    id myUserID = nil;
    
#ifdef SUBETHAEDIT
    myUserID = [TCMMMUserManager myUserID];
#endif
    
    for (i = 0; i < length; i++) {
        unichar character = [string characterAtIndex:i];
        NSString *charString = [[NSString alloc] initWithCharactersNoCopy:&character length:1 freeWhenDone:NO];
        if (![charString canBeConvertedToEncoding:encoding]) {
            [array addObject:[SelectionOperation selectionOperationWithRange:NSMakeRange(i, 1) userID:myUserID]];
        }
        [charString release];
    }
    
    // combine adjacent selection operations
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

- (id)objectSpecifier {
	return [I_foldableTextStorage objectSpecifier];
}


@end
