/*
 * Name: OGRegularExpressionEnumerator.m
 * Project: OgreKit
 *
 * Creation Date: Sep 03 2003
 * Author: Isao Sonobe <sonobe@gauge.scphys.kyoto-u.ac.jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <OgreKit/OGRegularExpression.h>
#import <OgreKit/OGRegularExpressionMatch.h>
#import <OgreKit/OGRegularExpressionEnumerator.h>
#import <OgreKit/OGRegularExpressionPrivate.h>
#import <OgreKit/OGRegularExpressionMatchPrivate.h>
#import <OgreKit/OGRegularExpressionEnumeratorPrivate.h>


// 自身をencoding/decodingするためのkey
static NSString	* const OgreRegexKey               = @"OgreEnumeratorRegularExpression";
static NSString	* const OgreSwappedTargetStringKey = @"OgreEnumeratorSwappedTargetString";
static NSString	* const OgreStartOffsetKey         = @"OgreEnumeratorStartOffset";
static NSString	* const OgreStartLocationKey       = @"OgreEnumeratorStartLocation";
static NSString	* const OgreTerminalOfLastMatchKey = @"OgreEnumeratorTerminalOfLastMatch";
static NSString	* const OgreIsLastMatchEmptyKey    = @"OgreEnumeratorIsLastMatchEmpty";
static NSString	* const OgreOptionsKey             = @"OgreEnumeratorOptions";
static NSString	* const OgreNumberOfMatchesKey     = @"OgreEnumeratorNumberOfMatches";

NSString	* const OgreEnumeratorException = @"OGRegularExpressionEnumeratorException";

@implementation OGRegularExpressionEnumerator

// 次を検索
- (id)nextObject
{
	int					r;
	unsigned char		*start, *range, *end;
	OnigRegion			*region;
	id					match = nil;
	unsigned			utf8charlen = 0;
	
	/* 全面的に書き直す予定 */
	if ( _utf8TerminalOfLastMatch == -1 ) {
		// マッチ終了
		return nil;
	}
	
	start = _utf8SwappedTargetString + _utf8StartLocation;	// search start address of target string
	end = _utf8SwappedTargetString + _utf8lengthOfSwappedTargetString;	// terminate address of target string
	range = end;	// search terminate address of target string
	if (start > range) {
		// これ以上検索範囲のない場合
		_utf8TerminalOfLastMatch = -1;
		return nil;
	}
	
	// compileオプション(OgreFindNotEmptyOptionを別に扱う)
	BOOL	findNotEmpty;
	if (([_regex options] & OgreFindNotEmptyOption) == 0) {
		findNotEmpty = NO;
	} else {
		findNotEmpty = YES;
	}
	
	// searchオプション(OgreFindEmptyOptionを別に扱う)
	BOOL		findEmpty;
	unsigned	searchOptions;
	if ((_searchOptions & OgreFindEmptyOption) == 0) {
		findEmpty = NO;
		searchOptions = _searchOptions;
	} else {
		findEmpty = YES;
		searchOptions = _searchOptions & ~OgreFindEmptyOption;  // turn off OgreFindEmptyOption
	}
	
	// regionの作成
	region = onig_region_new();
	if ( region == NULL ) {
		// メモリを確保できなかった場合、例外を発生させる。
		[NSException raise:OgreEnumeratorException format:@"fail to create a region"];
	}
	
	/* 検索 */
	regex_t*	regexBuffer = [_regex patternBuffer];
	
	int	counterOfAutorelease = 0;
	NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
	
	if (!findNotEmpty) {
		/* 空文字列へのマッチを許す場合 */
		r = onig_search(regexBuffer, _utf8SwappedTargetString, end, start, range, region, searchOptions);
		
		// OgreFindEmptyOptionが指定されていない場合で、
		// 前回空文字列以外にマッチして、今回空文字列にマッチした場合、1文字ずらしてもう1度マッチを試みる。
		if (!findEmpty && (!_isLastMatchEmpty) && (r >= 0) && (region->beg[0] == region->end[0]) && (_startLocation > 0)) {
			if (start < range) {
				utf8charlen = Ogre_utf8charlen(_utf8SwappedTargetString + _utf8StartLocation);
				_utf8StartLocation += utf8charlen;	// UTF8Stringで1文字進める
				start = _utf8SwappedTargetString + _utf8StartLocation;
				_startLocation += ((utf8charlen >= 4)? 2 : 1);	// NSStringで1文字進める (4-octet以上の場合はなぜか2文字(2文字目は空文字)進めなければならない)
				r = onig_search(regexBuffer, _utf8SwappedTargetString, end, start, range, region, searchOptions);
			} else {
				r = ONIG_MISMATCH;
			}
		}
		
	} else {
		/* 空文字列へのマッチを許さない場合 */
		while (TRUE) {
			r = onig_search(regexBuffer, _utf8SwappedTargetString, end, start, range, region, searchOptions);
			if ((r >= 0) && (region->beg[0] == region->end[0]) && (start < range)) {
				// 空文字列にマッチした場合
				utf8charlen = Ogre_utf8charlen(_utf8SwappedTargetString + _utf8StartLocation);
				_utf8StartLocation += utf8charlen;	// UTF8Stringで1文字進める
				start = _utf8SwappedTargetString + _utf8StartLocation;
				_startLocation += ((utf8charlen >= 4)? 2 : 1);	// NSStringで1文字進める (4-octetの場合はなぜか2文字(2文字目は空文字)進めなければならない)
			} else {
				// これ以上進めない場合・空文字列以外にマッチした場合・マッチに失敗した場合
				break;
			}
		
			counterOfAutorelease++;
			if (counterOfAutorelease % 100 == 0) {
				[pool release];
				pool = [[NSAutoreleasePool alloc] init];
			}
		}
		if ((r >= 0) && (region->beg[0] == region->end[0]) && (start >= range)) {
			// 最後に空文字列にマッチした場合。ミスマッチ扱いとする。
			r = ONIG_MISMATCH;
		}
	}
	
	[pool release];
	
	if (r >= 0) {
		// マッチした場合
		// matchオブジェクトの作成
		match = [[[OGRegularExpressionMatch allocWithZone:[self zone]] 
				initWithRegion: region 
				index: _numberOfMatches
				enumerator: self
				locationCache: _startLocation
				utf8LocationCache: _utf8StartLocation
				utf8TerminalOfLastMatch: _utf8TerminalOfLastMatch
				parentMatch:nil 
			] autorelease];
		
		_numberOfMatches++;	// マッチ数を増加
		
		/* マッチした文字列の終端位置 */
		if ( (r == _utf8lengthOfSwappedTargetString) && (r == region->end[0]) ) {
			_utf8TerminalOfLastMatch = -1;	// 最後に空文字列にマッチした場合は、これ以上マッチしない。
			_isLastMatchEmpty = YES;	// いらないだろうけど一応。

			return match;
		} else {
			_utf8TerminalOfLastMatch = region->end[0];	// 最後にマッチした文字列の終端位置
		}

		/* NSString と UTF8String での次回のマッチ開始位置を求める */
		_startLocation += Ogre_utf8strlen(_utf8SwappedTargetString + _utf8StartLocation, _utf8SwappedTargetString + _utf8TerminalOfLastMatch);
		
		/* UTF8Stringでの開始位置 */
		if (r == region->end[0]) {
			// 空文字列にマッチした場合、次回のマッチ開始位置を1文字先に進める。
			_isLastMatchEmpty = YES;
			utf8charlen = Ogre_utf8charlen(_utf8SwappedTargetString + _utf8TerminalOfLastMatch);
			_utf8StartLocation = _utf8TerminalOfLastMatch + utf8charlen;
			_startLocation += ((utf8charlen >= 4)? 2 : 1);  // NSStringで1文字進める (4-octetの場合はなぜか2文字(2文字目は空文字)進めなければならない)
		} else {
			// 空でなかった場合は進めない。
			_isLastMatchEmpty = NO;
			_utf8StartLocation = _utf8TerminalOfLastMatch;
		}
		
		return match;
	}
	
	onig_region_free(region, 1 /* free self */);	// マッチしなかった文字列のregionを開放。
	
	if (r == ONIG_MISMATCH) {
		// マッチしなかった場合
		_utf8TerminalOfLastMatch = -1;
	} else {
		// エラー。例外を発生させる。
		char s[ONIG_MAX_ERROR_MESSAGE_LEN];
		onig_error_code_to_str(s, r);
		[NSException raise:OgreEnumeratorException format:@"%s", s];
	}
	return nil;	// マッチしなかった場合
}

