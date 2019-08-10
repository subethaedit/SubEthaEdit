//  NSMutableAttributedStringSEEAdditions.m
//  SubEthaEdit
//
//  Created by Martin Ott on 3/19/07.

#import "NSStringSEEAdditions.h"
#import "NSMutableAttributedStringSEEAdditions.h"
#import <OgreKit/OgreKit.h>
#import "GeneralPreferences.h"
#import "SyntaxHighlighter.h"
#import "TCMMMUserManager.h"
#import "TCMMMUser.h"
#import "TCMMMUserSEEAdditions.h"

// this file needs arc - add -fobjc-arc in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

extern NSString * const WrittenByUserIDAttributeName, *ChangedByUserIDAttributeName, *SEESearchScopeAttributeName;


@implementation NSMutableAttributedString (NSMutableAttributedStringSEEAdditions) 

- (NSRange)detab:(BOOL)shouldDetab inRange:(NSRange)aRange tabWidth:(int)aTabWidth askingTextView:(NSTextView *)aTextView {
    [self beginEditing];

    static OGRegularExpression *tabExpression,*spaceExpression;
    if (!tabExpression) {
        tabExpression  = [OGRegularExpression regularExpressionWithString:@"\t+"];
        spaceExpression= [OGRegularExpression regularExpressionWithString:@"  +"];
    }

    unsigned changeInLength=0;
    
    if (shouldDetab) {
        NSArray *matches=[tabExpression allMatchesInString:[self string] range:aRange];
        for (OGRegularExpressionMatch *match in matches) {
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
    [self beginEditing];
    static NSString *hardspaceString=nil;
    if (hardspaceString==nil) {
        unichar hardspace=0x00A0;
        hardspaceString=[NSString stringWithCharacters:&hardspace length:1];
    }
    NSUInteger index=[self length];
    NSUInteger startIndex,lineEndIndex,contentsEndIndex;
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
    
    OGRegularExpression *moreThanOneSpace=[[OGRegularExpression alloc] initWithString:@"  +" options:OgreFindNotEmptyOption];
    NSEnumerator *matches=[[moreThanOneSpace allMatchesInString:[self string] range:NSMakeRange(0,[self length])] reverseObjectEnumerator];
    OGRegularExpressionMatch *match=nil;
    while ((match=[matches nextObject])) {
        NSRange matchRange=[match rangeOfMatchedString];
        [self replaceCharactersInRange:matchRange
              withString:[@" " stringByPaddingToLength:matchRange.length withString:hardspaceString startingAtIndex:0]];
    }
    [self endEditing];
}

- (void)removeAttributes:(id)anObjectEnumerable range:(NSRange)aRange {
	[self beginEditing];
    id attributeName=nil;
	for (attributeName in anObjectEnumerable) {
        [self removeAttribute:attributeName range:aRange];
	}
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


- (int)blockChangeTextInRange:(NSRange)aRange replacementString:(NSString *)aReplacementString
           lineRange:(NSRange)aLineRange inTextView:(NSTextView *)aTextView tabWidth:(unsigned)aTabWidth useTabs:(BOOL)aUseTabs{
    NSInteger lengthChange=0;
    NSInteger tabWidth=aTabWidth;
    NSMutableAttributedString *textStorage=self;
    NSRange aReplacementRange=aRange;
    NSString *string=[textStorage string];
    aReplacementRange.location+=aLineRange.location;
    // don't touch newlines
    {
        NSUInteger lineEnd,contentsEnd;
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
    NSMutableAttributedString *textStorage=self;
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

- (void)replaceAttachmentsWithAttributedString:(NSAttributedString *)aString {
	NSRange searchRange = NSMakeRange(0,[self length]);
	while (NSMaxRange(searchRange)>1) {
		NSRange effectiveRange;
		id attachment = [self attribute:NSAttachmentAttributeName atIndex:NSMaxRange(searchRange)-1 longestEffectiveRange:&effectiveRange inRange:searchRange];
		if (attachment) {
			[self replaceCharactersInRange:effectiveRange withAttributedString:aString];	
		}
		searchRange.length = effectiveRange.location;
	}
}


@end

@implementation NSAttributedString (NSAttributedStringSeeAdditions)

- (NSMutableDictionary *)mutableDictionaryRepresentation {
    NSMutableDictionary *dictionary=[NSMutableDictionary dictionary];
    [dictionary setObject:[[self string] copy] forKey:@"String"];
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
        }
    }
	if ([attributeDictionary count]) {
	    [dictionary setObject:attributeDictionary forKey:@"Attributes"];
	}
    return dictionary;
}

- (NSDictionary *)dictionaryRepresentationUsingEncoding:(NSStringEncoding)anEncoding {
	NSMutableDictionary *mutableRepresentation = (NSMutableDictionary *)[self mutableDictionaryRepresentation];
	[mutableRepresentation setObject:[NSNumber numberWithUnsignedInt:anEncoding] forKey:@"Encoding"];
    return mutableRepresentation;
}

- (NSDictionary *)dictionaryRepresentation {
	return [self mutableDictionaryRepresentation];
}

- (NSDictionary *)attributeDictionaryByAddingStyleAttributesForInsertLocation:(unsigned int)inLocation toDictionary:(NSDictionary *)inBaseStyle
{
	static NSArray *attributeNamesToCopy = nil;
	if (!attributeNamesToCopy) {
		attributeNamesToCopy = [@[NSForegroundColorAttributeName,kSyntaxHighlightingFoldingDepthAttributeName,SEESearchScopeAttributeName] copy];
	}
	unsigned int length = [self length];
	if (inLocation > length || inLocation < 1) return inBaseStyle; // do nothing if document is empty, or the proposed insertion point is beyond the current size
	
	// if this is not the case, copy the appropriate styles
	inLocation = inLocation - 1; // select the style from the character in front of the insertion, range validity was checked above
	NSDictionary *attributes = [self attributesAtIndex:inLocation effectiveRange:NULL];
	NSMutableDictionary *resultDictionary = [inBaseStyle mutableCopy];
	
	// currently visual style means font and color so copy these
	NSFont *font = [attributes objectForKey:NSFontAttributeName];
	if (font && [[[resultDictionary objectForKey:NSFontAttributeName] familyName] isEqualToString:[font familyName]]) {
		[resultDictionary setObject:font forKey:NSFontAttributeName];
	}
	
	for (NSString *attributeName in attributeNamesToCopy) {
		id value = attributes[attributeName];
		if (value) {
			resultDictionary[attributeName] = value;
		}
	}
		
	return resultDictionary;
}


- (BOOL)lastLineIsEmpty {
    NSUInteger lineStartIndex, lineEndIndex;
    [[self string] getLineStart:&lineStartIndex end:&lineEndIndex contentsEnd:NULL forRange:NSMakeRange([self length],0)];
    return lineStartIndex == lineEndIndex;
}

#pragma mark -
#pragma mark ### XHTML Export ###


- (NSMutableAttributedString *)attributedStringForXHTMLExportWithRange:(NSRange)aRange foregroundColor:(NSColor *)aForegroundColor backgroundColor:(NSColor *)aBackgroundColor {
    NSString *htmlForgreoundColor=[aForegroundColor HTMLString];
    NSMutableAttributedString *result=[[NSMutableAttributedString alloc] initWithString:[[self string] substringWithRange:aRange]];
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
