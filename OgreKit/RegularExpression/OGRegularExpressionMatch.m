/*
 * Name: OGRegularExpressionMatch.m
 * Project: OgreKit
 *
 * Creation Date: Aug 30 2003
 * Author: Isao Sonobe <sonobe@gauge.scphys.kyoto-u.ac.jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#ifndef NOT_RUBY
#	define NOT_RUBY
#endif
#ifndef HAVE_CONFIG_H
#	define HAVE_CONFIG_H
#endif
#import <OgreKit/oniguruma.h>

#import <OgreKit/OGRegularExpression.h>
#import <OgreKit/OGRegularExpressionPrivate.h>
#import <OgreKit/OGRegularExpressionMatch.h>
#import <OgreKit/OGRegularExpressionMatchPrivate.h>
#import <OgreKit/OGRegularExpressionEnumerator.h>
#import <OgreKit/OGRegularExpressionEnumeratorPrivate.h>


NSString	* const OgreMatchException = @"OGRegularExpressionMatchException";

// 自身をencoding/decodingするためのkey
static NSString	* const OgreRegionKey              = @"OgreMatchRegion";
static NSString	* const OgreEnumeratorKey          = @"OgreMatchEnumerator";
static NSString	* const OgreLocationCacheKey       = @"OgreMatchLocationCache";
static NSString	* const OgreUtf8LocationCacheKey   = @"OgreMatchUtf8LocationCache";
static NSString	* const OgreTerminalOfLastMatchKey = @"OgreMatchTerminalOfLastMatch";
static NSString	* const OgreIndexOfMatchKey        = @"OgreMatchIndexOfMatch";


inline unsigned Ogre_utf8strlen(unsigned char *const utf8string, unsigned char *const end)
{
	unsigned		length = 0;
	unsigned char	*utf8str = utf8string;
	unsigned char	byte;
	while ( ((byte = *utf8str) != 0) && (utf8str < end) ) {
		if ((byte & 0x80) == 0x00) {
			// 1 byte
			utf8str++;
			length++;
		} else if ((byte & 0xe0) == 0xc0) {
			// 2 bytes
			utf8str += 2;
			length++;
		} else if ((byte & 0xf0) == 0xe0) {
			// 3 bytes
			utf8str += 3;
			length++;
		} else if ((byte & 0xf8) == 0xf0) {
			// 4 bytes
			utf8str += 4;
			length += 2;	// 注意! Cocoaではなんでこんな仕様なんだろう?
		} else if ((byte & 0xfc) == 0xf8) {
			// 5 bytes
			utf8str += 5;
			length += 2;	// 注意! Cocoaではなんでこんな仕様なんだろう?
		} else if ((byte & 0xfe) == 0xfc) {
			// 6 bytes
			utf8str += 6;
			length += 2;	// 注意! Cocoaではなんでこんな仕様なんだろう?
		} else {
			// subsequent byte in a multibyte code
			// 出会わないはずなので、出会ったら例外を起こす。
			[NSException raise:OgreMatchException format:@"illegal byte code"];
		}
	}
	
	return length;
}

static NSArray *Ogre_arrayWithOnigRegion(OnigRegion *region)
{
	if (region == NULL) return nil;
	
	NSMutableArray	*regionArray = [NSMutableArray arrayWithCapacity:0];
	unsigned	i = 0, n = region->num_regs;
	OnigRegion  *cap;
	
	for( i = 0; i < n; i++ ) {
		if (ONIG_IS_CAPTURE_HISTORY_GROUP(region, i)) {
			cap = region->list[i];
		} else {
			cap = NULL;
		}
		
		[regionArray addObject: [NSArray arrayWithObjects:
			[NSNumber numberWithInt:region->beg[i]], 
			[NSNumber numberWithInt:region->end[i]], 
			Ogre_arrayWithOnigRegion(cap), 
			nil]];
	}
	
	return regionArray;
}

static OnigRegion *Ogre_onigRegionWithArray(NSArray *array)
{
	if (array == nil) return NULL;
	
	NSEnumerator	*enumerator = [array objectEnumerator];
	OnigRegion		*region = onig_region_new();
	if (region == NULL) {
		// メモリを確保できなかった場合、例外を発生させる。
		[NSException raise:OgreMatchException format:@"fail to memory allocation"];
	}
	unsigned		i = 0, j;
	NSArray			*anObject;
	BOOL			hasList = NO;
	int				r;
	
	r = onig_region_resize(region, [array count]);
	if (r != ONIG_NORMAL) {
		// メモリを確保できなかった場合、例外を発生させる。
		onig_region_free(region, 1);
		[NSException raise:OgreMatchException format:@"fail to memory allocation"];
	}
	region->list = NULL;
	while ( (anObject = [enumerator nextObject]) != nil ) {
		region->beg[i] = [[anObject objectAtIndex:0] unsignedIntValue];
		region->end[i] = [[anObject objectAtIndex:1] unsignedIntValue];
		if ([anObject count] > 2) {
			if (!hasList) {
				OnigRegion  **list = (OnigRegion**)malloc(sizeof(OnigRegion*) * (ONIG_MAX_CAPTURE_HISTORY_GROUP + 1));
				if (list == NULL) {
					// メモリを確保できなかった場合、例外を発生させる。
					onig_region_free(region, 1);
					[NSException raise:OgreMatchException format:@"fail to memory allocation"];
				}
				region->list = list;
				for (j = 0; j <= ONIG_MAX_CAPTURE_HISTORY_GROUP; j++) region->list[j] = (OnigRegion*)NULL;
				hasList = YES;
			}
			region->list[i] = Ogre_onigRegionWithArray((NSArray*)[anObject objectAtIndex:2]);
		}
		i++;
	}
	
	return region;
}

@implementation OGRegularExpressionMatch

// マッチした順番
- (unsigned)index
{
	return _index;
}

// 部分文字列の数 + 1
- (unsigned)count
{
	return _region->num_regs;
}

// マッチした文字列の範囲
- (NSRange)rangeOfMatchedString
{
	return [self rangeOfSubstringAtIndex:0];
}

// マッチした文字列 \&, \0
- (NSString*)matchedString
{
	return [self substringAtIndex:0];
}

// index番目のsubstringの範囲
- (NSRange)rangeOfSubstringAtIndex:(unsigned)index
{
	int	location, length;
	
	if ( (index >= _region->num_regs) || (_region->beg[index] == -1) ) {
		// index番目のsubstringが存在しない場合
		return NSMakeRange(-1, 0);
	}
	//NSLog(@"%d %d-%d", index, _region->beg[index], _region->end[index]);
	
	/* substringよりも前の文字列の長さを得る。 */
	location = _searchRange.location + _locationCache + Ogre_utf8strlen(_utf8SwappedTargetString + _utf8LocationCache, _utf8SwappedTargetString + _region->beg[index]);
	
	/* substringの長さを得る。 */
	length = Ogre_utf8strlen(_utf8SwappedTargetString + _region->beg[index], _utf8SwappedTargetString + _region->end[index]);
	
	return NSMakeRange(location, length);
}