- (NSArray*)allObjects
{	
#ifdef DEBUG_OGRE
	NSLog(@"-allObjects of OGRegularExpressionEnumerator");
#endif

	NSMutableArray	*matchArray = [NSMutableArray arrayWithCapacity:10];

	int			orgUtf8TerminalOfLastMatch = _utf8TerminalOfLastMatch;
	BOOL		orgIsLastMatchEmpty = _isLastMatchEmpty;
	unsigned	orgStartLocation = _startLocation;
	unsigned	orgUtf8StartLocation = _utf8StartLocation;
	unsigned	orgNumberOfMatches = _numberOfMatches;
	
	_utf8TerminalOfLastMatch = 0;
	_isLastMatchEmpty = NO;
	_startLocation = 0;
	_utf8StartLocation = 0;
	_numberOfMatches = 0;
			
	NSAutoreleasePool   *pool = [[NSAutoreleasePool alloc] init];
	OGRegularExpressionMatch	*match;
	int matches = 0;
	while ( (match = [self nextObject]) != nil ) {
		[matchArray addObject:match];
		matches++;
		if ((matches % 100) == 0) {
			[pool release];
			pool = [[NSAutoreleasePool alloc] init];
		}
	}
	[pool release];
	
	_utf8TerminalOfLastMatch = orgUtf8TerminalOfLastMatch;
	_isLastMatchEmpty = orgIsLastMatchEmpty;
	_startLocation = orgStartLocation;
	_utf8StartLocation = orgUtf8StartLocation;
	_numberOfMatches = orgNumberOfMatches;

	if (matches == 0) {
		// not found
		return nil;
	} else {
		// found something
		return matchArray;
	}
}

