//
//  NSStringSEEAdditions.m
//  
//
//  Created by Martin Ott on Tue Feb 17 2004.
//  Copyright (c) 2004-2007 TheCodingMonkeys. All rights reserved.
//

#import "NSStringSEEAdditions.h"
#import <OgreKit/OgreKit.h>

// this file needs arc - either project wide,
// or add -fobjc-arc on a per file basis in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

@interface TCMBracketSettings ()
@property (nonatomic, readwrite) unichar *openingBrackets;
@property (nonatomic, readwrite) unichar *closingBrackets;
@property (nonatomic, readwrite) NSInteger bracketCount;
@end

@implementation TCMBracketSettings
- (instancetype)initWithBracketString:(NSString *)aBracketString {
	self = [super init];
	if (self) {
		[self setBracketString:aBracketString];
	}
	return self;
}

- (void)setBracketString:(NSString *)aBracketString {
	if (_openingBrackets != NULL) free(_openingBrackets);
	if (_closingBrackets != NULL) free(_closingBrackets);
	_bracketCount = [aBracketString length] / 2;
	_closingBrackets = malloc(sizeof(unichar)*_bracketCount);
	_openingBrackets = malloc(sizeof(unichar)*_bracketCount);
	for (int i=0;i<_bracketCount;i++) {
		_openingBrackets[i]=[aBracketString characterAtIndex:i];
		_closingBrackets[i]=[aBracketString characterAtIndex:(_bracketCount*2-1)-i];
	}
}

- (BOOL)charIsClosingBracket:(unichar)aPossibleBracket {
    for (int i=0;i<_bracketCount;i++) {
        if (aPossibleBracket==_closingBrackets[i]) {
            return YES;
		}
    }
    return NO;
}

- (BOOL)charIsOpeningBracket:(unichar)aPossibleBracket {
    for (int i=0;i<_bracketCount;i++) {
        if (aPossibleBracket==_openingBrackets[i]) {
            return YES;
		}
    }
    return NO;
}

- (BOOL)charIsBracket:(unichar)aPossibleBracket {
	BOOL result = ([self matchingBracketForChar:aPossibleBracket] != (unichar)0);
    return result;
}

- (unichar)matchingBracketForChar:(unichar)aBracketCharacter; {
	for (int i=0;i<_bracketCount;i++) {
        if (aBracketCharacter==_openingBrackets[i]) {
			return _closingBrackets[i];
		} else if (aBracketCharacter==_closingBrackets[i]) {
            return _openingBrackets[i];
		}
    }
    return (unichar)0;
}

- (BOOL)shouldIgnoreBracketAtIndex:(NSUInteger)anIndex attributedString:(NSAttributedString *)anAttributedString {
	BOOL result = NO;
	if (self.attributeNameToDisregard) {
		id value = [anAttributedString attribute:self.attributeNameToDisregard atIndex:anIndex effectiveRange:NULL];
		for (id checkValue in self.attributeValuesToDisregard) {
			if ([value isEqual:checkValue]) {
				result = YES;
				break;
			}
		}
	}
	return result;
}

- (BOOL)shouldIgnoreBracketAtRangeBoundaries:(NSRange)aRange attributedString:(NSAttributedString *)anAttributedString {
	BOOL beforeValue = YES;
	BOOL afterValue = YES;
	if (aRange.location > 0) {
		beforeValue = [self shouldIgnoreBracketAtIndex:aRange.location-1 attributedString:anAttributedString];
	}
	if (NSMaxRange(aRange) < anAttributedString.length) {
		afterValue = [self shouldIgnoreBracketAtIndex:NSMaxRange(aRange) attributedString:anAttributedString];
	}
	BOOL result = beforeValue && afterValue;
	return result;
}


- (void)dealloc {
	free(_openingBrackets);
	free(_closingBrackets);
}

@end

static void convertLineEndingsInString(NSMutableString *string, NSString *newLineEnding)
{
    unsigned newEOLLen;
    unichar newEOLStackBuf[2];
    unichar *newEOLBuf;
    BOOL freeNewEOLBuf = NO;

    unsigned length = [string length];
    unsigned curPos = 0;
    NSUInteger start, end, contentsEnd;


    newEOLLen = [newLineEnding length];
    if (newEOLLen > 2) {
        newEOLBuf = NSZoneMalloc(NULL, sizeof(unichar) * newEOLLen);
        freeNewEOLBuf = YES;
    } else {
        newEOLBuf = newEOLStackBuf;
    }
    [newLineEnding getCharacters:newEOLBuf];

    NSMutableArray *changes=[[NSMutableArray alloc] init];

    while (curPos < length) {
        [string getLineStart:&start end:&end contentsEnd:&contentsEnd forRange:NSMakeRange(curPos, 0)];
        if (contentsEnd < end) {
            int oldLength = (end - contentsEnd);
            int changeInLength = newEOLLen - oldLength;
            BOOL alreadyNewEOL = YES;
            if (changeInLength == 0) {
                unsigned i;
                for (i = 0; i < newEOLLen; i++) {
                    if ([string characterAtIndex:contentsEnd + i] != newEOLBuf[i]) {
                        alreadyNewEOL = NO;
                        break;
                    }
                }
            } else {
                alreadyNewEOL = NO;
            }
            if (!alreadyNewEOL) {
                [changes addObject:[NSValue valueWithRange:NSMakeRange(contentsEnd, oldLength)]];
            }
        }
        curPos = end;
    }

    int count=[changes count];
    while (--count >= 0) {
        [string replaceCharactersInRange:[[changes objectAtIndex:count] rangeValue] withString:newLineEnding];
        // TODO: put this change also into the undomanager
    }

    if (freeNewEOLBuf) {
        NSZoneFree(NSZoneFromPointer(newEOLBuf), newEOLBuf);
    }
}