// index番目のsubstring \n
- (NSString*)substringAtIndex:(unsigned)index
{
	// index番目のsubstringが存在しない時には nil を返す
	if ( (index >= _region->num_regs) || (_region->beg[index] == -1) ){
		return nil;
	}
	if (_region->end[index] == _region->beg[index]) {
		// substringが空の場合
		return @"";
	}
	
	/* substring */
	unsigned char* utf8Substr;
	utf8Substr = malloc((_region->end[index] - _region->beg[index] + 1) * sizeof(unsigned char));
	if ( utf8Substr == NULL ) {
		// メモリを確保できなかった場合、例外を発生させる。
		[NSException raise:OgreMatchException format:@"fail to memory allocation"];
	}
	// コピー
	memcpy( utf8Substr, _utf8SwappedTargetString + _region->beg[index], _region->end[index] - _region->beg[index]);
	*(utf8Substr + (_region->end[index] - _region->beg[index])) = 0;
	NSString *substr = [NSString stringWithUTF8String:utf8Substr];
	// 開放
	free(utf8Substr);
	
	// \を入れ替える
	return [OGRegularExpression swapBackslashInString:substr forCharacter:_escapeCharacter];
}

// マッチの対象になった文字列
- (NSString*)targetString
{
	// \を入れ替える
	return [OGRegularExpression swapBackslashInString:_swappedTargetString forCharacter:_escapeCharacter];
}

