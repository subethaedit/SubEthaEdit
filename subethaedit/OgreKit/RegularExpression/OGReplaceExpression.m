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
#import <OgreKit/OGRegularExpressionCapture.h>
#import <OgreKit/OGReplaceExpression.h>
#import <OgreKit/OGReplaceExpressionPrivate.h>
#import <stdlib.h>
#import <limits.h>

// exception name
NSString	* const OgreReplaceException = @"OGReplaceExpressionException";
// 自身をencoding/decodingするためのkey
static NSString	* const OgreCompiledReplaceStringKey     = @"OgreReplaceCompiledReplaceString";
static NSString	* const OgreCompiledReplaceStringTypeKey = @"OgreReplaceCompiledReplaceStringType";
static NSString	* const OgreNameArrayKey                 = @"OgreReplaceNameArray";
// 
static OGRegularExpression  *gReplaceRegex = nil;

// \+, \-, \`, \'
#define OgreEscapePlus					(-1)
#define OgreEscapeMinus					(-2)
#define OgreEscapeBackquote				(-3)
#define OgreEscapeQuote					(-4)
#define OgreEscapeNamedGroup			(-5)
#define OgreEscapeControlCode			(-6)
#define OgreEscapeNormalCharacters		(-8)
#define OgreNonEscapedNormalCharacters	(-9)


@implementation OGReplaceExpression

+ (void)initialize
{
#ifdef DEBUG_OGRE
	NSLog(@"+initialize of %@", [self className]);
#endif
	gReplaceRegex = [[OGRegularExpression alloc] 
		initWithString:[NSString stringWithFormat:
		@"([^\\\\]+)|(?:\\\\x\\{(?@[0-9a-fA-F]{1,4})\\}){1,%d}|(?:\\\\(?:([0-9])|(&)|(\\+)|(`)|(')|(\\-)|(?:g<([0-9]+)>)|(?:g<([_a-zA-Z][_0-9a-zA-Z]*)>)|(t)|(n)|(r)|(\\\\)|(.?)))", ONIG_MAX_CAPTURE_HISTORY_GROUP] 
		/*1						2                                        3		 4   5	   6   7   8          9               10                         11  12  13  14     15    */
		options:(OgreCaptureGroupOption) 
		syntax:OgreRubySyntax 
		escapeCharacter:OgreBackslashCharacter];
}