@implementation NSMutableString (NSStringSEEAdditions)

- (void)convertLineEndingsToLineEndingString:(NSString *)aNewLineEndingString {
    convertLineEndingsInString(self,aNewLineEndingString);
}

- (NSMutableString *)addBRs {
    NSUInteger index=[self length];
    NSUInteger startIndex,lineEndIndex,contentsEndIndex;
    while (index!=0) {
        [self getLineStart:&startIndex end:&lineEndIndex contentsEnd:&contentsEndIndex forRange:NSMakeRange(index-1,0)];
        if (contentsEndIndex!=lineEndIndex) {
            [self replaceCharactersInRange:NSMakeRange(contentsEndIndex,0)
                  withString:@"<br />"];
        }
        index=startIndex;
    }
    return self;
}


@end


@implementation NSString (NSStringSEEAdditions) 

+ (NSString *)lineEndingStringForLineEnding:(LineEnding)aLineEnding {
    static NSString *sUnicodeLSEP=nil;
    static NSString *sUnicodePSEP=nil;
    if (sUnicodeLSEP==nil) {
        unichar seps[2];
        seps[0]=0x2028;
        seps[1]=0x2029;
        sUnicodeLSEP=[NSString stringWithCharacters:seps length:1];
        sUnicodePSEP=[NSString stringWithCharacters:seps+1 length:1];
    }
    switch(aLineEnding) {
    case LineEndingLF:
        return @"\n";
    case LineEndingCR:
        return @"\r";
    case LineEndingCRLF:
        return @"\r\n";
    case LineEndingUnicodeLineSeparator:
        return sUnicodeLSEP;
    case LineEndingUnicodeParagraphSeparator:
        return sUnicodePSEP;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunreachable-code"
    default:
        return @"\n";
#pragma clang diagnostic pop
    }
}

- (BOOL)isValidSerial
{
    // Pirated number (2.1.1): 2QF-PABI-OCM6-KRHH (Blocked by enforcing SEE prefix) (SB)
    // Pirated number (2.2): SEE-11G0-M1A0-5ROC (Blocked #1500/63000) (SB)
    // Pirated number (2.3): SEE-1960-4979-8692 (Blocked #431865/49392) (SB)
    // Published number (2.3): SEE-2XG6-8CK0-H8KX ( #43400/136374)
    // Published number (2.3): SEE-ZXFC-PF60-FZSX ( #43336/1676640)
    // Pirated number (2.5): SEE-SE2O-Y1LV-EZ1J ( #1464985/1332240) (KCN)
    // Pirated number (2.5.1): SEE-IC3I-O11Y-W0FO (#1603023/871794)
    // Pirated number (2.6): SEE-6Y2C-M157-UXZ2 (#371771/283332)
    // Pirated number (2.6.2): SEE-Z320-71AH-5P0S (#797220/1669500)
    
    // Pirated number (2.6.3): SEE-BW26-J17T-QQ3Y (#1395435/557970)
    // Pirated number (2.6.3): SEE-Z410-71AH-5P0S (#798516/1669500)
	// Pirated number (2.6.4): SEE-V006-81P0-35F4 (#123/1451814)	
	// Pirated number (3.0.2): SEE-XAAU-IKZJ-55TA (#899633/1553286)	
	// Pirated number (3.0.3): SEE-V006-81P0-17F4 (#51/1451814)	
    
    static int calls = 0;
    NSArray *splitArray = [self componentsSeparatedByString:@"-"];
    if ([splitArray count]==4 && calls++ < 100) {
        NSString *zero = [splitArray objectAtIndex:0];
        NSString *one  = [splitArray objectAtIndex:1];
        NSString *two  = [splitArray objectAtIndex:2];
        NSString *tri  = [splitArray objectAtIndex:3];
        if (([[zero uppercaseString] isEqualToString:@"SEE"]) && ([one length] == 4) && ([two length] == 4) && ([tri length] == 4)) {
            long prefix = [zero base36Value];
            // Buchstaben zwirbeln
            long number = [[NSString stringWithFormat:@"%c%c%c%c",
                      [two characterAtIndex:3],
                      [one characterAtIndex:1],
                      [tri characterAtIndex:0],
                      [tri characterAtIndex:2]] base36Value];
            long rndnumber = [[NSString stringWithFormat:@"%c%c%c%c",
                      [one characterAtIndex:0],
                      [tri characterAtIndex:3],
                      [two characterAtIndex:0],
                      [one characterAtIndex:3]] base36Value];
            long chksum = [[NSString stringWithFormat:@"%c%c%c%c",
                      [two characterAtIndex:1],
                      [one characterAtIndex:2],
                      [tri characterAtIndex:1],
                      [two characterAtIndex:2]] base36Value];

            // check for pirated number            
            if (((number==1500) && (rndnumber == 63000)) ||
                ((number==51) && (rndnumber == 1451814)) ||
                ((number==899633) && (rndnumber == 1553286)) ||
                ((number==123) && (rndnumber == 1451814)) ||
                ((number==43400) && (rndnumber == 136374)) ||
                ((number==1395435) && (rndnumber == 557970)) ||
                ((number==798516) && (rndnumber == 1669500)) ||
                ((number==797220) && (rndnumber == 1669500)) ||
                ((number==43336) && (rndnumber == 1676640)) ||
                ((number==1464985) && (rndnumber == 1332240)) ||
                ((number==1603023) && (rndnumber == 871794)) ||
                ((number==371771) && (rndnumber == 283332)) ||
                ((number==431865) && (rndnumber == 49392))) {
                NSLog(@"Arrrr!");
                return NO;
            }
            
            // check for validity            
            if (((rndnumber%42) == 0) && (rndnumber >= 42*1111)) {
                if ((((prefix+number+chksum+rndnumber)%4242)==0) && (chksum >= 42*1111)) {
                    return YES;
                }
            }
        }
    }
    return NO;
}