// マッチした部分より前の文字列 \`
- (NSString*)prematchString
{
	if (_region->beg[0] == -1) {
		// マッチした文字列が存在しない場合
		return nil;
	}
	if (_region->beg[0] == _region->end[0]) {
		// マッチした部分より前の文字列が空の場合
		return @"";
	}
	
	/* マッチした部分より前の文字列 */
	unsigned char* utf8Substr = malloc((_region->beg[0] + 1) * sizeof(unsigned char));
	if ( utf8Substr == NULL ) {
		// メモリを確保できなかった場合、例外を発生させる。
		[NSException raise:OgreMatchException format:@"fail to memory allocation"];
	}
	// コピー
	memcpy( utf8Substr, _utf8SwappedTargetString, _region->beg[0] );
	*(utf8Substr + _region->beg[0]) = 0;
	NSString *substr = [NSString stringWithUTF8String: utf8Substr];
	// 開放
	free(utf8Substr);
	
	// \を入れ替える
	return [OGRegularExpression swapBackslashInString:substr forCharacter:_escapeCharacter];
}

// マッチした部分より前の文字列 \` の範囲
- (NSRange)rangeOfPrematchString
{
	if (_region->beg[0] == -1) {
		// マッチした文字列が存在しない場合
		return NSMakeRange(-1,0);
	}

	/* マッチした部分より前の文字列 */
	unsigned length = _locationCache + Ogre_utf8strlen(_utf8SwappedTargetString + _utf8LocationCache, _utf8SwappedTargetString + _region->beg[0]);

	return NSMakeRange(_searchRange.location, length);
}

// マッチした部分より後ろの文字列 \'
- (NSString*)postmatchString
{
	if (_region->beg[0] == -1) {
		// マッチした部分より後ろの文字列が存在しない場合
		return nil;
	}

	unsigned	utf8strlen = strlen(_utf8SwappedTargetString);
	if (_region->end[0] == utf8strlen) {
		// マッチした部分より後ろの文字列が空の場合
		return @"";
	}
	
	/* マッチした部分より後ろの文字列 */
	unsigned char* utf8Substr = malloc((utf8strlen - _region->end[0] + 1) * sizeof(unsigned char));
	if ( utf8Substr == NULL ) {
		// メモリを確保できなかった場合、例外を発生させる。
		[NSException raise:OgreMatchException format:@"fail to memory allocation"];
	}
	// コピー
	memcpy( utf8Substr, _utf8SwappedTargetString + _region->end[0], utf8strlen - _region->end[0]);
	*(utf8Substr + (utf8strlen - _region->end[0])) = 0;
	NSString *substr = [NSString stringWithUTF8String:utf8Substr];
	// 開放
	free(utf8Substr);
	
	// \を入れ替える
	return [OGRegularExpression swapBackslashInString:substr forCharacter:_escapeCharacter];
}

// マッチした部分より後ろの文字列 \' の範囲
- (NSRange)rangeOfPostmatchString
{
	if (_region->beg[0] == -1) {
		// マッチした部分より後ろの文字列が存在しない場合
		return NSMakeRange(-1, 0);
	}
	
	unsigned	utf8strlen = strlen(_utf8SwappedTargetString);
	unsigned	length = Ogre_utf8strlen(_utf8SwappedTargetString + _region->end[0], _utf8SwappedTargetString + utf8strlen);
	
	return NSMakeRange(_searchRange.location + _searchRange.length - length, length);
}

