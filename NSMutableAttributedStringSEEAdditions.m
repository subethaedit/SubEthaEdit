//
//  NSMutableAttributedStringSEEAdditions.m
//  SubEthaEdit
//
//  Created by Martin Ott on 3/19/07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import "NSMutableAttributedStringSEEAdditions.h"
#ifndef TCM_ISSEED
    #import <OgreKit/OgreKit.h>
#endif

extern NSString const * WrittenByUserIDAttributeName, *ChangedByUserIDAttributeName;

@implementation NSMutableAttributedString (NSMutableAttributedStringSEEAdditions) 

#ifndef TCM_ISSEED
- (NSRange)detab:(BOOL)shouldDetab inRange:(NSRange)aRange tabWidth:(int)aTabWidth askingTextView:(NSTextView *)aTextView {
    [self beginEditing];

    static OGRegularExpression *tabExpression,*spaceExpression;
    if (!tabExpression) {
        tabExpression  =[[OGRegularExpression regularExpressionWithString:@"\t+"] retain];
        spaceExpression=[[OGRegularExpression regularExpressionWithString:@"  +"] retain];
    }

    unsigned changeInLength=0;
    
    if (shouldDetab) {
        NSArray *matches=[tabExpression allMatchesInString:[self string] range:aRange];
        int i=0;
        int count=[matches count];
        for (i=0;i<count;i++) {
            OGRegularExpressionMatch *match=[matches objectAtIndex:i];
            NSRange matchRange=[match rangeOfMatchedString];
            matchRange.location+=changeInLength;
            NSRange lineRange=[[self string] lineRangeForRange:matchRange];
            int replacementStringLength=(matchRange.length-1)*aTabWidth+
                                        (aTabWidth-(matchRange.location-lineRange.location)%aTabWidth);
            NSString *replacementString=[@"" stringByPaddingToLength:replacementStringLength withString:@" " startingAtIndex:0];
            if ((aTextView && [aTextView shouldChangeTextInRange:matchRange replacementString:replacementString]) 
                || !aTextView) {
                [self replaceCharactersInRange:matchRange withString:replacementString];
                if (aTextView) {
                    [self addAttributes:[aTextView typingAttributes] 
                          range:NSMakeRange(matchRange.location,replacementStringLength)];
                }
                changeInLength+=replacementStringLength-matchRange.length;
            }
        }
    } else {
        NSArray *matches=[spaceExpression allMatchesInString:[self string] range:aRange];
        int i=0;
        int count=[matches count];
        for (i=count-1;i>=0;i--) {
            OGRegularExpressionMatch *match=[matches objectAtIndex:i];
            NSRange matchRange=[match rangeOfMatchedString];
            NSRange lineRange=[[self string] lineRangeForRange:matchRange];
            if (matchRange.length>=(aTabWidth-(matchRange.location-lineRange.location)%aTabWidth)) {
                // align end of spaces to tab boundary
                matchRange.length-=(NSMaxRange(matchRange)-lineRange.location)%aTabWidth;
                int replacementStringLength=matchRange.length/aTabWidth;
                if ((matchRange.location-lineRange.location)%aTabWidth!=0) replacementStringLength+=1;
                NSString *replacementString=[@"" stringByPaddingToLength:replacementStringLength withString:@"\t" startingAtIndex:0];
                if ((aTextView && [aTextView shouldChangeTextInRange:matchRange replacementString:replacementString])
                    || !aTextView) {
                    [self replaceCharactersInRange:matchRange withString:replacementString];
                    if (aTextView) {
                        [self addAttributes:[aTextView typingAttributes] 
                              range:NSMakeRange(matchRange.location,replacementStringLength)];
                    }
                    changeInLength+=replacementStringLength-matchRange.length;
                }
            }
        }
    }

    aRange.length+=changeInLength;
    [self endEditing];

    [aTextView didChangeText];
    return aRange;
}
#endif

#ifndef TCM_ISSEED
- (void)makeLeadingWhitespaceNonBreaking {
    [self beginEditing];
    NSString *hardspaceString=nil;
    if (hardspaceString==nil) {
        unichar hardspace=0x00A0;
        hardspaceString=[[NSString stringWithCharacters:&hardspace length:1] retain];
    }
    unsigned index=[self length];
    unsigned startIndex,lineEndIndex,contentsEndIndex;
    while (index!=0) {
        [[self string] getLineStart:&startIndex end:&lineEndIndex contentsEnd:&contentsEndIndex forRange:NSMakeRange(index-1,0)];
        unsigned firstNonWhitespace=startIndex;
        NSString *string=[self string];
        while (firstNonWhitespace<contentsEndIndex &&
               [string characterAtIndex:firstNonWhitespace]==' ') {
            firstNonWhitespace++;
        }
        if (firstNonWhitespace>startIndex) {
            NSRange replaceRange=NSMakeRange(startIndex,firstNonWhitespace-startIndex);
            [self replaceCharactersInRange:replaceRange
                  withString:[@"" stringByPaddingToLength:replaceRange.length withString:hardspaceString startingAtIndex:0]];
        }
        index=startIndex;
    }
    
    OGRegularExpression *moreThanOneSpace=[[[OGRegularExpression alloc] initWithString:@"  +" options:OgreFindNotEmptyOption] autorelease];
    NSEnumerator *matches=[[moreThanOneSpace allMatchesInString:[self string] range:NSMakeRange(0,[self length])] reverseObjectEnumerator];
    OGRegularExpressionMatch *match=nil;
    while ((match=[matches nextObject])) {
        NSRange matchRange=[match rangeOfMatchedString];
        [self replaceCharactersInRange:matchRange
              withString:[@" " stringByPaddingToLength:matchRange.length withString:hardspaceString startingAtIndex:0]];
    }
    [self endEditing];
}
#endif

- (void)removeAttributes:(NSArray *)names range:(NSRange)aRange {
    [self beginEditing];
	int count = [names count];
	int i;
	for (i=0;i<count;i++)
		[self removeAttribute:[names objectAtIndex:i] range:aRange];
    [self endEditing];
}

- (void)setContentByDictionaryRepresentation:(NSDictionary *)aRepresentation {
    [self beginEditing];
    NSString *string=[aRepresentation objectForKey:@"String"];
    if (string && [string isKindOfClass:[NSString class]]) {
        [self replaceCharactersInRange:NSMakeRange(0,[self length]) withString:@""];
        [self replaceCharactersInRange:NSMakeRange(0,[self length]) withString:string];
        NSRange wholeRange=NSMakeRange(0,[self length]);
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

@implementation NSAttributedString (NSAttributedStringSeeAdditions)

- (NSDictionary *)dictionaryRepresentationUsingEncoding:(NSStringEncoding)anEncoding {
    NSMutableDictionary *dictionary=[NSMutableDictionary dictionary];
    [dictionary setObject:[[[self string] copy] autorelease] forKey:@"String"];
    [dictionary setObject:[NSNumber numberWithUnsignedInt:anEncoding] forKey:@"Encoding"];
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



@end