- (long) base36Value 
{
    unichar c;
    int i,p;
    long result = 0;
    NSString *aString = [self uppercaseString];
    
    for (i=[aString length]-1,p=0;i>=0;i--,p++) {
        c = [aString characterAtIndex:i];
        // 65-90:A-Z, 48-57:0-9
        if ((c >= 48) && (c <= 57)) {
            result += (long)(c-48)*pow(36,p);
        }
        if ((c >= 65) && (c <= 90)) {
            result += (long)(c-55)*pow(36,p);
        }
    }
    
    return result;
}

- (BOOL)isWhiteSpace {
    static unichar s_space=0,s_tab,s_cr,s_nl;
    if (s_space==0) {
        s_space=[@" " characterAtIndex:0];
        s_tab=[@"\t" characterAtIndex:0];
        s_cr=[@"\r" characterAtIndex:0];
        s_nl=[@"\n" characterAtIndex:0];
    }

   NSUInteger i=0;
    BOOL result=YES;
    for (i=0;i<[self length];i++) {
        unichar character=[self characterAtIndex:i];
        if (character!=s_space &&
            character!=s_tab &&
            character!=s_cr &&
            character!=s_nl) {
            result=NO;
            break;    
        }
    }
    return result;
}

- (NSRange)rangeOfLeadingWhitespaceStartingAt:(unsigned)location {
    unsigned length=[self length];
    NSRange result = NSMakeRange(location,0);
    while (NSMaxRange(result) < length &&
           ([self characterAtIndex:NSMaxRange(result)]==' ' ||
            [self characterAtIndex:NSMaxRange(result)]=='\t')) {
        result.length++;
    }
    return result;
}


- (unsigned) detabbedLengthForRange:(NSRange)aRange tabWidth:(int)aTabWidth {
    NSRange foundRange=[self rangeOfString:@"\t" options:0 range:aRange];
    if (foundRange.location==NSNotFound) {
        return aRange.length;
    } else {
        unsigned additionalLength=0;
        NSRange searchRange=aRange;
        while (foundRange.location!=NSNotFound) {
            additionalLength+=aTabWidth-((foundRange.location-aRange.location+additionalLength)%aTabWidth+1);
            searchRange.length-=foundRange.location-searchRange.location+1;
            searchRange.location=foundRange.location+1;
            foundRange=[self rangeOfString:@"\t" options:0 range:searchRange];
        }
        return aRange.length+additionalLength;
    }
}