// マッチした文字列と一つ前にマッチした文字列の間の文字列 \-
- (NSString*)stringBetweenMatchAndLastMatch
{
	if (_region->beg[0] == -1) {
		// マッチした文字列が存在しない場合
		return nil;
	}
	if (_region->beg[0] == _utf8TerminalOfLastMatch) {
		// 間の文字列が空の場合
		return @"";
	}
	
	/* 間の文字列 */
	unsigned char* utf8Substr = malloc((_region->beg[0] - _utf8TerminalOfLastMatch + 1) * sizeof(unsigned char));
	if ( utf8Substr == NULL ) {
		// メモリを確保できなかった場合、例外を発生させる。
		[NSException raise:OgreMatchException format:@"fail to memory allocation"];
	}
	// コピー
	memcpy( utf8Substr, _utf8SwappedTargetString + _utf8TerminalOfLastMatch, _region->beg[0] - _utf8TerminalOfLastMatch);
	*(utf8Substr + (_region->beg[0] - _utf8TerminalOfLastMatch)) = 0;
	NSString *substr = [NSString stringWithUTF8String: utf8Substr];
	// 開放
	free(utf8Substr);
	
	// \を入れ替える
	return [OGRegularExpression swapBackslashInString:substr forCharacter:_escapeCharacter];
}

// マッチした文字列と一つ前にマッチした文字列の間の文字列 \- の範囲
- (NSRange)rangeOfStringBetweenMatchAndLastMatch
{
	if (_region->beg[0] == -1) {
		// マッチした文字列が存在しない場合
		return NSMakeRange(-1,0);
	}

	unsigned length = Ogre_utf8strlen(_utf8SwappedTargetString + _utf8TerminalOfLastMatch, _utf8SwappedTargetString + _region->beg[0]);
	
	NSRange		rangeOfPrematchString = [self rangeOfPrematchString];
	return NSMakeRange(rangeOfPrematchString.location + rangeOfPrematchString.length - length, length);
}

// 最後にマッチした部分文字列 \+
- (NSString*)lastMatchSubstring
{
	int i = [self count] - 1;
	while ( (i > 0) && (_region->beg[i] == -1) ) {
		i--;
	}
	if ( i == 0) {
		return nil;
	} else {
		return [self substringAtIndex:i];
	}
}

// 最後にマッチした部分文字列の範囲 \+
- (NSRange)rangeOfLastMatchSubstring
{
	int i = [self count] - 1;
	while ( (i > 0) && (_region->beg[i] == -1) ) {
		i--;
	}
	if ( i == 0) {
		return NSMakeRange(-1,0);
	} else {
		return [self rangeOfSubstringAtIndex:i];
	}
}


// NSCoding protocols
- (void)encodeWithCoder:(NSCoder*)encoder
{
#ifdef DEBUG_OGRE
	NSLog(@"-encodeWithCoder: of OGRegularExpressionMatch");
#endif
	//[super encodeWithCoder:encoder]; NSObject does ont respond to method encodeWithCoder:
	
   if ([encoder allowsKeyedCoding]) {
		[encoder encodeObject: Ogre_arrayWithOnigRegion(_region) forKey: OgreRegionKey];
		[encoder encodeObject: _enumerator forKey: OgreEnumeratorKey];
		[encoder encodeObject: [NSNumber numberWithUnsignedInt: _locationCache] forKey: OgreLocationCacheKey];
		[encoder encodeObject: [NSNumber numberWithUnsignedInt: _utf8LocationCache] forKey: OgreUtf8LocationCacheKey];
		[encoder encodeObject: [NSNumber numberWithUnsignedInt: _utf8TerminalOfLastMatch] forKey: OgreTerminalOfLastMatchKey];
		[encoder encodeObject: [NSNumber numberWithUnsignedInt: _index] forKey: OgreIndexOfMatchKey];
	} else {
		[encoder encodeObject: Ogre_arrayWithOnigRegion(_region)];
		[encoder encodeObject: _enumerator];
		[encoder encodeObject: [NSNumber numberWithUnsignedInt: _locationCache]];
		[encoder encodeObject: [NSNumber numberWithUnsignedInt: _utf8LocationCache]];
		[encoder encodeObject: [NSNumber numberWithUnsignedInt: _utf8TerminalOfLastMatch]];
		[encoder encodeObject: [NSNumber numberWithUnsignedInt: _index]];
	}
}