// NSCoding protocols
- (void)encodeWithCoder:(NSCoder*)encoder
{
#ifdef DEBUG_OGRE
	NSLog(@"-encodeWithCoder: of OGRegularExpressionEnumerator");
#endif
	//[super encodeWithCoder:encoder]; NSObject does ont respond to method encodeWithCoder:
	
	//OGRegularExpression	*_regex;							// 正規表現オブジェクト
	//NSString				*_swappedTargetString;				// 検索対象文字列。\が入れ替わっている(事がある)ので注意
	//(unsigned char		*_utf8SwappedTargetString;)			// UTF8での検索対象文字列
	//(			_utf8lengthOfSwappedTargetString;)	// strlen([_swappedTargetString UTF8String])
	//NSRange				_searchRange;						// 検索範囲
	//			_searchOptions;						// 検索オプション
	//int					_utf8TerminalOfLastMatch;			// 前回にマッチした文字列の終端位置 (_region->end[0])
	//			_startLocation;						// マッチ開始位置
	//(			_utf8StartLocation;)				// UTF8でのマッチ開始位置
	//BOOL					_isLastMatchEmpty;					// 前回のマッチが空文字列だったかどうか

    if ([encoder allowsKeyedCoding]) {
		[encoder encodeObject: _regex forKey: OgreRegexKey];
		[encoder encodeObject: _swappedTargetString forKey: OgreSwappedTargetStringKey];	// [self targetString]ではない。
		[encoder encodeObject: [NSNumber numberWithUnsignedInt:_searchRange.location] forKey: OgreStartOffsetKey];
		[encoder encodeObject: [NSNumber numberWithUnsignedInt:_searchOptions] forKey: OgreOptionsKey];
		[encoder encodeObject: [NSNumber numberWithInt:_utf8TerminalOfLastMatch] forKey: OgreTerminalOfLastMatchKey];
		[encoder encodeObject: [NSNumber numberWithUnsignedInt:_startLocation] forKey: OgreStartLocationKey];
		[encoder encodeObject: [NSNumber numberWithBool:_isLastMatchEmpty] forKey: OgreIsLastMatchEmptyKey];
		[encoder encodeObject: [NSNumber numberWithUnsignedInt:_numberOfMatches] forKey: OgreNumberOfMatchesKey];
	} else {
		[encoder encodeObject: _regex];
		[encoder encodeObject: _swappedTargetString];	// [self targetString]ではない。
		[encoder encodeObject: [NSNumber numberWithUnsignedInt:_searchRange.location]];
		[encoder encodeObject: [NSNumber numberWithUnsignedInt:_searchOptions]];
		[encoder encodeObject: [NSNumber numberWithInt:_utf8TerminalOfLastMatch]];
		[encoder encodeObject: [NSNumber numberWithUnsignedInt:_startLocation]];
		[encoder encodeObject: [NSNumber numberWithBool:_isLastMatchEmpty]];
		[encoder encodeObject: [NSNumber numberWithUnsignedInt:_numberOfMatches]];
	}
}