- (BOOL)detabbedLength:(unsigned)aLength fromIndex:(unsigned)aFromIndex 
                length:(unsigned *)rLength upToCharacterIndex:(unsigned *)rIndex
              tabWidth:(int)aTabWidth {
    NSRange searchRange=NSMakeRange(aFromIndex,aLength);
    if (NSMaxRange(searchRange)>[self length]) {
        searchRange.length=[self length]-searchRange.location;
    }
    NSRange foundRange=[self rangeOfString:@"\t" options:0 range:searchRange];
    if (foundRange.location==NSNotFound) {
        *rLength=searchRange.length;
        *rIndex=aFromIndex+searchRange.length;
        return (searchRange.length==aLength);
    } else {
        NSRange lineRange=[self lineRangeForRange:NSMakeRange(aFromIndex,0)];
        *rLength=0;
        while (foundRange.location!=NSNotFound) {
            if (aLength<foundRange.location-searchRange.location) {
                *rLength+=aLength;
                *rIndex=searchRange.location+aLength;
                return YES;
            } else {
                int movement=foundRange.location-searchRange.location;
                *rLength+=movement;
                aLength -=movement;
                int spacesTabTakes=aTabWidth-(aFromIndex-lineRange.location+(*rLength))%aTabWidth;
                if (spacesTabTakes>(int)aLength) {
                    *rIndex=foundRange.location;
                    return NO;
                } else {
                    *rLength+=spacesTabTakes;
                    aLength -=spacesTabTakes;
                    searchRange.location+=movement+1;
                    searchRange.length  -=movement+1;
                }
            }
            foundRange=[self rangeOfString:@"\t" options:0 range:searchRange];
        }
        
        if (aLength<=searchRange.length) {
            *rLength+=aLength;
            *rIndex  =searchRange.location+aLength;
            return YES;
        } else {
            *rLength+=searchRange.length;
            *rIndex  =NSMaxRange(searchRange);
            return NO;
        }
    }
}