- (id)initWithCoder:(NSCoder*)decoder
{
#ifdef DEBUG_OGRE
	NSLog(@"-initWithCoder: of OGRegularExpressionMatch");
#endif
	self = [super init];	// NSObject does ont respond to method initWithCoder:
	if (self == nil) return nil;
	
	BOOL			allowsKeyedCoding = [decoder allowsKeyedCoding];
	
	// OnigRegion		*_region;				// match result region
	// /* match result region type */
	// struct re_registers {
	// int  allocated;
	// int  num_regs;
	// int* beg;
	// int* end;
	// /* extended */
	// struct re_registers** list; /* capture history. list[1]-list[31] */
	// };
	id  anObject;
	NSArray	*regionArray;
    if (allowsKeyedCoding) {
		regionArray = [decoder decodeObjectForKey: OgreRegionKey];
	} else {
		regionArray = [decoder decodeObject];
	}
	if (regionArray == nil) {
		// エラー。例外を発生させる。
		[self release];
		[NSException raise:OgreMatchException format:@"fail to decode"];
	}
	_region = Ogre_onigRegionWithArray(regionArray);	
	
	// OGRegularExpressionEnumerator*	_enumerator;	// 生成主
    if (allowsKeyedCoding) {
		_enumerator = [[decoder decodeObjectForKey: OgreEnumeratorKey] retain];
	} else {
		_enumerator = [[decoder decodeObject] retain];
	}
	if (_enumerator == nil) {
		// エラー。例外を発生させる。
		[self release];
		[NSException raise:OgreMatchException format:@"fail to decode"];
	}
	
	
	// unsigned		_locationCache;	// 既に分かっているNSStringの長さとUTF8Stringの長さの対応
    if (allowsKeyedCoding) {
		anObject = [decoder decodeObjectForKey: OgreLocationCacheKey];
	} else {
		anObject = [decoder decodeObject];
	}
	if (anObject == nil) {
		// エラー。例外を発生させる。
		[self release];
		[NSException raise:OgreMatchException format:@"fail to decode"];
	}
	_locationCache = [anObject unsignedIntValue];
	
	
	// unsigned		_utf8LocationCache;
    if (allowsKeyedCoding) {
		anObject = [decoder decodeObjectForKey: OgreUtf8LocationCacheKey];
	} else {
		anObject = [decoder decodeObject];
	}
	if (anObject == nil) {
		// エラー。例外を発生させる。
		[self release];
		[NSException raise:OgreMatchException format:@"fail to decode"];
	}
	_utf8LocationCache = [anObject unsignedIntValue];
	
	
	// unsigned	_utf8TerminalOfLastMatch;	// 前回にマッチした文字列の終端位置 (_region->end[0])
    if (allowsKeyedCoding) {
		anObject = [decoder decodeObjectForKey: OgreTerminalOfLastMatchKey];
	} else {
		anObject = [decoder decodeObject];
	}
	if (anObject == nil) {
		// エラー。例外を発生させる。
		[self release];
		[NSException raise:OgreMatchException format:@"fail to decode"];
	}
	_utf8TerminalOfLastMatch = [anObject unsignedIntValue];

	
	// 	unsigned		_index;		// マッチした順番
    if (allowsKeyedCoding) {
		anObject = [decoder decodeObjectForKey: OgreIndexOfMatchKey];
	} else {
		anObject = [decoder decodeObject];
	}
	if (anObject == nil) {
		// エラー。例外を発生させる。
		[self release];
		[NSException raise:OgreMatchException format:@"fail to decode"];
	}
	_index = [anObject unsignedIntValue];

	
	// 頻繁に利用するものはキャッシュする。保持はしない。
	// 検索対象文字列
	_swappedTargetString     = [_enumerator swappedTargetString];
	_utf8SwappedTargetString = [_enumerator utf8SwappedTargetString];
	// 検索範囲
	NSRange	searchRange = [_enumerator searchRange];
	_searchRange.location = searchRange.location;
	_searchRange.length   = searchRange.length;
	// 代替\文字を保持
	_escapeCharacter = [[_enumerator regularExpression] escapeCharacter];
	// 生成主
	_parentMatch = nil;
	
	
	return self;
}

// NSCopying protocol
- (id)copyWithZone:(NSZone*)zone
{
#ifdef DEBUG_OGRE
	NSLog(@"-copyWithZone: of OGRegularExpressionMatch");
#endif
	OnigRegion*	newRegion = onig_region_new();
	onig_region_copy(newRegion, _region);
	
	return [[[self class] allocWithZone:zone] 
		initWithRegion: newRegion 
		index: _index 
		enumerator: _enumerator
		locationCache: _locationCache 
		utf8LocationCache: _utf8LocationCache 
		utf8TerminalOfLastMatch: _utf8TerminalOfLastMatch
		parentMatch:nil];
}


