/*
 * Name: OGReplaceExpression.m
 * Project: OgreKit
 *
 * Creation Date: Sep 22 2003
 * Author: Isao Sonobe <sonobe@gauge.scphys.kyoto-u.ac.jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <OgreKit/OGRegularExpression.h>
#import <OgreKit/OGRegularExpressionPrivate.h>
#import <OgreKit/OGRegularExpressionMatch.h>
#import <OgreKit/OGReplaceExpression.h>
#import <OgreKit/OGReplaceExpressionPrivate.h>
#import <stdlib.h>
#import <limits.h>

// exception name
NSString	* const OgreReplaceException = @"OGReplaceExpressionException";
// 自身をencoding/decodingするためのkey
static NSString	* const OgreCompiledReplaceStringKey = @"OgreReplaceCompiledReplaceString";
static NSString	* const OgreNameArrayKey             = @"OgreReplaceNameArray";
// 
static OGRegularExpression  *gReplaceRegex = nil;

// \+, \-, \`, \'
#define OgreEscapePlus					(-1)
#define OgreEscapeMinus					(-2)
#define OgreEscapeBackquote				(-3)
#define OgreEscapeQuote					(-4)
#define OgreEscapeNamedGroup			(-5)
#define OgreEscapeControlCode			(-6)
#define OgreEscapeNonescapedCharacters  (-7)
#define OgreEscapeNormalCharacters		(-8)


@implementation OGReplaceExpression

+ (void)initialize
{
#ifdef DEBUG_OGRE
	NSLog(@"+initialize of OGReplaceExpression");
#endif
	gReplaceRegex = [[OGRegularExpression alloc] 
		initWithString:[NSString stringWithFormat:
		@"([^\\\\]+)|(?:\\\\x\\{(?@[0-9a-fA-F]{1,4})\\}){1,%d}|(?:\\\\(?:([0-9])|(&)|(\\+)|(`)|(')|(\\-)|(?:g<([0-9]+)>)|(?:g<([_a-zA-Z][_0-9a-zA-Z]*)>)|(t)|(n)|(r)|(\\\\)|(.?)))", ONIG_MAX_CAPTURE_HISTORY_GROUP] 
		/*1						2                                        3		 4   5	   6   7   8          9               10                         11  12  13  14     default */
		options:(OgreCaptureGroupOption) 
		syntax:OgreRubySyntax 
		escapeCharacter:OgreBackslashCharacter];
}

