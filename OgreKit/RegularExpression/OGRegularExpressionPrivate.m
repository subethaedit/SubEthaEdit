/*
 * Name: OGRegularExpressionPrivate.m
 * Project: OgreKit
 *
 * Creation Date: Sep 01 2003
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#ifndef NOT_RUBY
# define NOT_RUBY
#endif
#ifndef HAVE_CONFIG_H
# define HAVE_CONFIG_H
#endif
#import <OgreKit/onigmo.h>

#import <OgreKit/OGRegularExpression.h>
#import <OgreKit/OGRegularExpressionPrivate.h>
#import <OgreKit/OGString.h>
#import <OgreKit/OGMutableString.h>

OnigSyntaxType  OgrePrivatePOSIXBasicSyntax;
OnigSyntaxType  OgrePrivatePOSIXExtendedSyntax;
OnigSyntaxType  OgrePrivateEmacsSyntax;
OnigSyntaxType  OgrePrivateGrepSyntax;
OnigSyntaxType  OgrePrivateGNURegexSyntax;
OnigSyntaxType  OgrePrivateJavaSyntax;
OnigSyntaxType  OgrePrivatePerlSyntax;
OnigSyntaxType  OgrePrivateRubySyntax;

@implementation OGRegularExpression (Private)

/* ����J���\�b�h */

- (void)dealloc
{
#ifdef DEBUG_OGRE
	NSLog(@"-dealloc of %@", [self className]);
#endif
	// named group(�t����)����
	[_groupIndexForNameDictionary release];
	[_nameForGroupIndexArray release];
	
	// �S�Ԑ��K�\���I�u�W�F�N�g
	if (_regexBuffer != NULL) onig_free(_regexBuffer);
	
	// ���K�\����\��������
    NSZoneFree([self zone], _UTF16ExpressionString);
	[_expressionString release];
	
	// \�̑�֕���
	[_escapeCharacter release];
	
	[super dealloc];
}

// oniguruma regular expression buffer
- (regex_t*)patternBuffer
{
	return _regexBuffer;
}

// OgreSyntax�ɑΉ�����OnigSyntaxType*��Ԃ��B
+ (OnigSyntaxType*)onigSyntaxTypeForSyntax:(OgreSyntax)syntax
{
	if(syntax == OgreSimpleMatchingSyntax)	return &OgrePrivateRubySyntax;
	if(syntax == OgrePOSIXBasicSyntax)		return &OgrePrivatePOSIXBasicSyntax;
	if(syntax == OgrePOSIXExtendedSyntax)	return &OgrePrivatePOSIXExtendedSyntax;
	if(syntax == OgreEmacsSyntax)			return &OgrePrivateEmacsSyntax;
	if(syntax == OgreGrepSyntax)			return &OgrePrivateGrepSyntax;
	if(syntax == OgreGNURegexSyntax)		return &OgrePrivateGNURegexSyntax;
	if(syntax == OgreJavaSyntax)			return &OgrePrivateJavaSyntax;
	if(syntax == OgrePerlSyntax)			return &OgrePrivatePerlSyntax;
	if(syntax == OgreRubySyntax)			return &OgrePrivateRubySyntax;
	
	[NSException raise:OgreException format:@"unknown syntax."];
	return NULL;	// dummy
}

// string����\��character�ɒu���������������Ԃ��Bcharacter��nil�̏ꍇ�Astring��Ԃ��B
+ (NSObject<OGStringProtocol>*)changeEscapeCharacterInOGString:(NSObject<OGStringProtocol>*)string toCharacter:(NSString*)character
{
	if ( (character == nil) || (string == nil) || ([character length] == 0) ) {
		// �G���[�B��O�𔭐�������B
		[NSException raise:NSInvalidArgumentException format:@"nil string (or other) argument"];
	}
	
	if ([character isEqualToString:OgreBackslashCharacter]) {
		return string;
	}
	
	NSString	*plainString = [string string];
	unsigned	strLength = [plainString length];
	NSRange		scanRange = NSMakeRange(0, strLength);	// �X�L��������͈�
	NSRange		matchRange;					// escape�̔������ꂽ�͈�(length�͏��1)
	
	/* escape character set */
	NSCharacterSet	*swapCharSet = [NSCharacterSet characterSetWithCharactersInString:
		[OgreBackslashCharacter stringByAppendingString:character]];
	
	NSObject<OGStringProtocol,OGMutableStringProtocol>	*resultString;
	resultString = [[[[string mutableClass] alloc] init] autorelease];
	
	unsigned			counterOfAutorelease = 0;
	NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
	
	while ( (matchRange = [plainString rangeOfCharacterFromSet:swapCharSet options:0 range:scanRange]).length > 0 ) {
		unsigned	lastMatchLocation = scanRange.location;
		[resultString appendOGString:[string substringWithRange:NSMakeRange(lastMatchLocation, matchRange.location - lastMatchLocation)]];
		
		if ([[plainString substringWithRange:matchRange] isEqualToString:OgreBackslashCharacter]) {
			// \ -> \\ .
			[resultString appendOGString:[string substringWithRange:matchRange]];
			[resultString appendOGString:[string substringWithRange:matchRange]];
			scanRange.location = matchRange.location + 1;
		} else {
			if (matchRange.location + 1 < strLength && [[plainString substringWithRange:NSMakeRange(matchRange.location + 1, 1)] isEqualToString:character]) {
				// \\ -> \ .
				[resultString appendOGString:[string substringWithRange:matchRange]];
				scanRange.location = matchRange.location + 2;
			} else {
				// \(?=[^\]) -> \ .
				[resultString appendString:OgreBackslashCharacter hasAttributesOfOGString:[string substringWithRange:matchRange]];
				scanRange.location = matchRange.location + 1;
			}
		}
		scanRange.length = strLength - scanRange.location;
		
		counterOfAutorelease++;
		if (counterOfAutorelease % 100 == 0) {
			[pool release];
			pool = [[NSAutoreleasePool alloc] init];
		}
	}
	[resultString appendOGString:[string substringWithRange:NSMakeRange(scanRange.location, scanRange.length)]];
	
	[pool release];
	
	//NSLog(@"%@", resultString);
	return resultString;
}