// description
- (NSString*)description
{
	// OnigRegion		*_region;				// match result region
	// /* match result region type */
	// 		struct re_registers {
	// 		int  allocated;
	// 		int  num_regs;
	// 		int* beg;
	// 		int* end;
	// 		/* extended */
	// 		struct re_registers** list; /* capture history. list[1]-list[31] */
	// };
	
	NSRange	aRange = [self rangeOfStringBetweenMatchAndLastMatch];
	
	NSDictionary	*dictionary = [NSDictionary 
		dictionaryWithObjects: [NSArray arrayWithObjects: 
			Ogre_arrayWithOnigRegion(_region), 
			_enumerator, 
			[NSNumber numberWithUnsignedInt: _locationCache], 
			[NSNumber numberWithUnsignedInt: _utf8LocationCache], 
			[NSNumber numberWithUnsignedInt: aRange.location], 
			[NSNumber numberWithUnsignedInt: _index], 
			nil]
		forKeys:[NSArray arrayWithObjects: 
			@"Range of Substrings", 
			@"Regular Expression Enumerator", 
			@"Cache (Length of NSString)", 
			@"Cache (Length of UTF8String)", 
			@"Terminal of the Last Match", 
			@"Index", 
			nil]
		];
		
	return [dictionary description];
}


// 名前(ラベル)がnameの部分文字列 (OgreCaptureGroupOptionを指定したときに使用できる)
// 存在しない名前の場合は nil を返す。
// 同一の名前を持つ部分文字列が複数ある場合は例外を発生させる。
- (NSString*)substringNamed:(NSString*)name
{
	int	index = [self indexOfSubstringNamed:name];
	if (index == -1) return nil;
		
	return [self substringAtIndex:index];
}

// 名前がnameの部分文字列の範囲
// 存在しない名前の場合は {-1, 0} を返す。
// 同一の名前を持つ部分文字列が複数ある場合は例外を発生させる。
- (NSRange)rangeOfSubstringNamed:(NSString*)name
{
	int	index = [self indexOfSubstringNamed:name];
	if (index == -1) return NSMakeRange(-1, 0);
	
	return [self rangeOfSubstringAtIndex:index];
}

// 名前がnameの部分文字列のindex
// 存在しない場合は-1を返す
// 同一の名前を持つ部分文字列が複数ある場合は例外を発生させる。
- (unsigned)indexOfSubstringNamed:(NSString*)name
{
	int	index = [[_enumerator regularExpression] groupIndexForName:name];
	if (index == -2) {
		// 同一の名前を持つ部分文字列が複数ある場合は例外を発生させる。
		[NSException raise:OgreMatchException format:@"multiplex definition name <%@> call", name];
	}
	
	return index;
}

// index番目の部分文字列の名前
// 存在しない名前の場合は nil を返す。
- (NSString*)nameOfSubstringAtIndex:(unsigned)index
{
	return [[_enumerator regularExpression] nameForGroupIndex:index];
}



// マッチした部分文字列のうちグループ番号が最小のもの
- (unsigned)indexOfFirstMatchedSubstringInRange:(NSRange)aRange
{
	unsigned	index, count = [self count];
	if (count > NSMaxRange(aRange)) count = NSMaxRange(aRange);
	
	for (index = aRange.location; index < count; index++) {
		if (_region->beg[index] != -1) return index;
	}
	
	return 0;   // どの部分式にもマッチしなかった場合
}

- (NSString*)nameOfFirstMatchedSubstringInRange:(NSRange)aRange
{
	return [self nameOfSubstringAtIndex:[self indexOfFirstMatchedSubstringInRange:aRange]];
}


// マッチした部分文字列のうちグループ番号が最大のもの
- (unsigned)indexOfLastMatchedSubstringInRange:(NSRange)aRange
{
	unsigned	index, count = [self count];
	if (count > NSMaxRange(aRange)) count = NSMaxRange(aRange);

	for (index = count - 1; index >= aRange.location; index--) {
		if (_region->beg[index] != -1) return index;
	}
	
	return 0;   // どの部分式にもマッチしなかった場合
}