- (NSMutableString *)stringByReplacingEntitiesForUTF8:(BOOL)forUTF8  {
    static NSDictionary *sEntities=nil;
    if (!sEntities) {
        sEntities=[NSDictionary dictionaryWithObjectsAndKeys:
          @"&iexcl;",@"&#161;",
          @"&cent;",@"&#162;",
          @"&pound;",@"&#163;",
          @"&curren;",@"&#164;",
          @"&yen;",@"&#165;",
          @"&brvbar;",@"&#166;",
          @"&sect;",@"&#167;",
          @"&uml;",@"&#168;",
          @"&copy;",@"&#169;",
          @"&ordf;",@"&#170;",
          @"&laquo;",@"&#171;",
          @"&not;",@"&#172;",
          @"&reg;",@"&#174;",
          @"&macr;",@"&#175;",
          @"&deg;",@"&#176;",
          @"&plusmn;",@"&#177;",
          @"&sup2;",@"&#178;",
          @"&sup3;",@"&#179;",
          @"&acute;",@"&#180;",
          @"&micro;",@"&#181;",
          @"&para;",@"&#182;",
          @"&middot;",@"&#183;",
          @"&cedil;",@"&#184;",
          @"&sup1;",@"&#185;",
          @"&ordm;",@"&#186;",
          @"&raquo;",@"&#187;",
          @"&frac14;",@"&#188;",
          @"&frac12;",@"&#189;",
          @"&frac34;",@"&#190;",
          @"&iquest;",@"&#191;",
          @"&Agrave;",@"&#192;",
          @"&Aacute;",@"&#193;",
          @"&Acirc;",@"&#194;",
          @"&Atilde;",@"&#195;",
          @"&Auml;",@"&#196;",
          @"&Aring;",@"&#197;",
          @"&AElig;",@"&#198;",
          @"&Ccedil;",@"&#199;",
          @"&Egrave;",@"&#200;",
          @"&Eacute;",@"&#201;",
          @"&Ecirc;",@"&#202;",
          @"&Euml;",@"&#203;",
          @"&Igrave;",@"&#204;",
          @"&Iacute;",@"&#205;",
          @"&Icirc;",@"&#206;",
          @"&Iuml;",@"&#207;",
          @"&ETH;",@"&#208;",
          @"&Ntilde;",@"&#209;",
          @"&Ograve;",@"&#210;",
          @"&Oacute;",@"&#211;",
          @"&Ocirc;",@"&#212;",
          @"&Otilde;",@"&#213;",
          @"&Ouml;",@"&#214;",
          @"&times;",@"&#215;",
          @"&Oslash;",@"&#216;",
          @"&Ugrave;",@"&#217;",
          @"&Uacute;",@"&#218;",
          @"&Ucirc;",@"&#219;",
          @"&Uuml;",@"&#220;",
          @"&Yacute;",@"&#221;",
          @"&THORN;",@"&#222;",
          @"&szlig;",@"&#223;",
          @"&agrave;",@"&#224;",
          @"&aacute;",@"&#225;",
          @"&acirc;",@"&#226;",
          @"&atilde;",@"&#227;",
          @"&auml;",@"&#228;",
          @"&aring;",@"&#229;",
          @"&aelig;",@"&#230;",
          @"&ccedil;",@"&#231;",
          @"&egrave;",@"&#232;",
          @"&eacute;",@"&#233;",
          @"&ecirc;",@"&#234;",
          @"&euml;",@"&#235;",
          @"&igrave;",@"&#236;",
          @"&iacute;",@"&#237;",
          @"&icirc;",@"&#238;",
          @"&iuml;",@"&#239;",
          @"&eth;",@"&#240;",
          @"&ntilde;",@"&#241;",
          @"&ograve;",@"&#242;",
          @"&oacute;",@"&#243;",
          @"&ocirc;",@"&#244;",
          @"&otilde;",@"&#245;",
          @"&ouml;",@"&#246;",
          @"&divide;",@"&#247;",
          @"&oslash;",@"&#248;",
          @"&ugrave;",@"&#249;",
          @"&uacute;",@"&#250;",
          @"&ucirc;",@"&#251;",
          @"&uuml;",@"&#252;",
          @"&yacute;",@"&#253;",
          @"&thorn;",@"&#254;",
          @"&yuml;",@"&#255;",
          @"&OElig;",@"&#338;",
          @"&oelig;",@"&#339;",
          @"&quot;",@"&#34;",
          @"&Scaron;",@"&#352;",
          @"&scaron;",@"&#353;",
          @"&Yuml;",@"&#376;",
          @"&amp;",@"&#38;",
          @"&fnof;",@"&#402;",
          @"&lt;",@"&#60;",
          @"&gt;",@"&#62;",
          @"&circ;",@"&#710;",
          @"&tilde;",@"&#732;",
          @"&ndash;",@"&#8211;",
          @"&mdash;",@"&#8212;",
          @"&lsquo;",@"&#8216;",
          @"&rsquo;",@"&#8217;",
          @"&sbquo;",@"&#8218;",
          @"&ldquo;",@"&#8220;",
          @"&rdquo;",@"&#8221;",
          @"&bdquo;",@"&#8222;",
          @"&dagger;",@"&#8224;",
          @"&Dagger;",@"&#8225;",
          @"&bull;",@"&#8226;",
          @"&hellip;",@"&#8230;",
          @"&permil;",@"&#8240;",
          @"&prime;",@"&#8242;",
          @"&Prime;",@"&#8243;",
          @"&lsaquo;",@"&#8249;",
          @"&rsaquo;",@"&#8250;",
          @"&oline;",@"&#8254;",
          @"&frasl;",@"&#8260;",
          @"&euro;",@"&#8364;",
          @"&image;",@"&#8465;",
          @"&weierp;",@"&#8472;",
          @"&real;",@"&#8476;",
          @"&trade;",@"&#8482;",
          @"&alefsym;",@"&#8501;",
          @"&larr;",@"&#8592;",
          @"&uarr;",@"&#8593;",
          @"&rarr;",@"&#8594;",
          @"&darr;",@"&#8595;",
          @"&harr;",@"&#8596;",
          @"&crarr;",@"&#8629;",
          @"&lArr;",@"&#8656;",
          @"&uArr;",@"&#8657;",
          @"&rArr;",@"&#8658;",
          @"&dArr;",@"&#8659;",
          @"&hArr;",@"&#8660;",
          @"&forall;",@"&#8704;",
          @"&part;",@"&#8706;",
          @"&exist;",@"&#8707;",
          @"&empty;",@"&#8709;",
          @"&nabla;",@"&#8711;",
          @"&isin;",@"&#8712;",
          @"&notin;",@"&#8713;",
          @"&ni;",@"&#8715;",
          @"&prod;",@"&#8719;",
          @"&sum;",@"&#8721;",
          @"&minus;",@"&#8722;",
          @"&lowast;",@"&#8727;",
          @"&radic;",@"&#8730;",
          @"&prop;",@"&#8733;",
          @"&infin;",@"&#8734;",
          @"&ang;",@"&#8736;",
          @"&and;",@"&#8743;",
          @"&or;",@"&#8744;",
          @"&cap;",@"&#8745;",
          @"&cup;",@"&#8746;",
          @"&int;",@"&#8747;",
          @"&there4;",@"&#8756;",
          @"&sim;",@"&#8764;",
          @"&cong;",@"&#8773;",
          @"&asymp;",@"&#8776;",
          @"&ne;",@"&#8800;",
          @"&equiv;",@"&#8801;",
          @"&le;",@"&#8804;",
          @"&ge;",@"&#8805;",
          @"&sub;",@"&#8834;",
          @"&sup;",@"&#8835;",
          @"&nsub;",@"&#8836;",
          @"&sube;",@"&#8838;",
          @"&supe;",@"&#8839;",
          @"&oplus;",@"&#8853;",
          @"&otimes;",@"&#8855;",
          @"&perp;",@"&#8869;",
          @"&sdot;",@"&#8901;",
          @"&lceil;",@"&#8968;",
          @"&rceil;",@"&#8969;",
          @"&lfloor;",@"&#8970;",
          @"&rfloor;",@"&#8971;",
          @"&lang;",@"&#9001;",
          @"&rang;",@"&#9002;",
          @"&Alpha;",@"&#913;",
          @"&Beta;",@"&#914;",
          @"&Gamma;",@"&#915;",
          @"&Delta;",@"&#916;",
          @"&Epsilon;",@"&#917;",
          @"&Zeta;",@"&#918;",
          @"&Eta;",@"&#919;",
          @"&Theta;",@"&#920;",
          @"&Iota;",@"&#921;",
          @"&Kappa;",@"&#922;",
          @"&Lambda;",@"&#923;",
          @"&Mu;",@"&#924;",
          @"&Nu;",@"&#925;",
          @"&Xi;",@"&#926;",
          @"&Omicron;",@"&#927;",
          @"&Pi;",@"&#928;",
          @"&Rho;",@"&#929;",
          @"&Sigma;",@"&#931;",
          @"&Tau;",@"&#932;",
          @"&Upsilon;",@"&#933;",
          @"&Phi;",@"&#934;",
          @"&Chi;",@"&#935;",
          @"&Psi;",@"&#936;",
          @"&Omega;",@"&#937;",
          @"&alpha;",@"&#945;",
          @"&beta;",@"&#946;",
          @"&gamma;",@"&#947;",
          @"&delta;",@"&#948;",
          @"&epsilon;",@"&#949;",
          @"&zeta;",@"&#950;",
          @"&eta;",@"&#951;",
          @"&theta;",@"&#952;",
          @"&iota;",@"&#953;",
          @"&kappa;",@"&#954;",
          @"&lambda;",@"&#955;",
          @"&mu;",@"&#956;",
          @"&nu;",@"&#957;",
          @"&xi;",@"&#958;",
          @"&omicron;",@"&#959;",
          @"&pi;",@"&#960;",
          @"&rho;",@"&#961;",
          @"&sigmaf;",@"&#962;",
          @"&sigma;",@"&#963;",
          @"&tau;",@"&#964;",
          @"&upsilon;",@"&#965;",
          @"&phi;",@"&#966;",
          @"&loz;",@"&#9674;",
          @"&chi;",@"&#967;",
          @"&psi;",@"&#968;",
          @"&omega;",@"&#969;",
          @"&thetasym;",@"&#977;",
          @"&upsih;",@"&#978;",
          @"&spades;",@"&#9824;",
          @"&clubs;",@"&#9827;",
          @"&hearts;",@"&#9829;",
          @"&piv;",@"&#982;",
          @"&emsp;",@"&#8195;",
          @"&ensp;",@"&#8194;",
          @"&lrm;",@"&#8206;",
          @"&nbsp;",@"&#160;",
          @"&rlm;",@"&#8207;",
          @"&shy;",@"&#173;",
          @"&thinsp;",@"&#8201;",
          @"&zwj;",@"&#8205;",
          @"&zwnj;",@"&#8204;",
          @"&diams;",@"&#9830;", nil];
    }

    NSMutableString *string;
    string = [self mutableCopy];
    int index = 0;
	@autoreleasepool {
		while (index < [string length]) {
			@autoreleasepool {
				while (index < [string length]) {
					unichar c=[string characterAtIndex:index];
					if ((c > 128 && !forUTF8) || c=='&' || c=='<' || c=='>' || c=='"') {
						NSString *encodedString = [NSString stringWithFormat: @"&#%d;", c];
						if ([sEntities objectForKey:encodedString]) {
							encodedString = [sEntities objectForKey:encodedString];
						}
						[string replaceCharactersInRange:NSMakeRange(index, 1) withString:encodedString];
						index+=[encodedString length]-1;
					} else if (forUTF8) {
						if (c==0x00A0) {
							[string replaceCharactersInRange:NSMakeRange(index, 1) withString:@"&nbsp;"];
							index+=6-1;
						}
					}
					//        else if (c=='\n' || c=='\r') {
					//            [string replaceCharactersInRange:NSMakeRange(index,1) withString:@"<br/>\n"];
					//            index+=5;
					//        } else if (c=='\t') {
					//            [string replaceCharactersInRange:NSMakeRange(index,1) withString:@"&nbsp;&nbsp;&nbsp;"];
					//            index+=17;
					//        } else if (c==' ') {
					//            [string replaceCharactersInRange:NSMakeRange(index,1) withString:@"&nbsp;"];
					//            index+=5;
					//        }
					index ++;
					if (index % 50 == 0) {
						break;
					}
				}
			} // inner pool
		}
	}
    return string;
}