- (id)initWithCoder:(NSCoder*)decoder
{
#ifdef DEBUG_OGRE
	NSLog(@"-initWithCoder: of OGRegularExpressionEnumerator");
#endif
	self = [super init];	// NSObject does ont respond to method initWithCoder:
	if (self == nil) return nil;
	
	id		anObject;	
	BOOL	allowsKeyedCoding = [decoder allowsKeyedCoding];


	//OGRegularExpression	*_regex;							// 正規表現オブジェクト
    if (allowsKeyedCoding) {
		_regex = [[decoder decodeObjectForKey: OgreRegexKey] retain];
	} else {
		_regex = [[decoder decodeObject] retain];
	}
	if (_regex == nil) {
		// エラー。例外を発生させる。
		[self release];
		[NSException raise:OgreEnumeratorException format:@"fail to decode"];
	}
	
	
	//NSString			*_swappedTargetString;				// 検索対象文字列。\が入れ替わっている(事がある)ので注意
	//unsigned char		*_utf8SwappedTargetString;			// UTF8での検索対象文字列
	//		_utf8lengthOfSwappedTargetString;	// strlen([_swappedTargetString UTF8String])
    if (allowsKeyedCoding) {
		_swappedTargetString = [[decoder decodeObjectForKey: OgreSwappedTargetStringKey] retain];	// [self targetString]ではない。
	} else {
		_swappedTargetString = [[decoder decodeObject] retain];
	}
	if (_swappedTargetString == nil) {
		// エラー。例外を発生させる。
		[self release];
		[NSException raise:OgreEnumeratorException format:@"fail to decode"];
	}
	_utf8SwappedTargetString = (unsigned char*)[_swappedTargetString UTF8String];
	_utf8lengthOfSwappedTargetString = strlen(_utf8SwappedTargetString);
	
	
	// NSRange				_searchRange;						// 検索範囲
    if (allowsKeyedCoding) {
		anObject = [decoder decodeObjectForKey: OgreStartOffsetKey];
	} else {
		anObject = [decoder decodeObject];
	}
	if (anObject == nil) {
		// エラー。例外を発生させる。
		[self release];
		[NSException raise:OgreEnumeratorException format:@"fail to decode"];
	}
	_searchRange.location = [anObject unsignedIntValue];
	_searchRange.length = [_swappedTargetString length];
	
	
	
	// 	_searchOptions;			// 検索オプション
    if (allowsKeyedCoding) {
		anObject = [decoder decodeObjectForKey: OgreOptionsKey];
	} else {
		anObject = [decoder decodeObject];
	}
	if (anObject == nil) {
		// エラー。例外を発生させる。
		[self release];
		[NSException raise:OgreEnumeratorException format:@"fail to decode"];
	}
	_searchOptions = [anObject unsignedIntValue];
	
	
	// int	_utf8TerminalOfLastMatch;	// 前回にマッチした文字列の終端位置 (_region->end[0])
    if (allowsKeyedCoding) {
		anObject = [decoder decodeObjectForKey: OgreTerminalOfLastMatchKey];
	} else {
		anObject = [decoder decodeObject];
	}
	if (anObject == nil) {
		// エラー。例外を発生させる。
		[self release];
		[NSException raise:OgreEnumeratorException format:@"fail to decode"];
	}
	_utf8TerminalOfLastMatch = [anObject intValue];
	
	
	//			_startLocation;						// マッチ開始位置
	//			_utf8StartLocation;					// UTF8でのマッチ開始位置
    if (allowsKeyedCoding) {
		anObject = [decoder decodeObjectForKey: OgreStartLocationKey];
	} else {
		anObject = [decoder decodeObject];
	}
	if (anObject == nil) {
		// エラー。例外を発生させる。
		[self release];
		[NSException raise:OgreEnumeratorException format:@"fail to decode"];
	}
	_startLocation = [anObject unsignedIntValue];
	_utf8StartLocation = strlen([[_swappedTargetString substringWithRange:NSMakeRange(0, _startLocation)] UTF8String]);
	

	//BOOL				_isLastMatchEmpty;					// 前回のマッチが空文字列だったかどうか
    if (allowsKeyedCoding) {
		anObject = [decoder decodeObjectForKey: OgreIsLastMatchEmptyKey];
	} else {
		anObject = [decoder decodeObject];
	}
	if (anObject == nil) {
		// エラー。例外を発生させる。
		[self release];
		[NSException raise:OgreEnumeratorException format:@"fail to decode"];
	}
	_isLastMatchEmpty = [anObject boolValue];
	
	
	//	unsigned			_numberOfMatches;					// マッチした数
    if (allowsKeyedCoding) {
		anObject = [decoder decodeObjectForKey: OgreNumberOfMatchesKey];
	} else {
		anObject = [decoder decodeObject];
	}
	if (anObject == nil) {
		// エラー。例外を発生させる。
		[self release];
		[NSException raise:OgreEnumeratorException format:@"fail to decode"];
	}
	_numberOfMatches = [anObject unsignedIntValue];
	
	
	return self;
}