- (NSString*)nameOfLastMatchedSubstringInRange:(NSRange)aRange
{
	return [self nameOfSubstringAtIndex:[self indexOfLastMatchedSubstringInRange:aRange]];
}


// マッチした部分文字列のうち最長のもの
- (unsigned)indexOfLongestSubstringInRange:(NSRange)aRange
{
	BOOL		matched = NO;
	unsigned	maxLength = 0;
	unsigned	maxIndex = 0, i, count = [self count];
	NSRange		range;
	if (count > NSMaxRange(aRange)) count = NSMaxRange(aRange);

	for (i = aRange.location; i < count; i++) {
		range = [self rangeOfSubstringAtIndex:i];
		if ((range.location != -1) && ((maxLength < range.length) || !matched)) {
			matched = YES;
			maxLength = range.length;
			maxIndex = i;
		}
	}
	
	return maxIndex;
}

- (NSString*)nameOfLongestSubstringInRange:(NSRange)aRange
{
	return [self nameOfSubstringAtIndex:[self indexOfLongestSubstringInRange:aRange]];
}


// マッチした部分文字列のうち最短のもの
- (unsigned)indexOfShortestSubstringInRange:(NSRange)aRange
{
	BOOL		matched = NO;
	unsigned	minLength = 0;
	unsigned	minIndex = 0, i, count = [self count];
	NSRange		range;
	if (count > NSMaxRange(aRange)) count = NSMaxRange(aRange);
	
	for (i = aRange.location; i < count; i++) {
		range = [self rangeOfSubstringAtIndex:i];
		if ((range.location != -1) && ((minLength > range.length) || !matched)) {
			matched = YES;
			minLength = range.length;
			minIndex = i;
		}
	}
	
	return minIndex;
}

- (NSString*)nameOfShortestSubstringInRange:(NSRange)aRange
{
	return [self nameOfSubstringAtIndex:[self indexOfShortestSubstringInRange:aRange]];
}

// マッチした部分文字列のうちグループ番号が最小のもの (ない場合は0を返す)
- (unsigned)indexOfFirstMatchedSubstring
{
	return [self indexOfFirstMatchedSubstringInRange:NSMakeRange(1, [self count] - 1)];
}

- (unsigned)indexOfFirstMatchedSubstringBeforeIndex:(unsigned)anIndex
{
	return [self indexOfFirstMatchedSubstringInRange:NSMakeRange(1, anIndex - 1)];
}

- (unsigned)indexOfFirstMatchedSubstringAfterIndex:(unsigned)anIndex
{
	return [self indexOfFirstMatchedSubstringInRange:NSMakeRange(anIndex, [self count] - anIndex)];
}

// その名前
- (NSString*)nameOfFirstMatchedSubstring
{
	return [self nameOfFirstMatchedSubstringInRange:NSMakeRange(1, [self count] - 1)];
}

- (NSString*)nameOfFirstMatchedSubstringBeforeIndex:(unsigned)anIndex
{
	return [self nameOfFirstMatchedSubstringInRange:NSMakeRange(1, anIndex - 1)];
}

- (NSString*)nameOfFirstMatchedSubstringAfterIndex:(unsigned)anIndex
{
	return [self nameOfFirstMatchedSubstringInRange:NSMakeRange(anIndex, [self count] - anIndex)];
}


// マッチした部分文字列のうちグループ番号が最大のもの (ない場合は0を返す)
- (unsigned)indexOfLastMatchedSubstring
{
	return [self indexOfLastMatchedSubstringInRange:NSMakeRange(1, [self count] - 1)];
}

- (unsigned)indexOfLastMatchedSubstringBeforeIndex:(unsigned)anIndex
{
	return [self indexOfLastMatchedSubstringInRange:NSMakeRange(1, anIndex - 1)];
}

- (unsigned)indexOfLastMatchedSubstringAfterIndex:(unsigned)anIndex
{
	return [self indexOfLastMatchedSubstringInRange:NSMakeRange(anIndex, [self count] - anIndex)];
}