// 初期化
- (id)initWithString:(NSString*)replaceString escapeCharacter:(NSString*)character
{
#ifdef DEBUG_OGRE
	NSLog(@"-initWithString: of OGReplaceExpression");
#endif
	self = [super init];
	if (self == nil) return nil;
	
	if ((replaceString == nil) || (character == nil)) {
		// stringがnilの場合、例外を発生させる。
		[self release];
		[NSException raise:OgreReplaceException format: @"nil string (or other) argument"];
	}
	
	int			specialKey = 0;
	unsigned	matchIndex = 0;
	NSString	*controlCharacter = nil, *swappedReplaceString;
	unsigned	numberOfMatches = 0;
	unichar		unic[ONIG_MAX_CAPTURE_HISTORY_GROUP + 1];
	unsigned	numberOfHistory, indexOfHistory;
	
	NSEnumerator				*matchEnumerator;
	OGRegularExpressionMatch	*match, *cap;
	
	NSAutoreleasePool   *pool;
	
	// 置換文字列をcompileする
	//  compile結果: NSMutableArray
	//   文字列		NSString
	//   特殊文字		NSNumber
	//				対応表(int:特殊文字)
	//				0-9: \0 - \9
	//				OgreEscapePlus: \+
	//				OgreEscapeMinus: \-
	//				OgreEscapeBackquote: \`
	//				OgreEscapeQuote: \'
	//				OgreEscapeNamedGroup: \g
	//				OgreEscapeControlCode: \t, \n, \r
	_compiledReplaceString = [[NSMutableArray alloc] initWithCapacity:0];
	
	/* named group関連 */
	_nameArray = [[NSMutableArray alloc] initWithCapacity:0];	// replacedStringで使用されたnames (現れた順)
	
	// 置換文字列の\を入れ替える
	swappedReplaceString = [OGRegularExpression swapBackslashInString:replaceString forCharacter:character];
	matchEnumerator = [gReplaceRegex matchEnumeratorInString:swappedReplaceString];
	pool = [[NSAutoreleasePool alloc] init];
	
	while ((match = [matchEnumerator nextObject]) != nil) {
		numberOfMatches++;
		
		matchIndex = [match indexOfFirstMatchedSubstring];  // どの部分式にマッチしたのか
#ifdef DEBUG_OGRE
		NSLog(@" matchIndex: %d, %@", matchIndex, [match matchedString]);
#endif
		switch (matchIndex) {
			case 1: // 通常文字
				specialKey = OgreEscapeNormalCharacters;
				break;
			case 3: // \[0-9]
				specialKey = [[match substringAtIndex:matchIndex] intValue];
				break;
			case 4: // \&
				specialKey = 0;
				break;
			case 5: // \+
				specialKey = OgreEscapePlus;
				break;
			case 6: // \`
				specialKey = OgreEscapeBackquote;
				break;
			case 7: // \'
				specialKey = OgreEscapeQuote;
				break;
			case 8: // \-
				specialKey = OgreEscapeMinus;
				break;
			case 9: // \g<number>
				specialKey = [[match substringAtIndex:matchIndex] intValue];
				break;
			case 10: // \g<name>
				specialKey = OgreEscapeNamedGroup;
				[_nameArray addObject:[match substringAtIndex:matchIndex]];
				break;
			case 11: // \t
				specialKey = OgreEscapeControlCode;
				controlCharacter = [NSString stringWithFormat:@"\x09"];
				break;
			case 12: // \n
				specialKey = OgreEscapeControlCode;
				controlCharacter = [NSString stringWithFormat:@"\x0a"];
				break;
			case 13: // \r
				specialKey = OgreEscapeControlCode;
				controlCharacter = [NSString stringWithFormat:@"\x0d"];
				break;
			case 14: // Escaped Backslash 
				specialKey = OgreEscapeControlCode;
				controlCharacter = [NSString stringWithFormat:@"\\"];
				break;
			case 2: // \x{H} or \x{HH}, \x{HHH}, \x{HHHH} (H is a hexadecimal number)
				specialKey = OgreEscapeControlCode;
				cap = [match captureHistoryAtIndex:matchIndex];
				numberOfHistory = [cap count];
				for (indexOfHistory = 0; indexOfHistory < numberOfHistory; indexOfHistory++) unic[indexOfHistory] = (unichar)strtoul([[cap substringAtIndex:indexOfHistory] cString], NULL, 16);
				unic[numberOfHistory] = 0;
				controlCharacter = [NSString stringWithCharacters:unic length:numberOfHistory];
				break;
			default: // \.? 
				specialKey = OgreEscapeNonescapedCharacters;
				break;
		}
		
		if (specialKey == OgreEscapeNormalCharacters) {
			// 通常文字列
			[_compiledReplaceString addObject:[match matchedString]];
		} else if (specialKey == OgreEscapeNonescapedCharacters) {
			// \. 
			[_compiledReplaceString addObject:[OGRegularExpression swapBackslashInString:[match matchedString] forCharacter:character]];
		} else if (specialKey == OgreEscapeControlCode) {
			// コントロール文字
			[_compiledReplaceString addObject:controlCharacter];
		} else {
			// その他
			[_compiledReplaceString addObject:[NSNumber numberWithInt:specialKey]];
		}
		
		if ((numberOfMatches % 100) == 0) {
			[pool release];
			pool = [[NSAutoreleasePool alloc] init];
		}
	}
	
	// compileされた結果
#ifdef DEBUG_OGRE
	NSLog(@"Compiled Replace String: %@", [_compiledReplaceString description]);
	NSLog(@"Name Array: %@", [_nameArray description]);
#endif

	[pool release];

	return self;
}

- (id)initWithString:(NSString*)expressionString
{
	return [self initWithString:expressionString escapeCharacter:[OGRegularExpression defaultEscapeCharacter]];
}

+ (id)replaceExpressionWithString:(NSString*)expressionString escapeCharacter:(NSString*)character
{
	return [[[[self class] alloc] initWithString:expressionString escapeCharacter:character] autorelease];
}

+ (id)replaceExpressionWithString:(NSString*)expressionString;
{
	return [[[[self class] alloc] initWithString:expressionString escapeCharacter:[OGRegularExpression defaultEscapeCharacter]] autorelease];
}


- (void)dealloc
{
#ifdef DEBUG_OGRE
	NSLog(@"-dealloc of OGReplaceExpression");
#endif
	[_compiledReplaceString release];
	[_nameArray release];
	
	[super dealloc];
}