- (BOOL)findIANAEncodingUsingExpression:(NSString*)regEx encoding:(NSStringEncoding*)outEncoding;
{
	OGRegularExpression			*regex = nil;
	OGRegularExpressionMatch	*match = nil;
	BOOL						success = NO;

	//@"<meta.*?charset=(.*?)\""
	NS_DURING
	regex = [OGRegularExpression regularExpressionWithString:regEx options:OgreCaptureGroupOption | OgreIgnoreCaseOption];
	match = [regex matchInString:self];

	if ( [match count] >= 2 )
	{
		NSString *matchString = [self substringWithRange:[match rangeOfSubstringAtIndex:1]];

		if ( matchString )
		{
			CFStringEncoding cfEncoding = CFStringConvertIANACharSetNameToEncoding((CFStringRef)matchString);

			if ( cfEncoding == kCFStringEncodingInvalidId )
			{
				NSLog(@"findIANAEncodingUsingExpression:encoding: invalid encoding");
			}
			else
			{
				if ( outEncoding )
				{
					NSStringEncoding foundEncoding = CFStringConvertEncodingToNSStringEncoding(cfEncoding);
					// if we find a utf16 variant then this makes no sense as we found it in a text that was 8bit interpreted so we return no
					if (foundEncoding != NSUnicodeStringEncoding &&
						foundEncoding != 0x94000100 && // NSUTF16LittleEndianStringEncoding ||
						foundEncoding != 0x90000100 && // NSUTF16BigEndianStringEncoding ||
						foundEncoding != 0x98000100 && // NSUTF32BigEndianStringEncoding ||
						foundEncoding != 0x9c000100 && // NSUTF32LittleEndianStringEncoding ||
						foundEncoding != 0x8c000100 ) { //NSUTF32StringEncoding) {
						*outEncoding = foundEncoding;
						success = YES;
					}
				}
				else
				{
					success = NO;
				}
			}
		}
	}

	NS_HANDLER
	NSLog(@"%@", [localException description]);
	NS_ENDHANDLER
	return success;
}