// その名前
- (NSString*)nameOfLastMatchedSubstring
{
	return [self nameOfLastMatchedSubstringInRange:NSMakeRange(1, [self count] - 1)];
}

- (NSString*)nameOfLastMatchedSubstringBeforeIndex:(unsigned)anIndex
{
	return [self nameOfLastMatchedSubstringInRange:NSMakeRange(1, anIndex - 1)];
}

- (NSString*)nameOfLastMatchedSubstringAfterIndex:(unsigned)anIndex
{
	return [self nameOfLastMatchedSubstringInRange:NSMakeRange(anIndex, [self count] - anIndex)];
}


// マッチした部分文字列のうち最長のもの (ない場合は0を返す。同じ長さの物が複数あれば、番号の小さい物が優先される)
- (unsigned)indexOfLongestSubstring
{
	return [self indexOfLongestSubstringInRange:NSMakeRange(1, [self count] - 1)];
}

- (unsigned)indexOfLongestSubstringBeforeIndex:(unsigned)anIndex
{
	return [self indexOfLongestSubstringInRange:NSMakeRange(1, anIndex - 1)];
}

- (unsigned)indexOfLongestSubstringAfterIndex:(unsigned)anIndex
{
	return [self indexOfLongestSubstringInRange:NSMakeRange(anIndex, [self count] - anIndex)];
}

// その名前
- (NSString*)nameOfLongestSubstring
{
	return [self nameOfLongestSubstringInRange:NSMakeRange(1, [self count] - 1)];
}

- (NSString*)nameOfLongestSubstringBeforeIndex:(unsigned)anIndex
{
	return [self nameOfLongestSubstringInRange:NSMakeRange(1, anIndex - 1)];
}

- (NSString*)nameOfLongestSubstringAfterIndex:(unsigned)anIndex
{
	return [self nameOfLongestSubstringInRange:NSMakeRange(anIndex, [self count] - anIndex)];
}


// マッチした部分文字列のうち最短のもの (ない場合は0を返す。同じ長さの物が複数あれば、番号の小さい物が優先される)
- (unsigned)indexOfShortestSubstring
{
	return [self indexOfShortestSubstringInRange:NSMakeRange(1, [self count] - 1)];
}

- (unsigned)indexOfShortestSubstringBeforeIndex:(unsigned)anIndex
{
	return [self indexOfShortestSubstringInRange:NSMakeRange(1, anIndex - 1)];
}

- (unsigned)indexOfShortestSubstringAfterIndex:(unsigned)anIndex
{
	return [self indexOfShortestSubstringInRange:NSMakeRange(anIndex, [self count] - anIndex)];
}

// その名前
- (NSString*)nameOfShortestSubstring
{
	return [self nameOfShortestSubstringInRange:NSMakeRange(1, [self count] - 1)];
}

- (NSString*)nameOfShortestSubstringBeforeIndex:(unsigned)anIndex
{
	return [self nameOfShortestSubstringInRange:NSMakeRange(1, anIndex - 1)];
}

- (NSString*)nameOfShortestSubstringAfterIndex:(unsigned)anIndex
{
	return [self nameOfShortestSubstringInRange:NSMakeRange(anIndex, [self count] - anIndex)];
}

/******************
* Capture History *
*******************/
// index番目のグループの捕獲履歴
// 履歴がない場合はnilを返す。
- (OGRegularExpressionMatch*)captureHistoryAtIndex:(unsigned)index
{
	if ((index >= [self count]) || !ONIG_IS_CAPTURE_HISTORY_GROUP(_region, index)) return nil;
	
	return [[[[self class] allocWithZone:[self zone]] 
		initWithRegion: _region->list[index] 
		index: _index 
		enumerator: _enumerator 
		locationCache: _locationCache 
		utf8LocationCache: _utf8LocationCache 
		utf8TerminalOfLastMatch: _utf8TerminalOfLastMatch 
		parentMatch:self] autorelease];
}

- (OGRegularExpressionMatch*)captureHistoryNamed:(NSString*)name
{
	int	index = [self indexOfSubstringNamed:name];
	if (index == -1) return nil;
	
	return [self captureHistoryAtIndex:index];
}

@end