// 初期化
- (id)initWithString:(NSString*)replaceString 
	syntax:(OgreSyntax)syntax 
	escapeCharacter:(NSString*)character
{
#ifdef DEBUG_OGRE
	NSLog(@"-initWithString: of %@", [self className]);
#endif
	self = [super init];
	if (self == nil) return nil;
	
	if ((replaceString == nil) || (character == nil) || ([character length] == 0)) {
		// stringがnilの場合、例外を発生させる。
		[self release];
		[NSException raise:OgreReplaceException format: @"nil string (or other) argument"];
	}
	
    NSString    *escCharacter = [[character copy] autorelease];
	int			specialKey = 0;
	unsigned	matchIndex = 0;
	NSString	*controlCharacter = nil;
	NSString	*compileTimeString;
	unsigned	numberOfMatches = 0;
	unichar		unic[ONIG_MAX_CAPTURE_HISTORY_GROUP + 1];
	unsigned	numberOfHistory, indexOfHistory;
	
	NSEnumerator				*matchEnumerator;
	OGRegularExpressionMatch	*match;
    OGRegularExpressionCapture  *cap;
	
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
	//				OgreEscapeNormalCharacters: \[^\]?
	//				OgreNonEscapedNormalCharacters: otherwise
	
	/* named group関連 */
	_nameArray = [[NSMutableArray alloc] initWithCapacity:0];	// replacedStringで使用されたnames (現れた順)
	
	if (syntax == OgreSimpleMatchingSyntax) {
		_compiledReplaceString     = [[NSMutableArray alloc] initWithObjects:replaceString, nil];
		_compiledReplaceStringType = [[NSMutableArray alloc] initWithObjects:[NSNumber numberWithInt:OgreNonEscapedNormalCharacters], nil];
	} else {
		_compiledReplaceString     = [[NSMutableArray alloc] initWithCapacity:0];
		_compiledReplaceStringType = [[NSMutableArray alloc] initWithCapacity:0];
		
		if ([character isEqualToString:OgreBackslashCharacter]) {
			compileTimeString = replaceString;
		} else {
			compileTimeString = [OGRegularExpression changeEscapeCharacterInString:replaceString toCharacter:escCharacter];
		}
		
		matchEnumerator = [gReplaceRegex matchEnumeratorInString:compileTimeString
			options:OgreCaptureGroupOption 
			range:NSMakeRange(0, [compileTimeString length])];
		pool = [[NSAutoreleasePool alloc] init];
		
		while ((match = [matchEnumerator nextObject]) != nil) {
			numberOfMatches++;
			
			matchIndex = [match indexOfFirstMatchedSubstring];  // どの部分式にマッチしたのか
	#ifdef DEBUG_OGRE
			NSLog(@" matchIndex: %d, %@", matchIndex, [match matchedString]);
	#endif
			switch (matchIndex) {
				case 1: // 通常文字
					specialKey = OgreNonEscapedNormalCharacters;
					break;
				case 15: // \\[^\\]? 
					specialKey = OgreEscapeNormalCharacters;
					break;
				case 2: // \x{H} or \x{HH}, \x{HHH}, \x{HHHH} (H is a hexadecimal number)
					specialKey = OgreEscapeControlCode;
					cap = [match captureHistory];
					numberOfHistory = [cap numberOfChildren];
					for (indexOfHistory = 0; indexOfHistory < numberOfHistory; indexOfHistory++) {
						unic[indexOfHistory] = (unichar)strtoul([[[cap childAtIndex:indexOfHistory] string] cString], NULL, 16);
					}
					unic[numberOfHistory] = 0;
					controlCharacter = [NSString stringWithCharacters:unic length:numberOfHistory];
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
				case 14: // Escape Character
					specialKey = OgreEscapeControlCode;
					controlCharacter = OgreBackslashCharacter;
					break;
				default: // error
					[NSException raise:OgreException format: @"undefined replace expression (BUG!)"];
					break;
			}
			
			if (specialKey == OgreEscapeNormalCharacters || specialKey == OgreNonEscapedNormalCharacters) {
				// 通常文字列
				[_compiledReplaceString addObject:[match substringAtIndex:matchIndex]];
				specialKey = OgreNonEscapedNormalCharacters;
			}  else if (specialKey == OgreEscapeControlCode) {
				// コントロール文字
				[_compiledReplaceString addObject:controlCharacter];
				specialKey = OgreNonEscapedNormalCharacters;
			} else {
				// その他
				[_compiledReplaceString addObject:[match matchedString]];
			}
			[_compiledReplaceStringType addObject:[NSNumber numberWithInt:specialKey]];
			
			if ((numberOfMatches % 100) == 0) {
				[pool release];
				pool = [[NSAutoreleasePool alloc] init];
			}
		}
		
		[pool release];
	}
	
	// compileされた結果
#ifdef DEBUG_OGRE
	NSLog(@"Compiled Replace String: %@", [_compiledReplaceString description]);
	NSLog(@"Name Array: %@", [_nameArray description]);
#endif

	return self;
}


- (id)initWithString:(NSString*)replaceString 
	escapeCharacter:(NSString*)character 
{
	return [self initWithString:replaceString 
		syntax:[OGRegularExpression defaultSyntax] 
		escapeCharacter:character];
}

- (id)initWithString:(NSString*)replaceString
{
	return [self initWithString:replaceString 
		syntax:[OGRegularExpression defaultSyntax] 
		escapeCharacter:[OGRegularExpression defaultEscapeCharacter]];
}



+ (id)replaceExpressionWithString:(NSString*)replaceString 
	syntax:(OgreSyntax)syntax 
	escapeCharacter:(NSString*)character
{
	return [[[[self class] alloc] initWithString:replaceString 
		syntax:syntax 
		escapeCharacter:character] autorelease];
}

+ (id)replaceExpressionWithString:(NSString*)replaceString 
	escapeCharacter:(NSString*)character
{
	return [[[[self class] alloc] initWithString:replaceString 
		syntax:[OGRegularExpression defaultSyntax] 
		escapeCharacter:character] autorelease];
}

+ (id)replaceExpressionWithString:(NSString*)replaceString;
{
	return [[[[self class] alloc] initWithString:replaceString 
		syntax:[OGRegularExpression defaultSyntax] 
		escapeCharacter:[OGRegularExpression defaultEscapeCharacter]] autorelease];
}


- (void)dealloc
{
#ifdef DEBUG_OGRE
	NSLog(@"-dealloc of %@", [self className]);
#endif
	[_compiledReplaceStringType release];
	[_compiledReplaceString release];
	[_nameArray release];
	
	[super dealloc];
}

