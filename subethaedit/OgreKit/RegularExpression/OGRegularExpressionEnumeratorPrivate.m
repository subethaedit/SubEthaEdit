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
	NSLog(@"-initWithSwappedString: of %@", [self className]);
#endif
	self = [super init];
	if (self) {
		// 検索対象文字列を保持
		// target stringをUTF16文字列に変換する。
		_swappedTargetString = [swappedTargetString retain];
        _lengthOfSwappedTargetString = [_swappedTargetString length];
        
        _UTF16SwappedTargetString = (unichar*)NSZoneMalloc([self zone], sizeof(unichar) * _lengthOfSwappedTargetString);
        if (_UTF16SwappedTargetString == NULL) {
            // メモリを確保できなかった場合、例外を発生させる。
            [self release];
            [NSException raise:OgreEnumeratorException format:@"fail to allocate a memory"];
        }
        [_swappedTargetString getCharacters:_UTF16SwappedTargetString range:NSMakeRange(0, _lengthOfSwappedTargetString)];
            
        /* DEBUG 
        {
            NSLog(@"TargetString: '%@'", _swappedTargetString);
            int     i, count = _lengthOfSwappedTargetString;
            unichar *utf16Chars = _UTF16SwappedTargetString;
            for (i = 0; i < count; i++) {
                NSLog(@"UTF16: %04x", *(utf16Chars + i));
            }
        }*/
        
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
		_terminalOfLastMatch = 0;
		
		// マッチ開始位置
		_startLocation = 0;
	
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
	NSLog(@"-dealloc of %@", [self className]);
#endif
	// 開放
	[_regex release];
	NSZoneFree([self zone], _UTF16SwappedTargetString);
	[_swappedTargetString release];
	
	[super dealloc];
}

/* accessors */
// private
- (void)_setTerminalOfLastMatch:(int)location
{
	_terminalOfLastMatch = location;
}

- (void)_setIsLastMatchEmpty:(BOOL)yesOrNo
{
	_isLastMatchEmpty = yesOrNo;
}

- (void)_setStartLocation:(unsigned)location
{
	_startLocation = location;
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

- (unichar*)UTF16SwappedTargetString
{
	return _UTF16SwappedTargetString;
}

- (NSRange)searchRange
{
	return _searchRange;
}


@end