- (NSString *) stringByReplacingRegularExpressionOperators  {
    static OGRegularExpression *escapingExpression = nil;
    if (!escapingExpression) {
        escapingExpression = [[OGRegularExpression alloc] initWithString:@"[\\\\\\(\\){}\\[\\]?*+^$|\\-\\.]" options:OgreFindNotEmptyOption];
    }
	return [escapingExpression replaceAllMatchesInString:self withString:@"\\\\\\0" options:OgreNoneOption];
}

- (NSRange)TCM_fullLengthRange {
	NSRange result = NSMakeRange(0, self.length);
	return result;
}

- (NSString *)initials
{
	NSString *name = self;
	NSMutableString * initials = [NSMutableString string];
	NSArray * nameComponents = [name componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	for (NSString * word in nameComponents) {
		if ([word length] > 0) {
			NSString * firstLetter = [word substringWithRange:[word rangeOfComposedCharacterSequenceAtIndex:0]];
			[initials appendString:[firstLetter uppercaseString]];
		}
	}
	return [initials copy];
}
@end

@implementation NSAttributedString (NSAttributedStringSEEAdditions)

/*"AttributeMapping:

        "WrittenBy" => { "openTag" => "<span class="@%">",
                             "closeTag" => "</span>"},
        "ForegroundColor" => {"openTag"=>"<span style="color: %@;">",
                              "closeTag"=>"</span>" }
        "Bold" => {"openTag" => "<strong>",
                   "closeTag" => "</strong>"}
        "Italic" => {"openTag" => "<em>",
                     "closeTag"=> "</em>"};
"*/

- (NSMutableString *)XHTMLStringWithAttributeMapping:(NSDictionary *)anAttributeMapping forUTF8:(BOOL)forUTF8 {
    NSMutableString *result=[[NSMutableString alloc] initWithCapacity:[self length]*2];
    NSMutableDictionary *state=[NSMutableDictionary new];
    NSMutableDictionary *toOpen=[NSMutableDictionary new];
    NSMutableDictionary *toClose=[NSMutableDictionary new];
    NSMutableArray *stateStack=[NSMutableArray new];
    
    
    NSRange foundRange;
    NSRange maxRange=NSMakeRange(0,[self length]);
    NSDictionary *attributes;
    NSUInteger index=0;
    do {
		@autoreleasepool {
			attributes=[self attributesAtIndex:index
						 longestEffectiveRange:&foundRange inRange:maxRange];
			
			NSEnumerator *relevantAttributes=[anAttributeMapping keyEnumerator];
			NSString *key;
			while ((key=[relevantAttributes nextObject])) {
				id currentValue=[state      objectForKey:key];
				id nextValue   =[attributes objectForKey:key];
				if (currentValue == nil && nextValue == nil) {
					// nothing
				} else if (currentValue == nil) {
					[toOpen setObject:nextValue forKey:key];
				} else if (nextValue == nil) {
					[toClose setObject:currentValue forKey:key];
				} else if (![currentValue isEqual:nextValue]) {
					[toClose setObject:currentValue forKey:key];
					[toOpen setObject:nextValue forKey:key];
				}
			}
			int stackPosition=[stateStack count];
			while ([toClose count] && stackPosition>0) {
				stackPosition--;
				NSDictionary *pair=[stateStack objectAtIndex:stackPosition];
				NSString *attributeName=[pair objectForKey:@"AttributeName"];
				[result appendFormat:[[anAttributeMapping objectForKey:attributeName] objectForKey:@"closeTag"],[pair objectForKey:@"AttributeValue"]];
				if ([toClose objectForKey:attributeName]) {
					[toClose removeObjectForKey:attributeName];
					[stateStack removeObjectAtIndex:stackPosition];
					[state removeObjectForKey:attributeName];
				}
			}
			while (stackPosition<[stateStack count]) {
				NSDictionary *pair=[stateStack objectAtIndex:stackPosition];
				NSString *attributeName=[pair objectForKey:@"AttributeName"];
				[result appendFormat:[[anAttributeMapping objectForKey:attributeName] objectForKey:@"openTag"],[pair objectForKey:@"AttributeValue"]];
				stackPosition++;
			}
			NSEnumerator *openAttributes=[toOpen keyEnumerator];
			NSString *attributeName;
			while ((attributeName=[openAttributes nextObject])) {
				[result appendFormat:[[anAttributeMapping objectForKey:attributeName] objectForKey:@"openTag"],[toOpen objectForKey:attributeName]];
				[state setObject:[toOpen objectForKey:attributeName] forKey:attributeName];
				[stateStack addObject:[NSDictionary dictionaryWithObjectsAndKeys:attributeName,@"AttributeName",[toOpen objectForKey:attributeName],@"AttributeValue",nil]];
			}
			[toOpen removeAllObjects];
			
			NSString *contentString=[[[self string] substringWithRange:foundRange] stringByReplacingEntitiesForUTF8:forUTF8];
			[result appendString:contentString];
			
			index=NSMaxRange(foundRange);
		}
    } while (index<NSMaxRange(maxRange));
    // close all remaining open tags
    int stackPosition=[stateStack count];
    while (stackPosition>0) {
        stackPosition--;
        NSDictionary *pair=[stateStack objectAtIndex:stackPosition];
        NSString *attributeName=[pair objectForKey:@"AttributeName"];
        [result appendFormat:[[anAttributeMapping objectForKey:attributeName] objectForKey:@"closeTag"],[pair objectForKey:@"AttributeValue"]];
    }
    
    return result;
}


- (NSRange)TCM_fullLengthRange {
	NSRange result = NSMakeRange(0, self.length);
	return result;
}

#define STACKLIMIT 100
#define BUFFERSIZE 500

- (NSUInteger)TCM_positionOfMatchingBracketToPosition:(NSUInteger)position bracketSettings:(TCMBracketSettings *)aBracketSettings {
    NSString *aString = [self string];
    NSUInteger result=NSNotFound;
    unichar possibleBracket=[aString characterAtIndex:position];
    BOOL forward=YES;
    if ([aBracketSettings charIsOpeningBracket:possibleBracket]) {
        forward=YES;
    } else if ([aBracketSettings charIsClosingBracket:possibleBracket]) {
        forward=NO;
    } else {
        return result;
    }
    // extra block to only be initialized when thing was a bracket
    {
        unichar stack[STACKLIMIT];
        int stackPosition=0;
        NSRange searchRange,bufferRange;
        unichar buffer[BUFFERSIZE];
        int i;
        BOOL stop=NO;
		
        stack[stackPosition]=[aBracketSettings matchingBracketForChar:possibleBracket];
		
        if (forward) {
            searchRange=NSMakeRange(position+1,[aString length]-(position+1));
        } else {
            searchRange=NSMakeRange(0,position);
        }
        while (searchRange.length>0 && !stop) {
            if (searchRange.length<=BUFFERSIZE) {
                bufferRange=searchRange;
            } else {
                if (forward) {
                    bufferRange=NSMakeRange(searchRange.location,BUFFERSIZE);
                } else {
                    bufferRange=NSMakeRange(NSMaxRange(searchRange)-BUFFERSIZE,BUFFERSIZE);
                }
            }
            [aString getCharacters:buffer range:bufferRange];
            // go through the buffer
            if (forward) {
                for (i=0;i<(int)bufferRange.length && !stop;i++) {
					NSUInteger locationToCheck = bufferRange.location+i;
					unichar character = buffer[i];
                    if ([aBracketSettings charIsOpeningBracket:character] &&
						![aBracketSettings shouldIgnoreBracketAtIndex:locationToCheck attributedString:self]) {
                        if (++stackPosition>=STACKLIMIT) {
                            stop=YES;
                        } else {
                            stack[stackPosition]=[aBracketSettings  matchingBracketForChar:character];
                        }
                    } else if ([aBracketSettings charIsClosingBracket:character] &&
							   ![aBracketSettings shouldIgnoreBracketAtIndex:locationToCheck attributedString:self]) {
                        if (character != stack[stackPosition]) {
                            stop=YES;
                        } else {
                            if (--stackPosition<0) {
                                result = locationToCheck;
                                stop = YES;
                            }
                        }
                    }
                }
            } else { // backward
                for (i=bufferRange.length-1;i>=0 && !stop;i--) {
 					NSUInteger locationToCheck = bufferRange.location+i;
					unichar character = buffer[i];
					if ([aBracketSettings charIsClosingBracket:character] &&
						![aBracketSettings shouldIgnoreBracketAtIndex:locationToCheck attributedString:self]) {
						if (++stackPosition>=STACKLIMIT) {
                            stop=YES;
                        } else {
                            stack[stackPosition]=[aBracketSettings matchingBracketForChar:buffer[i]];
                        }
                    } else if ([aBracketSettings charIsOpeningBracket:character] &&
							   ![aBracketSettings shouldIgnoreBracketAtIndex:locationToCheck attributedString:self]) {
                        if (character != stack[stackPosition]) {
                            NSBeep(); // do it like project builder :-
                            stop = YES;
                        } else {
                            if (--stackPosition<0) {
                                result = locationToCheck;
                                stop = YES;
                            }
                        }
                    }
                }
            }
            if (forward) {
                searchRange.location+=bufferRange.length;
            }
            searchRange.length-=bufferRange.length;
        }
    }
    return result;
}


@end
