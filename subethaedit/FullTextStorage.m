//
//  FullTextStorage.m
//  TextEdit
//
//  Created by Dominik Wagner on 04.01.09.
//  Copyright 2009 TheCodingMonkeys. All rights reserved.
//


#import "FoldableTextStorage.h"
#import "FullTextStorage.h"
#import "TextStorage.h"
#import "EncodingManager.h"
#import "SyntaxHighlighter.h"


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
	unsigned origLen = [self length];

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
		[delegate textStorage:(NSTextStorage *)self didReplaceCharactersInRange:aRange withString:aString];
	}
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
    
    NSMutableAttributedString *string = self;
    NSString *kindOfFolding = [string attribute:kSyntaxHighlightingFoldableAttributeName atIndex:index effectiveRange:nil];
    
    if ([kindOfFolding isEqualToString:@"state"]) { // Foldable state from definition
        unsigned long int startIndex = 0, endIndex = 0;
        
        NSRange indexStackRange, startRange, endRange, originalRange;
        NSArray *stack = [string attribute:kSyntaxHighlightingStackName atIndex:index longestEffectiveRange:&indexStackRange inRange:NSMakeRange(0, [string length])];
        originalRange = indexStackRange;
        
        NSArray *neighborStack = stack;
        // Look for start
        while ([neighborStack count]>=[stack count]) {
            if (indexStackRange.location<=0) return NSMakeRange(NSNotFound, 0); // Not foldable
            if ([neighborStack count]==[stack count]) startIndex = indexStackRange.location;
            neighborStack = [string attribute:kSyntaxHighlightingStackName atIndex:indexStackRange.location-1 longestEffectiveRange:&indexStackRange inRange:NSMakeRange(0, indexStackRange.location)];
        }
        
        if ([[string attribute:kSyntaxHighlightingStateDelimiterName atIndex:startIndex effectiveRange:&startRange] isEqualTo:@"Start"]) {
            // Found a start
            startIndex = NSMaxRange(startRange);            
            // Look for an end
            neighborStack = stack;
            indexStackRange = originalRange;
            while ([neighborStack count]>=[stack count]) {
                if (NSMaxRange(indexStackRange)<=0) break;
                if ([neighborStack count]==[stack count]) endIndex = NSMaxRange(indexStackRange);
                
                if (NSMaxRange(indexStackRange)>=[string length]) break;
                neighborStack = [string attribute:kSyntaxHighlightingStackName atIndex:indexStackRange.location+1 longestEffectiveRange:&indexStackRange inRange:NSMakeRange(NSMaxRange(indexStackRange), [string length]-NSMaxRange(indexStackRange))];
            }
                        
            if ((endIndex>0)&&[[string attribute:kSyntaxHighlightingStateDelimiterName atIndex:endIndex-1 effectiveRange:&endRange] isEqualTo:@"End"]) {
                endIndex = endRange.location;
                return NSMakeRange(startIndex, endIndex-startIndex);
            }
            
            
        }
    }
    
    return NSMakeRange(NSNotFound, 0); // Not foldable
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

@end