// character�̕������Ԃ��B
/*
 �߂�l:
  OgreKindOfNil			character == nil
  OgreKindOfEmpty		�󕶎� @""
  OgreKindOfBackslash	\ @"\\"
  OgreKindOfNormal		���̑�
 */
+ (OgreKindOfCharacter)kindOfCharacter:(NSString*)character
{
	if (character == nil) {
		// Character��nil�̏ꍇ
		return OgreKindOfNil;
	}
	if ([character length] == 0) {
		// Character���󕶎���̏ꍇ
		return OgreKindOfEmpty;
	}
	// character��1������
	NSString	*substr = [character substringWithRange:NSMakeRange(0,1)];
		
	if ([substr isEqualToString:@"\\"]) {
		// \�̏ꍇ
		return OgreKindOfBackslash;
	}
		
	// ���ꕶ���łȂ��ꍇ
	return OgreKindOfNormal;
}

// �󔒂ŒP����O���[�v��������B��: @"alpha beta gamma" -> @"(alpha)|(beta)|(gamma)"
+ (NSString*)delimitByWhitespaceInString:(NSString*)string
{	
	if (string == nil) {
		// �G���[�B��O�𔭐�������B
		[NSException raise:OgreException format:@"nil string (or other) argument"];
	}

	NSMutableString	*expressionString = [NSMutableString stringWithString:@""];
	BOOL	first = YES;
	NSString	*scannedName;
	NSScanner	*scanner = [NSScanner scannerWithString:string];
	NSCharacterSet	*whitespaceCharacterSet = [NSCharacterSet whitespaceCharacterSet];
	
	unsigned	counterOfAutorelease = 0;
	NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];

	while (![scanner isAtEnd]) {
        if ([scanner scanUpToCharactersFromSet:whitespaceCharacterSet intoString:&scannedName]) {
			if ([scannedName length] == 0) continue;
			if (first) {
				[expressionString appendString: [NSString stringWithFormat:@"(%@)", scannedName]];
				first = NO;
			} else {
				[expressionString appendString: [NSString stringWithFormat:@"|(%@)", scannedName]];
			}
        }
        [scanner scanCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:nil];
		
		counterOfAutorelease++;
		if (counterOfAutorelease % 100 == 0) {
			[pool release];
			pool = [[NSAutoreleasePool alloc] init];
		}
    }
	
	[pool release];
	
	//NSLog(@"%@", expressionString);
	return expressionString;
}

// ���O��name��group number
// ���݂��Ȃ����O�̏ꍇ��-1��Ԃ��B
// ����̖��O�������������񂪕�������ꍇ��-2��Ԃ��B
- (int)groupIndexForName:(NSString*)name
{
	if (name == nil) {
		[NSException raise:NSInvalidArgumentException format:@"nil string (or other) argument"];
	}
	
	if (_groupIndexForNameDictionary == nil) return -1;
	
	NSArray	*array = [_groupIndexForNameDictionary objectForKey:name];
	if (array == nil) return -1;
	if ([array count] != 1) return -2;
	
	return [[array objectAtIndex:0] unsignedIntValue];
}

// index�Ԗڂ̕���������̖��O
// ���݂��Ȃ����O�̏ꍇ�� nil ��Ԃ��B
- (NSString*)nameForGroupIndex:(unsigned)index
{
	if ( (_nameForGroupIndexArray == nil) || (index < 1) || (index > [_nameForGroupIndexArray count])) {
		return nil;
	}
	
	NSString	*name = [_nameForGroupIndexArray objectAtIndex:(index - 1)];
	if ([name length] == 0) return nil;	// @"" �� nil �ɓǂݑւ���B
	
	return name;
}


@end