// 置換
- (NSString*)replaceMatchedStringOf:(OGRegularExpressionMatch*)match
{
	if (match == nil) {
		// stringがnilの場合、例外を発生させる。
		[NSException raise:OgreException format: @"nil string (or other) argument"];
	}
	
	NSMutableString	*resultString = [NSMutableString string];	// 置換結果
	NSString		*substr;
	
	NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
	
	// マッチした文字列をcompileされた置換文字列に従って置換
	NSEnumerator	*strEnumerator = [_compiledReplaceString objectEnumerator];
	id anObject;
	
	NSString	*name;
	unsigned	numOfNames = 0;
	int			specialKey;
	
	while ( (anObject = [strEnumerator nextObject]) != nil ) {
		if ([anObject isKindOfClass:[NSString class]]) {
			// anObject が文字列の場合
			[resultString appendString: anObject];
			
		} else if ([anObject isKindOfClass:[NSNumber class]]) {
			// anObject が数値の場合
			specialKey = [anObject intValue];
			switch (specialKey) {
				case OgreEscapePlus:			// \+
					// 最後にマッチした部分文字列
					substr = [match lastMatchSubstring];
					if (substr != nil) {
						[resultString appendString:substr];
					}
					break;
				case OgreEscapeBackquote:	// \`
					// マッチした部分よりも前の文字列
					[resultString appendString:[match prematchString]];
					break;
				case OgreEscapeQuote:		// \'
					// マッチした部分よりも後ろの文字列
					[resultString appendString:[match postmatchString]];
					break;
				case OgreEscapeMinus:		// \-
					// マッチした部分と一つ前にマッチした部分の間の文字列
					[resultString appendString:[match stringBetweenMatchAndLastMatch]];
					break;
				case OgreEscapeNamedGroup:	// \g<name>
					name = [_nameArray objectAtIndex:numOfNames];
					substr = [match substringNamed:name];
					numOfNames++;
					if (substr != nil) {
						[resultString appendString:substr];
					}
					break;
				default:	// \0 - \9, \&, \g<index>
					substr = [match substringAtIndex: specialKey];
					if (substr != nil) {
						[resultString appendString:substr];
					}
					break;
			}
		}
	}
	
	[pool release];
	
	return resultString;
}

// NSCoding protocols
- (void)encodeWithCoder:(NSCoder*)encoder
{
#ifdef DEBUG_OGRE
	NSLog(@"-encodeWithCoder: of OGReplaceExpression");
#endif
	if ([encoder allowsKeyedCoding]) {
		[encoder encodeObject: _compiledReplaceString forKey: OgreCompiledReplaceStringKey];
		[encoder encodeObject: _nameArray forKey: OgreNameArrayKey];
	} else {
		[encoder encodeObject: _compiledReplaceString];
		[encoder encodeObject: _nameArray];
	}
}

- (id)initWithCoder:(NSCoder*)decoder
{
#ifdef DEBUG_OGRE
	NSLog(@"-initWithCoder: of OGReplaceExpression");
#endif
	self = [super init];
	if (self == nil) return nil;
	
	BOOL			allowsKeyedCoding = [decoder allowsKeyedCoding];
	// NSString			*_escapeCharacter;
    if (allowsKeyedCoding) {
		_compiledReplaceString = [[decoder decodeObjectForKey: OgreCompiledReplaceStringKey] retain];
	} else {
		_compiledReplaceString = [[decoder decodeObject] retain];
	}
	if (_compiledReplaceString == nil) {
		// エラー。例外を発生させる。
		[self release];
		[NSException raise:OgreReplaceException format:@"fail to decode"];
	}
	
	// NSString			*_expressionString;
    if (allowsKeyedCoding) {
		_nameArray = [[decoder decodeObjectForKey: OgreNameArrayKey] retain];
	} else {
		_nameArray = [[decoder decodeObject] retain];
	}
	if (_nameArray == nil) {
		// エラー。例外を発生させる。
		[self release];
		[NSException raise:OgreReplaceException format:@"fail to decode"];
	}
	
	return self;
}

// NSCopying protocol
- (id)copyWithZone:(NSZone*)zone
{
#ifdef DEBUG_OGRE
	NSLog(@"-copyWithZone: of OGReplaceExpression");
#endif
	id	newObject = [[[self class] allocWithZone:zone] init];
	if (newObject != nil) {
		[newObject _setCompiledReplaceString:_compiledReplaceString];
		[newObject _setNameArray:_nameArray];
	}
	
	return newObject;
}

// description
- (NSString*)description
{
	return [[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:
			_compiledReplaceString, 
			_nameArray, 
			nil] 
		forKeys:[NSArray arrayWithObjects:
			@"Compiled Replace String", 
			@"Names",
			nil]] description];
}

@end