// NSCopying protocol
- (id)copyWithZone:(NSZone*)zone
{
#ifdef DEBUG_OGRE
	NSLog(@"-copyWithZone: of OGRegularExpressionEnumerator");
#endif
	id	newObject = [[[self class] allocWithZone:zone] 
			initWithSwappedString: _swappedTargetString 
			options: _searchOptions
			range: _searchRange 
			regularExpression: _regex];
			
	// 値のセット
	[newObject _setUtf8TerminalOfLastMatch: _utf8TerminalOfLastMatch];
	[newObject _setIsLastMatchEmpty: _isLastMatchEmpty];
	[newObject _setStartLocation: _startLocation];
	[newObject _setUtf8StartLocation: _utf8StartLocation];
	[newObject _setNumberOfMatches: _numberOfMatches];

	return newObject;
}

// description
- (NSString*)description
{
	NSDictionary	*dictionary = [NSDictionary 
		dictionaryWithObjects: [NSArray arrayWithObjects: 
			_regex, 	// 正規表現オブジェクト
			[[_regex class] swapBackslashInString:_swappedTargetString forCharacter:[_regex escapeCharacter]],
			[NSString stringWithFormat:@"(%d, %d)", _searchRange.location, _searchRange.length], 	// 検索範囲
			[[_regex class] stringsForOptions:_searchOptions], 	// 検索オプション
			[NSNumber numberWithInt:Ogre_utf8strlen(_utf8SwappedTargetString, _utf8SwappedTargetString + _utf8TerminalOfLastMatch)],	// 前回にマッチした文字列の終端位置より前の文字列の長さ
			[NSNumber numberWithUnsignedInt:_startLocation], 	// マッチ開始位置
			(_isLastMatchEmpty? @"YES" : @"NO"), 	// 前回のマッチが空文字列だったかどうか
			[NSNumber numberWithUnsignedInt:_numberOfMatches], 
			nil]
		forKeys:[NSArray arrayWithObjects: 
			@"Regular Expression", 
				@"Target String", 
			@"Search Range", 
			@"Options", 
			@"Terminal of the Last Match", 
			@"Location of the Next Search Start", 
			@"Was the Last Match Empty", 
			@"Number Of Matches", 
			nil]
		];
		
	return [dictionary description];
}

@end