// 置換
- (NSString*)replaceMatchedStringOf:(OGRegularExpressionMatch*)match 
{
	if (match == nil) {
		[NSException raise:OgreException format: @"nil string (or other) argument"];
	}
	
	NSMutableString	*resultString;
	resultString = [[[NSMutableString alloc] init] autorelease];	// 置換結果
	
	NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
	
	// マッチした文字列をcompileされた置換文字列に従って置換する
	NSEnumerator	*strEnumerator = [_compiledReplaceString objectEnumerator];
	NSEnumerator	*typeEnumerator = [_compiledReplaceStringType objectEnumerator];
	NSString		*string;
	NSString		*substr;
	NSNumber		*type;
	
	NSString	*name;
	unsigned	numOfNames = 0;
	int			specialKey;
	
	while ( (string = [strEnumerator nextObject]) != nil && (type = [typeEnumerator nextObject]) != nil ) {
		specialKey = [type intValue];
		switch (specialKey) {
			case OgreNonEscapedNormalCharacters:	// [^\]+
				[resultString appendString:string];
				break;
			case OgreEscapePlus:			// \+
				// 最後にマッチした部分文字
				substr = [match lastMatchSubstring];
				if (substr != nil) {
					[resultString appendString:substr];
				}
				break;
			case OgreEscapeBackquote:	// \`
				// マッチした部分よりも前の文字
				substr = [match prematchString];
				[resultString appendString:substr];
				break;
			case OgreEscapeQuote:		// \'
				// マッチした部分よりも後ろの文字
				substr = [match postmatchString];
				[resultString appendString:substr];
				break;
			case OgreEscapeMinus:		// \-
				// マッチした部分と一つ前にマッチした部分の間の文字
				substr = [match stringBetweenMatchAndLastMatch];
				[resultString appendString:substr];
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
				substr = [match substringAtIndex:specialKey];
				if (substr != nil) {
					[resultString appendString:substr];
				}
				break;
		}
	}
	
	[pool release];
	
	return resultString;
}

// NSCoding protocols
- (void)encodeWithCoder:(NSCoder*)encoder
{
#ifdef DEBUG_OGRE
	NSLog(@"-encodeWithCoder: of %@", [self className]);
#endif
	if ([encoder allowsKeyedCoding]) {
		[encoder encodeObject: _compiledReplaceString forKey: OgreCompiledReplaceStringKey];
		[encoder encodeObject: _compiledReplaceStringType forKey: OgreCompiledReplaceStringTypeKey];
		[encoder encodeObject: _nameArray forKey: OgreNameArrayKey];
	} else {
		[encoder encodeObject: _compiledReplaceString];
		[encoder encodeObject: _compiledReplaceStringType];
		[encoder encodeObject: _nameArray];
	}
}

- (id)initWithCoder:(NSCoder*)decoder
{
#ifdef DEBUG_OGRE
	NSLog(@"-initWithCoder: of %@", [self className]);
#endif
	self = [super init];
	if (self == nil) return nil;
	
	BOOL			allowsKeyedCoding = [decoder allowsKeyedCoding];
	
    if (allowsKeyedCoding) {
		_compiledReplaceString = [[decoder decodeObjectForKey:OgreCompiledReplaceStringKey] retain];
	} else {
		_compiledReplaceString = [[decoder decodeObject] retain];
	}
	if (_compiledReplaceString == nil) {
		// エラー。例外を発生させる。
		[self release];
		[NSException raise:OgreReplaceException format:@"fail to decode"];
	}
	
    if (allowsKeyedCoding) {
		_compiledReplaceStringType = [[decoder decodeObjectForKey:OgreCompiledReplaceStringTypeKey] retain];
	} else {
		_compiledReplaceStringType = [[decoder decodeObject] retain];
	}
	if (_compiledReplaceStringType == nil) {
		// エラー。例外を発生させる。
		[self release];
		[NSException raise:OgreReplaceException format:@"fail to decode"];
	}
	
    if (allowsKeyedCoding) {
		_nameArray = [[decoder decodeObjectForKey:OgreNameArrayKey] retain];
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
	NSLog(@"-copyWithZone: of %@", [self className]);
#endif
	id	newObject = [[[self class] allocWithZone:zone] init];
	if (newObject != nil) {
		[newObject _setCompiledReplaceString:_compiledReplaceString];
		[newObject _setCompiledReplaceStringType:_compiledReplaceStringType];
		[newObject _setNameArray:_nameArray];
	}
	
	return newObject;
}

// description
- (NSString*)description
{
	return [[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:
			_compiledReplaceString, 
			_compiledReplaceStringType, 
			_nameArray, 
			nil] 
		forKeys:[NSArray arrayWithObjects:
			@"Compiled Replace String", 
			@"Compiled Replace String Type", 
			@"Names",
			nil]] description];
}

@end
