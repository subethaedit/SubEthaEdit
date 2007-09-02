//
//  NSMutableAttributedStringSEEAdditions.m
//  SubEthaEdit
//
//  Created by Martin Ott on 3/19/07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import "NSMutableAttributedStringSEEAdditions.h"
#import <OgreKit/OgreKit.h>


@implementation NSMutableAttributedString (NSMutableAttributedStringSEEAdditions) 

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


- (void)makeLeadingWhitespaceNonBreaking {
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
    
    OGRegularExpression *moreThanOneSpace=[[[OGRegularExpression alloc] initWithString:@"  +" options:OgreFindLongestOption|OgreFindNotEmptyOption] autorelease];
    NSEnumerator *matches=[[moreThanOneSpace allMatchesInString:[self string] range:NSMakeRange(0,[self length])] reverseObjectEnumerator];
    OGRegularExpressionMatch *match=nil;
    while ((match=[matches nextObject])) {
        NSRange matchRange=[match rangeOfMatchedString];
        [self replaceCharactersInRange:matchRange
              withString:[@" " stringByPaddingToLength:matchRange.length withString:hardspaceString startingAtIndex:0]];
    }
}

- (void)removeAttributes:(NSArray *)names range:(NSRange)aRange {
	int count = [names count];
	int i;
	for (i=0;i<count;i++)
		[self removeAttribute:[names objectAtIndex:i] range:aRange];
}


@end
