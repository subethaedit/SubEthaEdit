/*
 * Name: OGRegularExpressionEnumeratorPrivate.m
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
#import <OgreKit/OGRegularExpressionPrivate.h>
#import <OgreKit/OGRegularExpressionMatch.h>
#import <OgreKit/OGRegularExpressionMatchPrivate.h>
#import <OgreKit/OGRegularExpressionEnumerator.h>
#import <OgreKit/OGRegularExpressionEnumeratorPrivate.h>


@implementation OGRegularExpressionEnumerator (Private)

- (id) initWithSwappedString:(NSString*)swappedTargetString 
	options:(unsigned)searchOptions 
	range:(NSRange)searchRange 
	regularExpression:(OGRegularExpression*)regex
{
#ifdef DEBUG_OGRE
	NSLog(@"-initWithSwappedString: of OGRegularExpressionEnumerator");
#endif
	self = [super init];
	if (self) {
		// 検索対象文字列を保持
		// target stringをUTF8文字列に変換する。
		_swappedTargetString = [swappedTargetString retain];
		
		// duplicate [_swappedTargetString UTF8String]
		unsigned char   *tmpUTF8String = (unsigned char*)[_swappedTargetString UTF8String];
		_utf8lengthOfSwappedTargetString = strlen(tmpUTF8String);
		_utf8SwappedTargetString = (unsigned char*)NSZoneMalloc([self zone], sizeof(unsigned char) * (_utf8lengthOfSwappedTargetString + 1));
		if (_utf8SwappedTargetString == NULL) {
			// メモリを確保できなかった場合、例外を発生させる。
			[NSException raise:OgreEnumeratorException format:@"fail to duplicate a utf8SwappedTargetString"];
		}
		memcpy(_utf8SwappedTargetString, tmpUTF8String, _utf8lengthOfSwappedTargetString + 1);
		
		// 検索範囲
		_searchRange = searchRange;
		
		// 正規表現オブジェクトを保持
		_regex = [regex retain];
		
		// 検索オプション
		_searchOptions = searchOptions;
		
		/* 初期値設定 */
		// 最後にマッチした文字列の終端位置
		// 初期値 0
		// 値 >=  0 終端位置
		// 値 == -1 マッチ終了
		_utf8TerminalOfLastMatch = 0;
		
		// マッチ開始位置
		_startLocation = 0;
		_utf8StartLocation = 0;
	
		// 前回のマッチが空文字列だったかどうか
		_isLastMatchEmpty = NO;
		
		// マッチした数
		_numberOfMatches = 0;
	}
	
	return self;
}

- (void)dealloc
{
#ifdef DEBUG_OGRE
	NSLog(@"-dealloc of OGRegularExpressionEnumerator");
#endif
	// 開放
	[_regex release];
	[_swappedTargetString release];
	
	[super dealloc];
}

/* accessors */
// private
- (void)_setUtf8TerminalOfLastMatch:(int)location
{
	_utf8TerminalOfLastMatch = location;
}

- (void)_setIsLastMatchEmpty:(BOOL)yesOrNo
{
	_isLastMatchEmpty = yesOrNo;
}

- (void)_setStartLocation:(unsigned)location
{
	_startLocation = location;
}

- (void)_setUtf8StartLocation:(unsigned)location
{
	_utf8StartLocation = location;
}

- (void)_setNumberOfMatches:(unsigned)aNumber
{
	_numberOfMatches = aNumber;
}

- (OGRegularExpression*)regularExpression
{
	return _regex;
}

- (void)setRegularExpression:(OGRegularExpression*)regularExpression
{
	[regularExpression retain];
	[_regex release];
	_regex = regularExpression;
}

// public?
- (NSString*)swappedTargetString
{
	return _swappedTargetString;
}

- (unsigned char*)utf8SwappedTargetString
{
	return _utf8SwappedTargetString;
}

- (NSRange)searchRange
{
	return _searchRange;
}


// 破壊的操作
- (NSString*)input
{
	NSString	*aCharacter;
	unsigned	utf8charlen;
	
	if ((_utf8TerminalOfLastMatch == -1) || (_startLocation > _searchRange.length) || (!_isLastMatchEmpty && _startLocation == _searchRange.length)) {
		// エラー。例外を発生させる。
		[NSException raise:OgreEnumeratorException format:@"out of range"];
	}
	
	if (!_isLastMatchEmpty) {
		// 1文字進める。
		utf8charlen = Ogre_utf8charlen(_utf8SwappedTargetString + _utf8StartLocation);
		_utf8StartLocation += utf8charlen;
		_startLocation += ((utf8charlen >= 4)? 2 : 1);   // NSStringで1文字進める (4-octetの場合はなぜか2文字(2文字目は空文字)進めなければならない)
	}
	utf8charlen = Ogre_utf8prevcharlen(_utf8SwappedTargetString + _utf8StartLocation);
	aCharacter = [[_regex class] swapBackslashInString:[_swappedTargetString substringWithRange:NSMakeRange(_searchRange.location + _startLocation - ((utf8charlen >= 4)? 2 : 1), ((utf8charlen >= 4)? 2 : 1))] forCharacter:[_regex escapeCharacter]];
	_isLastMatchEmpty = NO;
	_utf8TerminalOfLastMatch = _utf8StartLocation;
	
	return aCharacter;
}

- (void)less:(unsigned)aLength
{
	unsigned	i;
	unsigned	utf8charlen;

	if ((_utf8TerminalOfLastMatch == -1) || (_startLocation < aLength) || (_isLastMatchEmpty && _startLocation <= aLength)) {
		// エラー。例外を発生させる。
		[NSException raise:OgreEnumeratorException format:@"out of range"];
	}
	
	if (_isLastMatchEmpty) {
		// 1文字戻す。
		utf8charlen = Ogre_utf8prevcharlen(_utf8SwappedTargetString + _utf8TerminalOfLastMatch);
		_startLocation -= ((utf8charlen >= 4)? 2 : 1);  // NSStringで1文字戻す (4-octetの場合はなぜか2文字(2文字目は空文字)戻さなければならない)
	}
	
	// aLength文字戻す。
	for (i = 0; i < aLength; i++) {
		utf8charlen = Ogre_utf8prevcharlen(_utf8SwappedTargetString + _utf8TerminalOfLastMatch);
		_utf8TerminalOfLastMatch -= utf8charlen;
		_startLocation -= ((utf8charlen >= 4)? 2 : 1);  // NSStringで1文字戻す (4-octetの場合はなぜか2文字(2文字目は空文字)戻さなければならない)
	}
	_isLastMatchEmpty = NO;
	_utf8StartLocation = _utf8TerminalOfLastMatch;
}

@end
